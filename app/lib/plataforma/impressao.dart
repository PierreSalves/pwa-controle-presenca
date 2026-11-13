// Abre a página impressa numa aba nova (no navegador) para imprimir ou salvar em PDF.
// Fora do navegador (testes) não faz nada.
export 'impressao_stub.dart' if (dart.library.js_interop) 'impressao_web.dart';
