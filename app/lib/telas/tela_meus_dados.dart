// Tela 12 — Meus dados e senha (docs/telas/wireframes-meus-dados.html): dados de quem está logado,
// só para consulta, e a troca da própria senha. Para todos os usuários. A troca é online.
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../dados/cliente_api.dart';
import '../estado/dependencias.dart';
import 'componentes.dart';
import 'tela_alunos.dart' show descreverErroOnline;
import 'tema.dart';

String _descreverTipo(String tipo) => switch (tipo) {
  'superadmin' => 'administrador do sistema',
  _ => tipo,
};

class TelaMeusDados extends StatelessWidget {
  const TelaMeusDados({super.key});

  @override
  Widget build(BuildContext context) {
    final desktop = ehDesktop(context);
    final dados = const _CartaoDados();
    const senha = _CartaoSenha();
    return Scaffold(
      appBar: desktop
          ? null
          : AppBar(title: const Text('Meus dados'), centerTitle: true),
      body: LarguraCelular(
        child: ListView(
          padding: desktop
              ? const EdgeInsets.fromLTRB(28, 24, 28, 28)
              : const EdgeInsets.all(16),
          children: [
            if (desktop) ...[
              const Text(
                'Meus dados e senha',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              // D7: dados e troca de senha lado a lado.
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: dados),
                    const SizedBox(width: 18),
                    const Expanded(child: senha),
                  ],
                ),
              ),
            ] else ...[
              dados,
              const SizedBox(height: 16),
              senha,
            ],
          ],
        ),
      ),
    );
  }
}

class _CartaoDados extends StatelessWidget {
  const _CartaoDados();

  @override
  Widget build(BuildContext context) {
    final sessao = EscopoDependencias.obter(context).sessao;
    final usuario = sessao.usuario;
    if (usuario == null) return const SizedBox.shrink();
    final linhas = [
      ('Nome', usuario.nome),
      ('E-mail', usuario.email),
      ('Tipo', _descreverTipo(usuario.tipo)),
      if (usuario.tenantId != null) ('Academia', sessao.nomeAcademia ?? ''),
    ];
    final aviso = switch (usuario.tipo) {
      'assistente' => 'Para mudar nome ou e-mail, fale com o professor.',
      'professor' => 'Para mudar nome ou e-mail, use a tela de Usuários.',
      _ => null,
    };
    return Cartao(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < linhas.length; i++)
            Container(
              constraints: const BoxConstraints(minHeight: 44),
              decoration: BoxDecoration(
                border: i == linhas.length - 1 && aviso == null
                    ? null
                    : const Border(bottom: BorderSide(color: CoresV2.linha)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Text(
                    linhas[i].$1,
                    style: const TextStyle(color: CoresV2.nevoa, fontSize: 13),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      linhas[i].$2,
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          if (aviso != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                aviso,
                style: const TextStyle(color: CoresV2.nevoa, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}

class _CartaoSenha extends StatefulWidget {
  const _CartaoSenha();

  @override
  State<_CartaoSenha> createState() => _CartaoSenhaState();
}

class _CartaoSenhaState extends State<_CartaoSenha> {
  final _formulario = GlobalKey<FormState>();
  final _atual = TextEditingController();
  final _nova = TextEditingController();
  final _confirmacao = TextEditingController();
  bool _mostrarAtual = false;
  bool _mostrarNova = false;
  bool _trocando = false;
  bool _trocada = false;

  /// Erro que voltou do servidor para a senha atual (aparece no próprio campo).
  String? _erroAtual;

  @override
  void dispose() {
    _atual.dispose();
    _nova.dispose();
    _confirmacao.dispose();
    super.dispose();
  }

  Future<void> _trocar() async {
    setState(() {
      _erroAtual = null;
      _trocada = false;
    });
    if (_trocando || !_formulario.currentState!.validate()) return;
    final dependencias = EscopoDependencias.obter(context);
    setState(() => _trocando = true);
    try {
      await dependencias.conta.trocarSenha(
        senhaAtual: _atual.text,
        senhaNova: _nova.text,
      );
      if (!mounted) return;
      _atual.clear();
      _nova.clear();
      _confirmacao.clear();
      TextInput.finishAutofillContext();
      setState(() => _trocada = true);
    } on ErroApi catch (erro) {
      if (!mounted) return;
      if (erro.codigo == 'senha_atual_incorreta') {
        setState(() => _erroAtual = 'Senha atual incorreta.');
        _formulario.currentState!.validate();
      } else {
        _avisar(descreverErroOnline(erro));
      }
    } on SessaoEncerrada {
      await dependencias.sessao.encerrarLocalmente();
    } on SemConexao {
      // Mantém o que foi digitado para tentar de novo com internet.
      _avisar('Sem internet. A troca de senha precisa de conexão.');
    } catch (erro) {
      _avisar(descreverErroOnline(erro));
    }
    if (mounted) setState(() => _trocando = false);
  }

  void _avisar(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Widget _botaoMostrar({
    required bool visivel,
    required VoidCallback aoTocar,
  }) => IconButton(
    tooltip: visivel ? 'Esconder a senha' : 'Mostrar a senha',
    icon: Icon(visivel ? Symbols.visibility_off : Symbols.visibility),
    style: IconButton.styleFrom(backgroundColor: Colors.transparent),
    onPressed: aoTocar,
  );

  @override
  Widget build(BuildContext context) {
    const apoio = TextStyle(color: CoresV2.nevoa, fontSize: 13);
    return Cartao(
      child: Form(
        key: _formulario,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Trocar senha',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _atual,
                obscureText: !_mostrarAtual,
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: const [AutofillHints.password],
                decoration: InputDecoration(
                  labelText: 'Senha atual',
                  isDense: true,
                  suffixIcon: _botaoMostrar(
                    visivel: _mostrarAtual,
                    aoTocar: () =>
                        setState(() => _mostrarAtual = !_mostrarAtual),
                  ),
                ),
                validator: (v) => v == null || v.isEmpty
                    ? 'Informe a senha atual.'
                    : _erroAtual,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nova,
                obscureText: !_mostrarNova,
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: const [AutofillHints.newPassword],
                decoration: InputDecoration(
                  labelText: 'Nova senha',
                  isDense: true,
                  suffixIcon: _botaoMostrar(
                    visivel: _mostrarNova,
                    aoTocar: () => setState(() => _mostrarNova = !_mostrarNova),
                  ),
                ),
                validator: (v) => v == null || v.length < 8
                    ? 'A nova senha precisa ter pelo menos 8 caracteres.'
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _confirmacao,
                obscureText: !_mostrarNova,
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: const [AutofillHints.newPassword],
                decoration: const InputDecoration(
                  labelText: 'Confirmar nova senha',
                  isDense: true,
                ),
                validator: (v) =>
                    v != _nova.text ? 'As senhas não conferem.' : null,
                onFieldSubmitted: (_) => _trocar(),
              ),
              const SizedBox(height: 6),
              const Text(
                'Pelo menos 8 caracteres. Os outros aparelhos em que você entrou saem da conta.',
                style: apoio,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: ehDesktop(context)
                    ? Alignment.centerRight
                    : Alignment.center,
                child: BotaoPrincipal(
                  rotulo: 'Trocar senha',
                  rotuloCarregando: 'Trocando…',
                  icone: Symbols.lock,
                  carregando: _trocando,
                  largo: !ehDesktop(context),
                  aoTocar: _trocar,
                ),
              ),
              if (_trocada) ...[
                const SizedBox(height: 10),
                Semantics(
                  liveRegion: true,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
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
                            'Senha trocada.',
                            style: TextStyle(color: CoresV2.ok, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
