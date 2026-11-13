// Tela 4 — Lançar presença (docs/telas/README.md). Tela principal: marca quem veio, rápido,
// durante a aula. Grava no aparelho (funciona offline) e envia em seguida; com a tela aberta,
// busca as marcações dos outros aparelhos a cada poucos segundos.
import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../dados/consulta_lancamento.dart';
import '../dados/repositorio_presenca.dart';
import '../estado/dependencias.dart';
import '../regras/presenca.dart';
import 'componentes.dart';
import 'formatacao.dart';
import 'menu_app.dart';
import 'tela_busca_aluno.dart';
import 'tela_reposicao_avulsa.dart';

class TelaLancamento extends StatefulWidget {
  const TelaLancamento({
    super.key,
    required this.turmaId,
    this.ehTelaInicial = false,
  });

  final String turmaId;

  /// Usuário com uma turma só: a tela abre direto, com o menu no lugar do voltar.
  final bool ehTelaInicial;

  @override
  State<TelaLancamento> createState() => _TelaLancamentoState();
}

class _TelaLancamentoState extends State<TelaLancamento> {
  late final Dependencias _dependencias;
  List<QuadroAulas>? _quadros;
  late String _hoje;
  late String _data;
  String? _aulaIdAvulsa;
  Stream<DadosLancamento>? _dados;
  bool _iniciado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciado) return;
    _iniciado = true;
    _dependencias = EscopoDependencias.obter(context);
    _hoje = obterHojeEmSaoPaulo(_dependencias.relogio());
    _data = _hoje;
    _dependencias.coordenador.iniciarAtualizacaoPeriodica();
    unawaited(_carregarQuadros());
  }

  @override
  void dispose() {
    _dependencias.coordenador.pararAtualizacaoPeriodica();
    super.dispose();
  }

  Future<void> _carregarQuadros() async {
    final quadros = await _dependencias.consulta.obterQuadros(widget.turmaId);
    if (!mounted) return;
    setState(() => _quadros = quadros);
    _definirData(_hoje);
  }

  /// Escolhe o dia: se não houver aula nele, o último dia de aula já passado da mesma semana.
  /// Com [aulaIdAvulsa], abre a reposição avulsa daquele dia.
  void _definirData(String data, {String? aulaIdAvulsa}) {
    final dias = calcularDiasDeAulaDaSemana(data, _quadros ?? const [], _hoje);
    final ehDiaDeAula = dias.any((d) => d.data == data);
    final anteriores = dias.where(
      (d) => !d.futuro && d.data.compareTo(data) <= 0,
    );
    final escolhida = aulaIdAvulsa != null || ehDiaDeAula || anteriores.isEmpty
        ? data
        : anteriores.last.data;
    setState(() {
      _data = escolhida;
      _aulaIdAvulsa = aulaIdAvulsa;
      _dados = _dependencias.consulta.observarLancamento(
        widget.turmaId,
        escolhida,
        hoje: _hoje,
        aulaIdAvulsa: aulaIdAvulsa,
      );
    });
  }

  Future<void> _abrirReposicaoAvulsa(String turmaNome) async {
    final criada = await Navigator.of(context).push<DiaDeAula>(
      MaterialPageRoute(
        builder: (_) =>
            TelaReposicaoAvulsa(turmaId: widget.turmaId, turmaNome: turmaNome),
      ),
    );
    if (criada != null && mounted) {
      _definirData(criada.data, aulaIdAvulsa: criada.aulaIdAvulsa);
    }
  }

  Future<void> _escolherOutraData() async {
    final escolhida = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(_data),
      firstDate: DateTime(2020),
      lastDate: DateTime.parse(_hoje),
      helpText: 'Escolha o dia da aula',
    );
    if (escolhida != null) _definirData(formatarData(escolhida));
  }

  String _descreverRecusa(RecusaMarcacao motivo) => switch (motivo) {
    RecusaMarcacao.dataFutura => 'Não dá para lançar presença em dia futuro.',
    RecusaMarcacao.diaSemAulaRegular || RecusaMarcacao.diaSemReposicaoFixa =>
      'O quadro de aulas não tem aula neste dia.',
    RecusaMarcacao.foraDaMatricula =>
      'O aluno não estava matriculado nesta data.',
  };

  Future<void> _definirPresenca(
    DadosLancamento dados,
    String alunoId,
    bool presente,
  ) async {
    final tipo = dados.tipo;
    if (tipo == null) return;
    try {
      await _dependencias.repositorio.definirPresenca(
        turmaId: widget.turmaId,
        data: dados.data,
        alunoId: alunoId,
        presente: presente,
        tipo: tipo,
        aulaIdAvulsa: dados.aulaIdAvulsa,
      );
      unawaited(_dependencias.coordenador.sincronizar());
    } on MarcacaoRecusada catch (recusa) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_descreverRecusa(recusa.motivo))));
    }
  }

  Future<void> _marcarTodosFrequentes(DadosLancamento dados) async {
    for (final aluno in dados.lista.where((a) => !a.presente)) {
      await _definirPresenca(dados, aluno.id, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DadosLancamento>(
      stream: _dados,
      builder: (context, snapshot) {
        final dados = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            title: Text(dados?.turmaNome ?? 'Lançar presença'),
            centerTitle: true,
            actions: [
              IconButton(
                tooltip: 'Outro dia',
                icon: const Icon(Icons.calendar_month_outlined),
                onPressed: _quadros == null ? null : _escolherOutraData,
              ),
            ],
          ),
          drawer: widget.ehTelaInicial ? const MenuApp() : null,
          body: dados == null || _quadros == null
              ? const Center(child: CircularProgressIndicator())
              : LarguraCelular(child: _montarConteudo(context, dados)),
        );
      },
    );
  }

  Widget _montarConteudo(BuildContext context, DadosLancamento dados) {
    final cores = Theme.of(context).colorScheme;
    final textoApoio = TextStyle(color: cores.onSurfaceVariant, fontSize: 13);
    final dias = dados.diasDaSemana;
    final reposicoesFixas = dias.where(
      (d) => d.tipo == TipoAula.reposicao && d.aulaIdAvulsa == null,
    );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SeletorDias(
          dias: dias,
          data: _data,
          aulaIdAvulsa: _aulaIdAvulsa,
          aoEscolher: (dia) =>
              _definirData(dia.data, aulaIdAvulsa: dia.aulaIdAvulsa),
        ),
        const SizedBox(height: 8),
        Text(
          [
            if (dias.any((d) => d.data == _hoje)) 'Semana atual',
            'dia futuro bloqueado',
            for (final r in reposicoesFixas)
              '${obterDiaAbreviado(r.data)} = reposição fixa',
            if (dados.aulaIdAvulsa != null)
              'reposição avulsa de ${formatarDiaMes(dados.data)}',
          ].join(' · '),
          style: textoApoio,
        ),
        const SizedBox(height: 12),
        if (dados.tipo == null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Sem aula em ${formatarDataBr(dados.data)} pelo quadro de aulas.',
              textAlign: TextAlign.center,
            ),
          )
        else ...[
          TextField(
            readOnly: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Buscar outro aluno matriculado',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => TelaBuscaAluno(
                  turmaId: widget.turmaId,
                  data: dados.data,
                  tipo: dados.tipo!,
                  hoje: _hoje,
                  aulaIdAvulsa: dados.aulaIdAvulsa,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Frequentes (${dados.lista.length}) · ordem por frequência',
            style: textoApoio,
          ),
          for (final aluno in dados.lista) ...[
            LinhaAluno(
              aluno: aluno,
              aoMarcar: (v) => _definirPresenca(dados, aluno.id, v),
            ),
            const Divider(height: 1),
          ],
          if (dados.poucoFrequentes.isNotEmpty)
            ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 4),
              title: Text('Pouco frequentes (${dados.poucoFrequentes.length})'),
              controlAffinity: ListTileControlAffinity.leading,
              children: [
                for (final aluno in dados.poucoFrequentes)
                  LinhaAluno(
                    aluno: aluno,
                    mostrarFrequencia: true,
                    aoMarcar: (v) => _definirPresenca(dados, aluno.id, v),
                  ),
              ],
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Text('${dados.presentes} presentes')),
              const StatusEnvio(),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: dados.lista.every((a) => a.presente)
                ? null
                : () => _marcarTodosFrequentes(dados),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Marcar todos os frequentes'),
          ),
        ],
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _abrirReposicaoAvulsa(dados.turmaNome),
          icon: const Icon(Icons.add),
          label: const Text('Reposição avulsa (outro dia)'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ],
    );
  }
}

