// Usuários da academia (online): tela 11. Só o professor (gerenciar_usuarios + gerenciar_acessos).
// O usuário não se autocadastra: o professor cria com uma senha inicial e passa para a pessoa.
import { Hono, type Context } from 'hono';
import { autenticar, exigirPermissao } from '../middleware/autenticar';
import { ehSenhaValida, gerarHashSenha } from '../seguranca/senha';
import {
  existeOutroUsuarioComEmail,
  lerDadosNovoUsuario,
  lerEmail,
  lerTipoUsuarioDoTenant,
  prepararInsercaoUsuario,
  prepararRevogacaoSessoes,
} from '../servicos/usuarios';
import type { Contexto } from '../tipos';
import { responderErro } from '../util/erros';
import { gerarUuidV7 } from '../util/ids';
import { obterAgoraIso } from '../util/tempo';
import { ehUuid, lerCorpoJson, lerInteiro, lerTextoObrigatorio } from '../util/validacao';
import { prepararIncrementoVersao, SQL_VERSAO_ATUAL } from '../util/versao';

export const rotasUsuarios = new Hono<Contexto>();
rotasUsuarios.use(
  '*',
  autenticar,
  exigirPermissao('gerenciar_usuarios'),
  exigirPermissao('gerenciar_acessos'),
);

type Ctx = Context<Contexto>;

const SELECT_USUARIO = `
  SELECT u.id, u.nome, u.email, u.tipo, u.ativo, u.ultimo_login_em,
         (SELECT json_group_array(json_object('id', t.id, 'nome', t.nome))
            FROM turma_usuarios tu JOIN turmas t ON t.id = tu.turma_id
           WHERE tu.usuario_id = u.id AND tu.excluido = 0 AND t.excluido = 0) AS turmas
    FROM usuarios u`;

type LinhaUsuario = { turmas: string } & Record<string, unknown>;

function montarUsuario(linha: LinhaUsuario) {
  return { ...linha, turmas: JSON.parse(linha.turmas) as { id: string; nome: string }[] };
}

async function obterUsuario(db: D1Database, tenantId: string, usuarioId: string) {
  const linha = await db
    .prepare(`${SELECT_USUARIO} WHERE u.id = ?1 AND u.tenant_id = ?2 AND u.excluido = 0`)
    .bind(usuarioId, tenantId)
    .first<LinhaUsuario>();
  return linha ? montarUsuario(linha) : null;
}

/** Lê `turma_ids` (opcional) e confere que todas as turmas são da academia. `undefined` = inválido. */
async function lerTurmasDaAcademia(
  db: D1Database,
  tenantId: string,
  valor: unknown,
): Promise<string[] | undefined> {
  if (valor === undefined) return [];
  if (!Array.isArray(valor) || valor.length > 200 || !valor.every(ehUuid)) return undefined;
  const ids = [...new Set(valor as string[])];
  const { results } = await db
    .prepare(
      `SELECT id FROM turmas WHERE tenant_id = ?1 AND excluido = 0 AND id IN (SELECT value FROM json_each(?2))`,
    )
    .bind(tenantId, JSON.stringify(ids))
    .all();
  return results.length === ids.length ? ids : undefined;
}

/** Comandos para deixar o usuário com acesso exatamente às turmas informadas. */
async function prepararDefinicaoTurmas(
  db: D1Database,
  tenantId: string,
  usuarioId: string,
  turmaIds: string[],
  autorId: string,
  agora: string,
): Promise<D1PreparedStatement[]> {
  const { results: atuais } = await db
    .prepare(
      'SELECT id, turma_id FROM turma_usuarios WHERE usuario_id = ?1 AND tenant_id = ?2 AND excluido = 0',
    )
    .bind(usuarioId, tenantId)
    .all<{ id: string; turma_id: string }>();
  const desejadas = new Set(turmaIds);
  const comandos: D1PreparedStatement[] = [];
  for (const acesso of atuais.filter((a) => !desejadas.has(a.turma_id))) {
    comandos.push(
      db
        .prepare(
          `UPDATE turma_usuarios SET excluido = 1, updated_at = ?1, updated_by = ?2, server_version = ${SQL_VERSAO_ATUAL}
            WHERE id = ?3`,
        )
        .bind(agora, autorId, acesso.id),
    );
  }
  for (const turmaId of turmaIds.filter((id) => !atuais.some((a) => a.turma_id === id))) {
    comandos.push(
      db
        .prepare(
          `INSERT INTO turma_usuarios (id, tenant_id, turma_id, usuario_id, created_at, updated_at,
                                       server_version, created_by, updated_by)
           VALUES (?1, ?2, ?3, ?4, ?5, ?5, ${SQL_VERSAO_ATUAL}, ?6, ?6)`,
        )
        .bind(gerarUuidV7(), tenantId, turmaId, usuarioId, agora, autorId),
    );
  }
  return comandos;
}

function obterContexto(c: Ctx) {
  const usuario = c.get('usuario');
  return usuario.tenantId ? { autorId: usuario.id, tenantId: usuario.tenantId } : null;
}

rotasUsuarios.get('/', async (c) => {
  const ctx = obterContexto(c);
  if (!ctx) return responderErro(c, 403, 'sem_permissao');
  const { results } = await c.env.DB.prepare(
    `${SELECT_USUARIO} WHERE u.tenant_id = ?1 AND u.excluido = 0 ORDER BY u.ativo DESC, u.nome COLLATE NOCASE`,
  )
    .bind(ctx.tenantId)
    .all<LinhaUsuario>();
  return c.json({ usuarios: results.map(montarUsuario) });
});

