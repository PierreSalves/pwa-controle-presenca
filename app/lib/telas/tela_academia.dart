// Tela 13a / D7a — Academia aberta (só o superadmin): resumo, usuários (professores e assistentes)
// com o painel de cada um (13d–13g: mudar o acesso, remover da academia e "Redefinir senha", 13b,
// 13c / D7b, D7c), novo professor e carga inicial de alunos. Online, direto na API.
// Wireframes: docs/telas/wireframes-senha-professor.html e wireframes-admin-usuarios.html (v9).
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
    'Este usuário não está mais ativo nesta academia.',
  ErroApi(codigo: 'ultimo_professor') =>
    'É o único professor da academia. Crie outro professor antes.',
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
  List<UsuarioDaAcademia>? _usuarios;
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
      final usuarios = await dependencias.admin.buscarUsuarios(
        widget.academia.id,
      );
      if (mounted) setState(() => _usuarios = usuarios);
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

  Future<void> _abrirUsuario(UsuarioDaAcademia usuario) async {
    final usuarios = _usuarios ?? const [];
    final unicoProfessor =
        usuario.ehProfessor && usuarios.where((u) => u.ehProfessor).length == 1;
    final mensageiro = ScaffoldMessenger.of(context);
    final resultado = await _abrirPainelUsuario(
      context,
      academiaId: widget.academia.id,
      usuario: usuario,
      unicoProfessor: unicoProfessor,
    );
    if (!mounted || resultado == null) return;
    if (resultado == _ResultadoPainel.redefinirSenha) {
      await abrirRedefinicaoSenha(
        context,
        academiaId: widget.academia.id,
        professor: usuario,
      );
      return;
    }
    mensageiro.hideCurrentSnackBar();
    mensageiro.showSnackBar(
      SnackBar(
        content: Text(
          resultado == _ResultadoPainel.removido
              ? '${usuario.nome} não faz mais parte da academia.'
              : 'Acesso de ${usuario.nome} salvo. A pessoa entra de novo nos aparelhos.',
        ),
      ),
    );
    widget.aoAlterar?.call();
    unawaited(_carregar());
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
                'Usuários',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              ..._montarUsuarios(),
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

  List<Widget> _montarUsuarios() {
    final usuarios = _usuarios;
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
    if (usuarios == null) {
      return const [Padding(padding: EdgeInsets.all(16), child: Carregando())];
    }
    if (usuarios.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Text('Nenhum usuário ativo.'),
        ),
      ];
    }
    return [
      for (var i = 0; i < usuarios.length; i++)
        _LinhaUsuario(
          usuario: usuarios[i],
          ultima: i == usuarios.length - 1,
          aoTocar: () => _abrirUsuario(usuarios[i]),
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

/// Linha da lista de usuários (13a): nome, e-mail e último acesso, o tipo numa etiqueta e a seta.
class _LinhaUsuario extends StatelessWidget {
  const _LinhaUsuario({
    required this.usuario,
    required this.ultima,
    required this.aoTocar,
  });

  final UsuarioDaAcademia usuario;
  final bool ultima;
  final VoidCallback aoTocar;

  String _descreverAcesso() {
    final ultimo = usuario.ultimoLoginEm;
    return ultimo == null
        ? 'nunca entrou'
        : 'último acesso ${formatarDataDoInstante(ultimo)}';
  }

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '${usuario.nome}, ${usuario.tipo}',
    child: InkWell(
      onTap: aoTocar,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        decoration: BoxDecoration(
          border: ultima
              ? null
              : const Border(bottom: BorderSide(color: CoresV2.linha)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    usuario.nome,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${usuario.email} · ${_descreverAcesso()}',
                    style: const TextStyle(
                      color: CoresV2.nevoa,
                      fontSize: 13,
                      fontFeatures: numerosFixos,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _EtiquetaTipo(usuario.tipo),
            const Icon(Symbols.chevron_right, color: CoresV2.nevoa),
          ],
        ),
      ),
    ),
  );
}

class _EtiquetaTipo extends StatelessWidget {
  const _EtiquetaTipo(this.tipo);
  final String tipo;

  @override
  Widget build(BuildContext context) {
    final professor = tipo == 'professor';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: professor ? CoresV2.tatameClaro : CoresV2.menuLateral,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        tipo,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: professor ? CoresV2.tatame : CoresV2.nevoa,
        ),
      ),
    );
  }
}

/// O que aconteceu no painel do usuário.
enum _ResultadoPainel { acessoSalvo, removido, redefinirSenha }

/// Abre o painel do usuário: de baixo no celular (13d, 13f) e diálogo central no desktop.
Future<_ResultadoPainel?> _abrirPainelUsuario(
  BuildContext context, {
  required String academiaId,
  required UsuarioDaAcademia usuario,
  required bool unicoProfessor,
}) {
  final painel = _PainelUsuario(
    academiaId: academiaId,
    usuario: usuario,
    unicoProfessor: unicoProfessor,
  );
  if (ehDesktop(context)) {
    return showDialog<_ResultadoPainel>(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(padding: const EdgeInsets.all(22), child: painel),
        ),
      ),
    );
  }
  return showModalBottomSheet<_ResultadoPainel>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: CoresV2.papel,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      child: painel,
    ),
  );
}

