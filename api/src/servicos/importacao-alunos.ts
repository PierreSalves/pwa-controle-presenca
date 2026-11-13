// Importação da lista de alunos das planilhas (código + nome). Usada pela academia
// (POST /api/alunos/importacao) e, na carga inicial, pelo administrador do sistema.
// Opcionalmente matricula todos os alunos importados numa turma, a partir de uma data única.
import type { Context } from 'hono';
import {
  calcularRelatorioImportacao,
  normalizarCodigoImportado,
  type LinhaImportacao,
  type RelatorioImportacao,
} from '../regras/alunos';
import { ehDataValida } from '../regras/presenca';
import { responderErro } from '../util/erros';
import { gerarUuidV7 } from '../util/ids';
import { obterAgoraIso } from '../util/tempo';
import { ehUuid } from '../util/validacao';
import { prepararIncrementoVersao, SQL_VERSAO_ATUAL } from '../util/versao';

export const MAXIMO_LINHAS_IMPORTACAO = 2000;

/** Turma e data em que os alunos importados serão matriculados (mostradas no relatório). */
export interface MatriculaImportacao {
  turma_id: string;
  turma_nome: string;
  data_inicio: string;
}

export type ResultadoImportacao =
  | { tipo: 'dados_invalidos' }
  | { tipo: 'turma_nao_encontrada' }
  | { tipo: 'relatorio'; relatorio: RelatorioImportacao; matricula: MatriculaImportacao | null }
  | {
      tipo: 'importado';
      relatorio: RelatorioImportacao;
      matricula: MatriculaImportacao | null;
      importados: number;
    };

/** Confere se quem importa pode matricular na turma (a academia da turma é conferida à parte). */
export type ValidadorTurma = (turmaId: string) => Promise<boolean>;

/** Lê as linhas enviadas pelo app: [{ codigo, nome }], numeradas a partir de 1. */
export function lerLinhasImportacao(valor: unknown): LinhaImportacao[] | null {
  if (!Array.isArray(valor) || valor.length === 0 || valor.length > MAXIMO_LINHAS_IMPORTACAO) return null;
  const linhas: LinhaImportacao[] = [];
  for (const [indice, item] of valor.entries()) {
    const dados = (typeof item === 'object' && item !== null ? item : {}) as Record<string, unknown>;
    const codigo = typeof dados.codigo === 'string' ? normalizarCodigoImportado(dados.codigo) : '';
    const nome = typeof dados.nome === 'string' ? dados.nome.trim().replace(/\s+/g, ' ') : '';
    if (codigo.length > 20 || nome.length > 120) return null;
    linhas.push({ linha: indice + 1, codigo, nome });
  }
  return linhas;
}

/**
 * Lê `turma_id` e `data_inicio` (AAAA-MM-DD), opcionais mas sempre juntos.
 * Devolve `null` sem matrícula e `undefined` quando inválido.
 */
export function lerMatriculaImportacao(
  corpo: Record<string, unknown> | null,
): { turma_id: string; data_inicio: string } | null | undefined {
  const turmaId = corpo?.turma_id ?? null;
  const dataInicio = corpo?.data_inicio ?? null;
  if (turmaId === null && dataInicio === null) return null;
  if (!ehUuid(turmaId) || !ehDataValida(dataInicio)) return undefined;
  return { turma_id: turmaId, data_inicio: dataInicio };
}

async function buscarNomeTurma(db: D1Database, tenantId: string, turmaId: string): Promise<string | null> {
  const turma = await db
    .prepare('SELECT nome FROM turmas WHERE id = ?1 AND tenant_id = ?2 AND excluido = 0')
    .bind(turmaId, tenantId)
    .first<{ nome: string }>();
  return turma?.nome ?? null;
}

