// Cookie do manifesto: o navegador busca o manifesto do app instalável sem o token de acesso, só
// com cookies. Este cookie diz apenas qual é a academia (assinado, para ninguém trocar por outra)
// e vale só em /api/manifesto. O manifesto mostra nome e ícone, nada sensível.
import { converterBytesEmBase64Url, converterTextoEmBytes } from '../util/codificacao';

export const COOKIE_MANIFESTO = 'cp_manifesto';
export const CAMINHO_COOKIE_MANIFESTO = '/api/manifesto';

async function obterChave(segredo: string): Promise<CryptoKey> {
  // Contexto próprio: a assinatura do manifesto não serve como assinatura de token, e vice-versa.
  return crypto.subtle.importKey(
    'raw',
    converterTextoEmBytes(`manifesto:${segredo}`),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign', 'verify'],
  );
}

async function calcularAssinatura(tenantId: string, segredo: string): Promise<string> {
  const assinatura = await crypto.subtle.sign(
    'HMAC',
    await obterChave(segredo),
    converterTextoEmBytes(tenantId),
  );
  return converterBytesEmBase64Url(new Uint8Array(assinatura));
}

/** Valor do cookie: `<tenantId>.<assinatura>`. */
export async function assinarAcademia(tenantId: string, segredo: string): Promise<string> {
  return `${tenantId}.${await calcularAssinatura(tenantId, segredo)}`;
}

/** Id da academia do cookie, ou null se o valor não foi assinado por este servidor. */
export async function validarAcademia(valor: string | undefined, segredo: string): Promise<string | null> {
  if (!valor) return null;
  const ponto = valor.lastIndexOf('.');
  if (ponto <= 0) return null;
  const tenantId = valor.slice(0, ponto);
  const esperada = await calcularAssinatura(tenantId, segredo);
  const recebida = valor.slice(ponto + 1);
  // Comparação em tempo constante.
  if (esperada.length !== recebida.length) return null;
  let diferenca = 0;
  for (let i = 0; i < esperada.length; i++) diferenca |= esperada.charCodeAt(i) ^ recebida.charCodeAt(i);
  return diferenca === 0 ? tenantId : null;
}
