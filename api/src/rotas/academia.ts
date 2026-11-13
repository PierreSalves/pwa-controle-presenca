// Dados da academia (online): tela 14. Só o professor (editar_tenant).
// O envio do logotipo e a geração dos ícones (R2) ficam numa etapa própria.
import { Hono } from 'hono';
import { autenticar, exigirPermissao } from '../middleware/autenticar';
import type { Contexto } from '../tipos';
import { responderErro } from '../util/erros';
import { obterAgoraIso } from '../util/tempo';
import { lerCorpoJson, lerTextoObrigatorio, lerTextoOpcional } from '../util/validacao';

export const rotasAcademia = new Hono<Contexto>();
rotasAcademia.use('*', autenticar, exigirPermissao('editar_tenant'));

async function obterAcademia(db: D1Database, tenantId: string) {
  return db
    .prepare(
      `SELECT id, nome, nome_curto, cabecalho_impressao, logotipo_key IS NOT NULL AS tem_logotipo, updated_at
         FROM tenants WHERE id = ?1`,
    )
    .bind(tenantId)
    .first();
}

rotasAcademia.get('/', async (c) => {
  const { tenantId } = c.get('usuario');
  if (!tenantId) return responderErro(c, 403, 'sem_permissao');
  return c.json({ academia: await obterAcademia(c.env.DB, tenantId) });
});

/** Nome, nome curto (embaixo do ícone do app instalado, até 15 caracteres) e cabeçalho de impressão. */
rotasAcademia.put('/', async (c) => {
  const { id: autorId, tenantId } = c.get('usuario');
  if (!tenantId) return responderErro(c, 403, 'sem_permissao');
  const corpo = await lerCorpoJson(c.req);
  const nome = lerTextoObrigatorio(corpo?.nome, 120);
  const nomeCurto = lerTextoOpcional(corpo?.nome_curto, 15);
  const cabecalho = lerTextoOpcional(corpo?.cabecalho_impressao, 200);
  if (nome === undefined || nomeCurto === undefined || cabecalho === undefined) {
    return responderErro(c, 400, 'dados_invalidos');
  }
  await c.env.DB.prepare(
    `UPDATE tenants SET nome = ?1, nome_curto = ?2, cabecalho_impressao = ?3, updated_at = ?4, updated_by = ?5
      WHERE id = ?6`,
  )
    .bind(nome, nomeCurto, cabecalho, obterAgoraIso(), autorId, tenantId)
    .run();
  return c.json({ academia: await obterAcademia(c.env.DB, tenantId) });
});
