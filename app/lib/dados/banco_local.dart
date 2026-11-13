// Banco local do app (drift: SQLite no navegador via WebAssembly). Subconjunto do esquema do D1
// (db/migrations), só com os dados mínimos para lançar presença offline: código, nome, turma,
// período da matrícula e presenças. Dados sensíveis e mensalidades nunca ficam no aparelho.
import 'package:drift/drift.dart';

part 'banco_local.g.dart';

/// Colunas comuns das tabelas sincronizadas (o server_version fica só no servidor).
mixin ColunasSync on Table {
  TextColumn get id => text()();
  IntColumn get excluido => integer().withDefault(const Constant(0))();
  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class Turmas extends Table with ColunasSync {
  TextColumn get nome => text()();
  IntColumn get frequenciaMinima => integer().nullable()();
  TextColumn get cabecalhoImpressao => text().nullable()();

  /// Regras da turma (lista do lançamento e alunos sumidos), em JSON, como vêm do pull.
  TextColumn get regras => text().withDefault(const Constant('{}'))();
}

class QuadrosAulas extends Table with ColunasSync {
  TextColumn get turmaId => text()();
  TextColumn get vigenciaInicio => text()();
  TextColumn get vigenciaFim => text().nullable()();
  IntColumn get domingo => integer()();
  IntColumn get segunda => integer()();
  IntColumn get terca => integer()();
  IntColumn get quarta => integer()();
  IntColumn get quinta => integer()();
  IntColumn get sexta => integer()();
  IntColumn get sabado => integer()();
}

class Alunos extends Table with ColunasSync {
  TextColumn get codigo => text()();
  TextColumn get nome => text()();
  IntColumn get ativo => integer().withDefault(const Constant(1))();
}

class Matriculas extends Table with ColunasSync {
  TextColumn get alunoId => text()();
  TextColumn get turmaId => text()();
  TextColumn get dataInicio => text()();
  TextColumn get dataFim => text().nullable()();
  TextColumn get situacao => text()();
}

class Aulas extends Table with ColunasSync {
  TextColumn get turmaId => text()();
  TextColumn get dataAula => text()();

  /// 'regular' ou 'reposicao'.
  TextColumn get tipo => text()();
}

class Presencas extends Table with ColunasSync {
  TextColumn get aulaId => text()();
  TextColumn get alunoId => text()();
  TextColumn get updatedBy => text().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {aulaId, alunoId},
  ];
}

/// Alterações feitas no aparelho e ainda não aceitas pela API. Uma linha por registro:
/// marcar e desmarcar o mesmo aluno antes do envio só atualiza a linha.
class Outbox extends Table {
  TextColumn get id => text()();
  TextColumn get tabela => text()();
  TextColumn get registroId => text()();
  TextColumn get payload => text()();
  IntColumn get tentativas => integer().withDefault(const Constant(0))();

  /// Código de rejeição da API (ex.: fora_da_matricula). Com erro, o item não é reenviado.
  TextColumn get erro => text().nullable()();
  TextColumn get criadoEm => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {tabela, registroId},
  ];
}

/// Estado da sincronização em chave/valor (cursor do pull, turmas permitidas).
class EstadoSync extends Table {
  TextColumn get chave => text()();
  TextColumn get valor => text()();

  @override
  Set<Column> get primaryKey => {chave};
}

@DriftDatabase(
  tables: [
    Turmas,
    QuadrosAulas,
    Alunos,
    Matriculas,
    Aulas,
    Presencas,
    Outbox,
    EstadoSync,
  ],
)
class BancoLocal extends _$BancoLocal {
  BancoLocal(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await customStatement(
        'CREATE INDEX ix_aulas_turma_data ON aulas (turma_id, data_aula)',
      );
      await customStatement(
        'CREATE INDEX ix_matriculas_turma ON matriculas (turma_id)',
      );
    },
  );

  /// Logout ou usuário revogado: apaga todos os dados locais, inclusive a outbox.
  Future<void> apagarTudo() => transaction(() async {
    for (final tabela in allTables) {
      await delete(tabela).go();
    }
  });
}
