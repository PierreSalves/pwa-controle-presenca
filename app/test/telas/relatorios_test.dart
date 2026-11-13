import 'package:controle_presenca/dados/consulta_relatorios.dart';
import 'package:controle_presenca/regras/lista_lancamento.dart';
import 'package:controle_presenca/regras/relatorios.dart';
import 'package:controle_presenca/telas/relatorios/html_relatorio.dart';
import 'package:controle_presenca/telas/relatorios/montar_relatorio.dart';
import 'package:flutter_test/flutter_test.dart';

// Turma de terça e quarta com reposição no sábado 07/11; Ana desde 01/10, Bruno desde 10/11.
TurmaDoRelatorio _montarTurma() => TurmaDoRelatorio(
  id: 't',
  nome: 'Adulto <A>',
  cabecalhoImpressao: 'Prof. Fulano',
  base: BaseRelatorio(
    minimo: 75,
    aulas: const [
      AulaDaLista(id: 'a1', data: '2026-11-03', tipo: 'regular'),
      AulaDaLista(id: 'a2', data: '2026-11-04', tipo: 'regular'),
      AulaDaLista(id: 'a3', data: '2026-11-07', tipo: 'reposicao'),
      AulaDaLista(id: 'a4', data: '2026-11-10', tipo: 'regular'),
      AulaDaLista(id: 'a5', data: '2026-11-11', tipo: 'regular'),
    ],
    alunos: const [
      AlunoDoRelatorio(
        id: 'a',
        codigo: '1',
        nome: 'Ana',
        matriculas: [PeriodoMatricula(dataInicio: '2026-10-01', dataFim: null)],
      ),
      AlunoDoRelatorio(
        id: 'b',
        codigo: '2',
        nome: 'Bruno',
        matriculas: [PeriodoMatricula(dataInicio: '2026-11-10', dataFim: null)],
      ),
    ],
    presencas: const [
      (aulaId: 'a1', alunoId: 'a'),
      (aulaId: 'a3', alunoId: 'a'),
      (aulaId: 'a4', alunoId: 'a'),
      (aulaId: 'a5', alunoId: 'b'),
    ],
  ),
);

void main() {
  final turma = _montarTurma();

  test('atalhos de período a partir de hoje', () {
    const hoje = '2026-11-13'; // sexta
    expect(calcularPeriodoDoAtalho(AtalhoPeriodo.semana, hoje), (
      inicio: '2026-11-08',
      fim: '2026-11-14',
    ));
    expect(calcularPeriodoDoAtalho(AtalhoPeriodo.mes, hoje), (
      inicio: '2026-11-01',
      fim: '2026-11-30',
    ));
    expect(calcularPeriodoDoAtalho(AtalhoPeriodo.semestre, hoje), (
      inicio: '2026-07-01',
      fim: '2026-12-31',
    ));
    expect(
      calcularPeriodoDoAtalho(AtalhoPeriodo.mes, '2028-02-10').fim,
      '2028-02-29',
    );
  });

  test('semanal: semanas agrupadas, marcas, total e presentes por aula', () {
    final semanas = obterSemanas(turma, '2026-11-01', '2026-11-30');
    final r = montarSemanal(
      turma,
      '2026-11-01',
      '2026-11-30',
      semanas,
      comData: false,
    );
    expect([for (final g in r.grupos!) g.colunas], [3, 2]);
    expect(r.colunas[2].etiqueta, 'repos.');
    final bruno = r.linhas[1];
    expect(bruno.rotulo, '(2) Bruno');
    // Fora da matrícula nas três primeiras aulas, faltou na a4, veio na a5.
    expect(
      [for (final c in bruno.celulas) c.estilo],
      [
        EstiloCelula.vazio,
        EstiloCelula.vazio,
        EstiloCelula.vazio,
        EstiloCelula.faltou,
        EstiloCelula.veio,
        EstiloCelula.normal,
      ],
    );
    expect(bruno.celulas.last.texto, '1');
    final presentes = r.linhas.last;
    expect(presentes.rodape, isTrue);
    expect(
      [for (final c in presentes.celulas) c.texto],
      [
        '1', '0', '1', '1', '1', '', //
      ],
    );
  });

  test('mensal completo: frequência do período com o mínimo em destaque', () {
    final r = montarMensal(turma, '2026-11-01', '2026-11-30', completo: true);
    expect(
      [for (final c in r.colunas) c.rotulo],
      ['nov', 'Aulas', 'Presenças', 'Repos.', 'Freq.'],
    );
    expect(
      [for (final c in r.linhas[0].celulas) c.texto],
      [
        '3', '4', '2', '1', '75%', //
      ],
    );
    expect(r.linhas[1].celulas.last.estilo, EstiloCelula.abaixoDoMinimo);
    expect(
      r.linhas.last.celulas.first.texto,
      '4',
    ); // aulas regulares de novembro
    expect(r.periodo, '01/11 a 30/11/2026 · mínimo 75%');
  });

  test('anual: meses futuros com traço', () {
    final r = montarAnual(turma, '2026-11-30', '2026-11-13');
    expect(r.colunas.first.rotulo, 'JAN');
    expect(r.linhas[0].celulas[10].texto, '3'); // novembro
    expect(r.linhas[0].celulas[11].estilo, EstiloCelula.futuro); // dezembro
    expect(r.linhas[0].celulas.last.texto, '3');
  });

  test('por aluno e graduação', () {
    final bruno = turma.base.alunos.last;
    final porAluno = montarPorAluno(turma, bruno, '2026-11-01', '2026-11-30');
    expect(
      [for (final l in porAluno.linhas) l.rotulo],
      ['qua 11/11/2026', 'ter 10/11/2026'],
    );
    expect(porAluno.resumo.last.valor, '50%');
    expect(porAluno.resumo.last.baixo, isTrue);

    final graduacao = montarGraduacao(turma, '2026-11-12');
    expect(graduacao.periodo, '2º sem. 2026 · até 12/11/2026 · mínimo 75%');
    expect(graduacao.linhas, hasLength(2));
  });

  test('página impressa: cabeçalhos, marcas, paisagem e texto escapado', () {
    final semanas = obterSemanas(turma, '2026-11-01', '2026-11-30');
    final html = gerarHtmlRelatorio(
      montarSemanal(turma, '2026-11-01', '2026-11-30', semanas, comData: false),
      CabecalhoImpressao(
        academia: 'Academia Teste',
        cabecalhoAcademia: 'Mestre Fulano',
        turma: turma.nome,
        cabecalhoTurma: turma.cabecalhoImpressao,
        geradoEm: DateTime.utc(2026, 11, 13, 13, 15),
        geradoPor: 'Ana (assistente)',
      ),
    );
    expect(html, contains('size: A4 landscape'));
    expect(html, contains('<h1>Academia Teste</h1>'));
    expect(html, contains('Mestre Fulano'));
    expect(html, contains('Turma Adulto &lt;A&gt;'));
    expect(html, isNot(contains('<A>')));
    expect(html, contains('colspan="3"'));
    expect(html, contains('&#10003;'));
    expect(
      html,
      contains('Gerado em 13/11/2026 às 10:15 por Ana (assistente).'),
    );
    expect(html, isNot(contains('<script')));
  });
}
