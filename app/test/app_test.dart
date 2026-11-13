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
    if (caminho.endsWith('/sair')) return http.Response('', 204);
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

  Future<void> abrirApp(WidgetTester tester) async {
    await tester.pumpWidget(ControlePresencaApp(dependencias: dependencias));
    await tester.runAsync(dependencias.sessao.iniciar);
    await tester.pumpAndSettle();
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
    await abrirApp(tester);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'carla@exemplo.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'errada');
    await tester.tap(find.text('Entrar'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
    expect(find.text('E-mail ou senha incorretos.'), findsOneWidget);
    await fecharApp(tester);
  });

  testWidgets('entra, abre o lançamento da única turma e marca a aluna', (
    tester,
  ) async {
    await abrirApp(tester);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'carla@exemplo.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'segredo123');
    await tester.tap(find.text('Entrar'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();

    // Uma turma só: a escolha de turma é pulada.
    expect(find.text('Turma $turmaId'), findsOneWidget);
    expect(find.text('qui'), findsOneWidget);
    expect(find.textContaining('(10A) Ana'), findsOneWidget);
    expect(find.textContaining('(11) Bruno'), findsNothing);
    expect(find.text('0 presentes'), findsOneWidget);

    await tester.tap(find.byType(Checkbox));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 presentes'), findsOneWidget);
    expect(api.envios.expand((e) => e).length, 2); // aula + presença
    expect(find.text('Tudo enviado ✓'), findsOneWidget);
    await fecharApp(tester);
  });

  testWidgets('sem internet a marcação fica aguardando envio', (tester) async {
    await abrirApp(tester);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'carla@exemplo.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'segredo123');
    await tester.tap(find.text('Entrar'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();

    api.online = false;
    await tester.tap(find.byType(Checkbox));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 presentes'), findsOneWidget);
    expect(find.textContaining('2 aguardando envio'), findsOneWidget);
    expect(find.textContaining('sem internet'), findsOneWidget);
    await fecharApp(tester);
  });
}
