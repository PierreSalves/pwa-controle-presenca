// Regras de presença. Os casos de teste ficam em docs/casos-regras/presenca.json e
// rodam também no app (Dart), para as duas implementações nunca divergirem.
import { converterTextoEmBytes } from '../util/codificacao';

export type DiaDaSemana = 'domingo' | 'segunda' | 'terca' | 'quarta' | 'quinta' | 'sexta' | 'sabado';
export type TipoDia = 'sem_aula' | 'regular' | 'reposicao';

const DIAS: readonly DiaDaSemana[] = ['domingo', 'segunda', 'terca', 'quarta', 'quinta', 'sexta', 'sabado'];
const PADRAO_DATA = /^\d{4}-\d{2}-\d{2}$/;

export interface QuadroAulas {
  vigencia_inicio: string;
  vigencia_fim: string | null;
  dias: Record<DiaDaSemana, number>;
}

export interface PeriodoMatricula {
  data_inicio: string;
  data_fim: string | null;
}

/** Data de calendário válida no formato AAAA-MM-DD. */
export function ehDataValida(data: unknown): data is string {
  if (typeof data !== 'string' || !PADRAO_DATA.test(data)) return false;
  const [ano, mes, dia] = data.split('-').map(Number) as [number, number, number];
  const d = new Date(Date.UTC(ano, mes - 1, dia));
  return d.getUTCFullYear() === ano && d.getUTCMonth() === mes - 1 && d.getUTCDate() === dia;
}

export function obterDiaDaSemana(data: string): DiaDaSemana {
  const [ano, mes, dia] = data.split('-').map(Number) as [number, number, number];
  return DIAS[new Date(Date.UTC(ano, mes - 1, dia)).getUTCDay()] as DiaDaSemana;
}

/** Dia de hoje (AAAA-MM-DD) no fuso da academia, America/Sao_Paulo. */
export function obterHojeEmSaoPaulo(instante: Date = new Date()): string {
  return new Intl.DateTimeFormat('en-CA', {
    timeZone: 'America/Sao_Paulo',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).format(instante);
}

export function ehDataFutura(data: string, hoje: string): boolean {
  return data > hoje;
}

export function estaMatriculadoNaData(data: string, matricula: PeriodoMatricula): boolean {
  return matricula.data_inicio <= data && (matricula.data_fim === null || data <= matricula.data_fim);
}

/** Tipo do dia segundo o quadro vigente na data (o mais recente que cobre a data). */
export function calcularTipoDoDia(data: string, quadros: readonly QuadroAulas[]): TipoDia {
  const vigente = quadros
    .filter((q) => q.vigencia_inicio <= data && (q.vigencia_fim === null || data <= q.vigencia_fim))
    .sort((a, b) => b.vigencia_inicio.localeCompare(a.vigencia_inicio))[0];
  if (!vigente) return 'sem_aula';
  const valor = vigente.dias[obterDiaDaSemana(data)];
  return valor === 1 ? 'regular' : valor === 2 ? 'reposicao' : 'sem_aula';
}

// Namespace fixo do projeto para os UUID v5 das aulas (não mudar: o app usa o mesmo).
const NAMESPACE_AULAS = '6f1c2b8e-4a3d-5e7f-9b0a-1c2d3e4f5a6b';

function converterUuidEmBytes(uuid: string): Uint8Array {
  const hex = uuid.replace(/-/g, '');
  const bytes = new Uint8Array(16);
  for (let i = 0; i < 16; i++) bytes[i] = parseInt(hex.slice(i * 2, i * 2 + 2), 16);
  return bytes;
}

/**
 * Id determinístico (UUID v5) de uma aula do quadro: regular ou reposição fixa.
 * Dois aparelhos offline que abrem a mesma aula geram o mesmo id.
 */
export async function gerarIdAulaDoQuadro(
  turmaId: string,
  dataAula: string,
  tipo: 'regular' | 'reposicao',
): Promise<string> {
  const nome = converterTextoEmBytes(`${turmaId}|${dataAula}|${tipo}`);
  const entrada = new Uint8Array(16 + nome.length);
  entrada.set(converterUuidEmBytes(NAMESPACE_AULAS), 0);
  entrada.set(nome, 16);
  const hash = new Uint8Array(await crypto.subtle.digest('SHA-1', entrada)).slice(0, 16);
  hash[6] = ((hash[6] ?? 0) & 0x0f) | 0x50;
  hash[8] = ((hash[8] ?? 0) & 0x3f) | 0x80;
  const hex = Array.from(hash, (b) => b.toString(16).padStart(2, '0')).join('');
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
}
