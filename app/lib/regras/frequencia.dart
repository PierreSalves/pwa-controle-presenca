// Frequência no período (graduação e resumo do ano) e alunos sumidos.
// Espelho de api/src/regras/frequencia.ts; casos em docs/casos-regras/frequencia.json.
import 'lista_lancamento.dart';
import 'presenca.dart';

class FrequenciaNoPeriodo {
  const FrequenciaNoPeriodo({
    required this.alunoId,
    required this.aulas,
    required this.presencas,
    required this.reposicoes,
    required this.percentual,
    required this.abaixoDoMinimo,
  });

  final String alunoId;

  /// Aulas regulares lançadas no período, dentro da matrícula.
  final int aulas;

  /// Presenças nessas aulas regulares.
  final int presencas;

  /// Presenças em reposições no período, dentro da matrícula.
  final int reposicoes;

  /// (presenças + reposições) ÷ aulas, em % arredondado para baixo e limitado a 100; null sem aulas.
  final int? percentual;
  final bool abaixoDoMinimo;
}

typedef PresencaDaRegra = ({String aulaId, String alunoId});

/// Semestre da graduação: jan–jun ou jul–dez.
String calcularInicioDoSemestre(String data) =>
    '${data.substring(0, 4)}-${int.parse(data.substring(5, 7)) <= 6 ? '01' : '07'}-01';

Map<String, Set<String>> _agruparPresencas(List<PresencaDaRegra> presencas) {
  final porAluno = <String, Set<String>>{};
  for (final p in presencas) {
    porAluno.putIfAbsent(p.alunoId, () => {}).add(p.aulaId);
  }
  return porAluno;
}

/// Frequência dos alunos matriculados no dia [fim], na ordem recebida.
List<FrequenciaNoPeriodo> calcularFrequenciaNoPeriodo({
  required String inicio,
  required String fim,
  required int? minimo,
  required List<AulaDaLista> aulas,
  required List<PresencaDaRegra> presencas,
  required List<AlunoDaLista> alunos,
}) {
  final doPeriodo = aulas
      .where((a) => a.data.compareTo(inicio) >= 0 && a.data.compareTo(fim) <= 0)
      .toList();
  final presencasDoAluno = _agruparPresencas(presencas);
  return [
    for (final aluno in alunos)
      if (aluno.estaMatriculado(fim))
        _calcularFrequenciaDoAluno(
          aluno,
          doPeriodo,
          presencasDoAluno[aluno.id] ?? const {},
          minimo,
        ),
  ];
}

FrequenciaNoPeriodo _calcularFrequenciaDoAluno(
  AlunoDaLista aluno,
  List<AulaDaLista> doPeriodo,
  Set<String> presentes,
  int? minimo,
) {
  final naMatricula = doPeriodo.where((a) => aluno.estaMatriculado(a.data));
  final regulares = naMatricula.where((a) => a.tipo == 'regular').toList();
  final presencas = regulares.where((a) => presentes.contains(a.id)).length;
  final reposicoes = naMatricula
      .where((a) => a.tipo == 'reposicao' && presentes.contains(a.id))
      .length;
  final percentual = regulares.isEmpty
      ? null
      : (((presencas + reposicoes) * 100) ~/ regulares.length).clamp(0, 100);
  return FrequenciaNoPeriodo(
    alunoId: aluno.id,
    aulas: regulares.length,
    presencas: presencas,
    reposicoes: reposicoes,
    percentual: percentual,
    abaixoDoMinimo: percentual != null && minimo != null && percentual < minimo,
  );
}

class MatriculaDoAluno extends PeriodoMatricula {
  const MatriculaDoAluno({
    required this.id,
    required super.dataInicio,
    super.dataFim,
  });
  final String id;
}

class AlunoSumido {
  const AlunoSumido({
    required this.alunoId,
    required this.matriculaId,
    required this.ultimaPresenca,
  });
  final String alunoId;
  final String matriculaId;
  final String? ultimaPresenca;
}

/// Matrícula aberta (sem data de fim) no dia [hoje] cuja última presença — ou o início da
/// matrícula, se o aluno nunca veio — é anterior a [semanas] × 7 dias.
List<AlunoSumido> calcularAlunosSumidos({
  required String hoje,
  required int semanas,
  required List<AulaDaLista> aulas,
  required List<PresencaDaRegra> presencas,
  required List<({String id, List<MatriculaDoAluno> matriculas})> alunos,
}) {
  final limite = somarDiasNaData(hoje, -semanas * 7);
  final dataDaAula = {for (final a in aulas) a.id: a.data};
  final presencasDoAluno = _agruparPresencas(presencas);
  final resultado = <AlunoSumido>[];
  for (final aluno in alunos) {
    final abertas = aluno.matriculas.where(
      (m) => m.dataFim == null && m.dataInicio.compareTo(hoje) <= 0,
    );
    if (abertas.isEmpty) continue;
    final aberta = abertas.first;
    String? ultima;
    for (final aulaId in presencasDoAluno[aluno.id] ?? const <String>{}) {
      final d = dataDaAula[aulaId];
      if (d != null &&
          d.compareTo(hoje) <= 0 &&
          (ultima == null || d.compareTo(ultima) > 0)) {
        ultima = d;
      }
    }
    if ((ultima ?? aberta.dataInicio).compareTo(limite) < 0) {
      resultado.add(
        AlunoSumido(
          alunoId: aluno.id,
          matriculaId: aberta.id,
          ultimaPresenca: ultima,
        ),
      );
    }
  }
  return resultado;
}
