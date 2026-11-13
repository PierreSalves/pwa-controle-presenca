// Tela D2 — Lançar presença no desktop (docs/telas/README.md): a grade da semana, parecida com
// a planilha. Mesmas regras da tela 4: dia futuro e fora da matrícula bloqueados, grava no
// aparelho e envia em seguida.
import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../dados/consulta_lancamento.dart';
import '../dados/repositorio_presenca.dart';
import '../estado/dependencias.dart';
import '../regras/presenca.dart';
import 'componentes.dart';
import 'formatacao.dart';
import 'tela_reposicao_avulsa.dart';
import 'tema.dart';

/// Mensagem para a marcação recusada pelas regras do lançamento.
String descreverRecusa(RecusaMarcacao motivo) => switch (motivo) {
  RecusaMarcacao.dataFutura => 'Não dá para lançar presença em dia futuro.',
  RecusaMarcacao.diaSemAulaRegular || RecusaMarcacao.diaSemReposicaoFixa =>
    'O quadro de aulas não tem aula neste dia.',
  RecusaMarcacao.foraDaMatricula =>
    'O aluno não estava matriculado nesta data.',
};

class GradeSemana extends StatefulWidget {
  const GradeSemana({super.key, required this.turmaId});

  final String turmaId;

  @override
  State<GradeSemana> createState() => _GradeSemanaState();
}

class _GradeSemanaState extends State<GradeSemana> {
  late final Dependencias _dependencias;
  late String _hoje;
  late String _domingo;
  Stream<DadosGrade>? _dados;

  /// Pouco frequentes que o usuário pôs na grade pela busca.
  final _adicionados = <String>{};
  final _busca = TextEditingController();
  final _focoBusca = FocusNode();
  bool _poucoFrequentesAbertos = false;
  bool _iniciado = false;

  @override
  void dispose() {
    _busca.dispose();
    _focoBusca.dispose();
    super.dispose();
  }

