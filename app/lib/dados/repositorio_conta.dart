// Conta de quem está logado (tela 12, Meus dados e senha): online, direto na API.
import 'cliente_api.dart';

class RepositorioConta {
  RepositorioConta(this._cliente);
  final ClienteApi _cliente;

  /// Troca a própria senha; os outros aparelhos da pessoa saem da conta (este continua).
  /// Senha atual errada: `senha_atual_incorreta`; nova com menos de 8: `dados_invalidos`.
  Future<void> trocarSenha({
    required String senhaAtual,
    required String senhaNova,
  }) async {
    await _cliente.enviar(
      'POST',
      'eu/senha',
      corpo: {'senha_atual': senhaAtual, 'senha_nova': senhaNova},
    );
  }
}
