import { describe, expect, it } from 'vitest';
import {
  calcularProximoCodigo,
  calcularRelatorioImportacao,
  normalizarCodigoImportado,
  temSobreposicao,
} from '../src/regras/alunos';

describe('próximo código sugerido', () => {
  it.each([
    [[], '1'],
    [['1', '2', '3'], '4'],
    [['09', '10A', '03'], '10'],
    [['10A', 'X'], '1'],
    [['007', '12'], '13'],
    [['099'], '100'],
  ])('%j → %s', (codigos, esperado) => {
    expect(calcularProximoCodigo(codigos)).toBe(esperado);
  });
});

describe('sobreposição de períodos de matrícula', () => {
  const p = (data_inicio: string, data_fim: string | null) => ({ data_inicio, data_fim });
  it.each([
    [p('2026-01-01', '2026-03-31'), p('2026-04-01', null), false],
    [p('2026-01-01', '2026-03-31'), p('2026-03-31', null), true],
    [p('2026-01-01', null), p('2027-01-01', null), true],
    [p('2026-05-01', '2026-05-31'), p('2026-01-01', '2026-04-30'), false],
    [p('2026-05-01', '2026-05-31'), p('2026-05-10', '2026-05-12'), true],
  ])('%j × %j → %s', (a, b, esperado) => {
    expect(temSobreposicao(a, b)).toBe(esperado);
    expect(temSobreposicao(b, a)).toBe(esperado);
  });
});

describe('importação: relatório', () => {
  it('tira os parênteses do código da planilha', () => {
    expect(normalizarCodigoImportado(' (10A) ')).toBe('10A');
    expect(normalizarCodigoImportado('10A')).toBe('10A');
  });

  it('aponta linhas incompletas, códigos repetidos ou já cadastrados e nomes repetidos', () => {
    const relatorio = calcularRelatorioImportacao(
      [
        { linha: 1, codigo: '10A', nome: 'Ana' },
        { linha: 2, codigo: '10a', nome: 'Bruno' },
        { linha: 3, codigo: '11', nome: 'ana' },
        { linha: 4, codigo: '12', nome: '' },
        { linha: 5, codigo: '20', nome: 'Carla' },
      ],
      [{ codigo: '20', nome: 'Carla Souza' }],
    );
    expect(relatorio).toEqual({
      incompletas: [4],
      codigos_repetidos: [{ codigo: '10A', linhas: [1, 2] }],
      codigos_existentes: [{ codigo: '20', linha: 5, nome_cadastrado: 'Carla Souza' }],
      nomes_repetidos: [{ nome: 'Ana', linhas: [1, 3] }],
      pode_importar: false,
    });
  });

  it('nome repetido sozinho só avisa, não bloqueia', () => {
    const relatorio = calcularRelatorioImportacao(
      [
        { linha: 1, codigo: '1', nome: 'João Silva' },
        { linha: 2, codigo: '2', nome: 'João  Silva' },
      ],
      [],
    );
    expect(relatorio.nomes_repetidos).toHaveLength(1);
    expect(relatorio.pode_importar).toBe(true);
  });
});
