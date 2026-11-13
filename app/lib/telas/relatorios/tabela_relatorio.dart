// Desenho na tela de um RelatorioMontado (telas 7a–7d, D5, D6): resumo em cartões, tabela com a
// coluna do aluno fixa e o resto rolando para o lado, e a legenda das marcas.
import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../componentes.dart';
import '../tema.dart';
import 'montar_relatorio.dart';

class TabelaRelatorio extends StatelessWidget {
  const TabelaRelatorio({
    super.key,
    required this.relatorio,
    this.compacta = false,
    this.aoTocarLinha,
  });

  final RelatorioMontado relatorio;

  /// Celular: colunas e primeira coluna mais estreitas.
  final bool compacta;

  /// Toque no aluno (índice da linha); null deixa as linhas sem ação.
  final ValueChanged<int>? aoTocarLinha;

  static const _alturaGrupo = 30.0;
  static const _alturaLinha = 44.0;

  double get _larguraPrimeira => compacta ? 140 : 260;

  /// Largura da coluna [indice]: cabe o rótulo e o texto mais longo das células (as marcas
  /// são símbolos e não contam).
  double _calcularLargura(int indice) {
    final minima = compacta ? 48.0 : 64.0;
    var letras = relatorio.colunas[indice].rotulo.length;
    for (final linha in relatorio.linhas) {
      final celula = linha.celulas[indice];
      if (!celula.marca && celula.texto.length > letras) {
        letras = celula.texto.length;
      }
    }
    final pelaPalavra = letras * 8.0 + 20;
    return pelaPalavra > minima ? pelaPalavra : minima;
  }

  @override
  Widget build(BuildContext context) {
    final r = relatorio;
    final apoio = TextStyle(color: CoresV2.nevoa, fontSize: 13);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (r.resumo.isNotEmpty) ...[
          _Resumo(itens: r.resumo),
          const SizedBox(height: 12),
        ],
        if (r.estaVazio)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(r.vazio, textAlign: TextAlign.center),
          )
        else
          Cartao(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            child: _montarTabela(),
          ),
        if (!r.estaVazio && r.legendaDeMarcas) ...[
          const SizedBox(height: 8),
          const _LegendaDeMarcas(),
        ],
        if (!r.estaVazio && r.nota != null) ...[
          const SizedBox(height: 8),
          Text(r.nota!, style: apoio),
        ],
      ],
    );
  }

  Widget _montarTabela() {
    final r = relatorio;
    final larguras = [
      for (var c = 0; c < r.colunas.length; c++) _calcularLargura(c),
    ];
    final alturaCabecalho = r.colunas.any((c) => c.etiqueta != null)
        ? 54.0
        : 40.0;
    const linha = BorderSide(color: CoresV2.linha);
    const cabecalho = TextStyle(
      color: CoresV2.nevoa,
      fontSize: 13,
      fontFeatures: numerosFixos,
    );

    Widget celulaDaLinha(int i, Widget filho) {
      final toque = aoTocarLinha;
      final rodape = r.linhas[i].rodape;
      return Container(
        height: _alturaLinha,
        decoration: const BoxDecoration(border: Border(top: linha)),
        child: toque == null || rodape
            ? filho
            : InkWell(onTap: () => toque(i), child: filho),
      );
    }

    final primeira = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (r.grupos != null) const SizedBox(height: _alturaGrupo),
        SizedBox(
          height: alturaCabecalho,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(r.rotuloPrimeiraColuna, style: cabecalho),
          ),
        ),
        for (var i = 0; i < r.linhas.length; i++)
          celulaDaLinha(
            i,
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                r.linhas[i].rotulo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compacta ? 13 : 14,
                  color: r.linhas[i].rodape ? CoresV2.nevoa : null,
                ),
              ),
            ),
          ),
      ],
    );

    final resto = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (r.grupos != null)
          Row(
            children: [
              for (var g = 0, inicio = 0; g < r.grupos!.length; g++)
                () {
                  final grupo = r.grupos![g];
                  final largura = larguras
                      .sublist(inicio, inicio + grupo.colunas)
                      .fold(0.0, (a, b) => a + b);
                  inicio += grupo.colunas;
                  return SizedBox(
                    width: largura,
                    height: _alturaGrupo,
                    child: Center(
                      child: Text(
                        grupo.rotulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: cabecalho.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  );
                }(),
            ],
          ),
        Row(
          children: [
            for (var c = 0; c < r.colunas.length; c++)
              SizedBox(
                width: larguras[c],
                height: alturaCabecalho,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      r.colunas[c].rotulo,
                      textAlign: TextAlign.center,
                      style: cabecalho.copyWith(
                        color: r.colunas[c].esmaecida
                            ? CoresV2.desativado
                            : CoresV2.grafite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (r.colunas[c].etiqueta != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Etiqueta(r.colunas[c].etiqueta!),
                      ),
                  ],
                ),
              ),
          ],
        ),
        for (var i = 0; i < r.linhas.length; i++)
          Row(
            children: [
              for (var c = 0; c < r.linhas[i].celulas.length; c++)
                SizedBox(
                  width: larguras[c],
                  child: celulaDaLinha(
                    i,
                    Center(child: _Celula(celula: r.linhas[i].celulas[c])),
                  ),
                ),
            ],
          ),
      ],
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: _larguraPrimeira, child: primeira),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: resto,
          ),
        ),
      ],
    );
  }
}

