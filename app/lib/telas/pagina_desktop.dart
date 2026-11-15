// Padrão das páginas no desktop (docs/telas/wireframes-padrao-desktop.html, v11): título à
// esquerda ao lado do menu, ações à direita na mesma linha, voltar à esquerda do título nas
// subpáginas e o conteúdo em cartões, até 1040 px. O celular continua com a barra de cada tela.
import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'tema.dart';

/// Largura máxima do conteúdo das páginas no desktop.
const larguraMaximaPagina = 1040.0;

/// Margens da página no desktop: 28 px nas laterais, 24 px em cima.
const _margemLateral = 28.0;

class PaginaDesktop extends StatelessWidget {
  const PaginaDesktop({
    super.key,
    required this.titulo,
    required this.corpo,
    this.acoes = const [],
    this.voltar = false,
    this.rolavel = true,
  });

  final String titulo;

  /// O conteúdo (normalmente um ou mais [Cartao]).
  final Widget corpo;

  /// Botões à direita do título: secundário antes, principal por último.
  final List<Widget> acoes;

  /// Subpágina: mostra o botão de voltar à esquerda do título.
  final bool voltar;

  /// Com rolagem própria (padrão). Falso para conteúdo que já rola ou ocupa a altura toda
  /// (ex.: lista e cadastro lado a lado, grade da semana).
  final bool rolavel;

  @override
  Widget build(BuildContext context) {
    final cabecalho = Padding(
      padding: const EdgeInsets.fromLTRB(
        _margemLateral,
        24,
        _margemLateral,
        16,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: larguraMaximaPagina),
        child: Row(
          children: [
            if (voltar) ...[
              IconButton(
                tooltip: 'Voltar',
                icon: const Icon(Symbols.arrow_back),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            for (var i = 0; i < acoes.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              acoes[i],
            ],
          ],
        ),
      ),
    );
    final conteudo = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: larguraMaximaPagina),
      child: corpo,
    );
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          cabecalho,
          Expanded(
            child: rolavel
                ? SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      _margemLateral,
                      0,
                      _margemLateral,
                      28,
                    ),
                    child: Align(alignment: Alignment.topLeft, child: conteudo),
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(
                      _margemLateral,
                      0,
                      _margemLateral,
                      28,
                    ),
                    child: Align(alignment: Alignment.topLeft, child: conteudo),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Título de seção dentro de um cartão (14 px, peso 600).
class TituloSecao extends StatelessWidget {
  const TituloSecao(this.texto, {super.key});
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Semantics(
      header: true,
      child: Text(
        texto,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
  );
}

/// Linhas de uma lista dentro de um cartão, separadas por uma linha fina.
class ListaEmCartao extends StatelessWidget {
  const ListaEmCartao({super.key, required this.itens, this.titulo});

  final List<Widget> itens;
  final String? titulo;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: CoresV2.cartao,
      borderRadius: BorderRadius.circular(16),
      boxShadow: sombraCartao,
    ),
    child: Material(
      type: MaterialType.transparency,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (titulo != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: TituloSecao(titulo!),
              ),
            for (var i = 0; i < itens.length; i++) ...[
              if (i > 0)
                const Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: CoresV2.linha,
                ),
              itens[i],
            ],
          ],
        ),
      ),
    ),
  );
}

/// Troca de página no desktop: esmaecimento curto, sem zoom (o zoom passava por cima do menu
/// lateral). No celular continua a transição padrão; com "reduzir movimento", troca na hora.
class TransicaoSuave extends PageTransitionsBuilder {
  const TransicaoSuave();

  static const _celular = ZoomPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    if (!ehDesktop(context)) {
      return _celular.buildTransitions(
        route,
        context,
        animation,
        secondaryAnimation,
        child,
      );
    }
    return FadeTransition(
      // Termina na metade da duração padrão (~150 ms).
      opacity: CurvedAnimation(
        parent: animation,
        curve: const Interval(0, 0.5, curve: Curves.easeOut),
      ),
      child: child,
    );
  }
}
