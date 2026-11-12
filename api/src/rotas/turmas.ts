// Cadastro de turmas (online): dados da turma, quadro de aulas, regras da turma e acessos.
// Tela 10 dos wireframes (docs/telas/README.md). Contrato em docs/arquitetura/README.md.
//
// O professor vê e administra todas as turmas da academia; a assistente, só as liberadas para ela.
// Toda gravação em tabela sincronizada incrementa o server_version, para o app receber no próximo pull.
import { Hono, type Context } from 'hono';
import { autenticar, exigirPermissao } from '../middleware/autenticar';
import {
  calcularRegrasDaTurma,
  lerParametrosAlunosSumidos,
  lerParametrosListaLancamento,
  TIPOS_REGRA_TURMA,
  type TipoRegraTurma,
} from '../regras/configuracao-turma';
import { ehDataValida, obterHojeEmSaoPaulo, type DiaDaSemana } from '../regras/presenca';
import { temAcessoATurma, veTodasAsTurmas } from '../seguranca/acesso-turmas';
import type { Contexto, UsuarioAutenticado } from '../tipos';
import { somarDiasNaData } from '../util/datas';
import { responderErro } from '../util/erros';
import { gerarUuidV7 } from '../util/ids';
import { obterAgoraIso } from '../util/tempo';
import {
  ehUuid,
  lerCorpoJson,
  lerInteiroOpcional,
  lerTextoObrigatorio,
  lerTextoOpcional,
} from '../util/validacao';
import { prepararIncrementoVersao, SQL_VERSAO_ATUAL } from '../util/versao';

const DIAS: readonly DiaDaSemana[] = ['domingo', 'segunda', 'terca', 'quarta', 'quinta', 'sexta', 'sabado'];

export const rotasTurmas = new Hono<Contexto>();
rotasTurmas.use('*', autenticar, exigirPermissao('gerenciar_turmas'));

type Ctx = Context<Contexto>;

interface DadosTurma {
  nome: string;
  descricao: string | null;
  frequencia_minima: number | null;
  cabecalho_impressao: string | null;
}

function lerDadosTurma(corpo: Record<string, unknown> | null): DadosTurma | null {
  if (!corpo) return null;
  const nome = lerTextoObrigatorio(corpo.nome, 80);
  const descricao = lerTextoOpcional(corpo.descricao, 500);
  const frequencia = lerInteiroOpcional(corpo.frequencia_minima, 0, 100);
  const cabecalho = lerTextoOpcional(corpo.cabecalho_impressao, 200);
  if (nome === undefined || descricao === undefined || frequencia === undefined || cabecalho === undefined) {
    return null;
  }
  return { nome, descricao, frequencia_minima: frequencia, cabecalho_impressao: cabecalho };
}

function obterUsuarioComTenant(c: Ctx): (UsuarioAutenticado & { tenantId: string }) | null {
  const usuario = c.get('usuario');
  return usuario.tenantId ? { ...usuario, tenantId: usuario.tenantId } : null;
}

async function existeOutraTurmaComNome(
  db: D1Database,
  tenantId: string,
  nome: string,
  ignorarId: string | null,
): Promise<boolean> {
  const linha = await db
    .prepare(
      `SELECT 1 AS ok FROM turmas
        WHERE tenant_id = ?1 AND nome = ?2 COLLATE NOCASE AND excluido = 0 AND id <> coalesce(?3, '')`,
    )
    .bind(tenantId, nome, ignorarId)
    .first();
  return linha !== null;
}

async function obterTurma(db: D1Database, tenantId: string, turmaId: string) {
  return db
    .prepare(
      `SELECT id, nome, descricao, frequencia_minima, cabecalho_impressao, updated_at
         FROM turmas WHERE id = ?1 AND tenant_id = ?2 AND excluido = 0`,
    )
    .bind(turmaId, tenantId)
    .first();
}

async function obterQuadros(db: D1Database, tenantId: string, turmaId: string) {
  const { results } = await db
    .prepare(
      `SELECT id, vigencia_inicio, vigencia_fim, ${DIAS.join(', ')}
         FROM quadros_aulas WHERE turma_id = ?1 AND tenant_id = ?2 AND excluido = 0
        ORDER BY vigencia_inicio`,
    )
    .bind(turmaId, tenantId)
    .all<
      { id: string; vigencia_inicio: string; vigencia_fim: string | null } & Record<DiaDaSemana, number>
    >();
  return results;
}

