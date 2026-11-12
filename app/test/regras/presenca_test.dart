import 'dart:convert';
import 'dart:io';

import 'package:controle_presenca/regras/presenca.dart';
import 'package:flutter_test/flutter_test.dart';

// Mesmos casos usados na API (TypeScript): docs/casos-regras/presenca.json
void main() {
  final casos = jsonDecode(
    File('../docs/casos-regras/presenca.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  List<Map<String, dynamic>> lista(dynamic valor) =>
      (valor as List).cast<Map<String, dynamic>>();

  group('regras de presença (casos compartilhados)', () {
    for (final caso in lista(casos['dia_da_semana'])) {
      test('dia da semana de ${caso['data']} é ${caso['esperado']}', () {
        expect(obterDiaDaSemana(caso['data'] as String), caso['esperado']);
      });
    }

    for (final caso in lista(casos['data_futura'])) {
      test('${caso['data']} é futura em relação a ${caso['hoje']}', () {
        expect(
          ehDataFutura(caso['data'] as String, caso['hoje'] as String),
          caso['esperado'],
        );
      });
    }

    for (final caso in lista(casos['hoje_em_sao_paulo'])) {
      test('às ${caso['instante_utc']} é ${caso['esperado']} em São Paulo', () {
        expect(
          obterHojeEmSaoPaulo(DateTime.parse(caso['instante_utc'] as String)),
          caso['esperado'],
        );
      });
    }

    for (final caso in lista(casos['matricula_vigente'])) {
      test(
        'matrícula ${caso['data_inicio']}–${caso['data_fim']} cobre ${caso['data']}',
        () {
          expect(
            estaMatriculadoNaData(
              caso['data'] as String,
              dataInicio: caso['data_inicio'] as String,
              dataFim: caso['data_fim'] as String?,
            ),
            caso['esperado'],
          );
        },
      );
    }

    final quadro = casos['tipo_do_dia_no_quadro'] as Map<String, dynamic>;
    final quadros = [
      for (final q in lista(quadro['quadros']))
        QuadroAulas(
          vigenciaInicio: q['vigencia_inicio'] as String,
          vigenciaFim: q['vigencia_fim'] as String?,
          dias: (q['dias'] as Map<String, dynamic>).cast<String, int>(),
        ),
    ];
    const tipos = {
      'sem_aula': TipoDia.semAula,
      'regular': TipoDia.regular,
      'reposicao': TipoDia.reposicao,
    };
    for (final caso in lista(quadro['casos'])) {
      test('${caso['data']} é ${caso['esperado']} (${caso['obs']})', () {
        expect(
          calcularTipoDoDia(caso['data'] as String, quadros),
          tipos[caso['esperado']],
        );
      });
    }

    for (final caso in lista(casos['id_aula_regular'])) {
      test(
        'id determinístico da aula ${caso['tipo']} de ${caso['data_aula']}',
        () {
          expect(
            gerarIdAulaDoQuadro(
              caso['turma_id'] as String,
              caso['data_aula'] as String,
              TipoAula.values.byName(caso['tipo'] as String),
            ),
            caso['esperado'],
          );
        },
      );
    }
  });

  group('datas', () {
    test('valida datas reais', () {
      expect(ehDataValida('2026-11-12'), isTrue);
      expect(ehDataValida('2024-02-29'), isTrue);
      expect(ehDataValida('2026-02-29'), isFalse);
      expect(ehDataValida('12/11/2026'), isFalse);
    });

    test('soma dias atravessando mês e ano', () {
      expect(somarDiasNaData('2026-12-31', 1), '2027-01-01');
      expect(somarDiasNaData('2026-03-01', -1), '2026-02-28');
    });
  });
}
