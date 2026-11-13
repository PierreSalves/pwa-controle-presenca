// Lista do lançamento: separa os alunos frequentes dos pouco frequentes (docs/telas/README.md).
// Espelho de api/src/regras/lista-lancamento.ts; casos em docs/casos-regras/lista-lancamento.json.
import 'presenca.dart';

class ParametrosListaLancamento {
  const ParametrosListaLancamento({
    required this.percentualMinimo,
    required this.ultimasAulas,
  });

  static const padrao = ParametrosListaLancamento(
    percentualMinimo: 30,
    ultimasAulas: 8,
  );

  /// Lê o objeto `lista_lancamento` das regras da turma; inválido ou ausente → padrão.
  factory ParametrosListaLancamento.lerJson(Object? valor) {
    if (valor is! Map) return padrao;
    final percentual = valor['percentual_minimo'];
    final aulas = valor['ultimas_aulas'];
    if (percentual is! int || percentual < 0 || percentual > 100) return padrao;
    if (aulas is! int || aulas < 1 || aulas > 52) return padrao;
    return ParametrosListaLancamento(
      percentualMinimo: percentual,
      ultimasAulas: aulas,
    );
  }

  final int percentualMinimo;
  final int ultimasAulas;
}

class AulaDaLista {
  const AulaDaLista({required this.id, required this.data, required this.tipo});
  final String id;
  final String data;
  final String tipo;
}

class PeriodoMatricula {
  const PeriodoMatricula({required this.dataInicio, this.dataFim});
  final String dataInicio;
  final String? dataFim;
}

class AlunoDaLista {
  const AlunoDaLista({required this.id, required this.matriculas});
  final String id;
  final List<PeriodoMatricula> matriculas;

  bool estaMatriculado(String data) => matriculas.any(
    (m) => estaMatriculadoNaData(
      data,
      dataInicio: m.dataInicio,
      dataFim: m.dataFim,
    ),
  );
}

class FrequenciaNaLista {
  const FrequenciaNaLista({
    required this.alunoId,
    required this.percentual,
    required this.novo,
    required this.frequente,
    required this.ultimaPresenca,
  });

  final String alunoId;

  /// Presenças ÷ aulas regulares consideradas, em % arredondado para baixo.
  final int percentual;

  /// Menos aulas que o parâmetro `ultimasAulas`: sempre aparece.
  final bool novo;
  final bool frequente;
  final String? ultimaPresenca;
}

/// Frequência de cada aluno matriculado na data, na ordem recebida.
List<FrequenciaNaLista> calcularListaLancamento({
  required String data,
  required ParametrosListaLancamento parametros,
  required List<AulaDaLista> aulas,
  required List<({String aulaId, String alunoId})> presencas,
  required List<AlunoDaLista> alunos,
}) {
  final dataDaAula = {for (final a in aulas) a.id: a.data};
  final presencasDoAluno = <String, Set<String>>{};
  for (final p in presencas) {
    if (!dataDaAula.containsKey(p.aulaId)) continue;
    presencasDoAluno.putIfAbsent(p.alunoId, () => {}).add(p.aulaId);
  }
  final regularesAnteriores =
      aulas
          .where((a) => a.tipo == 'regular' && a.data.compareTo(data) < 0)
          .toList()
        ..sort((a, b) => b.data.compareTo(a.data));

  return [
    for (final aluno in alunos)
      if (aluno.estaMatriculado(data))
        _calcularFrequencia(
          aluno,
          data,
          parametros,
          regularesAnteriores,
          presencasDoAluno[aluno.id] ?? const {},
          dataDaAula,
        ),
  ];
}

FrequenciaNaLista _calcularFrequencia(
  AlunoDaLista aluno,
  String data,
  ParametrosListaLancamento parametros,
  List<AulaDaLista> regularesAnteriores,
  Set<String> presencas,
  Map<String, String> dataDaAula,
) {
  final consideradas = regularesAnteriores
      .where((a) => aluno.estaMatriculado(a.data))
      .take(parametros.ultimasAulas)
      .toList();
  final presentes = consideradas.where((a) => presencas.contains(a.id)).length;
  final novo = consideradas.length < parametros.ultimasAulas;
  final percentual = consideradas.isEmpty
      ? 0
      : (presentes * 100) ~/ consideradas.length;
  String? ultima;
  for (final aulaId in presencas) {
    final d = dataDaAula[aulaId]!;
    if (d.compareTo(data) <= 0 && (ultima == null || d.compareTo(ultima) > 0)) {
      ultima = d;
    }
  }
  return FrequenciaNaLista(
    alunoId: aluno.id,
    percentual: percentual,
    novo: novo,
    frequente: novo || percentual >= parametros.percentualMinimo,
    ultimaPresenca: ultima,
  );
}
