import { sign, verify } from 'hono/jwt';
import { converterBytesEmBase64Url, converterTextoEmBytes, gerarBytesAleatorios } from '../util/codificacao';
import type { TipoUsuario } from './permissoes';

export const DURACAO_TOKEN_ACESSO_SEGUNDOS = 15 * 60;
export const DURACAO_SESSAO_SEGUNDOS = 30 * 24 * 60 * 60;

export interface DadosTokenAcesso {
  sub: string;
  tenant: string | null;
  tipo: TipoUsuario;
  sessao: string;
}

export async function gerarTokenAcesso(
  dados: DadosTokenAcesso,
  segredo: string,
  agora = Date.now(),
): Promise<string> {
  const emitidoEm = Math.floor(agora / 1000);
  return sign({ ...dados, iat: emitidoEm, exp: emitidoEm + DURACAO_TOKEN_ACESSO_SEGUNDOS }, segredo, 'HS256');
}

/** Devolve os dados do token ou null se for inválido ou estiver expirado. */
export async function validarTokenAcesso(token: string, segredo: string): Promise<DadosTokenAcesso | null> {
  try {
    const carga = await verify(token, segredo, 'HS256');
    if (typeof carga.sub !== 'string' || typeof carga.sessao !== 'string') return null;
    return {
      sub: carga.sub,
      tenant: typeof carga.tenant === 'string' ? carga.tenant : null,
      tipo: carga.tipo as TipoUsuario,
      sessao: carga.sessao,
    };
  } catch {
    return null;
  }
}

/** Token de renovação: 32 bytes aleatórios. Só o hash vai para o banco. */
export function gerarTokenRenovacao(): string {
  return converterBytesEmBase64Url(gerarBytesAleatorios(32));
}

export async function calcularHashToken(token: string): Promise<string> {
  const digest = await crypto.subtle.digest('SHA-256', converterTextoEmBytes(token));
  return converterBytesEmBase64Url(new Uint8Array(digest));
}
