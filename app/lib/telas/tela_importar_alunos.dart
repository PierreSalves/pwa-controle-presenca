// Telas 8b e 8c — Importar alunos: colar a lista copiada da planilha (código + nome), conferir o
// relatório da API (códigos repetidos ou já cadastrados impedem; nome repetido é aviso) e importar.
// Nada é gravado enquanto houver erro. Online.
import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../dados/cliente_api.dart';
import '../dados/repositorio_alunos.dart';
import '../estado/dependencias.dart';
import '../regras/lista_colada.dart';
import 'componentes.dart';
import 'tela_alunos.dart' show descreverErroOnline;

/// Limite da API por importação.
const _maximoLinhas = 2000;

class TelaImportarAlunos extends StatefulWidget {
  const TelaImportarAlunos({super.key});

  @override
  State<TelaImportarAlunos> createState() => _TelaImportarAlunosState();
}

class _TelaImportarAlunosState extends State<TelaImportarAlunos> {
  final _texto = TextEditingController();
  List<LinhaColada>? _linhas;
  RelatorioImportacao? _relatorio;
  bool _trabalhando = false;
  String? _erro;

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  List<({String codigo, String nome})> get _paraEnviar => [
    for (final l in _linhas ?? const <LinhaColada>[])
      (codigo: l.codigo, nome: l.nome),
  ];

  /// A API numera pela posição na lista enviada; a tela mostra a linha do texto colado.
  int _linhaColada(int linhaDaLista) => _linhas![linhaDaLista - 1].numero;

  String _juntarLinhas(List<int> linhas) {
    final numeros = [for (final l in linhas) '${_linhaColada(l)}'];
    return numeros.length == 1
        ? 'linha ${numeros.single}'
        : 'linhas ${numeros.sublist(0, numeros.length - 1).join(', ')} e ${numeros.last}';
  }

  Future<void> _executar(Future<void> Function() acao) async {
    setState(() {
      _trabalhando = true;
      _erro = null;
    });
    final dependencias = EscopoDependencias.obter(context);
    try {
      await acao();
    } on SessaoEncerrada {
      await dependencias.sessao.encerrarLocalmente();
    } catch (erro) {
      _erro = descreverErroOnline(erro);
    }
    if (mounted) setState(() => _trabalhando = false);
  }

  Future<void> _conferir() async {
    final linhas = lerListaColada(_texto.text);
    if (linhas.isEmpty) {
      setState(() => _erro = 'Cole a lista de alunos antes de conferir.');
      return;
    }
    if (linhas.length > _maximoLinhas) {
      setState(
        () => _erro =
            'A lista tem ${linhas.length} linhas; o limite é $_maximoLinhas por vez.',
      );
      return;
    }
    _linhas = linhas;
    await _executar(() async {
      final resultado = await EscopoDependencias.obter(context).alunos
          .importarAlunos(_paraEnviar);
      _relatorio = resultado.relatorio;
    });
  }

  Future<void> _importar() async {
    final dependencias = EscopoDependencias.obter(context);
    final mensageiro = ScaffoldMessenger.of(context);
    final navegador = Navigator.of(context);
    await _executar(() async {
      final resultado = await dependencias.alunos.importarAlunos(
        _paraEnviar,
        confirmar: true,
      );
      if (resultado.importados == 0) {
        // Alguém cadastrou um código da lista nesse meio-tempo: mostra o relatório novo.
        _relatorio = resultado.relatorio;
        return;
      }
      await dependencias.coordenador.sincronizar();
      mensageiro.showSnackBar(
        SnackBar(
          content: Text(
            resultado.importados == 1
                ? '1 aluno importado.'
                : '${resultado.importados} alunos importados.',
          ),
        ),
      );
      navegador.pop(true);
    });
  }

  void _voltarParaCorrigir() => setState(() {
    _relatorio = null;
    _erro = null;
  });

