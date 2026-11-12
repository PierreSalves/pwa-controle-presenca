/** Timestamp ISO 8601 em UTC, no formato usado no banco. */
export function obterAgoraIso(agora: Date = new Date()): string {
  return agora.toISOString();
}

export function somarSegundos(base: Date, segundos: number): Date {
  return new Date(base.getTime() + segundos * 1000);
}
