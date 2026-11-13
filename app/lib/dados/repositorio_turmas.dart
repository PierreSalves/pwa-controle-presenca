// Configuração das turmas (tela 10): só online, direto na API. Depois de alterar, o app sincroniza
// para o lançamento usar o quadro e as regras novos.
import 'cliente_api.dart';

const diasDoQuadro = [
  'domingo',
  'segunda',
  'terca',
  'quarta',
  'quinta',
  'sexta',
  'sabado',
];

class ResumoTurma {
  const ResumoTurma({
    required this.id,
    required this.nome,
    required this.alunosMatriculados,
  });
  final String id;
  final String nome;
  final int alunosMatriculados;
}

class QuadroDaTurma {
  const QuadroDaTurma({
    required this.vigenciaInicio,
    required this.vigenciaFim,
    required this.dias,
  });

  /// Dia → 0 sem aula, 1 regular, 2 reposição.
  final Map<String, int> dias;
  final String vigenciaInicio;
  final String? vigenciaFim;
}

class UsuarioDaTurma {
  const UsuarioDaTurma({
    required this.id,
    required this.nome,
    required this.tipo,
  });
  final String id;
  final String nome;

  /// 'professor' ou 'assistente'.
  final String tipo;
}

class TurmaCompleta {
  const TurmaCompleta({
    required this.id,
    required this.nome,
    required this.frequenciaMinima,
    required this.cabecalhoImpressao,
    required this.quadroAtual,
    required this.percentualMinimoLista,
    required this.ultimasAulasLista,
    required this.semanasSumido,
    required this.acessos,
  });

  factory TurmaCompleta.lerJson(Map<String, dynamic> json) {
    final turma = json['turma'] as Map<String, dynamic>;
    final quadros = (json['quadros'] as List).cast<Map<String, dynamic>>();
    final regras = json['regras'] as Map<String, dynamic>;
    final lista = regras['lista_lancamento'] as Map<String, dynamic>;
    final sumidos = regras['alunos_sumidos'] as Map<String, dynamic>;
    // O quadro em vigor é o último (a API ordena pelo início da vigência).
    final ultimo = quadros.isEmpty ? null : quadros.last;
    return TurmaCompleta(
      id: turma['id'] as String,
      nome: turma['nome'] as String,
      frequenciaMinima: turma['frequencia_minima'] as int?,
      cabecalhoImpressao: turma['cabecalho_impressao'] as String?,
      quadroAtual: ultimo == null
          ? null
          : QuadroDaTurma(
              vigenciaInicio: ultimo['vigencia_inicio'] as String,
              vigenciaFim: ultimo['vigencia_fim'] as String?,
              dias: {for (final d in diasDoQuadro) d: ultimo[d] as int},
            ),
      percentualMinimoLista: lista['percentual_minimo'] as int,
      ultimasAulasLista: lista['ultimas_aulas'] as int,
      semanasSumido: sumidos['semanas'] as int,
      acessos: [
        for (final u in (json['acessos'] as List).cast<Map<String, dynamic>>())
          UsuarioDaTurma(
            id: u['id'] as String,
            nome: u['nome'] as String,
            tipo: u['tipo'] as String,
          ),
      ],
    );
  }

  final String id;
  final String nome;
  final int? frequenciaMinima;
  final String? cabecalhoImpressao;
  final QuadroDaTurma? quadroAtual;
  final int percentualMinimoLista;
  final int ultimasAulasLista;
  final int semanasSumido;
  final List<UsuarioDaTurma> acessos;
}

class RepositorioTurmas {
  RepositorioTurmas(this._cliente);
  final ClienteApi _cliente;

  /// Turmas que o usuário pode configurar (o professor vê todas da academia).
  Future<List<ResumoTurma>> buscarTurmas() async {
    final resposta = await _cliente.enviar('GET', 'turmas');
    return [
      for (final t in (resposta['turmas'] as List).cast<Map<String, dynamic>>())
        ResumoTurma(
          id: t['id'] as String,
          nome: t['nome'] as String,
          alunosMatriculados: (t['alunos_matriculados'] as int?) ?? 0,
        ),
    ];
  }

  Future<TurmaCompleta> buscarTurma(String id) async =>
      TurmaCompleta.lerJson(await _cliente.enviar('GET', 'turmas/$id'));

  /// Cria (sem [id]) ou altera os dados da turma e devolve o id. Nome repetido: `nome_ja_existe`.
  Future<String> salvarDados({
    String? id,
    required String nome,
    required int? frequenciaMinima,
    required String? cabecalhoImpressao,
  }) async {
    final resposta = await _cliente.enviar(
      id == null ? 'POST' : 'PUT',
      id == null ? 'turmas' : 'turmas/$id',
      corpo: {
        'nome': nome.trim(),
        'frequencia_minima': frequenciaMinima,
        'cabecalho_impressao': (cabecalhoImpressao?.trim().isEmpty ?? true)
            ? null
            : cabecalhoImpressao!.trim(),
      },
    );
    return (resposta['turma'] as Map<String, dynamic>)['id'] as String;
  }

  /// Novo quadro a partir de [vigenciaInicio] (o anterior termina na véspera; a mesma data corrige
  /// o último). Início anterior ao do último quadro: `vigencia_anterior_ao_quadro_atual`.
  Future<void> salvarQuadro(
    String turmaId, {
    required String vigenciaInicio,
    required Map<String, int> dias,
  }) => _cliente.enviar(
    'POST',
    'turmas/$turmaId/quadros',
    corpo: {'vigencia_inicio': vigenciaInicio, 'dias': dias},
  );

  Future<void> salvarRegras(
    String turmaId, {
    required int percentualMinimo,
    required int ultimasAulas,
    required int semanasSumido,
  }) => _cliente.enviar(
    'PUT',
    'turmas/$turmaId/regras',
    corpo: {
      'lista_lancamento': {
        'percentual_minimo': percentualMinimo,
        'ultimas_aulas': ultimasAulas,
      },
      'alunos_sumidos': {'semanas': semanasSumido},
    },
  );

  /// Lista completa de quem acessa a turma (só o professor pode alterar).
  Future<void> salvarAcessos(String turmaId, List<String> usuarioIds) =>
      _cliente.enviar(
        'PUT',
        'turmas/$turmaId/acessos',
        corpo: {'usuario_ids': usuarioIds},
      );

  /// Professores e assistentes ativos da academia (só o professor consulta).
  Future<List<UsuarioDaTurma>> buscarUsuarios() async {
    final resposta = await _cliente.enviar('GET', 'usuarios');
    return [
      for (final u
          in (resposta['usuarios'] as List).cast<Map<String, dynamic>>())
        if (u['ativo'] == 1 || u['ativo'] == true)
          UsuarioDaTurma(
            id: u['id'] as String,
            nome: u['nome'] as String,
            tipo: u['tipo'] as String,
          ),
    ];
  }
}
