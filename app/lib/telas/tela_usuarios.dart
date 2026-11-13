// Tela 11 — Usuários (só o professor): lista de professores e assistentes e, na própria lista,
// o cadastro ("Novo: nome · e-mail · tipo · turmas") e a edição de cada um. Online.
import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../dados/cliente_api.dart';
import '../dados/repositorio_turmas.dart';
import '../dados/repositorio_usuarios.dart';
import '../estado/dependencias.dart';
import 'componentes.dart';
import 'tema.dart';
import 'tela_alunos.dart' show descreverErroOnline;

String _descreverErroUsuario(Object erro) => switch (erro) {
  ErroApi(codigo: 'email_ja_existe') => 'Já existe um usuário com este e-mail.',
  ErroApi(codigo: 'nao_pode_alterar_o_proprio_acesso') =>
    'Você não pode mudar o próprio tipo nem se desativar.',
  ErroApi(codigo: 'use_a_troca_da_propria_senha') =>
    'Não é possível redefinir a própria senha por aqui.',
  ErroApi(codigo: 'dados_invalidos') =>
    'Confira os dados: e-mail válido e senha com pelo menos 8 caracteres.',
  _ => descreverErroOnline(erro),
};

const _novo = 'novo';

class TelaUsuarios extends StatefulWidget {
  const TelaUsuarios({super.key});

  @override
  State<TelaUsuarios> createState() => _TelaUsuariosState();
}

