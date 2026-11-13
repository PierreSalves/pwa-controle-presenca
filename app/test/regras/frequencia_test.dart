import 'dart:convert';
import 'dart:io';

import 'package:controle_presenca/regras/frequencia.dart';
import 'package:controle_presenca/regras/lista_lancamento.dart';
import 'package:flutter_test/flutter_test.dart';

// Mesmos casos usados na API (TypeScript): docs/casos-regras/frequencia.json
void main() {
  final arquivo = jsonDecode(
    File('../docs/casos-regras/frequencia.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  List<Map<String, dynamic>> lista(dynamic valor) =>
      (valor as List).cast<Map<String, dynamic>>();
  List<AulaDaLista> lerAulas(dynamic valor) => [
    for (final a in lista(valor))
      AulaDaLista(
        id: a['id'] as String,
        data: a['data'] as String,
        tipo: a['tipo'] as String,
      ),
  ];
  List<PresencaDaRegra> lerPresencas(dynamic valor) => [
    for (final p in lista(valor))
      (aulaId: p['aula_id'] as String, alunoId: p['aluno_id'] as String),
  ];

  group('frequência (casos compartilhados)', () {
    for (final caso in lista(arquivo['inicio_do_semestre'])) {
      test('semestre de ${caso['data']} começa em ${caso['esperado']}', () {
        expect(
          calcularInicioDoSemestre(caso['data'] as String),
          caso['esperado'],
        );
      });
    }

    for (final caso in lista(arquivo['frequencia'])) {
      test(caso['nome'], () {
        final resultado = calcularFrequenciaNoPeriodo(
          inicio: caso['inicio'] as String,
          fim: caso['fim'] as String,
          minimo: caso['minimo'] as int?,
          aulas: lerAulas(caso['aulas']),
          presencas: lerPresencas(caso['presencas']),
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
              'aulas': f.aulas,
              'presencas': f.presencas,
              'reposicoes': f.reposicoes,
              'percentual': f.percentual,
              'abaixo_do_minimo': f.abaixoDoMinimo,
            },
        ], caso['esperado']);
      });
    }

    for (final caso in lista(arquivo['alunos_sumidos'])) {
      test(caso['nome'], () {
        final resultado = calcularAlunosSumidos(
          hoje: caso['hoje'] as String,
          semanas: caso['semanas'] as int,
          aulas: lerAulas(caso['aulas']),
          presencas: lerPresencas(caso['presencas']),
          alunos: [
            for (final a in lista(caso['alunos']))
              (
                id: a['id'] as String,
                matriculas: [
                  for (final m in lista(a['matriculas']))
                    MatriculaDoAluno(
                      id: m['id'] as String,
                      dataInicio: m['data_inicio'] as String,
                      dataFim: m['data_fim'] as String?,
                    ),
                ],
              ),
          ],
        );
        expect([
          for (final s in resultado)
            {
              'aluno_id': s.alunoId,
              'matricula_id': s.matriculaId,
              'ultima_presenca': s.ultimaPresenca,
            },
        ], caso['esperado']);
      });
    }
  });
}
