import 'dart:convert';

import 'package:controle_presenca/dados/cliente_api.dart';
import 'package:controle_presenca/dados/repositorio_usuarios.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

final _agora = DateTime.utc(2026, 11, 12, 18);

http.Response _json(Object corpo, [int status = 200]) => http.Response(
  jsonEncode(corpo),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

const _ana = {
  'id': 'u2',
  'nome': 'Ana',
  'email': 'ana@exemplo.com',
  'tipo': 'assistente',
  'ativo': 1,
  'ultimo_login_em': null,
  'turmas': [
    {'id': 't1', 'nome': 'Adulto'},
  ],
};

void main() {
  late List<http.Request> recebidas;
  late http.Response Function(http.Request) responder;

  RepositorioUsuarios criar() => RepositorioUsuarios(
    ClienteApi(
      base: Uri.parse('https://app.test/api/'),
      relogio: () => _agora,
      cliente: MockClient((req) async {
        if (req.url.path.endsWith('/renovar')) {
          return _json({
            'token_acesso': 'T',
            'expira_em': _agora
                .add(const Duration(minutes: 15))
                .toIso8601String(),
          });
        }
        recebidas.add(req);
        return responder(req);
      }),
    ),
  );

  setUp(() {
    recebidas = [];
    responder = (_) => _json({'usuario': _ana});
  });

  test('lista com tipo, ativo e turmas', () async {
    responder = (_) => _json({
      'usuarios': [
        _ana,
        {..._ana, 'id': 'u3', 'nome': 'Bia', 'ativo': 0, 'turmas': []},
      ],
    });
    final usuarios = await criar().buscarUsuarios();
    expect(usuarios.first.turmaIds, {'t1'});
    expect(usuarios.last.ativo, isFalse);
  });

  test('criar, alterar, definir turmas e redefinir senha', () async {
    final repositorio = criar();
    await repositorio.criarUsuario(
      nome: ' Ana ',
      email: ' Ana@Exemplo.com ',
      tipo: 'assistente',
      senha: 'senha-inicial',
      turmaIds: {'t1'},
    );
    await repositorio.alterarUsuario(
      'u2',
      nome: 'Ana',
      email: 'ana@exemplo.com',
      tipo: 'assistente',
      ativo: false,
    );
    await repositorio.definirTurmas('u2', {});
    responder = (_) => http.Response('', 204);
    await repositorio.redefinirSenha('u2', 'nova-senha-1');

    expect(
      [for (final r in recebidas) '${r.method} ${r.url.path}'],
      [
        'POST /api/usuarios',
        'PUT /api/usuarios/u2',
        'PUT /api/usuarios/u2/turmas',
        'POST /api/usuarios/u2/senha',
      ],
    );
    final corpos = [for (final r in recebidas) jsonDecode(r.body)];
    expect(corpos[0], {
      'nome': 'Ana',
      'email': 'ana@exemplo.com',
      'tipo': 'assistente',
      'senha': 'senha-inicial',
      'turma_ids': ['t1'],
    });
    expect((corpos[1] as Map)['ativo'], 0);
    expect(corpos[2], {'turma_ids': []});
    expect(corpos[3], {'senha': 'nova-senha-1'});
  });

  test('e-mail repetido vira ErroApi', () async {
    responder = (_) => _json({'erro': 'email_ja_existe'}, 409);
    await expectLater(
      criar().criarUsuario(
        nome: 'Ana',
        email: 'ana@exemplo.com',
        tipo: 'assistente',
        senha: 'senha-inicial',
        turmaIds: {},
      ),
      throwsA(
        isA<ErroApi>().having((e) => e.codigo, 'codigo', 'email_ja_existe'),
      ),
    );
  });
}
