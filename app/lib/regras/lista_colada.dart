// Leitura da lista de alunos colada da planilha (telas 8b e 8c): código e nome por linha.
// A API normaliza o código ("(10A)" vira "10A") e faz o relatório de repetidos; aqui só se separa
// cada linha em código e nome, guardando o número da linha colada para o relatório apontar certo.

class LinhaColada {
  const LinhaColada({
    required this.numero,
    required this.codigo,
    required this.nome,
  });

  /// Número da linha no texto colado (a partir de 1, contando as linhas em branco).
  final int numero;
  final String codigo;
  final String nome;
}

final _espacos = RegExp(r'\s+');
final _cabecalho = RegExp(
  r'^(c[oó]d(igo)?\.?|n[ºo°]?\.?)$',
  caseSensitive: false,
);

/// Separa código e nome de cada linha: por tab (cópia de planilha), senão por ponto e vírgula,
/// senão pelo primeiro espaço. Linhas em branco e o cabeçalho ("Código  Nome") ficam de fora.
List<LinhaColada> lerListaColada(String texto) {
  final resultado = <LinhaColada>[];
  final linhas = texto
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .split('\n');
  for (var i = 0; i < linhas.length; i++) {
    final linha = linhas[i].trim();
    if (linha.isEmpty) continue;
    final String codigo;
    final String nome;
    if (linha.contains('\t')) {
      final celulas = linha
          .split('\t')
          .map((c) => c.trim())
          .where((c) => c.isNotEmpty)
          .toList();
      codigo = celulas.isEmpty ? '' : celulas.first;
      nome = celulas.length > 1 ? celulas[1] : '';
    } else if (linha.contains(';')) {
      final posicao = linha.indexOf(';');
      codigo = linha.substring(0, posicao).trim();
      nome = linha.substring(posicao + 1).replaceAll(';', ' ').trim();
    } else {
      final partes = linha.split(_espacos);
      codigo = partes.first;
      nome = partes.skip(1).join(' ');
    }
    if (resultado.isEmpty && _cabecalho.hasMatch(codigo)) continue;
    resultado.add(
      LinhaColada(
        numero: i + 1,
        codigo: codigo,
        nome: nome.replaceAll(_espacos, ' ').trim(),
      ),
    );
  }
  return resultado;
}
