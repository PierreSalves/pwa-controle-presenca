import type { Context } from 'hono';
import type { ContentfulStatusCode } from 'hono/utils/http-status';

/** Resposta de erro padrão da API: { erro: '<codigo>' }. */
export function responderErro(c: Context, status: ContentfulStatusCode, codigo: string) {
  return c.json({ erro: codigo }, status);
}
