// Leitura do banco local para a tela de lançamento: dias de aula da semana, alunos matriculados
// com a frequência (lista de frequentes) e quem já está marcado. Tudo local, funciona offline.
import 'dart:convert';

import 'package:drift/drift.dart';

import '../regras/lista_lancamento.dart';
import '../regras/presenca.dart';
import 'banco_local.dart';
import 'repositorio_presenca.dart';

class DiaDeAula {
  const DiaDeAula({
    required this.data,
    required this.tipo,
    required this.futuro,
  });
  final String data;
  final TipoAula tipo;
  final bool futuro;
}

class AlunoNoLancamento {
  const AlunoNoLancamento({
    required this.id,
    required this.codigo,
    required this.nome,
    required this.frequencia,
    required this.presente,
  });

  final String id;
  final String codigo;
  final String nome;
  final FrequenciaNaLista frequencia;
  final bool presente;

  /// Aparece na lista principal: é frequente ou já foi marcado no dia.
  bool get estaNaLista => frequencia.frequente || presente;
}

class DadosLancamento {
  const DadosLancamento({
    required this.turmaNome,
    required this.data,
    required this.tipo,
    required this.lista,
    required this.poucoFrequentes,
  });

  final String turmaNome;
  final String data;

  /// Tipo da aula do dia pelo quadro; null quando o quadro não tem aula nesse dia.
  final TipoAula? tipo;

  /// Frequentes e marcados, por frequência (maior primeiro) e nome.
  final List<AlunoNoLancamento> lista;

  /// Matriculados fora da lista, por nome.
  final List<AlunoNoLancamento> poucoFrequentes;

  int get presentes =>
      lista.where((a) => a.presente).length +
      poucoFrequentes.where((a) => a.presente).length;
}

/// Dias da semana (domingo a sábado) da data com aula regular ou reposição no quadro.
List<DiaDeAula> calcularDiasDeAulaDaSemana(
  String data,
  List<QuadroAulas> quadros,
  String hoje,
) {
  final indice = diasDaSemana.indexOf(obterDiaDaSemana(data));
  final domingo = somarDiasNaData(data, -indice);
  return [
    for (var i = 0; i < 7; i++)
      if (calcularTipoDoDia(somarDiasNaData(domingo, i), quadros)
          case final tipo when tipo != TipoDia.semAula)
        DiaDeAula(
          data: somarDiasNaData(domingo, i),
          tipo: tipo == TipoDia.regular ? TipoAula.regular : TipoAula.reposicao,
          futuro: ehDataFutura(somarDiasNaData(domingo, i), hoje),
        ),
  ];
}

class ConsultaLancamento {
  ConsultaLancamento(this._banco, this._repositorio);

  final BancoLocal _banco;
  final RepositorioPresenca _repositorio;

  /// Quantos dias de histórico entram na conta da frequência (folga sobre 52 aulas semanais).
  static const _diasDeHistorico = 400;

  Stream<List<Turma>> observarTurmas() =>
      (_banco.select(_banco.turmas)
            ..where((t) => t.excluido.equals(0))
            ..orderBy([(t) => OrderingTerm.asc(t.nome)]))
          .watch();

  Future<List<QuadroAulas>> obterQuadros(String turmaId) =>
      _repositorio.obterQuadrosDaTurma(turmaId);

  /// Recalcula sempre que o banco local muda (marcação ou dados novos do sync).
  Stream<DadosLancamento> observarLancamento(
    String turmaId,
    String data,
  ) async* {
    yield await obterLancamento(turmaId, data);
    await for (final _ in _banco.tableUpdates(
      TableUpdateQuery.onAllTables([
        _banco.turmas,
        _banco.quadrosAulas,
        _banco.alunos,
        _banco.matriculas,
        _banco.aulas,
        _banco.presencas,
      ]),
    )) {
      yield await obterLancamento(turmaId, data);
    }
  }

  Future<DadosLancamento> obterLancamento(String turmaId, String data) async {
    final turma = await (_banco.select(
      _banco.turmas,
    )..where((t) => t.id.equals(turmaId))).getSingle();
    final regras = jsonDecode(turma.regras);
    final parametros = ParametrosListaLancamento.lerJson(
      regras is Map ? regras['lista_lancamento'] : null,
    );
    final tipoDoDia = calcularTipoDoDia(data, await obterQuadros(turmaId));
    final tipo = switch (tipoDoDia) {
      TipoDia.regular => TipoAula.regular,
      TipoDia.reposicao => TipoAula.reposicao,
      TipoDia.semAula => null,
    };
    final aulaDoDia = tipo == null
        ? null
        : gerarIdAulaDoQuadro(turmaId, data, tipo);

    final inicioHistorico = somarDiasNaData(data, -_diasDeHistorico);
    final aulas =
        await (_banco.select(_banco.aulas)..where(
              (a) =>
                  a.turmaId.equals(turmaId) &
                  a.excluido.equals(0) &
                  a.dataAula.isBiggerOrEqualValue(inicioHistorico) &
                  a.dataAula.isSmallerOrEqualValue(data),
            ))
            .get();
    final idsAulas = aulas.map((a) => a.id).toList();
    final presencas = await (_banco.select(
      _banco.presencas,
    )..where((p) => p.aulaId.isIn(idsAulas) & p.excluido.equals(0))).get();
    final matriculas = await (_banco.select(
      _banco.matriculas,
    )..where((m) => m.turmaId.equals(turmaId) & m.excluido.equals(0))).get();
    final alunos =
        await (_banco.select(_banco.alunos)..where(
              (a) =>
                  a.id.isIn(matriculas.map((m) => m.alunoId).toSet()) &
                  a.excluido.equals(0),
            ))
            .get();

    final frequencias = calcularListaLancamento(
      data: data,
      parametros: parametros,
      aulas: [
        for (final a in aulas)
          AulaDaLista(id: a.id, data: a.dataAula, tipo: a.tipo),
      ],
      presencas: [
        for (final p in presencas) (aulaId: p.aulaId, alunoId: p.alunoId),
      ],
      alunos: [
        for (final a in alunos)
          AlunoDaLista(
            id: a.id,
            matriculas: [
              for (final m in matriculas)
                if (m.alunoId == a.id)
                  PeriodoMatricula(
                    dataInicio: m.dataInicio,
                    dataFim: m.dataFim,
                  ),
            ],
          ),
      ],
    );
    final presentesNoDia = {
      for (final p in presencas)
        if (p.aulaId == aulaDoDia) p.alunoId,
    };
    final alunoPorId = {for (final a in alunos) a.id: a};
    final todos = [
      for (final f in frequencias)
        AlunoNoLancamento(
          id: f.alunoId,
          codigo: alunoPorId[f.alunoId]!.codigo,
          nome: alunoPorId[f.alunoId]!.nome,
          frequencia: f,
          presente: presentesNoDia.contains(f.alunoId),
        ),
    ];
    int compararNome(AlunoNoLancamento a, AlunoNoLancamento b) =>
        a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
    return DadosLancamento(
      turmaNome: turma.nome,
      data: data,
      tipo: tipo,
      lista: todos.where((a) => a.estaNaLista).toList()
        ..sort((a, b) {
          final porFrequencia = b.frequencia.percentual.compareTo(
            a.frequencia.percentual,
          );
          return porFrequencia != 0 ? porFrequencia : compararNome(a, b);
        }),
      poucoFrequentes: todos.where((a) => !a.estaNaLista).toList()
        ..sort(compararNome),
    );
  }
}