class _PainelUsuario extends StatefulWidget {
  const _PainelUsuario({
    required this.academiaId,
    required this.usuario,
    required this.unicoProfessor,
  });

  final String academiaId;
  final UsuarioDaAcademia usuario;
  final bool unicoProfessor;

  @override
  State<_PainelUsuario> createState() => _PainelUsuarioState();
}

class _PainelUsuarioState extends State<_PainelUsuario> {
  late String _tipo = widget.usuario.tipo;
  bool _salvando = false;
  String? _erro;

  Future<void> _executar(
    Future<void> Function() acao,
    _ResultadoPainel resultado,
  ) async {
    final dependencias = EscopoDependencias.obter(context);
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      await acao();
      if (mounted) Navigator.of(context).pop(resultado);
      return;
    } on SessaoEncerrada {
      if (mounted) Navigator.of(context).pop();
      await dependencias.sessao.encerrarLocalmente();
      return;
    } on SemConexao {
      _erro = 'Sem internet. Esta mudança precisa de conexão.';
    } catch (erro) {
      _erro = _descreverErroProfessor(erro);
    }
    if (mounted) setState(() => _salvando = false);
  }

  Future<void> _salvarAcesso() {
    final admin = EscopoDependencias.obter(context).admin;
    return _executar(
      () => admin.definirTipoUsuario(
        academiaId: widget.academiaId,
        usuarioId: widget.usuario.id,
        tipo: _tipo,
      ),
      _ResultadoPainel.acessoSalvo,
    );
  }

  Future<void> _remover() async {
    final usuario = widget.usuario;
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remover ${usuario.nome} da academia?'),
        content: const Text(
          'A pessoa sai de todos os aparelhos e não consegue mais entrar. As presenças e '
          'cadastros que ela lançou continuam nos relatórios. Para voltar, o professor '
          'reativa em Usuários.',
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
    if (confirmou != true || !mounted) return;
    final admin = EscopoDependencias.obter(context).admin;
    await _executar(
      () => admin.removerUsuario(
        academiaId: widget.academiaId,
        usuarioId: usuario.id,
      ),
      _ResultadoPainel.removido,
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = widget.usuario;
    const apoio = TextStyle(color: CoresV2.nevoa, fontSize: 13);
    final bloqueado = widget.unicoProfessor;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          usuario.nome,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        Text(usuario.email, style: apoio),
        const SizedBox(height: 14),
        const Text('Acesso na academia', style: apoio),
        const SizedBox(height: 6),
        SegmentedButton<String>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: 'professor', label: Text('Professor')),
            ButtonSegment(value: 'assistente', label: Text('Assistente')),
          ],
          selected: {_tipo},
          onSelectionChanged: bloqueado || _salvando
              ? null
              : (escolha) => setState(() => _tipo = escolha.first),
        ),
        const SizedBox(height: 8),
        if (bloqueado)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: CoresV2.avisoClaro,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'É o único professor da academia. Para mudar o acesso ou remover, crie outro '
              'professor antes.',
              style: TextStyle(color: CoresV2.aviso, fontSize: 13),
            ),
          )
        else
          Text(
            _tipo == 'professor'
                ? 'Professor vê todas as turmas e cadastra usuários. Ao salvar, a pessoa sai dos '
                      'aparelhos e entra de novo.'
                : 'Assistente lança presenças e cadastra alunos e turmas, só nas turmas a que tem '
                      'acesso. Ao salvar, a pessoa sai dos aparelhos e entra de novo.',
            style: apoio,
          ),
        if (_erro != null) ...[
          const SizedBox(height: 8),
          Semantics(
            liveRegion: true,
            child: Text(_erro!, style: const TextStyle(color: CoresV2.ponta)),
          ),
        ],
        const SizedBox(height: 12),
        if (!bloqueado)
          BotaoPrincipal(
            rotulo: 'Salvar acesso',
            rotuloCarregando: 'Salvando…',
            icone: Symbols.check,
            largo: true,
            carregando: _salvando,
            aoTocar: _tipo == usuario.tipo ? null : _salvarAcesso,
          ),
        if (usuario.ehProfessor) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _salvando
                ? null
                : () =>
                      Navigator.of(context)
                          .pop(_ResultadoPainel.redefinirSenha),
            icon: const Icon(Symbols.key),
            label: const Text('Redefinir senha'),
          ),
        ],
        const SizedBox(height: 8),
        OutlinedButton.icon(
          style: estiloDestrutivo,
          onPressed: bloqueado || _salvando ? null : _remover,
          icon: const Icon(Symbols.person_remove),
          label: const Text('Remover da academia'),
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}

/// Abre a redefinição de senha: painel que sobe de baixo no celular (13b, 13c) e diálogo central
/// no desktop (D7b, D7c).
Future<void> abrirRedefinicaoSenha(
  BuildContext context, {
  required String academiaId,
  required UsuarioDaAcademia professor,
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
  final UsuarioDaAcademia professor;

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
