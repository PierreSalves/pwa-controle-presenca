// Tela 10 — Turma: nome, frequência mínima, cabeçalho de impressão, quadro de aulas (cada dia:
// sem aula, regular ou reposição) com vigência, lista do lançamento, prazo de sumidos e quem
// acessa (só o professor altera). Online.
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../dados/cliente_api.dart';
import '../dados/repositorio_turmas.dart';
import '../estado/dependencias.dart';
import '../regras/presenca.dart';
import 'componentes.dart';
import 'formatacao.dart';
import 'tela_alunos.dart' show descreverErroOnline;

const _abreviados = ['dom', 'seg', 'ter', 'qua', 'qui', 'sex', 'sáb'];
const _nomesTipo = {'professor': 'professor', 'assistente': 'assistente'};

String _descreverErroTurma(Object erro) => switch (erro) {
  ErroApi(codigo: 'nome_ja_existe') => 'Já existe uma turma com este nome.',
  ErroApi(codigo: 'vigencia_anterior_ao_quadro_atual') =>
    'O novo quadro precisa começar depois do quadro atual.',
  _ => descreverErroOnline(erro),
};

class TelaTurma extends StatefulWidget {
  /// Sem [turmaId], cria uma turma nova.
  const TelaTurma({super.key, this.turmaId});
  final String? turmaId;

  @override
  State<TelaTurma> createState() => _TelaTurmaState();
}

class _TelaTurmaState extends State<TelaTurma> {
  late final Dependencias _dependencias;
  late final String _hoje;
  late final bool _ehProfessor;
  final _formulario = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _frequencia = TextEditingController();
  final _cabecalho = TextEditingController();
  final _percentual = TextEditingController(text: '30');
  final _ultimasAulas = TextEditingController(text: '8');
  final _semanas = TextEditingController(text: '4');

