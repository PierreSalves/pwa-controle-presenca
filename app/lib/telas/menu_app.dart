// Tela 12 — Menu (parte desta etapa): usuário logado, lançamento e sair. Os demais itens entram
// com as telas correspondentes.
import 'package:material_ui/material_ui.dart';

import '../estado/dependencias.dart';

const _nomesTipo = {
  'superadmin': 'Administrador do sistema',
  'professor': 'Professor',
  'assistente': 'Assistente',
};

class MenuApp extends StatelessWidget {
  const MenuApp({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = EscopoDependencias.obter(context).sessao.usuario;
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              title: Text(usuario?.nome ?? ''),
              subtitle: Text(_nomesTipo[usuario?.tipo] ?? ''),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.check_box_outlined),
              title: const Text('Lançar presença'),
              onTap: () => Navigator.of(context).pop(),
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sair'),
              onTap: () => confirmarSaida(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sair apaga os dados do aparelho: tenta enviar antes e avisa se ainda houver pendências.
Future<void> confirmarSaida(BuildContext context) async {
  final dependencias = EscopoDependencias.obter(context);
  await dependencias.coordenador.sincronizar();
  final pendentes = await dependencias.repositorio.observarPendentes().first;
  if (!context.mounted) return;
  final confirmou = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Sair'),
      content: Text(
        pendentes == 0
            ? 'Os dados deste aparelho serão apagados. Para usar de novo, entre com seu e-mail e senha.'
            : 'Há $pendentes lançamento(s) ainda não enviado(s). Se sair agora, eles serão perdidos. '
                  'Conecte-se à internet para enviar antes de sair.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(pendentes == 0 ? 'Sair' : 'Sair mesmo assim'),
        ),
      ],
    ),
  );
  if (confirmou != true || !context.mounted) return;
  Navigator.of(context).popUntil((rota) => rota.isFirst);
  await dependencias.sessao.sair();
}
