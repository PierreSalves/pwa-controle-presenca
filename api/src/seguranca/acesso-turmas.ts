import type { UsuarioAutenticado } from '../tipos';

/**
 * O professor administra todas as turmas da academia (inclusive para definir quem acessa cada uma).
 * A assistente só vê e altera as turmas liberadas para ela em turma_usuarios.
 */
export function veTodasAsTurmas(usuario: UsuarioAutenticado): boolean {
  return usuario.tipo === 'professor';
}

/** A turma existe, não foi excluída, é do tenant do usuário e ele pode acessá-la. */
export async function temAcessoATurma(
  db: D1Database,
  usuario: UsuarioAutenticado,
  turmaId: string,
): Promise<boolean> {
  if (!usuario.tenantId) return false;
  const linha = await db
    .prepare(
      `SELECT 1 AS ok
         FROM turmas t
        WHERE t.id = ?1 AND t.tenant_id = ?2 AND t.excluido = 0
          AND (?3 = 1 OR EXISTS (
                SELECT 1 FROM turma_usuarios tu
                 WHERE tu.turma_id = t.id AND tu.usuario_id = ?4 AND tu.tenant_id = ?2 AND tu.excluido = 0))`,
    )
    .bind(turmaId, usuario.tenantId, veTodasAsTurmas(usuario) ? 1 : 0, usuario.id)
    .first();
  return linha !== null;
}
