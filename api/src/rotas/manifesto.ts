// Manifesto do app instalável por academia (docs/arquitetura/README.md, "Logotipo e ícone do app
// por academia"). Sem login (ou sem cookie válido) devolve o manifesto da TghServices; depois do
// login, o nome, o nome curto e os ícones da academia. Público por desenho: só nome e ícone.
import { Hono, type Context } from 'hono';
import { getCookie } from 'hono/cookie';
import { COOKIE_MANIFESTO, validarAcademia } from '../seguranca/cookie_manifesto';
import type { Contexto } from '../tipos';
import { responderErro } from '../util/erros';
import { obterVersaoDaChave } from './academia';

export const rotasManifesto = new Hono<Contexto>();

const COR_FUNDO = '#F5F6F4';

const ICONES_PADRAO = [
  { src: '/icons/Icon-192.png', sizes: '192x192', type: 'image/png' },
  { src: '/icons/Icon-512.png', sizes: '512x512', type: 'image/png' },
  { src: '/icons/Icon-maskable-192.png', sizes: '192x192', type: 'image/png', purpose: 'maskable' },
  { src: '/icons/Icon-maskable-512.png', sizes: '512x512', type: 'image/png', purpose: 'maskable' },
];

interface AcademiaDoManifesto {
  nome: string;
  nome_curto: string | null;
  icone_192_key: string | null;
  icone_512_key: string | null;
}

async function obterAcademiaDoCookie(c: Context<Contexto>) {
  const tenantId = await validarAcademia(getCookie(c, COOKIE_MANIFESTO), c.env.JWT_SEGREDO);
  if (!tenantId) return null;
  return c.env.DB.prepare(
    `SELECT nome, nome_curto, icone_192_key, icone_512_key FROM tenants
      WHERE id = ?1 AND ativo = 1 AND excluido = 0`,
  )
    .bind(tenantId)
    .first<AcademiaDoManifesto>();
}

const MAXIMO_NOME_CURTO_AUTOMATICO = 12;

/**
 * Nome curto embaixo do ícone: o cadastrado ou, sem ele, as primeiras palavras do nome que cabem
 * em 12 letras (sem cortar palavra no meio; só a primeira palavra longa demais é cortada).
 */
export function calcularNomeCurto(academia: Pick<AcademiaDoManifesto, 'nome' | 'nome_curto'>): string {
  if (academia.nome_curto) return academia.nome_curto;
  const palavras = academia.nome.trim().split(/\s+/);
  let nome = palavras[0]?.slice(0, MAXIMO_NOME_CURTO_AUTOMATICO) ?? '';
  for (const palavra of palavras.slice(1)) {
    if (`${nome} ${palavra}`.length > MAXIMO_NOME_CURTO_AUTOMATICO) break;
    nome = `${nome} ${palavra}`;
  }
  return nome;
}

rotasManifesto.get('/', async (c) => {
  const academia = await obterAcademiaDoCookie(c);
  const versao = obterVersaoDaChave(academia?.icone_512_key ?? null);
  // Os ícones gerados no app já têm a margem do ícone redondo: servem para "any" e "maskable".
  const icones =
    academia && versao
      ? [192, 512].map((tamanho) => ({
          src: `/api/manifesto/icone/${tamanho}?v=${versao}`,
          sizes: `${tamanho}x${tamanho}`,
          type: 'image/png',
          purpose: 'any maskable',
        }))
      : ICONES_PADRAO;
  const manifesto = {
    id: '/',
    name: academia ? academia.nome : 'Controle de presença',
    short_name: academia ? calcularNomeCurto(academia) : 'Presença',
    description: 'Controle de presença - TghServices',
    start_url: '/',
    scope: '/',
    display: 'standalone',
    orientation: 'portrait-primary',
    background_color: COR_FUNDO,
    theme_color: COR_FUNDO,
    lang: 'pt-BR',
    prefer_related_applications: false,
    icons: icones,
  };
  return new Response(JSON.stringify(manifesto), {
    headers: {
      'Content-Type': 'application/manifest+json; charset=utf-8',
      'Cache-Control': 'private, no-cache',
    },
  });
});

/** Ícone da academia do cookie (192 ou 512 px). */
rotasManifesto.get('/icone/:tamanho', async (c) => {
  const tamanho = c.req.param('tamanho');
  const academia = await obterAcademiaDoCookie(c);
  const chave =
    tamanho === '192' ? academia?.icone_192_key : tamanho === '512' ? academia?.icone_512_key : null;
  const objeto = chave ? await c.env.ARQUIVOS.get(chave) : null;
  if (!objeto) return responderErro(c, 404, 'icone_nao_encontrado');
  return new Response(objeto.body, {
    headers: {
      'Content-Type': 'image/png',
      // A versão vai no endereço (?v=): um logotipo novo é outro endereço.
      'Cache-Control': 'private, max-age=31536000, immutable',
      'X-Content-Type-Options': 'nosniff',
    },
  });
});
