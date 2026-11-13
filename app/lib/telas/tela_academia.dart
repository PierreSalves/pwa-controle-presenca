// Tela 13a / D7a — Academia aberta (só o superadmin): resumo, professores com "Redefinir senha"
// (13b, 13c / D7b, D7c), novo professor e carga inicial de alunos. Online, direto na API.
import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../dados/cliente_api.dart';
import '../dados/repositorio_admin.dart';
import '../estado/dependencias.dart';
import 'componentes.dart';
import 'formatacao.dart';
import 'tela_alunos.dart' show descreverErroOnline;
import 'tela_importar_alunos.dart';
import 'tema.dart';

const _palavrasDaSenha = [
  'tatame',
  'faixa',
  'kimono',
  'guarda',
  'montada',
  'raspagem',
  'chave',
  'treino',
];

/// Senha fácil de ditar por telefone: palavra do tatame, hífen e 4 algarismos ('tatame-7429').
String gerarSenhaParaDitar([Random? sorteio]) {
  final aleatorio = sorteio ?? Random.secure();
  final palavra = _palavrasDaSenha[aleatorio.nextInt(_palavrasDaSenha.length)];
  final numero = aleatorio.nextInt(10000).toString().padLeft(4, '0');
  return '$palavra-$numero';
}

String _descreverErroProfessor(Object erro) => switch (erro) {
  ErroApi(codigo: 'email_ja_existe') => 'Já existe um usuário com este e-mail.',
  ErroApi(codigo: 'usuario_nao_encontrado') =>
    'Este professor não está mais ativo nesta academia.',
  ErroApi(codigo: 'dados_invalidos') =>
    'Confira os dados: e-mail válido e senha com pelo menos 8 caracteres.',
  _ => descreverErroOnline(erro),
};

class TelaAcademia extends StatefulWidget {
  const TelaAcademia({
    super.key,
    required this.academia,
    this.embutido = false,
    this.aoAlterar,
  });

  final Academia academia;

  /// No desktop a academia abre ao lado da lista, sem barra própria (D7a).
  final bool embutido;

  /// Chamado depois de criar professor ou importar alunos (a lista recarrega os totais).
  final VoidCallback? aoAlterar;

  @override
  State<TelaAcademia> createState() => _TelaAcademiaState();
}

