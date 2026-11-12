const codificador = new TextEncoder();

export function converterTextoEmBytes(texto: string): Uint8Array {
  return codificador.encode(texto);
}

export function converterBytesEmBase64(bytes: Uint8Array): string {
  let binario = '';
  for (const byte of bytes) binario += String.fromCharCode(byte);
  return btoa(binario);
}

export function converterBase64EmBytes(base64: string): Uint8Array {
  const binario = atob(base64);
  const bytes = new Uint8Array(binario.length);
  for (let i = 0; i < binario.length; i++) bytes[i] = binario.charCodeAt(i);
  return bytes;
}

export function converterBytesEmBase64Url(bytes: Uint8Array): string {
  return converterBytesEmBase64(bytes).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

export function gerarBytesAleatorios(quantidade: number): Uint8Array {
  return crypto.getRandomValues(new Uint8Array(quantidade));
}