  @override
  Widget build(BuildContext context) {
    final relatorio = _relatorio;
    return PopScope(
      canPop: relatorio == null,
      onPopInvokedWithResult: (saiu, _) {
        if (!saiu) _voltarParaCorrigir();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Importar alunos'), centerTitle: true),
        body: LarguraCelular(
          child: relatorio == null
              ? _montarColar(context)
              : _montarRelatorio(context, relatorio),
        ),
      ),
    );
  }

  Widget _montarColar(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final apoio = TextStyle(color: cores.onSurfaceVariant, fontSize: 13);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Na planilha, selecione as colunas código e nome, copie e cole aqui. '
          'Uma linha por aluno.',
          style: TextStyle(color: cores.onSurfaceVariant),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _texto,
          minLines: 8,
          maxLines: 16,
          keyboardType: TextInputType.multiline,
          autocorrect: false,
          enableSuggestions: false,
          style: const TextStyle(fontSize: 13),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: '(01) Augusto E. B. Torres\n(03) Lucas V. S. da Mata',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Código e nome separados por tab, ponto e vírgula ou espaço; '
          '"(10A)" vira "10A".',
          style: apoio,
        ),
        if (_erro != null) ...[
          const SizedBox(height: 8),
          Text(_erro!, style: TextStyle(color: cores.error)),
        ],
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _trabalhando ? null : _conferir,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
          child: const Text('Conferir lista'),
        ),
      ],
    );
  }

  Widget _montarRelatorio(BuildContext context, RelatorioImportacao r) {
    final cores = Theme.of(context).colorScheme;
    final apoio = TextStyle(color: cores.onSurfaceVariant, fontSize: 13);
    final erros = [
      if (r.incompletas.isNotEmpty)
        'Sem código ou sem nome: ${_juntarLinhas(r.incompletas)}',
      for (final c in r.codigosRepetidos)
        'Código ${c.codigo} repetido nas ${_juntarLinhas(c.linhas)}',
      for (final c in r.codigosExistentes)
        'Código ${c.codigo} já cadastrado (linha ${_linhaColada(c.linha)}: '
            '${c.nomeCadastrado})',
    ];
    final avisos = [
      for (final n in r.nomesRepetidos)
        'Aviso: nome repetido "${n.nome}" (${_juntarLinhas(n.linhas)})',
    ];
    final total = _linhas!.length;
    // Botões no rodapé, como no wireframe 8c; com muitos erros, a tela rola.
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('$total ${total == 1 ? 'linha lida' : 'linhas lidas'}'),
                const SizedBox(height: 8),
                for (final e in erros) ...[
                  _Faixa(
                    texto: e,
                    fundo: const Color(0xFFFCEBEB),
                    cor: CoresWireframe.perigo,
                  ),
                  const SizedBox(height: 6),
                ],
                for (final a in avisos) ...[
                  _Faixa(
                    texto: a,
                    fundo: CoresWireframe.avisoFundo,
                    cor: CoresWireframe.avisoTexto,
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  r.podeImportar ? 'Tudo certo para importar.' : 'Corrija na planilha e cole de novo. Nada é gravado enquanto houver erro.',
                  style: apoio,
                ),
                if (_erro != null) ...[
                  const SizedBox(height: 8),
                  Text(_erro!, style: TextStyle(color: cores.error)),
                ],
                const Spacer(),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _trabalhando ? null : _voltarParaCorrigir,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Voltar e corrigir'),
                ),
                const SizedBox(height: 8),
                BotaoPrincipal(
                  rotulo: total == 1
                      ? 'Importar 1 aluno'
                      : 'Importar $total alunos',
                  icone: Symbols.upload,
                  largo: true,
                  carregando: _trabalhando && r.podeImportar,
                  rotuloCarregando: 'Importando…',
                  aoTocar: r.podeImportar ? _importar : null,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Faixa extends StatelessWidget {
  const _Faixa({required this.texto, required this.fundo, required this.cor});
  final String texto;
  final Color fundo;
  final Color cor;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: fundo,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(texto, style: TextStyle(color: cor, fontSize: 13)),
  );
}
