// Telas 8b e 8c (v1.2) e D8/D9 no desktop — Importar alunos: colar a lista copiada da planilha
// (código + nome), escolher opcionalmente uma turma e a data inicial para matricular todos, conferir o
// relatório da API (códigos repetidos ou já cadastrados impedem; nome repetido é aviso) e importar.
// Nada é gravado enquanto houver erro. Online.
import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../dados/cliente_api.dart';
import '../dados/repositorio_alunos.dart';
import '../estado/dependencias.dart';
import '../regras/lista_colada.dart';
import '../regras/presenca.dart';
import 'componentes.dart';
import 'formatacao.dart';
import 'relatorios/partes_relatorio.dart' show CampoData;
import 'tela_alunos.dart' show descreverErroOnline;
import 'tema.dart';

/// Limite da API por importação.
const _maximoLinhas = 2000;

class TelaImportarAlunos extends StatefulWidget {
  /// Sem [academiaId], importa para a academia de quem está logado; com ele, é a carga inicial
  /// do administrador do sistema (tela 13).
  const TelaImportarAlunos({super.key, this.academiaId, this.academiaNome});
  final String? academiaId;
  final String? academiaNome;

  @override
  State<TelaImportarAlunos> createState() => _TelaImportarAlunosState();
}

class _TelaImportarAlunosState extends State<TelaImportarAlunos> {
  final _texto = TextEditingController();
  List<LinhaColada>? _linhas;
  ResultadoImportacao? _resultado;
  bool _trabalhando = false;
  String? _erro;

