// Leitura do banco local para o Início (tela 2) e a frequência do semestre (tela 6): turmas do
// usuário, resumo do ano, alunos abaixo do mínimo e alunos sumidos. Tudo calculado das presenças
// (nenhum total gravado) e disponível offline.
import 'dart:convert';

import 'package:drift/drift.dart';

import '../regras/frequencia.dart';
import '../regras/lista_lancamento.dart';
import '../regras/presenca.dart';
import 'banco_local.dart';

class TurmaNoInicio {
  const TurmaNoInicio({
    required this.id,
    required this.nome,
    required this.diasDeAula,
    required this.alunos,
  });
  final String id;
  final String nome;

  /// Dias regulares do quadro vigente hoje, na ordem da semana ('ter', 'qua', ...).
  final List<String> diasDeAula;

  /// Matriculados hoje.
  final int alunos;
}

class AlunoComFrequencia {
  const AlunoComFrequencia({
    required this.turmaId,
    required this.alunoId,
    required this.codigo,
    required this.nome,
    required this.frequencia,
  });
  final String turmaId;
  final String alunoId;
  final String codigo;
  final String nome;
  final FrequenciaNoPeriodo frequencia;
}

class AlunoSumidoNoInicio {
  const AlunoSumidoNoInicio({
    required this.turmaId,
    required this.turmaNome,
    required this.matriculaId,
    required this.dataInicioMatricula,
    required this.codigo,
    required this.nome,
    required this.ultimaPresenca,
  });
  final String turmaId;
  final String turmaNome;
  final String matriculaId;
  final String dataInicioMatricula;
  final String codigo;
  final String nome;
  final String? ultimaPresenca;
}

class DadosInicio {
  const DadosInicio({
    required this.ano,
    required this.turmas,
    required this.aulasNoAno,
    required this.frequenciaMediaNoAno,
    required this.abaixoDoMinimo,
    required this.sumidos,
    required this.semanasSumido,
  });

  final int ano;
  final List<TurmaNoInicio> turmas;

  /// Aulas regulares lançadas no ano até hoje, somando as turmas.
  final int aulasNoAno;

  /// Média das frequências do ano dos alunos matriculados hoje; null sem aulas.
  final int? frequenciaMediaNoAno;

  /// Abaixo da frequência mínima da turma no semestre (graduação).
  final List<AlunoComFrequencia> abaixoDoMinimo;
  final List<AlunoSumidoNoInicio> sumidos;

  /// Prazo de sumido (o maior entre as turmas, para o texto do aviso).
  final int semanasSumido;
}

class DadosFrequenciaSemestre {
  const DadosFrequenciaSemestre({
    required this.turmaNome,
    required this.inicio,
    required this.fim,
    required this.minimo,
    required this.alunos,
  });
  final String turmaNome;
  final String inicio;
  final String fim;
  final int? minimo;

  /// Por código.
  final List<AlunoComFrequencia> alunos;
}

/// Compara códigos de aluno com números na ordem natural ('2' < '10' < '10A').
int compararCodigos(String a, String b) {
  final na = int.tryParse(RegExp(r'^\d+').stringMatch(a) ?? '');
  final nb = int.tryParse(RegExp(r'^\d+').stringMatch(b) ?? '');
  if (na != null && nb != null && na != nb) return na.compareTo(nb);
  return a.compareTo(b);
}

/// Dados de uma turma num intervalo de datas, já no formato das regras.
class _DadosDaTurma {
  _DadosDaTurma(this.turma, this.aulas, this.presencas, this.alunos);
  final Turma turma;
  final List<AulaDaLista> aulas;
  final List<PresencaDaRegra> presencas;
  final Map<String, Aluno> alunos;
  final Map<String, List<Matricula>> matriculasPorAluno = {};

  List<AlunoDaLista> converterAlunos() => [
    for (final entrada in matriculasPorAluno.entries)
      AlunoDaLista(
        id: entrada.key,
        matriculas: [
          for (final m in entrada.value)
            PeriodoMatricula(dataInicio: m.dataInicio, dataFim: m.dataFim),
        ],
      ),
  ];

  int obterSemanasSumido() {
    final regras = jsonDecode(turma.regras);
    final sumidos = regras is Map ? regras['alunos_sumidos'] : null;
    final semanas = sumidos is Map ? sumidos['semanas'] : null;
    return semanas is int && semanas >= 1 && semanas <= 52 ? semanas : 4;
  }
}

