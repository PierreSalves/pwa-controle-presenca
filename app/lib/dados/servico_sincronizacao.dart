// Sincronização da presença com a API (docs/arquitetura/README.md, "Como a sincronização funciona").
//   push: envia a outbox (até 500 itens), apaga os aceitos e marca os recusados com o código de erro;
//   pull: busca o que mudou desde o cursor e grava no banco local.
// Registro com alteração pendente na outbox não é sobrescrito pelo pull (a alteração local vence
// até a API responder). Se as turmas permitidas mudarem, apaga o que saiu e refaz o pull do zero.
import 'dart:convert';

import 'package:drift/drift.dart';

import 'banco_local.dart';

const maximoOperacoesPorPush = 500;

/// Respostas da API de sync. A implementação HTTP fica em cliente_api.dart.
abstract interface class ClienteSync {
  Future<Map<String, dynamic>> buscarAlteracoesDesde(int cursor);
  Future<Map<String, dynamic>> enviarOperacoes(
    List<Map<String, dynamic>> operacoes,
  );
}

class ResultadoEnvio {
  const ResultadoEnvio({required this.aceitos, required this.recusados});
  final int aceitos;
  final int recusados;
}

class ServicoSincronizacao {
  ServicoSincronizacao(this._banco, this._cliente);

  final BancoLocal _banco;
  final ClienteSync _cliente;

  static const _chaveCursor = 'cursor';
  static const _chaveTurmas = 'turmas_permitidas';

  Future<String?> _obterEstado(String chave) async => (await (_banco.select(
    _banco.estadoSync,
  )..where((e) => e.chave.equals(chave))).getSingleOrNull())?.valor;

  Future<void> _definirEstado(String chave, String valor) => _banco
      .into(_banco.estadoSync)
      .insertOnConflictUpdate(
        EstadoSyncCompanion.insert(chave: chave, valor: valor),
      );

  Future<int> obterCursor() async =>
      int.tryParse(await _obterEstado(_chaveCursor) ?? '') ?? 0;

  /// Envia os itens pendentes da outbox (sem erro), em ordem de criação.
  Future<ResultadoEnvio> enviarPendentes() async {
    final itens =
        await (_banco.select(_banco.outbox)
              ..where((o) => o.erro.isNull())
              ..orderBy([(o) => OrderingTerm.asc(o.criadoEm)])
              ..limit(maximoOperacoesPorPush))
            .get();
    if (itens.isEmpty) return const ResultadoEnvio(aceitos: 0, recusados: 0);

    // Guarda o payload enviado: se o usuário alterar o registro durante o envio, a nova
    // alteração continua na outbox.
    final enviados = {for (final i in itens) i.id: i.payload};
    final resposta = await _cliente.enviarOperacoes([
      for (final i in itens)
        {'id': i.id, 'tabela': i.tabela, 'registro': jsonDecode(i.payload)},
    ]);
    final aceitos = (resposta['aceitos'] as List).cast<String>();
    final recusados = (resposta['rejeitados'] as List)
        .cast<Map<String, dynamic>>();

    await _banco.transaction(() async {
      for (final id in aceitos) {
        await (_banco.delete(_banco.outbox)..where(
              (o) => o.id.equals(id) & o.payload.equals(enviados[id] ?? ''),
            ))
            .go();
      }
      for (final recusa in recusados) {
        final id = recusa['id'] as String;
        await (_banco.update(_banco.outbox)..where(
              (o) => o.id.equals(id) & o.payload.equals(enviados[id] ?? ''),
            ))
            .write(OutboxCompanion(erro: Value(recusa['erro'] as String)));
      }
    });
    return ResultadoEnvio(aceitos: aceitos.length, recusados: recusados.length);
  }

  /// Busca as alterações desde o último cursor e grava no banco local.
  Future<void> buscarAlteracoes() async {
    var cursor = await obterCursor();
    var dados = await _cliente.buscarAlteracoesDesde(cursor);

    final permitidas = (dados['turmas_permitidas'] as List)
        .cast<String>()
        .toSet();
    final anteriores = await _obterEstado(_chaveTurmas);
    final conhecidas = anteriores == null
        ? null
        : (jsonDecode(anteriores) as List).cast<String>().toSet();
    final mudou =
        conhecidas != null &&
        (conhecidas.length != permitidas.length ||
            !conhecidas.containsAll(permitidas));
    if (mudou) {
      await _apagarTurmas(conhecidas.difference(permitidas));
      if (cursor != 0) {
        cursor = 0;
        dados = await _cliente.buscarAlteracoesDesde(0);
      }
    }
    await _gravarAlteracoes(dados);
  }

  /// Apaga do aparelho os dados das turmas a que o usuário perdeu o acesso.
  Future<void> _apagarTurmas(Set<String> turmaIds) async {
    if (turmaIds.isEmpty) return;
    await _banco.transaction(() async {
      final aulas = await (_banco.select(
        _banco.aulas,
      )..where((a) => a.turmaId.isIn(turmaIds))).map((a) => a.id).get();
      await (_banco.delete(
        _banco.presencas,
      )..where((p) => p.aulaId.isIn(aulas))).go();
      await _apagarOutboxDasAulas(aulas.toSet());
      await (_banco.delete(
        _banco.aulas,
      )..where((a) => a.turmaId.isIn(turmaIds))).go();
      await (_banco.delete(
        _banco.matriculas,
      )..where((m) => m.turmaId.isIn(turmaIds))).go();
      await (_banco.delete(
        _banco.quadrosAulas,
      )..where((q) => q.turmaId.isIn(turmaIds))).go();
      await (_banco.delete(
        _banco.turmas,
      )..where((t) => t.id.isIn(turmaIds))).go();
    });
  }

