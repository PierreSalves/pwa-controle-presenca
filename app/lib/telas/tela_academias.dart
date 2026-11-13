// Tela 13 — Administrador do sistema (só o superadmin): academias, o cadastro "Nova: nome ·
// primeiro professor" na própria lista e a carga inicial de alunos (telas 8b e 8c). Online.
import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../dados/cliente_api.dart';
import '../dados/repositorio_admin.dart';
import '../estado/dependencias.dart';
import 'componentes.dart';
import 'menu_app.dart';
import 'tela_alunos.dart' show descreverErroOnline;
import 'tela_importar_alunos.dart';
import 'tema.dart';

String _descreverErroAcademia(Object erro) => switch (erro) {
  ErroApi(codigo: 'email_ja_existe') =>
    'Já existe um usuário com o e-mail do professor.',
  ErroApi(codigo: 'dados_invalidos') =>
    'Confira os dados: nome curto até 15 letras, e-mail válido e senha com '
        'pelo menos 8 caracteres.',
  _ => descreverErroOnline(erro),
};

class TelaAcademias extends StatefulWidget {
  const TelaAcademias({super.key});

  @override
  State<TelaAcademias> createState() => _TelaAcademiasState();
}

class _TelaAcademiasState extends State<TelaAcademias> {
  late final RepositorioAdmin _repositorio;
  List<Academia>? _academias;
  String? _erro;
  bool _formularioAberto = false;
  bool _iniciado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciado) return;
    _iniciado = true;
    _repositorio = EscopoDependencias.obter(context).admin;
    unawaited(_carregar());
  }

  Future<void> _carregar() async {
    setState(() => _erro = null);
    try {
      final academias = await _repositorio.buscarAcademias();
      if (mounted) setState(() => _academias = academias);
    } on SessaoEncerrada {
      if (mounted) {
        await EscopoDependencias.obter(context).sessao.encerrarLocalmente();
      }
    } catch (erro) {
      if (mounted) setState(() => _erro = descreverErroOnline(erro));
    }
  }

  void _aoCriar(Academia academia) {
    setState(() => _formularioAberto = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${academia.nome} cadastrada. Passe o e-mail e a senha inicial para o professor.',
        ),
      ),
    );
    unawaited(_carregar());
  }

  /// Carga inicial: escolhe a academia (se houver mais de uma) e abre a importação para ela.
  Future<void> _abrirCargaInicial() async {
    final academias = _academias ?? const [];
    if (academias.isEmpty) return;
    final escolhida = academias.length == 1
        ? academias.single
        : await showDialog<Academia>(
            context: context,
            builder: (context) => SimpleDialog(
              title: const Text('Carga inicial para qual academia?'),
              children: [
                for (final a in academias)
                  SimpleDialogOption(
                    onPressed: () => Navigator.of(context).pop(a),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(a.nome),
                    ),
                  ),
              ],
            ),
          );
    if (escolhida == null || !mounted) return;
    final importou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TelaImportarAlunos(
          academiaId: escolhida.id,
          academiaNome: escolhida.nome,
        ),
      ),
    );
    if (importou == true && mounted) unawaited(_carregar());
  }

  @override
  Widget build(BuildContext context) {
    final academias = _academias;
    final apoio = const TextStyle(color: CoresV2.nevoa, fontSize: 13);
    final desktop = ehDesktop(context);
    return Scaffold(
      appBar: desktop
          ? null
          : AppBar(
              title: const Text('Academias'),
              centerTitle: true,
              actions: [
                IconButton(
                  tooltip: 'Nova academia',
                  icon: const Icon(Symbols.add),
                  onPressed: () => setState(() => _formularioAberto = true),
                ),
              ],
            ),
      drawer: obterMenuDoCelular(context),
      body: LarguraCelular(
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
                      'Academias',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  BotaoPrincipal(
                    rotulo: 'Nova academia',
                    icone: Symbols.add,
                    aoTocar: () => setState(() => _formularioAberto = true),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            if (_erro != null) ...[
              Text(_erro!, style: const TextStyle(color: CoresV2.ponta)),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _carregar,
                child: const Text('Tentar de novo'),
              ),
            ] else if (academias == null)
              const Padding(padding: EdgeInsets.all(24), child: Carregando())
            else ...[
              if (academias.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Nenhuma academia cadastrada ainda.'),
                )
              else
                Cartao(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Column(
                    children: [
                      for (var i = 0; i < academias.length; i++)
                        _LinhaAcademia(
                          academia: academias[i],
                          ultima: i == academias.length - 1,
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              if (_formularioAberto)
                _FormularioAcademia(
                  aoCriar: _aoCriar,
                  aoCancelar: () => setState(() => _formularioAberto = false),
                )
              else
                Cartao(
                  aoTocar: () => setState(() => _formularioAberto = true),
                  child: Row(
                    children: [
                      const Icon(Symbols.add, color: CoresV2.tatame),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Nova: nome · primeiro professor',
                          style: apoio.copyWith(fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: academias.isEmpty ? null : _abrirCargaInicial,
                icon: const Icon(Symbols.upload),
                label: const Text('Carga inicial (planilha de alunos)'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              const SizedBox(height: 8),
              Text('Só o administrador do sistema vê esta área.', style: apoio),
            ],
          ],
        ),
      ),
    );
  }
}

class _LinhaAcademia extends StatelessWidget {
  const _LinhaAcademia({required this.academia, required this.ultima});
  final Academia academia;
  final bool ultima;

  String _descreverQuantidades() => [
    '${academia.alunos} ${academia.alunos == 1 ? 'aluno' : 'alunos'}',
    '${academia.turmas} ${academia.turmas == 1 ? 'turma' : 'turmas'}',
    '${academia.usuarios} ${academia.usuarios == 1 ? 'usuário' : 'usuários'}',
  ].join(' · ');

  @override
  Widget build(BuildContext context) {
    return Container(
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
                Text(academia.nome, overflow: TextOverflow.ellipsis),
                Text(
                  _descreverQuantidades(),
                  style: const TextStyle(
                    color: CoresV2.nevoa,
                    fontSize: 13,
                    fontFeatures: numerosFixos,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Etiqueta(academia.ativa ? 'ativa' : 'inativa'),
        ],
      ),
    );
  }
}

class _FormularioAcademia extends StatefulWidget {
  const _FormularioAcademia({required this.aoCriar, required this.aoCancelar});
  final ValueChanged<Academia> aoCriar;
  final VoidCallback aoCancelar;

  @override
  State<_FormularioAcademia> createState() => _FormularioAcademiaState();
}

class _FormularioAcademiaState extends State<_FormularioAcademia> {
  final _formulario = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _nomeCurto = TextEditingController();
  final _professor = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _salvando = false;
  String? _erro;

  @override
  void dispose() {
    for (final c in [_nome, _nomeCurto, _professor, _email, _senha]) {
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
      final academia = await dependencias.admin.criarAcademia(
        nome: _nome.text,
        nomeCurto: _nomeCurto.text,
        professorNome: _professor.text,
        professorEmail: _email.text,
        senha: _senha.text,
      );
      if (mounted) widget.aoCriar(academia);
    } on SessaoEncerrada {
      await dependencias.sessao.encerrarLocalmente();
    } catch (erro) {
      if (mounted) setState(() => _erro = _descreverErroAcademia(erro));
    }
    if (mounted) setState(() => _salvando = false);
  }

  String? _exigir(String? valor, String mensagem) =>
      valor == null || valor.trim().isEmpty ? mensagem : null;

  @override
  Widget build(BuildContext context) {
    const apoio = TextStyle(color: CoresV2.nevoa, fontSize: 13);
    const titulo = TextStyle(fontWeight: FontWeight.w600);
    return Cartao(
      child: Form(
        key: _formulario,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Nova academia', style: titulo),
            const SizedBox(height: 10),
            TextFormField(
              controller: _nome,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nome da academia',
                isDense: true,
              ),
              validator: (v) => _exigir(v, 'Informe o nome'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _nomeCurto,
              maxLength: 15,
              decoration: const InputDecoration(
                labelText: 'Nome curto no celular (opcional)',
                isDense: true,
              ),
            ),
            const SizedBox(height: 6),
            const Text('Primeiro professor', style: titulo),
            const SizedBox(height: 10),
            TextFormField(
              controller: _professor,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nome do professor',
                isDense: true,
              ),
              validator: (v) => _exigir(v, 'Informe o nome do professor'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                hintText: 'professor@academia.com.br…',
                isDense: true,
              ),
              validator: (v) => v == null || !v.contains('@')
                  ? 'Informe um e-mail válido'
                  : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _senha,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: 'Senha inicial',
                isDense: true,
              ),
              validator: (v) =>
                  v == null || v.length < 8 ? 'Pelo menos 8 caracteres' : null,
            ),
            const SizedBox(height: 4),
            const Text(
              'Passe o e-mail e a senha para o professor; ele cadastra as turmas e '
              'as assistentes.',
              style: apoio,
            ),
            if (_erro != null) ...[
              const SizedBox(height: 8),
              // Região ao vivo: o leitor de tela anuncia o erro que voltou do servidor.
              Semantics(
                liveRegion: true,
                child: Text(
                  _erro!,
                  style: const TextStyle(color: CoresV2.ponta),
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Celular estreito: o botão principal desce para a linha de baixo.
            Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton(
                  onPressed: _salvando ? null : widget.aoCancelar,
                  child: const Text('Cancelar'),
                ),
                BotaoPrincipal(
                  rotulo: 'Criar academia',
                  icone: Symbols.check,
                  carregando: _salvando,
                  aoTocar: _criar,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
