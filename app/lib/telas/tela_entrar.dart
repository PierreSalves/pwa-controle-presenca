// Tela 1 — Entrar (docs/telas/README.md). Login por e-mail e senha; o primeiro acesso exige internet.
import 'package:material_ui/material_ui.dart';

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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: LarguraCelular(
              child: Form(
                key: _formulario,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logotipo da TghServices: a academia só é conhecida após o login.
                      Container(
                        height: 80,
                        alignment: Alignment.center,
                        child: Text(
                          'TghServices',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Controle de presença',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _email,
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        validator: (v) => (v == null || !v.contains('@'))
                            ? 'Informe o e-mail'
                            : null,
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
                      FilledButton(
                        onPressed: _entrando ? null : _entrar,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: _entrando
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Entrar'),
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}
