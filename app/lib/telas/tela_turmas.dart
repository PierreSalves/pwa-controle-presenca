// Turmas (Menu → Turmas): lista no padrão da tela 3 (escolher turma), com "+" para criar; tocar
// abre a configuração (tela 10). Online.
import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../dados/cliente_api.dart';
import '../dados/repositorio_turmas.dart';
import '../estado/dependencias.dart';
import 'componentes.dart';
import 'tema.dart';
import 'tela_alunos.dart' show descreverErroOnline;
import 'tela_turma.dart';

class TelaTurmas extends StatefulWidget {
  const TelaTurmas({super.key});

  @override
  State<TelaTurmas> createState() => _TelaTurmasState();
}

class _TelaTurmasState extends State<TelaTurmas> {
  late final Dependencias _dependencias;
  List<ResumoTurma>? _turmas;
  String? _erro;
  bool _iniciado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciado) return;
    _iniciado = true;
    _dependencias = EscopoDependencias.obter(context);
    unawaited(_carregar());
  }

  Future<void> _carregar() async {
    setState(() => _erro = null);
    try {
      final turmas = await _dependencias.turmas.buscarTurmas();
      if (mounted) setState(() => _turmas = turmas);
    } on SessaoEncerrada {
      await _dependencias.sessao.encerrarLocalmente();
    } catch (erro) {
      if (mounted) setState(() => _erro = descreverErroOnline(erro));
    }
  }

  Future<void> _abrir({String? id}) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => TelaTurma(turmaId: id)));
    if (mounted) unawaited(_carregar());
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final turmas = _turmas;
    return Scaffold(
      appBar: AppBar(
        // No desktop o menu lateral faz o papel do voltar nas telas principais.
        automaticallyImplyLeading: !ehDesktop(context),
        title: const Text('Turmas'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Nova turma',
            icon: const Icon(Symbols.add),
            onPressed: () => _abrir(),
          ),
        ],
      ),
      body: LarguraCelular(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_erro != null) ...[
              Text(_erro!, style: TextStyle(color: cores.error)),
              OutlinedButton(
                onPressed: _carregar,
                child: const Text('Tentar de novo'),
              ),
            ] else if (turmas == null)
              const Padding(padding: EdgeInsets.all(24), child: Carregando())
            else ...[
              for (final turma in turmas) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(turma.nome),
                  subtitle: Text(
                    '${turma.alunosMatriculados} '
                    '${turma.alunosMatriculados == 1 ? 'aluno' : 'alunos'}',
                  ),
                  trailing: const Icon(Symbols.chevron_right),
                  onTap: () => _abrir(id: turma.id),
                ),
                const Divider(height: 1),
              ],
              if (turmas.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('Nenhuma turma. Toque em + para criar.'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
