import { describe, expect, it } from 'vitest';
import casos from '../../docs/casos-regras/presenca.json';
import {
  calcularTipoDoDia,
  ehDataFutura,
  ehDataValida,
  estaMatriculadoNaData,
  gerarIdAulaDoQuadro,
  obterDiaDaSemana,
  obterHojeEmSaoPaulo,
  type QuadroAulas,
} from '../src/regras/presenca';

// Mesmos casos usados no app (Dart): docs/casos-regras/presenca.json
describe('regras de presença (casos compartilhados)', () => {
  it.each(casos.dia_da_semana)('dia da semana de $data é $esperado', ({ data, esperado }) => {
    expect(obterDiaDaSemana(data)).toBe(esperado);
  });

  it.each(casos.data_futura)('$data é futura em relação a $hoje: $esperado', ({ data, hoje, esperado }) => {
    expect(ehDataFutura(data, hoje)).toBe(esperado);
  });

  it.each(casos.hoje_em_sao_paulo)(
    'às $instante_utc é $esperado em São Paulo',
    ({ instante_utc, esperado }) => {
      expect(obterHojeEmSaoPaulo(new Date(instante_utc))).toBe(esperado);
    },
  );

  it.each(casos.matricula_vigente)(
    'matrícula $data_inicio–$data_fim cobre $data: $esperado',
    ({ data, data_inicio, data_fim, esperado }) => {
      expect(estaMatriculadoNaData(data, { data_inicio, data_fim })).toBe(esperado);
    },
  );

  it.each(casos.tipo_do_dia_no_quadro.casos)('$data é $esperado ($obs)', ({ data, esperado }) => {
    expect(calcularTipoDoDia(data, casos.tipo_do_dia_no_quadro.quadros as QuadroAulas[])).toBe(esperado);
  });

  it.each(casos.id_aula_regular)(
    'id determinístico da aula $tipo de $data_aula',
    async ({ turma_id, data_aula, tipo, esperado }) => {
      expect(await gerarIdAulaDoQuadro(turma_id, data_aula, tipo as 'regular' | 'reposicao')).toBe(esperado);
    },
  );
});

describe('validação de data', () => {
  it('aceita datas reais e recusa formatos e datas inexistentes', () => {
    expect(ehDataValida('2026-11-12')).toBe(true);
    expect(ehDataValida('2024-02-29')).toBe(true);
    expect(ehDataValida('2026-02-29')).toBe(false);
    expect(ehDataValida('12/11/2026')).toBe(false);
    expect(ehDataValida(20261112)).toBe(false);
  });
});
