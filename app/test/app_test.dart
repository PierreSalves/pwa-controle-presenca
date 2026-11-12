import 'package:controle_presenca/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('abre o app com o nome do sistema', (tester) async {
    await tester.pumpWidget(const ControlePresencaApp());
    expect(find.text('Controle de presença'), findsOneWidget);
  });
}
