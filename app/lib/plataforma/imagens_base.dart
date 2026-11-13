import 'dart:typed_data';

class ImagemEscolhida {
  const ImagemEscolhida({required this.bytes, required this.nome});
  final Uint8List bytes;
  final String nome;
}

/// Escolher a imagem do logotipo e gerar os ícones do app (tela 14).
abstract class ServicoImagens {
  /// Abre o seletor de arquivos (PNG ou JPG); null se a pessoa cancelar.
  Future<ImagemEscolhida?> escolherImagem();

  /// Ícone PNG quadrado de [tamanho] px: fundo branco e a imagem inteira dentro da área segura do
  /// ícone redondo. Lança [FormatException] se a imagem não abrir.
  Future<Uint8List> gerarIcone(Uint8List imagem, int tamanho);
}

/// Lado da área segura do ícone: o logotipo inteiro cabe no círculo de 80% do ícone redondo
/// (0,8 ÷ √2 ≈ 0,566).
const proporcaoAreaSegura = 0.56;

enum TipoImagem { png, jpeg }

/// PNG ou JPEG pelos primeiros bytes (mesma conferência da API); null para o resto.
TipoImagem? detectarTipoImagem(Uint8List bytes) {
  bool comecaCom(List<int> assinatura) =>
      bytes.length >= assinatura.length &&
      Iterable<int>.generate(assinatura.length)
          .every((i) => bytes[i] == assinatura[i]);
  if (comecaCom(const [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])) {
    return TipoImagem.png;
  }
  if (comecaCom(const [0xff, 0xd8, 0xff])) return TipoImagem.jpeg;
  return null;
}
