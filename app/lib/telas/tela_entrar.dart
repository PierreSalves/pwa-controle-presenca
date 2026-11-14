// Tela 1 — Entrar (docs/telas/wireframes-login-desktop.html, v6). Login por e-mail e senha; o
// primeiro acesso exige internet. O formulário fica num cartão branco sobre o fundo cinza; no
// desktop, a tela se divide: apresentação do sistema à esquerda e o cartão à direita (DL1).
import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../dados/cliente_api.dart';
import '../estado/dependencias.dart';
import 'componentes.dart';
import 'tema.dart';

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
  bool _mostrarSenha = false;
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
    final ladoFormulario = Column(
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: _CartaoFormulario(child: _montarFormulario()),
              ),
            ),
          ),
        ),
        // A marca do sistema só como copyright discreto, no fim da tela.
        const RodapeCopyright(),
      ],
    );
    return Scaffold(
      backgroundColor: CoresV2.papel,
      body: ehDesktop(context)
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Expanded(child: _PainelApresentacao()),
                Expanded(child: SafeArea(child: ladoFormulario)),
              ],
            )
          : SafeArea(child: ladoFormulario),
    );
  }

  Widget _montarFormulario() {
    const textoApoio = TextStyle(color: CoresV2.nevoa, fontSize: 14);
    return Form(
      key: _formulario,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: const Text(
                'Entrar',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Entre com o e-mail e a senha que você recebeu.',
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
              decoration: InputDecoration(
                labelText: 'Senha',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: _mostrarSenha
                      ? 'Esconder a senha'
                      : 'Mostrar a senha',
                  icon: Icon(
                    _mostrarSenha ? Symbols.visibility_off : Symbols.visibility,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.transparent,
                  ),
                  onPressed: () =>
                      setState(() => _mostrarSenha = !_mostrarSenha),
                ),
              ),
              obscureText: !_mostrarSenha,
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _entrar(),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Informe a senha' : null,
            ),
            if (_erro != null) ...[
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Text(
                  _erro!,
                  style: const TextStyle(color: CoresV2.ponta),
                ),
              ),
            ],
            const SizedBox(height: 16),
            BotaoPrincipal(
              rotulo: 'Entrar',
              icone: Symbols.arrow_forward,
              largo: true,
              carregando: _entrando,
              rotuloCarregando: 'Entrando…',
              aoTocar: _entrar,
            ),
            const SizedBox(height: 14),
            const Text(
              'Esqueceu a senha? Fale com o professor',
              style: TextStyle(color: CoresV2.nevoa, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

/// O cartão branco do formulário: contorno fino e sombra suave para se destacar do fundo cinza.
class _CartaoFormulario extends StatelessWidget {
  const _CartaoFormulario({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: ehDesktop(context)
        ? const EdgeInsets.fromLTRB(32, 32, 32, 28)
        : const EdgeInsets.fromLTRB(20, 24, 20, 20),
    decoration: BoxDecoration(
      color: CoresV2.cartao,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: CoresV2.linha),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0F23262B),
          blurRadius: 2,
          offset: Offset(0, 1),
        ),
        BoxShadow(
          color: Color(0x4713557A),
          blurRadius: 36,
          spreadRadius: -14,
          offset: Offset(0, 16),
        ),
      ],
    ),
    child: child,
  );
}

/// Painel da esquerda no desktop: apresentação fixa do sistema (não muda por academia).
class _PainelApresentacao extends StatelessWidget {
  const _PainelApresentacao();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: CoresV2.tatameClaro,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(56),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: const Text(
                    'Controle de presença',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'A chamada da academia no celular, e os relatórios prontos no fim do mês.',
                  style: TextStyle(color: CoresV2.nevoa, fontSize: 16),
                ),
                const SizedBox(height: 26),
                const _ItemApresentacao(
                  icone: Symbols.check_box,
                  titulo: 'Lance a presença no tatame',
                  texto: 'Funciona mesmo sem internet; envia quando o sinal voltar.',
                ),
                const SizedBox(height: 18),
                const _ItemApresentacao(
                  icone: Symbols.bar_chart,
                  titulo: 'Relatórios sem somar à mão',
                  texto: 'Semanal, mensal, anual e por aluno, para imprimir ou salvar em PDF.',
                ),
                const SizedBox(height: 18),
                const _ItemApresentacao(
                  icone: Symbols.military_tech,
                  titulo: 'Frequência para graduação',
                  texto: 'Quem está abaixo do mínimo da turma, a qualquer momento.',
                ),
                const SizedBox(height: 28),
                // Enfeite: as faixas, o único destaque de cor da v2.
                const ExcludeSemantics(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FaixaDoAluno(faixa: 'branca', grau: 1, largura: 72),
                      FaixaDoAluno(faixa: 'azul', grau: 2, largura: 72),
                      FaixaDoAluno(faixa: 'roxa', grau: 3, largura: 72),
                      FaixaDoAluno(faixa: 'marrom', grau: 0, largura: 72),
                      FaixaDoAluno(faixa: 'preta', grau: 2, largura: 72),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemApresentacao extends StatelessWidget {
  const _ItemApresentacao({
    required this.icone,
    required this.titulo,
    required this.texto,
  });

  final IconData icone;
  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: CoresV2.cartao,
          borderRadius: BorderRadius.circular(12),
          boxShadow: sombraCartao,
        ),
        child: Icon(icone, size: 20, color: CoresV2.tatame),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(
              texto,
              style: const TextStyle(color: CoresV2.nevoa, fontSize: 14),
            ),
          ],
        ),
      ),
    ],
  );
}
