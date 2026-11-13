// Frequência no período (graduação e resumo do ano) e alunos sumidos (docs/arquitetura/README.md).
// Mesmos casos de teste do app (Dart): docs/casos-regras/frequencia.json
import type { AlunoDaLista, AulaDaLista } from './lista-lancamento';
import { somarDiasNaData } from '../util/datas';
import { estaMatriculadoNaData, type PeriodoMatricula } from './presenca';

export interface PresencaDaRegra {
  aula_id: string;
  aluno_id: string;
}

export interface FrequenciaNoPeriodo {
  aluno_id: string;
  /** Aulas regulares lançadas no período, dentro da matrícula. */
  aulas: number;
  /** Presenças nessas aulas regulares. */
  presencas: number;
  /** Presenças em reposições no período, dentro da matrícula. */
  reposicoes: number;
  /** (presenças + reposições) ÷ aulas, em % arredondado para baixo e limitado a 100; null sem aulas. */
  percentual: number | null;
  abaixo_do_minimo: boolean;
}

/** Semestre da graduação: jan–jun ou jul–dez. */
export function calcularInicioDoSemestre(data: string): string {
  return `${data.slice(0, 4)}-${Number(data.slice(5, 7)) <= 6 ? '01' : '07'}-01`;
}

function agruparPresencas(presencas: readonly PresencaDaRegra[]): Map<string, Set<string>> {
  const porAluno = new Map<string, Set<string>>();
  for (const p of presencas) {
    const aulas = porAluno.get(p.aluno_id) ?? new Set<string>();
    aulas.add(p.aula_id);
    porAluno.set(p.aluno_id, aulas);
  }
  return porAluno;
}

function estaEmAlgumaMatricula(data: string, matriculas: readonly PeriodoMatricula[]): boolean {
  return matriculas.some((m) => estaMatriculadoNaData(data, m));
}

/** Frequência dos alunos matriculados no dia `fim`, na ordem recebida. */
export function calcularFrequenciaNoPeriodo(entrada: {
  inicio: string;
  fim: string;
  minimo: number | null;
  aulas: readonly AulaDaLista[];
  presencas: readonly PresencaDaRegra[];
  alunos: readonly AlunoDaLista[];
}): FrequenciaNoPeriodo[] {
  const { inicio, fim, minimo } = entrada;
  const doPeriodo = entrada.aulas.filter((a) => a.data >= inicio && a.data <= fim);
  const presencasDoAluno = agruparPresencas(entrada.presencas);
  const resultado: FrequenciaNoPeriodo[] = [];
  for (const aluno of entrada.alunos) {
    if (!estaEmAlgumaMatricula(fim, aluno.matriculas)) continue;
    const presentes = presencasDoAluno.get(aluno.id) ?? new Set<string>();
    const naMatricula = doPeriodo.filter((a) => estaEmAlgumaMatricula(a.data, aluno.matriculas));
    const regulares = naMatricula.filter((a) => a.tipo === 'regular');
    const presencas = regulares.filter((a) => presentes.has(a.id)).length;
    const reposicoes = naMatricula.filter((a) => a.tipo === 'reposicao' && presentes.has(a.id)).length;
    const percentual =
      regulares.length === 0
        ? null
        : Math.min(100, Math.floor(((presencas + reposicoes) * 100) / regulares.length));
    resultado.push({
      aluno_id: aluno.id,
      aulas: regulares.length,
      presencas,
      reposicoes,
      percentual,
      abaixo_do_minimo: percentual !== null && minimo !== null && percentual < minimo,
    });
  }
  return resultado;
}

export interface AlunoSumido {
  aluno_id: string;
  matricula_id: string;
  ultima_presenca: string | null;
}

/**
 * Matrícula aberta (sem data de fim) no dia `hoje` cuja última presença — ou o início da matrícula,
 * se o aluno nunca veio — é anterior a `semanas` × 7 dias.
 */
export function calcularAlunosSumidos(entrada: {
  hoje: string;
  semanas: number;
  aulas: readonly AulaDaLista[];
  presencas: readonly PresencaDaRegra[];
  alunos: readonly { id: string; matriculas: readonly (PeriodoMatricula & { id: string })[] }[];
}): AlunoSumido[] {
  const { hoje } = entrada;
  const limite = somarDiasNaData(hoje, -entrada.semanas * 7);
  const dataDaAula = new Map(entrada.aulas.map((a) => [a.id, a.data]));
  const presencasDoAluno = agruparPresencas(entrada.presencas);
  const resultado: AlunoSumido[] = [];
  for (const aluno of entrada.alunos) {
    const aberta = aluno.matriculas.find((m) => m.data_fim === null && m.data_inicio <= hoje);
    if (!aberta) continue;
    let ultima: string | null = null;
    for (const aulaId of presencasDoAluno.get(aluno.id) ?? []) {
      const d = dataDaAula.get(aulaId);
      if (d !== undefined && d <= hoje && (ultima === null || d > ultima)) ultima = d;
    }
    const referencia = ultima ?? aberta.data_inicio;
    if (referencia < limite) {
      resultado.push({ aluno_id: aluno.id, matricula_id: aberta.id, ultima_presenca: ultima });
    }
  }
  return resultado;
}
