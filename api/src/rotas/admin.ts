// Administrador do sistema (online): tela 13. Só o superadmin (gerenciar_tenants).
// Cadastra academias, os primeiros professores de cada uma e faz a carga inicial dos alunos.
import { Hono, type Context } from 'hono';
import { autenticar, exigirPermissao } from '../middleware/autenticar';
import { ehSenhaValida, gerarHashSenha } from '../seguranca/senha';
import { importarAlunos } from '../servicos/importacao-alunos';
import {
  existeOutroUsuarioComEmail,
  lerDadosNovoUsuario,
  prepararInsercaoUsuario,
  prepararRevogacaoSessoes,
} from '../servicos/usuarios';
import type { Contexto } from '../tipos';
import { responderErro } from '../util/erros';
import { gerarUuidV7 } from '../util/ids';
import { obterAgoraIso } from '../util/tempo';
import { ehUuid, lerCorpoJson, lerInteiro, lerTextoObrigatorio, lerTextoOpcional } from '../util/validacao';

export const rotasAdmin = new Hono<Contexto>();
rotasAdmin.use('*', autenticar, exigirPermissao('gerenciar_tenants'));

type Ctx = Context<Contexto>;

const SELECT_ACADEMIA = `
  SELECT t.id, t.nome, t.nome_curto, t.cabecalho_impressao, t.ativo, t.created_at,
         (SELECT COUNT(*) FROM usuarios u WHERE u.tenant_id = t.id AND u.excluido = 0 AND u.ativo = 1) AS usuarios,
         (SELECT COUNT(*) FROM alunos a WHERE a.tenant_id = t.id AND a.excluido = 0) AS alunos,
         (SELECT COUNT(*) FROM turmas tu WHERE tu.tenant_id = t.id AND tu.excluido = 0) AS turmas
    FROM tenants t`;

async function obterAcademia(db: D1Database, tenantId: string) {
  return db.prepare(`${SELECT_ACADEMIA} WHERE t.id = ?1 AND t.excluido = 0`).bind(tenantId).first();
}

async function obterAcademiaDaRota(c: Ctx): Promise<string | null> {
  const id = c.req.param('id');
  if (!id || !ehUuid(id)) return null;
  return (await obterAcademia(c.env.DB, id)) ? id : null;
}

function lerDadosAcademia(corpo: Record<string, unknown> | null) {
  const nome = lerTextoObrigatorio(corpo?.nome, 120);
  const nomeCurto = lerTextoOpcional(corpo?.nome_curto, 15);
  const cabecalho = lerTextoOpcional(corpo?.cabecalho_impressao, 200);
  if (nome === undefined || nomeCurto === undefined || cabecalho === undefined) return null;
  return { nome, nome_curto: nomeCurto, cabecalho_impressao: cabecalho };
}

rotasAdmin.get('/academias', async (c) => {
  const { results } = await c.env.DB.prepare(
    `${SELECT_ACADEMIA} WHERE t.excluido = 0 ORDER BY t.nome COLLATE NOCASE`,
  ).all();
  return c.json({ academias: results });
});

/** Cria a academia e o primeiro professor dela numa gravação só. */
rotasAdmin.post('/academias', async (c) => {
  const corpo = await lerCorpoJson(c.req);
  const dados = lerDadosAcademia(corpo);
  const professor = lerDadosNovoUsuario(
    (typeof corpo?.professor === 'object' ? corpo.professor : null) as Record<string, unknown> | null,
    'professor',
  );
  if (!dados || !professor) return responderErro(c, 400, 'dados_invalidos');
  const db = c.env.DB;
  if (await existeOutroUsuarioComEmail(db, professor.email, null))
    return responderErro(c, 409, 'email_ja_existe');

  const autorId = c.get('usuario').id;
  const tenantId = gerarUuidV7();
  const agora = obterAgoraIso();
  const { comando } = await prepararInsercaoUsuario(db, tenantId, professor, autorId, agora);
  await db.batch([
    db
      .prepare(
        `INSERT INTO tenants (id, nome, nome_curto, cabecalho_impressao, created_at, updated_at, created_by, updated_by)
         VALUES (?1, ?2, ?3, ?4, ?5, ?5, ?6, ?6)`,
      )
      .bind(tenantId, dados.nome, dados.nome_curto, dados.cabecalho_impressao, agora, autorId),
    comando,
  ]);
  return c.json({ academia: await obterAcademia(db, tenantId) }, 201);
});

/** Altera os dados da academia. Desativar bloqueia o acesso de todos os usuários dela na hora. */
rotasAdmin.put('/academias/:id', async (c) => {
  const tenantId = await obterAcademiaDaRota(c);
  if (!tenantId) return responderErro(c, 404, 'academia_nao_encontrada');
  const corpo = await lerCorpoJson(c.req);
  const dados = lerDadosAcademia(corpo);
  const ativo = lerInteiro(corpo?.ativo, 0, 1);
  if (!dados || ativo === undefined) return responderErro(c, 400, 'dados_invalidos');
  const db = c.env.DB;
  const agora = obterAgoraIso();
  const comandos = [
    db
      .prepare(
        `UPDATE tenants SET nome = ?1, nome_curto = ?2, cabecalho_impressao = ?3, ativo = ?4, updated_at = ?5,
                updated_by = ?6 WHERE id = ?7`,
      )
      .bind(
        dados.nome,
        dados.nome_curto,
        dados.cabecalho_impressao,
        ativo,
        agora,
        c.get('usuario').id,
        tenantId,
      ),
  ];
  if (ativo === 0) {
    comandos.push(
      db
        .prepare(
          `UPDATE sessoes SET revogado_em = ?1
            WHERE revogado_em IS NULL AND usuario_id IN (SELECT id FROM usuarios WHERE tenant_id = ?2)`,
        )
        .bind(agora, tenantId),
    );
  }
  await db.batch(comandos);
  return c.json({ academia: await obterAcademia(db, tenantId) });
});

