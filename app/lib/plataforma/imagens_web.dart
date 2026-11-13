import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'imagens_base.dart';

class _ServicoImagensDoNavegador implements ServicoImagens {
  @override
  Future<ImagemEscolhida?> escolherImagem() {
    final concluido = Completer<ImagemEscolhida?>();
    final campo = web.HTMLInputElement()
      ..type = 'file'
      ..accept = 'image/png,image/jpeg';
    campo.addEventListener(
      'change',
      ((web.Event _) async {
        final arquivo = campo.files?.item(0);
        if (arquivo == null) {
          if (!concluido.isCompleted) concluido.complete(null);
          return;
        }
        final conteudo = await arquivo.arrayBuffer().toDart;
        if (!concluido.isCompleted) {
          concluido.complete(
            ImagemEscolhida(
              bytes: conteudo.toDart.asUint8List(),
              nome: arquivo.name,
            ),
          );
        }
      }).toJS,
    );
    campo.addEventListener(
      'cancel',
      ((web.Event _) {
        if (!concluido.isCompleted) concluido.complete(null);
      }).toJS,
    );
    campo.click();
    return concluido.future;
  }

  @override
  Future<Uint8List> gerarIcone(Uint8List imagem, int tamanho) async {
    final web.ImageBitmap figura;
    try {
      figura = await web.window
          .createImageBitmap(web.Blob([imagem.toJS].toJS))
          .toDart;
    } catch (_) {
      throw const FormatException('A imagem não pôde ser aberta.');
    }
    final canvas = web.HTMLCanvasElement()
      ..width = tamanho
      ..height = tamanho;
    final contexto = canvas.getContext('2d')! as web.CanvasRenderingContext2D;
    contexto
      ..fillStyle = '#FFFFFF'.toJS
      ..fillRect(0, 0, tamanho, tamanho);
    // A imagem inteira, centralizada, dentro da área segura (sem cortar nem distorcer).
    final lado = tamanho * proporcaoAreaSegura;
    final escala =
        lado / (figura.width > figura.height ? figura.width : figura.height);
    final largura = figura.width * escala;
    final altura = figura.height * escala;
    contexto
      ..imageSmoothingQuality = 'high'
      ..drawImage(
        figura,
        (tamanho - largura) / 2,
        (tamanho - altura) / 2,
        largura,
        altura,
      );
    figura.close();
    final endereco = canvas.toDataURL('image/png');
    return base64Decode(endereco.substring(endereco.indexOf(',') + 1));
  }
}

ServicoImagens criarServicoImagens() => _ServicoImagensDoNavegador();
