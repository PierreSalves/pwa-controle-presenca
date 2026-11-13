// Tela 7 — Relatórios (docs/telas/wireframes-relatorios.html). Celular: escolhe turma, período e
// relatório e abre o resultado numa tela própria (7a–7d). Desktop (D5, D6): filtros no topo e o
// relatório logo abaixo. Tudo calculado no aparelho a partir das presenças (funciona offline).
import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../dados/consulta_relatorios.dart';
import '../estado/dependencias.dart';
import 'componentes.dart';
import 'relatorios/montar_relatorio.dart';
import 'relatorios/partes_relatorio.dart';
import 'relatorios/tabela_relatorio.dart';
import 'relatorios/tela_resultado_relatorio.dart';
import 'tema.dart';

IconData obterIconeDoRelatorio(TipoRelatorio tipo) => switch (tipo) {
  TipoRelatorio.semanal => Symbols.calendar_view_week,
  TipoRelatorio.mensal => Symbols.calendar_view_month,
  TipoRelatorio.anual => Symbols.calendar_month,
  TipoRelatorio.porAluno => Symbols.person,
  TipoRelatorio.graduacao => Symbols.workspace_premium,
};

class TelaRelatorios extends StatefulWidget {
  const TelaRelatorios({super.key});

  @override
  State<TelaRelatorios> createState() => _TelaRelatoriosState();
}

