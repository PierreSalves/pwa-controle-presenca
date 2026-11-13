// Objetos compartilhados pelo app (banco, API, sessão e sincronização), acessíveis pelas telas.
import 'package:flutter/widgets.dart';

import '../dados/banco_local.dart';
import '../dados/cliente_api.dart';
import '../dados/consulta_inicio.dart';
import '../dados/consulta_lancamento.dart';
import '../dados/consulta_relatorios.dart';
import '../dados/repositorio_academia.dart';
import '../dados/repositorio_admin.dart';
import '../dados/repositorio_alunos.dart';
import '../dados/repositorio_conta.dart';
import '../dados/repositorio_turmas.dart';
import '../dados/repositorio_usuarios.dart';
import '../dados/repositorio_presenca.dart';
import '../dados/servico_sincronizacao.dart';
import '../plataforma/imagens.dart';
import '../plataforma/instalacao.dart';
import '../plataforma/impressao.dart' as impressao;
import 'coordenador_sincronizacao.dart';
import 'sessao_app.dart';

class Dependencias {
  Dependencias({
    required this.banco,
    required this.cliente,
    DateTime Function()? relogio,
    bool Function(String html)? abrirImpressao,
    ServicoImagens? imagens,
    ServicoInstalacao? instalacao,
  }) : relogio = relogio ?? DateTime.now,
       imagens = imagens ?? criarServicoImagens(),
       instalacao = instalacao ?? criarServicoInstalacao(),
       abrirImpressao = abrirImpressao ?? impressao.abrirImpressao {
    sessao = SessaoApp(banco, cliente);
    repositorio = RepositorioPresenca(banco, relogio: this.relogio);
    consulta = ConsultaLancamento(banco, repositorio);
    consultaInicio = ConsultaInicio(banco);
    relatorios = ConsultaRelatorios(banco);
    alunos = RepositorioAlunos(cliente);
    turmas = RepositorioTurmas(cliente);
    usuarios = RepositorioUsuarios(cliente);
    admin = RepositorioAdmin(cliente);
    academia = RepositorioAcademia(cliente);
    conta = RepositorioConta(cliente);
    coordenador = CoordenadorSincronizacao(
      ServicoSincronizacao(banco, cliente),
      aoEncerrarSessao: sessao.encerrarLocalmente,
    );
  }

  final BancoLocal banco;
  final ClienteApi cliente;
  final DateTime Function() relogio;

  /// Abre a página impressa (aba nova no navegador); false se o navegador bloqueou.
  final bool Function(String html) abrirImpressao;
  late final SessaoApp sessao;
  late final RepositorioPresenca repositorio;
  late final ConsultaLancamento consulta;
  late final ConsultaInicio consultaInicio;
  late final ConsultaRelatorios relatorios;
  late final RepositorioAlunos alunos;
  late final RepositorioTurmas turmas;
  late final RepositorioUsuarios usuarios;
  late final RepositorioAdmin admin;
  late final RepositorioAcademia academia;
  late final RepositorioConta conta;

  /// Seletor de arquivos e geração dos ícones (canvas do navegador).
  final ServicoImagens imagens;

  /// Convite de instalação, iPhone e identidade da academia no app instalável.
  final ServicoInstalacao instalacao;
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
