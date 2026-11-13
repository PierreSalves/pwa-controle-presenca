import { Hono, type Context } from 'hono';
import { deleteCookie, getCookie, setCookie } from 'hono/cookie';
import { ehTipoUsuario } from '../seguranca/permissoes';
import { gerarHashSenha, validarSenha } from '../seguranca/senha';
import {
  calcularHashToken,
  DURACAO_SESSAO_SEGUNDOS,
  DURACAO_TOKEN_ACESSO_SEGUNDOS,
  gerarTokenAcesso,
  gerarTokenRenovacao,
} from '../seguranca/tokens';
import type { Contexto } from '../tipos';
import { responderErro } from '../util/erros';
import { gerarUuidV7 } from '../util/ids';
import { obterAgoraIso, somarSegundos } from '../util/tempo';
import { assinarAcademia, CAMINHO_COOKIE_MANIFESTO, COOKIE_MANIFESTO } from '../seguranca/cookie_manifesto';

export const COOKIE_RENOVACAO = 'cp_renovacao';
const CAMINHO_COOKIE = '/api/autenticacao';

interface UsuarioLogin {
  id: string;
  tenant_id: string | null;
  tipo: string;
  nome: string;
  email: string;
  senha_hash: string;
  usuario_ativo: number;
  tenant_ativo: number | null;
}

// Hash de uma senha qualquer, usado quando o e-mail não existe, para o tempo de resposta não revelar isso.
let hashFicticio: Promise<string> | undefined;
function obterHashFicticio(): Promise<string> {
  hashFicticio ??= gerarHashSenha('senha-ficticia-para-igualar-tempo');
  return hashFicticio;
}

/** Cookie do manifesto do app instalável (só a academia, assinado); sem academia, apaga. */
async function definirCookieManifesto(c: Context, tenantId: string | null, segredo: string) {
  if (!tenantId) {
    deleteCookie(c, COOKIE_MANIFESTO, { path: CAMINHO_COOKIE_MANIFESTO });
    return;
  }
  setCookie(c, COOKIE_MANIFESTO, await assinarAcademia(tenantId, segredo), {
    httpOnly: true,
    secure: true,
    sameSite: 'Strict',
    path: CAMINHO_COOKIE_MANIFESTO,
    maxAge: DURACAO_SESSAO_SEGUNDOS,
  });
}

function definirCookieRenovacao(c: Context, token: string) {
  setCookie(c, COOKIE_RENOVACAO, token, {
    httpOnly: true,
    secure: true,
    sameSite: 'Strict',
    path: CAMINHO_COOKIE,
    maxAge: DURACAO_SESSAO_SEGUNDOS,
  });
}

async function emitirTokenAcesso(
  segredo: string,
  usuario: { id: string; tenant_id: string | null; tipo: string },
  sessaoId: string,
) {
  if (!ehTipoUsuario(usuario.tipo)) throw new Error('tipo de usuário inválido');
  const token = await gerarTokenAcesso(
    { sub: usuario.id, tenant: usuario.tenant_id, tipo: usuario.tipo, sessao: sessaoId },
    segredo,
  );
  return {
    token_acesso: token,
    expira_em: obterAgoraIso(somarSegundos(new Date(), DURACAO_TOKEN_ACESSO_SEGUNDOS)),
  };
}

export const rotasAutenticacao = new Hono<Contexto>();

