// Administrador do sistema (tela 13, só o superadmin): academias e o primeiro professor de cada
// uma. Online, direto na API; nada disso vai para o banco do aparelho.
import 'cliente_api.dart';

class Academia {
  const Academia({
    required this.id,
    required this.nome,
    required this.nomeCurto,
    required this.ativa,
    required this.usuarios,
    required this.alunos,
    required this.turmas,
  });

  factory Academia.lerJson(Map<String, dynamic> json) => Academia(
    id: json['id'] as String,
    nome: json['nome'] as String,
    nomeCurto: json['nome_curto'] as String?,
    ativa: json['ativo'] == 1 || json['ativo'] == true,
    usuarios: (json['usuarios'] as num?)?.toInt() ?? 0,
    alunos: (json['alunos'] as num?)?.toInt() ?? 0,
    turmas: (json['turmas'] as num?)?.toInt() ?? 0,
  );

  final String id;
  final String nome;
  final String? nomeCurto;
  final bool ativa;

  /// Usuários ativos.
  final int usuarios;
  final int alunos;
  final int turmas;
}

class ProfessorDaAcademia {
  const ProfessorDaAcademia({
    required this.id,
    required this.nome,
    required this.email,
    required this.ativo,
    required this.ultimoLoginEm,
  });

  factory ProfessorDaAcademia.lerJson(Map<String, dynamic> json) =>
      ProfessorDaAcademia(
        id: json['id'] as String,
        nome: json['nome'] as String,
        email: json['email'] as String,
        ativo: json['ativo'] == 1 || json['ativo'] == true,
        ultimoLoginEm: switch (json['ultimo_login_em']) {
          final String instante => DateTime.parse(instante),
          _ => null,
        },
      );

  final String id;
  final String nome;
  final String email;
  final bool ativo;

  /// Nulo quando o professor nunca entrou.
  final DateTime? ultimoLoginEm;
}

class RepositorioAdmin {
  RepositorioAdmin(this._cliente);
  final ClienteApi _cliente;

  Future<List<Academia>> buscarAcademias() async {
    final resposta = await _cliente.enviar('GET', 'admin/academias');
    return [
      for (final a
          in (resposta['academias'] as List).cast<Map<String, dynamic>>())
        Academia.lerJson(a),
    ];
  }

  /// Cria a academia e o primeiro professor numa gravação só. E-mail já usado: `email_ja_existe`;
  /// senha com menos de 8 caracteres ou nome curto com mais de 15: `dados_invalidos`.
  Future<Academia> criarAcademia({
    required String nome,
    required String? nomeCurto,
    required String professorNome,
    required String professorEmail,
    required String senha,
  }) async {
    final curto = nomeCurto?.trim();
    final resposta = await _cliente.enviar(
      'POST',
      'admin/academias',
      corpo: {
        'nome': nome.trim(),
        if (curto != null && curto.isNotEmpty) 'nome_curto': curto,
        'professor': {
          'nome': professorNome.trim(),
          'email': professorEmail.trim().toLowerCase(),
          'senha': senha,
        },
      },
    );
    return Academia.lerJson(resposta['academia'] as Map<String, dynamic>);
  }

  /// Professores da academia, inclusive os desativados (a API ordena pelo nome).
  Future<List<ProfessorDaAcademia>> buscarProfessores(String academiaId) async {
    final resposta = await _cliente.enviar(
      'GET',
      'admin/academias/$academiaId/professores',
    );
    return [
      for (final p
          in (resposta['professores'] as List).cast<Map<String, dynamic>>())
        ProfessorDaAcademia.lerJson(p),
    ];
  }

  /// Cria mais um professor na academia. E-mail já usado: `email_ja_existe`.
  Future<void> criarProfessor({
    required String academiaId,
    required String nome,
    required String email,
    required String senha,
  }) => _cliente.enviar(
    'POST',
    'admin/academias/$academiaId/professores',
    corpo: {
      'nome': nome.trim(),
      'email': email.trim().toLowerCase(),
      'senha': senha,
    },
  );

  /// Define a senha de um professor ativo da academia (esqueceu a senha); a API encerra as sessões
  /// dele. Professor desativado ou que não é da academia: `usuario_nao_encontrado`.
  Future<void> redefinirSenhaProfessor({
    required String academiaId,
    required String professorId,
    required String senha,
  }) => _cliente.enviar(
    'POST',
    'admin/academias/$academiaId/professores/$professorId/senha',
    corpo: {'senha': senha},
  );
}
