// Navegação da v2: cada item do menu é uma rota com endereço (/alunos, /turmas...), para recarregar
// manter a tela e o voltar do navegador funcionar. No desktop (a partir de 1000 px) o menu lateral
// fica fixo em volta do navegador interno, então continua visível ao abrir um aluno ou uma turma.
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../estado/dependencias.dart';
import '../estado/sessao_app.dart';
import 'componentes.dart';
import 'menu_app.dart';
import 'tela_entrar.dart';
import 'tela_escolher_turma.dart';
import 'tela_inicial.dart';
import 'tela_meus_dados.dart';
import 'tela_relatorios.dart';
import 'tela_alunos.dart';
import 'tela_dados_academia.dart';
import 'tela_turmas.dart';
import 'tela_usuarios.dart';
import 'tema.dart';

abstract final class Rotas {
  static const inicio = '/';
  static const lancar = '/lancar';
  static const relatorios = '/relatorios';
  static const alunos = '/alunos';
  static const turmas = '/turmas';
  static const usuarios = '/usuarios';
  static const academia = '/academia';
  static const meusDados = '/meus-dados';
}

class ItemMenu {
  const ItemMenu(this.rota, this.texto, this.icone);
  final String rota;
  final String texto;
  final IconData icone;
}

/// Itens do menu conforme a permissão (ordem do wireframe 12).
List<ItemMenu> obterItensMenu(SessaoApp sessao) {
  final usuario = sessao.usuario;
  if (usuario?.tipo == 'superadmin') {
    return const [
      ItemMenu(Rotas.inicio, 'Academias', Symbols.apartment),
      ItemMenu(Rotas.meusDados, 'Meus dados e senha', Symbols.lock),
    ];
  }
  if (usuario?.tenantId == null) return const [];
  return [
    const ItemMenu(Rotas.inicio, 'Início', Symbols.home),
    const ItemMenu(Rotas.lancar, 'Lançar presença', Symbols.check_box),
    const ItemMenu(Rotas.relatorios, 'Relatórios', Symbols.bar_chart),
    const ItemMenu(Rotas.alunos, 'Alunos', Symbols.group),
    const ItemMenu(Rotas.turmas, 'Turmas', Symbols.school),
    if (usuario?.tipo == 'professor')
      const ItemMenu(Rotas.usuarios, 'Usuários', Symbols.manage_accounts),
    if (usuario?.tipo == 'professor')
      const ItemMenu(Rotas.academia, 'Dados da academia', Symbols.storefront),
    const ItemMenu(Rotas.meusDados, 'Meus dados e senha', Symbols.lock),
  ];
}

/// Monta a tela da rota, sempre atrás da sessão (sem login, mostra a tela de entrar).
Route<void> gerarRota(RouteSettings settings) => MaterialPageRoute<void>(
  settings: settings,
  builder: (_) => PortaoSessao(rota: settings.name ?? Rotas.inicio),
);

class PortaoSessao extends StatelessWidget {
  const PortaoSessao({super.key, required this.rota});
  final String rota;

