import 'package:controle_presenca/telas/tema.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// Estilo de texto sem a família explícita cai na Roboto, que não está no app: no navegador o
// texto some (sem internet nem acesso ao Google não há fonte de reserva).
void main() {
  final tema = criarTemaV2();
  final estados = <WidgetState>{};

  test('texto dos botões usa a fonte embutida', () {
    final estilos = {
      'principal': tema.filledButtonTheme.style?.textStyle?.resolve(estados),
      'secundário': tema.outlinedButtonTheme.style?.textStyle?.resolve(estados),
      'texto': tema.textButtonTheme.style?.textStyle?.resolve(estados),
    };
    for (final MapEntry(:key, :value) in estilos.entries) {
      expect(value?.fontFamily, 'Lexend', reason: 'botão $key');
    }
  });

  test('título da barra e textos do tema usam a fonte embutida', () {
    expect(tema.appBarTheme.titleTextStyle?.fontFamily, 'Lexend');
    expect(tema.textTheme.bodyMedium?.fontFamily, 'Lexend');
    expect(tema.textTheme.labelLarge?.fontFamily, 'Lexend');
  });

  test('cor de ação e contornos com o contraste da v2', () {
    expect(tema.colorScheme.primary, CoresV2.tatame);
    expect(tema.colorScheme.outline, CoresV2.contorno);
  });
}