async function obterRegras(db: D1Database, tenantId: string, turmaId: string, hoje: string) {
  const { results } = await db
    .prepare(
      `SELECT tipo, parametros FROM regras
        WHERE tenant_id = ?1 AND escopo = 'turma' AND escopo_id = ?2 AND excluido = 0 AND vigencia_inicio <= ?3
        ORDER BY vigencia_inicio`,
    )
    .bind(tenantId, turmaId, hoje)
    .all<{ tipo: string; parametros: string }>();
  return calcularRegrasDaTurma(results);
}

async function obterAcessos(db: D1Database, tenantId: string, turmaId: string) {
  const { results } = await db
    .prepare(
      `SELECT u.id, u.nome, u.tipo
         FROM turma_usuarios tu
         JOIN usuarios u ON u.id = tu.usuario_id
        WHERE tu.turma_id = ?1 AND tu.tenant_id = ?2 AND tu.excluido = 0 AND u.excluido = 0
        ORDER BY u.nome COLLATE NOCASE`,
    )
    .bind(turmaId, tenantId)
    .all();
  return results;
}

/** Lista as turmas que o usuário pode ver, com o número de alunos com matrícula vigente hoje. */
rotasTurmas.get('/', async (c) => {
  const usuario = obterUsuarioComTenant(c);
  if (!usuario) return responderErro(c, 403, 'sem_permissao');
  const hoje = obterHojeEmSaoPaulo();
  const { results } = await c.env.DB.prepare(
    `SELECT t.id, t.nome, t.descricao, t.frequencia_minima, t.cabecalho_impressao,
            (SELECT COUNT(DISTINCT m.aluno_id) FROM matriculas m
              WHERE m.turma_id = t.id AND m.excluido = 0 AND m.data_inicio <= ?4
                AND (m.data_fim IS NULL OR m.data_fim >= ?4)) AS alunos_matriculados
       FROM turmas t
      WHERE t.tenant_id = ?1 AND t.excluido = 0
        AND (?2 = 1 OR EXISTS (
              SELECT 1 FROM turma_usuarios tu
               WHERE tu.turma_id = t.id AND tu.usuario_id = ?3 AND tu.tenant_id = ?1 AND tu.excluido = 0))
      ORDER BY t.nome COLLATE NOCASE`,
  )
    .bind(usuario.tenantId, veTodasAsTurmas(usuario) ? 1 : 0, usuario.id, hoje)
    .all();
  return c.json({ turmas: results });
});

/** Cria a turma. Quem cria ganha acesso a ela automaticamente. */
rotasTurmas.post('/', async (c) => {
  const usuario = obterUsuarioComTenant(c);
  if (!usuario) return responderErro(c, 403, 'sem_permissao');
  const dados = lerDadosTurma(await lerCorpoJson(c.req));
  if (!dados) return responderErro(c, 400, 'dados_invalidos');

  const db = c.env.DB;
  if (await existeOutraTurmaComNome(db, usuario.tenantId, dados.nome, null)) {
    return responderErro(c, 409, 'nome_ja_existe');
  }
  const id = gerarUuidV7();
  const agora = obterAgoraIso();
  await db.batch([
    prepararIncrementoVersao(db),
    db
      .prepare(
        `INSERT INTO turmas (id, tenant_id, nome, descricao, frequencia_minima, cabecalho_impressao,
                             created_at, updated_at, server_version, created_by, updated_by)
         VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?7, ${SQL_VERSAO_ATUAL}, ?8, ?8)`,
      )
      .bind(
        id,
        usuario.tenantId,
        dados.nome,
        dados.descricao,
        dados.frequencia_minima,
        dados.cabecalho_impressao,
        agora,
        usuario.id,
      ),
    db
      .prepare(
        `INSERT INTO turma_usuarios (id, tenant_id, turma_id, usuario_id, created_at, updated_at,
                                     server_version, created_by, updated_by)
         VALUES (?1, ?2, ?3, ?4, ?5, ?5, ${SQL_VERSAO_ATUAL}, ?4, ?4)`,
      )
      .bind(gerarUuidV7(), usuario.tenantId, id, usuario.id, agora),
  ]);
  return c.json({ turma: await obterTurma(db, usuario.tenantId, id) }, 201);
});

