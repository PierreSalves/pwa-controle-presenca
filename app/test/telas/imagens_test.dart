import 'dart:convert';
import 'dart:typed_data';

import 'package:controle_presenca/plataforma/imagens.dart';
import 'package:controle_presenca/telas/relatorios/html_relatorio.dart';
import 'package:controle_presenca/telas/relatorios/montar_relatorio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tipo da imagem pelos primeiros bytes, como na API', () {
    final png = Uint8List.fromList([
      0x89,
      0x50,
      0x4e,
      0x47,
      0x0d,
      0x0a,
      0x1a,
      0x0a,
      0,
    ]);
    final jpeg = Uint8List.fromList([0xff, 0xd8, 0xff, 0xe0]);
    expect(detectarTipoImagem(png), TipoImagem.png);
    expect(detectarTipoImagem(jpeg), TipoImagem.jpeg);
    expect(detectarTipoImagem(utf8.encode('<svg/>')), isNull);
    expect(detectarTipoImagem(Uint8List(0)), isNull);
  });

  test('página impressa leva o ícone da academia embutido', () {
    final icone = Uint8List.fromList([1, 2, 3]);
    CabecalhoImpressao cabecalho({Uint8List? logotipo}) => CabecalhoImpressao(
      academia: 'Academia Teste',
      cabecalhoAcademia: null,
      turma: 'Adulto',
      cabecalhoTurma: null,
      geradoEm: DateTime.utc(2026, 11, 13, 13),
      geradoPor: 'Ana (professor)',
      logotipo: logotipo,
    );
    const relatorio = RelatorioMontado(
      tipo: TipoRelatorio.graduacao,
      periodo: '2º sem. 2026',
      rotuloPrimeiraColuna: 'Aluno',
      colunas: [],
      linhas: [],
    );
    expect(
      gerarHtmlRelatorio(relatorio, cabecalho(logotipo: icone)),
      contains('<img src="data:image/png;base64,${base64Encode(icone)}"'),
    );
    expect(gerarHtmlRelatorio(relatorio, cabecalho()), isNot(contains('<img')));
  });
}
