// Tela 9 — Aluno: cadastro (código sugerido e editável, único na academia), dados sensíveis só
// online, matrículas e graduações. Nada desta tela é gravado no aparelho.
import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../dados/cliente_api.dart';
import '../dados/repositorio_alunos.dart';
import '../estado/dependencias.dart';
import '../regras/presenca.dart';
import 'componentes.dart';
import 'formatacao.dart';
import 'tela_alunos.dart';

const _faixas = [
  'Branca',
  'Cinza',
  'Amarela',
  'Laranja',
  'Verde',
  'Azul',
  'Roxa',
  'Marrom',
  'Preta',
];

const _situacoes = {
  'matriculado': 'matriculado',
  'remanejado': 'remanejado',
  'encerrado': 'encerrado',
};

class TelaAluno extends StatefulWidget {
  /// Sem [alunoId], cadastra um aluno novo.
  const TelaAluno({super.key, this.alunoId});
  final String? alunoId;

  @override
  State<TelaAluno> createState() => _TelaAlunoState();
}

class _TelaAlunoState extends State<TelaAluno> {
  late final Dependencias _dependencias;
  late final String _hoje;
  final _formulario = GlobalKey<FormState>();
  final _codigo = TextEditingController();
  final _nome = TextEditingController();
  final _campos = {
    for (final campo in camposSensiveisAluno) campo: TextEditingController(),
  };
  String? _id;
  AlunoCompleto? _aluno;
  String? _nascimento;
  bool _ativo = true;
  bool _carregando = true;
  bool _salvando = false;
  String? _erro;
  bool _iniciado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciado) return;
    _iniciado = true;
    _dependencias = EscopoDependencias.obter(context);
    _hoje = obterHojeEmSaoPaulo(_dependencias.relogio());
    _id = widget.alunoId;
    unawaited(_carregar());
  }

  @override
  void dispose() {
    _codigo.dispose();
    _nome.dispose();
    for (final c in _campos.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _executar(Future<void> Function() acao) async {
    try {
      await acao();
    } on SessaoEncerrada {
      await _dependencias.sessao.encerrarLocalmente();
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(descreverErroOnline(erro))));
    }
  }

  void _mostrar(AlunoCompleto aluno) {
    _aluno = aluno;
    _id = aluno.id;
    _codigo.text = aluno.codigo;
    _nome.text = aluno.nome;
    _nascimento = aluno.dataNascimento;
    _ativo = aluno.ativo;
    for (final campo in camposSensiveisAluno) {
      _campos[campo]!.text = aluno.sensiveis[campo] ?? '';
    }
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      if (_id == null) {
        _codigo.text = await _dependencias.alunos.buscarProximoCodigo();
      } else {
        _mostrar(await _dependencias.alunos.buscarAluno(_id!));
      }
    } on SessaoEncerrada {
      await _dependencias.sessao.encerrarLocalmente();
      return;
    } catch (erro) {
      _erro = descreverErroOnline(erro);
    }
    if (mounted) setState(() => _carregando = false);
  }

  /// Recarrega o cadastro e atualiza o aparelho (matrículas e nomes entram no lançamento).
  Future<void> _atualizar(AlunoCompleto? aluno) async {
    final atualizado = aluno ?? await _dependencias.alunos.buscarAluno(_id!);
    if (mounted) setState(() => _mostrar(atualizado));
    unawaited(_dependencias.coordenador.sincronizar());
  }

  Future<void> _salvar() async {
    if (_salvando || !_formulario.currentState!.validate()) return;
    setState(() => _salvando = true);
    await _executar(() async {
      final dados = DadosAluno(
        codigo: _codigo.text,
        nome: _nome.text,
        ativo: _ativo,
        dataNascimento: _nascimento,
        sensiveis: {
          for (final campo in camposSensiveisAluno) campo: _campos[campo]!.text,
        },
      );
      final novo = _id == null;
      await _atualizar(await _dependencias.alunos.salvarAluno(dados, id: _id));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(novo ? 'Aluno cadastrado.' : 'Alterações salvas.'),
        ),
      );
    });
    if (mounted) setState(() => _salvando = false);
  }

  Future<String?> _escolherData(
    String inicial, {
    String primeira = '2000-01-01',
    String? ultima,
    String? titulo,
  }) async {
    final escolhida = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(inicial),
      firstDate: DateTime.parse(primeira),
      lastDate: DateTime.parse(ultima ?? somarDiasNaData(_hoje, 365)),
      helpText: titulo,
    );
    return escolhida == null ? null : formatarData(escolhida);
  }

  Future<void> _matricular() async {
    final turmas = await _dependencias.alunos.buscarTurmas().catchError((
      Object erro,
    ) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(descreverErroOnline(erro))));
      }
      return <TurmaParaMatricula>[];
    });
    if (!mounted || turmas.isEmpty) return;
    final escolha = await showDialog<(String, String)>(
      context: context,
      builder: (_) => _DialogoMatricula(
        turmas: turmas,
        hoje: _hoje,
        escolherData: _escolherData,
      ),
    );
    if (escolha == null) return;
    await _executar(() async {
      await _dependencias.alunos.matricular(
        alunoId: _id!,
        turmaId: escolha.$1,
        dataInicio: escolha.$2,
      );
      await _atualizar(null);
    });
  }

  Future<void> _encerrar(MatriculaDoCadastro matricula) async {
    final dataFim = await _escolherData(
      _hoje.compareTo(matricula.dataInicio) < 0 ? matricula.dataInicio : _hoje,
      primeira: matricula.dataInicio,
      titulo: 'Fim da matrícula em ${matricula.turmaNome}',
    );
    if (dataFim == null) return;
    await _executar(() async {
      await _dependencias.alunos.encerrarMatricula(matricula, dataFim);
      await _atualizar(null);
    });
  }

  Future<void> _adicionarGraduacao() async {
    final escolha = await showDialog<(String, int, String)>(
      context: context,
      builder: (_) =>
          _DialogoGraduacao(hoje: _hoje, escolherData: _escolherData),
    );
    if (escolha == null) return;
    await _executar(() async {
      await _atualizar(
        await _dependencias.alunos.adicionarGraduacao(
          _id!,
          faixa: escolha.$1,
          grau: escolha.$2,
          data: escolha.$3,
        ),
      );
    });
  }

  Future<void> _excluirGraduacao(Graduacao graduacao) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir graduação'),
        content: Text(
          '${_descreverGraduacao(graduacao)} de ${formatarDataBr(graduacao.dataGraduacao)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmou != true) return;
    await _executar(() async {
      await _dependencias.alunos.excluirGraduacao(_id!, graduacao.id);
      await _atualizar(null);
    });
  }

  String _descreverGraduacao(Graduacao g) =>
      g.grau == 0 ? g.faixa : '${g.faixa} · ${g.grau}º grau';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aluno'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _carregando || _erro != null || _salvando
                ? null
                : _salvar,
            child: const Text('Salvar'),
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_erro!),
                  TextButton(
                    onPressed: _carregar,
                    child: const Text('Tentar de novo'),
                  ),
                ],
              ),
            )
          : LarguraCelular(child: _montarFormulario(context)),
    );
  }

  Widget _campo(String chave, String rotulo, {TextInputType? teclado}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: _campos[chave],
          keyboardType: teclado,
          decoration: InputDecoration(
            labelText: rotulo,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
      );

  Widget _montarFormulario(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final titulo = Theme.of(context).textTheme.titleSmall
        ?.copyWith(fontWeight: FontWeight.w600);
    final apoio = TextStyle(color: cores.onSurfaceVariant, fontSize: 13);
    final aluno = _aluno;
    return Form(
      key: _formulario,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 100,
                child: TextFormField(
                  controller: _codigo,
                  decoration: const InputDecoration(
                    labelText: 'Cód.',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Informe' : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _nome,
                  decoration: const InputDecoration(
                    labelText: 'Nome completo',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
                ),
              ),
            ],
          ),
          if (aluno == null) ...[
            const SizedBox(height: 6),
            Text('Código sugerido, pode editar', style: apoio),
          ],
          const SizedBox(height: 10),
          _Grupo(
            titulo: 'Nascimento · telefone · CPF',
            children: [
              InkWell(
                onTap: () async {
                  final data = await _escolherData(
                    _nascimento ?? '2010-01-01',
                    primeira: '1920-01-01',
                    ultima: _hoje,
                    titulo: 'Data de nascimento',
                  );
                  if (data != null) setState(() => _nascimento = data);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Nascimento',
                    border: OutlineInputBorder(),
                    isDense: true,
                    suffixIcon: Icon(Icons.calendar_month_outlined),
                  ),
                  child: Text(
                    _nascimento == null ? '' : formatarDataBr(_nascimento!),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _campo('telefone', 'Telefone', teclado: TextInputType.phone),
              _campo('email', 'E-mail', teclado: TextInputType.emailAddress),
              _campo('cpf', 'CPF', teclado: TextInputType.number),
              _campo('rg', 'RG'),
              _campo('endereco', 'Endereço'),
              _campo('observacoes', 'Observações'),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Aluno ativo'),
                value: _ativo,
                onChanged: (v) => setState(() => _ativo = v),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _Grupo(
            titulo: 'Responsáveis',
            children: [
              _campo('nome_mae', 'Nome da mãe'),
              _campo(
                'telefone_mae',
                'Telefone da mãe',
                teclado: TextInputType.phone,
              ),
              _campo('nome_pai', 'Nome do pai'),
              _campo(
                'telefone_pai',
                'Telefone do pai',
                teclado: TextInputType.phone,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Matrículas', style: titulo),
          if (aluno == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Salve o aluno para matricular e registrar graduações.',
                style: apoio,
              ),
            )
          else ...[
            for (final m in aluno.matriculas) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  m.dataFim == null
                      ? '${m.turmaNome} · desde ${formatarDataBr(m.dataInicio)}'
                      : '${m.turmaNome} · ${formatarDataBr(m.dataInicio)} a '
                            '${formatarDataBr(m.dataFim!)}',
                ),
                trailing: Text(
                  _situacoes[m.situacao] ?? m.situacao,
                  style: TextStyle(color: cores.onSurfaceVariant, fontSize: 14),
                ),
                onTap: m.dataFim == null ? () => _encerrar(m) : null,
              ),
              const Divider(height: 1),
            ],
            if (aluno.matriculas.any((m) => m.dataFim == null))
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Toque na matrícula aberta para encerrar.',
                  style: apoio,
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _matricular,
                icon: const Icon(Icons.add),
                label: const Text('Matricular'),
              ),
            ),
            const SizedBox(height: 8),
            Text('Graduações', style: titulo),
            for (final g in aluno.graduacoes) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_descreverGraduacao(g)),
                trailing: Text(
                  '${g.dataGraduacao.substring(5, 7)}/${g.dataGraduacao.substring(0, 4)}',
                  style: TextStyle(color: cores.onSurfaceVariant, fontSize: 14),
                ),
                onLongPress: () => _excluirGraduacao(g),
              ),
              const Divider(height: 1),
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _adicionarGraduacao,
                icon: const Icon(Icons.add),
                label: const Text('Graduação'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Grupo recolhido de campos (como as caixas do wireframe).
class _Grupo extends StatelessWidget {
  const _Grupo({required this.titulo, required this.children});
  final String titulo;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      border: Border.all(color: Theme.of(context).colorScheme.outline),
      borderRadius: BorderRadius.circular(8),
    ),
    child: ExpansionTile(
      title: Text(titulo),
      shape: const Border(),
      collapsedShape: const Border(),
      childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      children: children,
    ),
  );
}

typedef _EscolherData = Future<String?> Function(
  String inicial, {
  String primeira,
  String? ultima,
  String? titulo,
});

class _DialogoMatricula extends StatefulWidget {
  const _DialogoMatricula({
    required this.turmas,
    required this.hoje,
    required this.escolherData,
  });
  final List<TurmaParaMatricula> turmas;
  final String hoje;
  final _EscolherData escolherData;

  @override
  State<_DialogoMatricula> createState() => _DialogoMatriculaState();
}

class _DialogoMatriculaState extends State<_DialogoMatricula> {
  late String _turmaId = widget.turmas.first.id;
  late String _inicio = widget.hoje;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Matricular'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _turmaId,
          decoration: const InputDecoration(
            labelText: 'Turma',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final t in widget.turmas)
              DropdownMenuItem(value: t.id, child: Text(t.nome)),
          ],
          onChanged: (v) => setState(() => _turmaId = v ?? _turmaId),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async {
            final data = await widget.escolherData(
              _inicio,
              titulo: 'Início da matrícula',
            );
            if (data != null) setState(() => _inicio = data);
          },
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Início',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.calendar_month_outlined),
            ),
            child: Text(formatarDataBr(_inicio)),
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
        onPressed: () => Navigator.of(context).pop((_turmaId, _inicio)),
        child: const Text('Matricular'),
      ),
    ],
  );
}

