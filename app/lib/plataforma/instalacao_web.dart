import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

import 'instalacao_base.dart';

/// Evento beforeinstallprompt guardado por web/instalacao.js.
extension type _ConviteDoNavegador(JSObject _) implements JSObject {
  external JSPromise<JSAny?> prompt();
  external JSPromise<_EscolhaDoUsuario> get userChoice;
}

extension type _EscolhaDoUsuario(JSObject _) implements JSObject {
  external String get outcome;
}

class _InstalacaoNoNavegador implements ServicoInstalacao {
  _InstalacaoNoNavegador() {
    _disponivel.value = _obterConvite() != null;
    // O convite pode chegar depois de o app abrir; e some depois de instalado.
    web.window.addEventListener(
      'beforeinstallprompt',
      ((web.Event _) => _disponivel.value = true).toJS,
    );
    web.window.addEventListener(
      'appinstalled',
      ((web.Event _) => _disponivel.value = false).toJS,
    );
  }

  final _disponivel = ValueNotifier<bool>(false);

  _ConviteDoNavegador? _obterConvite() {
    final convite = web.window.getProperty<JSAny?>('conviteInstalacao'.toJS);
    return convite == null || convite.isUndefinedOrNull
        ? null
        : _ConviteDoNavegador(convite as JSObject);
  }

  @override
  bool get estaInstalado =>
      web.window.matchMedia('(display-mode: standalone)').matches ||
      web.window.navigator.getProperty<JSAny?>('standalone'.toJS)?.dartify() ==
          true ||
      web.window.getProperty<JSAny?>('appInstalado'.toJS)?.dartify() == true;

  @override
  bool get ehIphone {
    final agente = web.window.navigator.userAgent;
    // iPad novo se apresenta como Mac, mas tem tela de toque.
    return RegExp('iPhone|iPad|iPod').hasMatch(agente) ||
        (agente.contains('Macintosh') &&
            web.window.navigator.maxTouchPoints > 1);
  }

  @override
  ValueListenable<bool> get conviteDisponivel => _disponivel;

  @override
  Future<bool> convidar() async {
    final convite = _obterConvite();
    if (convite == null) return false;
    await convite.prompt().toDart;
    final escolha = await convite.userChoice.toDart;
    // O mesmo convite não pode ser usado de novo.
    web.window.setProperty('conviteInstalacao'.toJS, null);
    _disponivel.value = false;
    return escolha.outcome == 'accepted';
  }

  @override
  void definirIdentidade({
    required String? titulo,
    required Uint8List? icone,
    required String? chave,
  }) {
    final documento = web.document;
    documento
        .getElementById('titulo-ios')
        ?.setAttribute('content', titulo ?? 'Controle de presença');
    documento
        .getElementById('icone-ios')
        ?.setAttribute(
          'href',
          icone == null
              ? 'icons/Icon-192.png'
              : 'data:image/png;base64,${base64Encode(icone)}',
        );
    // Endereço novo faz o navegador pedir o manifesto de novo (agora com o cookie da academia).
    documento
        .getElementById('manifesto')
        ?.setAttribute(
          'href',
          chave == null
              ? '/api/manifesto'
              : '/api/manifesto?v=${Uri.encodeQueryComponent(chave)}',
        );
  }
}

ServicoInstalacao criarServicoInstalacao() => _InstalacaoNoNavegador();
