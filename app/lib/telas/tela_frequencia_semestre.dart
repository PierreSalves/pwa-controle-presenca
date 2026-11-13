// Tela 6 — Frequência do semestre: quem atinge a frequência mínima para a graduação.
// Presenças + reposições ÷ aulas regulares lançadas na matrícula, do início do semestre até hoje.
import 'package:material_ui/material_ui.dart';

import '../dados/consulta_inicio.dart';
import '../estado/dependencias.dart';
import '../regras/presenca.dart';
import 'componentes.dart';
import 'formatacao.dart';
import 'tema.dart';

class TelaFrequenciaSemestre extends StatefulWidget {
  const TelaFrequenciaSemestre({super.key, required this.turmaId});
  final String turmaId;

  @override
  State<TelaFrequenciaSemestre> createState() => _TelaFrequenciaSemestreState();
}

class _TelaFrequenciaSemestreState extends State<TelaFrequenciaSemestre> {
  Stream<DadosFrequenciaSemestre>? _dados;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dependencias = EscopoDependencias.obter(context);
    _dados ??= dependencias.consultaInicio.observarFrequenciaSemestre(
      widget.turmaId,
      obterHojeEmSaoPaulo(dependencias.relogio()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return StreamBuilder<DadosFrequenciaSemestre>(
      stream: _dados,
      builder: (context, snapshot) {
        final dados = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              dados == null ? 'Graduação' : 'Graduação · ${dados.turmaNome}',
            ),
            centerTitle: true,
          ),
          body: dados == null
              ? const Carregando()
              : LarguraCelular(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      InputDecorator(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        child: Text(
                          [
                            '${dados.inicio.substring(5, 7) == '01' ? '1º' : '2º'} sem. ${dados.inicio.substring(0, 4)}',
                            'até ${formatarDiaMes(dados.fim)}',
                            dados.minimo == null
                                ? 'sem mínimo definido'
                                : 'mínimo ${dados.minimo}%',
                          ].join(' · '),
                          style: TextStyle(color: cores.onSurfaceVariant),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (dados.alunos.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text('Nenhum aluno matriculado hoje.'),
                        ),
                      for (final aluno in dados.alunos) ...[
                        _LinhaFrequencia(aluno: aluno),
                        const Divider(height: 1),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        'Presenças + reposições ÷ aulas lançadas na matrícula',
                        style: TextStyle(
                          color: cores.onSurfaceVariant,
                          fontSize: 13,
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

class _LinhaFrequencia extends StatelessWidget {
  const _LinhaFrequencia({required this.aluno});
  final AlunoComFrequencia aluno;

  @override
  Widget build(BuildContext context) {
    final abaixo = aluno.frequencia.abaixoDoMinimo;
    final percentual = aluno.frequencia.percentual;
    final estilo = TextStyle(color: abaixo ? CoresWireframe.perigo : null);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(formatarAluno(aluno.codigo, aluno.nome), style: estilo),
          ),
          Semantics(
            label: abaixo ? 'abaixo do mínimo' : null,
            child: Text(
              percentual == null ? 'sem aulas' : '$percentual%',
              style: estilo.copyWith(fontFeatures: numerosFixos),
            ),
          ),
        ],
      ),
    );
  }
}