class ConsultaInicio {
  ConsultaInicio(this._banco);

  final BancoLocal _banco;

  Stream<T> _observar<T>(Future<T> Function() obter) async* {
    yield await obter();
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
      yield await obter();
    }
  }

  Future<_DadosDaTurma> _obterDadosDaTurma(
    Turma turma,
    String desde,
    String ate,
  ) async {
    final aulas =
        await (_banco.select(_banco.aulas)..where(
              (a) =>
                  a.turmaId.equals(turma.id) &
                  a.excluido.equals(0) &
                  a.dataAula.isBetweenValues(desde, ate),
            ))
            .get();
    final presencas =
        await (_banco.select(_banco.presencas)..where(
              (p) =>
                  p.aulaId.isIn(aulas.map((a) => a.id)) & p.excluido.equals(0),
            ))
            .get();
    final matriculas = await (_banco.select(
      _banco.matriculas,
    )..where((m) => m.turmaId.equals(turma.id) & m.excluido.equals(0))).get();
    final alunos =
        await (_banco.select(_banco.alunos)..where(
              (a) =>
                  a.id.isIn(matriculas.map((m) => m.alunoId).toSet()) &
                  a.excluido.equals(0),
            ))
            .get();
    final dados = _DadosDaTurma(
      turma,
      [
        for (final a in aulas)
          AulaDaLista(id: a.id, data: a.dataAula, tipo: a.tipo),
      ],
      [for (final p in presencas) (aulaId: p.aulaId, alunoId: p.alunoId)],
      {for (final a in alunos) a.id: a},
    );
    for (final m in matriculas) {
      if (!dados.alunos.containsKey(m.alunoId)) continue;
      dados.matriculasPorAluno.putIfAbsent(m.alunoId, () => []).add(m);
    }
    return dados;
  }

  Future<List<Turma>> _obterTurmas() =>
      (_banco.select(_banco.turmas)
            ..where((t) => t.excluido.equals(0))
            ..orderBy([(t) => OrderingTerm.asc(t.nome)]))
          .get();

  Future<List<String>> _obterDiasDeAula(String turmaId, String hoje) async {
    final quadros = await (_banco.select(
      _banco.quadrosAulas,
    )..where((q) => q.turmaId.equals(turmaId) & q.excluido.equals(0))).get();
    final vigentes =
        quadros
            .where(
              (q) =>
                  q.vigenciaInicio.compareTo(hoje) <= 0 &&
                  (q.vigenciaFim == null ||
                      q.vigenciaFim!.compareTo(hoje) >= 0),
            )
            .toList()
          ..sort((a, b) => b.vigenciaInicio.compareTo(a.vigenciaInicio));
    if (vigentes.isEmpty) return const [];
    final q = vigentes.first;
    final valores = [
      q.domingo,
      q.segunda,
      q.terca,
      q.quarta,
      q.quinta,
      q.sexta,
      q.sabado,
    ];
    const abreviados = ['dom', 'seg', 'ter', 'qua', 'qui', 'sex', 'sáb'];
    return [
      for (var i = 0; i < 7; i++)
        if (valores[i] == 1) abreviados[i],
    ];
  }

  Stream<DadosInicio> observarInicio(String hoje) =>
      _observar(() => obterInicio(hoje));

  Future<DadosInicio> obterInicio(String hoje) async {
    final inicioAno = '${hoje.substring(0, 4)}-01-01';
    final inicioSemestre = calcularInicioDoSemestre(hoje);
    final turmas = <TurmaNoInicio>[];
    final abaixo = <AlunoComFrequencia>[];
    final sumidos = <AlunoSumidoNoInicio>[];
    final percentuaisAno = <int>[];
    var aulasNoAno = 0;
    var semanasSumido = 0;

    for (final turma in await _obterTurmas()) {
      // Os sumidos olham presenças anteriores ao ano (a última pode ser de dezembro).
      final dados = await _obterDadosDaTurma(
        turma,
        somarDiasNaData(hoje, -400),
        hoje,
      );
      final alunos = dados.converterAlunos();
      final doAno = calcularFrequenciaNoPeriodo(
        inicio: inicioAno,
        fim: hoje,
        minimo: null,
        aulas: dados.aulas,
        presencas: dados.presencas,
        alunos: alunos,
      );
      turmas.add(
        TurmaNoInicio(
          id: turma.id,
          nome: turma.nome,
          diasDeAula: await _obterDiasDeAula(turma.id, hoje),
          alunos: doAno.length,
        ),
      );
      aulasNoAno += dados.aulas
          .where((a) => a.tipo == 'regular' && a.data.compareTo(inicioAno) >= 0)
          .length;
      percentuaisAno.addAll(doAno.map((f) => f.percentual).whereType<int>());

      final doSemestre = calcularFrequenciaNoPeriodo(
        inicio: inicioSemestre,
        fim: hoje,
        minimo: turma.frequenciaMinima,
        aulas: dados.aulas,
        presencas: dados.presencas,
        alunos: alunos,
      );
      for (final f in doSemestre.where((f) => f.abaixoDoMinimo)) {
        final aluno = dados.alunos[f.alunoId]!;
        abaixo.add(
          AlunoComFrequencia(
            turmaId: turma.id,
            alunoId: f.alunoId,
            codigo: aluno.codigo,
            nome: aluno.nome,
            frequencia: f,
          ),
        );
      }

      final semanas = dados.obterSemanasSumido();
      if (semanas > semanasSumido) semanasSumido = semanas;
      final sumidosDaTurma = calcularAlunosSumidos(
        hoje: hoje,
        semanas: semanas,
        aulas: dados.aulas,
        presencas: dados.presencas,
        alunos: [
          for (final entrada in dados.matriculasPorAluno.entries)
            (
              id: entrada.key,
              matriculas: [
                for (final m in entrada.value)
                  MatriculaDoAluno(
                    id: m.id,
                    dataInicio: m.dataInicio,
                    dataFim: m.dataFim,
                  ),
              ],
            ),
        ],
      );
      for (final s in sumidosDaTurma) {
        final aluno = dados.alunos[s.alunoId]!;
        final matricula = dados.matriculasPorAluno[s.alunoId]!.firstWhere(
          (m) => m.id == s.matriculaId,
        );
        sumidos.add(
          AlunoSumidoNoInicio(
            turmaId: turma.id,
            turmaNome: turma.nome,
            matriculaId: s.matriculaId,
            dataInicioMatricula: matricula.dataInicio,
            codigo: aluno.codigo,
            nome: aluno.nome,
            ultimaPresenca: s.ultimaPresenca,
          ),
        );
      }
    }

    sumidos.sort(
      (a, b) => (a.ultimaPresenca ?? a.dataInicioMatricula).compareTo(
        b.ultimaPresenca ?? b.dataInicioMatricula,
      ),
    );
    return DadosInicio(
      ano: int.parse(hoje.substring(0, 4)),
      turmas: turmas,
      aulasNoAno: aulasNoAno,
      frequenciaMediaNoAno: percentuaisAno.isEmpty
          ? null
          : (percentuaisAno.reduce((a, b) => a + b) / percentuaisAno.length)
                .floor(),
      abaixoDoMinimo: abaixo,
      sumidos: sumidos,
      semanasSumido: semanasSumido == 0 ? 4 : semanasSumido,
    );
  }

  Stream<DadosFrequenciaSemestre> observarFrequenciaSemestre(
    String turmaId,
    String hoje,
  ) => _observar(() => obterFrequenciaSemestre(turmaId, hoje));

  /// Tela 6: frequência no semestre da data, até a data, de cada matriculado.
  Future<DadosFrequenciaSemestre> obterFrequenciaSemestre(
    String turmaId,
    String data,
  ) async {
    final turma = await (_banco.select(
      _banco.turmas,
    )..where((t) => t.id.equals(turmaId))).getSingle();
    final inicio = calcularInicioDoSemestre(data);
    final dados = await _obterDadosDaTurma(turma, inicio, data);
    final frequencias = calcularFrequenciaNoPeriodo(
      inicio: inicio,
      fim: data,
      minimo: turma.frequenciaMinima,
      aulas: dados.aulas,
      presencas: dados.presencas,
      alunos: dados.converterAlunos(),
    );
    return DadosFrequenciaSemestre(
      turmaNome: turma.nome,
      inicio: inicio,
      fim: data,
      minimo: turma.frequenciaMinima,
      alunos: [
        for (final f in frequencias)
          AlunoComFrequencia(
            turmaId: turmaId,
            alunoId: f.alunoId,
            codigo: dados.alunos[f.alunoId]!.codigo,
            nome: dados.alunos[f.alunoId]!.nome,
            frequencia: f,
          ),
      ]..sort((a, b) => compararCodigos(a.codigo, b.codigo)),
    );
  }
}