class _SeletorDias extends StatelessWidget {
  const _SeletorDias({
    required this.dias,
    required this.data,
    required this.aulaIdAvulsa,
    required this.aoEscolher,
  });

  final List<DiaDeAula> dias;
  final String data;
  final String? aulaIdAvulsa;
  final ValueChanged<DiaDeAula> aoEscolher;

  bool _estaSelecionado(DiaDeAula dia) =>
      dia.data == data && dia.aulaIdAvulsa == aulaIdAvulsa;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    if (dias.isEmpty) {
      return const Text('O quadro de aulas não tem aula nesta semana.');
    }
    return Row(
      children: [
        for (final dia in dias)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Semantics(
                selected: _estaSelecionado(dia),
                button: true,
                enabled: !dia.futuro,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: dia.futuro ? null : () => aoEscolher(dia),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _estaSelecionado(dia)
                            ? cores.onSurface
                            : cores.outlineVariant,
                        width: _estaSelecionado(dia) ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          obterDiaAbreviado(dia.data),
                          style: TextStyle(
                            color: dia.futuro ? cores.outline : null,
                          ),
                        ),
                        Text(
                          formatarDiaMes(dia.data),
                          style: TextStyle(
                            color: dia.futuro ? cores.outline : null,
                          ),
                        ),
                        if (dia.tipo == TipoAula.reposicao)
                          Text(
                            dia.aulaIdAvulsa == null ? 'repos.' : 'avulsa',
                            style: TextStyle(
                              fontSize: 11,
                              color: cores.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