class _TelaAcademiaState extends State<TelaAcademia> {
  List<ProfessorDaAcademia>? _professores;
  String? _erro;
  bool _iniciado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciado) return;
    _iniciado = true;
    unawaited(_carregar());
  }

  Future<void> _carregar() async {
    final dependencias = EscopoDependencias.obter(context);
    setState(() => _erro = null);
    try {
      final professores = await dependencias.admin.buscarProfessores(
        widget.academia.id,
      );
      if (mounted) setState(() => _professores = professores);
    } on SessaoEncerrada {
      await dependencias.sessao.encerrarLocalmente();
    } catch (erro) {
      if (mounted) setState(() => _erro = descreverErroOnline(erro));
    }
  }

  Future<void> _criarProfessor() async {
    final criou = await showDialog<bool>(
      context: context,
      builder: (_) => _DialogoNovoProfessor(academiaId: widget.academia.id),
    );
    if (criou != true || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Professor cadastrado. Passe o e-mail e a senha para ele.',
        ),
      ),
    );
    widget.aoAlterar?.call();
    unawaited(_carregar());
  }

  Future<void> _abrirCargaInicial() async {
    final importou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TelaImportarAlunos(
          academiaId: widget.academia.id,
          academiaNome: widget.academia.nome,
        ),
      ),
    );
    if (importou == true && mounted) widget.aoAlterar?.call();
  }

  @override
  Widget build(BuildContext context) {
    final academia = widget.academia;
    final conteudo = ListView(
      padding: widget.embutido
          ? const EdgeInsets.all(18)
          : const EdgeInsets.all(16),
      children: [
        if (widget.embutido) ...[
          Text(
            academia.nome,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Pilula(
              academia.ativa ? 'ativa' : 'inativa',
              destaque: academia.ativa,
            ),
            _Pilula(
              '${academia.alunos} ${academia.alunos == 1 ? 'aluno' : 'alunos'}',
            ),
            _Pilula(
              '${academia.turmas} ${academia.turmas == 1 ? 'turma' : 'turmas'}',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Cartao(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Professores',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              ..._montarProfessores(),
            ],
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _criarProfessor,
          icon: const Icon(Symbols.person_add),
          label: const Text('Novo professor'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _abrirCargaInicial,
          icon: const Icon(Symbols.upload),
          label: const Text('Carga inicial de alunos'),
        ),
      ],
    );
    if (widget.embutido) return conteudo;
    return Scaffold(
      appBar: AppBar(title: Text(academia.nome), centerTitle: true),
      body: LarguraCelular(child: conteudo),
    );
  }

  List<Widget> _montarProfessores() {
    final professores = _professores;
    if (_erro != null) {
      return [
        const SizedBox(height: 8),
        Text(_erro!, style: const TextStyle(color: CoresV2.ponta)),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _carregar,
          child: const Text('Tentar de novo'),
        ),
      ];
    }
    if (professores == null) {
      return const [Padding(padding: EdgeInsets.all(16), child: Carregando())];
    }
    if (professores.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Text('Nenhum professor cadastrado.'),
        ),
      ];
    }
    return [
      for (var i = 0; i < professores.length; i++)
        _LinhaProfessor(
          professor: professores[i],
          ultima: i == professores.length - 1,
          aoRedefinir: () => abrirRedefinicaoSenha(
            context,
            academiaId: widget.academia.id,
            professor: professores[i],
          ),
        ),
    ];
  }
}

class _Pilula extends StatelessWidget {
  const _Pilula(this.texto, {this.destaque = false});
  final String texto;
  final bool destaque;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: destaque ? CoresV2.okClaro : CoresV2.cartao,
      borderRadius: BorderRadius.circular(999),
      boxShadow: destaque ? null : sombraCartao,
    ),
    child: Text(
      texto,
      style: TextStyle(
        fontSize: 13,
        color: destaque ? CoresV2.ok : CoresV2.grafite,
        fontFeatures: numerosFixos,
      ),
    ),
  );
}

class _LinhaProfessor extends StatelessWidget {
  const _LinhaProfessor({
    required this.professor,
    required this.ultima,
    required this.aoRedefinir,
  });

  final ProfessorDaAcademia professor;
  final bool ultima;
  final VoidCallback aoRedefinir;

  String _descreverAcesso() {
    if (!professor.ativo) return 'desativado';
    final ultimo = professor.ultimoLoginEm;
    return ultimo == null
        ? 'nunca entrou'
        : 'último acesso ${formatarDataDoInstante(ultimo)}';
  }

  @override
  Widget build(BuildContext context) {
    final dados = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          professor.nome,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        Text(
          '${professor.email} · ${_descreverAcesso()}',
          style: const TextStyle(
            color: CoresV2.nevoa,
            fontSize: 13,
            fontFeatures: numerosFixos,
          ),
        ),
      ],
    );
    final botao = professor.ativo
        ? OutlinedButton.icon(
            onPressed: aoRedefinir,
            icon: const Icon(Symbols.key),
            label: const Text('Redefinir senha'),
          )
        : null;
    return Container(
      decoration: BoxDecoration(
        border: ultima
            ? null
            : const Border(bottom: BorderSide(color: CoresV2.linha)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      // Largo (desktop): o botão fica à direita, como a tabela do D7a.
      child: LayoutBuilder(
        builder: (context, limites) => limites.maxWidth >= 480
            ? Row(
                children: [
                  Expanded(child: dados),
                  if (botao != null) ...[const SizedBox(width: 10), botao],
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  dados,
                  if (botao != null) ...[const SizedBox(height: 8), botao],
                ],
              ),
      ),
    );
  }
}

