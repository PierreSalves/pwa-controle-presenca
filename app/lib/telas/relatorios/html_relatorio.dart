// Página impressa dos relatórios (P1 em docs/telas/wireframes-relatorios.html): HTML simples, sem
// script, aberto numa aba nova para o navegador imprimir ou salvar em PDF. Mesma tabela da tela.
import '../formatacao.dart';
import 'montar_relatorio.dart';

class CabecalhoImpressao {
  const CabecalhoImpressao({
    required this.academia,
    required this.cabecalhoAcademia,
    required this.turma,
    required this.cabecalhoTurma,
    required this.geradoEm,
    required this.geradoPor,
  });

  final String academia;
  final String? cabecalhoAcademia;
  final String turma;
  final String? cabecalhoTurma;

  /// Instante da geração (mostrado no fuso de São Paulo).
  final DateTime geradoEm;

  /// "Ana (assistente)".
  final String geradoPor;
}

String _escapar(String texto) => texto
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

String _formatarCelula(CelulaRelatorio c) {
  if (c.marca) {
    return c.estilo == EstiloCelula.veio
        ? '<span class="veio" aria-label="veio">&#10003;</span>'
        : '<span class="faltou" aria-label="faltou">&middot;</span>';
  }
  final texto = _escapar(c.texto);
  return switch (c.estilo) {
    EstiloCelula.abaixoDoMinimo => '<b>$texto</b>',
    EstiloCelula.veio => '<span class="veio">$texto</span>',
    _ => texto,
  };
}

/// Data do instante em São Paulo (UTC−3): '13/11/2026'.
String _formatarDataSaoPaulo(DateTime instante) {
  final local = instante.toUtc().subtract(const Duration(hours: 3));
  String dois(int n) => n.toString().padLeft(2, '0');
  return '${dois(local.day)}/${dois(local.month)}/${local.year}';
}

String gerarHtmlRelatorio(RelatorioMontado r, CabecalhoImpressao c) {
  final b = StringBuffer();
  final titulo = '${r.tipo.titulo} · ${c.turma}';
  b.write('''<!doctype html>
<html lang="pt-BR"><head><meta charset="utf-8">
<title>${_escapar(titulo)}</title>
<style>
@page { size: A4 ${r.paisagem ? 'landscape' : 'portrait'}; margin: 12mm; }
* { box-sizing: border-box; }
body { font-family: system-ui, "Segoe UI", Arial, sans-serif; color: #111; font-size: 12px; margin: 0; }
.cab { display: flex; gap: 16px; align-items: flex-start; border-bottom: 2px solid #111; padding-bottom: 10px; margin-bottom: 12px; }
.cab .academia { flex: 1; }
.cab h1 { font-size: 17px; margin: 0 0 2px; }
.cab .rel { text-align: right; }
table { width: 100%; border-collapse: collapse; font-variant-numeric: tabular-nums; }
th, td { border: 1px solid #c9ccc8; padding: 4px 5px; text-align: center; }
th { background: #f1f2f0; font-weight: 600; }
th:first-child, td:first-child { text-align: left; }
tr.rodape td { background: #f7f8f6; color: #444; }
tr { page-break-inside: avoid; }
thead { display: table-header-group; }
.etq { display: block; font-weight: 400; font-size: 10px; color: #13557A; }
.veio { color: #13557A; font-weight: 600; }
.faltou { color: #5E646B; }
.resumo { display: flex; gap: 24px; margin: 0 0 12px; }
.resumo b { font-size: 15px; }
.nota, .rodape-pagina { color: #555; margin: 10px 0 0; }
</style></head><body>
''');
  b.write('<div class="cab"><div class="academia">');
  b.write('<h1>${_escapar(c.academia)}</h1>');
  if (c.cabecalhoAcademia != null) {
    b.write('<div>${_escapar(c.cabecalhoAcademia!)}</div>');
  }
  b.write('<div><b>Turma ${_escapar(c.turma)}</b>');
  if (c.cabecalhoTurma != null) b.write(' · ${_escapar(c.cabecalhoTurma!)}');
  b.write('</div></div>');
  b.write(
    '<div class="rel"><b>${_escapar(r.tipo.titulo)}</b><br>'
    '${_escapar(r.periodo)}</div></div>',
  );

  if (r.resumo.isNotEmpty) {
    b.write('<div class="resumo">');
    for (final item in r.resumo) {
      b.write(
        '<div>${_escapar(item.rotulo)}<br><b>${_escapar(item.valor)}</b>'
        '${item.apoio == null ? '' : ' (${_escapar(item.apoio!)})'}</div>',
      );
    }
    b.write('</div>');
  }

  if (r.estaVazio) {
    b.write('<p>${_escapar(r.vazio)}</p>');
  } else {
    b.write('<table><thead>');
    final grupos = r.grupos;
    if (grupos != null) {
      b.write('<tr><th rowspan="2">${_escapar(r.rotuloPrimeiraColuna)}</th>');
      for (final g in grupos) {
        b.write('<th colspan="${g.colunas}">${_escapar(g.rotulo)}</th>');
      }
      // Colunas depois dos grupos (ex.: Total) ocupam as duas linhas.
      final agrupadas = grupos.fold(0, (s, g) => s + g.colunas);
      for (final coluna in r.colunas.skip(agrupadas)) {
        b.write('<th rowspan="2">${_escapar(coluna.rotulo)}</th>');
      }
      b.write('</tr><tr>');
      for (final coluna in r.colunas.take(agrupadas)) {
        b.write('<th>${_formatarCabecalho(coluna)}</th>');
      }
      b.write('</tr>');
    } else {
      b.write('<tr><th>${_escapar(r.rotuloPrimeiraColuna)}</th>');
      for (final coluna in r.colunas) {
        b.write('<th>${_formatarCabecalho(coluna)}</th>');
      }
      b.write('</tr>');
    }
    b.write('</thead><tbody>');
    for (final linha in r.linhas) {
      b.write(linha.rodape ? '<tr class="rodape">' : '<tr>');
      b.write('<td>${_escapar(linha.rotulo)}</td>');
      for (final celula in linha.celulas) {
        b.write('<td>${_formatarCelula(celula)}</td>');
      }
      b.write('</tr>');
    }
    b.write('</tbody></table>');
    if (r.legendaDeMarcas) {
      b.write(
        '<p class="nota">&#10003; veio &middot; &middot; faltou &middot; '
        'em branco: fora da matrícula</p>',
      );
    }
    if (r.nota != null) b.write('<p class="nota">${_escapar(r.nota!)}</p>');
  }
  b.write(
    '<p class="rodape-pagina">Gerado em ${_formatarDataSaoPaulo(c.geradoEm)} às '
    '${formatarHora(c.geradoEm)} por ${_escapar(c.geradoPor)}.</p>',
  );
  b.write('</body></html>');
  return b.toString();
}

String _formatarCabecalho(ColunaRelatorio coluna) =>
    '${_escapar(coluna.rotulo)}'
    '${coluna.etiqueta == null ? '' : '<span class="etq">${_escapar(coluna.etiqueta!)}</span>'}';
