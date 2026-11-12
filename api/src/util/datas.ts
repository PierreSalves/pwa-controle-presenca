/** Soma (ou subtrai, com valor negativo) dias a uma data de calendário AAAA-MM-DD. */
export function somarDiasNaData(data: string, dias: number): string {
  const [ano, mes, dia] = data.split('-').map(Number) as [number, number, number];
  return new Date(Date.UTC(ano, mes - 1, dia + dias)).toISOString().slice(0, 10);
}
