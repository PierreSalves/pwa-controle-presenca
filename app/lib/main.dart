import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const ControlePresencaApp());
}

/// Raiz do app. As telas da Fase 1 seguem os wireframes aprovados em docs/telas/.
class ControlePresencaApp extends StatelessWidget {
  const ControlePresencaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle de presença',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1F1E1D),
        useMaterial3: true,
      ),
      home: const Scaffold(body: Center(child: Text('Controle de presença'))),
    );
  }
}