class _Celula extends StatelessWidget {
  const _Celula({required this.celula});
  final CelulaRelatorio celula;

  @override
  Widget build(BuildContext context) {
    if (celula.marca && celula.estilo == EstiloCelula.veio) {
      return Icon(
        Symbols.check,
        size: 20,
        color: CoresV2.tatame,
        semanticLabel: celula.texto,
      );
    }
    if (celula.marca) {
      return Semantics(
        label: celula.texto,
        excludeSemantics: true,
        child: const Text(
          '·',
          style: TextStyle(color: CoresV2.nevoa, fontSize: 18),
        ),
      );
    }
    final estilo = switch (celula.estilo) {
      EstiloCelula.veio => const TextStyle(
        color: CoresV2.tatame,
        fontWeight: FontWeight.w600,
      ),
      EstiloCelula.abaixoDoMinimo => const TextStyle(
        color: CoresV2.ponta,
        fontWeight: FontWeight.w600,
      ),
      EstiloCelula.faltou ||
      EstiloCelula.futuro ||
      EstiloCelula.vazio => const TextStyle(color: CoresV2.nevoa),
      EstiloCelula.normal => const TextStyle(),
    };
    return Text(
      celula.texto,
      style: estilo.copyWith(fontSize: 14, fontFeatures: numerosFixos),
    );
  }
}

class _Resumo extends StatelessWidget {
  const _Resumo({required this.itens});
  final List<ItemResumo> itens;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < itens.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: Cartao(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    itens[i].rotulo,
                    style: const TextStyle(color: CoresV2.nevoa, fontSize: 13),
                  ),
                  Text(
                    itens[i].valor,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      fontFeatures: numerosFixos,
                      color: itens[i].baixo ? CoresV2.ponta : null,
                    ),
                  ),
                  if (itens[i].apoio != null)
                    Text(
                      itens[i].apoio!,
                      style: const TextStyle(
                        color: CoresV2.nevoa,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _LegendaDeMarcas extends StatelessWidget {
  const _LegendaDeMarcas();

  @override
  Widget build(BuildContext context) {
    const estilo = TextStyle(color: CoresV2.nevoa, fontSize: 13);
    return const Wrap(
      spacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Symbols.check, size: 16, color: CoresV2.tatame),
            SizedBox(width: 4),
            Text('veio', style: estilo),
          ],
        ),
        Text('·  faltou', style: estilo),
        Text('em branco: fora da matrícula', style: estilo),
      ],
    );
  }
}
