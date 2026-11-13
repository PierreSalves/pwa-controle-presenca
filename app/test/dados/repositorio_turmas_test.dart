import 'dart:convert';

import 'package:controle_presenca/dados/cliente_api.dart';
import 'package:controle_presenca/dados/repositorio_turmas.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

final _agora = DateTime.utc(2026, 11, 12, 18);

http.Response _json(Object corpo, [int status = 200]) => http.Response(
  jsonEncode(corpo),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Map<String, Object?> _quadro(String inicio, String? fim, {int sabado = 0}) => {
  'id': 'q-$inicio',
  'vigencia_inicio': inicio,
  'vigencia_fim': fim,
  'domingo': 0,
  'segunda': 0,
  'terca': 1,
  'quarta': 1,
  'quinta': 1,
  'sexta': 0,
  'sabado': sabado,
};

void main() {
  late List<http.Request> recebidas;
  late http.Response Function(http.Request) responder;

  RepositorioTurmas criar() => RepositorioTurmas(
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
    responder = (_) => _json({});
  });

  test('turma completa usa o último quadro e as regras', () async {
    responder = (_) => _json({
      'turma': {
        'id': 't1',
        'nome': 'Adulto',
        'descricao': null,
        'frequencia_minima': 75,
        'cabecalho_impressao': 'Prof. Junião',
        'updated_at': '2026-11-01T00:00:00.000Z',
      },
      'quadros': [
        _quadro('2026-01-01', '2026-01-31'),
        _quadro('2026-02-01', null, sabado: 2),
      ],
      'regras': {
        'lista_lancamento': {'percentual_minimo': 40, 'ultimas_aulas': 6},
        'alunos_sumidos': {'semanas': 3},
      },
      'acessos': [
        {'id': 'u1', 'nome': 'Ana', 'tipo': 'assistente'},
      ],
    });
    final turma = await criar().buscarTurma('t1');
    expect(turma.quadroAtual!.vigenciaInicio, '2026-02-01');
    expect(turma.quadroAtual!.dias['sabado'], 2);
    expect(turma.frequenciaMinima, 75);
    expect(turma.percentualMinimoLista, 40);
    expect(turma.ultimasAulasLista, 6);
    expect(turma.semanasSumido, 3);
    expect(turma.acessos.single.nome, 'Ana');
  });

  test('turma sem quadro', () async {
    responder = (_) => _json({
      'turma': {
        'id': 't1',
        'nome': 'Kids',
        'frequencia_minima': null,
        'cabecalho_impressao': null,
      },
      'quadros': [],
      'regras': {
        'lista_lancamento': {'percentual_minimo': 30, 'ultimas_aulas': 8},
        'alunos_sumidos': {'semanas': 4},
      },
      'acessos': [],
    });
    expect((await criar().buscarTurma('t1')).quadroAtual, isNull);
  });

  test('salvar dados, quadro, regras e acessos', () async {
    final repositorio = criar();
    responder = (req) => _json({
      'turma': {'id': 't9'},
    }, req.method == 'POST' ? 201 : 200);
    final id = await repositorio.salvarDados(
      nome: ' Feminino ',
      frequenciaMinima: null,
      cabecalhoImpressao: '  ',
    );
    expect(id, 't9');
    await repositorio.salvarDados(
      id: 't9',
      nome: 'Feminino',
      frequenciaMinima: 70,
      cabecalhoImpressao: 'Prof. X',
    );
    await repositorio.salvarQuadro(
      't9',
      vigenciaInicio: '2026-11-12',
      dias: {'segunda': 1, 'sabado': 2},
    );
    await repositorio.salvarRegras(
      't9',
      percentualMinimo: 50,
      ultimasAulas: 10,
      semanasSumido: 6,
    );
    await repositorio.salvarAcessos('t9', ['u1', 'u2']);

    expect(
      [for (final r in recebidas) '${r.method} ${r.url.path}'],
      [
        'POST /api/turmas',
        'PUT /api/turmas/t9',
        'POST /api/turmas/t9/quadros',
        'PUT /api/turmas/t9/regras',
        'PUT /api/turmas/t9/acessos',
      ],
    );
    List<dynamic> corpos() => [for (final r in recebidas) jsonDecode(r.body)];
    expect(corpos()[0], {
      'nome': 'Feminino',
      'frequencia_minima': null,
      'cabecalho_impressao': null,
    });
    expect(corpos()[2], {
      'vigencia_inicio': '2026-11-12',
      'dias': {'segunda': 1, 'sabado': 2},
    });
    expect(corpos()[3], {
      'lista_lancamento': {'percentual_minimo': 50, 'ultimas_aulas': 10},
      'alunos_sumidos': {'semanas': 6},
    });
    expect(corpos()[4], {
      'usuario_ids': ['u1', 'u2'],
    });
  });

  test('usuários para dar acesso: só os ativos', () async {
    responder = (_) => _json({
      'usuarios': [
        {'id': 'u1', 'nome': 'Ana', 'tipo': 'assistente', 'ativo': 1},
        {'id': 'u2', 'nome': 'Bia', 'tipo': 'assistente', 'ativo': 0},
      ],
    });
    final usuarios = await criar().buscarUsuarios();
    expect([for (final u in usuarios) u.id], ['u1']);
  });

  test('nome repetido vira ErroApi', () async {
    responder = (_) => _json({'erro': 'nome_ja_existe'}, 409);
    await expectLater(
      criar().salvarDados(
        nome: 'Adulto',
        frequenciaMinima: null,
        cabecalhoImpressao: null,
      ),
      throwsA(
        isA<ErroApi>().having((e) => e.codigo, 'codigo', 'nome_ja_existe'),
      ),
    );
  });
}
