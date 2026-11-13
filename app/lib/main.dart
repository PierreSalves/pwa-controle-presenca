import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'dados/abrir_banco.dart';
import 'dados/cliente_api.dart';
import 'estado/dependencias.dart';
import 'estado/sessao_app.dart';
import 'telas/tela_entrar.dart';
import 'telas/tela_inicial.dart';

void main() {
  final dependencias = Dependencias(
    banco: abrirBancoLocal(),
    cliente: ClienteApi(),
  );
  runApp(ControlePresencaApp(dependencias: dependencias));
  unawaited(dependencias.sessao.iniciar());
}

const _cantos8 = RoundedRectangleBorder(
  borderRadius: BorderRadius.all(Radius.circular(8)),
);

/// Raiz do app. As telas da Fase 1 seguem os wireframes aprovados em docs/telas/.
class ControlePresencaApp extends StatelessWidget {
  const ControlePresencaApp({super.key, required this.dependencias});

  final Dependencias dependencias;

  @override
  Widget build(BuildContext context) {
    return EscopoDependencias(
      dependencias: dependencias,
      child: MaterialApp(
        title: 'Controle de presença',
        debugShowCheckedModeBanner: false,
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        // Preto e branco, como os wireframes aprovados.
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1F1E1D),
            dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
          ),
          useMaterial3: true,
          // Botões com cantos de 8 px (wireframes), não em pílula.
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(shape: _cantos8),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(shape: _cantos8),
          ),
        ),
        home: ListenableBuilder(
          listenable: dependencias.sessao,
          builder: (context, _) => switch (dependencias.sessao.situacao) {
            SituacaoSessao.carregando => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            SituacaoSessao.deslogado => const TelaEntrar(),
            SituacaoSessao.falhaNoBanco => const Scaffold(
              body: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Este navegador não permitiu guardar os dados no aparelho. '
                    'Saia da janela anônima ou use outro navegador.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            // A chave pelo usuário recria as telas a cada login (estado limpo).
            SituacaoSessao.logado => TelaInicial(
              key: ValueKey(dependencias.sessao.usuario?.id),
            ),
          },
        ),
      ),
    );
  }
}
