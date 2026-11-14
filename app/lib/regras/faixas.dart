// Faixas e graus do sistema de graduação da CBJJ (docs/telas/wireframes-faixas.html).
// Funções puras; os mesmos casos rodam na API (TypeScript): docs/casos-regras/faixas.json.

class Faixa {
  const Faixa(this.nome, this.grupo, this.grauMinimo, this.grauMaximo);

  final String nome;

  /// 'infantil e adulto', 'infantil', 'adulto' ou 'mestres'.
  final String grupo;
  final int grauMinimo;
  final int grauMaximo;
}

List<Faixa> _coloridas(String grupo, List<String> nomes) => [
  for (final nome in nomes) Faixa(nome, grupo, 0, 4),
];

/// Faixas na ordem de graduação. A branca é a primeira do infantil e do adulto.
final List<Faixa> faixas = List.unmodifiable([
  ..._coloridas('infantil e adulto', ['Branca']),
  ..._coloridas('infantil', [
    for (final cor in ['Cinza', 'Amarela', 'Laranja', 'Verde']) ...[
      '$cor e branca',
      cor,
      '$cor e preta',
    ],
  ]),
  ..._coloridas('adulto', ['Azul', 'Roxa', 'Marrom']),
  const Faixa('Preta', 'adulto', 0, 6),
  const Faixa('Coral (vermelha e preta)', 'mestres', 7, 7),
  const Faixa('Coral (vermelha e branca)', 'mestres', 8, 8),
  const Faixa('Vermelha', 'mestres', 9, 10),
]);

/// Graus permitidos na faixa (mínimo, máximo); null se a faixa não é da lista.
(int, int)? obterLimitesGrau(String faixa) {
  for (final f in faixas) {
    if (f.nome == faixa) return (f.grauMinimo, f.grauMaximo);
  }
  return null;
}

/// Só a faixa preta escolhe a ponteira (vermelha: professor; branca: competidor).
bool temPonteiraEscolhida(String faixa) => faixa == 'Preta';

/// Faixa da lista, grau dentro do limite e ponteira só (e sempre) na faixa preta.
bool ehGraduacaoValida(String faixa, int grau, String? ponteira) {
  final limites = obterLimitesGrau(faixa);
  if (limites == null || grau < limites.$1 || grau > limites.$2) return false;
  if (temPonteiraEscolhida(faixa)) {
    return ponteira == 'vermelha' || ponteira == 'branca';
  }
  return ponteira == null;
}

/// Grau levado para dentro do limite da faixa (ao trocar a faixa no diálogo).
int calcularGrauAjustado(String faixa, int grau) {
  final limites = obterLimitesGrau(faixa);
  if (limites == null) return grau;
  return grau.clamp(limites.$1, limites.$2);
}
