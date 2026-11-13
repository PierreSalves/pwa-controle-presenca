// Regras configuráveis por turma (tabela `regras`, escopo 'turma'). Veja docs/arquitetura/README.md.
import { lerInteiro } from '../util/validacao';

export interface ParametrosListaLancamento {
  /** % mínimo de presença nas últimas aulas para o aluno aparecer entre os frequentes. */
  percentual_minimo: number;
  /** Quantas aulas regulares recentes entram na conta. */
  ultimas_aulas: number;
}

export interface ParametrosAlunosSumidos {
  /** Semanas sem presença para o aluno aparecer no aviso de sumidos. */
  semanas: number;
}

export interface RegrasDaTurma {
  lista_lancamento: ParametrosListaLancamento;
  alunos_sumidos: ParametrosAlunosSumidos;
}

export type TipoRegraTurma = keyof RegrasDaTurma;

export const TIPOS_REGRA_TURMA: readonly TipoRegraTurma[] = ['lista_lancamento', 'alunos_sumidos'];

export const REGRAS_PADRAO_TURMA: RegrasDaTurma = {
  lista_lancamento: { percentual_minimo: 30, ultimas_aulas: 8 },
  alunos_sumidos: { semanas: 4 },
};

export function lerParametrosListaLancamento(valor: unknown): ParametrosListaLancamento | undefined {
  if (typeof valor !== 'object' || valor === null) return undefined;
  const dados = valor as Record<string, unknown>;
  const percentual = lerInteiro(dados.percentual_minimo, 0, 100);
  const aulas = lerInteiro(dados.ultimas_aulas, 1, 52);
  if (percentual === undefined || aulas === undefined) return undefined;
  return { percentual_minimo: percentual, ultimas_aulas: aulas };
}

export function lerParametrosAlunosSumidos(valor: unknown): ParametrosAlunosSumidos | undefined {
  if (typeof valor !== 'object' || valor === null) return undefined;
  const semanas = lerInteiro((valor as Record<string, unknown>).semanas, 1, 52);
  return semanas === undefined ? undefined : { semanas };
}

/** Junta os parâmetros gravados (JSON, o mais recente de cada tipo) com os valores padrão. */
export function calcularRegrasDaTurma(gravadas: { tipo: string; parametros: string }[]): RegrasDaTurma {
  const regras: RegrasDaTurma = structuredClone(REGRAS_PADRAO_TURMA);
  for (const { tipo, parametros } of gravadas) {
    let dados: unknown;
    try {
      dados = JSON.parse(parametros);
    } catch {
      continue;
    }
    if (tipo === 'lista_lancamento') {
      regras.lista_lancamento = lerParametrosListaLancamento(dados) ?? regras.lista_lancamento;
    } else if (tipo === 'alunos_sumidos') {
      regras.alunos_sumidos = lerParametrosAlunosSumidos(dados) ?? regras.alunos_sumidos;
    }
  }
  return regras;
}
