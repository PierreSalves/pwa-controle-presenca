// Tela 2 — Início: status de envio, atalho para lançar a presença de hoje, turmas do usuário,
// resumo do ano e avisos (abaixo do mínimo para graduação e alunos sumidos, com Encerrar).
// O convite para instalar o app entra com o manifest da academia.
import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../dados/cliente_api.dart';
import '../dados/consulta_inicio.dart';
import '../estado/dependencias.dart';
import '../regras/presenca.dart';
import 'componentes.dart';
import 'convite_instalacao.dart';
import 'formatacao.dart';
import 'menu_app.dart';
import 'tela_escolher_turma.dart';
import 'tela_lancamento.dart';
import 'tema.dart';

class TelaInicio extends StatefulWidget {
  const TelaInicio({super.key});

  @override
  State<TelaInicio> createState() => _TelaInicioState();
}

class _TelaInicioState extends State<TelaInicio> {
  late final Dependencias _dependencias;
  late final String _hoje;
  Stream<DadosInicio>? _dados;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dados != null) return;
    _dependencias = EscopoDependencias.obter(context);
    _hoje = obterHojeEmSaoPaulo(_dependencias.relogio());
    _dados = _dependencias.consultaInicio.observarInicio(_hoje);
    unawaited(_dependencias.coordenador.sincronizar());
  }

  @override
  Widget build(BuildContext context) {
    final desktop = ehDesktop(context);
    return Scaffold(
      appBar: desktop
          ? null
          : AppBar(
              centerTitle: true,
              title: ListenableBuilder(
                listenable: _dependencias.sessao,
                // Sem logotipo cadastrado, mostra o nome da academia.
                builder: (context, _) => Text(
                  _dependencias.sessao.nomeAcademia ?? 'Controle de presença',
                ),
              ),
            ),
      drawer: obterMenuDoCelular(context),
      body: StreamBuilder<DadosInicio>(
        stream: _dados,
        builder: (context, snapshot) {
          final dados = snapshot.data;
          if (dados == null) {
            return const Carregando();
          }
          return desktop
              ? _montarDesktop(context, dados)
              : LarguraCelular(child: _montarConteudo(context, dados));
        },
      ),
    );
  }

  /// D1: cabeçalho com status e botão principal, quatro indicadores e duas colunas.
  Widget _montarDesktop(BuildContext context, DadosInicio dados) {
    final titulo = Theme.of(context).textTheme.titleSmall
        ?.copyWith(fontWeight: FontWeight.w600);
    final lancar = dados.turmas.isEmpty ? null : () => abrirLancamento(context);
    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 22, 28, 28),
          children: [
            Row(
              children: [
                Expanded(
                  child: ListenableBuilder(
                    listenable: _dependencias.sessao,
                    builder: (context, _) => Text(
                      'Início · ${_dependencias.sessao.nomeAcademia ?? 'Controle de presença'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const StatusEnvio(),
                const SizedBox(width: 12),
                BotaoPrincipal(
                  rotulo: 'Lançar presença de hoje',
                  icone: Symbols.check_box,
                  aoTocar: lancar,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _Indicador(
                    rotulo: 'Aulas ${dados.ano}',
                    valor: '${dados.aulasNoAno}',
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _Indicador(
                    rotulo: 'Freq. média',
                    valor: dados.frequenciaMediaNoAno == null
                        ? '—'
                        : '${dados.frequenciaMediaNoAno}%',
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _Indicador(
                    rotulo: 'Alunos ativos',
                    valor: '${dados.alunosAtivos}',
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _Indicador(
                    rotulo: 'Abaixo do mínimo',
                    valor: '${dados.abaixoDoMinimo.length}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Cartao(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Suas turmas', style: titulo),
                        if (dados.turmas.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'Nenhuma turma liberada para você. Fale com o professor.',
                            ),
                          ),
                        for (final turma in dados.turmas)
                          _LinhaTurmaDesktop(turma: turma),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Cartao(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Abaixo do mínimo (graduação)', style: titulo),
                        if (dados.abaixoDoMinimo.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'Ninguém abaixo do mínimo no semestre.',
                            ),
                          ),
                        for (final a in dados.abaixoDoMinimo)
                          InkWell(
                            onTap: () => abrirFrequenciaSemestre(
                              context,
                              soAsTurmas: {a.turmaId},
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      formatarAluno(a.codigo, a.nome),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '${a.frequencia.percentual}%',
                                    style: const TextStyle(
                                      color: CoresV2.ponta,
                                      fontFeatures: numerosFixos,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (dados.sumidos.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _Aviso(
                            texto:
                                '${dados.sumidos.length} ${dados.sumidos.length == 1 ? 'aluno' : 'alunos'} '
                                'sem vir há mais de ${dados.semanasSumido} semanas',
                          ),
                          for (final sumido in dados.sumidos)
                            _LinhaSumido(
                              sumido: sumido,
                              mostrarTurma: dados.turmas.length > 1,
                              hoje: _hoje,
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _montarConteudo(BuildContext context, DadosInicio dados) {
    final titulo = Theme.of(context).textTheme.titleSmall
        ?.copyWith(fontWeight: FontWeight.w600);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Tela 2: o convite para instalar vem antes do status (some se instalado ou dispensado).
        const ConviteInstalacao(),
        const Align(alignment: Alignment.centerLeft, child: StatusEnvio()),
        const SizedBox(height: 12),
        BotaoPrincipal(
          rotulo: 'Lançar presença de hoje',
          icone: Symbols.check_box,
          largo: true,
          aoTocar: dados.turmas.isEmpty ? null : () => abrirLancamento(context),
        ),
        const SizedBox(height: 16),
        Text('Suas turmas', style: titulo),
        const SizedBox(height: 8),
        if (dados.turmas.isEmpty)
          const Text('Nenhuma turma liberada para você. Fale com o professor.'),
        for (final turma in dados.turmas)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _Caixa(
              aoTocar: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => TelaLancamento(turmaId: turma.id),
                ),
              ),
              child: Text(
                [
                  turma.nome,
                  if (turma.diasDeAula.isNotEmpty) turma.diasDeAula.join(' '),
                  '${turma.alunos} ${turma.alunos == 1 ? 'aluno' : 'alunos'}',
                ].join(' · '),
              ),
            ),
          ),
        const SizedBox(height: 8),
        Text('Resumo de ${dados.ano}', style: titulo),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _Indicador(rotulo: 'Aulas', valor: '${dados.aulasNoAno}'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Indicador(
                rotulo: 'Freq. média',
                valor: dados.frequenciaMediaNoAno == null
                    ? '—'
                    : '${dados.frequenciaMediaNoAno}%',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (dados.abaixoDoMinimo.isNotEmpty) ...[
          _Aviso(
            texto: dados.abaixoDoMinimo.length == 1
                ? '1 aluno abaixo do mínimo para graduação'
                : '${dados.abaixoDoMinimo.length} alunos abaixo do mínimo para graduação',
            aoTocar: () => abrirFrequenciaSemestre(
              context,
              soAsTurmas: {for (final a in dados.abaixoDoMinimo) a.turmaId},
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (dados.sumidos.isNotEmpty) ...[
          _Aviso(
            texto:
                '${dados.sumidos.length} ${dados.sumidos.length == 1 ? 'aluno' : 'alunos'} '
                'sem vir há mais de ${dados.semanasSumido} semanas',
          ),
          for (final sumido in dados.sumidos) ...[
            _LinhaSumido(
              sumido: sumido,
              mostrarTurma: dados.turmas.length > 1,
              hoje: _hoje,
            ),
            const Divider(height: 1),
          ],
        ],
      ],
    );
  }
}

class _Caixa extends StatelessWidget {
  const _Caixa({required this.child, this.aoTocar});
  final Widget child;
  final VoidCallback? aoTocar;

  @override
  Widget build(BuildContext context) => Cartao(
    aoTocar: aoTocar,
    child: SizedBox(width: double.infinity, child: child),
  );
}

class _Indicador extends StatelessWidget {
  const _Indicador({required this.rotulo, required this.valor});
  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) => _Caixa(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          style: const TextStyle(color: CoresV2.nevoa, fontSize: 13),
        ),
        Text(
          valor,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            fontFeatures: numerosFixos,
          ),
        ),
      ],
    ),
  );
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.texto, this.aoTocar});
  final String texto;
  final VoidCallback? aoTocar;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: aoTocar,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: CoresWireframe.avisoFundo,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        texto,
        style: const TextStyle(color: CoresWireframe.avisoTexto, fontSize: 13),
      ),
    ),
  );
}

class _LinhaSumido extends StatelessWidget {
  const _LinhaSumido({
    required this.sumido,
    required this.mostrarTurma,
    required this.hoje,
  });

  final AlunoSumidoNoInicio sumido;
  final bool mostrarTurma;
  final String hoje;

  @override
  Widget build(BuildContext context) {
    final ultima = sumido.ultimaPresenca;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              [
                formatarAluno(sumido.codigo, sumido.nome),
                if (mostrarTurma) sumido.turmaNome,
                ultima == null
                    ? 'nunca veio'
                    : 'desde ${formatarDiaMes(ultima)}',
              ].join(' · '),
            ),
          ),
          OutlinedButton(
            style: estiloDestrutivo,
            onPressed: () => _encerrar(context),
            child: const Text('Encerrar'),
          ),
        ],
      ),
    );
  }

  /// Pede a data de fim (sugere a última presença) e encerra a matrícula na API (online).
  Future<void> _encerrar(BuildContext context) async {
    final dependencias = EscopoDependencias.obter(context);
    final sugerida = sumido.ultimaPresenca ?? sumido.dataInicioMatricula;
    final dataFim = await showDialog<String>(
      context: context,
      builder: (_) => _DialogoEncerrar(
        aluno: formatarAluno(sumido.codigo, sumido.nome),
        turma: sumido.turmaNome,
        dataInicio: sumido.dataInicioMatricula,
        sugerida: sugerida,
        hoje: hoje,
      ),
    );
    if (dataFim == null || !context.mounted) return;
    final mensageiro = ScaffoldMessenger.of(context);
    try {
      await dependencias.cliente.encerrarMatricula(
        matriculaId: sumido.matriculaId,
        dataInicio: sumido.dataInicioMatricula,
        dataFim: dataFim,
      );
      await dependencias.coordenador.sincronizar();
      mensageiro.showSnackBar(
        SnackBar(
          content: Text(
            'Matrícula de ${sumido.nome} encerrada em ${formatarDataBr(dataFim)}.',
          ),
        ),
      );
    } on SemConexao {
      mensageiro.showSnackBar(
        const SnackBar(
          content: Text(
            'Sem internet. Encerrar a matrícula precisa de conexão.',
          ),
        ),
      );
    } on SessaoEncerrada {
      await dependencias.sessao.encerrarLocalmente();
    } on ErroApi {
      mensageiro.showSnackBar(
        const SnackBar(
          content: Text('Não foi possível encerrar agora. Tente de novo.'),
        ),
      );
    }
  }
}