  /// Põe o aluno na grade e limpa a busca para o próximo.
  void _adicionarNaGrade(AlunoNaGrade aluno) {
    setState(() => _adicionados.add(aluno.id));
    _busca.clear();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciado) return;
    _iniciado = true;
    _dependencias = EscopoDependencias.obter(context);
    _hoje = obterHojeEmSaoPaulo(_dependencias.relogio());
    _definirSemana(obterDomingoDaSemana(_hoje));
  }

  void _definirSemana(String domingo) {
    setState(() {
      _domingo = domingo;
      _dados = _dependencias.consulta.observarGrade(
        widget.turmaId,
        domingo,
        hoje: _hoje,
      );
    });
  }

  bool get _temProximaSemana =>
      !ehDataFutura(somarDiasNaData(_domingo, 7), _hoje);

  Future<void> _definirPresenca(
    AlunoNaGrade aluno,
    DiaDeAula dia,
    bool presente,
  ) async {
    try {
      await _dependencias.repositorio.definirPresenca(
        turmaId: widget.turmaId,
        data: dia.data,
        alunoId: aluno.id,
        presente: presente,
        tipo: dia.tipo,
        aulaIdAvulsa: dia.aulaIdAvulsa,
      );
      unawaited(_dependencias.coordenador.sincronizar());
    } on MarcacaoRecusada catch (recusa) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(descreverRecusa(recusa.motivo))));
    }
  }

  Future<void> _abrirReposicaoAvulsa(String turmaNome) async {
    final criada = await Navigator.of(context).push<DiaDeAula>(
      MaterialPageRoute(
        builder: (_) =>
            TelaReposicaoAvulsa(turmaId: widget.turmaId, turmaNome: turmaNome),
      ),
    );
    if (criada != null && mounted) {
      _definirSemana(obterDomingoDaSemana(criada.data));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<DadosGrade>(
        stream: _dados,
        builder: (context, snapshot) {
          final dados = snapshot.data;
          if (dados == null || dados.domingo != _domingo) {
            return const Carregando();
          }
          return Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
                children: [
                  _montarCabecalho(context, dados),
                  const SizedBox(height: 16),
                  if (dados.dias.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'O quadro de aulas não tem aula nesta semana.',
                      ),
                    )
                  else ...[
                    _montarBusca(dados),
                    const SizedBox(height: 12),
                    Cartao(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: _montarTabela(context, dados),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Dia futuro e fora da matrícula ficam bloqueados.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _montarCabecalho(BuildContext context, DadosGrade dados) {
    final sabado = somarDiasNaData(dados.domingo, 6);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (Navigator.of(context).canPop())
          IconButton(
            tooltip: 'Voltar',
            icon: const Icon(Symbols.arrow_back),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        IconButton(
          tooltip: 'Semana anterior',
          icon: const Icon(Symbols.chevron_left),
          onPressed: () => _definirSemana(somarDiasNaData(_domingo, -7)),
        ),
        Text(
          '${dados.turmaNome} · ${formatarDiaMes(dados.domingo)} a '
          '${formatarDataBr(sabado)}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFeatures: numerosFixos,
          ),
        ),
        IconButton(
          tooltip: 'Próxima semana',
          icon: const Icon(Symbols.chevron_right),
          onPressed: _temProximaSemana
              ? () => _definirSemana(somarDiasNaData(_domingo, 7))
              : null,
        ),
        const SizedBox(width: 8),
        const StatusEnvio(),
        OutlinedButton.icon(
          onPressed: () => _abrirReposicaoAvulsa(dados.turmaNome),
          icon: const Icon(Symbols.add),
          label: const Text('Reposição avulsa'),
        ),
      ],
    );
  }

  Widget _montarBusca(DadosGrade dados) {
    final disponiveis = dados.poucoFrequentes
        .where((a) => !_adicionados.contains(a.id))
        .toList();
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Autocomplete<AlunoNaGrade>(
        textEditingController: _busca,
        focusNode: _focoBusca,
        displayStringForOption: (a) => formatarAluno(a.codigo, a.nome),
        optionsBuilder: (valor) {
          final busca = normalizarBusca(valor.text);
          if (busca.isEmpty) return const [];
          return disponiveis.where(
            (a) =>
                normalizarBusca(formatarAluno(a.codigo, a.nome))
                    .contains(busca),
          );
        },
        onSelected: _adicionarNaGrade,
        fieldViewBuilder: (context, controle, foco, aoEnviar) => TextField(
          controller: controle,
          focusNode: foco,
          autocorrect: false,
          onSubmitted: (_) => aoEnviar(),
          decoration: const InputDecoration(
            prefixIcon: Icon(Symbols.search),
            hintText: 'Adicionar aluno pouco frequente à grade…',
            isDense: true,
          ),
        ),
      ),
    );
  }

  Widget _montarTabela(BuildContext context, DadosGrade dados) {
    final cores = Theme.of(context).colorScheme;
    final apoio = TextStyle(color: cores.onSurfaceVariant, fontSize: 13);
    final naGrade = [
      ...dados.lista,
      ...dados.poucoFrequentes.where((a) => _adicionados.contains(a.id)),
    ];
    final restantes = dados.poucoFrequentes
        .where((a) => !_adicionados.contains(a.id))
        .toList();
    final linha = BorderSide(color: cores.outlineVariant);

    TableRow montarLinhaAluno(AlunoNaGrade aluno) => TableRow(
      decoration: BoxDecoration(border: Border(top: linha)),
      children: [
        _CelulaAluno(aluno: aluno),
        for (final dia in dados.dias)
          Center(
            // Bloqueada (futuro ou fora da matrícula): esmaecida, como no wireframe D2.
            child: Opacity(
              opacity: aluno.bloqueados.contains(dia.chave) ? 0.4 : 1,
              child: Checkbox(
                value: aluno.presencas.contains(dia.chave),
                semanticLabel:
                    '${aluno.nome}, ${obterDiaAbreviado(dia.data)} '
                    '${formatarDiaMes(dia.data)}',
                onChanged: aluno.bloqueados.contains(dia.chave)
                    ? null
                    : (v) => _definirPresenca(aluno, dia, v ?? false),
              ),
            ),
          ),
      ],
    );

    return Table(
      columnWidths: {
        0: const FlexColumnWidth(),
        for (var i = 1; i <= dados.dias.length; i++)
          i: const FixedColumnWidth(96),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('Aluno · frequência', style: apoio),
            ),
            for (final dia in dados.dias) _CabecalhoDia(dia: dia),
          ],
        ),
        for (final aluno in naGrade) montarLinhaAluno(aluno),
        if (restantes.isNotEmpty)
          TableRow(
            decoration: BoxDecoration(border: Border(top: linha)),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(
                    () => _poucoFrequentesAbertos = !_poucoFrequentesAbertos,
                  ),
                  icon: Icon(
                    _poucoFrequentesAbertos
                        ? Symbols.expand_less
                        : Symbols.expand_more,
                  ),
                  label: Text('Pouco frequentes (${restantes.length})'),
                ),
              ),
              for (final _ in dados.dias) const SizedBox.shrink(),
            ],
          ),
        if (_poucoFrequentesAbertos)
          for (final aluno in restantes) montarLinhaAluno(aluno),
        TableRow(
          decoration: BoxDecoration(border: Border(top: linha)),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('Presentes', style: apoio),
            ),
            for (final dia in dados.dias)
              Center(
                child: Text(
                  dia.futuro ? '–' : '${dados.calcularPresentes(dia)}',
                  style: apoio.copyWith(fontFeatures: numerosFixos),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _CabecalhoDia extends StatelessWidget {
  const _CabecalhoDia({required this.dia});
  final DiaDeAula dia;

  @override
  Widget build(BuildContext context) {
    final cor = dia.futuro ? CoresV2.desativado : CoresV2.grafite;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Text(
            '${obterDiaAbreviado(dia.data)} ${formatarDiaMes(dia.data)}',
            style: TextStyle(
              color: cor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFeatures: numerosFixos,
            ),
          ),
          if (dia.tipo == TipoAula.reposicao)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Etiqueta(dia.aulaIdAvulsa == null ? 'repos.' : 'avulsa'),
            ),
        ],
      ),
    );
  }
}

class _CelulaAluno extends StatelessWidget {
  const _CelulaAluno({required this.aluno});
  final AlunoNaGrade aluno;

  @override
  Widget build(BuildContext context) {
    final apoio = TextStyle(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontFeatures: numerosFixos,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: formatarAluno(aluno.codigo, aluno.nome)),
            if (aluno.frequencia.novo)
              const WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Etiqueta('novo'),
                ),
              ),
            TextSpan(text: ' · ${aluno.frequencia.percentual}%', style: apoio),
          ],
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
