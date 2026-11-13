// Quem está logado. O usuário fica gravado no banco local para o app abrir sem internet; a sessão
// no servidor continua pelo cookie de renovação. Sair ou ter a sessão encerrada apaga tudo.
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../dados/banco_local.dart';
import '../dados/cliente_api.dart';
import '../dados/servico_sincronizacao.dart';

enum SituacaoSessao { carregando, deslogado, logado, falhaNoBanco }

class SessaoApp extends ChangeNotifier {
  SessaoApp(this._banco, this._cliente);

  final BancoLocal _banco;
  final ClienteApi _cliente;

  static const _chaveUsuario = 'usuario';

  SituacaoSessao _situacao = SituacaoSessao.carregando;
  SituacaoSessao get situacao => _situacao;

  UsuarioLogado? _usuario;
  UsuarioLogado? get usuario => _usuario;

  void _definir(SituacaoSessao situacao, UsuarioLogado? usuario) {
    _situacao = situacao;
    _usuario = usuario;
    notifyListeners();
  }

  /// Abre o app: com usuário gravado, entra direto (mesmo offline) e confere a sessão em seguida.
  Future<void> iniciar() async {
    final EstadoSyncData? gravado;
    try {
      gravado = await (_banco.select(
        _banco.estadoSync,
      )..where((e) => e.chave.equals(_chaveUsuario))).getSingleOrNull();
    } catch (erro) {
      // Navegador sem armazenamento disponível (ex.: janela anônima restrita).
      debugPrint('banco local: $erro');
      _definir(SituacaoSessao.falhaNoBanco, null);
      return;
    }
    if (gravado == null) {
      _definir(SituacaoSessao.deslogado, null);
      return;
    }
    _definir(
      SituacaoSessao.logado,
      UsuarioLogado.lerJson(jsonDecode(gravado.valor) as Map<String, dynamic>),
    );
    try {
      await _cliente.renovarSessao();
    } on SessaoEncerrada {
      await encerrarLocalmente();
    } on SemConexao {
      // offline: segue com os dados locais
    } on ErroApi {
      // servidor com problema: segue com os dados locais
    }
  }

  /// Login. O primeiro carregamento dos dados precisa de internet (lança [SemConexao]).
  Future<void> entrar(String email, String senha) async {
    final usuario = await _cliente.entrar(email.trim(), senha);
    await _banco.apagarTudo();
    await _banco
        .into(_banco.estadoSync)
        .insertOnConflictUpdate(
          EstadoSyncCompanion.insert(
            chave: _chaveUsuario,
            valor: jsonEncode(usuario.converterEmJson()),
          ),
        );
    if (usuario.tenantId != null) {
      try {
        await ServicoSincronizacao(_banco, _cliente).buscarAlteracoes();
      } catch (_) {
        // Sem a primeira carga o app não tem o que mostrar offline: volta ao login.
        await _banco.apagarTudo();
        rethrow;
      }
    }
    _definir(SituacaoSessao.logado, usuario);
  }

  /// Sair: encerra a sessão no servidor e apaga os dados do aparelho.
  Future<void> sair() async {
    await _cliente.sair();
    await encerrarLocalmente();
  }

  /// Apaga os dados locais e volta ao login (sessão encerrada ou revogada no servidor).
  Future<void> encerrarLocalmente() async {
    await _banco.apagarTudo();
    _definir(SituacaoSessao.deslogado, null);
  }
}
