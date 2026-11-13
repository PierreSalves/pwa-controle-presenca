import 'package:controle_presenca/dados/banco_local.dart';
import 'package:controle_presenca/dados/servico_sincronizacao.dart';
import 'package:controle_presenca/regras/presenca.dart';
import 'package:drift/native.dart';

const turmaId = '0190f5a0-0000-7000-8000-0000000000a1';
const outraTurmaId = '0190f5a0-0000-7000-8000-0000000000a2';
const alunoId = '0190f5a0-0000-7000-8000-0000000000b1';
const alunoForaId = '0190f5a0-0000-7000-8000-0000000000b2';

/// Quinta-feira, 12/11/2026, 15h em São Paulo.
final agora = DateTime.utc(2026, 11, 12, 18);
final hoje = obterHojeEmSaoPaulo(agora);
final ontem = somarDiasNaData(hoje, -1);
final amanha = somarDiasNaData(hoje, 1);

BancoLocal criarBancoEmMemoria() => BancoLocal(NativeDatabase.memory());

/// Resposta de pull com uma turma: quinta e quarta regulares, sábado reposição;
/// aluno matriculado desde 01/10 e outro sem matrícula.
Map<String, dynamic> montarPull({
  int cursor = 10,
  List<String> turmas = const [turmaId],
  List<Map<String, dynamic>> aulas = const [],
  List<Map<String, dynamic>> presencas = const [],
}) => {
  'cursor': cursor,
  'turmas_permitidas': turmas,
  'turmas': [
    for (final id in turmas)
      {
        'id': id,
        'nome': 'Turma $id',
        'frequencia_minima': 75,
        'cabecalho_impressao': null,
        'excluido': 0,
        'updated_at': '2026-10-01T00:00:00.000Z',
        'server_version': 1,
        'regras': {
          'lista_lancamento': {'percentual_minimo': 30, 'ultimas_aulas': 8},
          'alunos_sumidos': {'semanas': 4},
        },
      },
  ],
  'turma_usuarios': [],
  'quadros_aulas': [
    for (final id in turmas)
      {
        'id': '0190f5a0-0000-7000-8000-00000000c${id.substring(id.length - 3)}',
        'turma_id': id,
        'vigencia_inicio': '2026-01-01',
        'vigencia_fim': null,
        'domingo': 0,
        'segunda': 0,
        'terca': 0,
        'quarta': 1,
        'quinta': 1,
        'sexta': 0,
        'sabado': 2,
        'excluido': 0,
        'updated_at': '2026-01-01T00:00:00.000Z',
        'server_version': 1,
      },
  ],
  'matriculas': [
    for (final id in turmas)
      {
        'id': '0190f5a0-0000-7000-8000-00000000d${id.substring(id.length - 3)}',
        'aluno_id': alunoId,
        'turma_id': id,
        'data_inicio': '2026-10-01',
        'data_fim': null,
        'situacao': 'matriculado',
        'excluido': 0,
        'updated_at': '2026-10-01T00:00:00.000Z',
        'server_version': 1,
      },
  ],
  'alunos': [
    {
      'id': alunoId,
      'codigo': '10A',
      'nome': 'Ana',
      'ativo': 1,
      'excluido': 0,
      'updated_at': '2026-10-01T00:00:00.000Z',
      'server_version': 1,
    },
    {
      'id': alunoForaId,
      'codigo': '11',
      'nome': 'Bruno',
      'ativo': 1,
      'excluido': 0,
      'updated_at': '2026-10-01T00:00:00.000Z',
      'server_version': 1,
    },
  ],
  'aulas': aulas,
  'presencas': presencas,
};

/// Cliente falso: devolve as respostas configuradas e guarda o que recebeu.
class ClienteSyncFalso implements ClienteSync {
  final List<int> cursoresPedidos = [];
  final List<List<Map<String, dynamic>>> envios = [];
  Map<String, dynamic> Function(int cursor) respostaPull = (_) => montarPull();
  Future<Map<String, dynamic>> Function(List<Map<String, dynamic>> ops)?
  respostaPush;

  @override
  Future<Map<String, dynamic>> buscarAlteracoesDesde(int cursor) async {
    cursoresPedidos.add(cursor);
    return respostaPull(cursor);
  }

  @override
  Future<Map<String, dynamic>> enviarOperacoes(
    List<Map<String, dynamic>> operacoes,
  ) async {
    envios.add(operacoes);
    if (respostaPush != null) return respostaPush!(operacoes);
    return {
      'aceitos': [for (final op in operacoes) op['id']],
      'rejeitados': [],
    };
  }
}