rotasAutenticacao.post('/entrar', async (c) => {
  const corpo = await c.req.json().catch(() => null);
  const email = typeof corpo?.email === 'string' ? corpo.email.trim().toLowerCase() : '';
  const senha = typeof corpo?.senha === 'string' ? corpo.senha : '';
  if (!email || !senha) return responderErro(c, 400, 'dados_invalidos');

  const usuario = await c.env.DB.prepare(
    `SELECT u.id, u.tenant_id, u.tipo, u.nome, u.email, u.senha_hash,
            u.ativo AS usuario_ativo, t.ativo AS tenant_ativo
       FROM usuarios u
       LEFT JOIN tenants t ON t.id = u.tenant_id AND t.excluido = 0
      WHERE u.email = ?1 AND u.excluido = 0`,
  )
    .bind(email)
    .first<UsuarioLogin>();

  const senhaConfere = await validarSenha(senha, usuario?.senha_hash ?? (await obterHashFicticio()));
  const tenantOk = usuario?.tenant_id === null || usuario?.tenant_ativo === 1;
  if (!usuario || !senhaConfere || usuario.usuario_ativo !== 1 || !tenantOk) {
    return responderErro(c, 401, 'credenciais_invalidas');
  }

  const agora = new Date();
  const sessaoId = gerarUuidV7();
  const tokenRenovacao = gerarTokenRenovacao();
  await c.env.DB.batch([
    c.env.DB.prepare(
      'INSERT INTO sessoes (id, usuario_id, token_hash, expira_em, created_at) VALUES (?1, ?2, ?3, ?4, ?5)',
    ).bind(
      sessaoId,
      usuario.id,
      await calcularHashToken(tokenRenovacao),
      obterAgoraIso(somarSegundos(agora, DURACAO_SESSAO_SEGUNDOS)),
      obterAgoraIso(agora),
    ),
    c.env.DB.prepare('UPDATE usuarios SET ultimo_login_em = ?1 WHERE id = ?2').bind(
      obterAgoraIso(agora),
      usuario.id,
    ),
  ]);

  definirCookieRenovacao(c, tokenRenovacao);
  await definirCookieManifesto(c, usuario.tenant_id, c.env.JWT_SEGREDO);
  return c.json({
    ...(await emitirTokenAcesso(c.env.JWT_SEGREDO, usuario, sessaoId)),
    usuario: {
      id: usuario.id,
      nome: usuario.nome,
      email: usuario.email,
      tipo: usuario.tipo,
      tenant_id: usuario.tenant_id,
    },
  });
});

rotasAutenticacao.post('/renovar', async (c) => {
  const token = getCookie(c, COOKIE_RENOVACAO);
  if (!token) return responderErro(c, 401, 'sessao_encerrada');

  const agora = new Date();
  const sessao = await c.env.DB.prepare(
    `SELECT s.id AS sessao_id, u.id, u.tenant_id, u.tipo
       FROM sessoes s
       JOIN usuarios u ON u.id = s.usuario_id
       LEFT JOIN tenants t ON t.id = u.tenant_id
      WHERE s.token_hash = ?1 AND s.revogado_em IS NULL AND s.expira_em > ?2
        AND u.ativo = 1 AND u.excluido = 0
        AND (u.tenant_id IS NULL OR (t.ativo = 1 AND t.excluido = 0))`,
  )
    .bind(await calcularHashToken(token), obterAgoraIso(agora))
    .first<{ sessao_id: string; id: string; tenant_id: string | null; tipo: string }>();
  if (!sessao) {
    deleteCookie(c, COOKIE_RENOVACAO, { path: CAMINHO_COOKIE });
    deleteCookie(c, COOKIE_MANIFESTO, { path: CAMINHO_COOKIE_MANIFESTO });
    return responderErro(c, 401, 'sessao_encerrada');
  }

  // Rotação: cada renovação troca o token de renovação e estende a sessão.
  const novoToken = gerarTokenRenovacao();
  await c.env.DB.prepare(
    'UPDATE sessoes SET token_hash = ?1, expira_em = ?2, ultimo_uso_em = ?3 WHERE id = ?4',
  )
    .bind(
      await calcularHashToken(novoToken),
      obterAgoraIso(somarSegundos(agora, DURACAO_SESSAO_SEGUNDOS)),
      obterAgoraIso(agora),
      sessao.sessao_id,
    )
    .run();

  definirCookieRenovacao(c, novoToken);
  await definirCookieManifesto(c, sessao.tenant_id, c.env.JWT_SEGREDO);
  return c.json(await emitirTokenAcesso(c.env.JWT_SEGREDO, sessao, sessao.sessao_id));
});

rotasAutenticacao.post('/sair', async (c) => {
  const token = getCookie(c, COOKIE_RENOVACAO);
  if (token) {
    await c.env.DB.prepare(
      'UPDATE sessoes SET revogado_em = ?1 WHERE token_hash = ?2 AND revogado_em IS NULL',
    )
      .bind(obterAgoraIso(), await calcularHashToken(token))
      .run();
  }
  deleteCookie(c, COOKIE_RENOVACAO, { path: CAMINHO_COOKIE });
  deleteCookie(c, COOKIE_MANIFESTO, { path: CAMINHO_COOKIE_MANIFESTO });
  return c.body(null, 204);
});
