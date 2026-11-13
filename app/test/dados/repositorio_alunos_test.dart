import 'dart:convert';

import 'package:controle_presenca/dados/cliente_api.dart';
import 'package:controle_presenca/dados/repositorio_alunos.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

final _agora = DateTime.utc(2026, 11, 12, 18);

http.Response _json(Object corpo, [int status = 200]) => http.Response(
  jsonEncode(corpo),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Map<String, Object?> _alunoCompleto({String? cpf, String? sexo}) => {
  'aluno': {
    'id': 'a1',
    'codigo': '10A',
    'nome': 'Ana Souza',
    'ativo': 1,
    'data_nascimento': '2012-05-03',
    'sexo': sexo,
    'cpf': cpf,
    'rg': null,
    'telefone': '11 99999-0000',
    'email': null,
    'endereco': null,
    'nome_pai': null,
    'telefone_pai': null,
    'nome_mae': 'Maria',
    'telefone_mae': null,
    'observacoes': null,
  },
  'matriculas': [
    {
      'id': 'm1',
      'turma_id': 't1',
      'turma_nome': 'Adulto',
      'data_inicio': '2026-02-05',
      'data_fim': null,
      'situacao': 'matriculado',
    },
  ],
  'graduacoes': [
    {
      'id': 'g1',
      'faixa': 'Azul',
      'grau': 2,
      'data_graduacao': '2026-06-10',
      'observacoes': null,
    },
  ],
};

void main() {
  late List<http.Request> recebidas;
  late http.Response Function(http.Request) responder;

  RepositorioAlunos criar() => RepositorioAlunos(
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

  test('lista com busca e turmas abertas', () async {
    responder = (_) => _json({
      'alunos': [
        {
          'id': 'a1',
          'codigo': '01',
          'nome': 'Augusto',
          'ativo': 1,
          'turmas': ['Adulto'],
        },
      ],
    });
    final alunos = await criar().buscarAlunos(busca: ' aug ');
    expect(recebidas.single.url.path, '/api/alunos');
    expect(recebidas.single.url.queryParameters, {'busca': 'aug'});
    expect(alunos.single.turmas, ['Adulto']);
  });

  test('cadastro completo com matrículas e graduações', () async {
    responder = (_) => _json(_alunoCompleto(cpf: '111'));
    final aluno = await criar().buscarAluno('a1');
    expect(aluno.codigo, '10A');
    expect(aluno.sensiveis['cpf'], '111');
    expect(aluno.sensiveis['nome_mae'], 'Maria');
    expect(aluno.matriculas.single.dataFim, isNull);
    expect(aluno.graduacoes.single.grau, 2);
  });

  test(
    'salvar novo usa POST; campos vazios vão como null; sexo volta como veio',
    () async {
      responder = (_) => _json(_alunoCompleto(), 201);
      await criar().salvarAluno(
        const DadosAluno(
          codigo: ' 109 ',
          nome: ' Bruno ',
          ativo: true,
          dataNascimento: null,
          sensiveis: {'cpf': '  ', 'telefone': '11 98888-0000', 'sexo': 'M'},
        ),
      );
      final req = recebidas.single;
      expect(req.method, 'POST');
      expect(req.url.path, '/api/alunos');
      final corpo = jsonDecode(req.body) as Map<String, dynamic>;
      expect(corpo['codigo'], '109');
      expect(corpo['nome'], 'Bruno');
      expect(corpo['ativo'], 1);
      expect(corpo['cpf'], isNull);
      expect(corpo['telefone'], '11 98888-0000');
      expect(corpo['sexo'], 'M');
    },
  );

  test('salvar existente usa PUT; código repetido vira ErroApi', () async {
    responder = (_) => _json({'erro': 'codigo_ja_existe'}, 409);
    await expectLater(
      criar().salvarAluno(
        const DadosAluno(
          codigo: '01',
          nome: 'Ana',
          ativo: true,
          dataNascimento: null,
          sensiveis: {},
        ),
        id: 'a1',
      ),
      throwsA(
        isA<ErroApi>().having((e) => e.codigo, 'codigo', 'codigo_ja_existe'),
      ),
    );
    expect(recebidas.single.method, 'PUT');
    expect(recebidas.single.url.path, '/api/alunos/a1');
  });

  test('matricular, graduar e excluir graduação', () async {
    final repositorio = criar();
    responder = (req) => req.method == 'DELETE'
        ? http.Response('', 204)
        : _json(_alunoCompleto(), 201);
    await repositorio.matricular(
      alunoId: 'a1',
      turmaId: 't1',
      dataInicio: '2026-11-12',
    );
    await repositorio.adicionarGraduacao(
      'a1',
      faixa: 'Roxa',
      grau: 0,
      data: '2026-11-12',
    );
    await repositorio.excluirGraduacao('a1', 'g1');
    expect(
      [for (final r in recebidas) '${r.method} ${r.url.path}'],
      [
        'POST /api/matriculas',
        'POST /api/alunos/a1/graduacoes',
        'DELETE /api/alunos/a1/graduacoes/g1',
      ],
    );
    expect(jsonDecode(recebidas[0].body), {
      'aluno_id': 'a1',
      'turma_id': 't1',
      'data_inicio': '2026-11-12',
    });
    expect(jsonDecode(recebidas[1].body), {
      'faixa': 'Roxa',
      'grau': 0,
      'data_graduacao': '2026-11-12',
    });
  });

  test('importação: confere sem gravar e importa com confirmar', () async {
    final repositorio = criar();
    final relatorio = {
      'incompletas': [3],
      'codigos_repetidos': [
        {
          'codigo': '10A',
          'linhas': [1, 2],
        },
      ],
      'codigos_existentes': [
        {'codigo': '03', 'linha': 4, 'nome_cadastrado': 'Lucas'},
      ],
      'nomes_repetidos': [
        {
          'nome': 'Ana',
          'linhas': [1, 5],
        },
      ],
      'pode_importar': false,
    };
    responder = (_) => _json({'relatorio': relatorio, 'importados': 0});
    final conferido = await repositorio.importarAlunos([
      (codigo: '10A', nome: 'Ana'),
    ]);
    expect(conferido.importados, 0);
    expect(conferido.relatorio.podeImportar, isFalse);
    expect(conferido.relatorio.incompletas, [3]);
    expect(conferido.relatorio.codigosRepetidos.single.linhas, [1, 2]);
    expect(
      conferido.relatorio.codigosExistentes.single.nomeCadastrado,
      'Lucas',
    );
    expect(conferido.relatorio.nomesRepetidos.single.nome, 'Ana');
    expect(jsonDecode(recebidas.last.body), {
      'alunos': [
        {'codigo': '10A', 'nome': 'Ana'},
      ],
    });

    responder = (_) => _json({
      'relatorio': {...relatorio, 'pode_importar': true},
      'importados': 1,
    }, 201);
    final importado = await repositorio.importarAlunos([
      (codigo: '10A', nome: 'Ana'),
    ], confirmar: true);
    expect(importado.importados, 1);
    expect((jsonDecode(recebidas.last.body) as Map)['confirmar'], isTrue);
  });

  test(
    'importação com turma envia turma e data e lê a matrícula do relatório',
    () async {
      final repositorio = criar();
      responder = (_) => _json({
        'relatorio': {
          'incompletas': [],
          'codigos_repetidos': [],
          'codigos_existentes': [],
          'nomes_repetidos': [],
          'pode_importar': true,
        },
        'matricula': {
          'turma_id': 't1',
          'turma_nome': 'Adulto',
          'data_inicio': '2026-08-01',
        },
        'importados': 0,
      });
      final conferido = await repositorio.importarAlunos(
        [(codigo: '1', nome: 'Ana')],
        academiaId: 'a1',
        turmaId: 't1',
        dataInicio: '2026-08-01',
      );
      expect(
        recebidas.last.url.path,
        '/api/admin/academias/a1/alunos/importacao',
      );
      expect(jsonDecode(recebidas.last.body), {
        'alunos': [
          {'codigo': '1', 'nome': 'Ana'},
        ],
        'turma_id': 't1',
        'data_inicio': '2026-08-01',
      });
      expect(conferido.matricula?.turmaNome, 'Adulto');
      expect(conferido.matricula?.dataInicio, '2026-08-01');

      responder = (_) => _json({
        'turmas': [
          {'id': 't1', 'nome': 'Adulto'},
        ],
      });
      final turmas = await repositorio.buscarTurmas(academiaId: 'a1');
      expect(recebidas.last.url.path, '/api/admin/academias/a1/turmas');
      expect(turmas.single.nome, 'Adulto');
    },
  );
}
