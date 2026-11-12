// Gravação local da presença. A tela de lançamento só fala com este repositório (regra de ouro da
// arquitetura): grava no SQLite local e põe a alteração na outbox, numa transação só. O envio à API
// fica com o ServicoSincronizacao.
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../regras/presenca.dart';
import 'banco_local.dart';

/// Motivo pelo qual a marcação foi recusada no próprio aparelho (as mesmas regras da API).
enum RecusaMarcacao {
  dataFutura,
  diaSemAulaRegular,
  diaSemReposicaoFixa,
  foraDaMatricula,
}

class MarcacaoRecusada implements Exception {
  const MarcacaoRecusada(this.motivo);
  final RecusaMarcacao motivo;

  @override
  String toString() => 'MarcacaoRecusada(${motivo.name})';
}

class RepositorioPresenca {
  RepositorioPresenca(this._banco, {DateTime Function()? relogio})
    : _relogio = relogio ?? DateTime.now;

  final BancoLocal _banco;
  final DateTime Function() _relogio;
  static const _uuid = Uuid();

  String _agoraIso() => _relogio().toUtc().toIso8601String();

  Future<List<QuadroAulas>> obterQuadrosDaTurma(String turmaId) async {
    final linhas = await (_banco.select(
      _banco.quadrosAulas,
    )..where((q) => q.turmaId.equals(turmaId) & q.excluido.equals(0))).get();
    return [
      for (final q in linhas)
        QuadroAulas(
          vigenciaInicio: q.vigenciaInicio,
          vigenciaFim: q.vigenciaFim,
          dias: {
            'domingo': q.domingo,
            'segunda': q.segunda,
            'terca': q.terca,
            'quarta': q.quarta,
            'quinta': q.quinta,
            'sexta': q.sexta,
            'sabado': q.sabado,
          },
        ),
    ];
  }

  Future<bool> _estaMatriculado(
    String alunoId,
    String turmaId,
    String data,
  ) async {
    final matriculas =
        await (_banco.select(_banco.matriculas)..where(
              (m) =>
                  m.alunoId.equals(alunoId) &
                  m.turmaId.equals(turmaId) &
                  m.excluido.equals(0),
            ))
            .get();
    return matriculas.any(
      (m) => estaMatriculadoNaData(
        data,
        dataInicio: m.dataInicio,
        dataFim: m.dataFim,
      ),
    );
  }

  /// Põe (ou atualiza) a alteração do registro na outbox.
  Future<void> _enfileirar(
    String tabela,
    String registroId,
    Map<String, Object?> registro,
  ) async {
    final existente =
        await (_banco.select(_banco.outbox)..where(
              (o) => o.tabela.equals(tabela) & o.registroId.equals(registroId),
            ))
            .getSingleOrNull();
    final payload = jsonEncode(registro);
    if (existente == null) {
      await _banco
          .into(_banco.outbox)
          .insert(
            OutboxCompanion.insert(
              id: _uuid.v7(),
              tabela: tabela,
              registroId: registroId,
              payload: payload,
              criadoEm: _agoraIso(),
            ),
          );
    } else {
      // Nova alteração do mesmo registro: substitui a anterior e limpa um erro antigo.
      await (_banco.update(
        _banco.outbox,
      )..where((o) => o.id.equals(existente.id))).write(
        OutboxCompanion(
          payload: Value(payload),
          erro: const Value(null),
          tentativas: const Value(0),
        ),
      );
    }
  }

  /// Garante a aula do quadro (id determinístico) ou a reposição avulsa informada; devolve o id.
  Future<String> _garantirAula({
    required String turmaId,
    required String data,
    required TipoAula tipo,
    String? idReposicaoAvulsa,
  }) async {
    final id = idReposicaoAvulsa ?? gerarIdAulaDoQuadro(turmaId, data, tipo);
    final existente = await (_banco.select(
      _banco.aulas,
    )..where((a) => a.id.equals(id))).getSingleOrNull();
    if (existente != null && existente.excluido == 0) return id;
    final agora = _agoraIso();
    await _banco
        .into(_banco.aulas)
        .insertOnConflictUpdate(
          AulasCompanion.insert(
            id: id,
            turmaId: turmaId,
            dataAula: data,
            tipo: tipo.valor,
            updatedAt: agora,
          ),
        );
    await _enfileirar('aulas', id, {
      'id': id,
      'turma_id': turmaId,
      'data_aula': data,
      'tipo': tipo.valor,
      'excluido': 0,
      'updated_at': agora,
    });
    return id;
  }

