// Cadastro de alunos (online): telas 8 e 9 dos wireframes. Contrato em docs/arquitetura/README.md.
//
// Alunos são da academia: qualquer professor ou assistente vê o cadastro para poder matricular.
// Os dados sensíveis (CPF, RG, endereço, telefones, responsáveis) só saem por estas rotas, nunca pelo sync.
import { Hono, type Context } from 'hono';
import { autenticar, exigirPermissao } from '../middleware/autenticar';
import { calcularProximoCodigo } from '../regras/alunos';
import { ehDataValida } from '../regras/presenca';
import { importarAlunos } from '../servicos/importacao-alunos';
import type { Contexto } from '../tipos';
import { responderErro } from '../util/erros';
import { gerarUuidV7 } from '../util/ids';
import { obterAgoraIso } from '../util/tempo';
import { ehUuid, lerCorpoJson, lerInteiro, lerTextoObrigatorio, lerTextoOpcional } from '../util/validacao';
import { prepararIncrementoVersao, SQL_VERSAO_ATUAL } from '../util/versao';

export const rotasAlunos = new Hono<Contexto>();
rotasAlunos.use('*', autenticar, exigirPermissao('gerenciar_alunos'));

type Ctx = Context<Contexto>;

/** Campos opcionais e sensíveis, com o tamanho máximo de cada um. */
const CAMPOS_SENSIVEIS = {
  sexo: 20,
  cpf: 20,
  rg: 30,
  telefone: 30,
  email: 120,
  endereco: 300,
  nome_pai: 120,
  telefone_pai: 30,
  nome_mae: 120,
  telefone_mae: 30,
  observacoes: 1000,
} as const;
type CampoSensivel = keyof typeof CAMPOS_SENSIVEIS;
const NOMES_SENSIVEIS = Object.keys(CAMPOS_SENSIVEIS) as CampoSensivel[];

type DadosAluno = { codigo: string; nome: string; ativo: number; data_nascimento: string | null } & Record<
  CampoSensivel,
  string | null
>;

function lerDadosAluno(corpo: Record<string, unknown> | null): DadosAluno | null {
  if (!corpo) return null;
  const codigo = lerTextoObrigatorio(corpo.codigo, 20);
  const nome = lerTextoObrigatorio(corpo.nome, 120);
  const ativo = corpo.ativo === undefined ? 1 : lerInteiro(corpo.ativo, 0, 1);
  const nascimento = corpo.data_nascimento ?? null;
  if (codigo === undefined || nome === undefined || ativo === undefined) return null;
  if (nascimento !== null && !ehDataValida(nascimento)) return null;
  const dados = { codigo, nome, ativo, data_nascimento: nascimento } as DadosAluno;
  for (const campo of NOMES_SENSIVEIS) {
    const valor = lerTextoOpcional(corpo[campo], CAMPOS_SENSIVEIS[campo]);
    if (valor === undefined) return null;
    dados[campo] = valor;
  }
  return dados;
}

function obterTenantId(c: Ctx): string | null {
  return c.get('usuario').tenantId;
}

async function existeOutroAlunoComCodigo(
  db: D1Database,
  tenantId: string,
  codigo: string,
  ignorarId: string | null,
) {
  const linha = await db
    .prepare(
      `SELECT 1 AS ok FROM alunos
        WHERE tenant_id = ?1 AND codigo = ?2 COLLATE NOCASE AND excluido = 0 AND id <> coalesce(?3, '')`,
    )
    .bind(tenantId, codigo, ignorarId)
    .first();
  return linha !== null;
}

async function obterAlunoCompleto(db: D1Database, tenantId: string, alunoId: string) {
  const aluno = await db
    .prepare(
      `SELECT id, codigo, nome, ativo, data_nascimento, ${NOMES_SENSIVEIS.join(', ')}, updated_at
         FROM alunos WHERE id = ?1 AND tenant_id = ?2 AND excluido = 0`,
    )
    .bind(alunoId, tenantId)
    .first();
  if (!aluno) return null;
  const [matriculas, graduacoes] = await db.batch([
    db
      .prepare(
        `SELECT m.id, m.turma_id, t.nome AS turma_nome, m.data_inicio, m.data_fim, m.situacao
           FROM matriculas m JOIN turmas t ON t.id = m.turma_id
          WHERE m.aluno_id = ?1 AND m.tenant_id = ?2 AND m.excluido = 0 AND t.excluido = 0
          ORDER BY m.data_inicio DESC`,
      )
      .bind(alunoId, tenantId),
    db
      .prepare(
        `SELECT id, faixa, grau, data_graduacao, observacoes FROM graduacoes
          WHERE aluno_id = ?1 AND tenant_id = ?2 AND excluido = 0 ORDER BY data_graduacao DESC`,
      )
      .bind(alunoId, tenantId),
  ]);
  return { aluno, matriculas: matriculas?.results ?? [], graduacoes: graduacoes?.results ?? [] };
}

