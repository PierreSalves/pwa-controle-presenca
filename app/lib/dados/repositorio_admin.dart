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

/// Usuário ativo da academia (professor ou assistente), visto pelo superadmin.
class UsuarioDaAcademia {
  const UsuarioDaAcademia({
    required this.id,
    required this.nome,
    required this.email,
    required this.tipo,
    required this.ultimoLoginEm,
  });

  factory UsuarioDaAcademia.lerJson(Map<String, dynamic> json) =>
      UsuarioDaAcademia(
        id: json['id'] as String,
        nome: json['nome'] as String,
        email: json['email'] as String,
        tipo: json['tipo'] as String,
        ultimoLoginEm: switch (json['ultimo_login_em']) {
          final String instante => DateTime.parse(instante),
          _ => null,
        },
      );

  final String id;
  final String nome;
  final String email;

  /// 'professor' ou 'assistente'.
  final String tipo;
  final DateTime? ultimoLoginEm;

  bool get ehProfessor => tipo == 'professor';
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

  /// Professores e assistentes ativos da academia (a API ordena pelo nome).
  Future<List<UsuarioDaAcademia>> buscarUsuarios(String academiaId) async {
    final resposta = await _cliente.enviar(
      'GET',
      'admin/academias/$academiaId/usuarios',
    );
    return [
      for (final u
          in (resposta['usuarios'] as List).cast<Map<String, dynamic>>())
        UsuarioDaAcademia.lerJson(u),
    ];
  }

  /// Muda o acesso ('professor' ou 'assistente'); a pessoa sai dos aparelhos. O único professor
  /// não vira assistente: `ultimo_professor`.
  Future<void> definirTipoUsuario({
    required String academiaId,
    required String usuarioId,
    required String tipo,
  }) => _cliente.enviar(
    'PUT',
    'admin/academias/$academiaId/usuarios/$usuarioId/tipo',
    corpo: {'tipo': tipo},
  );

  /// Remove da academia (desativa e tira dos aparelhos). O único professor: `ultimo_professor`.
  Future<void> removerUsuario({
    required String academiaId,
    required String usuarioId,
  }) => _cliente.enviar(
    'DELETE',
    'admin/academias/$academiaId/usuarios/$usuarioId',
  );

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
