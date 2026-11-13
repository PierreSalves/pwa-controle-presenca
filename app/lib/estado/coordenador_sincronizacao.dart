// Quando sincronizar: logo após cada marcação e a cada poucos segundos com a tela de lançamento
// aberta (para ver as marcações dos outros aparelhos). Uma rodada por vez: push, depois pull.
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../dados/cliente_api.dart';
import '../dados/servico_sincronizacao.dart';

enum ConexaoSync { desconhecida, online, offline }

class CoordenadorSincronizacao extends ChangeNotifier {
  CoordenadorSincronizacao(this._servico, {required this.aoEncerrarSessao});

  final ServicoSincronizacao _servico;

  /// Chamado quando a API diz que a sessão acabou (usuário revogado, por exemplo).
  final Future<void> Function() aoEncerrarSessao;

  static const intervaloLancamento = Duration(seconds: 12);

  ConexaoSync _conexao = ConexaoSync.desconhecida;
  ConexaoSync get conexao => _conexao;

  /// Itens recusados pela API na última rodada (ficam na outbox com o código do erro).
  int _recusados = 0;
  int get recusados => _recusados;

  /// Fim da última rodada completa (push e pull), em UTC.
  DateTime? _ultimaSincronizacao;
  DateTime? get ultimaSincronizacao => _ultimaSincronizacao;

  Future<void>? _rodadaAtual;
  bool _repetirRodada = false;
  Timer? _timer;
  bool _descartado = false;

  /// Push e pull. Se já houver uma rodada, agenda outra para logo depois (pega a marcação nova).
  Future<void> sincronizar() {
    if (_rodadaAtual != null) {
      _repetirRodada = true;
      return _rodadaAtual!;
    }
    return _rodadaAtual = _executarRodadas().whenComplete(
      () => _rodadaAtual = null,
    );
  }

  Future<void> _executarRodadas() async {
    do {
      _repetirRodada = false;
      await _executarRodada();
    } while (_repetirRodada && !_descartado);
  }

  Future<void> _executarRodada() async {
    try {
      final envio = await _servico.enviarPendentes();
      await _servico.buscarAlteracoes();
      _recusados = envio.recusados;
      _ultimaSincronizacao = DateTime.now().toUtc();
      _definirConexao(ConexaoSync.online);
    } on SemConexao {
      _definirConexao(ConexaoSync.offline);
    } on SessaoEncerrada {
      _pararAtualizacaoPeriodica();
      await aoEncerrarSessao();
    } on ErroApi catch (erro) {
      // Erro do servidor: tenta de novo na próxima rodada; os dados continuam na outbox.
      debugPrint('sincronização: $erro');
      _definirConexao(ConexaoSync.offline);
    }
  }

  void _definirConexao(ConexaoSync nova) {
    if (_descartado) return;
    _conexao = nova;
    notifyListeners();
  }

  /// Liga a atualização a cada [intervaloLancamento] (tela de lançamento aberta).
  void iniciarAtualizacaoPeriodica() {
    _timer?.cancel();
    unawaited(sincronizar());
    _timer = Timer.periodic(intervaloLancamento, (_) => sincronizar());
  }

  void pararAtualizacaoPeriodica() => _pararAtualizacaoPeriodica();

  void _pararAtualizacaoPeriodica() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _descartado = true;
    _pararAtualizacaoPeriodica();
    super.dispose();
  }
}
