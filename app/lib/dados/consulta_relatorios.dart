// Leitura do banco local para os relatórios (tela 7): aulas lançadas, matrículas, alunos e
// presenças da turma. Tudo local, funciona offline; os totais saem de regras/relatorios.dart.
import 'package:drift/drift.dart';

import '../regras/lista_lancamento.dart';
import '../regras/relatorios.dart';
import 'banco_local.dart';

class TurmaDoRelatorio {
  const TurmaDoRelatorio({
    required this.id,
    required this.nome,
    required this.cabecalhoImpressao,
    required this.base,
  });
  final String id;
  final String nome;
  final String? cabecalhoImpressao;
  final BaseRelatorio base;
}

class ConsultaRelatorios {
  ConsultaRelatorios(this._banco);

  final BancoLocal _banco;

  Future<List<Turma>> obterTurmas() =>
      (_banco.select(_banco.turmas)
            ..where((t) => t.excluido.equals(0))
            ..orderBy([(t) => OrderingTerm.asc(t.nome)]))
          .get();

  Future<TurmaDoRelatorio> obterTurma(String turmaId) async {
    final turma = await (_banco.select(
      _banco.turmas,
    )..where((t) => t.id.equals(turmaId))).getSingle();
    final aulas = await (_banco.select(
      _banco.aulas,
    )..where((a) => a.turmaId.equals(turmaId) & a.excluido.equals(0))).get();
    final presencas =
        await (_banco.select(_banco.presencas)..where(
              (p) =>
                  p.aulaId.isIn(aulas.map((a) => a.id)) & p.excluido.equals(0),
            ))
            .get();
    final matriculas = await (_banco.select(
      _banco.matriculas,
    )..where((m) => m.turmaId.equals(turmaId) & m.excluido.equals(0))).get();
    final alunos =
        await (_banco.select(_banco.alunos)..where(
              (a) =>
                  a.id.isIn(matriculas.map((m) => m.alunoId).toSet()) &
                  a.excluido.equals(0),
            ))
            .get();
    return TurmaDoRelatorio(
      id: turma.id,
      nome: turma.nome,
      cabecalhoImpressao: turma.cabecalhoImpressao,
      base: BaseRelatorio(
        minimo: turma.frequenciaMinima,
        aulas: [
          for (final a in aulas)
            AulaDaLista(id: a.id, data: a.dataAula, tipo: a.tipo),
        ],
        presencas: [
          for (final p in presencas) (aulaId: p.aulaId, alunoId: p.alunoId),
        ],
        alunos: [
          for (final a in alunos)
            AlunoDoRelatorio(
              id: a.id,
              codigo: a.codigo,
              nome: a.nome,
              matriculas: [
                for (final m in matriculas)
                  if (m.alunoId == a.id)
                    PeriodoMatricula(
                      dataInicio: m.dataInicio,
                      dataFim: m.dataFim,
                    ),
              ],
            ),
        ],
      ),
    );
  }
}
