// Regras de presença. Espelho de api/src/regras/presenca.ts: os casos de teste ficam em
// docs/casos-regras/presenca.json e rodam nos dois lados, para as regras nunca divergirem.
import 'dart:convert';

import 'package:crypto/crypto.dart';

const diasDaSemana = [
  'domingo',
  'segunda',
  'terca',
  'quarta',
  'quinta',
  'sexta',
  'sabado',
];

enum TipoDia { semAula, regular, reposicao }

enum TipoAula {
  regular('regular'),
  reposicao('reposicao');

  const TipoAula(this.valor);
  final String valor;
}

class QuadroAulas {
  const QuadroAulas({
    required this.vigenciaInicio,
    required this.vigenciaFim,
    required this.dias,
  });

  final String vigenciaInicio;
  final String? vigenciaFim;

  /// Dia da semana → 0 sem aula, 1 regular, 2 reposição.
  final Map<String, int> dias;
}

final _padraoData = RegExp(r'^\d{4}-\d{2}-\d{2}$');

DateTime _converterEmUtc(String data) {
  final partes = data.split('-').map(int.parse).toList();
  return DateTime.utc(partes[0], partes[1], partes[2]);
}

/// Data de calendário válida no formato AAAA-MM-DD.
bool ehDataValida(String data) {
  if (!_padraoData.hasMatch(data)) return false;
  final partes = data.split('-').map(int.parse).toList();
  final d = DateTime.utc(partes[0], partes[1], partes[2]);
  return d.year == partes[0] && d.month == partes[1] && d.day == partes[2];
}

String formatarData(DateTime data) =>
    '${data.year.toString().padLeft(4, '0')}-'
    '${data.month.toString().padLeft(2, '0')}-'
    '${data.day.toString().padLeft(2, '0')}';

/// Soma (ou subtrai) dias a uma data AAAA-MM-DD.
String somarDiasNaData(String data, int dias) =>
    formatarData(_converterEmUtc(data).add(Duration(days: dias)));

String obterDiaDaSemana(String data) =>
    diasDaSemana[_converterEmUtc(data).weekday % 7];

/// Dia de hoje (AAAA-MM-DD) em America/Sao_Paulo. O Brasil não tem horário de verão desde 2019,
/// então o fuso é UTC−3 fixo.
String obterHojeEmSaoPaulo([DateTime? instante]) {
  final utc = (instante ?? DateTime.now()).toUtc();
  return formatarData(utc.subtract(const Duration(hours: 3)));
}

bool ehDataFutura(String data, String hoje) => data.compareTo(hoje) > 0;

bool estaMatriculadoNaData(
  String data, {
  required String dataInicio,
  required String? dataFim,
}) =>
    dataInicio.compareTo(data) <= 0 &&
    (dataFim == null || data.compareTo(dataFim) <= 0);

/// Tipo do dia segundo o quadro vigente na data (o mais recente que cobre a data).
TipoDia calcularTipoDoDia(String data, List<QuadroAulas> quadros) {
  final vigentes =
      quadros
          .where(
            (q) =>
                q.vigenciaInicio.compareTo(data) <= 0 &&
                (q.vigenciaFim == null || data.compareTo(q.vigenciaFim!) <= 0),
          )
          .toList()
        ..sort((a, b) => b.vigenciaInicio.compareTo(a.vigenciaInicio));
  if (vigentes.isEmpty) return TipoDia.semAula;
  return switch (vigentes.first.dias[obterDiaDaSemana(data)]) {
    1 => TipoDia.regular,
    2 => TipoDia.reposicao,
    _ => TipoDia.semAula,
  };
}

// Namespace fixo do projeto para os UUID v5 das aulas (não mudar: a API usa o mesmo).
const _namespaceAulas = '6f1c2b8e-4a3d-5e7f-9b0a-1c2d3e4f5a6b';

List<int> _converterUuidEmBytes(String uuid) {
  final hex = uuid.replaceAll('-', '');
  return [
    for (var i = 0; i < 16; i++)
      int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16),
  ];
}

/// Id determinístico (UUID v5) de uma aula do quadro: regular ou reposição fixa.
/// Dois aparelhos offline que abrem a mesma aula geram o mesmo id.
String gerarIdAulaDoQuadro(String turmaId, String dataAula, TipoAula tipo) {
  final entrada = [
    ..._converterUuidEmBytes(_namespaceAulas),
    ...utf8.encode('$turmaId|$dataAula|${tipo.valor}'),
  ];
  final hash = sha1.convert(entrada).bytes.sublist(0, 16);
  hash[6] = (hash[6] & 0x0f) | 0x50;
  hash[8] = (hash[8] & 0x3f) | 0x80;
  final hex = hash.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-'
      '${hex.substring(16, 20)}-${hex.substring(20)}';
}