class _TelaUsuariosState extends State<TelaUsuarios> {
  late final Dependencias _dependencias;
  List<UsuarioDaAcademia>? _usuarios;
  List<ResumoTurma> _turmas = [];
  String? _erro;
  String? _aberto;
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
      final resultados = await Future.wait([
        _dependencias.usuarios.buscarUsuarios(),
        _dependencias.turmas.buscarTurmas(),
      ]);
      if (!mounted) return;
      setState(() {
        _usuarios = resultados[0] as List<UsuarioDaAcademia>;
        _turmas = resultados[1] as List<ResumoTurma>;
      });
    } on SessaoEncerrada {
      await _dependencias.sessao.encerrarLocalmente();
    } catch (erro) {
      if (mounted) setState(() => _erro = descreverErroOnline(erro));
    }
  }

  void _alternar(String chave) =>
      setState(() => _aberto = _aberto == chave ? null : chave);

  Future<void> _aoSalvar(String mensagem) async {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensagem)));
    setState(() => _aberto = null);
    await _carregar();
    // O acesso às turmas muda o que cada aparelho recebe (inclusive o deste professor).
    unawaited(_dependencias.coordenador.sincronizar());
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final usuarios = _usuarios;
    final euId = _dependencias.sessao.usuario?.id;
    return Scaffold(
      appBar: AppBar(
        // No desktop o menu lateral faz o papel do voltar nas telas principais.
        automaticallyImplyLeading: !ehDesktop(context),
        title: const Text('Usuários'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Novo usuário',
            icon: const Icon(Symbols.add),
            onPressed: usuarios == null
                ? null
                : () => setState(() => _aberto = _novo),
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
            ] else if (usuarios == null)
              const Padding(padding: EdgeInsets.all(24), child: Carregando())
            else ...[
              for (final u in usuarios) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    u.nome,
                    style: TextStyle(
                      color: u.ativo ? null : cores.onSurfaceVariant,
                    ),
                  ),
                  trailing: Text(
                    u.ativo ? u.tipo : '${u.tipo} · inativo',
                    style: TextStyle(
                      color: cores.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                  onTap: () => _alternar(u.id),
                ),
                if (_aberto == u.id)
                  _FormularioUsuario(
                    key: ValueKey(u.id),
                    usuario: u,
                    ehVoce: u.id == euId,
                    turmas: _turmas,
                    aoSalvar: _aoSalvar,
                  ),
                const Divider(height: 1),
              ],
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: cores.outline),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    ListTile(
                      title: Text(
                        'Novo: nome · e-mail · tipo · turmas',
                        style: TextStyle(color: cores.onSurfaceVariant),
                      ),
                      onTap: () => _alternar(_novo),
                    ),
                    if (_aberto == _novo)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: _FormularioUsuario(
                          key: const ValueKey(_novo),
                          usuario: null,
                          ehVoce: false,
                          turmas: _turmas,
                          aoSalvar: _aoSalvar,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FormularioUsuario extends StatefulWidget {
  const _FormularioUsuario({
    super.key,
    required this.usuario,
    required this.ehVoce,
    required this.turmas,
    required this.aoSalvar,
  });

  /// Null para cadastrar um usuário novo.
  final UsuarioDaAcademia? usuario;
  final bool ehVoce;
  final List<ResumoTurma> turmas;
  final Future<void> Function(String mensagem) aoSalvar;

  @override
  State<_FormularioUsuario> createState() => _FormularioUsuarioState();
}

class _FormularioUsuarioState extends State<_FormularioUsuario> {
  final _formulario = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.usuario?.nome);
  late final _email = TextEditingController(text: widget.usuario?.email);
  final _senha = TextEditingController();
  late String _tipo = widget.usuario?.tipo ?? 'assistente';
  late bool _ativo = widget.usuario?.ativo ?? true;
  late final Set<String> _turmaIds = {...?widget.usuario?.turmaIds};
  bool _salvando = false;

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _executar(
    Future<String> Function(RepositorioUsuarios repositorio) acao,
  ) async {
    if (_salvando) return;
    setState(() => _salvando = true);
    final dependencias = EscopoDependencias.obter(context);
    final mensageiro = ScaffoldMessenger.of(context);
    try {
      final mensagem = await acao(dependencias.usuarios);
      await widget.aoSalvar(mensagem);
    } on SessaoEncerrada {
      await dependencias.sessao.encerrarLocalmente();
    } catch (erro) {
      mensageiro.showSnackBar(
        SnackBar(content: Text(_descreverErroUsuario(erro))),
      );
    }
    if (mounted) setState(() => _salvando = false);
  }

  Future<void> _salvar() async {
    if (!_formulario.currentState!.validate()) return;
    final usuario = widget.usuario;
    await _executar((repositorio) async {
      if (usuario == null) {
        await repositorio.criarUsuario(
          nome: _nome.text,
          email: _email.text,
          tipo: _tipo,
          senha: _senha.text,
          turmaIds: _turmaIds,
        );
        return 'Usuário cadastrado. Passe a senha inicial para a pessoa.';
      }
      await repositorio.alterarUsuario(
        usuario.id,
        nome: _nome.text,
        email: _email.text,
        tipo: _tipo,
        ativo: _ativo,
      );
      final mudou =
          usuario.turmaIds.length != _turmaIds.length ||
          !usuario.turmaIds.containsAll(_turmaIds);
      if (mudou) await repositorio.definirTurmas(usuario.id, _turmaIds);
      return 'Alterações salvas.';
    });
  }

  Future<void> _redefinirSenha() async {
    final usuario = widget.usuario!;
    if (_senha.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A nova senha precisa ter pelo menos 8 caracteres.'),
        ),
      );
      return;
    }
    await _executar((repositorio) async {
      await repositorio.redefinirSenha(usuario.id, _senha.text);
      return 'Senha de ${usuario.nome} redefinida. Passe a nova senha para a pessoa.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final apoio = TextStyle(color: cores.onSurfaceVariant, fontSize: 13);
    final novo = widget.usuario == null;
    // O professor sempre vê todas as turmas; o acesso só restringe a assistente.
    final mostrarTurmas = _tipo == 'assistente' || novo;
    return Form(
      key: _formulario,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nome,
              decoration: const InputDecoration(
                labelText: 'Nome',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (v) => (v == null || !v.contains('@'))
                  ? 'Informe um e-mail válido'
                  : null,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _tipo,
              decoration: const InputDecoration(
                labelText: 'Tipo',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(
                  value: 'assistente',
                  child: Text('assistente'),
                ),
                DropdownMenuItem(value: 'professor', child: Text('professor')),
              ],
              onChanged: widget.ehVoce
                  ? null
                  : (v) => setState(() => _tipo = v ?? _tipo),
            ),
            if (novo) ...[
              const SizedBox(height: 10),
              TextFormField(
                controller: _senha,
                decoration: const InputDecoration(
                  labelText: 'Senha inicial',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (v) => (v == null || v.length < 8)
                    ? 'Pelo menos 8 caracteres'
                    : null,
              ),
              const SizedBox(height: 4),
              Text('Passe a senha para a pessoa.', style: apoio),
            ] else
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Ativo'),
                subtitle: widget.ehVoce
                    ? const Text('Você não pode se desativar.')
                    : const Text('Desativar encerra o acesso na hora.'),
                value: _ativo,
                onChanged: widget.ehVoce
                    ? null
                    : (v) => setState(() => _ativo = v),
              ),
            if (mostrarTurmas) ...[
              const SizedBox(height: 8),
              Text('Turmas que acessa', style: apoio),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final t in widget.turmas)
                    FilterChip(
                      label: Text(t.nome),
                      selected: _turmaIds.contains(t.id),
                      onSelected: (marcada) => setState(
                        () => marcada
                            ? _turmaIds.add(t.id)
                            : _turmaIds.remove(t.id),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            BotaoPrincipal(
              rotulo: novo ? 'Cadastrar' : 'Salvar',
              icone: novo ? Symbols.person_add : Symbols.check,
              largo: true,
              carregando: _salvando,
              aoTocar: _salvar,
            ),
            if (!novo && !widget.ehVoce) ...[
              const SizedBox(height: 16),
              Text('Esqueceu a senha?', style: apoio),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _senha,
                      decoration: const InputDecoration(
                        labelText: 'Nova senha',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _salvando ? null : _redefinirSenha,
                    child: const Text('Redefinir'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