/// Abre a redefinição de senha: painel que sobe de baixo no celular (13b, 13c) e diálogo central
/// no desktop (D7b, D7c).
Future<void> abrirRedefinicaoSenha(
  BuildContext context, {
  required String academiaId,
  required ProfessorDaAcademia professor,
}) async {
  final painel = _PainelSenha(academiaId: academiaId, professor: professor);
  if (ehDesktop(context)) {
    await showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(padding: const EdgeInsets.all(22), child: painel),
        ),
      ),
    );
    return;
  }
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: CoresV2.papel,
    builder: (context) => Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        18 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: painel,
    ),
  );
}

class _PainelSenha extends StatefulWidget {
  const _PainelSenha({required this.academiaId, required this.professor});
  final String academiaId;
  final ProfessorDaAcademia professor;

  @override
  State<_PainelSenha> createState() => _PainelSenhaState();
}

class _PainelSenhaState extends State<_PainelSenha> {
  final _senha = TextEditingController();
  bool _oculta = true;
  bool _salvando = false;
  bool _copiada = false;
  String? _erro;

  /// Preenchida depois que a API aceitou: mostra a confirmação (13c / D7c).
  String? _senhaDefinida;

  @override
  void dispose() {
    _senha.dispose();
    super.dispose();
  }

  String get _primeiroNome => widget.professor.nome.trim().split(' ').first;

  void _gerar() => setState(() {
    _senha.text = gerarSenhaParaDitar();
    _oculta = false;
    _erro = null;
  });

