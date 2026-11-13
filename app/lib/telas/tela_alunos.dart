// Tela 8 — Alunos: lista, busca por nome ou código e cadastro. Online (dados vêm da API).
// O botão Importar planilha abre as telas 8b e 8c.
import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../dados/cliente_api.dart';
import '../dados/repositorio_alunos.dart';
import '../estado/dependencias.dart';
import 'componentes.dart';
import 'tema.dart';
import 'formatacao.dart';
import 'tela_aluno.dart';
import 'tela_importar_alunos.dart';

/// Mensagem para erros das telas online.
String descreverErroOnline(Object erro) => switch (erro) {
  SemConexao() => 'Sem internet. O cadastro precisa de conexão.',
  ErroApi(codigo: 'codigo_ja_existe') => 'Já existe um aluno com este código.',
  ErroApi(codigo: 'matricula_sobreposta') =>
    'O aluno já está matriculado nessa turma nesse período.',
  ErroApi(codigo: 'dados_invalidos') => 'Confira os dados informados.',
  ErroApi(codigo: 'sem_permissao') => 'Você não tem permissão para isso.',
  _ => 'Não foi possível concluir agora. Tente de novo.',
};

class TelaAlunos extends StatefulWidget {
  const TelaAlunos({super.key});

  @override
  State<TelaAlunos> createState() => _TelaAlunosState();
}

class _TelaAlunosState extends State<TelaAlunos> {
  late final RepositorioAlunos _repositorio;
  List<ResumoAluno>? _alunos;
  String? _erro;
  String _busca = '';
  Timer? _espera;
  bool _iniciado = false;
  int _consulta = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciado) return;
    _iniciado = true;
    _repositorio = EscopoDependencias.obter(context).alunos;
    unawaited(_carregar());
  }

  @override
  void dispose() {
    _espera?.cancel();
    super.dispose();
  }

  Future<void> _carregar() async {
    final consulta = ++_consulta;
    setState(() => _erro = null);
    try {
      final alunos = await _repositorio.buscarAlunos(busca: _busca);
      // Só a resposta da busca mais recente vale (o usuário pode ter digitado mais).
      if (mounted && consulta == _consulta) setState(() => _alunos = alunos);
    } on SessaoEncerrada {
      if (mounted) {
        await EscopoDependencias.obter(context).sessao.encerrarLocalmente();
      }
    } catch (erro) {
      if (mounted && consulta == _consulta) {
        setState(() => _erro = descreverErroOnline(erro));
      }
    }
  }

  void _definirBusca(String texto) {
    _busca = texto;
    _espera?.cancel();
    _espera = Timer(const Duration(milliseconds: 300), _carregar);
  }

  Future<void> _abrirAluno({String? id}) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => TelaAluno(alunoId: id)));
    if (mounted) unawaited(_carregar());
  }

  Future<void> _importar() async {
    final importou = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const TelaImportarAlunos()));
    if (importou == true && mounted) unawaited(_carregar());
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final alunos = _alunos;
    return Scaffold(
      appBar: AppBar(
        // No desktop o menu lateral faz o papel do voltar nas telas principais.
        automaticallyImplyLeading: !ehDesktop(context),
        title: const Text('Alunos'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Novo aluno',
            icon: const Icon(Symbols.add),
            onPressed: () => _abrirAluno(),
          ),
        ],
      ),
      body: LarguraCelular(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Symbols.search),
                hintText: 'Nome ou código…',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: _definirBusca,
            ),
            const SizedBox(height: 8),
            if (_erro != null) ...[
              Text(_erro!, style: TextStyle(color: cores.error)),
              OutlinedButton(
                onPressed: _carregar,
                child: const Text('Tentar de novo'),
              ),
            ] else if (alunos == null)
              const Padding(padding: EdgeInsets.all(24), child: Carregando())
            else ...[
              Text(
                'Ativos · ${alunos.length}',
                style: TextStyle(color: cores.onSurfaceVariant, fontSize: 13),
              ),
              for (final aluno in alunos) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(formatarAluno(aluno.codigo, aluno.nome)),
                  // Aluno em várias turmas: a lista não empurra o nome para fora.
                  trailing: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 140),
                    child: Text(
                      aluno.turmas.join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: cores.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  onTap: () => _abrirAluno(id: aluno.id),
                ),
                const Divider(height: 1),
              ],
              if (alunos.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('Nenhum aluno encontrado.'),
                ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _importar,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Importar planilha'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
