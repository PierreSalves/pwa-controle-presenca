import 'dart:convert';

import 'package:controle_presenca/dados/banco_local.dart';
import 'package:controle_presenca/dados/cliente_api.dart';
import 'package:controle_presenca/estado/dependencias.dart';
import 'package:controle_presenca/main.dart';
import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';

import 'dados/apoio.dart';

http.Response _json(Object corpo, [int status = 200]) => http.Response(
  jsonEncode(corpo),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// API falsa: login da Carla, pull com a turma de apoio.dart e push aceitando tudo.
class _ApiFalsa {
  final List<List<dynamic>> envios = [];
  final List<Map<String, dynamic>> matriculasEncerradas = [];
  bool online = true;

  Future<http.Response> responder(http.Request req) async {
    if (!online) throw http.ClientException('offline');
    final caminho = req.url.path;
    final token = {
      'token_acesso': 'T',
      'expira_em': agora.add(const Duration(minutes: 15)).toIso8601String(),
    };
    if (caminho.endsWith('/entrar')) {
      final corpo = jsonDecode(req.body) as Map;
      if (corpo['senha'] != 'segredo123') {
        return _json({'erro': 'credenciais_invalidas'}, 401);
      }
      return _json({
        ...token,
        'usuario': {
          'id': 'u1',
          'nome': 'Carla',
          'email': 'carla@exemplo.com',
          'tipo': 'assistente',
          'tenant_id': 't1',
        },
      });
    }
    if (caminho.endsWith('/renovar')) return _json(token);
    if (caminho.endsWith('/eu')) {
      return _json({
        'usuario': {'id': 'u1'},
        'tenant': {'id': 't1', 'nome': 'Academia Teste'},
        'turmas': [],
      });
    }
    if (caminho.endsWith('/sair')) return http.Response('', 204);
    if (caminho.contains('/matriculas/') && req.method == 'PUT') {
      matriculasEncerradas.add(jsonDecode(req.body) as Map<String, dynamic>);
      return _json({'matricula': {}});
    }
    if (caminho.endsWith('/sync/pull')) return _json(montarPull());
    if (caminho.endsWith('/sync/push')) {
      final ops = (jsonDecode(req.body) as Map)['operacoes'] as List;
      envios.add(ops);
      return _json({
        'aceitos': [for (final op in ops) (op as Map)['id']],
        'rejeitados': [],
      });
    }
    return _json({'erro': 'rota_nao_encontrada'}, 404);
  }
}

void main() {
  late BancoLocal banco;
  late _ApiFalsa api;
  late Dependencias dependencias;

  setUp(() {
    banco = BancoLocal(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    api = _ApiFalsa();
    dependencias = Dependencias(
      banco: banco,
      cliente: ClienteApi(
        base: Uri.parse('https://app.test/api/'),
        relogio: () => agora,
        cliente: MockClient(api.responder),
      ),
      relogio: () => agora,
    );
  });

  tearDown(() async {
    dependencias.coordenador.dispose();
    await banco.close();
  });

  /// Deixa o banco e a API falsa responderem (fora do relógio falso) e redesenha.
  Future<void> esperar(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> abrirApp(WidgetTester tester) async {
    await tester.pumpWidget(ControlePresencaApp(dependencias: dependencias));
    await tester.runAsync(dependencias.sessao.iniciar);
    await tester.pumpAndSettle();
  }

  Future<void> entrar(
    WidgetTester tester, {
    String senha = 'segredo123',
  }) async {
    await abrirApp(tester);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'carla@exemplo.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), senha);
    await tester.tap(find.text('Entrar'));
    await esperar(tester);
  }

  /// Do Início, abre o lançamento de hoje (uma turma só: a escolha é pulada).
  Future<void> abrirLancamentoDeHoje(WidgetTester tester) async {
    await entrar(tester);
    await tester.tap(find.text('Lançar presença de hoje'));
    await esperar(tester);
  }

  Future<void> fecharApp(WidgetTester tester) async {
    // Desmonta as telas (para o timer da atualização periódica) antes de fechar o banco.
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  }

  testWidgets('sem usuário gravado abre a tela de entrar', (tester) async {
    await abrirApp(tester);
    expect(find.text('Controle de presença'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    await fecharApp(tester);
  });

  testWidgets('senha errada mostra o aviso', (tester) async {
    await entrar(tester, senha: 'errada');
    expect(find.text('E-mail ou senha incorretos.'), findsOneWidget);
    await fecharApp(tester);
  });

  testWidgets('depois do login abre o Início com o nome da academia', (
    tester,
  ) async {
    await entrar(tester);
    expect(find.text('Academia Teste'), findsOneWidget);
    expect(find.text('Lançar presença de hoje'), findsOneWidget);
    expect(find.text('Suas turmas'), findsOneWidget);
    expect(find.text('Turma $turmaId · qua qui · 1 aluno'), findsOneWidget);
    expect(find.text('Resumo de 2026'), findsOneWidget);
    expect(find.textContaining('Tudo enviado ✓'), findsOneWidget);
    await fecharApp(tester);
  });

  testWidgets('lança a presença de hoje da única turma e marca a aluna', (
    tester,
  ) async {
    await abrirLancamentoDeHoje(tester);
    expect(find.text('Turma $turmaId'), findsOneWidget);
    expect(find.text('qui'), findsOneWidget);
    expect(find.textContaining('(10A) Ana'), findsOneWidget);
    expect(find.textContaining('(11) Bruno'), findsNothing);
    expect(find.text('0 presentes'), findsOneWidget);

    await tester.tap(find.byType(Checkbox));
    await esperar(tester);
    expect(find.text('1 presentes'), findsOneWidget);
    expect(api.envios.expand((e) => e).length, 2); // aula + presença
    expect(find.textContaining('Tudo enviado ✓'), findsOneWidget);
    await fecharApp(tester);
  });

  testWidgets('sem internet a marcação fica aguardando envio', (tester) async {
    await abrirLancamentoDeHoje(tester);
    api.online = false;
    await tester.tap(find.byType(Checkbox));
    await esperar(tester);
    expect(find.text('1 presentes'), findsOneWidget);
    expect(find.textContaining('2 aguardando envio'), findsOneWidget);
    expect(find.textContaining('sem internet'), findsOneWidget);
    await fecharApp(tester);
  });

  testWidgets('cria reposição avulsa e marca a aluna nela', (tester) async {
    await abrirLancamentoDeHoje(tester);
    final botao = find.text('Reposição avulsa (outro dia)');
    await tester.ensureVisible(botao);
    await tester.tap(botao);
    await tester.pumpAndSettle();
    expect(find.text('Turma $turmaId'), findsOneWidget);
    expect(find.text('12/11/2026 (quinta)'), findsOneWidget);

    await tester.tap(find.text('Criar e marcar presenças'));
    await esperar(tester);
    expect(find.text('avulsa'), findsOneWidget);
    expect(find.textContaining('reposição avulsa de 12/11'), findsOneWidget);
    expect(find.text('0 presentes'), findsOneWidget);

    await tester.tap(find.byType(Checkbox));
    await esperar(tester);
    expect(find.text('1 presentes'), findsOneWidget);
    final enviados = api.envios.expand((e) => e).toList();
    final aula = enviados.firstWhere((op) => op['tabela'] == 'aulas');
    expect((aula['registro'] as Map)['tipo'], 'reposicao');
    expect(enviados.where((op) => op['tabela'] == 'presencas'), hasLength(1));
    await fecharApp(tester);
  });

  testWidgets('encerra a matrícula de aluno sumido sugerindo a data', (
    tester,
  ) async {
    await entrar(tester);
    // A Ana está matriculada desde 01/10 e nunca veio: sumida há mais de 4 semanas.
    expect(find.text('1 aluno sem vir há mais de 4 semanas'), findsOneWidget);
    expect(find.text('(10A) Ana · nunca veio'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Encerrar'));
    await tester.pumpAndSettle();
    expect(find.text('Encerrar matrícula'), findsOneWidget);
    expect(
      find.text('01/10/2026'),
      findsOneWidget,
    ); // nunca veio: início da matrícula

    await tester.tap(find.widgetWithText(FilledButton, 'Encerrar'));
    await esperar(tester);
    expect(api.matriculasEncerradas.single, {
      'data_inicio': '2026-10-01',
      'data_fim': '2026-10-01',
      'situacao': 'encerrado',
    });
    expect(
      find.text('Matrícula de Ana encerrada em 01/10/2026.'),
      findsOneWidget,
    );
    await fecharApp(tester);
  });
}
