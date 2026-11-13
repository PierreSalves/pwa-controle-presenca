// Usuários da academia (tela 11, só o professor): online, direto na API. O usuário não se
// autocadastra: o professor cria com uma senha inicial e passa para a pessoa.
import 'cliente_api.dart';

class UsuarioDaAcademia {
  const UsuarioDaAcademia({
    required this.id,
    required this.nome,
    required this.email,
    required this.tipo,
    required this.ativo,
    required this.turmaIds,
  });

  factory UsuarioDaAcademia.lerJson(Map<String, dynamic> json) =>
      UsuarioDaAcademia(
        id: json['id'] as String,
        nome: json['nome'] as String,
        email: json['email'] as String,
        tipo: json['tipo'] as String,
        ativo: json['ativo'] == 1 || json['ativo'] == true,
        turmaIds: {
          for (final t
              in ((json['turmas'] as List?) ?? const [])
                  .cast<Map<String, dynamic>>())
            t['id'] as String,
        },
      );

  final String id;
  final String nome;
  final String email;

  /// 'professor' ou 'assistente'.
  final String tipo;
  final bool ativo;
  final Set<String> turmaIds;
}

class RepositorioUsuarios {
  RepositorioUsuarios(this._cliente);
  final ClienteApi _cliente;

  UsuarioDaAcademia _lerUsuario(Map<String, dynamic> resposta) =>
      UsuarioDaAcademia.lerJson(resposta['usuario'] as Map<String, dynamic>);

  Future<List<UsuarioDaAcademia>> buscarUsuarios() async {
    final resposta = await _cliente.enviar('GET', 'usuarios');
    return [
      for (final u
          in (resposta['usuarios'] as List).cast<Map<String, dynamic>>())
        UsuarioDaAcademia.lerJson(u),
    ];
  }

  /// E-mail já usado: `email_ja_existe`. Senha com menos de 8 caracteres: `dados_invalidos`.
  Future<UsuarioDaAcademia> criarUsuario({
    required String nome,
    required String email,
    required String tipo,
    required String senha,
    required Set<String> turmaIds,
  }) async => _lerUsuario(
    await _cliente.enviar(
      'POST',
      'usuarios',
      corpo: {
        'nome': nome.trim(),
        'email': email.trim().toLowerCase(),
        'tipo': tipo,
        'senha': senha,
        'turma_ids': turmaIds.toList(),
      },
    ),
  );

  /// Desativar encerra as sessões da pessoa na hora. O professor não muda o próprio tipo nem se
  /// desativa (`nao_pode_alterar_o_proprio_acesso`).
  Future<UsuarioDaAcademia> alterarUsuario(
    String id, {
    required String nome,
    required String email,
    required String tipo,
    required bool ativo,
  }) async => _lerUsuario(
    await _cliente.enviar(
      'PUT',
      'usuarios/$id',
      corpo: {
        'nome': nome.trim(),
        'email': email.trim().toLowerCase(),
        'tipo': tipo,
        'ativo': ativo ? 1 : 0,
      },
    ),
  );

  Future<UsuarioDaAcademia> definirTurmas(
    String id,
    Set<String> turmaIds,
  ) async => _lerUsuario(
    await _cliente.enviar(
      'PUT',
      'usuarios/$id/turmas',
      corpo: {'turma_ids': turmaIds.toList()},
    ),
  );

  /// Nova senha para quem esqueceu; encerra as sessões da pessoa.
  Future<void> redefinirSenha(String id, String senha) =>
      _cliente.enviar('POST', 'usuarios/$id/senha', corpo: {'senha': senha});
}
