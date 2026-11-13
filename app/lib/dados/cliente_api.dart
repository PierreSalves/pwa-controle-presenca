// Cliente HTTP da API (mesmo domínio do app: /api/...). Guarda o token de acesso só na memória;
// a sessão continua pelo cookie de renovação (httpOnly), que o navegador envia sozinho.
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'servico_sincronizacao.dart';

/// A sessão acabou no servidor (saiu, expirou ou o usuário foi revogado): apagar os dados locais.
class SessaoEncerrada implements Exception {
  const SessaoEncerrada();
}

/// Sem resposta da API (sem internet ou servidor fora do ar): seguir offline.
class SemConexao implements Exception {
  const SemConexao();
}

/// A API respondeu com erro (corpo `{ "erro": "<codigo>" }`).
class ErroApi implements Exception {
  const ErroApi(this.status, this.codigo);
  final int status;
  final String codigo;

  @override
  String toString() => 'ErroApi($status, $codigo)';
}

class UsuarioLogado {
  const UsuarioLogado({
    required this.id,
    required this.nome,
    required this.email,
    required this.tipo,
    required this.tenantId,
  });

  factory UsuarioLogado.lerJson(Map<String, dynamic> json) => UsuarioLogado(
    id: json['id'] as String,
    nome: json['nome'] as String,
    email: json['email'] as String,
    tipo: json['tipo'] as String,
    tenantId: json['tenant_id'] as String?,
  );

  final String id;
  final String nome;
  final String email;

  /// 'superadmin', 'professor' ou 'assistente'.
  final String tipo;
  final String? tenantId;

  Map<String, Object?> converterEmJson() => {
    'id': id,
    'nome': nome,
    'email': email,
    'tipo': tipo,
    'tenant_id': tenantId,
  };
}

class ClienteApi implements ClienteSync {
  ClienteApi({http.Client? cliente, Uri? base, DateTime Function()? relogio})
    : _http = cliente ?? http.Client(),
      _base = base ?? Uri.base.resolve('/api/'),
      _relogio = relogio ?? DateTime.now;

  final http.Client _http;
  final Uri _base;
  final DateTime Function() _relogio;

  String? _tokenAcesso;
  DateTime? _expiraEm;
  Future<void>? _renovacaoEmAndamento;

  /// Margem para renovar o token antes de expirar.
  static const _margemRenovacao = Duration(seconds: 30);
  static const _tempoLimite = Duration(seconds: 20);
  static const _cabecalhoJson = {'content-type': 'application/json'};

  Uri _montarUrl(String caminho) => _base.resolve(caminho);

  Future<http.Response> _enviar(
    Future<http.Response> Function() requisicao,
  ) async {
    try {
      return await requisicao().timeout(_tempoLimite);
    } on http.ClientException {
      throw const SemConexao();
    } on TimeoutException {
      throw const SemConexao();
    }
  }

  Never _lancarErro(http.Response resposta) {
    var codigo = 'erro_desconhecido';
    try {
      final corpo = jsonDecode(resposta.body);
      if (corpo is Map && corpo['erro'] is String) {
        codigo = corpo['erro'] as String;
      }
    } on FormatException {
      // corpo não é JSON: mantém o código genérico
    }
    throw ErroApi(resposta.statusCode, codigo);
  }

  void _guardarToken(Map<String, dynamic> corpo) {
    _tokenAcesso = corpo['token_acesso'] as String;
    _expiraEm = DateTime.parse(corpo['expira_em'] as String);
  }

  /// Login por e-mail e senha. Lança [ErroApi] com `credenciais_invalidas` se não conferir.
  Future<UsuarioLogado> entrar(String email, String senha) async {
    final resposta = await _enviar(
      () => _http.post(
        _montarUrl('autenticacao/entrar'),
        headers: _cabecalhoJson,
        body: jsonEncode({'email': email, 'senha': senha}),
      ),
    );
    if (resposta.statusCode != 200) _lancarErro(resposta);
    final corpo = jsonDecode(resposta.body) as Map<String, dynamic>;
    _guardarToken(corpo);
    return UsuarioLogado.lerJson(corpo['usuario'] as Map<String, dynamic>);
  }

  /// Troca o cookie de renovação por um token de acesso novo. Uma renovação por vez: o servidor
  /// gira o cookie a cada chamada, e duas ao mesmo tempo encerrariam a sessão.
  Future<void> renovarSessao() => _renovacaoEmAndamento ??= _renovar()
      .whenComplete(() => _renovacaoEmAndamento = null);

  Future<void> _renovar() async {
    final resposta = await _enviar(
      () => _http.post(_montarUrl('autenticacao/renovar')),
    );
    if (resposta.statusCode == 401) {
      _tokenAcesso = null;
      throw const SessaoEncerrada();
    }
    if (resposta.statusCode != 200) _lancarErro(resposta);
    _guardarToken(jsonDecode(resposta.body) as Map<String, dynamic>);
  }

  /// Encerra a sessão no servidor. Sem internet, o cookie expira sozinho.
  Future<void> sair() async {
    _tokenAcesso = null;
    _expiraEm = null;
    try {
      await _enviar(() => _http.post(_montarUrl('autenticacao/sair')));
    } on SemConexao {
      // segue: os dados locais são apagados de qualquer jeito
    }
  }

  bool _precisaRenovar() {
    final expira = _expiraEm;
    return _tokenAcesso == null ||
        expira == null ||
        _relogio().toUtc().add(_margemRenovacao).isAfter(expira);
  }

  /// Requisição com o token de acesso; renova antes de expirar e tenta de novo uma vez após 401.
  Future<http.Response> _enviarAutenticado(
    Future<http.Response> Function(Map<String, String> cabecalhos) requisicao,
  ) async {
    if (_precisaRenovar()) await renovarSessao();
    Map<String, String> cabecalhos() => {
      ..._cabecalhoJson,
      'authorization': 'Bearer $_tokenAcesso',
    };
    var resposta = await _enviar(() => requisicao(cabecalhos()));
    if (resposta.statusCode == 401) {
      await renovarSessao();
      resposta = await _enviar(() => requisicao(cabecalhos()));
      if (resposta.statusCode == 401) throw const SessaoEncerrada();
    }
    if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
      _lancarErro(resposta);
    }
    return resposta;
  }

  Future<Map<String, dynamic>> _buscarJson(String caminho) async {
    final resposta = await _enviarAutenticado(
      (cabecalhos) => _http.get(_montarUrl(caminho), headers: cabecalhos),
    );
    return jsonDecode(resposta.body) as Map<String, dynamic>;
  }

  /// Dados do usuário logado e da academia (`GET /api/eu`).
  Future<Map<String, dynamic>> buscarEu() => _buscarJson('eu');

  @override
  Future<Map<String, dynamic>> buscarAlteracoesDesde(int cursor) =>
      _buscarJson('sync/pull?desde=$cursor');

  @override
  Future<Map<String, dynamic>> enviarOperacoes(
    List<Map<String, dynamic>> operacoes,
  ) async {
    final resposta = await _enviarAutenticado(
      (cabecalhos) => _http.post(
        _montarUrl('sync/push'),
        headers: cabecalhos,
        body: jsonEncode({'operacoes': operacoes}),
      ),
    );
    return jsonDecode(resposta.body) as Map<String, dynamic>;
  }
}
