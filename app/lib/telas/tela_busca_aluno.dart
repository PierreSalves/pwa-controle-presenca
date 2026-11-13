// Tela 4b — Busca de aluno pouco frequente: marca quem não está na lista; ao marcar, o aluno
// volta para os frequentes.
import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../dados/consulta_lancamento.dart';
import '../dados/repositorio_presenca.dart';
import '../estado/dependencias.dart';
import '../regras/presenca.dart';
import 'componentes.dart';
import 'formatacao.dart';

class TelaBuscaAluno extends StatefulWidget {
  const TelaBuscaAluno({
    super.key,
    required this.turmaId,
    required this.data,
    required this.tipo,
  });

  final String turmaId;
  final String data;
  final TipoAula tipo;

  @override
  State<TelaBuscaAluno> createState() => _TelaBuscaAlunoState();
}

class _TelaBuscaAlunoState extends State<TelaBuscaAluno> {
  String _busca = '';
  Stream<DadosLancamento>? _dados;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dados ??= EscopoDependencias.obter(context).consulta
        .observarLancamento(widget.turmaId, widget.data);
  }

  List<AlunoNoLancamento> _filtrar(DadosLancamento dados) {
    final termo = normalizarBusca(_busca);
    if (termo.isEmpty) return const [];
    return [...dados.lista, ...dados.poucoFrequentes].where((a) {
        return normalizarBusca(a.nome).contains(termo) ||
            normalizarBusca(a.codigo).contains(termo);
      }).toList()
      ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
  }

  Future<void> _definirPresenca(String alunoId, bool presente) async {
    final dependencias = EscopoDependencias.obter(context);
    try {
      await dependencias.repositorio.definirPresenca(
        turmaId: widget.turmaId,
        data: widget.data,
        alunoId: alunoId,
        presente: presente,
        tipo: widget.tipo,
      );
      unawaited(dependencias.coordenador.sincronizar());
    } on MarcacaoRecusada {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível marcar este aluno.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textoApoio = TextStyle(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontSize: 13,
    );
    return StreamBuilder<DadosLancamento>(
      stream: _dados,
      builder: (context, snapshot) {
        final dados = snapshot.data;
        final titulo = dados == null
            ? 'Buscar aluno'
            : '${dados.turmaNome} · ${obterDiaAbreviado(widget.data)} ${formatarDiaMes(widget.data)}';
        final resultado = dados == null
            ? const <AlunoNoLancamento>[]
            : _filtrar(dados);
        return Scaffold(
          appBar: AppBar(title: Text(titulo), centerTitle: true),
          body: LarguraCelular(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  autofocus: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Nome ou código do aluno',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _busca = v),
                ),
                const SizedBox(height: 8),
                for (final aluno in resultado) ...[
                  LinhaAluno(
                    aluno: aluno,
                    mostrarFrequencia: true,
                    aoMarcar: (v) => _definirPresenca(aluno.id, v),
                  ),
                  const Divider(height: 1),
                ],
                if (_busca.trim().isNotEmpty && resultado.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('Nenhum aluno matriculado com esse nome.'),
                  ),
                const SizedBox(height: 8),
                Text(
                  'Ao marcar, o aluno volta para a lista de frequentes',
                  style: textoApoio,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