  /// Cria uma reposição avulsa (qualquer dia não futuro) e devolve o id da aula.
  Future<String> criarReposicaoAvulsa(String turmaId, String data) async {
    if (ehDataFutura(data, obterHojeEmSaoPaulo(_relogio()))) {
      throw const MarcacaoRecusada(RecusaMarcacao.dataFutura);
    }
    return _banco.transaction(
      () => _garantirAula(
        turmaId: turmaId,
        data: data,
        tipo: TipoAula.reposicao,
        idReposicaoAvulsa: _uuid.v7(),
      ),
    );
  }

  /// Marca (presente = true) ou desmarca o aluno na aula do dia.
  /// Para aula do quadro, informe `tipo`; para reposição avulsa, o `aulaId` já criado.
  Future<void> definirPresenca({
    required String turmaId,
    required String data,
    required String alunoId,
    required bool presente,
    TipoAula tipo = TipoAula.regular,
    String? aulaIdAvulsa,
  }) async {
    final hoje = obterHojeEmSaoPaulo(_relogio());
    if (ehDataFutura(data, hoje)) {
      throw const MarcacaoRecusada(RecusaMarcacao.dataFutura);
    }
    if (aulaIdAvulsa == null) {
      final tipoDoDia = calcularTipoDoDia(
        data,
        await obterQuadrosDaTurma(turmaId),
      );
      if (tipo == TipoAula.regular && tipoDoDia != TipoDia.regular) {
        throw const MarcacaoRecusada(RecusaMarcacao.diaSemAulaRegular);
      }
      if (tipo == TipoAula.reposicao && tipoDoDia != TipoDia.reposicao) {
        throw const MarcacaoRecusada(RecusaMarcacao.diaSemReposicaoFixa);
      }
    }
    if (presente && !await _estaMatriculado(alunoId, turmaId, data)) {
      throw const MarcacaoRecusada(RecusaMarcacao.foraDaMatricula);
    }

    await _banco.transaction(() async {
      final aulaId =
          aulaIdAvulsa ??
          await _garantirAula(turmaId: turmaId, data: data, tipo: tipo);
      final existente =
          await (_banco.select(_banco.presencas)..where(
                (p) => p.aulaId.equals(aulaId) & p.alunoId.equals(alunoId),
              ))
              .getSingleOrNull();
      final id = existente?.id ?? _uuid.v7();
      final agora = _agoraIso();
      final excluido = presente ? 0 : 1;
      if (existente == null) {
        await _banco
            .into(_banco.presencas)
            .insert(
              PresencasCompanion.insert(
                id: id,
                aulaId: aulaId,
                alunoId: alunoId,
                excluido: Value(excluido),
                updatedAt: agora,
              ),
            );
      } else {
        await (_banco.update(
          _banco.presencas,
        )..where((p) => p.id.equals(id))).write(
          PresencasCompanion(
            excluido: Value(excluido),
            updatedAt: Value(agora),
          ),
        );
      }
      await _enfileirar('presencas', id, {
        'id': id,
        'aula_id': aulaId,
        'aluno_id': alunoId,
        'excluido': excluido,
        'updated_at': agora,
      });
    });
  }

  /// Quantas alterações ainda não foram aceitas pela API (sem contar as recusadas).
  Stream<int> observarPendentes() {
    final contagem = _banco.outbox.id.count();
    final consulta = _banco.selectOnly(_banco.outbox)
      ..addColumns([contagem])
      ..where(_banco.outbox.erro.isNull());
    return consulta.map((linha) => linha.read(contagem) ?? 0).watchSingle();
  }
}
