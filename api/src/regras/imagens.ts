// Conferência das imagens enviadas pelo app (logotipo e ícones da tela 14): o tipo vem dos
// primeiros bytes (nunca do nome ou do tipo informado) e o tamanho do ícone vem do cabeçalho PNG.

export type TipoImagem = 'png' | 'jpeg';

const ASSINATURA_PNG = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];

/** PNG ou JPEG pelos primeiros bytes; null para qualquer outra coisa. */
export function detectarTipoImagem(bytes: Uint8Array): TipoImagem | null {
  if (ASSINATURA_PNG.every((b, i) => bytes[i] === b)) return 'png';
  if (bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff) return 'jpeg';
  return null;
}

/** Largura e altura de um PNG (bloco IHDR, logo depois da assinatura). */
export function lerDimensoesPng(bytes: Uint8Array): { largura: number; altura: number } | null {
  if (detectarTipoImagem(bytes) !== 'png' || bytes.length < 24) return null;
  const tipoBloco = String.fromCharCode(...bytes.subarray(12, 16));
  if (tipoBloco !== 'IHDR') return null;
  const visao = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  return { largura: visao.getUint32(16), altura: visao.getUint32(20) };
}

/** Ícone PNG quadrado do tamanho pedido. */
export function ehIconeValido(bytes: Uint8Array, tamanho: number): boolean {
  const dimensoes = lerDimensoesPng(bytes);
  return dimensoes !== null && dimensoes.largura === tamanho && dimensoes.altura === tamanho;
}
