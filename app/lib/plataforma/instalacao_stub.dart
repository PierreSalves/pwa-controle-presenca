import 'package:flutter/foundation.dart';

import 'instalacao_base.dart';

/// Fora do navegador (testes): nada instalado, sem convite; os testes trocam por uma versão falsa.
class _InstalacaoIndisponivel implements ServicoInstalacao {
  @override
  bool get estaInstalado => false;

  @override
  bool get ehIphone => false;

  @override
  final ValueListenable<bool> conviteDisponivel = ValueNotifier(false);

  @override
  Future<bool> convidar() async => false;

  @override
  void definirIdentidade({
    required String? titulo,
    required Uint8List? icone,
    required String? chave,
  }) {}
}

ServicoInstalacao criarServicoInstalacao() => _InstalacaoIndisponivel();
