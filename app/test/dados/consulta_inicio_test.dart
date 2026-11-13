import 'package:controle_presenca/dados/banco_local.dart';
import 'package:controle_presenca/dados/consulta_inicio.dart';
import 'package:controle_presenca/dados/servico_sincronizacao.dart';
import 'package:controle_presenca/regras/presenca.dart';
import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

Map<String, dynamic> _aula(String data, {String tipo = 'regular'}) => {
  'id': gerarIdAulaDoQuadro(
    turmaId,
    data,
    tipo == 'regular' ? TipoAula.regular : TipoAula.reposicao,
  ),
  'turma_id': turmaId,
  'data_aula': data,
  'tipo': tipo,
  'excluido': 0,
  'updated_at': '2026-11-01T00:00:00.000Z',
  'server_version': 2,
};

Map<String, dynamic> _presenca(String data, String id) => {
  'id': id,
  'aula_id': gerarIdAulaDoQuadro(turmaId, data, TipoAula.regular),
  'aluno_id': alunoId,
  'excluido': 0,
  'updated_at': '2026-11-01T00:00:00.000Z',
  'updated_by': null,
  'server_version': 3,
};

void main() {
  late BancoLocal banco;
  late ConsultaInicio consulta;

  Future<void> carregar(Map<String, dynamic> pull) async {
    final cliente = ClienteSyncFalso()..respostaPull = (_) => pull;
    await ServicoSincronizacao(banco, cliente).buscarAlteracoes();
  }

  setUp(() {
    banco = criarBancoEmMemoria();
    consulta = ConsultaInicio(banco);
  });
  tearDown(() => banco.close());

  test('turmas com dias regulares do quadro e matriculados hoje', () async {
    await carregar(montarPull());
    final dados = await consulta.obterInicio(hoje);
    expect(dados.ano, 2026);
    final turma = dados.turmas.single;
    expect(turma.diasDeAula, ['qua', 'qui']);
    expect(turma.alunos, 1); // o Bruno não tem matrícula
    expect(dados.aulasNoAno, 0);
    expect(dados.frequenciaMediaNoAno, isNull);
  });

  test('resumo do ano, abaixo do mínimo e sumido', () async {
    // Quatro aulas regulares; a Ana veio só na primeira (25%, mínimo da turma 75%).
    await carregar(
      montarPull(
        aulas: [
          _aula('2026-10-07'),
          _aula('2026-10-08'),
          _aula('2026-10-14'),
          _aula('2026-10-15'),
        ],
        presencas: [
          _presenca('2026-10-07', '0190f5a0-0000-7000-8000-0000000000e1'),
        ],
      ),
    );
    final dados = await consulta.obterInicio(hoje);
    expect(dados.aulasNoAno, 4);
    expect(dados.frequenciaMediaNoAno, 25);
    expect(dados.abaixoDoMinimo.single.nome, 'Ana');
    expect(dados.abaixoDoMinimo.single.frequencia.percentual, 25);
    final sumido = dados.sumidos.single;
    expect(sumido.nome, 'Ana');
    expect(sumido.ultimaPresenca, '2026-10-07');
    expect(sumido.dataInicioMatricula, '2026-10-01');
    expect(dados.semanasSumido, 4);
  });

  test('presença recente tira o aluno dos sumidos', () async {
    await carregar(
      montarPull(
        aulas: [_aula('2026-11-11')],
        presencas: [
          _presenca('2026-11-11', '0190f5a0-0000-7000-8000-0000000000e2'),
        ],
      ),
    );
    final dados = await consulta.obterInicio(hoje);
    expect(dados.sumidos, isEmpty);
    expect(dados.abaixoDoMinimo, isEmpty);
    expect(dados.frequenciaMediaNoAno, 100);
  });

  test('frequência do semestre da turma', () async {
    await carregar(
      montarPull(
        aulas: [_aula('2026-06-25'), _aula('2026-11-05'), _aula('2026-11-11')],
        presencas: [
          _presenca('2026-11-11', '0190f5a0-0000-7000-8000-0000000000e3'),
        ],
      ),
    );
    final dados = await consulta.obterFrequenciaSemestre(turmaId, hoje);
    expect(dados.inicio, '2026-07-01');
    expect(dados.fim, hoje);
    expect(dados.minimo, 75);
    final ana = dados.alunos.single;
    expect(ana.frequencia.aulas, 2); // a aula de junho é do outro semestre
    expect(ana.frequencia.percentual, 50);
    expect(ana.frequencia.abaixoDoMinimo, isTrue);
  });

  test('códigos em ordem natural', () {
    final codigos = ['10A', '2', '10', '01', 'B']..sort(compararCodigos);
    expect(codigos, ['01', '2', '10', '10A', 'B']);
  });
}