/** Cria professor ou assistente com senha inicial e, opcionalmente, as turmas que ele acessa. */
rotasUsuarios.post('/', async (c) => {
  const ctx = obterContexto(c);
  if (!ctx) return responderErro(c, 403, 'sem_permissao');
  const corpo = await lerCorpoJson(c.req);
  const dados = lerDadosNovoUsuario(corpo);
  const db = c.env.DB;
  const turmaIds = dados ? await lerTurmasDaAcademia(db, ctx.tenantId, corpo?.turma_ids) : undefined;
  if (!dados || !turmaIds) return responderErro(c, 400, 'dados_invalidos');
  if (await existeOutroUsuarioComEmail(db, dados.email, null))
    return responderErro(c, 409, 'email_ja_existe');

  const agora = obterAgoraIso();
  const { id, comando } = await prepararInsercaoUsuario(db, ctx.tenantId, dados, ctx.autorId, agora);
  const acessos = await prepararDefinicaoTurmas(db, ctx.tenantId, id, turmaIds, ctx.autorId, agora);
  await db.batch([prepararIncrementoVersao(db), comando, ...acessos]);
  return c.json({ usuario: await obterUsuario(db, ctx.tenantId, id) }, 201);
});

/**
 * Altera nome, e-mail, tipo e se está ativo. Desativar encerra as sessões na hora.
 * O professor não muda o próprio tipo nem se desativa (a academia ficaria sem professor).
 */
rotasUsuarios.put('/:id', async (c) => {
  const ctx = obterContexto(c);
  const usuarioId = c.req.param('id');
  const db = c.env.DB;
  if (!ctx || !ehUuid(usuarioId) || !(await obterUsuario(db, ctx.tenantId, usuarioId))) {
    return responderErro(c, 404, 'usuario_nao_encontrado');
  }
  const corpo = await lerCorpoJson(c.req);
  const nome = lerTextoObrigatorio(corpo?.nome, 120);
  const email = lerEmail(corpo?.email);
  const tipo = lerTipoUsuarioDoTenant(corpo?.tipo);
  const ativo = lerInteiro(corpo?.ativo, 0, 1);
  if (nome === undefined || email === undefined || tipo === undefined || ativo === undefined) {
    return responderErro(c, 400, 'dados_invalidos');
  }
  if (usuarioId === ctx.autorId && (tipo !== 'professor' || ativo !== 1)) {
    return responderErro(c, 409, 'nao_pode_alterar_o_proprio_acesso');
  }
  if (await existeOutroUsuarioComEmail(db, email, usuarioId)) return responderErro(c, 409, 'email_ja_existe');

  const agora = obterAgoraIso();
  const comandos = [
    db
      .prepare(
        `UPDATE usuarios SET nome = ?1, email = ?2, tipo = ?3, ativo = ?4, updated_at = ?5, updated_by = ?6
          WHERE id = ?7 AND tenant_id = ?8`,
      )
      .bind(nome, email, tipo, ativo, agora, ctx.autorId, usuarioId, ctx.tenantId),
  ];
  if (ativo === 0) comandos.push(prepararRevogacaoSessoes(db, usuarioId, agora));
  await db.batch(comandos);
  return c.json({ usuario: await obterUsuario(db, ctx.tenantId, usuarioId) });
});

/** Define a senha de outro usuário (esqueceu a senha) e encerra as sessões dele. */
rotasUsuarios.post('/:id/senha', async (c) => {
  const ctx = obterContexto(c);
  const usuarioId = c.req.param('id');
  const db = c.env.DB;
  if (!ctx || !ehUuid(usuarioId) || !(await obterUsuario(db, ctx.tenantId, usuarioId))) {
    return responderErro(c, 404, 'usuario_nao_encontrado');
  }
  if (usuarioId === ctx.autorId) return responderErro(c, 409, 'use_a_troca_da_propria_senha');
  const corpo = await lerCorpoJson(c.req);
  if (!ehSenhaValida(corpo?.senha)) return responderErro(c, 400, 'dados_invalidos');
  const agora = obterAgoraIso();
  await db.batch([
    db
      .prepare(
        'UPDATE usuarios SET senha_hash = ?1, updated_at = ?2, updated_by = ?3 WHERE id = ?4 AND tenant_id = ?5',
      )
      .bind(await gerarHashSenha(corpo.senha), agora, ctx.autorId, usuarioId, ctx.tenantId),
    prepararRevogacaoSessoes(db, usuarioId, agora),
  ]);
  return c.body(null, 204);
});

/** Define a lista completa de turmas que o usuário acessa. */
rotasUsuarios.put('/:id/turmas', async (c) => {
  const ctx = obterContexto(c);
  const usuarioId = c.req.param('id');
  const db = c.env.DB;
  if (!ctx || !ehUuid(usuarioId) || !(await obterUsuario(db, ctx.tenantId, usuarioId))) {
    return responderErro(c, 404, 'usuario_nao_encontrado');
  }
  const corpo = await lerCorpoJson(c.req);
  const turmaIds =
    corpo?.turma_ids === undefined ? undefined : await lerTurmasDaAcademia(db, ctx.tenantId, corpo.turma_ids);
  if (!turmaIds) return responderErro(c, 400, 'dados_invalidos');
  const comandos = await prepararDefinicaoTurmas(
    db,
    ctx.tenantId,
    usuarioId,
    turmaIds,
    ctx.autorId,
    obterAgoraIso(),
  );
  if (comandos.length > 0) await db.batch([prepararIncrementoVersao(db), ...comandos]);
  return c.json({ usuario: await obterUsuario(db, ctx.tenantId, usuarioId) });
});
