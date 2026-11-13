import { describe, expect, it } from 'vitest';
import casos from '../../docs/casos-regras/frequencia.json';
import {
  calcularAlunosSumidos,
  calcularFrequenciaNoPeriodo,
  calcularInicioDoSemestre,
} from '../src/regras/frequencia';

// Mesmos casos usados no app (Dart): docs/casos-regras/frequencia.json
describe('frequência (casos compartilhados)', () => {
  it.each(casos.inicio_do_semestre)('semestre de $data começa em $esperado', ({ data, esperado }) => {
    expect(calcularInicioDoSemestre(data)).toBe(esperado);
  });

  it.each(casos.frequencia)('$nome', (caso) => {
    expect(calcularFrequenciaNoPeriodo(caso)).toEqual(caso.esperado);
  });

  it.each(casos.alunos_sumidos)('$nome', (caso) => {
    expect(calcularAlunosSumidos(caso)).toEqual(caso.esperado);
  });
});
