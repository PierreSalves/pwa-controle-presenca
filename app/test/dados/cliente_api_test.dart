import 'dart:convert';

import 'package:controle_presenca/dados/cliente_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

final _base = Uri.parse('https://app.test/api/');
final _agora = DateTime.utc(2026, 11, 12, 18);

http.Response _json(Object corpo, [int status = 200]) => http.Response(
  jsonEncode(corpo),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Map<String, Object?> _token(String valor, {int minutos = 15}) => {
  'token_acesso': valor,
  'expira_em': _agora.add(Duration(minutes: minutos)).toIso8601String(),
};

const _usuario = {
  'id': 'u1',
  'nome': 'Carla',
  'email': 'carla@exemplo.com',
  'tipo': 'assistente',
  'tenant_id': 't1',
};

void main() {
  test('entrar guarda o token e o envia nas chamadas seguintes', () async {
    final autorizacoes = <String?>[];
    final cliente = ClienteApi(
      base: _base,
      relogio: () => _agora,
      cliente: MockClient((req) async {
        if (req.url.path.endsWith('/autenticacao/entrar')) {
          expect(jsonDecode(req.body), {
            'email': 'carla@exemplo.com',
            'senha': 'segredo123',
          });
          return _json({..._token('A'), 'usuario': _usuario});
        }
        autorizacoes.add(req.headers['authorization']);
        return _json({'usuario': _usuario});
      }),
    );
    final usuario = await cliente.entrar('carla@exemplo.com', 'segredo123');
    expect(usuario.nome, 'Carla');
    expect(usuario.tenantId, 't1');
    await cliente.buscarEu();
    expect(autorizacoes, ['Bearer A']);
  });

  test('credenciais erradas viram ErroApi com o código da API', () async {
    final cliente = ClienteApi(
      base: _base,
      cliente: MockClient(
        (_) async => _json({'erro': 'credenciais_invalidas'}, 401),
      ),
    );
    await expectLater(
      cliente.entrar('x@exemplo.com', 'errada'),
      throwsA(
        isA<ErroApi>().having(
          (e) => e.codigo,
          'codigo',
          'credenciais_invalidas',
        ),
      ),
    );
  });

  test('sem token, renova pelo cookie antes de chamar', () async {
    final caminhos = <String>[];
    final cliente = ClienteApi(
      base: _base,
      relogio: () => _agora,
      cliente: MockClient((req) async {
        caminhos.add(req.url.path);
        if (req.url.path.endsWith('/renovar')) return _json(_token('B'));
        expect(req.headers['authorization'], 'Bearer B');
        expect(req.url.queryParameters['desde'], '7');
        return _json({'cursor': 7});
      }),
    );
    await cliente.buscarAlteracoesDesde(7);
    expect(caminhos, ['/api/autenticacao/renovar', '/api/sync/pull']);
  });

  test('401 na chamada renova o token e tenta de novo uma vez', () async {
    var renovacoes = 0;
    var chamadas = 0;
    final cliente = ClienteApi(
      base: _base,
      relogio: () => _agora,
      cliente: MockClient((req) async {
        if (req.url.path.endsWith('/entrar')) {
          return _json({..._token('velho'), 'usuario': _usuario});
        }
        if (req.url.path.endsWith('/renovar')) {
          renovacoes++;
          return _json(_token('novo'));
        }
        chamadas++;
        if (req.headers['authorization'] == 'Bearer velho') {
          return _json({'erro': 'token_invalido'}, 401);
        }
        return _json({'aceitos': [], 'rejeitados': []});
      }),
    );
    await cliente.entrar('carla@exemplo.com', 'segredo123');
    final resposta = await cliente.enviarOperacoes([]);
    expect(resposta['aceitos'], isEmpty);
    expect(renovacoes, 1);
    expect(chamadas, 2);
  });

  test('sessão encerrada no servidor lança SessaoEncerrada', () async {
    final cliente = ClienteApi(
      base: _base,
      cliente: MockClient(
        (_) async => _json({'erro': 'sessao_encerrada'}, 401),
      ),
    );
    await expectLater(
      cliente.buscarAlteracoesDesde(0),
      throwsA(isA<SessaoEncerrada>()),
    );
  });

  test('chamadas simultâneas fazem uma renovação só', () async {
    var renovacoes = 0;
    final cliente = ClienteApi(
      base: _base,
      relogio: () => _agora,
      cliente: MockClient((req) async {
        if (req.url.path.endsWith('/renovar')) {
          renovacoes++;
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return _json(_token('C'));
        }
        return _json({'ok': true});
      }),
    );
    await Future.wait([
      cliente.buscarEu(),
      cliente.buscarAlteracoesDesde(0),
      cliente.enviarOperacoes([]),
    ]);
    expect(renovacoes, 1);
  });

  test('token perto de expirar é renovado antes da chamada', () async {
    var renovacoes = 0;
    final cliente = ClienteApi(
      base: _base,
      relogio: () => _agora,
      cliente: MockClient((req) async {
        if (req.url.path.endsWith('/entrar')) {
          return _json({..._token('curto', minutos: 0), 'usuario': _usuario});
        }
        if (req.url.path.endsWith('/renovar')) {
          renovacoes++;
          return _json(_token('D'));
        }
        expect(req.headers['authorization'], 'Bearer D');
        return _json({'ok': true});
      }),
    );
    await cliente.entrar('carla@exemplo.com', 'segredo123');
    await cliente.buscarEu();
    expect(renovacoes, 1);
  });

  test('encerrar matrícula envia o período com a situação encerrado', () async {
    late http.Request recebida;
    final cliente = ClienteApi(
      base: _base,
      relogio: () => _agora,
      cliente: MockClient((req) async {
        if (req.url.path.endsWith('/renovar')) return _json(_token('E'));
        recebida = req;
        return _json({'matricula': {}});
      }),
    );
    await cliente.encerrarMatricula(
      matriculaId: 'm1',
      dataInicio: '2026-03-01',
      dataFim: '2026-09-02',
    );
    expect(recebida.method, 'PUT');
    expect(recebida.url.path, '/api/matriculas/m1');
    expect(jsonDecode(recebida.body), {
      'data_inicio': '2026-03-01',
      'data_fim': '2026-09-02',
      'situacao': 'encerrado',
    });
  });

  test('falha de rede vira SemConexao', () async {
    final cliente = ClienteApi(
      base: _base,
      cliente: MockClient((_) async => throw http.ClientException('offline')),
    );
    await expectLater(
      cliente.entrar('carla@exemplo.com', 'segredo123'),
      throwsA(isA<SemConexao>()),
    );
  });

  test('sair sem internet não falha', () async {
    final cliente = ClienteApi(
      base: _base,
      cliente: MockClient((_) async => throw http.ClientException('offline')),
    );
    await cliente.sair();
  });
}
