import 'dart:math';

import 'package:controle_presenca/telas/formatacao.dart';
import 'package:controle_presenca/telas/tela_academia.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a senha gerada é palavra, hífen e 4 algarismos, com 8+ caracteres', () {
    final sorteio = Random(42);
    for (var i = 0; i < 200; i++) {
      final senha = gerarSenhaParaDitar(sorteio);
      expect(senha, matches(RegExp(r'^[a-z]+-\d{4}$')));
      expect(senha.length, greaterThanOrEqualTo(8));
    }
  });

  test('a data do último acesso sai no fuso de São Paulo', () {
    expect(
      formatarDataDoInstante(DateTime.parse('2026-11-02T13:00:00Z')),
      '02/11/2026',
    );
    // 01h UTC ainda é o dia anterior em São Paulo.
    expect(
      formatarDataDoInstante(DateTime.parse('2026-11-03T01:00:00Z')),
      '02/11/2026',
    );
  });
}
