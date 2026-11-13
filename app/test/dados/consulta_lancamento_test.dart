import 'package:controle_presenca/dados/banco_local.dart';
import 'package:controle_presenca/dados/consulta_lancamento.dart';
import 'package:controle_presenca/dados/repositorio_presenca.dart';
import 'package:controle_presenca/dados/servico_sincronizacao.dart';
import 'package:controle_presenca/regras/presenca.dart';
import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

void main() {
  late BancoLocal banco;
  late RepositorioPresenca repositorio;
  late ConsultaLancamento consulta;

  Future<void> carregar(Map<String, dynamic> pull) async {
    final cliente = ClienteSyncFalso()..respostaPull = (_) => pull;
    await ServicoSincronizacao(banco, cliente).buscarAlteracoes();
  }

  setUp(() {
    banco = criarBancoEmMemoria();
    repositorio = RepositorioPresenca(banco, relogio: () => agora);
    consulta = ConsultaLancamento(banco, repositorio);
  });
  tearDown(() => banco.close());

  test('dias de aula da semana seguem o quadro e bloqueiam o futuro', () async {
    await carregar(montarPull());
    final dias = calcularDiasDeAulaDaSemana(
      hoje,
      await consulta.obterQuadros(turmaId),
      hoje,
    );
    expect(
      [for (final d in dias) d.data],
      ['2026-11-11', '2026-11-12', '2026-11-14'],
    );
    expect(
      [for (final d in dias) d.tipo],
      [TipoAula.regular, TipoAula.regular, TipoAula.reposicao],
    );
    expect([for (final d in dias) d.futuro], [false, false, true]);
  });

  test(
    'só matriculados entram; aluno novo aparece entre os frequentes',
    () async {
      await carregar(montarPull());
      final dados = await consulta.obterLancamento(turmaId, hoje, hoje: hoje);
      expect(dados.tipo, TipoAula.regular);
      expect([for (final a in dados.lista) a.nome], ['Ana']);
      expect(dados.lista.single.frequencia.novo, isTrue);
      expect(dados.poucoFrequentes, isEmpty);
      expect(dados.presentes, 0);
    },
  );

  test('dia sem aula no quadro não tem tipo', () async {
    await carregar(montarPull());
    final dados = await consulta.obterLancamento(
      turmaId,
      '2026-11-10',
      hoje: hoje,
    );
    expect(dados.tipo, isNull);
  });

  test(
    'aluno que não vem fica entre os pouco frequentes até ser marcado',
    () async {
      // Oito quartas e quintas anteriores, sem presença da Ana.
      final aulas = [
        for (final data in [
          '2026-10-14',
          '2026-10-15',
          '2026-10-21',
          '2026-10-22',
          '2026-10-28',
          '2026-10-29',
          '2026-11-04',
          '2026-11-05',
        ])
          {
            'id': gerarIdAulaDoQuadro(turmaId, data, TipoAula.regular),
            'turma_id': turmaId,
            'data_aula': data,
            'tipo': 'regular',
            'excluido': 0,
            'updated_at': '2026-11-05T00:00:00.000Z',
            'server_version': 2,
          },
      ];
      await carregar(montarPull(aulas: aulas));
      var dados = await consulta.obterLancamento(turmaId, hoje, hoje: hoje);
      expect(dados.lista, isEmpty);
      expect(dados.poucoFrequentes.single.frequencia.percentual, 0);

      await repositorio.definirPresenca(
        turmaId: turmaId,
        data: hoje,
        alunoId: alunoId,
        presente: true,
      );
      dados = await consulta.obterLancamento(turmaId, hoje, hoje: hoje);
      expect(dados.lista.single.presente, isTrue);
      expect(dados.poucoFrequentes, isEmpty);
      expect(dados.presentes, 1);
    },
  );

  test('a consulta observada atualiza após a marcação', () async {
    await carregar(montarPull());
    final emissoes = consulta.observarLancamento(turmaId, hoje, hoje: hoje);
    final esperadas = expectLater(
      emissoes.map((d) => d.presentes),
      emitsThrough(1),
    );
    await Future<void>.delayed(Duration.zero);
    await repositorio.definirPresenca(
      turmaId: turmaId,
      data: hoje,
      alunoId: alunoId,
      presente: true,
    );
    await esperadas;
  });

  test('reposição avulsa aparece na semana e recebe presenças', () async {
    await carregar(montarPull());
    final terca = '2026-11-10'; // sem aula no quadro
    final aulaId = await repositorio.criarReposicaoAvulsa(turmaId, terca);

    var dados = await consulta.obterLancamento(
      turmaId,
      terca,
      hoje: hoje,
      aulaIdAvulsa: aulaId,
    );
    expect(dados.tipo, TipoAula.reposicao);
    expect(dados.aulaIdAvulsa, aulaId);
    expect(
      [for (final d in dados.diasDaSemana) (d.data, d.aulaIdAvulsa)],
      [
        (terca, aulaId),
        ('2026-11-11', null),
        ('2026-11-12', null),
        ('2026-11-14', null),
      ],
    );

    await repositorio.definirPresenca(
      turmaId: turmaId,
      data: terca,
      alunoId: alunoId,
      presente: true,
      aulaIdAvulsa: aulaId,
    );
    dados = await consulta.obterLancamento(
      turmaId,
      terca,
      hoje: hoje,
      aulaIdAvulsa: aulaId,
    );
    expect(dados.presentes, 1);

    // A aula regular do dia seguinte não enxerga a presença da avulsa.
    final quarta = await consulta.obterLancamento(
      turmaId,
      '2026-11-11',
      hoje: hoje,
    );
    expect(quarta.presentes, 0);
    expect(quarta.lista.single.frequencia.ultimaPresenca, terca);
  });

  test(
    'reposição avulsa no mesmo dia de aula regular fica depois dela',
    () async {
      await carregar(montarPull());
      final aulaId = await repositorio.criarReposicaoAvulsa(turmaId, hoje);
      final dados = await consulta.obterLancamento(turmaId, hoje, hoje: hoje);
      final doDia = dados.diasDaSemana.where((d) => d.data == hoje).toList();
      expect([for (final d in doDia) d.aulaIdAvulsa], [null, aulaId]);
      expect(dados.aulaIdAvulsa, isNull);
      expect(dados.tipo, TipoAula.regular);
    },
  );

  group('grade da semana (desktop)', () {
    test('mostra as presenças da semana e bloqueia o futuro', () async {
      await carregar(montarPull());
      await repositorio.definirPresenca(
        turmaId: turmaId,
        data: '2026-11-11',
        alunoId: alunoId,
        presente: true,
      );
      final grade = await consulta.obterGrade(turmaId, hoje, hoje: hoje);
      expect(grade.domingo, '2026-11-08');
      expect(
        [for (final d in grade.dias) d.chave],
        ['2026-11-11', '2026-11-12', '2026-11-14'],
      );
      final ana = grade.lista.single;
      expect(ana.presencas, {'2026-11-11'});
      expect(ana.bloqueados, {'2026-11-14'});
      expect(grade.calcularPresentes(grade.dias.first), 1);
      expect(grade.calcularPresentes(grade.dias[1]), 0);
    });

    test('dia antes da matrícula fica bloqueado', () async {
      await carregar(montarPull());
      // Matrícula desde 01/10: na semana de 27/09, a quarta 30/09 fica de fora.
      final grade = await consulta.obterGrade(
        turmaId,
        '2026-09-30',
        hoje: hoje,
      );
      final ana = [...grade.lista, ...grade.poucoFrequentes].single;
      expect(ana.bloqueados, {'2026-09-30'});
    });

    test('reposição avulsa tem coluna própria', () async {
      await carregar(montarPull());
      final aulaId = await repositorio.criarReposicaoAvulsa(turmaId, hoje);
      await repositorio.definirPresenca(
        turmaId: turmaId,
        data: hoje,
        alunoId: alunoId,
        presente: true,
        aulaIdAvulsa: aulaId,
      );
      final grade = await consulta.obterGrade(turmaId, hoje, hoje: hoje);
      expect([for (final d in grade.dias) d.chave], contains(aulaId));
      expect(grade.lista.single.presencas, {aulaId});
    });
  });
}