  Future<void> _redefinir() async {
    if (_salvando) return;
    final senha = _senha.text;
    if (senha.length < 8) {
      setState(() => _erro = 'A senha precisa ter pelo menos 8 caracteres.');
      return;
    }
    final dependencias = EscopoDependencias.obter(context);
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      await dependencias.admin.redefinirSenhaProfessor(
        academiaId: widget.academiaId,
        professorId: widget.professor.id,
        senha: senha,
      );
      if (mounted) setState(() => _senhaDefinida = senha);
    } on SessaoEncerrada {
      if (mounted) Navigator.of(context).pop();
      await dependencias.sessao.encerrarLocalmente();
    } catch (erro) {
      if (mounted) setState(() => _erro = _descreverErroProfessor(erro));
    }
    if (mounted) setState(() => _salvando = false);
  }

  Future<void> _copiar() async {
    await Clipboard.setData(ClipboardData(text: _senhaDefinida!));
    if (mounted) setState(() => _copiada = true);
  }

  @override
  Widget build(BuildContext context) {
    final desktop = ehDesktop(context);
    final senhaDefinida = _senhaDefinida;
    return SingleChildScrollView(
      child: senhaDefinida == null
          ? _montarFormulario(desktop)
          : _montarPronto(senhaDefinida, desktop),
    );
  }

  Widget _montarFormulario(bool desktop) {
    final cancelar = OutlinedButton(
      onPressed: _salvando ? null : () => Navigator.of(context).pop(),
      child: const Text('Cancelar'),
    );
    final gerar = OutlinedButton.icon(
      onPressed: _salvando ? null : _gerar,
      icon: const Icon(Symbols.wand_stars),
      label: const Text('Gerar senha'),
    );
    final redefinir = BotaoPrincipal(
      rotulo: 'Redefinir senha',
      icone: Symbols.arrow_forward,
      carregando: _salvando,
      largo: !desktop,
      aoTocar: _redefinir,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Redefinir a senha de ${widget.professor.nome}',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _senha,
          autofocus: true,
          obscureText: _oculta,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            labelText: 'Nova senha',
            suffixIcon: IconButton(
              tooltip: _oculta ? 'Mostrar senha' : 'Esconder senha',
              style: IconButton.styleFrom(backgroundColor: Colors.transparent),
              icon: Icon(_oculta ? Symbols.visibility : Symbols.visibility_off),
              onPressed: () => setState(() => _oculta = !_oculta),
            ),
          ),
          onSubmitted: (_) => _redefinir(),
        ),
        if (!desktop) ...[const SizedBox(height: 10), gerar],
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: CoresV2.avisoClaro,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$_primeiroNome sai de todos os aparelhos e passa a entrar com a '
            'nova senha.',
            style: const TextStyle(color: CoresV2.aviso, fontSize: 13),
          ),
        ),
        if (_erro != null) ...[
          const SizedBox(height: 10),
          // Região ao vivo: o leitor de tela anuncia o erro.
          Semantics(
            liveRegion: true,
            child: Text(_erro!, style: const TextStyle(color: CoresV2.ponta)),
          ),
        ],
        const SizedBox(height: 14),
        if (desktop)
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [gerar, cancelar, redefinir],
          )
        else ...[
          redefinir,
          const SizedBox(height: 8),
          cancelar,
        ],
      ],
    );
  }

  Widget _montarPronto(String senha, bool desktop) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Região ao vivo: o leitor de tela anuncia que deu certo.
        Semantics(
          liveRegion: true,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: CoresV2.okClaro,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Symbols.check, size: 16, color: CoresV2.ok),
                  SizedBox(width: 6),
                  Text(
                    'Senha redefinida',
                    style: TextStyle(color: CoresV2.ok, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Passe a nova senha para '),
              TextSpan(
                text: widget.professor.nome,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const TextSpan(text: '. Ela não aparece de novo.'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Cartao(
          child: Row(
            children: [
              Expanded(
                child: SelectableText(
                  senha,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _copiar,
                icon: Icon(_copiada ? Symbols.check : Symbols.content_copy),
                label: Text(_copiada ? 'Copiada' : 'Copiar'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'E-mail para entrar: ${widget.professor.email}',
          style: const TextStyle(color: CoresV2.nevoa, fontSize: 13),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: desktop ? Alignment.centerRight : Alignment.center,
          child: BotaoPrincipal(
            rotulo: 'Concluir',
            icone: Symbols.check,
            largo: !desktop,
            aoTocar: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }
}

class _DialogoNovoProfessor extends StatefulWidget {
  const _DialogoNovoProfessor({required this.academiaId});
  final String academiaId;

  @override
  State<_DialogoNovoProfessor> createState() => _DialogoNovoProfessorState();
}

class _DialogoNovoProfessorState extends State<_DialogoNovoProfessor> {
  final _formulario = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _salvando = false;
  String? _erro;

  @override
  void dispose() {
    for (final c in [_nome, _email, _senha]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _criar() async {
    if (_salvando || !_formulario.currentState!.validate()) return;
    final dependencias = EscopoDependencias.obter(context);
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      await dependencias.admin.criarProfessor(
        academiaId: widget.academiaId,
        nome: _nome.text,
        email: _email.text,
        senha: _senha.text,
      );
      if (mounted) Navigator.of(context).pop(true);
      return;
    } on SessaoEncerrada {
      if (mounted) Navigator.of(context).pop();
      await dependencias.sessao.encerrarLocalmente();
      return;
    } catch (erro) {
      if (mounted) setState(() => _erro = _descreverErroProfessor(erro));
    }
    if (mounted) setState(() => _salvando = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo professor'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formulario,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nome,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(labelText: 'E-mail'),
                validator: (v) => v == null || !v.contains('@')
                    ? 'Informe um e-mail válido'
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _senha,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(labelText: 'Senha inicial'),
                validator: (v) => v == null || v.length < 8
                    ? 'Pelo menos 8 caracteres'
                    : null,
              ),
              if (_erro != null) ...[
                const SizedBox(height: 10),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _erro!,
                    style: const TextStyle(color: CoresV2.ponta),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _salvando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        BotaoPrincipal(
          rotulo: 'Cadastrar',
          icone: Symbols.check,
          carregando: _salvando,
          aoTocar: _criar,
        ),
      ],
    );
  }
}
