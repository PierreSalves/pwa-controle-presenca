import 'dart:convert';

import 'package:controle_presenca/dados/banco_local.dart';
import 'package:controle_presenca/dados/repositorio_presenca.dart';
import 'package:controle_presenca/dados/servico_sincronizacao.dart';
import 'package:controle_presenca/regras/presenca.dart';
import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

void main() {
  late BancoLocal banco;
  late RepositorioPresenca repositorio;

  setUp(() async {
    banco = criarBancoEmMemoria();
    repositorio = RepositorioPresenca(banco, relogio: () => agora);
    await ServicoSincronizacao(banco, ClienteSyncFalso()).buscarAlteracoes();
  });
  tearDown(() => banco.close());

  Future<List<OutboxData>> obterOutbox() => banco.select(banco.outbox).get();

  test(
    'marcar grava a aula do quadro (id determinístico), a presença e a outbox',
    () async {
      await repositorio.definirPresenca(
        turmaId: turmaId,
        data: hoje,
        alunoId: alunoId,
        presente: true,
      );

      final aulaId = gerarIdAulaDoQuadro(turmaId, hoje, TipoAula.regular);
      final aulas = await banco.select(banco.aulas).get();
      expect(aulas.single.id, aulaId);
      final presenca = (await banco.select(banco.presencas).get()).single;
      expect(presenca.aulaId, aulaId);
      expect(presenca.excluido, 0);

      final outbox = await obterOutbox();
      expect(
        outbox.map((o) => o.tabela),
        unorderedEquals(['aulas', 'presencas']),
      );
      expect(await repositorio.observarPendentes().first, 2);
    },
  );

  test('desmarcar antes de enviar só atualiza o item da outbox', () async {
    await repositorio.definirPresenca(
      turmaId: turmaId,
      data: hoje,
      alunoId: alunoId,
      presente: true,
    );
    await repositorio.definirPresenca(
      turmaId: turmaId,
      data: hoje,
      alunoId: alunoId,
      presente: false,
    );

    final outbox = await obterOutbox();
    expect(outbox, hasLength(2));
    final itemPresenca = outbox.firstWhere((o) => o.tabela == 'presencas');
    expect((jsonDecode(itemPresenca.payload) as Map)['excluido'], 1);
    expect((await banco.select(banco.presencas).get()).single.excluido, 1);
  });

  test(
    'recusa dia futuro, dia sem aula regular e aluno fora da matrícula',
    () async {
      Future<void> marcar(
        String data,
        String aluno, {
        TipoAula tipo = TipoAula.regular,
      }) => repositorio.definirPresenca(
        turmaId: turmaId,
        data: data,
        alunoId: aluno,
        presente: true,
        tipo: tipo,
      );
      final terca = somarDiasNaData(hoje, -2);
      final sabado = somarDiasNaData(hoje, -5);

      await expectLater(
        marcar(amanha, alunoId),
        throwsA(
          isA<MarcacaoRecusada>().having(
            (e) => e.motivo,
            'motivo',
            RecusaMarcacao.dataFutura,
          ),
        ),
      );
      await expectLater(
        marcar(terca, alunoId),
        throwsA(
          isA<MarcacaoRecusada>().having(
            (e) => e.motivo,
            'motivo',
            RecusaMarcacao.diaSemAulaRegular,
          ),
        ),
      );
      await expectLater(
        marcar(hoje, alunoId, tipo: TipoAula.reposicao),
        throwsA(
          isA<MarcacaoRecusada>().having(
            (e) => e.motivo,
            'motivo',
            RecusaMarcacao.diaSemReposicaoFixa,
          ),
        ),
      );
      await expectLater(
        marcar(hoje, alunoForaId),
        throwsA(
          isA<MarcacaoRecusada>().having(
            (e) => e.motivo,
            'motivo',
            RecusaMarcacao.foraDaMatricula,
          ),
        ),
      );
      // No dia de reposição fixa do quadro (sábado), a reposição é aceita.
      await marcar(sabado, alunoId, tipo: TipoAula.reposicao);
      expect(await obterOutbox(), hasLength(2));
    },
  );

  test('reposição avulsa pode ser em qualquer dia não futuro', () async {
    final terca = somarDiasNaData(hoje, -2);
    final aulaId = await repositorio.criarReposicaoAvulsa(turmaId, terca);
    await repositorio.definirPresenca(
      turmaId: turmaId,
      data: terca,
      alunoId: alunoId,
      presente: true,
      tipo: TipoAula.reposicao,
      aulaIdAvulsa: aulaId,
    );
    final aula = (await banco.select(banco.aulas).get()).single;
    expect(aula.tipo, 'reposicao');
    expect(
      aula.id,
      isNot(gerarIdAulaDoQuadro(turmaId, terca, TipoAula.reposicao)),
    );
    await expectLater(
      repositorio.criarReposicaoAvulsa(turmaId, amanha),
      throwsA(isA<MarcacaoRecusada>()),
    );
  });
}