/** Lista para a tela de alunos. `busca` filtra por nome ou código; `inativos=1` inclui os inativos. */
rotasAlunos.get('/', async (c) => {
  const tenantId = obterTenantId(c);
  if (!tenantId) return responderErro(c, 403, 'sem_permissao');
  const busca = (c.req.query('busca') ?? '').trim().slice(0, 60);
  const comInativos = c.req.query('inativos') === '1' ? 1 : 0;
  const padrao = `%${busca.replace(/[\\%_]/g, (s) => `\\${s}`)}%`;
  const { results } = await c.env.DB.prepare(
    `SELECT a.id, a.codigo, a.nome, a.ativo,
            (SELECT json_group_array(t.nome) FROM matriculas m JOIN turmas t ON t.id = m.turma_id
              WHERE m.aluno_id = a.id AND m.excluido = 0 AND t.excluido = 0 AND m.data_fim IS NULL) AS turmas
       FROM alunos a
      WHERE a.tenant_id = ?1 AND a.excluido = 0 AND (?2 = 1 OR a.ativo = 1)
        AND (?3 = '' OR a.nome LIKE ?4 ESCAPE '\\' OR a.codigo LIKE ?4 ESCAPE '\\')
      ORDER BY a.nome COLLATE NOCASE
      LIMIT 1000`,
  )
    .bind(tenantId, comInativos, busca, padrao)
    .all<{ turmas: string }>();
  return c.json({
    alunos: results.map((a) => ({ ...a, turmas: JSON.parse(a.turmas) as string[] })),
  });
});

/** Código sugerido para o próximo aluno (o próximo número livre). */
rotasAlunos.get('/proximo-codigo', async (c) => {
  const tenantId = obterTenantId(c);
  if (!tenantId) return responderErro(c, 403, 'sem_permissao');
  const { results } = await c.env.DB.prepare(
    'SELECT codigo FROM alunos WHERE tenant_id = ?1 AND excluido = 0',
  )
    .bind(tenantId)
    .all<{ codigo: string }>();
  return c.json({ codigo: calcularProximoCodigo(results.map((r) => r.codigo)) });
});

rotasAlunos.post('/', async (c) => {
  const tenantId = obterTenantId(c);
  if (!tenantId) return responderErro(c, 403, 'sem_permissao');
  const dados = lerDadosAluno(await lerCorpoJson(c.req));
  if (!dados) return responderErro(c, 400, 'dados_invalidos');
  const db = c.env.DB;
  if (await existeOutroAlunoComCodigo(db, tenantId, dados.codigo, null)) {
    return responderErro(c, 409, 'codigo_ja_existe');
  }
  const id = gerarUuidV7();
  const agora = obterAgoraIso();
  const usuarioId = c.get('usuario').id;
  const colunas = ['codigo', 'nome', 'ativo', 'data_nascimento', ...NOMES_SENSIVEIS] as const;
  await db.batch([
    prepararIncrementoVersao(db),
    db
      .prepare(
        `INSERT INTO alunos (id, tenant_id, ${colunas.join(', ')}, created_at, updated_at, server_version,
                             created_by, updated_by)
         VALUES (?1, ?2, ${colunas.map((_, i) => `?${i + 3}`).join(', ')}, ?${colunas.length + 3},
                 ?${colunas.length + 3}, ${SQL_VERSAO_ATUAL}, ?${colunas.length + 4}, ?${colunas.length + 4})`,
      )
      .bind(id, tenantId, ...colunas.map((col) => dados[col]), agora, usuarioId),
  ]);
  return c.json(await obterAlunoCompleto(db, tenantId, id), 201);
});

/**
 * Importação da lista de alunos (código + nome). Sem `confirmar`, devolve só o relatório de
 * códigos repetidos/existentes e nomes repetidos; com `confirmar: true`, grava se não houver bloqueio.
 */
rotasAlunos.post('/importacao', async (c) => {
  const tenantId = obterTenantId(c);
  if (!tenantId) return responderErro(c, 403, 'sem_permissao');
  const resultado = await importarAlunos(c.env.DB, tenantId, c.get('usuario').id, await lerCorpoJson(c.req));
  if (resultado.tipo === 'dados_invalidos') return responderErro(c, 400, 'dados_invalidos');
  if (resultado.tipo === 'relatorio') return c.json({ relatorio: resultado.relatorio, importados: 0 });
  return c.json({ relatorio: resultado.relatorio, importados: resultado.importados }, 201);
});

rotasAlunos.get('/:id', async (c) => {
  const tenantId = obterTenantId(c);
  const alunoId = c.req.param('id');
  const completo = tenantId && ehUuid(alunoId) ? await obterAlunoCompleto(c.env.DB, tenantId, alunoId) : null;
  if (!completo) return responderErro(c, 404, 'aluno_nao_encontrado');
  return c.json(completo);
});

