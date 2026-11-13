// Tela 14 — Dados da academia (só o professor): nome, nome curto (embaixo do ícone do app
// instalado), logotipo com a prévia do ícone e cabeçalho de impressão. Online.
// O logotipo é enviado na hora em que é escolhido, junto com os ícones 192 e 512 px gerados aqui.
import 'dart:async';
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../dados/cliente_api.dart';
import '../dados/repositorio_academia.dart';
import '../estado/dependencias.dart';
import '../plataforma/imagens.dart';
import 'componentes.dart';
import 'tela_alunos.dart' show descreverErroOnline;
import 'tema.dart';

const _maximoLogotipo = 1024 * 1024;

String _descreverErroAcademia(Object erro) => switch (erro) {
  ErroApi(codigo: 'imagem_invalida') || FormatException() =>
    'A imagem não abriu como PNG ou JPG. Escolha outro arquivo.',
  ErroApi(codigo: 'logotipo_grande_demais') =>
    'O logotipo passa de 1 MB. Diminua a imagem e tente de novo.',
  ErroApi(codigo: 'dados_invalidos') =>
    'Confira os dados: o nome curto tem até 15 letras.',
  _ => descreverErroOnline(erro),
};

class TelaDadosAcademia extends StatefulWidget {
  const TelaDadosAcademia({super.key});

  @override
  State<TelaDadosAcademia> createState() => _TelaDadosAcademiaState();
}

class _TelaDadosAcademiaState extends State<TelaDadosAcademia> {
  late final Dependencias _dependencias;
  final _formulario = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _nomeCurto = TextEditingController();
  final _cabecalho = TextEditingController();
  DadosAcademia? _academia;
  String? _erro;
  bool _salvando = false;
  bool _enviandoLogotipo = false;
  bool _iniciado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciado) return;
    _iniciado = true;
    _dependencias = EscopoDependencias.obter(context);
    unawaited(_carregar());
  }

  @override
  void dispose() {
    _nome.dispose();
    _nomeCurto.dispose();
    _cabecalho.dispose();
    super.dispose();
  }

  void _mostrar(DadosAcademia academia) {
    _academia = academia;
    _nome.text = academia.nome;
    _nomeCurto.text = academia.nomeCurto ?? '';
    _cabecalho.text = academia.cabecalhoImpressao ?? '';
  }

  Future<void> _carregar() async {
    setState(() => _erro = null);
    try {
      final academia = await _dependencias.academia.buscarAcademia();
      if (mounted) setState(() => _mostrar(academia));
    } on SessaoEncerrada {
      await _dependencias.sessao.encerrarLocalmente();
    } catch (erro) {
      if (mounted) setState(() => _erro = descreverErroOnline(erro));
    }
  }

  bool _temAlteracoes() {
    final a = _academia;
    if (a == null) return false;
    return _nome.text.trim() != a.nome ||
        _nomeCurto.text.trim() != (a.nomeCurto ?? '') ||
        _cabecalho.text.trim() != (a.cabecalhoImpressao ?? '');
  }

  void _avisar(String texto) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(texto)));

  Future<void> _executar(Future<void> Function() acao) async {
    try {
      await acao();
    } on SessaoEncerrada {
      await _dependencias.sessao.encerrarLocalmente();
    } catch (erro) {
      if (mounted) _avisar(_descreverErroAcademia(erro));
    }
  }

  Future<void> _salvar() async {
    if (_salvando || !_formulario.currentState!.validate()) return;
    setState(() => _salvando = true);
    await _executar(() async {
      final academia = await _dependencias.academia.salvarAcademia(
        nome: _nome.text,
        nomeCurto: _nomeCurto.text,
        cabecalhoImpressao: _cabecalho.text,
      );
      if (!mounted) return;
      setState(() => _mostrar(academia));
      unawaited(_dependencias.sessao.atualizarAcademia());
      _avisar('Dados da academia salvos.');
    });
    if (mounted) setState(() => _salvando = false);
  }

  Future<void> _enviarLogotipo() async {
    final escolhida = await _dependencias.imagens.escolherImagem();
    if (escolhida == null || !mounted) return;
    if (detectarTipoImagem(escolhida.bytes) == null) {
      _avisar(_descreverErroAcademia(const FormatException()));
      return;
    }
    if (escolhida.bytes.length > _maximoLogotipo) {
      _avisar(
        _descreverErroAcademia(const ErroApi(413, 'logotipo_grande_demais')),
      );
      return;
    }
    setState(() => _enviandoLogotipo = true);
    await _executar(() async {
      final imagens = _dependencias.imagens;
      final icone192 = await imagens.gerarIcone(escolhida.bytes, 192);
      final icone512 = await imagens.gerarIcone(escolhida.bytes, 512);
      final academia = await _dependencias.academia.enviarLogotipo(
        logotipo: escolhida.bytes,
        icone192: icone192,
        icone512: icone512,
      );
      await _dependencias.sessao.definirLogotipo(
        icone: icone512,
        original: escolhida.bytes,
        versao: academia.logotipoVersao,
      );
      if (!mounted) return;
      setState(() => _academia = academia);
      _avisar('Logotipo enviado.');
    });
    if (mounted) setState(() => _enviandoLogotipo = false);
  }

  Future<void> _removerLogotipo() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover o logotipo?'),
        content: const Text(
          'O app volta a mostrar o nome da academia e o ícone da TghServices.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: estiloConfirmarDestrutivo,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmou != true) return;
    setState(() => _enviandoLogotipo = true);
    await _executar(() async {
      final academia = await _dependencias.academia.removerLogotipo();
      await _dependencias.sessao.definirLogotipo(
        icone: null,
        original: null,
        versao: null,
      );
      if (mounted) setState(() => _academia = academia);
    });
    if (mounted) setState(() => _enviandoLogotipo = false);
  }

  @override
  Widget build(BuildContext context) {
    final desktop = ehDesktop(context);
    final salvar = BotaoPrincipal(
      rotulo: 'Salvar',
      icone: Symbols.check,
      carregando: _salvando,
      aoTocar: _academia == null ? null : _salvar,
    );
    return ProtecaoAlteracoes(
      temAlteracoes: _temAlteracoes,
      child: Scaffold(
        appBar: desktop
            ? null
            : AppBar(
                title: const Text('Dados da academia'),
                // Título à esquerda: centralizado, ele não cabe ao lado do Salvar no celular.
                centerTitle: false,
                actions: [salvar],
              ),
        body: LarguraCelular(
          child: _erro != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_erro!),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: _carregar,
                        child: const Text('Tentar de novo'),
                      ),
                    ],
                  ),
                )
              : _academia == null
              ? const Carregando()
              : _montarFormulario(desktop, salvar),
        ),
      ),
    );
  }

  Widget _montarFormulario(bool desktop, Widget salvar) {
    const apoio = TextStyle(color: CoresV2.nevoa, fontSize: 13);
    const titulo = TextStyle(fontWeight: FontWeight.w600);
    final logotipo = _dependencias.sessao.iconeAcademia;
    final temLogotipo = _academia!.temLogotipo;
    return Form(
      key: _formulario,
      child: ListView(
        padding: desktop
            ? const EdgeInsets.fromLTRB(28, 24, 28, 28)
            : const EdgeInsets.all(16),
        children: [
          if (desktop) ...[
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Dados da academia',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                ),
                salvar,
              ],
            ),
            const SizedBox(height: 16),
          ],
          TextFormField(
            controller: _nome,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Nome', isDense: true),
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Informe o nome da academia'
                : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _nomeCurto,
            maxLength: 15,
            decoration: const InputDecoration(
              labelText: 'Nome curto no celular',
              helperText: 'Aparece embaixo do ícone do app instalado.',
              isDense: true,
            ),
          ),
          const SizedBox(height: 6),
          Cartao(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Logotipo', style: titulo),
                const SizedBox(height: 10),
                if (_enviandoLogotipo)
                  const SizedBox(
                    height: 96,
                    child: Center(
                      child: CircularProgressIndicator(
                        semanticsLabel: 'Enviando o logotipo…',
                      ),
                    ),
                  )
                else if (!temLogotipo)
                  _AreaEnviar(aoTocar: _enviarLogotipo)
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _enviarLogotipo,
                        icon: const Icon(Symbols.upload),
                        label: const Text('Trocar logotipo'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _removerLogotipo,
                        style: estiloDestrutivo,
                        icon: const Icon(Symbols.delete),
                        label: const Text('Remover'),
                      ),
                    ],
                  ),
                const SizedBox(height: 14),
                const Text('Prévia do ícone do app', style: titulo),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _PreviaIcone(icone: logotipo, redondo: false),
                    const SizedBox(width: 12),
                    _PreviaIcone(icone: logotipo, redondo: true),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Quadrado e redondo, como cada celular mostra.',
                        style: apoio,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _cabecalho,
            maxLength: 200,
            decoration: const InputDecoration(
              labelText: 'Cabeçalho de impressão (opcional)',
              hintText: 'Ex.: Prof. Fulano de Tal…',
              isDense: true,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'O logotipo também aparece nos relatórios impressos. Sem logotipo, o app '
            'usa o ícone da TghServices.',
            style: apoio,
          ),
        ],
      ),
    );
  }
}