/**
 * Sem `confirmar`, só devolve o relatório. Com `confirmar: true`, grava se o relatório permitir;
 * caso contrário devolve o relatório sem gravar nada. Alunos e matrículas vão no mesmo batch
 * (tudo ou nada) e com o mesmo server_version, para os aparelhos receberem tudo no próximo pull.
 *
 * Código já cadastrado impede a importação, então todos os alunos gravados são novos e nunca
 * têm outra matrícula na turma.
 */
export async function importarAlunos(
  db: D1Database,
  tenantId: string,
  usuarioId: string,
  corpo: Record<string, unknown> | null,
  podeAcessarTurma: ValidadorTurma,
): Promise<ResultadoImportacao> {
  const linhas = lerLinhasImportacao(corpo?.alunos);
  const pedidoMatricula = lerMatriculaImportacao(corpo);
  if (!linhas || pedidoMatricula === undefined) return { tipo: 'dados_invalidos' };

  let matricula: MatriculaImportacao | null = null;
  if (pedidoMatricula) {
    const nome = await buscarNomeTurma(db, tenantId, pedidoMatricula.turma_id);
    if (nome === null || !(await podeAcessarTurma(pedidoMatricula.turma_id))) {
      return { tipo: 'turma_nao_encontrada' };
    }
    matricula = { ...pedidoMatricula, turma_nome: nome };
  }

  const { results: existentes } = await db
    .prepare('SELECT codigo, nome FROM alunos WHERE tenant_id = ?1 AND excluido = 0')
    .bind(tenantId)
    .all<{ codigo: string; nome: string }>();
  const relatorio = calcularRelatorioImportacao(linhas, existentes);
  if (corpo?.confirmar !== true || !relatorio.pode_importar)
    return { tipo: 'relatorio', relatorio, matricula };

  const agora = obterAgoraIso();
  const novos = linhas.map((l) => ({
    id: gerarUuidV7(),
    matricula_id: gerarUuidV7(),
    codigo: l.codigo,
    nome: l.nome,
  }));
  const json = JSON.stringify(novos);
  const comandos = [
    prepararIncrementoVersao(db),
    db
      .prepare(
        `INSERT INTO alunos (id, tenant_id, codigo, nome, created_at, updated_at, server_version, created_by, updated_by)
         SELECT json_extract(value, '$.id'), ?1, json_extract(value, '$.codigo'), json_extract(value, '$.nome'),
                ?2, ?2, ${SQL_VERSAO_ATUAL}, ?3, ?3
           FROM json_each(?4)`,
      )
      .bind(tenantId, agora, usuarioId, json),
  ];
  if (matricula) {
    comandos.push(
      db
        .prepare(
          `INSERT INTO matriculas (id, tenant_id, aluno_id, turma_id, data_inicio, data_fim, situacao,
                                   created_at, updated_at, server_version, created_by, updated_by)
           SELECT json_extract(value, '$.matricula_id'), ?1, json_extract(value, '$.id'), ?2, ?3, NULL,
                  'matriculado', ?4, ?4, ${SQL_VERSAO_ATUAL}, ?5, ?5
             FROM json_each(?6)`,
        )
        .bind(tenantId, matricula.turma_id, matricula.data_inicio, agora, usuarioId, json),
    );
  }
  await db.batch(comandos);
  return { tipo: 'importado', relatorio, matricula, importados: novos.length };
}

/** Resposta das duas rotas de importação: 400, 404, 200 (só relatório) ou 201 (gravado). */
export function responderImportacao(c: Context, resultado: ResultadoImportacao) {
  if (resultado.tipo === 'dados_invalidos') return responderErro(c, 400, 'dados_invalidos');
  if (resultado.tipo === 'turma_nao_encontrada') return responderErro(c, 404, 'turma_nao_encontrada');
  const { relatorio, matricula } = resultado;
  if (resultado.tipo === 'relatorio') return c.json({ relatorio, matricula, importados: 0 });
  return c.json({ relatorio, matricula, importados: resultado.importados }, 201);
}
