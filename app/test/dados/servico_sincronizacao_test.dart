import 'package:controle_presenca/dados/banco_local.dart';
import 'package:controle_presenca/dados/repositorio_presenca.dart';
import 'package:controle_presenca/dados/servico_sincronizacao.dart';
import 'package:controle_presenca/regras/presenca.dart';
import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

void main() {
  late BancoLocal banco;
  late ClienteSyncFalso cliente;
  late ServicoSincronizacao sync;
  late RepositorioPresenca repositorio;

  setUp(() {
    banco = criarBancoEmMemoria();
    cliente = ClienteSyncFalso();
    sync = ServicoSincronizacao(banco, cliente);
    repositorio = RepositorioPresenca(banco, relogio: () => agora);
  });
  tearDown(() => banco.close());

  Future<void> marcarHoje({bool presente = true}) =>
      repositorio.definirPresenca(
        turmaId: turmaId,
        data: hoje,
        alunoId: alunoId,
        presente: presente,
      );

  group('pull', () {
    test('primeira carga grava os dados e guarda o cursor; a seguinte pede desde o cursor', () async {
      await sync.buscarAlteracoes();
      expect(await banco.select(banco.turmas).get(), hasLength(1));
      expect(await banco.select(banco.alunos).get(), hasLength(2));
      expect(await sync.obterCursor(), 10);

      cliente.respostaPull = (_) => montarPull(cursor: 15);
      await sync.buscarAlteracoes();
      expect(cliente.cursoresPedidos, [0, 10]);
      expect(await sync.obterCursor(), 15);
    });

    test('não sobrescreve presença com alteração pendente; depois do envio, o servidor vale', () async {
      await sync.buscarAlteracoes();
      await marcarHoje();
      final aulaId = gerarIdAulaDoQuadro(turmaId, hoje, TipoAula.regular);
      final local = (await banco.select(banco.presencas).get()).single;

      // Outro aparelho desmarcou o mesmo aluno, com outro id de presença.
      cliente.respostaPull = (_) => montarPull(
        cursor: 20,
        presencas: [
          {
            'id': '0190f5a0-0000-7000-8000-0000000000ff',
            'aula_id': aulaId,
            'aluno_id': alunoId,
            'excluido': 1,
            'updated_at': '2026-11-12T17:00:00.000Z',
            'updated_by': 'outra',
          },
        ],
      );
      await sync.buscarAlteracoes();
      expect((await banco.select(banco.presencas).get()).single.id, local.id);

      await sync.enviarPendentes();
      await sync.buscarAlteracoes();
      final presenca = (await banco.select(banco.presencas).get()).single;
      expect(presenca.id, '0190f5a0-0000-7000-8000-0000000000ff');
      expect(presenca.excluido, 1);
    });

    test('turma retirada some do aparelho, com a outbox dela, e o pull recomeça do zero', () async {
      cliente.respostaPull = (_) => montarPull(turmas: [turmaId, outraTurmaId]);
      await sync.buscarAlteracoes();
      await repositorio.definirPresenca(
        turmaId: outraTurmaId,
        data: hoje,
        alunoId: alunoId,
        presente: true,
      );
      await marcarHoje();
      expect(await banco.select(banco.outbox).get(), hasLength(4));

      cliente.respostaPull = (cursor) =>
          montarPull(cursor: cursor == 0 ? 30 : 25, turmas: [turmaId]);
      await sync.buscarAlteracoes();

      expect(cliente.cursoresPedidos, [0, 10, 0]);
      expect((await banco.select(banco.turmas).get()).map((t) => t.id), [
        turmaId,
      ]);
      expect(
        (await banco.select(banco.aulas).get()).map((a) => a.turmaId).toSet(),
        {turmaId},
      );
      final outbox = await banco.select(banco.outbox).get();
      expect(outbox, hasLength(2));
      expect(await sync.obterCursor(), 30);
    });
  });

  group('push', () {
    test(
      'envia a outbox, apaga os aceitos e marca os recusados com o erro',
      () async {
        await sync.buscarAlteracoes();
        await marcarHoje();
        cliente.respostaPush = (ops) async => {
          'aceitos': [
            for (final op in ops)
              if (op['tabela'] == 'aulas') op['id'],
          ],
          'rejeitados': [
            for (final op in ops)
              if (op['tabela'] == 'presencas')
                {'id': op['id'], 'erro': 'fora_da_matricula'},
          ],
        };

        final resultado = await sync.enviarPendentes();
        expect(resultado.aceitos, 1);
        expect(resultado.recusados, 1);
        final outbox = (await banco.select(banco.outbox).get()).single;
        expect(outbox.tabela, 'presencas');
        expect(outbox.erro, 'fora_da_matricula');
        expect(await repositorio.observarPendentes().first, 0);

        // Item recusado não é reenviado; uma nova marcação do mesmo aluno limpa o erro.
        expect((await sync.enviarPendentes()).aceitos, 0);
        await marcarHoje(presente: false);
        expect(await repositorio.observarPendentes().first, 1);
      },
    );

    test('alteração feita durante o envio continua na outbox', () async {
      await sync.buscarAlteracoes();
      await marcarHoje();
      cliente.respostaPush = (ops) async {
        await marcarHoje(presente: false);
        return {
          'aceitos': [for (final op in ops) op['id']],
          'rejeitados': [],
        };
      };
      await sync.enviarPendentes();
      final restante = (await banco.select(banco.outbox).get()).single;
      expect(restante.tabela, 'presencas');
      expect(restante.payload, contains('"excluido":1'));
    });

    test('sem pendências não chama a API', () async {
      await sync.enviarPendentes();
      expect(cliente.envios, isEmpty);
    });
  });

  test('apagarTudo limpa o banco local, inclusive a outbox (logout)', () async {
    await sync.buscarAlteracoes();
    await marcarHoje();
    await banco.apagarTudo();
    expect(await banco.select(banco.turmas).get(), isEmpty);
    expect(await banco.select(banco.outbox).get(), isEmpty);
    expect(await sync.obterCursor(), 0);
  });
}