/** Professores da academia (para o admin conferir quem já foi criado). */
rotasAdmin.get('/academias/:id/professores', async (c) => {
  const tenantId = await obterAcademiaDaRota(c);
  if (!tenantId) return responderErro(c, 404, 'academia_nao_encontrada');
  const { results } = await c.env.DB.prepare(
    `SELECT id, nome, email, ativo, ultimo_login_em FROM usuarios
      WHERE tenant_id = ?1 AND tipo = 'professor' AND excluido = 0 ORDER BY nome COLLATE NOCASE`,
  )
    .bind(tenantId)
    .all();
  return c.json({ professores: results });
});

/** Cria mais um professor na academia (os seguintes podem ser criados pelo próprio professor). */
rotasAdmin.post('/academias/:id/professores', async (c) => {
  const tenantId = await obterAcademiaDaRota(c);
  if (!tenantId) return responderErro(c, 404, 'academia_nao_encontrada');
  const dados = lerDadosNovoUsuario(await lerCorpoJson(c.req), 'professor');
  if (!dados) return responderErro(c, 400, 'dados_invalidos');
  const db = c.env.DB;
  if (await existeOutroUsuarioComEmail(db, dados.email, null))
    return responderErro(c, 409, 'email_ja_existe');
  const { id, comando } = await prepararInsercaoUsuario(
    db,
    tenantId,
    dados,
    c.get('usuario').id,
    obterAgoraIso(),
  );
  await comando.run();
  return c.json({ professor: { id, nome: dados.nome, email: dados.email } }, 201);
});

/** Desativa um professor da academia (ex.: criado com o e-mail errado). */
rotasAdmin.delete('/academias/:id/professores/:usuarioId', async (c) => {
  const tenantId = await obterAcademiaDaRota(c);
  const usuarioId = c.req.param('usuarioId');
  if (!tenantId || !ehUuid(usuarioId)) return responderErro(c, 404, 'usuario_nao_encontrado');
  const db = c.env.DB;
  const agora = obterAgoraIso();
  const [resultado] = await db.batch([
    db
      .prepare(
        `UPDATE usuarios SET ativo = 0, updated_at = ?1, updated_by = ?2
          WHERE id = ?3 AND tenant_id = ?4 AND tipo = 'professor' AND excluido = 0`,
      )
      .bind(agora, c.get('usuario').id, usuarioId, tenantId),
    prepararRevogacaoSessoes(db, usuarioId, agora),
  ]);
  if (!resultado || resultado.meta.changes === 0) return responderErro(c, 404, 'usuario_nao_encontrado');
  return c.body(null, 204);
});

/**
 * Define a senha de um professor ativo da academia (esqueceu a senha) e encerra as sessões dele.
 * Atende o professor autônomo, que não tem outro professor para redefinir a senha dele.
 */
rotasAdmin.post('/academias/:id/professores/:usuarioId/senha', async (c) => {
  const tenantId = await obterAcademiaDaRota(c);
  const usuarioId = c.req.param('usuarioId');
  if (!tenantId || !ehUuid(usuarioId)) return responderErro(c, 404, 'usuario_nao_encontrado');
  const db = c.env.DB;
  const professor = await db
    .prepare(
      `SELECT id FROM usuarios
        WHERE id = ?1 AND tenant_id = ?2 AND tipo = 'professor' AND ativo = 1 AND excluido = 0`,
    )
    .bind(usuarioId, tenantId)
    .first();
  if (!professor) return responderErro(c, 404, 'usuario_nao_encontrado');
  const corpo = await lerCorpoJson(c.req);
  if (!ehSenhaValida(corpo?.senha)) return responderErro(c, 400, 'dados_invalidos');
  const agora = obterAgoraIso();
  await db.batch([
    db
      .prepare(
        'UPDATE usuarios SET senha_hash = ?1, updated_at = ?2, updated_by = ?3 WHERE id = ?4 AND tenant_id = ?5',
      )
      .bind(await gerarHashSenha(corpo.senha), agora, c.get('usuario').id, usuarioId, tenantId),
    prepararRevogacaoSessoes(db, usuarioId, agora),
  ]);
  return c.body(null, 204);
});

/** Carga inicial dos alunos da academia (mesmas regras de POST /api/alunos/importacao). */
rotasAdmin.post('/academias/:id/alunos/importacao', async (c) => {
  const tenantId = await obterAcademiaDaRota(c);
  if (!tenantId) return responderErro(c, 404, 'academia_nao_encontrada');
  const resultado = await importarAlunos(c.env.DB, tenantId, c.get('usuario').id, await lerCorpoJson(c.req));
  if (resultado.tipo === 'dados_invalidos') return responderErro(c, 400, 'dados_invalidos');
  if (resultado.tipo === 'relatorio') return c.json({ relatorio: resultado.relatorio, importados: 0 });
  return c.json({ relatorio: resultado.relatorio, importados: resultado.importados }, 201);
});