/** Turma completa para a tela de configuração: dados, quadros, regras e quem acessa. */
rotasTurmas.get('/:id', async (c) => {
  const usuario = obterUsuarioComTenant(c);
  const turmaId = c.req.param('id');
  const db = c.env.DB;
  if (!usuario || !ehUuid(turmaId) || !(await temAcessoATurma(db, usuario, turmaId))) {
    return responderErro(c, 404, 'turma_nao_encontrada');
  }
  const hoje = obterHojeEmSaoPaulo();
  const [turma, quadros, regras, acessos] = await Promise.all([
    obterTurma(db, usuario.tenantId, turmaId),
    obterQuadros(db, usuario.tenantId, turmaId),
    obterRegras(db, usuario.tenantId, turmaId, hoje),
    obterAcessos(db, usuario.tenantId, turmaId),
  ]);
  return c.json({ turma, quadros, regras, acessos });
});

rotasTurmas.put('/:id', async (c) => {
  const usuario = obterUsuarioComTenant(c);
  const turmaId = c.req.param('id');
  const db = c.env.DB;
  if (!usuario || !ehUuid(turmaId) || !(await temAcessoATurma(db, usuario, turmaId))) {
    return responderErro(c, 404, 'turma_nao_encontrada');
  }
  const dados = lerDadosTurma(await lerCorpoJson(c.req));
  if (!dados) return responderErro(c, 400, 'dados_invalidos');
  if (await existeOutraTurmaComNome(db, usuario.tenantId, dados.nome, turmaId)) {
    return responderErro(c, 409, 'nome_ja_existe');
  }
  await db.batch([
    prepararIncrementoVersao(db),
    db
      .prepare(
        `UPDATE turmas SET nome = ?1, descricao = ?2, frequencia_minima = ?3, cabecalho_impressao = ?4,
                           updated_at = ?5, updated_by = ?6, server_version = ${SQL_VERSAO_ATUAL}
          WHERE id = ?7 AND tenant_id = ?8`,
      )
      .bind(
        dados.nome,
        dados.descricao,
        dados.frequencia_minima,
        dados.cabecalho_impressao,
        obterAgoraIso(),
        usuario.id,
        turmaId,
        usuario.tenantId,
      ),
  ]);
  return c.json({ turma: await obterTurma(db, usuario.tenantId, turmaId) });
});

/** Exclusão lógica. A turma some do aparelho de quem a acessava no próximo pull. */
rotasTurmas.delete('/:id', async (c) => {
  const usuario = obterUsuarioComTenant(c);
  const turmaId = c.req.param('id');
  const db = c.env.DB;
  if (!usuario || !ehUuid(turmaId) || !(await temAcessoATurma(db, usuario, turmaId))) {
    return responderErro(c, 404, 'turma_nao_encontrada');
  }
  await db.batch([
    prepararIncrementoVersao(db),
    db
      .prepare(
        `UPDATE turmas SET excluido = 1, updated_at = ?1, updated_by = ?2, server_version = ${SQL_VERSAO_ATUAL}
          WHERE id = ?3 AND tenant_id = ?4`,
      )
      .bind(obterAgoraIso(), usuario.id, turmaId, usuario.tenantId),
  ]);
  return c.body(null, 204);
});

/**
 * Novo quadro de aulas a partir de `vigencia_inicio` (cada dia: 0 sem aula, 1 regular, 2 reposição).
 * O quadro anterior em aberto termina na véspera. Mesma data de início do último quadro = corrige esse quadro.
 * Não aceita início anterior ao do último quadro (para não reescrever o histórico do meio).
 */
