// Ponto de entrada depois do login: o Início (tela 2). O administrador do sistema ainda não tem
// telas no app.
import 'package:material_ui/material_ui.dart';

import '../estado/dependencias.dart';
import 'menu_app.dart';
import 'tela_inicio.dart';

class TelaInicial extends StatelessWidget {
  const TelaInicial({super.key});

  @override
  Widget build(BuildContext context) {
    final dependencias = EscopoDependencias.obter(context);
    if (dependencias.sessao.usuario?.tenantId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Controle de presença')),
        drawer: const MenuApp(),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'A área do administrador do sistema ainda não está disponível no app.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    return const TelaInicio();
  }
}