class _TelaRelatoriosState extends State<TelaRelatorios> {
  late final Dependencias _dependencias;
  late final String _hoje;
  List<({String id, String nome})>? _turmas;
  String? _turmaId;
  late String _inicio;
  late String _fim;
  AtalhoPeriodo? _atalho = AtalhoPeriodo.mes;
  TipoRelatorio _tipo = TipoRelatorio.semanal;
  String? _alunoId;
  final _carregadas = <String, Future<TurmaDoRelatorio>>{};
  bool _iniciado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciado) return;
    _iniciado = true;
    _dependencias = EscopoDependencias.obter(context);
    _hoje = obterHoje(context);
    final periodo = calcularPeriodoDoAtalho(AtalhoPeriodo.mes, _hoje);
    _inicio = periodo.inicio;
    _fim = periodo.fim;
    unawaited(_carregarTurmas());
  }

  Future<void> _carregarTurmas() async {
    final turmas = await _dependencias.relatorios.obterTurmas();
    if (!mounted) return;
    setState(() {
      _turmas = [for (final t in turmas) (id: t.id, nome: t.nome)];
      _turmaId = turmas.isEmpty ? null : turmas.first.id;
    });
  }

  Future<TurmaDoRelatorio> _obterTurma(String id) =>
      _carregadas[id] ??= _dependencias.relatorios.obterTurma(id);

  void _definirAtalho(AtalhoPeriodo atalho) {
    final periodo = calcularPeriodoDoAtalho(atalho, _hoje);
    setState(() {
      _atalho = atalho;
      _inicio = periodo.inicio;
      _fim = periodo.fim;
    });
  }

  void _definirPeriodo({String? inicio, String? fim}) {
    final novoInicio = inicio ?? _inicio;
    final novoFim = fim ?? _fim;
    // De depois do Até: o outro campo acompanha.
    final ajustado = inicio != null
        ? ajustarPeriodo(novoInicio, novoFim)
        : (
            inicio: novoInicio.compareTo(novoFim) > 0 ? novoFim : novoInicio,
            fim: novoFim,
          );
    setState(() {
      _atalho = null;
      _inicio = ajustado.inicio;
      _fim = ajustado.fim;
    });
  }

  Future<void> _abrirResultado(TipoRelatorio tipo) async {
    final turmaId = _turmaId;
    if (turmaId == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TelaResultadoRelatorio(
          turma: _obterTurma(turmaId),
          tipo: tipo,
          inicio: _inicio,
          fim: _fim,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final turmas = _turmas;
    if (turmas == null) return const Scaffold(body: Carregando());
    if (turmas.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: !ehDesktop(context),
          title: const Text('Relatórios'),
          centerTitle: true,
        ),
        body: const Center(child: Text('Você ainda não tem turmas.')),
      );
    }
    return ehDesktop(context)
        ? _montarDesktop(context, turmas)
        : _montarCelular(context, turmas);
  }

  List<Widget> _montarFiltrosDoPeriodo() => [
    Row(
      children: [
        Expanded(
          child: CampoData(
            rotulo: 'De',
            data: _inicio,
            aoEscolher: (d) => _definirPeriodo(inicio: d),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: CampoData(
            rotulo: 'Até',
            data: _fim,
            aoEscolher: (d) => _definirPeriodo(fim: d),
          ),
        ),
      ],
    ),
    const SizedBox(height: 8),
    EscolhaEmPilulas<AtalhoPeriodo>(
      opcoes: AtalhoPeriodo.values,
      escolhida: _atalho,
      rotular: (a) => a.rotulo,
      aoEscolher: _definirAtalho,
    ),
  ];

  Widget _montarCelular(
    BuildContext context,
    List<({String id, String nome})> turmas,
  ) {
    return Scaffold(
      appBar: AppBar(title: const Text('Relatórios'), centerTitle: true),
      body: LarguraCelular(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            EscolhaTurma(
              turmas: turmas,
              turmaId: _turmaId,
              aoEscolher: (id) => setState(() => _turmaId = id),
            ),
            const SizedBox(height: 12),
            ..._montarFiltrosDoPeriodo(),
            const SizedBox(height: 12),
            Cartao(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Column(
                children: [
                  for (final tipo in TipoRelatorio.values) ...[
                    if (tipo != TipoRelatorio.values.first)
                      const Divider(height: 1, indent: 64),
                    ListTile(
                      minTileHeight: 56,
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: CoresV2.tatameClaro,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          obterIconeDoRelatorio(tipo),
                          color: CoresV2.tatame,
                        ),
                      ),
                      title: Text(
                        tipo.titulo,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(tipo.descricao),
                      trailing: const Icon(Symbols.chevron_right),
                      onTap: () => _abrirResultado(tipo),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _montarDesktop(
    BuildContext context,
    List<({String id, String nome})> turmas,
  ) {
    final turmaId = _turmaId!;
    return Scaffold(
      body: FutureBuilder<TurmaDoRelatorio>(
        future: _obterTurma(turmaId),
        builder: (context, snapshot) {
          final turma = snapshot.data;
          final alunosDoPeriodo =
              turma?.base.obterAlunosEntre(_inicio, _fim) ?? const [];
          final aluno = alunosDoPeriodo
              .where((a) => a.id == _alunoId)
              .firstOrNull;
          final relatorio = turma == null
              ? null
              : montarRelatorio(
                  turma,
                  _tipo,
                  inicio: _inicio,
                  fim: _fim,
                  hoje: _hoje,
                  aluno: aluno,
                );
          return ListView(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Relatórios',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  BotaoPrincipal(
                    rotulo: 'Imprimir / PDF',
                    icone: Symbols.print,
                    aoTocar: turma == null || relatorio == null
                        ? null
                        : () => imprimirRelatorio(
                            context,
                            turma,
                            montarRelatorio(
                              turma,
                              _tipo,
                              inicio: _inicio,
                              fim: _fim,
                              hoje: _hoje,
                              aluno: aluno,
                            )!,
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 220,
                    child: EscolhaTurma(
                      turmas: turmas,
                      turmaId: turmaId,
                      aoEscolher: (id) => setState(() => _turmaId = id),
                    ),
                  ),
                  SizedBox(
                    width: 170,
                    child: CampoData(
                      rotulo: 'De',
                      data: _inicio,
                      aoEscolher: (d) => _definirPeriodo(inicio: d),
                    ),
                  ),
                  SizedBox(
                    width: 170,
                    child: CampoData(
                      rotulo: 'Até',
                      data: _fim,
                      aoEscolher: (d) => _definirPeriodo(fim: d),
                    ),
                  ),
                  EscolhaEmPilulas<AtalhoPeriodo>(
                    opcoes: AtalhoPeriodo.values,
                    escolhida: _atalho,
                    rotular: (a) => a.rotulo,
                    aoEscolher: _definirAtalho,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              EscolhaEmPilulas<TipoRelatorio>(
                opcoes: TipoRelatorio.values,
                escolhida: _tipo,
                rotular: (t) => t.rotuloCurto,
                icone: obterIconeDoRelatorio,
                aoEscolher: (t) => setState(() => _tipo = t),
              ),
              const SizedBox(height: 16),
              if (turma == null)
                const Padding(padding: EdgeInsets.all(24), child: Carregando())
              else ...[
                if (_tipo == TipoRelatorio.porAluno) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 380,
                      child: EscolhaAluno(
                        alunos: alunosDoPeriodo,
                        alunoId: _alunoId,
                        aoEscolher: (id) => setState(() => _alunoId = id),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  relatorio?.periodo ?? '',
                  style: const TextStyle(color: CoresV2.nevoa, fontSize: 13),
                ),
                const SizedBox(height: 8),
                if (relatorio == null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Escolha o aluno para ver as aulas do período.',
                    ),
                  )
                else
                  TabelaRelatorio(
                    relatorio: relatorio,
                    aoTocarLinha: _tipo == TipoRelatorio.mensal
                        ? (i) => setState(() {
                            _tipo = TipoRelatorio.porAluno;
                            _alunoId = alunosDoPeriodo[i].id;
                          })
                        : null,
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}
