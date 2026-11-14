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
    expect(find.bySemanticsLabel('Faixa Azul, 2º grau'), findsOneWidget);
  });

  testWidgets('faixa preta tem a ponteira vermelha com os graus', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: FaixaDoAluno(faixa: 'Preta', grau: 3)),
      ),
    );
    final cores = tester
        .widgetList<Container>(find.byType(Container))
        .map((c) => c.color)
        .toList();
    expect(cores, contains(const Color(0xFFB3261E)));
    expect(cores.where((c) => c == Colors.white), hasLength(3));
  });

  testWidgets('faixa preta com ponteira branca: listras escuras', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: FaixaDoAluno(faixa: 'Preta', grau: 2, ponteira: 'branca'),
        ),
      ),
    );
    final cores = tester
        .widgetList<Container>(find.byType(Container))
        .map((c) => c.color)
        .toList();
    expect(cores, isNot(contains(const Color(0xFFB3261E))));
    expect(cores.where((c) => c == const Color(0xFF1E1E1E)), hasLength(3));
    expect(
      find.bySemanticsLabel('Faixa Preta, 2º grau, ponteira branca'),
      findsOneWidget,
    );
  });

  testWidgets('faixa infantil de duas cores tem a listra do meio', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: FaixaDoAluno(faixa: 'Cinza e branca', grau: 0)),
      ),
    );
    final listra = tester.widget<ColoredBox>(
      find.descendant(
        of: find.byType(FractionallySizedBox),
        matching: find.byType(ColoredBox),
      ),
    );
    expect(listra.color, const Color(0xFFF4F4F2));
  });
}
