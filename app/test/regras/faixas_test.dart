import 'dart:convert';
import 'dart:io';

import 'package:controle_presenca/regras/faixas.dart';
import 'package:flutter_test/flutter_test.dart';

// Mesmos casos usados na API (TypeScript): docs/casos-regras/faixas.json
void main() {
  final casos = jsonDecode(
    File('../docs/casos-regras/faixas.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  List<Map<String, dynamic>> lista(dynamic valor) =>
      (valor as List).cast<Map<String, dynamic>>();

  group('faixas e graus (casos compartilhados)', () {
    for (final caso in lista(casos['limites_do_grau'])) {
      test('limites do grau na faixa ${caso['faixa']}', () {
        final esperado = (caso['esperado'] as List?)?.cast<int>();
        final limites = obterLimitesGrau(caso['faixa'] as String);
        expect(limites == null ? null : [limites.$1, limites.$2], esperado);
      });
    }

    for (final caso in lista(casos['graduacao_valida'])) {
      test(
        '${caso['faixa']}, grau ${caso['grau']}, ponteira ${caso['ponteira']}',
        () {
          expect(
            ehGraduacaoValida(
              caso['faixa'] as String,
              caso['grau'] as int,
              caso['ponteira'] as String?,
            ),
            caso['esperado'],
          );
        },
      );
    }

    for (final caso in lista(casos['grau_ajustado'])) {
      test('grau ${caso['grau']} na faixa ${caso['faixa']}', () {
        expect(
          calcularGrauAjustado(caso['faixa'] as String, caso['grau'] as int),
          caso['esperado'],
        );
      });
    }
  });

  test('lista 20 faixas, sem nome repetido', () {
    expect(faixas, hasLength(20));
    expect(faixas.map((f) => f.nome).toSet(), hasLength(20));
  });
}
