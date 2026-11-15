// Quem está logado. O usuário fica gravado no banco local para o app abrir sem internet; a sessão
// no servidor continua pelo cookie de renovação. Sair ou ter a sessão encerrada apaga tudo, menos
// a academia lembrada (só nome e ícone, para a tela de entrar; docs/telas/wireframes-academia-lembrada.html).
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
  static const _chaveNomeCurto = 'academia_nome_curto';
  static const _chaveConviteDispensado = 'convite_instalacao_dispensado';
  static const _chaveLembradaNome = 'academia_lembrada_nome';
  static const _chaveLembradaIcone = 'academia_lembrada_icone';

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

  /// Nome embaixo do ícone do app instalado (o cadastrado ou o começo do nome).
  String? _nomeCurto;
  String? get nomeCurto => _nomeCurto;

  /// A pessoa tocou em "Agora não" no convite de instalação (tela 2).
  bool _conviteDispensado = false;
  bool get conviteDispensado => _conviteDispensado;

  Future<void> dispensarConvite() async {
    _conviteDispensado = true;
    await _gravarEstado(_chaveConviteDispensado, '1');
    notifyListeners();
  }

  /// Academia do último login neste aparelho (só nome e ícone): a tela de entrar mostra no topo do
  /// cartão. Sobrevive a Sair e à sessão encerrada; some com [esquecerAcademia] ou com o login do
  /// superadmin, e é trocada quando alguém de outra academia entra.
  String? _academiaLembrada;
  String? get academiaLembrada => _academiaLembrada;
  Uint8List? _iconeLembrado;
  Uint8List? get iconeLembrado => _iconeLembrado;

  Future<void> _gravarLembrada() async {
    final nome = _academiaLembrada;
    if (nome == null) return;
    await _gravarEstado(_chaveLembradaNome, nome);
    await _gravarEstado(
      _chaveLembradaIcone,
      _iconeLembrado == null ? '' : base64Encode(_iconeLembrado!),
    );
  }

  /// Passa a lembrar a academia de quem está logado (com os dados atuais dela).
  Future<void> _lembrarAcademia() async {
    final nome = _nomeAcademia;
    if (nome == null) return;
    if (nome == _academiaLembrada && _iconeAcademia == _iconeLembrado) return;
    _academiaLembrada = nome;
    _iconeLembrado = _iconeAcademia;
    await _gravarLembrada();
  }

  /// "Não é desta academia?": esquece o nome e o ícone guardados.
  Future<void> esquecerAcademia() async {
    _academiaLembrada = null;
    _iconeLembrado = null;
    await (_banco.delete(_banco.estadoSync)..where(
          (e) => e.chave.isIn([_chaveLembradaNome, _chaveLembradaIcone]),
        ))
        .go();
    notifyListeners();
  }

  /// Apaga os dados do aparelho, menos a academia lembrada.
  Future<void> _apagarDadosLocais() async {
    await _banco.apagarTudo();
    await _gravarLembrada();
  }

  /// Ícone 512 px da academia (menu lateral e prévia do ícone) e o logotipo original (relatórios
  /// impressos), guardados no aparelho para aparecer também sem internet; null sem logotipo.
  Uint8List? _iconeAcademia;
  Uint8List? get iconeAcademia => _iconeAcademia;
  Uint8List? _logotipoAcademia;
  Uint8List? get logotipoAcademia => _logotipoAcademia;
  String? _logotipoVersao;

  /// Muda a cada logotipo novo (vem da API).
  String? get logotipoVersao => _logotipoVersao;

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
      final nomeCurto = tenant?['nome_curto'] as String?;
      if (nomeCurto != _nomeCurto) {
        _nomeCurto = nomeCurto;
        await _gravarEstado(_chaveNomeCurto, nomeCurto ?? '');
        notifyListeners();
      }
      await _atualizarLogotipo(tenant?['logotipo_versao'] as String?);
      if (tenant != null) await _lembrarAcademia();
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
    _academiaLembrada = await _obterEstado(_chaveLembradaNome);
    _iconeLembrado = _converterEstado(await _obterEstado(_chaveLembradaIcone));
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
    final nomeCurto = await _obterEstado(_chaveNomeCurto);
    _nomeCurto = nomeCurto == null || nomeCurto.isEmpty ? null : nomeCurto;
    _conviteDispensado = await _obterEstado(_chaveConviteDispensado) == '1';
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
    await _apagarDadosLocais();
    _nomeAcademia = null;
    _cabecalhoAcademia = null;
    _iconeAcademia = null;
    _logotipoAcademia = null;
    _nomeCurto = null;
    _conviteDispensado = false;
    _logotipoVersao = null;
    await _gravarEstado(_chaveUsuario, jsonEncode(usuario.converterEmJson()));
    if (usuario.tenantId != null) {
      try {
        await ServicoSincronizacao(_banco, _cliente).buscarAlteracoes();
        await _atualizarAcademia();
      } catch (_) {
        // Sem a primeira carga o app não tem o que mostrar offline: volta ao login.
        await _apagarDadosLocais();
        rethrow;
      }
    } else {
      // O superadmin não pertence a academia: o aparelho não lembra nenhuma.
      await esquecerAcademia();
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
    await _apagarDadosLocais();
    _nomeAcademia = null;
    _cabecalhoAcademia = null;
    _iconeAcademia = null;
    _logotipoAcademia = null;
    _nomeCurto = null;
    _conviteDispensado = false;
    _logotipoVersao = null;
    _definir(SituacaoSessao.deslogado, null);
  }
}
