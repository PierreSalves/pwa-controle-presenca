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
}
