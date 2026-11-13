import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// A Roboto embutida cobre o Latim (com acentos) e a pontuação comum. Um caractere fora dela (ex.:
// ✓, →, emoji) aparece como um quadrado: sem internet o Flutter não acha fonte de reserva, e a CSP
// bloqueia o Google. Para esses símbolos, usar um ícone.
const _permitidosForaDoLatim1 = {'—', '–', '…', '‘', '’', '“', '”', '•'};

bool _ehPermitido(int codigo) =>
    codigo <= 0xFF ||
    _permitidosForaDoLatim1.contains(String.fromCharCode(codigo));

void main() {
  test('textos do app só usam caracteres que a fonte embutida tem', () {
    final problemas = <String>[];
    final arquivos = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'));
    for (final arquivo in arquivos) {
      final linhas = arquivo.readAsLinesSync();
      for (var i = 0; i < linhas.length; i++) {
        final linha = linhas[i];
        if (linha.trimLeft().startsWith('//')) continue;
        final codigo = linha.split('//').first;
        for (final c in codigo.runes) {
          if (!_ehPermitido(c)) {
            problemas.add(
              '${arquivo.path}:${i + 1}: "${String.fromCharCode(c)}" (U+${c.toRadixString(16).toUpperCase()})',
            );
          }
        }
      }
    }
    expect(problemas, isEmpty);
  });
}
