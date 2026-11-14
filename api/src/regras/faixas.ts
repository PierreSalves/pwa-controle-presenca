// Faixas e graus do sistema de graduação da CBJJ (docs/telas/wireframes-faixas.html).
// Funções puras; os mesmos casos rodam no app (Dart): docs/casos-regras/faixas.json.

export type Ponteira = 'vermelha' | 'branca';

export interface Faixa {
  nome: string;
  grupo: 'infantil e adulto' | 'infantil' | 'adulto' | 'mestres';
  grauMinimo: number;
  grauMaximo: number;
}

const coloridas = (grupo: Faixa['grupo'], nomes: string[]): Faixa[] =>
  nomes.map((nome) => ({ nome, grupo, grauMinimo: 0, grauMaximo: 4 }));

/** Faixas na ordem de graduação. A branca é a primeira do infantil e do adulto. */
export const FAIXAS: readonly Faixa[] = [
  ...coloridas('infantil e adulto', ['Branca']),
  ...coloridas(
    'infantil',
    ['Cinza', 'Amarela', 'Laranja', 'Verde'].flatMap((cor) => [`${cor} e branca`, cor, `${cor} e preta`]),
  ),
  ...coloridas('adulto', ['Azul', 'Roxa', 'Marrom']),
  { nome: 'Preta', grupo: 'adulto', grauMinimo: 0, grauMaximo: 6 },
  { nome: 'Coral (vermelha e preta)', grupo: 'mestres', grauMinimo: 7, grauMaximo: 7 },
  { nome: 'Coral (vermelha e branca)', grupo: 'mestres', grauMinimo: 8, grauMaximo: 8 },
  { nome: 'Vermelha', grupo: 'mestres', grauMinimo: 9, grauMaximo: 10 },
];

/** Graus permitidos na faixa ([mínimo, máximo]); null se a faixa não é da lista. */
export function obterLimitesGrau(faixa: string): [number, number] | null {
  const encontrada = FAIXAS.find((f) => f.nome === faixa);
  return encontrada ? [encontrada.grauMinimo, encontrada.grauMaximo] : null;
}

/** Só a faixa preta escolhe a ponteira (vermelha: professor; branca: competidor). */
export function temPonteiraEscolhida(faixa: string): boolean {
  return faixa === 'Preta';
}

/** Faixa da lista, grau dentro do limite e ponteira só (e sempre) na faixa preta. */
export function ehGraduacaoValida(faixa: string, grau: number, ponteira: string | null): boolean {
  const limites = obterLimitesGrau(faixa);
  if (!limites || !Number.isInteger(grau) || grau < limites[0] || grau > limites[1]) return false;
  if (temPonteiraEscolhida(faixa)) return ponteira === 'vermelha' || ponteira === 'branca';
  return ponteira === null;
}

/** Grau levado para dentro do limite da faixa (ao trocar a faixa no diálogo). */
export function calcularGrauAjustado(faixa: string, grau: number): number {
  const limites = obterLimitesGrau(faixa);
  if (!limites) return grau;
  return Math.min(Math.max(grau, limites[0]), limites[1]);
}