class _AreaEnviar extends StatelessWidget {
  const _AreaEnviar({required this.aoTocar});
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Enviar logotipo, PNG ou JPG até 1 MB',
      excludeSemantics: true,
      child: Material(
        color: CoresV2.tatameClaro,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: aoTocar,
          child: const SizedBox(
            height: 96,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Symbols.upload, color: CoresV2.tatame),
                SizedBox(height: 4),
                Text(
                  'Enviar logotipo',
                  style: TextStyle(
                    color: CoresV2.tatame,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'PNG ou JPG · até 1 MB',
                  style: TextStyle(color: CoresV2.nevoa, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviaIcone extends StatelessWidget {
  const _PreviaIcone({required this.icone, required this.redondo});
  final Uint8List? icone;
  final bool redondo;

  @override
  Widget build(BuildContext context) {
    const tamanho = 64.0;
    final conteudo = icone == null
        ? Container(
            color: CoresV2.tatameClaro,
            alignment: Alignment.center,
            child: const Icon(Symbols.image, color: CoresV2.tatame),
          )
        : Image.memory(icone!, width: tamanho, height: tamanho);
    return Semantics(
      label: redondo ? 'Prévia do ícone redondo' : 'Prévia do ícone quadrado',
      image: true,
      excludeSemantics: true,
      child: Container(
        width: tamanho,
        height: tamanho,
        decoration: BoxDecoration(
          boxShadow: sombraCartao,
          shape: redondo ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: redondo ? null : BorderRadius.circular(14),
        ),
        child: redondo
            ? ClipOval(child: conteudo)
            : ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: conteudo,
              ),
      ),
    );
  }
}
