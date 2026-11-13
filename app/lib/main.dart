import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:material_ui/material_ui.dart';

import 'dados/abrir_banco.dart';
import 'dados/cliente_api.dart';
import 'estado/dependencias.dart';
import 'estado/sessao_app.dart';
import 'telas/navegacao.dart';
import 'telas/tema.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // No navegador o Flutter só monta a árvore de acessibilidade quando o leitor de tela acha o
  // botão escondido "Enable accessibility". Ligada desde o início, o app já abre acessível.
  SemanticsBinding.instance.ensureSemantics();
  // Endereços sem #: /alunos, /turmas... (o Worker e o service worker devolvem o index.html).
  usePathUrlStrategy();
  final dependencias = Dependencias(
    banco: abrirBancoLocal(),
    cliente: ClienteApi(),
  );
  runApp(ControlePresencaApp(dependencias: dependencias));
  unawaited(dependencias.sessao.iniciar());
}

/// Raiz do app. As telas seguem os wireframes aprovados em docs/telas/ (visual da v2).
class ControlePresencaApp extends StatefulWidget {
  const ControlePresencaApp({super.key, required this.dependencias});

  final Dependencias dependencias;

  @override
  State<ControlePresencaApp> createState() => _ControlePresencaAppState();
}

class _ControlePresencaAppState extends State<ControlePresencaApp> {
  final _navegador = GlobalKey<NavigatorState>();
  final _observador = ObservadorRotas();
  late SituacaoSessao _situacao = widget.dependencias.sessao.situacao;

  @override
  void initState() {
    super.initState();
    widget.dependencias.sessao.addListener(_aoMudarSessao);
  }

  @override
  void dispose() {
    widget.dependencias.sessao.removeListener(_aoMudarSessao);
    super.dispose();
  }

  /// Ao sair (ou ter a sessão encerrada), volta para o início com a pilha limpa.
  void _aoMudarSessao() {
    final nova = widget.dependencias.sessao.situacao;
    if (_situacao == SituacaoSessao.logado &&
        nova == SituacaoSessao.deslogado) {
      _navegador.currentState?.pushNamedAndRemoveUntil(
        Rotas.inicio,
        (_) => false,
      );
    }
    _situacao = nova;
  }

  @override
  Widget build(BuildContext context) {
    return EscopoDependencias(
      dependencias: widget.dependencias,
      child: MaterialApp(
        title: 'Controle de presença',
        debugShowCheckedModeBanner: false,
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: criarTemaV2(),
        navigatorKey: _navegador,
        navigatorObservers: [_observador],
        onGenerateRoute: gerarRota,
        builder: (context, child) => EstruturaComMenu(
          navegador: _navegador,
          observador: _observador,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
