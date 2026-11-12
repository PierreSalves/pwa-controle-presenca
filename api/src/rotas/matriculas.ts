// Matrículas (aluno × turma com período), online. Tela 9 e atalho "Encerrar" dos alunos sumidos (tela 2).
// Exige acesso à turma. O mesmo aluno não pode ter duas matrículas com dias em comum na mesma turma.
import { Hono, type Context } from 'hono';
import { autenticar, exigirPermissao } from '../middleware/autenticar';
import { temSobreposicao, type Periodo } from '../regras/alunos';
import { ehDataValida } from '../regras/presenca';
import { temAcessoATurma } from '../seguranca/acesso-turmas';
import type { Contexto } from '../tipos';
import { responderErro } from '../util/erros';
import { gerarUuidV7 } from '../util/ids';
import { obterAgoraIso } from '../util/tempo';
import { ehUuid, lerCorpoJson } from '../util/validacao';
import { prepararIncrementoVersao, SQL_VERSAO_ATUAL } from '../util/versao';

export const rotasMatriculas = new Hono<Contexto>();
rotasMatriculas.use('*', autenticar, exigirPermissao('gerenciar_matriculas'));

type Ctx = Context<Contexto>;
type Situacao = 'matriculado' | 'remanejado' | 'encerrado';
interface DadosPeriodo extends Periodo {
  situacao: Situacao;
}

const SELECT_MATRICULA = `SELECT m.id, m.aluno_id, m.turma_id, t.nome AS turma_nome, m.data_inicio, m.data_fim, m.situacao
                            FROM matriculas m JOIN turmas t ON t.id = m.turma_id`;

/** Período e situação. Sem situação informada: com data de fim é 'encerrado', sem data de fim é 'matriculado'. */
function lerPeriodo(corpo: Record<string, unknown> | null): DadosPeriodo | null {
  if (!corpo || !ehDataValida(corpo.data_inicio)) return null;
  const fim = corpo.data_fim ?? null;
  if (fim !== null && (!ehDataValida(fim) || fim < corpo.data_inicio)) return null;
  const situacao = corpo.situacao ?? (fim === null ? 'matriculado' : 'encerrado');
  if (situacao !== 'matriculado' && situacao !== 'remanejado' && situacao !== 'encerrado') return null;
  return { data_inicio: corpo.data_inicio, data_fim: fim, situacao };
}

async function haOutraMatriculaNoPeriodo(
  db: D1Database,
  tenantId: string,
  alunoId: string,
  turmaId: string,
  periodo: Periodo,
  ignorarId: string | null,
): Promise<boolean> {
  const { results } = await db
    .prepare(
      `SELECT data_inicio, data_fim FROM matriculas
        WHERE tenant_id = ?1 AND aluno_id = ?2 AND turma_id = ?3 AND excluido = 0 AND id <> coalesce(?4, '')`,
    )
    .bind(tenantId, alunoId, turmaId, ignorarId)
    .all<Periodo>();
  return results.some((outra) => temSobreposicao(periodo, outra));
}

async function obterMatricula(db: D1Database, tenantId: string, matriculaId: string) {
  return db
    .prepare(`${SELECT_MATRICULA} WHERE m.id = ?1 AND m.tenant_id = ?2 AND m.excluido = 0`)
    .bind(matriculaId, tenantId)
    .first<{ id: string; aluno_id: string; turma_id: string }>();
}

/** Matrícula existente numa turma que o usuário acessa; senão `null` (a rota responde 404). */
async function obterMatriculaAcessivel(c: Ctx) {
  const usuario = c.get('usuario');
  const matriculaId = c.req.param('id');
  if (!usuario.tenantId || !matriculaId || !ehUuid(matriculaId)) return null;
  const matricula = await obterMatricula(c.env.DB, usuario.tenantId, matriculaId);
  if (!matricula || !(await temAcessoATurma(c.env.DB, usuario, matricula.turma_id))) return null;
  return { ...matricula, tenantId: usuario.tenantId };
}

