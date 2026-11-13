import 'dart:typed_data';

import 'imagens_base.dart';

class _ServicoImagensIndisponivel implements ServicoImagens {
  @override
  Future<ImagemEscolhida?> escolherImagem() async => null;

  @override
  Future<Uint8List> gerarIcone(Uint8List imagem, int tamanho) =>
      throw UnsupportedError('Gerar ícones só funciona no navegador.');
}

/// Fora do navegador (testes) não há seletor de arquivos nem canvas.
ServicoImagens criarServicoImagens() => _ServicoImagensIndisponivel();