rotasTurmas.post('/:id/quadros', async (c) => {
  const usuario = obterUsuarioComTenant(c);
  const turmaId = c.req.param('id');
  const db = c.env.DB;
  if (!usuario || !ehUuid(turmaId) || !(await temAcessoATurma(db, usuario, turmaId))) {
    return responderErro(c, 404, 'turma_nao_encontrada');
  }
  const corpo = await lerCorpoJson(c.req);
  const inicio = corpo?.vigencia_inicio;
  const diasInformados = (
    typeof corpo?.dias === 'object' && corpo.dias !== null ? corpo.dias : null
  ) as Record<string, unknown> | null;
  if (!ehDataValida(inicio) || !diasInformados) return responderErro(c, 400, 'dados_invalidos');
  const dias = DIAS.map((d) => diasInformados[d] ?? 0);
  if (dias.some((v) => v !== 0 && v !== 1 && v !== 2)) return responderErro(c, 400, 'dados_invalidos');

  const quadros = await obterQuadros(db, usuario.tenantId, turmaId);
  const ultimo = quadros[quadros.length - 1];
  if (ultimo && inicio < ultimo.vigencia_inicio)
    return responderErro(c, 409, 'vigencia_anterior_ao_quadro_atual');

  const agora = obterAgoraIso();
  const comandos: D1PreparedStatement[] = [prepararIncrementoVersao(db)];
  if (ultimo && ultimo.vigencia_inicio === inicio) {
    comandos.push(
      db
        .prepare(
          `UPDATE quadros_aulas SET ${DIAS.map((d, i) => `${d} = ?${i + 1}`).join(', ')},
                  updated_at = ?8, updated_by = ?9, server_version = ${SQL_VERSAO_ATUAL}
            WHERE id = ?10 AND tenant_id = ?11`,
        )
        .bind(...dias, agora, usuario.id, ultimo.id, usuario.tenantId),
    );
  } else {
    if (ultimo && (ultimo.vigencia_fim === null || ultimo.vigencia_fim >= inicio)) {
      comandos.push(
        db
          .prepare(
            `UPDATE quadros_aulas SET vigencia_fim = ?1, updated_at = ?2, updated_by = ?3,
                    server_version = ${SQL_VERSAO_ATUAL}
              WHERE id = ?4 AND tenant_id = ?5`,
          )
          .bind(somarDiasNaData(inicio, -1), agora, usuario.id, ultimo.id, usuario.tenantId),
      );
    }
    comandos.push(
      db
        .prepare(
          `INSERT INTO quadros_aulas (id, tenant_id, turma_id, vigencia_inicio, ${DIAS.join(', ')},
                                      created_at, updated_at, server_version, created_by, updated_by)
           VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11, ?12, ?12, ${SQL_VERSAO_ATUAL}, ?13, ?13)`,
        )
        .bind(gerarUuidV7(), usuario.tenantId, turmaId, inicio, ...dias, agora, usuario.id),
    );
  }
  await db.batch(comandos);
  return c.json({ quadros: await obterQuadros(db, usuario.tenantId, turmaId) }, 201);
});

/**
 * Regras da turma: lista do lançamento e alunos sumidos (os dois são opcionais no corpo).
 * Grava com vigência a partir de hoje e atualiza a turma para o app receber as regras no pull.
 */
rotasTurmas.put('/:id/regras', async (c) => {
  const usuario = obterUsuarioComTenant(c);
  const turmaId = c.req.param('id');
  const db = c.env.DB;
  if (!usuario || !ehUuid(turmaId) || !(await temAcessoATurma(db, usuario, turmaId))) {
    return responderErro(c, 404, 'turma_nao_encontrada');
  }
  const corpo = await lerCorpoJson(c.req);
  if (!corpo) return responderErro(c, 400, 'dados_invalidos');
  const novas = new Map<TipoRegraTurma, object>();
  for (const tipo of TIPOS_REGRA_TURMA) {
    if (corpo[tipo] === undefined) continue;
    const parametros =
      tipo === 'lista_lancamento'
        ? lerParametrosListaLancamento(corpo[tipo])
        : lerParametrosAlunosSumidos(corpo[tipo]);
    if (!parametros) return responderErro(c, 400, 'dados_invalidos');
    novas.set(tipo, parametros);
  }
  if (novas.size === 0) return responderErro(c, 400, 'dados_invalidos');

  const hoje = obterHojeEmSaoPaulo();
  const agora = obterAgoraIso();
  const { results: deHoje } = await db
    .prepare(
      `SELECT id, tipo FROM regras
        WHERE tenant_id = ?1 AND escopo = 'turma' AND escopo_id = ?2 AND vigencia_inicio = ?3 AND excluido = 0`,
    )
    .bind(usuario.tenantId, turmaId, hoje)
    .all<{ id: string; tipo: string }>();

  const comandos: D1PreparedStatement[] = [prepararIncrementoVersao(db)];
  for (const [tipo, parametros] of novas) {
    const existente = deHoje.find((r) => r.tipo === tipo);
    comandos.push(
      existente
        ? db
            .prepare('UPDATE regras SET parametros = ?1, updated_at = ?2, updated_by = ?3 WHERE id = ?4')
            .bind(JSON.stringify(parametros), agora, usuario.id, existente.id)
        : db
            .prepare(
              `INSERT INTO regras (id, tenant_id, escopo, escopo_id, tipo, parametros, vigencia_inicio,
                                   created_at, updated_at, created_by, updated_by)
               VALUES (?1, ?2, 'turma', ?3, ?4, ?5, ?6, ?7, ?7, ?8, ?8)`,
            )
            .bind(
              gerarUuidV7(),
              usuario.tenantId,
              turmaId,
              tipo,
              JSON.stringify(parametros),
              hoje,
              agora,
              usuario.id,
            ),
    );
  }
  comandos.push(
    db
      .prepare(
        `UPDATE turmas SET updated_at = ?1, updated_by = ?2, server_version = ${SQL_VERSAO_ATUAL}
          WHERE id = ?3 AND tenant_id = ?4`,
      )
      .bind(agora, usuario.id, turmaId, usuario.tenantId),
  );
  await db.batch(comandos);
  return c.json({ regras: await obterRegras(db, usuario.tenantId, turmaId, hoje) });
});

