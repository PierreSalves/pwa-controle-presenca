// Cadastro de alunos (telas 8 e 9): só online, direto na API. Os dados sensíveis (CPF, RG,
// endereço, telefones, responsáveis) ficam só na memória da tela, nunca no banco do aparelho (LGPD).
import 'cliente_api.dart';

class ResumoAluno {
  const ResumoAluno({
    required this.id,
    required this.codigo,
    required this.nome,
    required this.ativo,
    required this.turmas,
    this.faixa,
    this.grau = 0,
  });

  factory ResumoAluno.lerJson(Map<String, dynamic> json) {
    final graduacao = json['graduacao'] as Map<String, dynamic>?;
    return ResumoAluno(
      id: json['id'] as String,
      codigo: json['codigo'] as String,
      nome: json['nome'] as String,
      ativo: json['ativo'] == 1,
      turmas: ((json['turmas'] as List?) ?? const []).cast<String>(),
      faixa: graduacao?['faixa'] as String?,
      grau: (graduacao?['grau'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String codigo;
  final String nome;
  final bool ativo;

  /// Turmas com matrícula aberta.
  final List<String> turmas;

  /// Faixa atual (a graduação mais recente); null sem graduação.
  final String? faixa;
  final int grau;
}

class MatriculaDoCadastro {
  const MatriculaDoCadastro({
    required this.id,
    required this.turmaId,
    required this.turmaNome,
    required this.dataInicio,
    required this.dataFim,
    required this.situacao,
  });

  factory MatriculaDoCadastro.lerJson(Map<String, dynamic> json) =>
      MatriculaDoCadastro(
        id: json['id'] as String,
        turmaId: json['turma_id'] as String,
        turmaNome: json['turma_nome'] as String,
        dataInicio: json['data_inicio'] as String,
        dataFim: json['data_fim'] as String?,
        situacao: json['situacao'] as String,
      );

  final String id;
  final String turmaId;
  final String turmaNome;
  final String dataInicio;
  final String? dataFim;

  /// 'matriculado', 'remanejado' ou 'encerrado'.
  final String situacao;
}

class Graduacao {
  const Graduacao({
    required this.id,
    required this.faixa,
    required this.grau,
    required this.dataGraduacao,
  });

  factory Graduacao.lerJson(Map<String, dynamic> json) => Graduacao(
    id: json['id'] as String,
    faixa: json['faixa'] as String,
    grau: json['grau'] as int,
    dataGraduacao: json['data_graduacao'] as String,
  );

  final String id;
  final String faixa;
  final int grau;
  final String dataGraduacao;
}

/// Campos do cadastro que vão e voltam da API como texto opcional (dados sensíveis). O PUT grava
/// todos: campos sem tela (ex.: sexo) voltam como vieram, para não serem apagados.
const camposSensiveisAluno = [
  'sexo',
  'cpf',
  'rg',
  'telefone',
  'email',
  'endereco',
  'nome_pai',
  'telefone_pai',
  'nome_mae',
  'telefone_mae',
  'observacoes',
];

class AlunoCompleto {
  const AlunoCompleto({
    required this.id,
    required this.codigo,
    required this.nome,
    required this.ativo,
    required this.dataNascimento,
    required this.sensiveis,
    required this.matriculas,
    required this.graduacoes,
  });

  factory AlunoCompleto.lerJson(Map<String, dynamic> json) {
    final aluno = json['aluno'] as Map<String, dynamic>;
    return AlunoCompleto(
      id: aluno['id'] as String,
      codigo: aluno['codigo'] as String,
      nome: aluno['nome'] as String,
      ativo: aluno['ativo'] == 1,
      dataNascimento: aluno['data_nascimento'] as String?,
      sensiveis: {
        for (final campo in camposSensiveisAluno)
          campo: aluno[campo] as String?,
      },
      matriculas: [
        for (final m
            in (json['matriculas'] as List).cast<Map<String, dynamic>>())
          MatriculaDoCadastro.lerJson(m),
      ],
      graduacoes: [
        for (final g
            in (json['graduacoes'] as List).cast<Map<String, dynamic>>())
          Graduacao.lerJson(g),
      ],
    );
  }

  final String id;
  final String codigo;
  final String nome;
  final bool ativo;
  final String? dataNascimento;
  final Map<String, String?> sensiveis;
  final List<MatriculaDoCadastro> matriculas;
  final List<Graduacao> graduacoes;
}

class DadosAluno {
  const DadosAluno({
    required this.codigo,
    required this.nome,
    required this.ativo,
    required this.dataNascimento,
    required this.sensiveis,
  });

  final String codigo;
  final String nome;
  final bool ativo;
  final String? dataNascimento;
  final Map<String, String?> sensiveis;

  Map<String, Object?> converterEmJson() => {
    'codigo': codigo.trim(),
    'nome': nome.trim(),
    'ativo': ativo ? 1 : 0,
    'data_nascimento': dataNascimento,
    for (final campo in camposSensiveisAluno)
      campo: (sensiveis[campo]?.trim().isEmpty ?? true)
          ? null
          : sensiveis[campo]!.trim(),
  };
}

/// Relatório da importação (API: `calcularRelatorioImportacao`). As linhas são as da lista enviada
/// (a partir de 1).
class RelatorioImportacao {
  const RelatorioImportacao({
    required this.incompletas,
    required this.codigosRepetidos,
    required this.codigosExistentes,
    required this.nomesRepetidos,
    required this.podeImportar,
  });

  factory RelatorioImportacao.lerJson(Map<String, dynamic> json) {
    List<int> linhas(Object? v) => (v as List).cast<int>();
    return RelatorioImportacao(
      incompletas: linhas(json['incompletas']),
      codigosRepetidos: [
        for (final c
            in (json['codigos_repetidos'] as List).cast<Map<String, dynamic>>())
          (codigo: c['codigo'] as String, linhas: linhas(c['linhas'])),
      ],
      codigosExistentes: [
        for (final c
            in (json['codigos_existentes'] as List)
                .cast<Map<String, dynamic>>())
          (
            codigo: c['codigo'] as String,
            linha: c['linha'] as int,
            nomeCadastrado: c['nome_cadastrado'] as String,
          ),
      ],
      nomesRepetidos: [
        for (final n
            in (json['nomes_repetidos'] as List).cast<Map<String, dynamic>>())
          (nome: n['nome'] as String, linhas: linhas(n['linhas'])),
      ],
      podeImportar: json['pode_importar'] as bool,
    );
  }

  final List<int> incompletas;
  final List<({String codigo, List<int> linhas})> codigosRepetidos;
  final List<({String codigo, int linha, String nomeCadastrado})>
  codigosExistentes;
  final List<({String nome, List<int> linhas})> nomesRepetidos;
  final bool podeImportar;
}

/// Resposta da importação: relatório, turma e data das matrículas (sem turma, `null`) e quantos
/// alunos foram gravados (0 quando só conferiu ou havia erro).
class ResultadoImportacao {
  const ResultadoImportacao({
    required this.relatorio,
    required this.matricula,
    required this.importados,
  });
  final RelatorioImportacao relatorio;
  final ({String turmaNome, String dataInicio})? matricula;
  final int importados;
}

class TurmaParaMatricula {
  const TurmaParaMatricula({required this.id, required this.nome});
  final String id;
  final String nome;
}

class RepositorioAlunos {
  RepositorioAlunos(this._cliente);
  final ClienteApi _cliente;

  Future<List<ResumoAluno>> buscarAlunos({
    String busca = '',
    bool inativos = false,
  }) async {
    final parametros = Uri(
      queryParameters: {
        if (busca.trim().isNotEmpty) 'busca': busca.trim(),
        if (inativos) 'inativos': '1',
      },
    ).query;
    final resposta = await _cliente.enviar(
      'GET',
      parametros.isEmpty ? 'alunos' : 'alunos?$parametros',
    );
    return [
      for (final a in (resposta['alunos'] as List).cast<Map<String, dynamic>>())
        ResumoAluno.lerJson(a),
    ];
  }

  /// Sem [confirmar], só confere e devolve o relatório. Com [confirmar], grava se não houver
  /// erro e devolve quantos alunos foram importados (0 se o relatório impediu).
  /// Com [academiaId], é a carga inicial feita pelo administrador do sistema (tela 13).
  /// Sem [confirmar], só confere. Com [turmaId] e [dataInicio] (AAAA-MM-DD), matricula todos os
  /// importados na turma; turma de outra academia ou sem acesso: [ErroApi] `turma_nao_encontrada`.
  Future<ResultadoImportacao> importarAlunos(
    List<({String codigo, String nome})> linhas, {
    bool confirmar = false,
    String? academiaId,
    String? turmaId,
    String? dataInicio,
  }) async {
    final resposta = await _cliente.enviar(
      'POST',
      academiaId == null
          ? 'alunos/importacao'
          : 'admin/academias/$academiaId/alunos/importacao',
      corpo: {
        'alunos': [
          for (final l in linhas) {'codigo': l.codigo, 'nome': l.nome},
        ],
        'turma_id': ?turmaId,
        if (turmaId != null) 'data_inicio': dataInicio,
        if (confirmar) 'confirmar': true,
      },
    );
    final matricula = resposta['matricula'] as Map<String, dynamic>?;
    return ResultadoImportacao(
      relatorio: RelatorioImportacao.lerJson(
        resposta['relatorio'] as Map<String, dynamic>,
      ),
      matricula: matricula == null
          ? null
          : (
              turmaNome: matricula['turma_nome'] as String,
              dataInicio: matricula['data_inicio'] as String,
            ),
      importados: (resposta['importados'] as int?) ?? 0,
    );
  }

  Future<String> buscarProximoCodigo() async =>
      (await _cliente.enviar('GET', 'alunos/proximo-codigo'))['codigo']
          as String;

  Future<AlunoCompleto> buscarAluno(String id) async =>
      AlunoCompleto.lerJson(await _cliente.enviar('GET', 'alunos/$id'));

  /// Cria (sem [id]) ou altera o aluno. Lança [ErroApi] `codigo_ja_existe` se o código for repetido.
  Future<AlunoCompleto> salvarAluno(DadosAluno dados, {String? id}) async =>
      AlunoCompleto.lerJson(
        await _cliente.enviar(
          id == null ? 'POST' : 'PUT',
          id == null ? 'alunos' : 'alunos/$id',
          corpo: dados.converterEmJson(),
        ),
      );

  Future<AlunoCompleto> adicionarGraduacao(
    String alunoId, {
    required String faixa,
    required int grau,
    required String data,
  }) async => AlunoCompleto.lerJson(
    await _cliente.enviar(
      'POST',
      'alunos/$alunoId/graduacoes',
      corpo: {'faixa': faixa, 'grau': grau, 'data_graduacao': data},
    ),
  );

  Future<void> excluirGraduacao(String alunoId, String graduacaoId) =>
      _cliente.enviar('DELETE', 'alunos/$alunoId/graduacoes/$graduacaoId');

  /// Turmas em que o usuário pode matricular (o professor vê todas da academia).
  /// Turmas em que o usuário pode matricular. Com [academiaId], as turmas da academia na carga
  /// inicial do administrador do sistema.
  Future<List<TurmaParaMatricula>> buscarTurmas({String? academiaId}) async {
    final resposta = await _cliente.enviar(
      'GET',
      academiaId == null ? 'turmas' : 'admin/academias/$academiaId/turmas',
    );
    return [
      for (final t in (resposta['turmas'] as List).cast<Map<String, dynamic>>())
        TurmaParaMatricula(id: t['id'] as String, nome: t['nome'] as String),
    ];
  }

  /// Lança [ErroApi] `matricula_sobreposta` se já houver matrícula com dias em comum na turma.
  Future<void> matricular({
    required String alunoId,
    required String turmaId,
    required String dataInicio,
  }) => _cliente.enviar(
    'POST',
    'matriculas',
    corpo: {
      'aluno_id': alunoId,
      'turma_id': turmaId,
      'data_inicio': dataInicio,
    },
  );

  Future<void> encerrarMatricula(
    MatriculaDoCadastro matricula,
    String dataFim,
  ) => _cliente.encerrarMatricula(
    matriculaId: matricula.id,
    dataInicio: matricula.dataInicio,
    dataFim: dataFim,
  );
}
