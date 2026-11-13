import { describe, expect, it } from 'vitest';
import casos from '../../docs/casos-regras/lista-lancamento.json';
import { calcularListaLancamento } from '../src/regras/lista-lancamento';

// Mesmos casos usados no app (Dart): docs/casos-regras/lista-lancamento.json
describe('lista do lançamento (casos compartilhados)', () => {
  it.each(casos.casos)('$nome', (caso) => {
    expect(calcularListaLancamento(caso)).toEqual(caso.esperado);
  });
});
