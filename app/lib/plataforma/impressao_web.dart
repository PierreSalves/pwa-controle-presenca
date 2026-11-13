import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Abre o [html] numa aba nova e chama a impressão quando a página carregar. A página vem de um
/// blob do próprio app (mesma origem, sem script); false quando o navegador bloqueou a aba.
bool abrirImpressao(String html) {
  final blob = web.Blob(
    [html.toJS].toJS,
    web.BlobPropertyBag(type: 'text/html;charset=utf-8'),
  );
  final endereco = web.URL.createObjectURL(blob);
  final aba = web.window.open(endereco, '_blank');
  if (aba == null) {
    web.URL.revokeObjectURL(endereco);
    return false;
  }
  aba.addEventListener(
    'load',
    ((web.Event _) {
      aba.focus();
      aba.print();
    }).toJS,
  );
  return true;
}
