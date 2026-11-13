// Relatórios da tela 7 (docs/telas/wireframes-relatorios.html): tudo calculado na hora a partir
// das aulas lançadas e das presenças; nenhum total é gravado.
// Falta = aula lançada sem presença do aluno, dentro da matrícula. Frequência = a mesma regra da
// graduação (frequencia.dart): presenças + reposições ÷ aulas regulares lançadas, limite de 100%.
import 'frequencia.dart';
import 'lista_lancamento.dart';
import 'presenca.dart';

enum MarcaPresenca { veio, faltou, foraDaMatricula }

class AlunoDoRelatorio extends AlunoDaLista {
  const AlunoDoRelatorio({
    required super.id,
    required super.matriculas,
    required this.codigo,
    required this.nome,
  });
  final String codigo;
  final String nome;

  /// Tem matrícula em algum dia entre [inicio] e [fim] (inclusive).
  bool estaMatriculadoEntre(String inicio, String fim) => matriculas.any(
    (m) =>
        m.dataInicio.compareTo(fim) <= 0 &&
        (m.dataFim == null || m.dataFim!.compareTo(inicio) >= 0),
  );
}

/// Aulas, alunos e presenças da turma; os relatórios recortam o período que precisam.
class BaseRelatorio {
  BaseRelatorio({
    required List<AulaDaLista> aulas,
    required List<AlunoDoRelatorio> alunos,
    required List<PresencaDaRegra> presencas,
    required this.minimo,
  }) : aulas = [...aulas]..sort(_compararAulas),
       alunos = [...alunos]
         ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase())),
       _presentes = {for (final p in presencas) '${p.aulaId}|${p.alunoId}'},
       _presencas = presencas;

  /// Por data; no mesmo dia, a regular antes da reposição.
  final List<AulaDaLista> aulas;

  /// Por nome.
  final List<AlunoDoRelatorio> alunos;
  final int? minimo;
  final Set<String> _presentes;
  final List<PresencaDaRegra> _presencas;

  static int _compararAulas(AulaDaLista a, AulaDaLista b) {
    final porData = a.data.compareTo(b.data);
    if (porData != 0) return porData;
    return (a.tipo == 'regular' ? 0 : 1) - (b.tipo == 'regular' ? 0 : 1);
  }

  bool estaPresente(AlunoDoRelatorio aluno, AulaDaLista aula) =>
      _presentes.contains('${aula.id}|${aluno.id}');

  MarcaPresenca calcularMarca(AlunoDoRelatorio aluno, AulaDaLista aula) =>
      !aluno.estaMatriculado(aula.data)
      ? MarcaPresenca.foraDaMatricula
      : estaPresente(aluno, aula)
      ? MarcaPresenca.veio
      : MarcaPresenca.faltou;

  List<AulaDaLista> obterAulasEntre(String inicio, String fim) => [
    for (final a in aulas)
      if (a.data.compareTo(inicio) >= 0 && a.data.compareTo(fim) <= 0) a,
  ];

  List<AlunoDoRelatorio> obterAlunosEntre(String inicio, String fim) => [
    for (final a in alunos)
      if (a.estaMatriculadoEntre(inicio, fim)) a,
  ];

  /// Quantas vezes o aluno veio nas aulas (regulares e reposições), dentro da matrícula.
  int contarPresencas(AlunoDoRelatorio aluno, Iterable<AulaDaLista> aulas) =>
      aulas.where((a) => calcularMarca(aluno, a) == MarcaPresenca.veio).length;

  FrequenciaNoPeriodo calcularFrequencia(
    AlunoDoRelatorio aluno,
    String inicio,
    String fim,
  ) => calcularFrequenciaDoAluno(aluno, obterAulasEntre(inicio, fim), {
    for (final p in _presencas)
      if (p.alunoId == aluno.id) p.aulaId,
  }, minimo);
}

// --- Presença semanal (7a, D5) ---

class SemanaDoRelatorio {
  const SemanaDoRelatorio({
    required this.ordem,
    required this.domingo,
    required this.aulas,
  });

  /// 1ª, 2ª... dentro do período.
  final int ordem;
  final String domingo;
  final List<AulaDaLista> aulas;

  String get sabado => somarDiasNaData(domingo, 6);
}

/// Semanas (domingo a sábado) do período que têm aula lançada.
List<SemanaDoRelatorio> calcularSemanas(
  BaseRelatorio base,
  String inicio,
  String fim,
) {
  final porDomingo = <String, List<AulaDaLista>>{};
  for (final aula in base.obterAulasEntre(inicio, fim)) {
    final domingo = somarDiasNaData(
      aula.data,
      -diasDaSemana.indexOf(obterDiaDaSemana(aula.data)),
    );
    porDomingo.putIfAbsent(domingo, () => []).add(aula);
  }
  final domingos = porDomingo.keys.toList()..sort();
  return [
    for (var i = 0; i < domingos.length; i++)
      SemanaDoRelatorio(
        ordem: i + 1,
        domingo: domingos[i],
        aulas: porDomingo[domingos[i]]!,
      ),
  ];
}

// --- Presença mensal (7b) e anual (7c, D6) ---

/// Meses (AAAA-MM) de [inicio] a [fim], inclusive.
List<String> calcularMeses(String inicio, String fim) {
  final meses = <String>[];
  var ano = int.parse(inicio.substring(0, 4));
  var mes = int.parse(inicio.substring(5, 7));
  final ultimo = fim.substring(0, 7);
  while (true) {
    final atual = '$ano-${mes.toString().padLeft(2, '0')}';
    if (atual.compareTo(ultimo) > 0) break;
    meses.add(atual);
    mes++;
    if (mes == 13) {
      mes = 1;
      ano++;
    }
  }
  return meses;
}

List<AulaDaLista> obterAulasDoMes(List<AulaDaLista> aulas, String mes) => [
  for (final a in aulas)
    if (a.data.startsWith(mes)) a,
];

/// Aulas regulares lançadas (a linha "Aulas" dos relatórios mensal e anual).
int contarAulasRegulares(Iterable<AulaDaLista> aulas) =>
    aulas.where((a) => a.tipo == 'regular').length;

/// Mês ainda não começado em relação a [hoje] (mostrado como "–").
bool ehMesFuturo(String mes, String hoje) =>
    mes.compareTo(hoje.substring(0, 7)) > 0;

// --- Por aluno (7d) ---

typedef AulaDoAluno = ({AulaDaLista aula, bool veio});

/// Aulas do período dentro da matrícula do aluno, da mais recente para a mais antiga.
List<AulaDoAluno> calcularAulasDoAluno(
  BaseRelatorio base,
  AlunoDoRelatorio aluno,
  String inicio,
  String fim,
) => [
  for (final aula in base.obterAulasEntre(inicio, fim).reversed)
    if (aluno.estaMatriculado(aula.data))
      (aula: aula, veio: base.estaPresente(aluno, aula)),
];