  /// Turmas em que pode matricular; `null` enquanto carrega.
  List<TurmaParaMatricula>? _turmas;
  bool _falhouTurmas = false;
  String? _turmaId;
  late String _dataInicio;
  bool _iniciado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciado) return;
    _iniciado = true;
    final dependencias = EscopoDependencias.obter(context);
    _dataInicio = obterHojeEmSaoPaulo(dependencias.relogio());
    _carregarTurmas(dependencias);
  }

  Future<void> _carregarTurmas(Dependencias dependencias) async {
    try {
      final turmas = await dependencias.alunos.buscarTurmas(
        academiaId: widget.academiaId,
      );
      if (mounted) setState(() => _turmas = turmas);
    } on SessaoEncerrada {
      await dependencias.sessao.encerrarLocalmente();
    } catch (_) {
      // Sem a lista, dá para importar sem matricular.
      if (mounted) {
        setState(() {
          _turmas = const [];
          _falhouTurmas = true;
        });
      }
    }
  }

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

  Future<ResultadoImportacao> _enviar(
    RepositorioAlunos alunos, {
    bool confirmar = false,
  }) => alunos.importarAlunos(
    _paraEnviar,
    confirmar: confirmar,
    academiaId: widget.academiaId,
    turmaId: _turmaId,
    dataInicio: _turmaId == null ? null : _dataInicio,
  );

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
    final alunos = EscopoDependencias.obter(context).alunos;
    await _executar(() async => _resultado = await _enviar(alunos));
  }

  Future<void> _importar() async {
    final dependencias = EscopoDependencias.obter(context);
    final mensageiro = ScaffoldMessenger.of(context);
    final navegador = Navigator.of(context);
    await _executar(() async {
      final resultado = await _enviar(dependencias.alunos, confirmar: true);
      if (resultado.importados == 0) {
        // Alguém cadastrou um código da lista nesse meio-tempo: mostra o relatório novo.
        _resultado = resultado;
        return;
      }
      // Na carga inicial do administrador nada vai para o aparelho dele.
      if (widget.academiaId == null) {
        await dependencias.coordenador.sincronizar();
      }
      final n = resultado.importados;
      final importados = n == 1 ? '1 aluno importado' : '$n alunos importados';
      final matricula = resultado.matricula;
      mensageiro.showSnackBar(
        SnackBar(
          content: Text(
            matricula == null
                ? '$importados.'
                : '$importados e ${n == 1 ? 'matriculado' : 'matriculados'} '
                      'na turma ${matricula.turmaNome}.',
          ),
        ),
      );
      navegador.pop(true);
    });
  }

  void _voltarParaCorrigir() => setState(() {
    _resultado = null;
    _erro = null;
  });

  @override
  Widget build(BuildContext context) {
    final resultado = _resultado;
    return PopScope(
      canPop: resultado == null,
      onPopInvokedWithResult: (saiu, _) {
        if (!saiu) _voltarParaCorrigir();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.academiaNome == null
                ? 'Importar alunos'
                : 'Carga inicial · ${widget.academiaNome}',
          ),
          centerTitle: true,
        ),
        body: LarguraCelular(
          child: resultado == null
              ? _montarColar(context)
              : _montarRelatorio(context, resultado),
        ),
      ),
    );
  }

  Widget _montarColar(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final apoio = TextStyle(color: cores.onSurfaceVariant, fontSize: 13);
    final lista = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
      ],
    );
    final conferir = OutlinedButton(
      onPressed: _trabalhando ? null : _conferir,
      style: OutlinedButton.styleFrom(minimumSize: const Size(220, 48)),
      child: const Text('Conferir lista'),
    );
    final erro = _erro == null
        ? null
        : Text(_erro!, style: TextStyle(color: cores.error));

    // No desktop (D8), lista colada e turma lado a lado.
    if (ehDesktop(context)) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: lista),
              const SizedBox(width: 20),
              SizedBox(width: 340, child: _montarMatricula(context)),
            ],
          ),
          if (erro != null) ...[const SizedBox(height: 8), erro],
          const SizedBox(height: 16),
          Align(alignment: Alignment.centerLeft, child: conferir),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        lista,
        const SizedBox(height: 16),
        _montarMatricula(context),
        if (erro != null) ...[const SizedBox(height: 8), erro],
        const SizedBox(height: 16),
        conferir,
      ],
    );
  }

  /// Turma (opcional) e data inicial das matrículas dos importados.
  Widget _montarMatricula(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final apoio = TextStyle(color: cores.onSurfaceVariant, fontSize: 13);
    final turmas = _turmas;
    final semTurmas = turmas != null && turmas.isEmpty;
    final String ajuda;
    if (_falhouTurmas) {
      ajuda = 'Não foi possível carregar as turmas; dá para importar sem matricular.';
    } else if (semTurmas) {
      ajuda = widget.academiaId == null
          ? 'Nenhuma turma disponível para matricular.'
          : 'A academia ainda não tem turmas.';
    } else if (_turmaId == null) {
      ajuda =
          'Sem turma, a data fica desabilitada e os alunos só são cadastrados.';
    } else {
      ajuda = 'Todos os alunos da lista serão matriculados nessa turma a partir dessa data.';
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text.rich(
          TextSpan(
            text: 'Matricular numa turma ',
            style: const TextStyle(fontWeight: FontWeight.w600),
            children: [
              TextSpan(
                text: '(opcional)',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  color: cores.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String?>(
          key: ValueKey('turmas-${turmas?.length}'),
          initialValue: _turmaId,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Turma', isDense: true),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Não matricular (só cadastrar)'),
            ),
            for (final t in turmas ?? const <TurmaParaMatricula>[])
              DropdownMenuItem<String?>(value: t.id, child: Text(t.nome)),
          ],
          onChanged: turmas == null || semTurmas || _trabalhando
              ? null
              : (id) => setState(() => _turmaId = id),
        ),
        const SizedBox(height: 10),
        CampoData(
          rotulo: 'Matriculados desde',
          data: _dataInicio,
          aoEscolher: _turmaId == null || _trabalhando
              ? null
              : (data) => setState(() => _dataInicio = data),
        ),
        const SizedBox(height: 6),
        Text(ajuda, style: apoio),
      ],
    );
  }

  Widget _montarRelatorio(BuildContext context, ResultadoImportacao resultado) {
    final r = resultado.relatorio;
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
    final matricula = resultado.matricula;
    final alunos = total == 1 ? '1 aluno' : '$total alunos';
    final voltar = OutlinedButton(
      onPressed: _trabalhando ? null : _voltarParaCorrigir,
      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
      child: const Text('Voltar e corrigir'),
    );
    final desktop = ehDesktop(context);
    final importar = BotaoPrincipal(
      rotulo: matricula == null
          ? 'Importar $alunos'
          : 'Importar e matricular $alunos',
      icone: Symbols.upload,
      largo: !desktop,
      carregando: _trabalhando && r.podeImportar,
      rotuloCarregando: 'Importando…',
      aoTocar: r.podeImportar ? _importar : null,
    );
    final cartaoMatricula = _CartaoMatricula(
      texto: matricula == null
          ? 'Só cadastro: nenhuma matrícula será criada.'
          : null,
      turma: matricula?.turmaNome,
      data: matricula == null ? null : formatarDataBr(matricula.dataInicio),
      alunos: total == 1
          ? 'O aluno será matriculado'
          : 'Os $total alunos serão matriculados',
    );
    // Botões no rodapé no celular (8c) e alinhados à direita no desktop (D9); com muitos erros, rola.
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
                // No desktop a matrícula vem logo no topo (D9); no celular, depois dos erros (8c).
                if (desktop) ...[cartaoMatricula, const SizedBox(height: 6)],
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
                if (!desktop) ...[cartaoMatricula, const SizedBox(height: 6)],
                Text(
                  r.podeImportar ? 'Tudo certo para importar.' : 'Corrija na planilha e cole de novo. Nada é gravado enquanto houver erro.',
                  style: apoio,
                ),
                if (_erro != null) ...[
                  const SizedBox(height: 8),
                  Text(_erro!, style: TextStyle(color: cores.error)),
                ],
                if (desktop) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [voltar, const SizedBox(width: 12), importar],
                  ),
                ] else ...[
                  const Spacer(),
                  const SizedBox(height: 16),
                  voltar,
                  const SizedBox(height: 8),
                  importar,
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Turma e data das matrículas (azul-claro) ou o aviso de que é só cadastro (neutro).
class _CartaoMatricula extends StatelessWidget {
  const _CartaoMatricula({
    required this.texto,
    required this.turma,
    required this.data,
    required this.alunos,
  });

  /// Texto do aviso sem matrícula; com turma, `null`.
  final String? texto;
  final String? turma;
  final String? data;
  final String alunos;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final comTurma = texto == null;
    final cor = comTurma
        ? CoresWireframe.etiquetaTexto
        : cores.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: comTurma ? CoresWireframe.etiquetaFundo : cores.surface,
        borderRadius: BorderRadius.circular(14),
        border: comTurma ? null : Border.all(color: cores.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            comTurma ? Symbols.school : Symbols.person_add,
            color: cor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: comTurma
                ? Text.rich(
                    TextSpan(
                      style: TextStyle(color: cor, fontSize: 14),
                      children: [
                        TextSpan(text: '$alunos na turma '),
                        TextSpan(
                          text: turma,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const TextSpan(text: ' a partir de '),
                        TextSpan(
                          text: data,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                  )
                : Text(texto!, style: TextStyle(color: cor, fontSize: 14)),
          ),
        ],
      ),
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
