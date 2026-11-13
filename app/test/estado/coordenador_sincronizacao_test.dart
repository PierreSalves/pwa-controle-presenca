import 'package:controle_presenca/dados/banco_local.dart';
import 'package:controle_presenca/dados/cliente_api.dart';
import 'package:controle_presenca/dados/servico_sincronizacao.dart';
import 'package:controle_presenca/estado/coordenador_sincronizacao.dart';
import 'package:flutter_test/flutter_test.dart';

import '../dados/apoio.dart';

/// Cliente que falha com a exceção configurada.
class _ClienteComFalha extends ClienteSyncFalso {
  Exception? falha;

  @override
  Future<Map<String, dynamic>> buscarAlteracoesDesde(int cursor) async {
    if (falha != null) throw falha!;
    return super.buscarAlteracoesDesde(cursor);
  }
}

void main() {
  late BancoLocal banco;
  late _ClienteComFalha cliente;
  late CoordenadorSincronizacao coordenador;
  late int sessoesEncerradas;

  setUp(() {
    banco = criarBancoEmMemoria();
    cliente = _ClienteComFalha();
    sessoesEncerradas = 0;
    coordenador = CoordenadorSincronizacao(
      ServicoSincronizacao(banco, cliente),
      aoEncerrarSessao: () async => sessoesEncerradas++,
    );
  });
  tearDown(() async {
    coordenador.dispose();
    await banco.close();
  });

  test('rodada com sucesso deixa online', () async {
    await coordenador.sincronizar();
    expect(coordenador.conexao, ConexaoSync.online);
    expect(cliente.cursoresPedidos, [0]);
  });

  test('sem internet fica offline e tenta de novo depois', () async {
    cliente.falha = const SemConexao();
    await coordenador.sincronizar();
    expect(coordenador.conexao, ConexaoSync.offline);
    cliente.falha = null;
    await coordenador.sincronizar();
    expect(coordenador.conexao, ConexaoSync.online);
  });

  test('sessão encerrada no servidor chama o encerramento local', () async {
    cliente.falha = const SessaoEncerrada();
    await coordenador.sincronizar();
    expect(sessoesEncerradas, 1);
  });

  test(
    'pedido durante uma rodada gera mais uma rodada, não duas paralelas',
    () async {
      final primeira = coordenador.sincronizar();
      final segunda = coordenador.sincronizar();
      final terceira = coordenador.sincronizar();
      await Future.wait([primeira, segunda, terceira]);
      expect(cliente.cursoresPedidos.length, 2);
    },
  );
}
