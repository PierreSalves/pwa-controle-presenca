// Tela 5 — Reposição avulsa: aula extra fora do dia fixo de reposição, em qualquer dia não futuro.
// Conta na frequência como reposição (soma presença, não soma aula). Devolve o dia criado.
import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../dados/consulta_lancamento.dart';
import '../dados/repositorio_presenca.dart';
import '../estado/dependencias.dart';
import '../regras/presenca.dart';
import 'componentes.dart';
import 'formatacao.dart';

const _nomesDia = {
  'domingo': 'domingo',
  'segunda': 'segunda',
  'terca': 'terça',
  'quarta': 'quarta',
  'quinta': 'quinta',
  'sexta': 'sexta',
  'sabado': 'sábado',
};

class TelaReposicaoAvulsa extends StatefulWidget {
  const TelaReposicaoAvulsa({
    super.key,
    required this.turmaId,
    required this.turmaNome,
  });

  final String turmaId;
  final String turmaNome;

  @override
  State<TelaReposicaoAvulsa> createState() => _TelaReposicaoAvulsaState();
}

class _TelaReposicaoAvulsaState extends State<TelaReposicaoAvulsa> {
  late final Dependencias _dependencias;
  late final String _hoje;
  late String _data;
  bool _iniciado = false;
  bool _criando = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciado) return;
    _iniciado = true;
    _dependencias = EscopoDependencias.obter(context);
    _hoje = obterHojeEmSaoPaulo(_dependencias.relogio());
    _data = _hoje;
  }

  Future<void> _escolherData() async {
    final escolhida = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(_data),
      firstDate: DateTime(2020),
      lastDate: DateTime.parse(_hoje),
      helpText: 'Dia da reposição',
    );
    if (escolhida != null) setState(() => _data = formatarData(escolhida));
  }

  Future<void> _criar() async {
    setState(() => _criando = true);
    try {
      final aulaId = await _dependencias.repositorio.criarReposicaoAvulsa(
        widget.turmaId,
        _data,
      );
      if (!mounted) return;
      Navigator.of(context).pop(
        DiaDeAula(
          data: _data,
          tipo: TipoAula.reposicao,
          futuro: false,
          aulaIdAvulsa: aulaId,
        ),
      );
    } on MarcacaoRecusada {
      if (!mounted) return;
      setState(() => _criando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escolha um dia que não seja futuro.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reposição avulsa'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Fechar',
            icon: const Icon(Symbols.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: LarguraCelular(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Aula extra fora do dia fixo de reposição. Conta na frequência.',
              style: TextStyle(color: cores.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Turma',
                border: OutlineInputBorder(),
              ),
              child: Text(widget.turmaNome),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _escolherData,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Data',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Symbols.calendar_month),
                ),
                child: Text(
                  '${formatarDataBr(_data)} (${_nomesDia[obterDiaDaSemana(_data)]})',
                ),
              ),
            ),
            const SizedBox(height: 16),
            BotaoPrincipal(
              rotulo: 'Criar e marcar presenças',
              icone: Symbols.add,
              largo: true,
              carregando: _criando,
              rotuloCarregando: 'Criando…',
              aoTocar: _criar,
            ),
          ],
        ),
      ),
    );
  }
}
