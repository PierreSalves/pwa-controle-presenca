// Formatos de exibição (pt-BR). As datas internas continuam AAAA-MM-DD.
import '../regras/presenca.dart';

const _diasAbreviados = {
  'domingo': 'dom',
  'segunda': 'seg',
  'terca': 'ter',
  'quarta': 'qua',
  'quinta': 'qui',
  'sexta': 'sex',
  'sabado': 'sáb',
};

/// '2026-11-11' → '11/11'.
String formatarDiaMes(String data) =>
    '${data.substring(8, 10)}/${data.substring(5, 7)}';

/// '2026-11-11' → '11/11/2026'.
String formatarDataBr(String data) =>
    '${formatarDiaMes(data)}/${data.substring(0, 4)}';

/// '2026-11-11' → 'qua'.
String obterDiaAbreviado(String data) =>
    _diasAbreviados[obterDiaDaSemana(data)]!;

/// Hora em São Paulo (UTC−3, sem horário de verão desde 2019): '14:32'.
String formatarHora(DateTime instante) {
  final local = instante.toUtc().subtract(const Duration(hours: 3));
  return '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

/// Data em São Paulo (UTC−3) de um instante: '13/11/2026'.
String formatarDataDoInstante(DateTime instante) {
  final local = instante.toUtc().subtract(const Duration(hours: 3));
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/${local.year}';
}

/// '(10A) Ana Souza'.
String formatarAluno(String codigo, String nome) => '($codigo) $nome';

/// Minúsculas e sem acentos, para a busca.
String normalizarBusca(String texto) {
  const deParaAcentos = {
    'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', //
    'é': 'e', 'ê': 'e', 'è': 'e', 'ë': 'e', //
    'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i', //
    'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', //
    'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', 'ç': 'c', 'ñ': 'n',
  };
  final minusculo = texto.toLowerCase();
  return String.fromCharCodes(
    minusculo.runes.map(
      (r) => (deParaAcentos[String.fromCharCode(r)] ?? String.fromCharCode(r))
          .codeUnitAt(0),
    ),
  ).trim();
}
