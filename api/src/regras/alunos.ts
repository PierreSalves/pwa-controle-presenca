// Regras do cadastro de alunos e matrículas. Funções puras, testadas em test/regras-alunos.test.ts.

export interface Periodo {
  data_inicio: string;
  data_fim: string | null;
}

/**
 * Próximo código livre sugerido no cadastro (o professor pode trocar).
 * Considera só os códigos numéricos; mantém a largura com zeros à esquerda do maior (ex.: '09' → '10').
 */
export function calcularProximoCodigo(codigos: readonly string[]): string {
  let maior = 0;
  let largura = 1;
  for (const codigo of codigos) {
    if (!/^\d+$/.test(codigo)) continue;
    const valor = Number(codigo);
    if (valor > maior) {
      maior = valor;
      largura = codigo.length;
    }
  }
  return String(maior + 1).padStart(largura, '0');
}

/** Dois períodos (data_fim nula = em aberto) têm pelo menos um dia em comum. */
export function temSobreposicao(a: Periodo, b: Periodo): boolean {
  return (
    (b.data_fim === null || a.data_inicio <= b.data_fim) &&
    (a.data_fim === null || b.data_inicio <= a.data_fim)
  );
}

/** Código como vem da planilha, ex.: '(10A)' → '10A'. */
export function normalizarCodigoImportado(codigo: string): string {
  return codigo
    .trim()
    .replace(/^\((.*)\)$/, '$1')
    .trim();
}

export interface LinhaImportacao {
  linha: number;
  codigo: string;
  nome: string;
}

export interface RelatorioImportacao {
  /** Linhas sem código ou sem nome. */
  incompletas: number[];
  /** Mesmo código em mais de uma linha da planilha (sem diferenciar maiúsculas). */
  codigos_repetidos: { codigo: string; linhas: number[] }[];
  /** Código que já existe na academia. */
  codigos_existentes: { codigo: string; linha: number; nome_cadastrado: string }[];
  /** Mesmo nome em mais de uma linha (só aviso: irmãos e homônimos existem). */
  nomes_repetidos: { nome: string; linhas: number[] }[];
  /** Pode gravar: nenhuma linha incompleta, nenhum código repetido ou já existente. */
  pode_importar: boolean;
}

function agruparPorChave(linhas: readonly LinhaImportacao[], chave: (l: LinhaImportacao) => string) {
  const grupos = new Map<string, LinhaImportacao[]>();
  for (const l of linhas) {
    const k = chave(l);
    grupos.set(k, [...(grupos.get(k) ?? []), l]);
  }
  return [...grupos.values()].filter((g) => g.length > 1);
}

/** Relatório mostrado antes de gravar a importação (códigos duplicados, como já aconteceu na planilha). */
export function calcularRelatorioImportacao(
  linhas: readonly LinhaImportacao[],
  existentes: readonly { codigo: string; nome: string }[],
): RelatorioImportacao {
  const incompletas = linhas.filter((l) => !l.codigo || !l.nome).map((l) => l.linha);
  const completas = linhas.filter((l) => l.codigo && l.nome);
  const codigosRepetidos = agruparPorChave(completas, (l) => l.codigo.toLowerCase()).map((g) => ({
    codigo: g[0]?.codigo ?? '',
    linhas: g.map((l) => l.linha),
  }));
  const porCodigo = new Map(existentes.map((e) => [e.codigo.toLowerCase(), e.nome]));
  const codigosExistentes = completas
    .filter((l) => porCodigo.has(l.codigo.toLowerCase()))
    .map((l) => ({
      codigo: l.codigo,
      linha: l.linha,
      nome_cadastrado: porCodigo.get(l.codigo.toLowerCase()) ?? '',
    }));
  const nomesRepetidos = agruparPorChave(completas, (l) =>
    l.nome.toLocaleLowerCase('pt-BR').replace(/\s+/g, ' '),
  ).map((g) => ({ nome: g[0]?.nome ?? '', linhas: g.map((l) => l.linha) }));
  return {
    incompletas,
    codigos_repetidos: codigosRepetidos,
    codigos_existentes: codigosExistentes,
    nomes_repetidos: nomesRepetidos,
    pode_importar:
      incompletas.length === 0 && codigosRepetidos.length === 0 && codigosExistentes.length === 0,
  };
}