/** Define a lista completa de usuários com acesso à turma. Só o professor (gerenciar_acessos). */
rotasTurmas.put('/:id/acessos', exigirPermissao('gerenciar_acessos'), async (c) => {
  const usuario = obterUsuarioComTenant(c);
  const turmaId = c.req.param('id');
  const db = c.env.DB;
  if (!usuario || !ehUuid(turmaId) || !(await temAcessoATurma(db, usuario, turmaId))) {
    return responderErro(c, 404, 'turma_nao_encontrada');
  }
  const corpo = await lerCorpoJson(c.req);
  const ids: unknown = corpo?.usuario_ids;
  if (!Array.isArray(ids) || ids.length > 200 || !ids.every((id) => typeof id === 'string')) {
    return responderErro(c, 400, 'dados_invalidos');
  }
  const desejados = new Set(ids as string[]);

  const [rValidos, rAtuais] = await db.batch([
    db
      .prepare(
        `SELECT id FROM usuarios
          WHERE tenant_id = ?1 AND excluido = 0 AND tipo IN ('professor', 'assistente')
            AND id IN (SELECT value FROM json_each(?2))`,
      )
      .bind(usuario.tenantId, JSON.stringify([...desejados])),
    db
      .prepare(
        'SELECT id, usuario_id FROM turma_usuarios WHERE turma_id = ?1 AND tenant_id = ?2 AND excluido = 0',
      )
      .bind(turmaId, usuario.tenantId),
  ]);
  const validos = new Set(((rValidos?.results ?? []) as { id: string }[]).map((r) => r.id));
  if (validos.size !== desejados.size) return responderErro(c, 400, 'usuario_invalido');
  const atuais = (rAtuais?.results ?? []) as { id: string; usuario_id: string }[];

  const remover = atuais.filter((a) => !desejados.has(a.usuario_id));
  const adicionar = [...desejados].filter((id) => !atuais.some((a) => a.usuario_id === id));
  if (remover.length > 0 || adicionar.length > 0) {
    const agora = obterAgoraIso();
    const comandos: D1PreparedStatement[] = [prepararIncrementoVersao(db)];
    for (const acesso of remover) {
      comandos.push(
        db
          .prepare(
            `UPDATE turma_usuarios SET excluido = 1, updated_at = ?1, updated_by = ?2,
                    server_version = ${SQL_VERSAO_ATUAL}
              WHERE id = ?3`,
          )
          .bind(agora, usuario.id, acesso.id),
      );
    }
    for (const usuarioId of adicionar) {
      comandos.push(
        db
          .prepare(
            `INSERT INTO turma_usuarios (id, tenant_id, turma_id, usuario_id, created_at, updated_at,
                                         server_version, created_by, updated_by)
             VALUES (?1, ?2, ?3, ?4, ?5, ?5, ${SQL_VERSAO_ATUAL}, ?6, ?6)`,
          )
          .bind(gerarUuidV7(), usuario.tenantId, turmaId, usuarioId, agora, usuario.id),
      );
    }
    await db.batch(comandos);
  }
  return c.json({ acessos: await obterAcessos(db, usuario.tenantId, turmaId) });
});
