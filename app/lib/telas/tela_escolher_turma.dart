// Tela 3 — Escolher turma. Pulada quando há uma turma só (o destino abre direto).
import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../dados/banco_local.dart';
import '../estado/dependencias.dart';
import 'componentes.dart';
import 'pagina_desktop.dart';
import 'tema.dart';
import 'tela_frequencia_semestre.dart';
import 'tela_lancamento.dart';

class TelaEscolherTurma extends StatelessWidget {
  const TelaEscolherTurma({
    super.key,
    required this.titulo,
    required this.turmas,
    required this.abrir,
    this.abrirDireto = false,
  });

  final String titulo;
  final List<Turma> turmas;
  final Widget Function(Turma turma) abrir;

  /// Como rota do menu (/lancar): com uma turma só, mostra o destino no lugar da lista; com mais,
  /// abre o destino por cima (voltar retorna à lista).
  final bool abrirDireto;

  @override
  Widget build(BuildContext context) {
    if (abrirDireto && turmas.length == 1) return abrir(turmas.single);
    void escolher(Turma turma) {
      final rota = MaterialPageRoute<void>(builder: (_) => abrir(turma));
      final navegador = Navigator.of(context);
      abrirDireto ? navegador.push(rota) : navegador.pushReplacement(rota);
    }

    if (ehDesktop(context)) {
      // PD3: título à esquerda e a lista num cartão; voltar só quando aberta de outra página.
      return PaginaDesktop(
        titulo: titulo,
        voltar: !abrirDireto,
        corpo: ListaEmCartao(
          titulo: turmas.isEmpty ? null : 'Escolha a turma',
          itens: [
            for (final turma in turmas)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: Text(turma.nome),
                trailing: const Icon(Symbols.chevron_right),
                onTap: () => escolher(turma),
              ),
            if (turmas.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Nenhuma turma liberada para você. Fale com o professor.',
                ),
              ),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
        centerTitle: true,
        automaticallyImplyLeading: !abrirDireto || !ehDesktop(context),
      ),
      body: LarguraCelular(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final turma in turmas) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(turma.nome),
                trailing: const Icon(Symbols.chevron_right),
                onTap: () => escolher(turma),
              ),
              const Divider(height: 1),
            ],
            if (turmas.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Nenhuma turma liberada para você. Fale com o professor.',
                ),
              ),
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

/// Tela de lançamento da turma (para a rota /lancar).
Widget abrirTelaLancamento(String turmaId) => TelaLancamento(turmaId: turmaId);
