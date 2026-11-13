// Ponto de entrada depois do login: o Início (tela 2) ou, para o administrador do sistema, as
// academias (tela 13).
import 'package:material_ui/material_ui.dart';

import '../estado/dependencias.dart';
import 'tela_academias.dart';
import 'tela_inicio.dart';

class TelaInicial extends StatelessWidget {
  const TelaInicial({super.key});

  @override
  Widget build(BuildContext context) {
    final dependencias = EscopoDependencias.obter(context);
    if (dependencias.sessao.usuario?.tipo == 'superadmin') {
      return const TelaAcademias();
    }
    return const TelaInicio();
  }
}
