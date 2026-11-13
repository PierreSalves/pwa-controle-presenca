// Tela 3 — Escolher turma. Pulada quando há uma turma só (o destino abre direto).
import 'package:material_ui/material_ui.dart';

import '../dados/banco_local.dart';
import '../estado/dependencias.dart';
import 'componentes.dart';
import 'tela_frequencia_semestre.dart';
import 'tela_lancamento.dart';

class TelaEscolherTurma extends StatelessWidget {
  const TelaEscolherTurma({
    super.key,
    required this.titulo,
    required this.turmas,
    required this.abrir,
  });

  final String titulo;
  final List<Turma> turmas;
  final Widget Function(Turma turma) abrir;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo), centerTitle: true),
      body: LarguraCelular(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final turma in turmas) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(turma.nome),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(builder: (_) => abrir(turma)),
                ),
              ),
              const Divider(height: 1),
            ],
          ],
        ),
      ),
    );
  }
}

/// Abre o destino da turma; com mais de uma turma, passa antes pela escolha.
Future<void> abrirComTurma(
  BuildContext context, {
  required String titulo,
  required Widget Function(Turma turma) abrir,
  Set<String>? soAsTurmas,
}) async {
  final todas = await EscopoDependencias.obter(context).consulta
      .observarTurmas()
      .first;
  final turmas = soAsTurmas == null
      ? todas
      : todas.where((t) => soAsTurmas.contains(t.id)).toList();
  if (!context.mounted || turmas.isEmpty) return;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => turmas.length == 1
          ? abrir(turmas.single)
          : TelaEscolherTurma(titulo: titulo, turmas: turmas, abrir: abrir),
    ),
  );
}

Future<void> abrirLancamento(BuildContext context) => abrirComTurma(
  context,
  titulo: 'Lançar presença',
  abrir: (turma) => TelaLancamento(turmaId: turma.id),
);

Future<void> abrirFrequenciaSemestre(
  BuildContext context, {
  Set<String>? soAsTurmas,
}) => abrirComTurma(
  context,
  titulo: 'Frequência do semestre',
  soAsTurmas: soAsTurmas,
  abrir: (turma) => TelaFrequenciaSemestre(turmaId: turma.id),
);
