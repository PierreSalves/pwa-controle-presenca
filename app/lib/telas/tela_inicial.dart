// Ponto de entrada depois do login. Nesta etapa: tela 3 (escolher turma), pulada quando o usuário
// tem uma turma só. O Início completo (tela 2: resumo do ano, alunos sumidos) vem numa etapa seguinte.
import 'package:material_ui/material_ui.dart';

import '../dados/banco_local.dart';
import '../estado/dependencias.dart';
import 'componentes.dart';
import 'menu_app.dart';
import 'tela_lancamento.dart';

class TelaInicial extends StatelessWidget {
  const TelaInicial({super.key});

  @override
  Widget build(BuildContext context) {
    final dependencias = EscopoDependencias.obter(context);
    if (dependencias.sessao.usuario?.tenantId == null) {
      return const _TelaSemTurmas(
        mensagem: 'A área do administrador do sistema ainda não está disponível no app.',
      );
    }
    return StreamBuilder<List<Turma>>(
      stream: dependencias.consulta.observarTurmas(),
      builder: (context, snapshot) {
        final turmas = snapshot.data;
        if (turmas == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (turmas.isEmpty) {
          return const _TelaSemTurmas(
            mensagem: 'Nenhuma turma liberada para você. Fale com o professor.',
          );
        }
        if (turmas.length == 1) {
          return TelaLancamento(
            key: ValueKey(turmas.single.id),
            turmaId: turmas.single.id,
            ehTelaInicial: true,
          );
        }
        return _TelaEscolherTurma(turmas: turmas);
      },
    );
  }
}

/// Tela 3 — Escolher turma.
class _TelaEscolherTurma extends StatelessWidget {
  const _TelaEscolherTurma({required this.turmas});
  final List<Turma> turmas;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lançar presença'), centerTitle: true),
      drawer: const MenuApp(),
      body: LarguraCelular(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final turma in turmas) ...[
              ListTile(
                title: Text(turma.nome),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => TelaLancamento(turmaId: turma.id),
                  ),
                ),
              ),
              const Divider(height: 1),
            ],
            const SizedBox(height: 16),
            const Align(alignment: Alignment.centerLeft, child: StatusEnvio()),
          ],
        ),
      ),
    );
  }
}

class _TelaSemTurmas extends StatelessWidget {
  const _TelaSemTurmas({required this.mensagem});
  final String mensagem;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Controle de presença')),
      drawer: const MenuApp(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(mensagem, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
