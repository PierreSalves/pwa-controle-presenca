import { createMiddleware } from 'hono/factory';
import { ehTipoUsuario, podeExecutar, type Acao } from '../seguranca/permissoes';
import { validarTokenAcesso } from '../seguranca/tokens';
import type { Contexto } from '../tipos';
import { responderErro } from '../util/erros';

/**
 * Exige um token de acesso válido (cabeçalho Authorization: Bearer).
 * Também confere no banco que a sessão não foi revogada e que o usuário e o tenant seguem ativos,
 * para que a revogação valha na hora.
 */
export const autenticar = createMiddleware<Contexto>(async (c, next) => {
  const cabecalho = c.req.header('Authorization') ?? '';
  const [esquema, token] = cabecalho.split(' ');
  if (esquema !== 'Bearer' || !token) return responderErro(c, 401, 'nao_autenticado');

  const dados = await validarTokenAcesso(token, c.env.JWT_SEGREDO);
  if (!dados) return responderErro(c, 401, 'token_invalido');

  const ativo = await c.env.DB.prepare(
    `SELECT u.tipo, u.tenant_id
       FROM sessoes s
       JOIN usuarios u ON u.id = s.usuario_id
       LEFT JOIN tenants t ON t.id = u.tenant_id
      WHERE s.id = ?1 AND s.usuario_id = ?2 AND s.revogado_em IS NULL
        AND u.ativo = 1 AND u.excluido = 0
        AND (u.tenant_id IS NULL OR (t.ativo = 1 AND t.excluido = 0))`,
  )
    .bind(dados.sessao, dados.sub)
    .first<{ tipo: string; tenant_id: string | null }>();
  if (!ativo || !ehTipoUsuario(ativo.tipo)) return responderErro(c, 401, 'sessao_encerrada');

  c.set('usuario', { id: dados.sub, tenantId: ativo.tenant_id, tipo: ativo.tipo, sessaoId: dados.sessao });
  await next();
});

/** Exige que o usuário autenticado possa executar a ação (matriz de permissões). */
export function exigirPermissao(acao: Acao) {
  return createMiddleware<Contexto>(async (c, next) => {
    if (!podeExecutar(c.get('usuario').tipo, acao)) return responderErro(c, 403, 'sem_permissao');
    await next();
  });
}
