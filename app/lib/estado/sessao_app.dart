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
  static const _chaveAcademia = 'academia';
  static const _chaveCabecalho = 'academia_cabecalho';
  static const _chaveIcone = 'academia_icone';
  static const _chaveLogotipo = 'academia_logotipo';
  static const _chaveLogotipoVersao = 'academia_logotipo_versao';

  SituacaoSessao _situacao = SituacaoSessao.carregando;
  SituacaoSessao get situacao => _situacao;

  UsuarioLogado? _usuario;
  UsuarioLogado? get usuario => _usuario;

  /// Nome da academia (cabeçalho do Início enquanto não houver logotipo).
  String? _nomeAcademia;
  String? get nomeAcademia => _nomeAcademia;

  /// Cabeçalho de impressão da academia (ex.: nome do professor), nos relatórios impressos.
  String? _cabecalhoAcademia;
  String? get cabecalhoAcademia => _cabecalhoAcademia;

  /// Ícone 512 px da academia (menu lateral e prévia do ícone) e o logotipo original (relatórios
  /// impressos), guardados no aparelho para aparecer também sem internet; null sem logotipo.
  Uint8List? _iconeAcademia;
  Uint8List? get iconeAcademia => _iconeAcademia;
  Uint8List? _logotipoAcademia;
  Uint8List? get logotipoAcademia => _logotipoAcademia;
  String? _logotipoVersao;

  /// Troca o logotipo guardado (depois do envio na tela 14, sem esperar a próxima conexão).
  Future<void> definirLogotipo({
    required Uint8List? icone,
    required Uint8List? original,
    required String? versao,
  }) async {
    _iconeAcademia = icone;
    _logotipoAcademia = original;
    _logotipoVersao = versao;
    String converter(Uint8List? bytes) =>
        bytes == null ? '' : base64Encode(bytes);
    await _gravarEstado(_chaveIcone, converter(icone));
    await _gravarEstado(_chaveLogotipo, converter(original));
    await _gravarEstado(_chaveLogotipoVersao, versao ?? '');
    notifyListeners();
  }

  /// Baixa o ícone e o logotipo de novo só quando a versão do servidor muda.
  Future<void> _atualizarLogotipo(String? versao) async {
    if (versao == _logotipoVersao) return;
    if (versao == null) {
      await definirLogotipo(icone: null, original: null, versao: null);
      return;
    }
    await definirLogotipo(
      icone: await _cliente.buscarBytes('eu/logotipo/512'),
      original: await _cliente.buscarBytes('eu/logotipo/original'),
      versao: versao,
    );
  }

  Uint8List? _converterEstado(String? base64) =>
      base64 == null || base64.isEmpty ? null : base64Decode(base64);

  Future<void> _gravarEstado(String chave, String valor) => _banco
      .into(_banco.estadoSync)
      .insertOnConflictUpdate(
        EstadoSyncCompanion.insert(chave: chave, valor: valor),
      );

  Future<String?> _obterEstado(String chave) async => (await (_banco.select(
    _banco.estadoSync,
  )..where((e) => e.chave.equals(chave))).getSingleOrNull())?.valor;

  /// Atualiza nome, cabeçalho e logotipo da academia (ex.: depois de salvar na tela 14).
  Future<void> atualizarAcademia() => _atualizarAcademia();

  /// Busca o nome da academia na API e guarda no aparelho; sem internet, mantém o guardado.
  Future<void> _atualizarAcademia() async {
    try {
      final eu = await _cliente.buscarEu();
      final tenant = eu['tenant'] as Map?;
      final nome = tenant?['nome'];
      final cabecalho = tenant?['cabecalho_impressao'] as String?;
      if (cabecalho != _cabecalhoAcademia) {
        _cabecalhoAcademia = cabecalho;
        await _gravarEstado(_chaveCabecalho, cabecalho ?? '');
      }
      if (nome is String && nome != _nomeAcademia) {
        _nomeAcademia = nome;
        await _gravarEstado(_chaveAcademia, nome);
        notifyListeners();
      }
      await _atualizarLogotipo(tenant?['logotipo_versao'] as String?);
    } on SemConexao {
      // segue com o nome guardado
    } on ErroApi {
      // segue com o nome guardado
    }
  }

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
    _nomeAcademia = await _obterEstado(_chaveAcademia);
    final cabecalho = await _obterEstado(_chaveCabecalho);
    _cabecalhoAcademia = cabecalho == null || cabecalho.isEmpty
        ? null
        : cabecalho;
    _iconeAcademia = _converterEstado(await _obterEstado(_chaveIcone));
    _logotipoAcademia = _converterEstado(await _obterEstado(_chaveLogotipo));
    final versao = await _obterEstado(_chaveLogotipoVersao);
    _logotipoVersao = versao == null || versao.isEmpty ? null : versao;
    _definir(
      SituacaoSessao.logado,
      UsuarioLogado.lerJson(jsonDecode(gravado.valor) as Map<String, dynamic>),
    );
    try {
      await _cliente.renovarSessao();
      await _atualizarAcademia();
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
    _nomeAcademia = null;
    _cabecalhoAcademia = null;
    _iconeAcademia = null;
    _logotipoAcademia = null;
    _logotipoVersao = null;
    await _gravarEstado(_chaveUsuario, jsonEncode(usuario.converterEmJson()));
    if (usuario.tenantId != null) {
      try {
        await ServicoSincronizacao(_banco, _cliente).buscarAlteracoes();
        await _atualizarAcademia();
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
    _nomeAcademia = null;
    _cabecalhoAcademia = null;
    _iconeAcademia = null;
    _logotipoAcademia = null;
    _logotipoVersao = null;
    _definir(SituacaoSessao.deslogado, null);
  }
}
