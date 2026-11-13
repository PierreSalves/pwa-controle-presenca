import 'package:controle_presenca/regras/lista_lancamento.dart';
import 'package:controle_presenca/regras/relatorios.dart';
import 'package:flutter_test/flutter_test.dart';

// Turma de terça e quarta, reposição no sábado 07/11. Ana desde 01/10; Bruno desde 10/11.
void main() {
  const aulas = [
    AulaDaLista(id: 'a0', data: '2026-10-28', tipo: 'regular'),
    AulaDaLista(id: 'a3', data: '2026-11-07', tipo: 'reposicao'),
    AulaDaLista(id: 'a1', data: '2026-11-03', tipo: 'regular'),
    AulaDaLista(id: 'a2', data: '2026-11-04', tipo: 'regular'),
    AulaDaLista(id: 'a4', data: '2026-11-10', tipo: 'regular'),
    AulaDaLista(id: 'a5', data: '2026-11-11', tipo: 'regular'),
  ];
  const bruno = AlunoDoRelatorio(
    id: 'b',
    codigo: '2',
    nome: 'Bruno',
    matriculas: [PeriodoMatricula(dataInicio: '2026-11-10', dataFim: null)],
  );
  const ana = AlunoDoRelatorio(
    id: 'a',
    codigo: '1',
    nome: 'ana',
    matriculas: [PeriodoMatricula(dataInicio: '2026-10-01', dataFim: null)],
  );
  final base = BaseRelatorio(
    aulas: aulas,
    alunos: const [bruno, ana],
    presencas: const [
      (aulaId: 'a1', alunoId: 'a'),
      (aulaId: 'a3', alunoId: 'a'),
      (aulaId: 'a4', alunoId: 'a'),
      (aulaId: 'a5', alunoId: 'b'),
    ],
    minimo: 75,
  );
  final ana_ = base.alunos.first;
  final bruno_ = base.alunos.last;
  AulaDaLista aula(String id) => aulas.firstWhere((a) => a.id == id);

  test('alunos por nome e só os matriculados em algum dia do período', () {
    expect([for (final a in base.alunos) a.nome], ['ana', 'Bruno']);
    expect(
      [for (final a in base.obterAlunosEntre('2026-10-01', '2026-10-31')) a.id],
      ['a'],
    );
    expect(base.obterAlunosEntre('2026-11-01', '2026-11-30'), hasLength(2));
  });

  test('marca: veio, faltou e fora da matrícula', () {
    expect(
      base.calcularMarca(bruno_, aula('a1')),
      MarcaPresenca.foraDaMatricula,
    );
    expect(base.calcularMarca(bruno_, aula('a4')), MarcaPresenca.faltou);
    expect(base.calcularMarca(bruno_, aula('a5')), MarcaPresenca.veio);
  });

  test('semanas do período com aula, de domingo a sábado e numeradas', () {
    final semanas = calcularSemanas(base, '2026-11-01', '2026-11-30');
    expect([for (final s in semanas) s.domingo], ['2026-11-01', '2026-11-08']);
    expect([for (final s in semanas) s.ordem], [1, 2]);
    expect(semanas.first.sabado, '2026-11-07');
    expect([for (final a in semanas.first.aulas) a.id], ['a1', 'a2', 'a3']);
  });

  test('meses do período atravessando o ano', () {
    expect(calcularMeses('2026-11-15', '2027-02-01'), [
      '2026-11',
      '2026-12',
      '2027-01',
      '2027-02',
    ]);
  });

  test('contagens do mês: presenças com reposição e aulas só regulares', () {
    final novembro = obterAulasDoMes(base.aulas, '2026-11');
    expect(base.contarPresencas(ana_, novembro), 3);
    expect(contarAulasRegulares(novembro), 4);
    expect(ehMesFuturo('2026-12', '2026-11-13'), isTrue);
    expect(ehMesFuturo('2026-11', '2026-11-13'), isFalse);
  });

  test('frequência do período segue a regra da graduação e a matrícula', () {
    final daAna = base.calcularFrequencia(ana_, '2026-11-01', '2026-11-30');
    expect((daAna.aulas, daAna.presencas, daAna.reposicoes), (4, 2, 1));
    expect(daAna.percentual, 75);
    expect(daAna.abaixoDoMinimo, isFalse);
    final doBruno = base.calcularFrequencia(bruno_, '2026-11-01', '2026-11-30');
    expect((doBruno.aulas, doBruno.percentual), (2, 50));
    expect(doBruno.abaixoDoMinimo, isTrue);
  });

  test('por aluno: aulas da matrícula, da mais recente para a mais antiga', () {
    final doBruno = calcularAulasDoAluno(
      base,
      bruno_,
      '2026-11-01',
      '2026-11-30',
    );
    expect(
      [for (final a in doBruno) (a.aula.id, a.veio)],
      [('a5', true), ('a4', false)],
    );
  });
}
