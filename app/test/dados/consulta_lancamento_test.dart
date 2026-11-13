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
      final dados = await consulta.obterLancamento(turmaId, hoje);
      expect(dados.tipo, TipoAula.regular);
      expect([for (final a in dados.lista) a.nome], ['Ana']);
      expect(dados.lista.single.frequencia.novo, isTrue);
      expect(dados.poucoFrequentes, isEmpty);
      expect(dados.presentes, 0);
    },
  );

  test('dia sem aula no quadro não tem tipo', () async {
    await carregar(montarPull());
    final dados = await consulta.obterLancamento(turmaId, '2026-11-10');
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
      var dados = await consulta.obterLancamento(turmaId, hoje);
      expect(dados.lista, isEmpty);
      expect(dados.poucoFrequentes.single.frequencia.percentual, 0);

      await repositorio.definirPresenca(
        turmaId: turmaId,
        data: hoje,
        alunoId: alunoId,
        presente: true,
      );
      dados = await consulta.obterLancamento(turmaId, hoje);
      expect(dados.lista.single.presente, isTrue);
      expect(dados.poucoFrequentes, isEmpty);
      expect(dados.presentes, 1);
    },
  );

  test('a consulta observada atualiza após a marcação', () async {
    await carregar(montarPull());
    final emissoes = consulta.observarLancamento(turmaId, hoje);
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
}
