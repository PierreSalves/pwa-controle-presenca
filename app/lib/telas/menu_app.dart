// Tela 12 — Menu do celular (no desktop, o menu lateral fixo de navegacao.dart faz este papel).
// Itens conforme a permissão, na ordem do wireframe; cada item abre a rota com endereço.
import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../estado/dependencias.dart';
import 'componentes.dart';
import 'navegacao.dart';
import 'tema.dart';

/// O menu escondido (☰) só existe no celular; no desktop o menu lateral fica sempre visível.
Widget? obterMenuDoCelular(BuildContext context) =>
    ehDesktop(context) ? null : const MenuApp();

class MenuApp extends StatelessWidget {
  const MenuApp({super.key});

  @override
  Widget build(BuildContext context) {
    final itens = obterItensMenu(EscopoDependencias.obter(context).sessao);
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Menu',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  tooltip: 'Fechar',
                  icon: const Icon(Symbols.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 1),
            for (final item in itens)
              _ItemMenu(
                icone: item.icone,
                texto: item.texto,
                aoTocar: () {
                  final navegador = Navigator.of(context)..pop();
                  if (item.rota == Rotas.inicio) {
                    navegador.pushNamedAndRemoveUntil(
                      Rotas.inicio,
                      (_) => false,
                    );
                  } else {
                    navegador.pushNamed(item.rota);
                  }
                },
              ),
            _ItemMenu(
              icone: Symbols.logout,
              texto: 'Sair',
              aoTocar: () => confirmarSaida(context),
            ),
            const SizedBox(height: 8),
            const RodapeCopyright(),
          ],
        ),
      ),
    );
  }
}

class _ItemMenu extends StatelessWidget {
  const _ItemMenu({
    required this.icone,
    required this.texto,
    required this.aoTocar,
  });

  final IconData icone;
  final String texto;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icone, size: 20),
        minLeadingWidth: 20,
        title: Text(texto),
        onTap: aoTocar,
      ),
      const Divider(height: 1),
    ],
  );
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
          style: pendentes == 0 ? null : estiloConfirmarDestrutivo,
          child: Text(pendentes == 0 ? 'Sair' : 'Sair mesmo assim'),
        ),
      ],
    ),
  );
  if (confirmou != true || !context.mounted) return;
  Navigator.of(context).popUntil((rota) => rota.isFirst);
  await dependencias.sessao.sair();
}