  /// Itens da outbox das aulas informadas (a própria aula ou presenças nela): a API recusaria
  /// por falta de acesso, então não adianta guardar.
  Future<void> _apagarOutboxDasAulas(Set<String> aulas) async {
    final itens = await _banco.select(_banco.outbox).get();
    final ids = [
      for (final item in itens)
        if (aulas.contains(item.registroId) ||
            (item.tabela == 'presencas' &&
                aulas.contains((jsonDecode(item.payload) as Map)['aula_id'])))
          item.id,
    ];
    await (_banco.delete(_banco.outbox)..where((o) => o.id.isIn(ids))).go();
  }

  Future<Set<String>> _obterPendentes(String tabela) async =>
      (await (_banco.select(_banco.outbox)
                ..where((o) => o.tabela.equals(tabela) & o.erro.isNull()))
              .map((o) => o.registroId)
              .get())
          .toSet();

  Future<void> _gravarAlteracoes(Map<String, dynamic> dados) async {
    List<Map<String, dynamic>> linhas(String chave) =>
        ((dados[chave] as List?) ?? const []).cast<Map<String, dynamic>>();
    final aulasPendentes = await _obterPendentes('aulas');
    final presencasPendentes = await _obterPendentes('presencas');

    await _banco.transaction(() async {
      for (final t in linhas('turmas')) {
        await _banco
            .into(_banco.turmas)
            .insertOnConflictUpdate(
              TurmasCompanion.insert(
                id: t['id'] as String,
                nome: t['nome'] as String,
                frequenciaMinima: Value(t['frequencia_minima'] as int?),
                cabecalhoImpressao: Value(t['cabecalho_impressao'] as String?),
                regras: Value(jsonEncode(t['regras'] ?? const {})),
                excluido: Value(t['excluido'] as int),
                updatedAt: t['updated_at'] as String,
              ),
            );
      }
      for (final q in linhas('quadros_aulas')) {
        await _banco
            .into(_banco.quadrosAulas)
            .insertOnConflictUpdate(
              QuadrosAulasCompanion.insert(
                id: q['id'] as String,
                turmaId: q['turma_id'] as String,
                vigenciaInicio: q['vigencia_inicio'] as String,
                vigenciaFim: Value(q['vigencia_fim'] as String?),
                domingo: q['domingo'] as int,
                segunda: q['segunda'] as int,
                terca: q['terca'] as int,
                quarta: q['quarta'] as int,
                quinta: q['quinta'] as int,
                sexta: q['sexta'] as int,
                sabado: q['sabado'] as int,
                excluido: Value(q['excluido'] as int),
                updatedAt: q['updated_at'] as String,
              ),
            );
      }
      for (final a in linhas('alunos')) {
        await _banco
            .into(_banco.alunos)
            .insertOnConflictUpdate(
              AlunosCompanion.insert(
                id: a['id'] as String,
                codigo: a['codigo'] as String,
                nome: a['nome'] as String,
                ativo: Value(a['ativo'] as int),
                excluido: Value(a['excluido'] as int),
                updatedAt: a['updated_at'] as String,
              ),
            );
      }
      for (final m in linhas('matriculas')) {
        await _banco
            .into(_banco.matriculas)
            .insertOnConflictUpdate(
              MatriculasCompanion.insert(
                id: m['id'] as String,
                alunoId: m['aluno_id'] as String,
                turmaId: m['turma_id'] as String,
                dataInicio: m['data_inicio'] as String,
                dataFim: Value(m['data_fim'] as String?),
                situacao: m['situacao'] as String,
                excluido: Value(m['excluido'] as int),
                updatedAt: m['updated_at'] as String,
              ),
            );
      }
      for (final a in linhas('aulas')) {
        if (aulasPendentes.contains(a['id'])) continue;
        await _banco
            .into(_banco.aulas)
            .insertOnConflictUpdate(
              AulasCompanion.insert(
                id: a['id'] as String,
                turmaId: a['turma_id'] as String,
                dataAula: a['data_aula'] as String,
                tipo: a['tipo'] as String,
                excluido: Value(a['excluido'] as int),
                updatedAt: a['updated_at'] as String,
              ),
            );
      }
      for (final p in linhas('presencas')) {
        await _gravarPresencaDoServidor(p, presencasPendentes);
      }
      await _definirEstado(_chaveCursor, '${dados['cursor']}');
      await _definirEstado(
        _chaveTurmas,
        jsonEncode(dados['turmas_permitidas']),
      );
    });
  }

  /// A presença é única por (aula, aluno): outro aparelho pode ter criado a mesma com outro id.
  Future<void> _gravarPresencaDoServidor(
    Map<String, dynamic> p,
    Set<String> pendentes,
  ) async {
    final aulaId = p['aula_id'] as String;
    final alunoId = p['aluno_id'] as String;
    final local =
        await (_banco.select(_banco.presencas)..where(
              (x) => x.aulaId.equals(aulaId) & x.alunoId.equals(alunoId),
            ))
            .getSingleOrNull();
    if (local != null && pendentes.contains(local.id)) return;
    if (local != null && local.id != p['id']) {
      await (_banco.delete(
        _banco.presencas,
      )..where((x) => x.id.equals(local.id))).go();
    }
    await _banco
        .into(_banco.presencas)
        .insertOnConflictUpdate(
          PresencasCompanion.insert(
            id: p['id'] as String,
            aulaId: aulaId,
            alunoId: alunoId,
            excluido: Value(p['excluido'] as int),
            updatedAt: p['updated_at'] as String,
            updatedBy: Value(p['updated_by'] as String?),
          ),
        );
  }
}