class _DialogoGraduacao extends StatefulWidget {
  const _DialogoGraduacao({required this.hoje, required this.escolherData});
  final String hoje;
  final _EscolherData escolherData;

  @override
  State<_DialogoGraduacao> createState() => _DialogoGraduacaoState();
}

class _DialogoGraduacaoState extends State<_DialogoGraduacao> {
  String _faixa = _faixas.first;
  int _grau = 0;
  late String _data = widget.hoje;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Graduação'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _faixa,
          decoration: const InputDecoration(
            labelText: 'Faixa',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final f in _faixas) DropdownMenuItem(value: f, child: Text(f)),
          ],
          onChanged: (v) => setState(() => _faixa = v ?? _faixa),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          initialValue: _grau,
          decoration: const InputDecoration(
            labelText: 'Grau',
            border: OutlineInputBorder(),
          ),
          items: [
            for (var g = 0; g <= 10; g++)
              DropdownMenuItem(
                value: g,
                child: Text(g == 0 ? 'Sem grau' : '$gº grau'),
              ),
          ],
          onChanged: (v) => setState(() => _grau = v ?? _grau),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async {
            final data = await widget.escolherData(
              _data,
              ultima: widget.hoje,
              titulo: 'Data da graduação',
            );
            if (data != null) setState(() => _data = data);
          },
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Data',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.calendar_month_outlined),
            ),
            child: Text(formatarDataBr(_data)),
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
        onPressed: () => Navigator.of(context).pop((_faixa, _grau, _data)),
        child: const Text('Registrar'),
      ),
    ],
  );
}
