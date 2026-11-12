import {
  converterBase64EmBytes,
  converterBytesEmBase64,
  converterTextoEmBytes,
  gerarBytesAleatorios,
} from '../util/codificacao.ts';

// O runtime do Workers limita o PBKDF2 a 100.000 iterações.
const ITERACOES = 100_000;
const BITS_HASH = 256;
const PREFIXO = 'pbkdf2-sha256';

async function derivarHash(senha: string, salt: Uint8Array, iteracoes: number): Promise<Uint8Array> {
  const chave = await crypto.subtle.importKey('raw', converterTextoEmBytes(senha), 'PBKDF2', false, [
    'deriveBits',
  ]);
  const bits = await crypto.subtle.deriveBits(
    { name: 'PBKDF2', hash: 'SHA-256', salt, iterations: iteracoes },
    chave,
    BITS_HASH,
  );
  return new Uint8Array(bits);
}

/** Gera o hash no formato 'pbkdf2-sha256$<iteracoes>$<salt_base64>$<hash_base64>'. */
export async function gerarHashSenha(senha: string): Promise<string> {
  const salt = gerarBytesAleatorios(16);
  const hash = await derivarHash(senha, salt, ITERACOES);
  return [PREFIXO, ITERACOES, converterBytesEmBase64(salt), converterBytesEmBase64(hash)].join('$');
}

/** Confere a senha contra o hash guardado, em tempo constante. */
export async function validarSenha(senha: string, hashGuardado: string): Promise<boolean> {
  const [prefixo, textoIteracoes, saltBase64, hashBase64, ...resto] = hashGuardado.split('$');
  if (prefixo !== PREFIXO || !saltBase64 || !hashBase64 || resto.length > 0) return false;
  const iteracoes = Number(textoIteracoes);
  if (!Number.isInteger(iteracoes) || iteracoes < 1 || iteracoes > ITERACOES) return false;
  const esperado = converterBase64EmBytes(hashBase64);
  const calculado = await derivarHash(senha, converterBase64EmBytes(saltBase64), iteracoes);
  if (esperado.byteLength !== calculado.byteLength) return false;
  return crypto.subtle.timingSafeEqual(esperado, calculado);
}

/** Regra mínima de senha: 8 caracteres ou mais. */
export function ehSenhaValida(senha: unknown): senha is string {
  return typeof senha === 'string' && senha.length >= 8 && senha.length <= 200;
}