class _DialogoEncerrar extends StatefulWidget {
  const _DialogoEncerrar({
    required this.aluno,
    required this.turma,
    required this.dataInicio,
    required this.sugerida,
    required this.hoje,
  });

  final String aluno;
  final String turma;
  final String dataInicio;
  final String sugerida;
  final String hoje;

  @override
  State<_DialogoEncerrar> createState() => _DialogoEncerrarState();
}

class _DialogoEncerrarState extends State<_DialogoEncerrar> {
  late String _data = widget.sugerida;

  Future<void> _escolherData() async {
    final escolhida = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(_data),
      firstDate: DateTime.parse(widget.dataInicio),
      lastDate: DateTime.parse(widget.hoje),
      helpText: 'Data de fim da matrícula',
    );
    if (escolhida != null) setState(() => _data = formatarData(escolhida));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Encerrar matrícula'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${widget.aluno} · ${widget.turma}'),
        const SizedBox(height: 12),
        InkWell(
          onTap: _escolherData,
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Data de fim',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Symbols.calendar_month),
            ),
            child: Text(formatarDataBr(_data)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sugestão: a última presença.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        style: estiloConfirmarDestrutivo,
        onPressed: () => Navigator.of(context).pop(_data),
        child: const Text('Encerrar'),
      ),
    ],
  );
}

/// Linha de turma no Início do desktop, com o atalho "Lançar" (botão secundário).
class _LinhaTurmaDesktop extends StatelessWidget {
  const _LinhaTurmaDesktop({required this.turma});
  final TurmaNoInicio turma;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(
          child: Text(
            [
              turma.nome,
              if (turma.diasDeAula.isNotEmpty) turma.diasDeAula.join(' '),
            ].join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        OutlinedButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => TelaLancamento(turmaId: turma.id),
            ),
          ),
          child: const Text('Lançar'),
        ),
      ],
    ),
  );
}
