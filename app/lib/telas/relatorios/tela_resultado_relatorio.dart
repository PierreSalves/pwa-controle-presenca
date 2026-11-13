// Telas 7a–7d — resultado do relatório no celular, com Imprimir / PDF no topo. A presença semanal
// mostra uma semana por vez; a impressão leva o período inteiro.
import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../dados/consulta_relatorios.dart';
import '../componentes.dart';
import '../formatacao.dart';
import '../tema.dart';
import 'montar_relatorio.dart';
import 'partes_relatorio.dart';
import 'tabela_relatorio.dart';

class TelaResultadoRelatorio extends StatefulWidget {
  const TelaResultadoRelatorio({
    super.key,
    required this.turma,
    required this.tipo,
    required this.inicio,
    required this.fim,
    this.alunoId,
  });

  final Future<TurmaDoRelatorio> turma;
  final TipoRelatorio tipo;
  final String inicio;
  final String fim;
  final String? alunoId;

  @override
  State<TelaResultadoRelatorio> createState() => _TelaResultadoRelatorioState();
}

class _TelaResultadoRelatorioState extends State<TelaResultadoRelatorio> {
  int _semana = 0;
  String? _alunoId;
  bool _semanaDefinida = false;

  @override
  void initState() {
    super.initState();
    _alunoId = widget.alunoId;
  }

  @override
  Widget build(BuildContext context) {
    final hoje = obterHoje(context);
    return FutureBuilder<TurmaDoRelatorio>(
      future: widget.turma,
      builder: (context, snapshot) {
        final turma = snapshot.data;
        if (turma == null) return const Scaffold(body: Carregando());
        final semanas = obterSemanas(turma, widget.inicio, widget.fim);
        if (!_semanaDefinida) {
          // Abre na semana de hoje, ou na última do período.
          _semanaDefinida = true;
          final atual = semanas.indexWhere(
            (s) =>
                s.domingo.compareTo(hoje) <= 0 && s.sabado.compareTo(hoje) >= 0,
          );
          _semana = atual >= 0
              ? atual
              : (semanas.isEmpty ? 0 : semanas.length - 1);
        }
        final alunos = turma.base.obterAlunosEntre(widget.inicio, widget.fim);
        final aluno = alunos.where((a) => a.id == _alunoId).firstOrNull;
        RelatorioMontado? montar({required bool paraImprimir}) =>
            montarRelatorio(
              turma,
              widget.tipo,
              inicio: widget.inicio,
              fim: widget.fim,
              hoje: hoje,
              aluno: aluno,
              compacto: !paraImprimir,
              semana: paraImprimir || widget.tipo != TipoRelatorio.semanal
                  ? null
                  : _semana,
            );
        final relatorio = montar(paraImprimir: false);
        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.tipo == TipoRelatorio.porAluno
                  ? widget.tipo.rotuloCurto
                  : '${widget.tipo.rotuloCurto} · ${turma.nome}',
            ),
            centerTitle: true,
            actions: [
              IconButton(
                tooltip: 'Imprimir / PDF',
                icon: const Icon(Symbols.print),
                onPressed: relatorio == null
                    ? null
                    : () => imprimirRelatorio(
                        context,
                        turma,
                        montar(paraImprimir: true)!,
                      ),
              ),
            ],
          ),
          body: LarguraCelular(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (widget.tipo == TipoRelatorio.porAluno) ...[
                  EscolhaAluno(
                    alunos: alunos,
                    alunoId: _alunoId,
                    aoEscolher: (id) => setState(() => _alunoId = id),
                  ),
                  const SizedBox(height: 12),
                ],
                if (relatorio != null) ...[
                  Text(
                    widget.tipo == TipoRelatorio.semanal
                        ? montarRelatorio(
                            turma,
                            widget.tipo,
                            inicio: widget.inicio,
                            fim: widget.fim,
                            hoje: hoje,
                          )!.periodo
                        : relatorio.periodo,
                    style: const TextStyle(color: CoresV2.nevoa, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  if (widget.tipo == TipoRelatorio.semanal &&
                      semanas.isNotEmpty) ...[
                    Text(
                      '${semanas[_semana].ordem}ª semana · '
                      '${formatarDiaMes(semanas[_semana].domingo)} a '
                      '${formatarDiaMes(semanas[_semana].sabado)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                  ],
                  TabelaRelatorio(
                    relatorio: relatorio,
                    compacta: true,
                    aoTocarLinha: widget.tipo == TipoRelatorio.mensal
                        ? (i) => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => TelaResultadoRelatorio(
                                turma: widget.turma,
                                tipo: TipoRelatorio.porAluno,
                                inicio: widget.inicio,
                                fim: widget.fim,
                                alunoId: alunos[i].id,
                              ),
                            ),
                          )
                        : null,
                  ),
                  if (widget.tipo == TipoRelatorio.semanal &&
                      semanas.length > 1) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (_semana > 0)
                          OutlinedButton.icon(
                            onPressed: () => setState(() => _semana--),
                            icon: const Icon(Symbols.chevron_left),
                            label: Text(
                              '${semanas[_semana - 1].ordem}ª semana',
                            ),
                          ),
                        const Spacer(),
                        if (_semana < semanas.length - 1)
                          OutlinedButton.icon(
                            onPressed: () => setState(() => _semana++),
                            icon: const Icon(Symbols.chevron_right),
                            iconAlignment: IconAlignment.end,
                            label: Text(
                              '${semanas[_semana + 1].ordem}ª semana',
                            ),
                          ),
                      ],
                    ),
                  ],
                  if (widget.tipo == TipoRelatorio.mensal &&
                      !relatorio.estaVazio) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Toque no aluno para ver as aulas do período.',
                      style: TextStyle(color: CoresV2.nevoa, fontSize: 13),
                    ),
                  ],
                ] else
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Escolha o aluno para ver as aulas do período.',
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