  String? _id;
  TurmaCompleta? _turma;
  Map<String, int> _dias = {for (final d in diasDoQuadro) d: 0};
  late String _inicioNovoQuadro;
  List<UsuarioDaTurma> _acessos = [];
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
    _inicioNovoQuadro = _hoje;
    _ehProfessor = _dependencias.sessao.usuario?.tipo == 'professor';
    _id = widget.turmaId;
    unawaited(_carregar());
  }

  @override
  void dispose() {
    for (final c in [
      _nome,
      _frequencia,
      _cabecalho,
      _percentual,
      _ultimasAulas,
      _semanas,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _mostrar(TurmaCompleta turma) {
    _turma = turma;
    _id = turma.id;
    _nome.text = turma.nome;
    _frequencia.text = turma.frequenciaMinima?.toString() ?? '';
    _cabecalho.text = turma.cabecalhoImpressao ?? '';
    _dias = Map.of(
      turma.quadroAtual?.dias ?? {for (final d in diasDoQuadro) d: 0},
    );
    _inicioNovoQuadro = _hoje;
    _percentual.text = '${turma.percentualMinimoLista}';
    _ultimasAulas.text = '${turma.ultimasAulasLista}';
    _semanas.text = '${turma.semanasSumido}';
    _acessos = List.of(turma.acessos);
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      if (_id != null) _mostrar(await _dependencias.turmas.buscarTurma(_id!));
    } on SessaoEncerrada {
      await _dependencias.sessao.encerrarLocalmente();
      return;
    } catch (erro) {
      _erro = descreverErroOnline(erro);
    }
    if (mounted) setState(() => _carregando = false);
  }

  bool get _quadroMudou {
    final atual = _turma?.quadroAtual?.dias;
    if (atual == null) return _dias.values.any((v) => v != 0);
    return diasDoQuadro.any((d) => atual[d] != _dias[d]);
  }

  bool get _regrasMudaram {
    final t = _turma;
    return t == null
        ? _percentual.text != '30' ||
              _ultimasAulas.text != '8' ||
              _semanas.text != '4'
        : int.tryParse(_percentual.text) != t.percentualMinimoLista ||
              int.tryParse(_ultimasAulas.text) != t.ultimasAulasLista ||
              int.tryParse(_semanas.text) != t.semanasSumido;
  }

  bool get _acessosMudaram {
    final antes = (_turma?.acessos ?? const []).map((u) => u.id).toSet();
    final agora = _acessos.map((u) => u.id).toSet();
    return antes.length != agora.length || !antes.containsAll(agora);
  }

  /// Há algo mudado e não salvo (consultado ao voltar).
  bool _temAlteracoes() {
    if (_carregando || _erro != null) return false;
    final t = _turma;
    final dadosMudaram = t == null
        ? _nome.text.trim().isNotEmpty ||
              _frequencia.text.isNotEmpty ||
              _cabecalho.text.trim().isNotEmpty
        : _nome.text.trim() != t.nome ||
              int.tryParse(_frequencia.text) != t.frequenciaMinima ||
              _cabecalho.text.trim() != (t.cabecalhoImpressao ?? '');
    return dadosMudaram || _quadroMudou || _regrasMudaram || _acessosMudaram;
  }

  Future<void> _salvar() async {
    if (_salvando || !_formulario.currentState!.validate()) return;
    setState(() => _salvando = true);
    final repositorio = _dependencias.turmas;
    final mensageiro = ScaffoldMessenger.of(context);
    try {
      final nova = _id == null;
      final id = await repositorio.salvarDados(
        id: _id,
        nome: _nome.text,
        frequenciaMinima: int.tryParse(_frequencia.text),
        cabecalhoImpressao: _cabecalho.text,
      );
      _id = id;
      if (_quadroMudou) {
        await repositorio.salvarQuadro(
          id,
          vigenciaInicio: _inicioNovoQuadro,
          dias: _dias,
        );
      }
      if (_regrasMudaram) {
        await repositorio.salvarRegras(
          id,
          percentualMinimo: int.parse(_percentual.text),
          ultimasAulas: int.parse(_ultimasAulas.text),
          semanasSumido: int.parse(_semanas.text),
        );
      }
      if (_ehProfessor && !nova && _acessosMudaram) {
        await repositorio.salvarAcessos(id, [for (final u in _acessos) u.id]);
      }
      final atualizada = await repositorio.buscarTurma(id);
      if (mounted) setState(() => _mostrar(atualizada));
      unawaited(_dependencias.coordenador.sincronizar());
      mensageiro.showSnackBar(
        SnackBar(content: Text(nova ? 'Turma criada.' : 'Alterações salvas.')),
      );
    } on SessaoEncerrada {
      await _dependencias.sessao.encerrarLocalmente();
    } catch (erro) {
      mensageiro.showSnackBar(
        SnackBar(content: Text(_descreverErroTurma(erro))),
      );
    }
    if (mounted) setState(() => _salvando = false);
  }

  void _alternarDia(String dia) =>
      setState(() => _dias[dia] = ((_dias[dia] ?? 0) + 1) % 3);

  Future<void> _escolherInicioQuadro() async {
    final primeiro = _turma?.quadroAtual?.vigenciaInicio ?? '2020-01-01';
    final escolhida = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(
        _inicioNovoQuadro.compareTo(primeiro) < 0
            ? primeiro
            : _inicioNovoQuadro,
      ),
      firstDate: DateTime.parse(primeiro),
      lastDate: DateTime.parse(somarDiasNaData(_hoje, 365)),
      helpText: 'O quadro novo vale a partir de',
    );
    if (escolhida != null) {
      setState(() => _inicioNovoQuadro = formatarData(escolhida));
    }
  }

  Future<void> _adicionarAcesso() async {
    final mensageiro = ScaffoldMessenger.of(context);
    List<UsuarioDaTurma> usuarios;
    try {
      usuarios = await _dependencias.turmas.buscarUsuarios();
    } catch (erro) {
      mensageiro.showSnackBar(
        SnackBar(content: Text(descreverErroOnline(erro))),
      );
      return;
    }
    final ja = _acessos.map((u) => u.id).toSet();
    final disponiveis = usuarios.where((u) => !ja.contains(u.id)).toList();
    if (!mounted) return;
    if (disponiveis.isEmpty) {
      mensageiro.showSnackBar(
        const SnackBar(content: Text('Todos os usuários já acessam a turma.')),
      );
      return;
    }
    final escolhido = await showDialog<UsuarioDaTurma>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Quem acessa'),
        children: [
          for (final u in disponiveis)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(u),
              child: Text('${u.nome} (${_nomesTipo[u.tipo] ?? u.tipo})'),
            ),
        ],
      ),
    );
    if (escolhido != null) setState(() => _acessos.add(escolhido));
  }

  @override
  Widget build(BuildContext context) {
    return ProtecaoAlteracoes(
      temAlteracoes: _temAlteracoes,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Turma'),
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
            ? const Carregando()
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
      ),
    );
  }

  String? _validarInteiro(
    String? v,
    int min,
    int max, {
    bool opcional = false,
  }) {
    if ((v == null || v.isEmpty) && opcional) return null;
    final n = int.tryParse(v ?? '');
    return n == null || n < min || n > max ? 'De $min a $max' : null;
  }

  Widget _numero(
    TextEditingController controle, {
    required String? Function(String?) validar,
  }) => SizedBox(
    width: 56,
    child: TextFormField(
      controller: controle,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: const InputDecoration(
        isDense: true,
        border: OutlineInputBorder(),
        errorStyle: TextStyle(fontSize: 0, height: 0),
      ),
      style: const TextStyle(fontWeight: FontWeight.w700),
      validator: validar,
      onChanged: (_) => setState(() {}),
    ),
  );

  Widget _montarFormulario(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final titulo = Theme.of(context).textTheme.titleSmall
        ?.copyWith(fontWeight: FontWeight.w600);
    final apoio = TextStyle(color: cores.onSurfaceVariant, fontSize: 13);
    final quadro = _turma?.quadroAtual;
    final inicioMostrado = _quadroMudou || quadro == null
        ? _inicioNovoQuadro
        : quadro.vigenciaInicio;
    return Form(
      key: _formulario,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _nome,
            decoration: const InputDecoration(
              labelText: 'Nome',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _frequencia,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Frequência mínima (%)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            validator: (v) => _validarInteiro(v, 0, 100, opcional: true),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _cabecalho,
            decoration: const InputDecoration(
              labelText: 'Cabeçalho de impressão (opcional)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _quadroMudou || quadro == null
                ? _escolherInicioQuadro
                : null,
            child: Text(
              'Quadro de aulas · desde ${formatarDataBr(inicioMostrado)}',
              style: titulo,
            ),
          ),
          const SizedBox(height: 4),
          // A dica fica fixa acima dos dias e o aviso do quadro novo vai embaixo: assim os dias
          // não mudam de lugar enquanto o usuário toca.
          Text('Toque no dia: sem aula, regular, reposição', style: apoio),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < 7; i++)
                _ChipDia(
                  rotulo: _abreviados[i],
                  valor: _dias[diasDoQuadro[i]] ?? 0,
                  aoTocar: () => _alternarDia(diasDoQuadro[i]),
                ),
            ],
          ),
          if (_quadroMudou && quadro != null) ...[
            const SizedBox(height: 6),
            Text(
              'Quadro novo a partir de ${formatarDataBr(_inicioNovoQuadro)} '
              '(toque no título para mudar). O atual termina na véspera.',
              style: apoio,
            ),
          ],
          const SizedBox(height: 16),
          Text('Lista do lançamento', style: titulo),
          const SizedBox(height: 8),
          _Caixa(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                const Text('Frequentes: ao menos'),
                _numero(
                  _percentual,
                  validar: (v) => _validarInteiro(v, 0, 100),
                ),
                const Text('% das últimas'),
                _numero(
                  _ultimasAulas,
                  validar: (v) => _validarInteiro(v, 1, 52),
                ),
                const Text('aulas'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _Caixa(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              children: [
                const Text('Avisar sumidos após'),
                _numero(_semanas, validar: (v) => _validarInteiro(v, 1, 52)),
                const Text('semanas'),
              ],
            ),
          ),
          if (_turma != null) ...[
            const SizedBox(height: 16),
            Text('Quem acessa', style: titulo),
            for (final u in _acessos) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  u.tipo == 'assistente' ? '${u.nome} (assistente)' : u.nome,
                ),
                trailing: _ehProfessor
                    ? IconButton(
                        tooltip: 'Tirar acesso de ${u.nome}',
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _acessos.remove(u)),
                      )
                    : null,
              ),
              const Divider(height: 1),
            ],
            if (_ehProfessor)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _adicionarAcesso,
                  icon: const Icon(Icons.add),
                  label: const Text('Dar acesso'),
                ),
              ),
            Text('Só professor altera os acessos', style: apoio),
          ],
        ],
      ),
    );
  }
}

class _Caixa extends StatelessWidget {
  const _Caixa({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      border: Border.all(color: Theme.of(context).colorScheme.outline),
      borderRadius: BorderRadius.circular(8),
    ),
    child: child,
  );
}

/// Dia do quadro: sem aula (claro), regular (negrito) ou reposição (negrito + "repos.").
class _ChipDia extends StatelessWidget {
  const _ChipDia({
    required this.rotulo,
    required this.valor,
    required this.aoTocar,
  });

  final String rotulo;
  final int valor;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final temAula = valor != 0;
    final descricao = switch (valor) {
      1 => 'regular',
      2 => 'reposição',
      _ => 'sem aula',
    };
    return Semantics(
      label: '$rotulo: $descricao',
      button: true,
      child: InkWell(
        onTap: aoTocar,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: temAula ? cores.onSurface : cores.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                rotulo,
                style: TextStyle(
                  fontWeight: temAula ? FontWeight.w700 : FontWeight.w400,
                  color: temAula ? null : cores.onSurfaceVariant,
                ),
              ),
              if (valor == 2) ...[
                const SizedBox(width: 6),
                const Etiqueta('repos.'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
