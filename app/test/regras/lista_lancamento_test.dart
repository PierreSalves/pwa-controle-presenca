import 'dart:convert';
import 'dart:io';

import 'package:controle_presenca/regras/lista_lancamento.dart';
import 'package:flutter_test/flutter_test.dart';

// Mesmos casos usados na API (TypeScript): docs/casos-regras/lista-lancamento.json
void main() {
  final arquivo = jsonDecode(
    File('../docs/casos-regras/lista-lancamento.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  List<Map<String, dynamic>> lista(dynamic valor) =>
      (valor as List).cast<Map<String, dynamic>>();

  group('lista do lançamento (casos compartilhados)', () {
    for (final caso in lista(arquivo['casos'])) {
      test(caso['nome'], () {
        final parametros = caso['parametros'] as Map<String, dynamic>;
        final resultado = calcularListaLancamento(
          data: caso['data'] as String,
          parametros: ParametrosListaLancamento(
            percentualMinimo: parametros['percentual_minimo'] as int,
            ultimasAulas: parametros['ultimas_aulas'] as int,
          ),
          aulas: [
            for (final a in lista(caso['aulas']))
              AulaDaLista(
                id: a['id'] as String,
                data: a['data'] as String,
                tipo: a['tipo'] as String,
              ),
          ],
          presencas: [
            for (final p in lista(caso['presencas']))
              (
                aulaId: p['aula_id'] as String,
                alunoId: p['aluno_id'] as String,
              ),
          ],
          alunos: [
            for (final a in lista(caso['alunos']))
              AlunoDaLista(
                id: a['id'] as String,
                matriculas: [
                  for (final m in lista(a['matriculas']))
                    PeriodoMatricula(
                      dataInicio: m['data_inicio'] as String,
                      dataFim: m['data_fim'] as String?,
                    ),
                ],
              ),
          ],
        );
        expect([
          for (final f in resultado)
            {
              'aluno_id': f.alunoId,
              'percentual': f.percentual,
              'novo': f.novo,
              'frequente': f.frequente,
              'ultima_presenca': f.ultimaPresenca,
            },
        ], caso['esperado']);
      });
    }
  });

  test('parâmetros inválidos ou ausentes usam o padrão', () {
    final p = ParametrosListaLancamento.lerJson({'percentual_minimo': 200});
    expect(p.percentualMinimo, 30);
    expect(p.ultimasAulas, 8);
    final q = ParametrosListaLancamento.lerJson({
      'percentual_minimo': 40,
      'ultimas_aulas': 6,
    });
    expect(q.percentualMinimo, 40);
    expect(q.ultimasAulas, 6);
  });
}
