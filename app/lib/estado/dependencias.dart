// Objetos compartilhados pelo app (banco, API, sessão e sincronização), acessíveis pelas telas.
import 'package:flutter/widgets.dart';

import '../dados/banco_local.dart';
import '../dados/cliente_api.dart';
import '../dados/consulta_inicio.dart';
import '../dados/consulta_lancamento.dart';
import '../dados/repositorio_alunos.dart';
import '../dados/repositorio_presenca.dart';
import '../dados/servico_sincronizacao.dart';
import 'coordenador_sincronizacao.dart';
import 'sessao_app.dart';

class Dependencias {
  Dependencias({
    required this.banco,
    required this.cliente,
    DateTime Function()? relogio,
  }) : relogio = relogio ?? DateTime.now {
    sessao = SessaoApp(banco, cliente);
    repositorio = RepositorioPresenca(banco, relogio: this.relogio);
    consulta = ConsultaLancamento(banco, repositorio);
    consultaInicio = ConsultaInicio(banco);
    alunos = RepositorioAlunos(cliente);
    coordenador = CoordenadorSincronizacao(
      ServicoSincronizacao(banco, cliente),
      aoEncerrarSessao: sessao.encerrarLocalmente,
    );
  }

  final BancoLocal banco;
  final ClienteApi cliente;
  final DateTime Function() relogio;
  late final SessaoApp sessao;
  late final RepositorioPresenca repositorio;
  late final ConsultaLancamento consulta;
  late final ConsultaInicio consultaInicio;
  late final RepositorioAlunos alunos;
  late final CoordenadorSincronizacao coordenador;
}

class EscopoDependencias extends InheritedWidget {
  const EscopoDependencias({
    super.key,
    required this.dependencias,
    required super.child,
  });

  final Dependencias dependencias;

  static Dependencias obter(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<EscopoDependencias>()!
      .dependencias;

  @override
  bool updateShouldNotify(EscopoDependencias oldWidget) =>
      dependencias != oldWidget.dependencias;
}