rotasMatriculas.post('/', async (c) => {
  const usuario = c.get('usuario');
  const tenantId = usuario.tenantId;
  if (!tenantId) return responderErro(c, 403, 'sem_permissao');
  const corpo = await lerCorpoJson(c.req);
  const periodo = lerPeriodo(corpo);
  const alunoId = corpo?.aluno_id;
  const turmaId = corpo?.turma_id;
  if (!periodo || !ehUuid(alunoId) || !ehUuid(turmaId)) return responderErro(c, 400, 'dados_invalidos');

  const db = c.env.DB;
  if (!(await temAcessoATurma(db, usuario, turmaId))) return responderErro(c, 404, 'turma_nao_encontrada');
  const aluno = await db
    .prepare('SELECT 1 AS ok FROM alunos WHERE id = ?1 AND tenant_id = ?2 AND excluido = 0')
    .bind(alunoId, tenantId)
    .first();
  if (!aluno) return responderErro(c, 404, 'aluno_nao_encontrado');
  if (await haOutraMatriculaNoPeriodo(db, tenantId, alunoId, turmaId, periodo, null)) {
    return responderErro(c, 409, 'matricula_sobreposta');
  }

  const id = gerarUuidV7();
  const agora = obterAgoraIso();
  await db.batch([
    prepararIncrementoVersao(db),
    db
      .prepare(
        `INSERT INTO matriculas (id, tenant_id, aluno_id, turma_id, data_inicio, data_fim, situacao,
                                 created_at, updated_at, server_version, created_by, updated_by)
         VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?8, ${SQL_VERSAO_ATUAL}, ?9, ?9)`,
      )
      .bind(
        id,
        tenantId,
        alunoId,
        turmaId,
        periodo.data_inicio,
        periodo.data_fim,
        periodo.situacao,
        agora,
        usuario.id,
      ),
  ]);
  return c.json({ matricula: await obterMatricula(db, tenantId, id) }, 201);
});

/** Altera o período ou a situação (ex.: encerrar com a data da última presença). */
rotasMatriculas.put('/:id', async (c) => {
  const matricula = await obterMatriculaAcessivel(c);
  if (!matricula) return responderErro(c, 404, 'matricula_nao_encontrada');
  const periodo = lerPeriodo(await lerCorpoJson(c.req));
  if (!periodo) return responderErro(c, 400, 'dados_invalidos');
  const db = c.env.DB;
  const { tenantId } = matricula;
  if (
    await haOutraMatriculaNoPeriodo(
      db,
      tenantId,
      matricula.aluno_id,
      matricula.turma_id,
      periodo,
      matricula.id,
    )
  ) {
    return responderErro(c, 409, 'matricula_sobreposta');
  }
  await db.batch([
    prepararIncrementoVersao(db),
    db
      .prepare(
        `UPDATE matriculas SET data_inicio = ?1, data_fim = ?2, situacao = ?3, updated_at = ?4, updated_by = ?5,
                server_version = ${SQL_VERSAO_ATUAL}
          WHERE id = ?6 AND tenant_id = ?7`,
      )
      .bind(
        periodo.data_inicio,
        periodo.data_fim,
        periodo.situacao,
        obterAgoraIso(),
        c.get('usuario').id,
        matricula.id,
        tenantId,
      ),
  ]);
  return c.json({ matricula: await obterMatricula(db, tenantId, matricula.id) });
});

/** Exclusão lógica (matrícula lançada por engano). Para o aluno que saiu, use o encerramento. */
rotasMatriculas.delete('/:id', async (c) => {
  const matricula = await obterMatriculaAcessivel(c);
  if (!matricula) return responderErro(c, 404, 'matricula_nao_encontrada');
  const db = c.env.DB;
  await db.batch([
    prepararIncrementoVersao(db),
    db
      .prepare(
        `UPDATE matriculas SET excluido = 1, updated_at = ?1, updated_by = ?2, server_version = ${SQL_VERSAO_ATUAL}
          WHERE id = ?3 AND tenant_id = ?4`,
      )
      .bind(obterAgoraIso(), c.get('usuario').id, matricula.id, matricula.tenantId),
  ]);
  return c.body(null, 204);
});
