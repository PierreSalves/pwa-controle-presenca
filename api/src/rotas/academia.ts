// Dados da academia (online): tela 14. Só o professor (editar_tenant).
// Logotipo: o app gera os ícones 192 e 512 px (com margem para o ícone redondo) e envia tudo junto;
// a API confere o tipo pelos bytes e guarda no R2 com uma versão nova na chave (sem cache velho).
import { Hono } from 'hono';
import { autenticar, exigirPermissao } from '../middleware/autenticar';
import type { Contexto } from '../tipos';
import { responderErro } from '../util/erros';
import { detectarTipoImagem, ehIconeValido } from '../regras/imagens';
import { converterBase64EmBytes } from '../util/codificacao';
import { gerarUuidV7 } from '../util/ids';
import { obterAgoraIso } from '../util/tempo';
import { lerCorpoJson, lerTextoObrigatorio, lerTextoOpcional } from '../util/validacao';

export const rotasAcademia = new Hono<Contexto>();
rotasAcademia.use('*', autenticar, exigirPermissao('editar_tenant'));

async function obterAcademia(db: D1Database, tenantId: string) {
  const academia = await db
    .prepare(
      `SELECT id, nome, nome_curto, cabecalho_impressao, logotipo_key IS NOT NULL AS tem_logotipo,
              icone_512_key, updated_at
         FROM tenants WHERE id = ?1`,
    )
    .bind(tenantId)
    .first<Record<string, unknown> & { icone_512_key: string | null }>();
  if (!academia) return null;
  const { icone_512_key: chave, ...resto } = academia;
  return { ...resto, logotipo_versao: obterVersaoDaChave(chave) };
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

export const MAXIMO_LOGOTIPO = 1024 * 1024;
const MAXIMO_ICONE = 512 * 1024;

type ChavesDoLogotipo = {
  logotipo_key: string | null;
  icone_192_key: string | null;
  icone_512_key: string | null;
};

/** A versão é a pasta da chave: academias/<tenant>/<versão>/arquivo. */
export function obterVersaoDaChave(chave: string | null): string | null {
  return chave?.split('/')[2] ?? null;
}

/** Tamanho, em bytes, do conteúdo em base64. */
function calcularTamanhoBase64(base64: string): number {
  return Math.floor((base64.length * 3) / 4);
}

function lerImagem(valor: unknown, maximo: number): Uint8Array | null {
  if (typeof valor !== 'string' || calcularTamanhoBase64(valor) > maximo + 3) return null;
  try {
    const bytes = converterBase64EmBytes(valor);
    return bytes.length > 0 && bytes.length <= maximo ? bytes : null;
  } catch {
    return null;
  }
}

async function obterChavesDoLogotipo(db: D1Database, tenantId: string) {
  return db
    .prepare('SELECT logotipo_key, icone_192_key, icone_512_key FROM tenants WHERE id = ?1')
    .bind(tenantId)
    .first<ChavesDoLogotipo>();
}

async function apagarArquivos(arquivos: R2Bucket, chaves: ChavesDoLogotipo | null) {
  const existentes = [chaves?.logotipo_key, chaves?.icone_192_key, chaves?.icone_512_key].filter(
    (c): c is string => typeof c === 'string',
  );
  if (existentes.length > 0) await arquivos.delete(existentes);
}

/**
 * Envia o logotipo (PNG ou JPG até 1 MB) com os ícones 192 e 512 px gerados pelo app.
 * Corpo: `{ logotipo, icone_192, icone_512 }` em base64.
 */
rotasAcademia.put('/logotipo', async (c) => {
  const { id: autorId, tenantId } = c.get('usuario');
  if (!tenantId) return responderErro(c, 403, 'sem_permissao');
  const corpo = await lerCorpoJson(c.req);
  if (typeof corpo?.logotipo === 'string' && calcularTamanhoBase64(corpo.logotipo) > MAXIMO_LOGOTIPO + 3) {
    return responderErro(c, 413, 'logotipo_grande_demais');
  }
  const logotipo = lerImagem(corpo?.logotipo, MAXIMO_LOGOTIPO);
  const icone192 = lerImagem(corpo?.icone_192, MAXIMO_ICONE);
  const icone512 = lerImagem(corpo?.icone_512, MAXIMO_ICONE);
  const tipo = logotipo ? detectarTipoImagem(logotipo) : null;
  if (
    !logotipo ||
    !tipo ||
    !icone192 ||
    !icone512 ||
    !ehIconeValido(icone192, 192) ||
    !ehIconeValido(icone512, 512)
  ) {
    return responderErro(c, 400, 'imagem_invalida');
  }
  const db = c.env.DB;
  const anterior = await obterChavesDoLogotipo(db, tenantId);
  const pasta = `academias/${tenantId}/${gerarUuidV7()}`;
  const chaves = {
    logotipo: `${pasta}/logotipo.${tipo === 'png' ? 'png' : 'jpg'}`,
    icone192: `${pasta}/icone-192.png`,
    icone512: `${pasta}/icone-512.png`,
  };
  await Promise.all([
    c.env.ARQUIVOS.put(chaves.logotipo, logotipo, { httpMetadata: { contentType: `image/${tipo}` } }),
    c.env.ARQUIVOS.put(chaves.icone192, icone192, { httpMetadata: { contentType: 'image/png' } }),
    c.env.ARQUIVOS.put(chaves.icone512, icone512, { httpMetadata: { contentType: 'image/png' } }),
  ]);
  await db
    .prepare(
      `UPDATE tenants SET logotipo_key = ?1, icone_192_key = ?2, icone_512_key = ?3, updated_at = ?4, updated_by = ?5
        WHERE id = ?6`,
    )
    .bind(chaves.logotipo, chaves.icone192, chaves.icone512, obterAgoraIso(), autorId, tenantId)
    .run();
  await apagarArquivos(c.env.ARQUIVOS, anterior);
  return c.json({ academia: await obterAcademia(db, tenantId) });
});

/** Remove o logotipo: o app volta a mostrar o nome da academia e o ícone da TghServices. */
rotasAcademia.delete('/logotipo', async (c) => {
  const { id: autorId, tenantId } = c.get('usuario');
  if (!tenantId) return responderErro(c, 403, 'sem_permissao');
  const db = c.env.DB;
  const anterior = await obterChavesDoLogotipo(db, tenantId);
  await db
    .prepare(
      `UPDATE tenants SET logotipo_key = NULL, icone_192_key = NULL, icone_512_key = NULL, updated_at = ?1, updated_by = ?2
        WHERE id = ?3`,
    )
    .bind(obterAgoraIso(), autorId, tenantId)
    .run();
  await apagarArquivos(c.env.ARQUIVOS, anterior);
  return c.json({ academia: await obterAcademia(db, tenantId) });
});
