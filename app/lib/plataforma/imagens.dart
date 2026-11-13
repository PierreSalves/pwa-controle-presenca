// Escolher a imagem do logotipo e gerar os ícones do app (tela 14). No navegador usa o seletor de
// arquivos e um canvas (sem dependência nova); fora dele (testes) não faz nada.
export 'imagens_base.dart';
export 'imagens_stub.dart' if (dart.library.js_interop) 'imagens_web.dart';
