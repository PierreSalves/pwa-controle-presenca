import 'package:flutter/foundation.dart';

/// Instalação do app (tela 2 e 2b): convite do navegador, iPhone e a identidade da academia
/// (título e ícone do iPhone e o manifesto pedido de novo depois do login).
abstract class ServicoInstalacao {
  /// O app já está aberto como instalado (tela cheia, fora do navegador).
  bool get estaInstalado;

  /// iPhone ou iPad: não tem convite automático; a tela 2b explica o passo a passo.
  bool get ehIphone;

  /// O navegador ofereceu o convite de instalação (Android, Chrome/Edge no computador).
  ValueListenable<bool> get conviteDisponivel;

  /// Mostra o convite do navegador; true se a pessoa aceitou.
  Future<bool> convidar();

  /// Usa o nome e o ícone da academia (null volta ao padrão da TghServices). [chave] muda quando
  /// a academia, o nome curto ou o logotipo mudam, para o navegador pedir o manifesto de novo.
  void definirIdentidade({
    required String? titulo,
    required Uint8List? icone,
    required String? chave,
  });
}