  Widget _montarTela(SessaoApp sessao) {
    final permitidas = {for (final i in obterItensMenu(sessao)) i.rota};
    return switch (permitidas.contains(rota) ? rota : Rotas.inicio) {
      Rotas.lancar => const TelaLancarPresenca(),
      Rotas.relatorios => const TelaRelatorios(),
      Rotas.alunos => const TelaAlunos(),
      Rotas.turmas => const TelaTurmas(),
      Rotas.usuarios => const TelaUsuarios(),
      Rotas.academia => const TelaDadosAcademia(),
      Rotas.meusDados => const TelaMeusDados(),
      _ => const TelaInicial(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final sessao = EscopoDependencias.obter(context).sessao;
    return ListenableBuilder(
      listenable: sessao,
      builder: (context, _) => switch (sessao.situacao) {
        SituacaoSessao.carregando => const Scaffold(body: Carregando()),
        SituacaoSessao.deslogado => const TelaEntrar(),
        SituacaoSessao.falhaNoBanco => const Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Este navegador não permitiu guardar os dados no aparelho. '
                'Saia da janela anônima ou use outro navegador.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        // A chave pelo usuário recria as telas a cada login (estado limpo).
        SituacaoSessao.logado => KeyedSubtree(
          key: ValueKey(sessao.usuario?.id),
          child: _montarTela(sessao),
        ),
      },
    );
  }
}

/// Acompanha a rota com endereço em exibição (para destacar o item do menu lateral).
class ObservadorRotas extends NavigatorObserver {
  final rotaAtiva = ValueNotifier<String>(Rotas.inicio);
  final List<Route<dynamic>> _pilha = [];

  void _atualizar() {
    for (final rota in _pilha.reversed) {
      final nome = rota.settings.name;
      if (nome != null) {
        rotaAtiva.value = nome;
        return;
      }
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _pilha.add(route);
    _atualizar();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _pilha.remove(route);
    _atualizar();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _pilha.remove(route);
    _atualizar();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final i = oldRoute == null ? -1 : _pilha.indexOf(oldRoute);
    if (i >= 0 && newRoute != null) {
      _pilha[i] = newRoute;
    } else if (newRoute != null) {
      _pilha.add(newRoute);
    }
    _atualizar();
  }
}

/// Envolve o navegador do app: no desktop, com usuário de academia logado, põe o menu lateral fixo.
class EstruturaComMenu extends StatelessWidget {
  const EstruturaComMenu({
    super.key,
    required this.navegador,
    required this.observador,
    required this.child,
  });

  final GlobalKey<NavigatorState> navegador;
  final ObservadorRotas observador;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final sessao = EscopoDependencias.obter(context).sessao;
    return ListenableBuilder(
      listenable: sessao,
      builder: (context, _) {
        final itens = sessao.situacao == SituacaoSessao.logado
            ? obterItensMenu(sessao)
            : const <ItemMenu>[];
        if (itens.isEmpty || !ehDesktop(context)) return child;
        return Row(
          children: [
            _MenuLateral(
              itens: itens,
              navegador: navegador,
              observador: observador,
              nomeAcademia: sessao.nomeAcademia,
              logotipo: sessao.iconeAcademia,
            ),
            // Contêiner próprio de acessibilidade: a barreira de cada rota bloqueia o que vem antes
            // dela no mesmo contêiner, e sem isto o menu lateral sumiria para o leitor de tela.
            Expanded(child: Semantics(container: true, child: child)),
          ],
        );
      },
    );
  }
}

class _MenuLateral extends StatelessWidget {
  const _MenuLateral({
    required this.itens,
    required this.navegador,
    required this.observador,
    required this.nomeAcademia,
    required this.logotipo,
  });

  final List<ItemMenu> itens;

  /// Ícone 512 px da academia; null mostra só o nome.
  final Uint8List? logotipo;
  final GlobalKey<NavigatorState> navegador;
  final ObservadorRotas observador;
  final String? nomeAcademia;

  void _abrir(String rota) =>
      navegador.currentState?.pushNamedAndRemoveUntil(rota, (_) => false);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CoresV2.menuLateral,
      child: SizedBox(
        width: 232,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
            child: ValueListenableBuilder<String>(
              valueListenable: observador.rotaAtiva,
              builder: (context, ativa, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Com logotipo, o ícone da academia ao lado do nome; sem, só o nome.
                  Container(
                    height: 48,
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: CoresV2.linha, width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (logotipo != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              logotipo!,
                              width: 34,
                              height: 34,
                              excludeFromSemantics: true,
                              filterQuality: FilterQuality.medium,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            nomeAcademia ?? 'Controle de presença',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (final item in itens)
                    _ItemLateral(
                      item: item,
                      ativo: item.rota == ativa,
                      aoTocar: () => _abrir(item.rota),
                    ),
                  const Spacer(),
                  _ItemLateral(
                    item: const ItemMenu('', 'Sair', Symbols.logout),
                    ativo: false,
                    aoTocar: () {
                      final contexto = navegador.currentContext;
                      if (contexto != null) confirmarSaida(contexto);
                    },
                  ),
                  const RodapeCopyright(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemLateral extends StatelessWidget {
  const _ItemLateral({
    required this.item,
    required this.ativo,
    required this.aoTocar,
  });

  final ItemMenu item;
  final bool ativo;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final cor = ativo ? Colors.white : CoresV2.grafite;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Semantics(
        selected: ativo,
        button: true,
        child: Material(
          color: ativo ? CoresV2.tatame : Colors.transparent,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: aoTocar,
            hoverColor: ativo ? null : const Color(0xFFE1E6E1),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    Icon(
                      item.icone,
                      size: 20,
                      color: ativo ? Colors.white : CoresV2.nevoa,
                    ),
                    const SizedBox(width: 10),
                    // Até duas linhas (como "Meus dados e senha" no wireframe D7) antes de cortar.
                    Expanded(
                      child: Text(
                        item.texto,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: cor,
                          fontWeight: ativo ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Rota /lancar: com uma turma só, abre o lançamento direto; com mais, a escolha (tela 3).
class TelaLancarPresenca extends StatelessWidget {
  const TelaLancarPresenca({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: EscopoDependencias.obter(context).consulta.observarTurmas(),
      builder: (context, snapshot) {
        final turmas = snapshot.data;
        if (turmas == null) return const Scaffold(body: Carregando());
        return TelaEscolherTurma(
          titulo: 'Lançar presença',
          turmas: turmas,
          abrirDireto: true,
          abrir: (turma) => abrirTelaLancamento(turma.id),
        );
      },
    );
  }
}
