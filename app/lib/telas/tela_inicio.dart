// Tela 2 — Início: status de envio, atalho para lançar a presença de hoje, turmas do usuário,
// resumo do ano e avisos (abaixo do mínimo para graduação e alunos sumidos, com Encerrar).
// O convite para instalar o app entra com o manifest da academia.
import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../dados/cliente_api.dart';
import '../dados/consulta_inicio.dart';
import '../estado/dependencias.dart';
import '../regras/presenca.dart';
import 'componentes.dart';
import 'formatacao.dart';
import 'menu_app.dart';
import 'tela_escolher_turma.dart';
import 'tela_lancamento.dart';

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
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: ListenableBuilder(
          listenable: _dependencias.sessao,
          // Sem logotipo cadastrado, mostra o nome da academia.
          builder: (context, _) =>
              Text(_dependencias.sessao.nomeAcademia ?? 'Controle de presença'),
        ),
      ),
      drawer: const MenuApp(),
      body: StreamBuilder<DadosInicio>(
        stream: _dados,
        builder: (context, snapshot) {
          final dados = snapshot.data;
          if (dados == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return LarguraCelular(child: _montarConteudo(context, dados));
        },
      ),
    );
  }

  Widget _montarConteudo(BuildContext context, DadosInicio dados) {
    final titulo = Theme.of(context).textTheme.titleSmall
        ?.copyWith(fontWeight: FontWeight.w600);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Align(alignment: Alignment.centerLeft, child: StatusEnvio()),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: dados.turmas.isEmpty
              ? null
              : () => abrirLancamento(context),
          icon: const Icon(Icons.check_box_outlined),
          label: const Text('Lançar presença de hoje'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
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
  Widget build(BuildContext context) => InkWell(
    onTap: aoTocar,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    ),
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
        Text(rotulo),
        Text(valor, style: const TextStyle(fontWeight: FontWeight.w700)),
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
              suffixIcon: Icon(Icons.calendar_month_outlined),
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
        onPressed: () => Navigator.of(context).pop(_data),
        child: const Text('Encerrar'),
      ),
    ],
  );
}
