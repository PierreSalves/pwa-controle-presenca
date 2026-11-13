import { Hono } from 'hono';
import { autenticar } from '../middleware/autenticar';
import { ehSenhaValida, gerarHashSenha, validarSenha } from '../seguranca/senha';
import { obterVersaoDaChave } from './academia';
import type { Contexto } from '../tipos';
import { responderErro } from '../util/erros';
import { obterAgoraIso } from '../util/tempo';

export const rotasEu = new Hono<Contexto>();

rotasEu.use('*', autenticar);

/** Dados do usuário logado, da academia e das turmas a que ele tem acesso. */
rotasEu.get('/', async (c) => {
  const { id, tenantId } = c.get('usuario');
  const usuario = await c.env.DB.prepare(
    'SELECT id, nome, email, tipo, tenant_id FROM usuarios WHERE id = ?1',
  )
    .bind(id)
    .first();
  const tenant = tenantId
    ? await c.env.DB.prepare('SELECT id, nome, cabecalho_impressao, icone_512_key FROM tenants WHERE id = ?1')
        .bind(tenantId)
        .first<{
          id: string;
          nome: string;
          cabecalho_impressao: string | null;
          icone_512_key: string | null;
        }>()
    : null;
  const turmas = tenantId
    ? (
        await c.env.DB.prepare(
          `SELECT t.id, t.nome
             FROM turma_usuarios tu
             JOIN turmas t ON t.id = tu.turma_id
            WHERE tu.usuario_id = ?1 AND tu.tenant_id = ?2 AND tu.excluido = 0 AND t.excluido = 0
            ORDER BY t.nome`,
        )
          .bind(id, tenantId)
          .all()
      ).results
    : [];
  // logotipo_versao muda a cada envio: o app baixa o ícone de novo só quando ela muda.
  const academia = tenant
    ? {
        id: tenant.id,
        nome: tenant.nome,
        cabecalho_impressao: tenant.cabecalho_impressao,
        logotipo_versao: obterVersaoDaChave(tenant.icone_512_key),
      }
    : null;
  return c.json({ usuario, tenant: academia, turmas });
});

const COLUNAS_DO_LOGOTIPO: Record<string, string> = {
  original: 'logotipo_key',
  '192': 'icone_192_key',
  '512': 'icone_512_key',
};

/** Logotipo da própria academia (qualquer usuário dela): `original`, `192` ou `512`. */
rotasEu.get('/logotipo/:tamanho', async (c) => {
  const { tenantId } = c.get('usuario');
  const coluna = COLUNAS_DO_LOGOTIPO[c.req.param('tamanho')];
  if (!tenantId || !coluna) return responderErro(c, 404, 'logotipo_nao_encontrado');
  const linha = await c.env.DB.prepare(`SELECT ${coluna} AS chave FROM tenants WHERE id = ?1`)
    .bind(tenantId)
    .first<{ chave: string | null }>();
  const objeto = linha?.chave ? await c.env.ARQUIVOS.get(linha.chave) : null;
  if (!objeto) return responderErro(c, 404, 'logotipo_nao_encontrado');
  return new Response(objeto.body, {
    headers: {
      'Content-Type': objeto.httpMetadata?.contentType ?? 'application/octet-stream',
      'Cache-Control': 'private, max-age=31536000, immutable',
      'X-Content-Type-Options': 'nosniff',
    },
  });
});

/** Troca a própria senha. Encerra as outras sessões do usuário. */
rotasEu.post('/senha', async (c) => {
  const { id, sessaoId } = c.get('usuario');
  const corpo = await c.req.json().catch(() => null);
  if (typeof corpo?.senha_atual !== 'string' || !ehSenhaValida(corpo?.senha_nova)) {
    return responderErro(c, 400, 'dados_invalidos');
  }
  const atual = await c.env.DB.prepare('SELECT senha_hash FROM usuarios WHERE id = ?1')
    .bind(id)
    .first<{ senha_hash: string }>();
  if (!atual || !(await validarSenha(corpo.senha_atual, atual.senha_hash))) {
    return responderErro(c, 400, 'senha_atual_incorreta');
  }
  const agora = obterAgoraIso();
  await c.env.DB.batch([
    c.env.DB.prepare(
      'UPDATE usuarios SET senha_hash = ?1, updated_at = ?2, updated_by = ?3 WHERE id = ?3',
    ).bind(await gerarHashSenha(corpo.senha_nova), agora, id),
    c.env.DB.prepare(
      'UPDATE sessoes SET revogado_em = ?1 WHERE usuario_id = ?2 AND id <> ?3 AND revogado_em IS NULL',
    ).bind(agora, id, sessaoId),
  ]);
  return c.body(null, 204);
});
