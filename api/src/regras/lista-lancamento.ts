// Lista do lançamento: separa os alunos frequentes dos pouco frequentes (docs/telas/README.md).
// Mesmos casos de teste do app (Dart): docs/casos-regras/lista-lancamento.json
import type { ParametrosListaLancamento } from './configuracao-turma';
import { estaMatriculadoNaData, type PeriodoMatricula } from './presenca';

export interface AulaDaLista {
  id: string;
  data: string;
  tipo: string;
}

export interface AlunoDaLista {
  id: string;
  matriculas: readonly PeriodoMatricula[];
}

export interface FrequenciaNaLista {
  aluno_id: string;
  /** Presenças ÷ aulas regulares consideradas, em % arredondado para baixo. */
  percentual: number;
  /** Menos aulas que o parâmetro `ultimas_aulas`: sempre aparece. */
  novo: boolean;
  frequente: boolean;
  ultima_presenca: string | null;
}

export interface EntradaListaLancamento {
  data: string;
  parametros: ParametrosListaLancamento;
  aulas: readonly AulaDaLista[];
  presencas: readonly { aula_id: string; aluno_id: string }[];
  alunos: readonly AlunoDaLista[];
}

/** Frequência de cada aluno matriculado na data, na ordem recebida. */
export function calcularListaLancamento(entrada: EntradaListaLancamento): FrequenciaNaLista[] {
  const { data, parametros } = entrada;
  const dataDaAula = new Map(entrada.aulas.map((a) => [a.id, a.data]));
  const presencasDoAluno = new Map<string, Set<string>>();
  for (const p of entrada.presencas) {
    if (!dataDaAula.has(p.aula_id)) continue;
    const aulas = presencasDoAluno.get(p.aluno_id) ?? new Set<string>();
    aulas.add(p.aula_id);
    presencasDoAluno.set(p.aluno_id, aulas);
  }
  const regularesAnteriores = entrada.aulas
    .filter((a) => a.tipo === 'regular' && a.data < data)
    .sort((a, b) => (a.data < b.data ? 1 : a.data > b.data ? -1 : 0));

  const resultado: FrequenciaNaLista[] = [];
  for (const aluno of entrada.alunos) {
    if (!aluno.matriculas.some((m) => estaMatriculadoNaData(data, m))) continue;
    const presencas = presencasDoAluno.get(aluno.id) ?? new Set<string>();
    const consideradas = regularesAnteriores
      .filter((a) => aluno.matriculas.some((m) => estaMatriculadoNaData(a.data, m)))
      .slice(0, parametros.ultimas_aulas);
    const presentes = consideradas.filter((a) => presencas.has(a.id)).length;
    const novo = consideradas.length < parametros.ultimas_aulas;
    const percentual = consideradas.length === 0 ? 0 : Math.floor((presentes * 100) / consideradas.length);
    let ultima: string | null = null;
    for (const aulaId of presencas) {
      const d = dataDaAula.get(aulaId);
      if (d !== undefined && d <= data && (ultima === null || d > ultima)) ultima = d;
    }
    resultado.push({
      aluno_id: aluno.id,
      percentual,
      novo,
      frequente: novo || percentual >= parametros.percentual_minimo,
      ultima_presenca: ultima,
    });
  }
  return resultado;
}