rotasAlunos.put('/:id', async (c) => {
  const tenantId = obterTenantId(c);
  const alunoId = c.req.param('id');
  const db = c.env.DB;
  if (!tenantId || !ehUuid(alunoId) || !(await obterAlunoCompleto(db, tenantId, alunoId))) {
    return responderErro(c, 404, 'aluno_nao_encontrado');
  }
  const dados = lerDadosAluno(await lerCorpoJson(c.req));
  if (!dados) return responderErro(c, 400, 'dados_invalidos');
  if (await existeOutroAlunoComCodigo(db, tenantId, dados.codigo, alunoId)) {
    return responderErro(c, 409, 'codigo_ja_existe');
  }
  const colunas = ['codigo', 'nome', 'ativo', 'data_nascimento', ...NOMES_SENSIVEIS] as const;
  const n = colunas.length;
  await db.batch([
    prepararIncrementoVersao(db),
    db
      .prepare(
        `UPDATE alunos SET ${colunas.map((col, i) => `${col} = ?${i + 1}`).join(', ')},
                updated_at = ?${n + 1}, updated_by = ?${n + 2}, server_version = ${SQL_VERSAO_ATUAL}
          WHERE id = ?${n + 3} AND tenant_id = ?${n + 4}`,
      )
      .bind(...colunas.map((col) => dados[col]), obterAgoraIso(), c.get('usuario').id, alunoId, tenantId),
  ]);
  return c.json(await obterAlunoCompleto(db, tenantId, alunoId));
});

/** Exclusão lógica do aluno e das matrículas dele (o código fica livre para outro aluno). */
rotasAlunos.delete('/:id', async (c) => {
  const tenantId = obterTenantId(c);
  const alunoId = c.req.param('id');
  const db = c.env.DB;
  if (!tenantId || !ehUuid(alunoId) || !(await obterAlunoCompleto(db, tenantId, alunoId))) {
    return responderErro(c, 404, 'aluno_nao_encontrado');
  }
  const agora = obterAgoraIso();
  const usuarioId = c.get('usuario').id;
  await db.batch([
    prepararIncrementoVersao(db),
    db
      .prepare(
        `UPDATE alunos SET excluido = 1, updated_at = ?1, updated_by = ?2, server_version = ${SQL_VERSAO_ATUAL}
          WHERE id = ?3 AND tenant_id = ?4`,
      )
      .bind(agora, usuarioId, alunoId, tenantId),
    db
      .prepare(
        `UPDATE matriculas SET excluido = 1, updated_at = ?1, updated_by = ?2, server_version = ${SQL_VERSAO_ATUAL}
          WHERE aluno_id = ?3 AND tenant_id = ?4 AND excluido = 0`,
      )
      .bind(agora, usuarioId, alunoId, tenantId),
  ]);
  return c.body(null, 204);
});

/** Registra uma graduação (faixa e grau) do aluno. */
rotasAlunos.post('/:id/graduacoes', async (c) => {
  const tenantId = obterTenantId(c);
  const alunoId = c.req.param('id');
  const db = c.env.DB;
  if (!tenantId || !ehUuid(alunoId) || !(await obterAlunoCompleto(db, tenantId, alunoId))) {
    return responderErro(c, 404, 'aluno_nao_encontrado');
  }
  const corpo = await lerCorpoJson(c.req);
  const faixa = lerTextoObrigatorio(corpo?.faixa, 40);
  const grau = corpo?.grau === undefined ? 0 : lerInteiro(corpo.grau, 0, 10);
  const observacoes = lerTextoOpcional(corpo?.observacoes, 500);
  if (
    faixa === undefined ||
    grau === undefined ||
    observacoes === undefined ||
    !ehDataValida(corpo?.data_graduacao)
  ) {
    return responderErro(c, 400, 'dados_invalidos');
  }
  const agora = obterAgoraIso();
  const usuarioId = c.get('usuario').id;
  await db
    .prepare(
      `INSERT INTO graduacoes (id, tenant_id, aluno_id, faixa, grau, data_graduacao, observacoes,
                               created_at, updated_at, created_by, updated_by)
       VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?8, ?9, ?9)`,
    )
    .bind(gerarUuidV7(), tenantId, alunoId, faixa, grau, corpo?.data_graduacao, observacoes, agora, usuarioId)
    .run();
  return c.json(await obterAlunoCompleto(db, tenantId, alunoId), 201);
});

rotasAlunos.delete('/:id/graduacoes/:graduacaoId', async (c) => {
  const tenantId = obterTenantId(c);
  const { id: alunoId, graduacaoId } = c.req.param();
  if (!tenantId || !ehUuid(alunoId) || !ehUuid(graduacaoId))
    return responderErro(c, 404, 'graduacao_nao_encontrada');
  const resultado = await c.env.DB.prepare(
    `UPDATE graduacoes SET excluido = 1, updated_at = ?1, updated_by = ?2
      WHERE id = ?3 AND aluno_id = ?4 AND tenant_id = ?5 AND excluido = 0`,
  )
    .bind(obterAgoraIso(), c.get('usuario').id, graduacaoId, alunoId, tenantId)
    .run();
  if (resultado.meta.changes === 0) return responderErro(c, 404, 'graduacao_nao_encontrada');
  return c.body(null, 204);
});
