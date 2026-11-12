// Leitura e validação dos corpos JSON das rotas de cadastro (online).
// Cada função devolve o valor normalizado ou `undefined` quando o valor é inválido.

const PADRAO_UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;

export function ehUuid(valor: unknown): valor is string {
  return typeof valor === 'string' && PADRAO_UUID.test(valor);
}

/** Lê o corpo da requisição como objeto; corpo ausente ou que não é objeto vira `null`. */
export async function lerCorpoJson(requisicao: {
  json: () => Promise<unknown>;
}): Promise<Record<string, unknown> | null> {
  const corpo = await requisicao.json().catch(() => null);
  return typeof corpo === 'object' && corpo !== null && !Array.isArray(corpo)
    ? (corpo as Record<string, unknown>)
    : null;
}

/** Texto obrigatório: sem espaços nas pontas, não vazio e com no máximo `maximo` caracteres. */
export function lerTextoObrigatorio(valor: unknown, maximo: number): string | undefined {
  if (typeof valor !== 'string') return undefined;
  const texto = valor.trim();
  return texto.length > 0 && texto.length <= maximo ? texto : undefined;
}

/** Texto opcional: `null`, ausente ou vazio viram `null`. */
export function lerTextoOpcional(valor: unknown, maximo: number): string | null | undefined {
  if (valor === undefined || valor === null) return null;
  if (typeof valor !== 'string') return undefined;
  const texto = valor.trim();
  if (texto.length === 0) return null;
  return texto.length <= maximo ? texto : undefined;
}

/** Inteiro dentro do intervalo [minimo, maximo]. */
export function lerInteiro(valor: unknown, minimo: number, maximo: number): number | undefined {
  return typeof valor === 'number' && Number.isInteger(valor) && valor >= minimo && valor <= maximo
    ? valor
    : undefined;
}

/** Inteiro opcional: `null` ou ausente viram `null`. */
export function lerInteiroOpcional(
  valor: unknown,
  minimo: number,
  maximo: number,
): number | null | undefined {
  if (valor === undefined || valor === null) return null;
  return lerInteiro(valor, minimo, maximo);
}
