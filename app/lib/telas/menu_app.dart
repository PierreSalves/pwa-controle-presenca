// Tela 12 — Menu: itens conforme a permissão, na ordem do wireframe. Nesta etapa existem Início,
// Lançar presença, Alunos, Turmas, Usuários (só professor) e Sair; os demais entram com as telas correspondentes.
import 'package:material_ui/material_ui.dart';

import '../estado/dependencias.dart';
import 'tela_alunos.dart';
import 'tela_escolher_turma.dart';
import 'tela_turmas.dart';
import 'tela_usuarios.dart';

class MenuApp extends StatelessWidget {
  const MenuApp({super.key});

  @override
  Widget build(BuildContext context) {
    // O administrador do sistema não lança presença.
    final usuario = EscopoDependencias.obter(context).sessao.usuario;
    final temAcademia = usuario?.tenantId != null;
    // Usuários: só o professor (tela 11).
    final ehProfessor = usuario?.tipo == 'professor';
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
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 1),
            if (temAcademia) ...[
              _ItemMenu(
                icone: Icons.home_outlined,
                texto: 'Início',
                aoTocar: () =>
                    Navigator.of(context).popUntil((rota) => rota.isFirst),
              ),
              _ItemMenu(
                icone: Icons.check_box_outlined,
                texto: 'Lançar presença',
                aoTocar: () {
                  Navigator.of(context).pop();
                  abrirLancamento(context);
                },
              ),
              _ItemMenu(
                icone: Icons.people_outline,
                texto: 'Alunos',
                aoTocar: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const TelaAlunos()),
                  );
                },
              ),
              _ItemMenu(
                icone: Icons.school_outlined,
                texto: 'Turmas',
                aoTocar: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const TelaTurmas()),
                  );
                },
              ),
              if (ehProfessor)
                _ItemMenu(
                  icone: Icons.manage_accounts_outlined,
                  texto: 'Usuários',
                  aoTocar: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const TelaUsuarios(),
                      ),
                    );
                  },
                ),
            ],
            _ItemMenu(
              icone: Icons.logout,
              texto: 'Sair',
              aoTocar: () => confirmarSaida(context),
            ),
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
          child: Text(pendentes == 0 ? 'Sair' : 'Sair mesmo assim'),
        ),
      ],
    ),
  );
  if (confirmou != true || !context.mounted) return;
  Navigator.of(context).popUntil((rota) => rota.isFirst);
  await dependencias.sessao.sair();
}
