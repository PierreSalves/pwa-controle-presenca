// Instalação do app (telas 2 e 2b): convite do navegador, iPhone e identidade da academia.
// No navegador usa o evento guardado por web/instalacao.js; fora dele (testes) não faz nada.
export 'instalacao_base.dart';
export 'instalacao_stub.dart'
    if (dart.library.js_interop) 'instalacao_web.dart';
