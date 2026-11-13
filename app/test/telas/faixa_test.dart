import 'package:controle_presenca/telas/componentes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('faixa mostra a cor real e uma listra por grau', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: FaixaDoAluno(faixa: 'Azul', grau: 2)),
      ),
    );
    final faixaAzul = tester
        .widgetList<Container>(find.byType(Container))
        .where((c) => c.color == const Color(0xFF2456A6));
    expect(faixaAzul, hasLength(1));
    // A parte colorida tem a altura da faixa (não some).
    expect(
      tester.getSize(find.byWidget(faixaAzul.single)).height,
      greaterThan(10),
    );
    final listras = tester
        .widgetList<Container>(find.byType(Container))
        .where((c) => c.color == Colors.white);
    expect(listras, hasLength(2));
    expect(find.bySemanticsLabel('Faixa Azul, 2 grau'), findsOneWidget);
  });
}
