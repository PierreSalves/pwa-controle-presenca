import { describe, expect, it } from 'vitest';
import casos from '../../docs/casos-regras/faixas.json';
import { calcularGrauAjustado, ehGraduacaoValida, FAIXAS, obterLimitesGrau } from '../src/regras/faixas';

// Mesmos casos usados no app (Dart): docs/casos-regras/faixas.json
describe('faixas e graus (casos compartilhados)', () => {
  it.each(casos.limites_do_grau)('limites do grau na faixa $faixa', ({ faixa, esperado }) => {
    expect(obterLimitesGrau(faixa)).toEqual(esperado);
  });

  it.each(casos.graduacao_valida)(
    '$faixa, grau $grau, ponteira $ponteira: $esperado',
    ({ faixa, grau, ponteira, esperado }) => {
      expect(ehGraduacaoValida(faixa, grau, ponteira)).toBe(esperado);
    },
  );

  it.each(casos.grau_ajustado)('grau $grau na faixa $faixa vira $esperado', ({ faixa, grau, esperado }) => {
    expect(calcularGrauAjustado(faixa, grau)).toBe(esperado);
  });

  it('lista 20 faixas, sem nome repetido', () => {
    expect(FAIXAS).toHaveLength(20);
    expect(new Set(FAIXAS.map((f) => f.nome)).size).toBe(20);
  });
});
