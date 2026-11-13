// Tela 1 — Entrar (docs/telas/README.md). Login por e-mail e senha; o primeiro acesso exige internet.
import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../dados/cliente_api.dart';
import '../estado/dependencias.dart';
import 'componentes.dart';

class TelaEntrar extends StatefulWidget {
  const TelaEntrar({super.key});

  @override
  State<TelaEntrar> createState() => _TelaEntrarState();
}

class _TelaEntrarState extends State<TelaEntrar> {
  final _formulario = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _entrando = false;
  String? _erro;

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  String _descreverErro(Object erro) => switch (erro) {
    ErroApi(codigo: 'credenciais_invalidas') => 'E-mail ou senha incorretos.',
    SemConexao() => 'Sem internet. O primeiro acesso precisa de conexão.',
    _ => 'Não foi possível entrar agora. Tente de novo.',
  };

  Future<void> _entrar() async {
    if (_entrando || !_formulario.currentState!.validate()) return;
    setState(() {
      _entrando = true;
      _erro = null;
    });
    try {
      await EscopoDependencias.obter(context).sessao
          .entrar(_email.text, _senha.text);
    } catch (erro) {
      if (mounted) setState(() => _erro = _descreverErro(erro));
    } finally {
      if (mounted) setState(() => _entrando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final textoApoio = TextStyle(color: cores.onSurfaceVariant);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: LarguraCelular(
                    child: _montarFormulario(textoApoio, cores),
                  ),
                ),
              ),
            ),
            // A marca do sistema só como copyright discreto, no fim da tela.
            const RodapeCopyright(),
          ],
        ),
      ),
    );
  }

  Widget _montarFormulario(TextStyle textoApoio, ColorScheme cores) {
    return Form(
      key: _formulario,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // A academia só é conhecida depois do login: em destaque, o nome do app.
            Text(
              'Controle de presença',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Entre com o e-mail e a senha que você recebeu.',
              textAlign: TextAlign.center,
              style: textoApoio,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || !v.contains('@')) ? 'Informe o e-mail' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _senha,
              decoration: const InputDecoration(
                labelText: 'Senha',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _entrar(),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Informe a senha' : null,
            ),
            if (_erro != null) ...[
              const SizedBox(height: 12),
              Text(
                _erro!,
                style: TextStyle(color: cores.error),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 12),
            BotaoPrincipal(
              rotulo: 'Entrar',
              icone: Symbols.arrow_forward,
              largo: true,
              carregando: _entrando,
              rotuloCarregando: 'Entrando…',
              aoTocar: _entrar,
            ),
            const SizedBox(height: 12),
            Text(
              'Esqueceu a senha? Fale com o professor',
              textAlign: TextAlign.center,
              style: textoApoio,
            ),
          ],
        ),
      ),
    );
  }
}
