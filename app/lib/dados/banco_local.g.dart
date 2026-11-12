// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'banco_local.dart';

// ignore_for_file: type=lint
class $TurmasTable extends Turmas with TableInfo<$TurmasTable, Turma> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TurmasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _excluidoMeta = const VerificationMeta(
    'excluido',
  );
  @override
  late final GeneratedColumn<int> excluido = GeneratedColumn<int>(
    'excluido',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  @override
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
    'nome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _frequenciaMinimaMeta = const VerificationMeta(
    'frequenciaMinima',
  );
  @override
  late final GeneratedColumn<int> frequenciaMinima = GeneratedColumn<int>(
    'frequencia_minima',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cabecalhoImpressaoMeta =
      const VerificationMeta('cabecalhoImpressao');
  @override
  late final GeneratedColumn<String> cabecalhoImpressao =
      GeneratedColumn<String>(
        'cabecalho_impressao',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _regrasMeta = const VerificationMeta('regras');
  @override
  late final GeneratedColumn<String> regras = GeneratedColumn<String>(
    'regras',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    excluido,
    updatedAt,
    nome,
    frequenciaMinima,
    cabecalhoImpressao,
    regras,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'turmas';
  @override
  VerificationContext validateIntegrity(
    Insertable<Turma> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('excluido')) {
      context.handle(
        _excluidoMeta,
        excluido.isAcceptableOrUnknown(data['excluido']!, _excluidoMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('nome')) {
      context.handle(
        _nomeMeta,
        nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta),
      );
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    if (data.containsKey('frequencia_minima')) {
      context.handle(
        _frequenciaMinimaMeta,
        frequenciaMinima.isAcceptableOrUnknown(
          data['frequencia_minima']!,
          _frequenciaMinimaMeta,
        ),
      );
    }
    if (data.containsKey('cabecalho_impressao')) {
      context.handle(
        _cabecalhoImpressaoMeta,
        cabecalhoImpressao.isAcceptableOrUnknown(
          data['cabecalho_impressao']!,
          _cabecalhoImpressaoMeta,
        ),
      );
    }
    if (data.containsKey('regras')) {
      context.handle(
        _regrasMeta,
        regras.isAcceptableOrUnknown(data['regras']!, _regrasMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Turma map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Turma(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      excluido: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}excluido'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      nome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nome'],
      )!,
      frequenciaMinima: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}frequencia_minima'],
      ),
      cabecalhoImpressao: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cabecalho_impressao'],
      ),
      regras: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}regras'],
      )!,
    );
  }

  @override
  $TurmasTable createAlias(String alias) {
    return $TurmasTable(attachedDatabase, alias);
  }
}

class Turma extends DataClass implements Insertable<Turma> {
  final String id;
  final int excluido;
  final String updatedAt;
  final String nome;
  final int? frequenciaMinima;
  final String? cabecalhoImpressao;

  /// Regras da turma (lista do lançamento e alunos sumidos), em JSON, como vêm do pull.
  final String regras;
  const Turma({
    required this.id,
    required this.excluido,
    required this.updatedAt,
    required this.nome,
    this.frequenciaMinima,
    this.cabecalhoImpressao,
    required this.regras,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['excluido'] = Variable<int>(excluido);
    map['updated_at'] = Variable<String>(updatedAt);
    map['nome'] = Variable<String>(nome);
    if (!nullToAbsent || frequenciaMinima != null) {
      map['frequencia_minima'] = Variable<int>(frequenciaMinima);
    }
    if (!nullToAbsent || cabecalhoImpressao != null) {
      map['cabecalho_impressao'] = Variable<String>(cabecalhoImpressao);
    }
    map['regras'] = Variable<String>(regras);
    return map;
  }

  TurmasCompanion toCompanion(bool nullToAbsent) {
    return TurmasCompanion(
      id: Value(id),
      excluido: Value(excluido),
      updatedAt: Value(updatedAt),
      nome: Value(nome),
      frequenciaMinima: frequenciaMinima == null && nullToAbsent
          ? const Value.absent()
          : Value(frequenciaMinima),
      cabecalhoImpressao: cabecalhoImpressao == null && nullToAbsent
          ? const Value.absent()
          : Value(cabecalhoImpressao),
      regras: Value(regras),
    );
  }

  factory Turma.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Turma(
      id: serializer.fromJson<String>(json['id']),
      excluido: serializer.fromJson<int>(json['excluido']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      nome: serializer.fromJson<String>(json['nome']),
      frequenciaMinima: serializer.fromJson<int?>(json['frequenciaMinima']),
      cabecalhoImpressao: serializer.fromJson<String?>(
        json['cabecalhoImpressao'],
      ),
      regras: serializer.fromJson<String>(json['regras']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'excluido': serializer.toJson<int>(excluido),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'nome': serializer.toJson<String>(nome),
      'frequenciaMinima': serializer.toJson<int?>(frequenciaMinima),
      'cabecalhoImpressao': serializer.toJson<String?>(cabecalhoImpressao),
      'regras': serializer.toJson<String>(regras),
    };
  }

  Turma copyWith({
    String? id,
    int? excluido,
    String? updatedAt,
    String? nome,
    Value<int?> frequenciaMinima = const Value.absent(),
    Value<String?> cabecalhoImpressao = const Value.absent(),
    String? regras,
  }) => Turma(
    id: id ?? this.id,
    excluido: excluido ?? this.excluido,
    updatedAt: updatedAt ?? this.updatedAt,
    nome: nome ?? this.nome,
    frequenciaMinima: frequenciaMinima.present
        ? frequenciaMinima.value
        : this.frequenciaMinima,
    cabecalhoImpressao: cabecalhoImpressao.present
        ? cabecalhoImpressao.value
        : this.cabecalhoImpressao,
    regras: regras ?? this.regras,
  );
  Turma copyWithCompanion(TurmasCompanion data) {
    return Turma(
      id: data.id.present ? data.id.value : this.id,
      excluido: data.excluido.present ? data.excluido.value : this.excluido,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      nome: data.nome.present ? data.nome.value : this.nome,
      frequenciaMinima: data.frequenciaMinima.present
          ? data.frequenciaMinima.value
          : this.frequenciaMinima,
      cabecalhoImpressao: data.cabecalhoImpressao.present
          ? data.cabecalhoImpressao.value
          : this.cabecalhoImpressao,
      regras: data.regras.present ? data.regras.value : this.regras,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Turma(')
          ..write('id: $id, ')
          ..write('excluido: $excluido, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('nome: $nome, ')
          ..write('frequenciaMinima: $frequenciaMinima, ')
          ..write('cabecalhoImpressao: $cabecalhoImpressao, ')
          ..write('regras: $regras')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    excluido,
    updatedAt,
    nome,
    frequenciaMinima,
    cabecalhoImpressao,
    regras,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Turma &&
          other.id == this.id &&
          other.excluido == this.excluido &&
          other.updatedAt == this.updatedAt &&
          other.nome == this.nome &&
          other.frequenciaMinima == this.frequenciaMinima &&
          other.cabecalhoImpressao == this.cabecalhoImpressao &&
          other.regras == this.regras);
}

class TurmasCompanion extends UpdateCompanion<Turma> {
  final Value<String> id;
  final Value<int> excluido;
  final Value<String> updatedAt;
  final Value<String> nome;
  final Value<int?> frequenciaMinima;
  final Value<String?> cabecalhoImpressao;
  final Value<String> regras;
  final Value<int> rowid;
  const TurmasCompanion({
    this.id = const Value.absent(),
    this.excluido = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.nome = const Value.absent(),
    this.frequenciaMinima = const Value.absent(),
    this.cabecalhoImpressao = const Value.absent(),
    this.regras = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TurmasCompanion.insert({
    required String id,
    this.excluido = const Value.absent(),
    required String updatedAt,
    required String nome,
    this.frequenciaMinima = const Value.absent(),
    this.cabecalhoImpressao = const Value.absent(),
    this.regras = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       nome = Value(nome);
  static Insertable<Turma> custom({
    Expression<String>? id,
    Expression<int>? excluido,
    Expression<String>? updatedAt,
    Expression<String>? nome,
    Expression<int>? frequenciaMinima,
    Expression<String>? cabecalhoImpressao,
    Expression<String>? regras,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (excluido != null) 'excluido': excluido,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (nome != null) 'nome': nome,
      if (frequenciaMinima != null) 'frequencia_minima': frequenciaMinima,
      if (cabecalhoImpressao != null) 'cabecalho_impressao': cabecalhoImpressao,
      if (regras != null) 'regras': regras,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TurmasCompanion copyWith({
    Value<String>? id,
    Value<int>? excluido,
    Value<String>? updatedAt,
    Value<String>? nome,
    Value<int?>? frequenciaMinima,
    Value<String?>? cabecalhoImpressao,
    Value<String>? regras,
    Value<int>? rowid,
  }) {
    return TurmasCompanion(
      id: id ?? this.id,
      excluido: excluido ?? this.excluido,
      updatedAt: updatedAt ?? this.updatedAt,
      nome: nome ?? this.nome,
      frequenciaMinima: frequenciaMinima ?? this.frequenciaMinima,
      cabecalhoImpressao: cabecalhoImpressao ?? this.cabecalhoImpressao,
      regras: regras ?? this.regras,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (excluido.present) {
      map['excluido'] = Variable<int>(excluido.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (frequenciaMinima.present) {
      map['frequencia_minima'] = Variable<int>(frequenciaMinima.value);
    }
    if (cabecalhoImpressao.present) {
      map['cabecalho_impressao'] = Variable<String>(cabecalhoImpressao.value);
    }
    if (regras.present) {
      map['regras'] = Variable<String>(regras.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TurmasCompanion(')
          ..write('id: $id, ')
          ..write('excluido: $excluido, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('nome: $nome, ')
          ..write('frequenciaMinima: $frequenciaMinima, ')
          ..write('cabecalhoImpressao: $cabecalhoImpressao, ')
          ..write('regras: $regras, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QuadrosAulasTable extends QuadrosAulas
    with TableInfo<$QuadrosAulasTable, QuadrosAula> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuadrosAulasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _excluidoMeta = const VerificationMeta(
    'excluido',
  );
  @override
  late final GeneratedColumn<int> excluido = GeneratedColumn<int>(
    'excluido',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _turmaIdMeta = const VerificationMeta(
    'turmaId',
  );
  @override
  late final GeneratedColumn<String> turmaId = GeneratedColumn<String>(
    'turma_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vigenciaInicioMeta = const VerificationMeta(
    'vigenciaInicio',
  );
  @override
  late final GeneratedColumn<String> vigenciaInicio = GeneratedColumn<String>(
    'vigencia_inicio',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vigenciaFimMeta = const VerificationMeta(
    'vigenciaFim',
  );
  @override
  late final GeneratedColumn<String> vigenciaFim = GeneratedColumn<String>(
    'vigencia_fim',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _domingoMeta = const VerificationMeta(
    'domingo',
  );
  @override
  late final GeneratedColumn<int> domingo = GeneratedColumn<int>(
    'domingo',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _segundaMeta = const VerificationMeta(
    'segunda',
  );
  @override
  late final GeneratedColumn<int> segunda = GeneratedColumn<int>(
    'segunda',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tercaMeta = const VerificationMeta('terca');
  @override
  late final GeneratedColumn<int> terca = GeneratedColumn<int>(
    'terca',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quartaMeta = const VerificationMeta('quarta');
  @override
  late final GeneratedColumn<int> quarta = GeneratedColumn<int>(
    'quarta',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quintaMeta = const VerificationMeta('quinta');
  @override
  late final GeneratedColumn<int> quinta = GeneratedColumn<int>(
    'quinta',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sextaMeta = const VerificationMeta('sexta');
  @override
  late final GeneratedColumn<int> sexta = GeneratedColumn<int>(
    'sexta',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sabadoMeta = const VerificationMeta('sabado');
  @override
  late final GeneratedColumn<int> sabado = GeneratedColumn<int>(
    'sabado',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    excluido,
    updatedAt,
    turmaId,
    vigenciaInicio,
    vigenciaFim,
    domingo,
    segunda,
    terca,
    quarta,
    quinta,
    sexta,
    sabado,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quadros_aulas';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuadrosAula> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('excluido')) {
      context.handle(
        _excluidoMeta,
        excluido.isAcceptableOrUnknown(data['excluido']!, _excluidoMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('turma_id')) {
      context.handle(
        _turmaIdMeta,
        turmaId.isAcceptableOrUnknown(data['turma_id']!, _turmaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_turmaIdMeta);
    }
    if (data.containsKey('vigencia_inicio')) {
      context.handle(
        _vigenciaInicioMeta,
        vigenciaInicio.isAcceptableOrUnknown(
          data['vigencia_inicio']!,
          _vigenciaInicioMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_vigenciaInicioMeta);
    }
    if (data.containsKey('vigencia_fim')) {
      context.handle(
        _vigenciaFimMeta,
        vigenciaFim.isAcceptableOrUnknown(
          data['vigencia_fim']!,
          _vigenciaFimMeta,
        ),
      );
    }
    if (data.containsKey('domingo')) {
      context.handle(
        _domingoMeta,
        domingo.isAcceptableOrUnknown(data['domingo']!, _domingoMeta),
      );
    } else if (isInserting) {
      context.missing(_domingoMeta);
    }
    if (data.containsKey('segunda')) {
      context.handle(
        _segundaMeta,
        segunda.isAcceptableOrUnknown(data['segunda']!, _segundaMeta),
      );
    } else if (isInserting) {
      context.missing(_segundaMeta);
    }
    if (data.containsKey('terca')) {
      context.handle(
        _tercaMeta,
        terca.isAcceptableOrUnknown(data['terca']!, _tercaMeta),
      );
    } else if (isInserting) {
      context.missing(_tercaMeta);
    }
    if (data.containsKey('quarta')) {
      context.handle(
        _quartaMeta,
        quarta.isAcceptableOrUnknown(data['quarta']!, _quartaMeta),
      );
    } else if (isInserting) {
      context.missing(_quartaMeta);
    }
    if (data.containsKey('quinta')) {
      context.handle(
        _quintaMeta,
        quinta.isAcceptableOrUnknown(data['quinta']!, _quintaMeta),
      );
    } else if (isInserting) {
      context.missing(_quintaMeta);
    }
    if (data.containsKey('sexta')) {
      context.handle(
        _sextaMeta,
        sexta.isAcceptableOrUnknown(data['sexta']!, _sextaMeta),
      );
    } else if (isInserting) {
      context.missing(_sextaMeta);
    }
    if (data.containsKey('sabado')) {
      context.handle(
        _sabadoMeta,
        sabado.isAcceptableOrUnknown(data['sabado']!, _sabadoMeta),
      );
    } else if (isInserting) {
      context.missing(_sabadoMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QuadrosAula map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuadrosAula(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      excluido: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}excluido'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      turmaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}turma_id'],
      )!,
      vigenciaInicio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vigencia_inicio'],
      )!,
      vigenciaFim: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vigencia_fim'],
      ),
      domingo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}domingo'],
      )!,
      segunda: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}segunda'],
      )!,
      terca: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}terca'],
      )!,
      quarta: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quarta'],
      )!,
      quinta: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quinta'],
      )!,
      sexta: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sexta'],
      )!,
      sabado: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sabado'],
      )!,
    );
  }

  @override
  $QuadrosAulasTable createAlias(String alias) {
    return $QuadrosAulasTable(attachedDatabase, alias);
  }
}

class QuadrosAula extends DataClass implements Insertable<QuadrosAula> {
  final String id;
  final int excluido;
  final String updatedAt;
  final String turmaId;
  final String vigenciaInicio;
  final String? vigenciaFim;
  final int domingo;
  final int segunda;
  final int terca;
  final int quarta;
  final int quinta;
  final int sexta;
  final int sabado;
  const QuadrosAula({
    required this.id,
    required this.excluido,
    required this.updatedAt,
    required this.turmaId,
    required this.vigenciaInicio,
    this.vigenciaFim,
    required this.domingo,
    required this.segunda,
    required this.terca,
    required this.quarta,
    required this.quinta,
    required this.sexta,
    required this.sabado,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['excluido'] = Variable<int>(excluido);
    map['updated_at'] = Variable<String>(updatedAt);
    map['turma_id'] = Variable<String>(turmaId);
    map['vigencia_inicio'] = Variable<String>(vigenciaInicio);
    if (!nullToAbsent || vigenciaFim != null) {
      map['vigencia_fim'] = Variable<String>(vigenciaFim);
    }
    map['domingo'] = Variable<int>(domingo);
    map['segunda'] = Variable<int>(segunda);
    map['terca'] = Variable<int>(terca);
    map['quarta'] = Variable<int>(quarta);
    map['quinta'] = Variable<int>(quinta);
    map['sexta'] = Variable<int>(sexta);
    map['sabado'] = Variable<int>(sabado);
    return map;
  }

  QuadrosAulasCompanion toCompanion(bool nullToAbsent) {
    return QuadrosAulasCompanion(
      id: Value(id),
      excluido: Value(excluido),
      updatedAt: Value(updatedAt),
      turmaId: Value(turmaId),
      vigenciaInicio: Value(vigenciaInicio),
      vigenciaFim: vigenciaFim == null && nullToAbsent
          ? const Value.absent()
          : Value(vigenciaFim),
      domingo: Value(domingo),
      segunda: Value(segunda),
      terca: Value(terca),
      quarta: Value(quarta),
      quinta: Value(quinta),
      sexta: Value(sexta),
      sabado: Value(sabado),
    );
  }

  factory QuadrosAula.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuadrosAula(
      id: serializer.fromJson<String>(json['id']),
      excluido: serializer.fromJson<int>(json['excluido']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      turmaId: serializer.fromJson<String>(json['turmaId']),
      vigenciaInicio: serializer.fromJson<String>(json['vigenciaInicio']),
      vigenciaFim: serializer.fromJson<String?>(json['vigenciaFim']),
      domingo: serializer.fromJson<int>(json['domingo']),
      segunda: serializer.fromJson<int>(json['segunda']),
      terca: serializer.fromJson<int>(json['terca']),
      quarta: serializer.fromJson<int>(json['quarta']),
      quinta: serializer.fromJson<int>(json['quinta']),
      sexta: serializer.fromJson<int>(json['sexta']),
      sabado: serializer.fromJson<int>(json['sabado']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'excluido': serializer.toJson<int>(excluido),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'turmaId': serializer.toJson<String>(turmaId),
      'vigenciaInicio': serializer.toJson<String>(vigenciaInicio),
      'vigenciaFim': serializer.toJson<String?>(vigenciaFim),
      'domingo': serializer.toJson<int>(domingo),
      'segunda': serializer.toJson<int>(segunda),
      'terca': serializer.toJson<int>(terca),
      'quarta': serializer.toJson<int>(quarta),
      'quinta': serializer.toJson<int>(quinta),
      'sexta': serializer.toJson<int>(sexta),
      'sabado': serializer.toJson<int>(sabado),
    };
  }

  QuadrosAula copyWith({
    String? id,
    int? excluido,
    String? updatedAt,
    String? turmaId,
    String? vigenciaInicio,
    Value<String?> vigenciaFim = const Value.absent(),
    int? domingo,
    int? segunda,
    int? terca,
    int? quarta,
    int? quinta,
    int? sexta,
    int? sabado,
  }) => QuadrosAula(
    id: id ?? this.id,
    excluido: excluido ?? this.excluido,
    updatedAt: updatedAt ?? this.updatedAt,
    turmaId: turmaId ?? this.turmaId,
    vigenciaInicio: vigenciaInicio ?? this.vigenciaInicio,
    vigenciaFim: vigenciaFim.present ? vigenciaFim.value : this.vigenciaFim,
    domingo: domingo ?? this.domingo,
    segunda: segunda ?? this.segunda,
    terca: terca ?? this.terca,
    quarta: quarta ?? this.quarta,
    quinta: quinta ?? this.quinta,
    sexta: sexta ?? this.sexta,
    sabado: sabado ?? this.sabado,
  );
  QuadrosAula copyWithCompanion(QuadrosAulasCompanion data) {
    return QuadrosAula(
      id: data.id.present ? data.id.value : this.id,
      excluido: data.excluido.present ? data.excluido.value : this.excluido,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      turmaId: data.turmaId.present ? data.turmaId.value : this.turmaId,
      vigenciaInicio: data.vigenciaInicio.present
          ? data.vigenciaInicio.value
          : this.vigenciaInicio,
      vigenciaFim: data.vigenciaFim.present
          ? data.vigenciaFim.value
          : this.vigenciaFim,
      domingo: data.domingo.present ? data.domingo.value : this.domingo,
      segunda: data.segunda.present ? data.segunda.value : this.segunda,
      terca: data.terca.present ? data.terca.value : this.terca,
      quarta: data.quarta.present ? data.quarta.value : this.quarta,
      quinta: data.quinta.present ? data.quinta.value : this.quinta,
      sexta: data.sexta.present ? data.sexta.value : this.sexta,
      sabado: data.sabado.present ? data.sabado.value : this.sabado,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuadrosAula(')
          ..write('id: $id, ')
          ..write('excluido: $excluido, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('turmaId: $turmaId, ')
          ..write('vigenciaInicio: $vigenciaInicio, ')
          ..write('vigenciaFim: $vigenciaFim, ')
          ..write('domingo: $domingo, ')
          ..write('segunda: $segunda, ')
          ..write('terca: $terca, ')
          ..write('quarta: $quarta, ')
          ..write('quinta: $quinta, ')
          ..write('sexta: $sexta, ')
          ..write('sabado: $sabado')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    excluido,
    updatedAt,
    turmaId,
    vigenciaInicio,
    vigenciaFim,
    domingo,
    segunda,
    terca,
    quarta,
    quinta,
    sexta,
    sabado,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuadrosAula &&
          other.id == this.id &&
          other.excluido == this.excluido &&
          other.updatedAt == this.updatedAt &&
          other.turmaId == this.turmaId &&
          other.vigenciaInicio == this.vigenciaInicio &&
          other.vigenciaFim == this.vigenciaFim &&
          other.domingo == this.domingo &&
          other.segunda == this.segunda &&
          other.terca == this.terca &&
          other.quarta == this.quarta &&
          other.quinta == this.quinta &&
          other.sexta == this.sexta &&
          other.sabado == this.sabado);
}

class QuadrosAulasCompanion extends UpdateCompanion<QuadrosAula> {
  final Value<String> id;
  final Value<int> excluido;
  final Value<String> updatedAt;
  final Value<String> turmaId;
  final Value<String> vigenciaInicio;
  final Value<String?> vigenciaFim;
  final Value<int> domingo;
  final Value<int> segunda;
  final Value<int> terca;
  final Value<int> quarta;
  final Value<int> quinta;
  final Value<int> sexta;
  final Value<int> sabado;
  final Value<int> rowid;
  const QuadrosAulasCompanion({
    this.id = const Value.absent(),
    this.excluido = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.turmaId = const Value.absent(),
    this.vigenciaInicio = const Value.absent(),
    this.vigenciaFim = const Value.absent(),
    this.domingo = const Value.absent(),
    this.segunda = const Value.absent(),
    this.terca = const Value.absent(),
    this.quarta = const Value.absent(),
    this.quinta = const Value.absent(),
    this.sexta = const Value.absent(),
    this.sabado = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuadrosAulasCompanion.insert({
    required String id,
    this.excluido = const Value.absent(),
    required String updatedAt,
    required String turmaId,
    required String vigenciaInicio,
    this.vigenciaFim = const Value.absent(),
    required int domingo,
    required int segunda,
    required int terca,
    required int quarta,
    required int quinta,
    required int sexta,
    required int sabado,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       turmaId = Value(turmaId),
       vigenciaInicio = Value(vigenciaInicio),
       domingo = Value(domingo),
       segunda = Value(segunda),
       terca = Value(terca),
       quarta = Value(quarta),
       quinta = Value(quinta),
       sexta = Value(sexta),
       sabado = Value(sabado);
  static Insertable<QuadrosAula> custom({
    Expression<String>? id,
    Expression<int>? excluido,
    Expression<String>? updatedAt,
    Expression<String>? turmaId,
    Expression<String>? vigenciaInicio,
    Expression<String>? vigenciaFim,
    Expression<int>? domingo,
    Expression<int>? segunda,
    Expression<int>? terca,
    Expression<int>? quarta,
    Expression<int>? quinta,
    Expression<int>? sexta,
    Expression<int>? sabado,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (excluido != null) 'excluido': excluido,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (turmaId != null) 'turma_id': turmaId,
      if (vigenciaInicio != null) 'vigencia_inicio': vigenciaInicio,
      if (vigenciaFim != null) 'vigencia_fim': vigenciaFim,
      if (domingo != null) 'domingo': domingo,
      if (segunda != null) 'segunda': segunda,
      if (terca != null) 'terca': terca,
      if (quarta != null) 'quarta': quarta,
      if (quinta != null) 'quinta': quinta,
      if (sexta != null) 'sexta': sexta,
      if (sabado != null) 'sabado': sabado,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuadrosAulasCompanion copyWith({
    Value<String>? id,
    Value<int>? excluido,
    Value<String>? updatedAt,
    Value<String>? turmaId,
    Value<String>? vigenciaInicio,
    Value<String?>? vigenciaFim,
    Value<int>? domingo,
    Value<int>? segunda,
    Value<int>? terca,
    Value<int>? quarta,
    Value<int>? quinta,
    Value<int>? sexta,
    Value<int>? sabado,
    Value<int>? rowid,
  }) {
    return QuadrosAulasCompanion(
      id: id ?? this.id,
      excluido: excluido ?? this.excluido,
      updatedAt: updatedAt ?? this.updatedAt,
      turmaId: turmaId ?? this.turmaId,
      vigenciaInicio: vigenciaInicio ?? this.vigenciaInicio,
      vigenciaFim: vigenciaFim ?? this.vigenciaFim,
      domingo: domingo ?? this.domingo,
      segunda: segunda ?? this.segunda,
      terca: terca ?? this.terca,
      quarta: quarta ?? this.quarta,
      quinta: quinta ?? this.quinta,
      sexta: sexta ?? this.sexta,
      sabado: sabado ?? this.sabado,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (excluido.present) {
      map['excluido'] = Variable<int>(excluido.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (turmaId.present) {
      map['turma_id'] = Variable<String>(turmaId.value);
    }
    if (vigenciaInicio.present) {
      map['vigencia_inicio'] = Variable<String>(vigenciaInicio.value);
    }
    if (vigenciaFim.present) {
      map['vigencia_fim'] = Variable<String>(vigenciaFim.value);
    }
    if (domingo.present) {
      map['domingo'] = Variable<int>(domingo.value);
    }
    if (segunda.present) {
      map['segunda'] = Variable<int>(segunda.value);
    }
    if (terca.present) {
      map['terca'] = Variable<int>(terca.value);
    }
    if (quarta.present) {
      map['quarta'] = Variable<int>(quarta.value);
    }
    if (quinta.present) {
      map['quinta'] = Variable<int>(quinta.value);
    }
    if (sexta.present) {
      map['sexta'] = Variable<int>(sexta.value);
    }
    if (sabado.present) {
      map['sabado'] = Variable<int>(sabado.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuadrosAulasCompanion(')
          ..write('id: $id, ')
          ..write('excluido: $excluido, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('turmaId: $turmaId, ')
          ..write('vigenciaInicio: $vigenciaInicio, ')
          ..write('vigenciaFim: $vigenciaFim, ')
          ..write('domingo: $domingo, ')
          ..write('segunda: $segunda, ')
          ..write('terca: $terca, ')
          ..write('quarta: $quarta, ')
          ..write('quinta: $quinta, ')
          ..write('sexta: $sexta, ')
          ..write('sabado: $sabado, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AlunosTable extends Alunos with TableInfo<$AlunosTable, Aluno> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlunosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _excluidoMeta = const VerificationMeta(
    'excluido',
  );
  @override
  late final GeneratedColumn<int> excluido = GeneratedColumn<int>(
    'excluido',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codigoMeta = const VerificationMeta('codigo');
  @override
  late final GeneratedColumn<String> codigo = GeneratedColumn<String>(
    'codigo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  @override
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
    'nome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ativoMeta = const VerificationMeta('ativo');
  @override
  late final GeneratedColumn<int> ativo = GeneratedColumn<int>(
    'ativo',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    excluido,
    updatedAt,
    codigo,
    nome,
    ativo,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'alunos';
  @override
  VerificationContext validateIntegrity(
    Insertable<Aluno> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('excluido')) {
      context.handle(
        _excluidoMeta,
        excluido.isAcceptableOrUnknown(data['excluido']!, _excluidoMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('codigo')) {
      context.handle(
        _codigoMeta,
        codigo.isAcceptableOrUnknown(data['codigo']!, _codigoMeta),
      );
    } else if (isInserting) {
      context.missing(_codigoMeta);
    }
    if (data.containsKey('nome')) {
      context.handle(
        _nomeMeta,
        nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta),
      );
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    if (data.containsKey('ativo')) {
      context.handle(
        _ativoMeta,
        ativo.isAcceptableOrUnknown(data['ativo']!, _ativoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Aluno map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Aluno(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      excluido: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}excluido'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      codigo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}codigo'],
      )!,
      nome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nome'],
      )!,
      ativo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ativo'],
      )!,
    );
  }

  @override
  $AlunosTable createAlias(String alias) {
    return $AlunosTable(attachedDatabase, alias);
  }
}

class Aluno extends DataClass implements Insertable<Aluno> {
  final String id;
  final int excluido;
  final String updatedAt;
  final String codigo;
  final String nome;
  final int ativo;
  const Aluno({
    required this.id,
    required this.excluido,
    required this.updatedAt,
    required this.codigo,
    required this.nome,
    required this.ativo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['excluido'] = Variable<int>(excluido);
    map['updated_at'] = Variable<String>(updatedAt);
    map['codigo'] = Variable<String>(codigo);
    map['nome'] = Variable<String>(nome);
    map['ativo'] = Variable<int>(ativo);
    return map;
  }

  AlunosCompanion toCompanion(bool nullToAbsent) {
    return AlunosCompanion(
      id: Value(id),
      excluido: Value(excluido),
      updatedAt: Value(updatedAt),
      codigo: Value(codigo),
      nome: Value(nome),
      ativo: Value(ativo),
    );
  }

  factory Aluno.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Aluno(
      id: serializer.fromJson<String>(json['id']),
      excluido: serializer.fromJson<int>(json['excluido']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      codigo: serializer.fromJson<String>(json['codigo']),
      nome: serializer.fromJson<String>(json['nome']),
      ativo: serializer.fromJson<int>(json['ativo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'excluido': serializer.toJson<int>(excluido),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'codigo': serializer.toJson<String>(codigo),
      'nome': serializer.toJson<String>(nome),
      'ativo': serializer.toJson<int>(ativo),
    };
  }

  Aluno copyWith({
    String? id,
    int? excluido,
    String? updatedAt,
    String? codigo,
    String? nome,
    int? ativo,
  }) => Aluno(
    id: id ?? this.id,
    excluido: excluido ?? this.excluido,
    updatedAt: updatedAt ?? this.updatedAt,
    codigo: codigo ?? this.codigo,
    nome: nome ?? this.nome,
    ativo: ativo ?? this.ativo,
  );
  Aluno copyWithCompanion(AlunosCompanion data) {
    return Aluno(
      id: data.id.present ? data.id.value : this.id,
      excluido: data.excluido.present ? data.excluido.value : this.excluido,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      codigo: data.codigo.present ? data.codigo.value : this.codigo,
      nome: data.nome.present ? data.nome.value : this.nome,
      ativo: data.ativo.present ? data.ativo.value : this.ativo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Aluno(')
          ..write('id: $id, ')
          ..write('excluido: $excluido, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('codigo: $codigo, ')
          ..write('nome: $nome, ')
          ..write('ativo: $ativo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, excluido, updatedAt, codigo, nome, ativo);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Aluno &&
          other.id == this.id &&
          other.excluido == this.excluido &&
          other.updatedAt == this.updatedAt &&
          other.codigo == this.codigo &&
          other.nome == this.nome &&
          other.ativo == this.ativo);
}

class AlunosCompanion extends UpdateCompanion<Aluno> {
  final Value<String> id;
  final Value<int> excluido;
  final Value<String> updatedAt;
  final Value<String> codigo;
  final Value<String> nome;
  final Value<int> ativo;
  final Value<int> rowid;
  const AlunosCompanion({
    this.id = const Value.absent(),
    this.excluido = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.codigo = const Value.absent(),
    this.nome = const Value.absent(),
    this.ativo = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AlunosCompanion.insert({
    required String id,
    this.excluido = const Value.absent(),
    required String updatedAt,
    required String codigo,
    required String nome,
    this.ativo = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       codigo = Value(codigo),
       nome = Value(nome);
  static Insertable<Aluno> custom({
    Expression<String>? id,
    Expression<int>? excluido,
    Expression<String>? updatedAt,
    Expression<String>? codigo,
    Expression<String>? nome,
    Expression<int>? ativo,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (excluido != null) 'excluido': excluido,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (codigo != null) 'codigo': codigo,
      if (nome != null) 'nome': nome,
      if (ativo != null) 'ativo': ativo,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AlunosCompanion copyWith({
    Value<String>? id,
    Value<int>? excluido,
    Value<String>? updatedAt,
    Value<String>? codigo,
    Value<String>? nome,
    Value<int>? ativo,
    Value<int>? rowid,
  }) {
    return AlunosCompanion(
      id: id ?? this.id,
      excluido: excluido ?? this.excluido,
      updatedAt: updatedAt ?? this.updatedAt,
      codigo: codigo ?? this.codigo,
      nome: nome ?? this.nome,
      ativo: ativo ?? this.ativo,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (excluido.present) {
      map['excluido'] = Variable<int>(excluido.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (codigo.present) {
      map['codigo'] = Variable<String>(codigo.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (ativo.present) {
      map['ativo'] = Variable<int>(ativo.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlunosCompanion(')
          ..write('id: $id, ')
          ..write('excluido: $excluido, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('codigo: $codigo, ')
          ..write('nome: $nome, ')
          ..write('ativo: $ativo, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MatriculasTable extends Matriculas
    with TableInfo<$MatriculasTable, Matricula> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MatriculasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _excluidoMeta = const VerificationMeta(
    'excluido',
  );
  @override
  late final GeneratedColumn<int> excluido = GeneratedColumn<int>(
    'excluido',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _alunoIdMeta = const VerificationMeta(
    'alunoId',
  );
  @override
  late final GeneratedColumn<String> alunoId = GeneratedColumn<String>(
    'aluno_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _turmaIdMeta = const VerificationMeta(
    'turmaId',
  );
  @override
  late final GeneratedColumn<String> turmaId = GeneratedColumn<String>(
    'turma_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataInicioMeta = const VerificationMeta(
    'dataInicio',
  );
  @override
  late final GeneratedColumn<String> dataInicio = GeneratedColumn<String>(
    'data_inicio',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataFimMeta = const VerificationMeta(
    'dataFim',
  );
  @override
  late final GeneratedColumn<String> dataFim = GeneratedColumn<String>(
    'data_fim',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _situacaoMeta = const VerificationMeta(
    'situacao',
  );
  @override
  late final GeneratedColumn<String> situacao = GeneratedColumn<String>(
    'situacao',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    excluido,
    updatedAt,
    alunoId,
    turmaId,
    dataInicio,
    dataFim,
    situacao,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'matriculas';
  @override
  VerificationContext validateIntegrity(
    Insertable<Matricula> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('excluido')) {
      context.handle(
        _excluidoMeta,
        excluido.isAcceptableOrUnknown(data['excluido']!, _excluidoMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('aluno_id')) {
      context.handle(
        _alunoIdMeta,
        alunoId.isAcceptableOrUnknown(data['aluno_id']!, _alunoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_alunoIdMeta);
    }
    if (data.containsKey('turma_id')) {
      context.handle(
        _turmaIdMeta,
        turmaId.isAcceptableOrUnknown(data['turma_id']!, _turmaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_turmaIdMeta);
    }
    if (data.containsKey('data_inicio')) {
      context.handle(
        _dataInicioMeta,
        dataInicio.isAcceptableOrUnknown(data['data_inicio']!, _dataInicioMeta),
      );
    } else if (isInserting) {
      context.missing(_dataInicioMeta);
    }
    if (data.containsKey('data_fim')) {
      context.handle(
        _dataFimMeta,
        dataFim.isAcceptableOrUnknown(data['data_fim']!, _dataFimMeta),
      );
    }
    if (data.containsKey('situacao')) {
      context.handle(
        _situacaoMeta,
        situacao.isAcceptableOrUnknown(data['situacao']!, _situacaoMeta),
      );
    } else if (isInserting) {
      context.missing(_situacaoMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Matricula map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Matricula(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      excluido: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}excluido'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      alunoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}aluno_id'],
      )!,
      turmaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}turma_id'],
      )!,
      dataInicio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data_inicio'],
      )!,
      dataFim: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data_fim'],
      ),
      situacao: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}situacao'],
      )!,
    );
  }

  @override
  $MatriculasTable createAlias(String alias) {
    return $MatriculasTable(attachedDatabase, alias);
  }
}

class Matricula extends DataClass implements Insertable<Matricula> {
  final String id;
  final int excluido;
  final String updatedAt;
  final String alunoId;
  final String turmaId;
  final String dataInicio;
  final String? dataFim;
  final String situacao;
  const Matricula({
    required this.id,
    required this.excluido,
    required this.updatedAt,
    required this.alunoId,
    required this.turmaId,
    required this.dataInicio,
    this.dataFim,
    required this.situacao,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['excluido'] = Variable<int>(excluido);
    map['updated_at'] = Variable<String>(updatedAt);
    map['aluno_id'] = Variable<String>(alunoId);
    map['turma_id'] = Variable<String>(turmaId);
    map['data_inicio'] = Variable<String>(dataInicio);
    if (!nullToAbsent || dataFim != null) {
      map['data_fim'] = Variable<String>(dataFim);
    }
    map['situacao'] = Variable<String>(situacao);
    return map;
  }

  MatriculasCompanion toCompanion(bool nullToAbsent) {
    return MatriculasCompanion(
      id: Value(id),
      excluido: Value(excluido),
      updatedAt: Value(updatedAt),
      alunoId: Value(alunoId),
      turmaId: Value(turmaId),
      dataInicio: Value(dataInicio),
      dataFim: dataFim == null && nullToAbsent
          ? const Value.absent()
          : Value(dataFim),
      situacao: Value(situacao),
    );
  }

  factory Matricula.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Matricula(
      id: serializer.fromJson<String>(json['id']),
      excluido: serializer.fromJson<int>(json['excluido']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      alunoId: serializer.fromJson<String>(json['alunoId']),
      turmaId: serializer.fromJson<String>(json['turmaId']),
      dataInicio: serializer.fromJson<String>(json['dataInicio']),
      dataFim: serializer.fromJson<String?>(json['dataFim']),
      situacao: serializer.fromJson<String>(json['situacao']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'excluido': serializer.toJson<int>(excluido),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'alunoId': serializer.toJson<String>(alunoId),
      'turmaId': serializer.toJson<String>(turmaId),
      'dataInicio': serializer.toJson<String>(dataInicio),
      'dataFim': serializer.toJson<String?>(dataFim),
      'situacao': serializer.toJson<String>(situacao),
    };
  }

  Matricula copyWith({
    String? id,
    int? excluido,
    String? updatedAt,
    String? alunoId,
    String? turmaId,
    String? dataInicio,
    Value<String?> dataFim = const Value.absent(),
    String? situacao,
  }) => Matricula(
    id: id ?? this.id,
    excluido: excluido ?? this.excluido,
    updatedAt: updatedAt ?? this.updatedAt,
    alunoId: alunoId ?? this.alunoId,
    turmaId: turmaId ?? this.turmaId,
    dataInicio: dataInicio ?? this.dataInicio,
    dataFim: dataFim.present ? dataFim.value : this.dataFim,
    situacao: situacao ?? this.situacao,
  );
  Matricula copyWithCompanion(MatriculasCompanion data) {
    return Matricula(
      id: data.id.present ? data.id.value : this.id,
      excluido: data.excluido.present ? data.excluido.value : this.excluido,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      alunoId: data.alunoId.present ? data.alunoId.value : this.alunoId,
      turmaId: data.turmaId.present ? data.turmaId.value : this.turmaId,
      dataInicio: data.dataInicio.present
          ? data.dataInicio.value
          : this.dataInicio,
      dataFim: data.dataFim.present ? data.dataFim.value : this.dataFim,
      situacao: data.situacao.present ? data.situacao.value : this.situacao,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Matricula(')
          ..write('id: $id, ')
          ..write('excluido: $excluido, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('alunoId: $alunoId, ')
          ..write('turmaId: $turmaId, ')
          ..write('dataInicio: $dataInicio, ')
          ..write('dataFim: $dataFim, ')
          ..write('situacao: $situacao')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    excluido,
    updatedAt,
    alunoId,
    turmaId,
    dataInicio,
    dataFim,
    situacao,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Matricula &&
          other.id == this.id &&
          other.excluido == this.excluido &&
          other.updatedAt == this.updatedAt &&
          other.alunoId == this.alunoId &&
          other.turmaId == this.turmaId &&
          other.dataInicio == this.dataInicio &&
          other.dataFim == this.dataFim &&
          other.situacao == this.situacao);
}

class MatriculasCompanion extends UpdateCompanion<Matricula> {
  final Value<String> id;
  final Value<int> excluido;
  final Value<String> updatedAt;
  final Value<String> alunoId;
  final Value<String> turmaId;
  final Value<String> dataInicio;
  final Value<String?> dataFim;
  final Value<String> situacao;
  final Value<int> rowid;
  const MatriculasCompanion({
    this.id = const Value.absent(),
    this.excluido = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.alunoId = const Value.absent(),
    this.turmaId = const Value.absent(),
    this.dataInicio = const Value.absent(),
    this.dataFim = const Value.absent(),
    this.situacao = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MatriculasCompanion.insert({
    required String id,
    this.excluido = const Value.absent(),
    required String updatedAt,
    required String alunoId,
    required String turmaId,
    required String dataInicio,
    this.dataFim = const Value.absent(),
    required String situacao,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       alunoId = Value(alunoId),
       turmaId = Value(turmaId),
       dataInicio = Value(dataInicio),
       situacao = Value(situacao);
  static Insertable<Matricula> custom({
    Expression<String>? id,
    Expression<int>? excluido,
    Expression<String>? updatedAt,
    Expression<String>? alunoId,
    Expression<String>? turmaId,
    Expression<String>? dataInicio,
    Expression<String>? dataFim,
    Expression<String>? situacao,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (excluido != null) 'excluido': excluido,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (alunoId != null) 'aluno_id': alunoId,
      if (turmaId != null) 'turma_id': turmaId,
      if (dataInicio != null) 'data_inicio': dataInicio,
      if (dataFim != null) 'data_fim': dataFim,
      if (situacao != null) 'situacao': situacao,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MatriculasCompanion copyWith({
    Value<String>? id,
    Value<int>? excluido,
    Value<String>? updatedAt,
    Value<String>? alunoId,
    Value<String>? turmaId,
    Value<String>? dataInicio,
    Value<String?>? dataFim,
    Value<String>? situacao,
    Value<int>? rowid,
  }) {
    return MatriculasCompanion(
      id: id ?? this.id,
      excluido: excluido ?? this.excluido,
      updatedAt: updatedAt ?? this.updatedAt,
      alunoId: alunoId ?? this.alunoId,
      turmaId: turmaId ?? this.turmaId,
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
      situacao: situacao ?? this.situacao,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (excluido.present) {
      map['excluido'] = Variable<int>(excluido.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (alunoId.present) {
      map['aluno_id'] = Variable<String>(alunoId.value);
    }
    if (turmaId.present) {
      map['turma_id'] = Variable<String>(turmaId.value);
    }
    if (dataInicio.present) {
      map['data_inicio'] = Variable<String>(dataInicio.value);
    }
    if (dataFim.present) {
      map['data_fim'] = Variable<String>(dataFim.value);
    }
    if (situacao.present) {
      map['situacao'] = Variable<String>(situacao.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MatriculasCompanion(')
          ..write('id: $id, ')
          ..write('excluido: $excluido, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('alunoId: $alunoId, ')
          ..write('turmaId: $turmaId, ')
          ..write('dataInicio: $dataInicio, ')
          ..write('dataFim: $dataFim, ')
          ..write('situacao: $situacao, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AulasTable extends Aulas with TableInfo<$AulasTable, Aula> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AulasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _excluidoMeta = const VerificationMeta(
    'excluido',
  );
  @override
  late final GeneratedColumn<int> excluido = GeneratedColumn<int>(
    'excluido',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _turmaIdMeta = const VerificationMeta(
    'turmaId',
  );
  @override
  late final GeneratedColumn<String> turmaId = GeneratedColumn<String>(
    'turma_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataAulaMeta = const VerificationMeta(
    'dataAula',
  );
  @override
  late final GeneratedColumn<String> dataAula = GeneratedColumn<String>(
    'data_aula',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
    'tipo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    excluido,
    updatedAt,
    turmaId,
    dataAula,
    tipo,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'aulas';
  @override
  VerificationContext validateIntegrity(
    Insertable<Aula> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('excluido')) {
      context.handle(
        _excluidoMeta,
        excluido.isAcceptableOrUnknown(data['excluido']!, _excluidoMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('turma_id')) {
      context.handle(
        _turmaIdMeta,
        turmaId.isAcceptableOrUnknown(data['turma_id']!, _turmaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_turmaIdMeta);
    }
    if (data.containsKey('data_aula')) {
      context.handle(
        _dataAulaMeta,
        dataAula.isAcceptableOrUnknown(data['data_aula']!, _dataAulaMeta),
      );
    } else if (isInserting) {
      context.missing(_dataAulaMeta);
    }
    if (data.containsKey('tipo')) {
      context.handle(
        _tipoMeta,
        tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta),
      );
    } else if (isInserting) {
      context.missing(_tipoMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Aula map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Aula(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      excluido: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}excluido'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      turmaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}turma_id'],
      )!,
      dataAula: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data_aula'],
      )!,
      tipo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo'],
      )!,
    );
  }

  @override
  $AulasTable createAlias(String alias) {
    return $AulasTable(attachedDatabase, alias);
  }
}

class Aula extends DataClass implements Insertable<Aula> {
  final String id;
  final int excluido;
  final String updatedAt;
  final String turmaId;
  final String dataAula;

  /// 'regular' ou 'reposicao'.
  final String tipo;
  const Aula({
    required this.id,
    required this.excluido,
    required this.updatedAt,
    required this.turmaId,
    required this.dataAula,
    required this.tipo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['excluido'] = Variable<int>(excluido);
    map['updated_at'] = Variable<String>(updatedAt);
    map['turma_id'] = Variable<String>(turmaId);
    map['data_aula'] = Variable<String>(dataAula);
    map['tipo'] = Variable<String>(tipo);
    return map;
  }

  AulasCompanion toCompanion(bool nullToAbsent) {
    return AulasCompanion(
      id: Value(id),
      excluido: Value(excluido),
      updatedAt: Value(updatedAt),
      turmaId: Value(turmaId),
      dataAula: Value(dataAula),
      tipo: Value(tipo),
    );
  }

  factory Aula.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Aula(
      id: serializer.fromJson<String>(json['id']),
      excluido: serializer.fromJson<int>(json['excluido']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      turmaId: serializer.fromJson<String>(json['turmaId']),
      dataAula: serializer.fromJson<String>(json['dataAula']),
      tipo: serializer.fromJson<String>(json['tipo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'excluido': serializer.toJson<int>(excluido),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'turmaId': serializer.toJson<String>(turmaId),
      'dataAula': serializer.toJson<String>(dataAula),
      'tipo': serializer.toJson<String>(tipo),
    };
  }

  Aula copyWith({
    String? id,
    int? excluido,
    String? updatedAt,
    String? turmaId,
    String? dataAula,
    String? tipo,
  }) => Aula(
    id: id ?? this.id,
    excluido: excluido ?? this.excluido,
    updatedAt: updatedAt ?? this.updatedAt,
    turmaId: turmaId ?? this.turmaId,
    dataAula: dataAula ?? this.dataAula,
    tipo: tipo ?? this.tipo,
  );
  Aula copyWithCompanion(AulasCompanion data) {
    return Aula(
      id: data.id.present ? data.id.value : this.id,
      excluido: data.excluido.present ? data.excluido.value : this.excluido,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      turmaId: data.turmaId.present ? data.turmaId.value : this.turmaId,
      dataAula: data.dataAula.present ? data.dataAula.value : this.dataAula,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Aula(')
          ..write('id: $id, ')
          ..write('excluido: $excluido, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('turmaId: $turmaId, ')
          ..write('dataAula: $dataAula, ')
          ..write('tipo: $tipo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, excluido, updatedAt, turmaId, dataAula, tipo);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Aula &&
          other.id == this.id &&
          other.excluido == this.excluido &&
          other.updatedAt == this.updatedAt &&
          other.turmaId == this.turmaId &&
          other.dataAula == this.dataAula &&
          other.tipo == this.tipo);
}

class AulasCompanion extends UpdateCompanion<Aula> {
  final Value<String> id;
  final Value<int> excluido;
  final Value<String> updatedAt;
  final Value<String> turmaId;
  final Value<String> dataAula;
  final Value<String> tipo;
  final Value<int> rowid;
  const AulasCompanion({
    this.id = const Value.absent(),
    this.excluido = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.turmaId = const Value.absent(),
    this.dataAula = const Value.absent(),
    this.tipo = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AulasCompanion.insert({
    required String id,
    this.excluido = const Value.absent(),
    required String updatedAt,
    required String turmaId,
    required String dataAula,
    required String tipo,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       turmaId = Value(turmaId),
       dataAula = Value(dataAula),
       tipo = Value(tipo);
  static Insertable<Aula> custom({
    Expression<String>? id,
    Expression<int>? excluido,
    Expression<String>? updatedAt,
    Expression<String>? turmaId,
    Expression<String>? dataAula,
    Expression<String>? tipo,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (excluido != null) 'excluido': excluido,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (turmaId != null) 'turma_id': turmaId,
      if (dataAula != null) 'data_aula': dataAula,
      if (tipo != null) 'tipo': tipo,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AulasCompanion copyWith({
    Value<String>? id,
    Value<int>? excluido,
    Value<String>? updatedAt,
    Value<String>? turmaId,
    Value<String>? dataAula,
    Value<String>? tipo,
    Value<int>? rowid,
  }) {
    return AulasCompanion(
      id: id ?? this.id,
      excluido: excluido ?? this.excluido,
      updatedAt: updatedAt ?? this.updatedAt,
      turmaId: turmaId ?? this.turmaId,
      dataAula: dataAula ?? this.dataAula,
      tipo: tipo ?? this.tipo,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (excluido.present) {
      map['excluido'] = Variable<int>(excluido.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (turmaId.present) {
      map['turma_id'] = Variable<String>(turmaId.value);
    }
    if (dataAula.present) {
      map['data_aula'] = Variable<String>(dataAula.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AulasCompanion(')
          ..write('id: $id, ')
          ..write('excluido: $excluido, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('turmaId: $turmaId, ')
          ..write('dataAula: $dataAula, ')
          ..write('tipo: $tipo, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PresencasTable extends Presencas
    with TableInfo<$PresencasTable, Presenca> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PresencasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _excluidoMeta = const VerificationMeta(
    'excluido',
  );
  @override
  late final GeneratedColumn<int> excluido = GeneratedColumn<int>(
    'excluido',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _aulaIdMeta = const VerificationMeta('aulaId');
  @override
  late final GeneratedColumn<String> aulaId = GeneratedColumn<String>(
    'aula_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _alunoIdMeta = const VerificationMeta(
    'alunoId',
  );
  @override
  late final GeneratedColumn<String> alunoId = GeneratedColumn<String>(
    'aluno_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedByMeta = const VerificationMeta(
    'updatedBy',
  );
  @override
  late final GeneratedColumn<String> updatedBy = GeneratedColumn<String>(
    'updated_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    excluido,
    updatedAt,
    aulaId,
    alunoId,
    updatedBy,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'presencas';
  @override
  VerificationContext validateIntegrity(
    Insertable<Presenca> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('excluido')) {
      context.handle(
        _excluidoMeta,
        excluido.isAcceptableOrUnknown(data['excluido']!, _excluidoMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('aula_id')) {
      context.handle(
        _aulaIdMeta,
        aulaId.isAcceptableOrUnknown(data['aula_id']!, _aulaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_aulaIdMeta);
    }
    if (data.containsKey('aluno_id')) {
      context.handle(
        _alunoIdMeta,
        alunoId.isAcceptableOrUnknown(data['aluno_id']!, _alunoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_alunoIdMeta);
    }
    if (data.containsKey('updated_by')) {
      context.handle(
        _updatedByMeta,
        updatedBy.isAcceptableOrUnknown(data['updated_by']!, _updatedByMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {aulaId, alunoId},
  ];
  @override
  Presenca map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Presenca(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      excluido: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}excluido'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      aulaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}aula_id'],
      )!,
      alunoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}aluno_id'],
      )!,
      updatedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by'],
      ),
    );
  }

  @override
  $PresencasTable createAlias(String alias) {
    return $PresencasTable(attachedDatabase, alias);
  }
}

class Presenca extends DataClass implements Insertable<Presenca> {
  final String id;
  final int excluido;
  final String updatedAt;
  final String aulaId;
  final String alunoId;
  final String? updatedBy;
  const Presenca({
    required this.id,
    required this.excluido,
    required this.updatedAt,
    required this.aulaId,
    required this.alunoId,
    this.updatedBy,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['excluido'] = Variable<int>(excluido);
    map['updated_at'] = Variable<String>(updatedAt);
    map['aula_id'] = Variable<String>(aulaId);
    map['aluno_id'] = Variable<String>(alunoId);
    if (!nullToAbsent || updatedBy != null) {
      map['updated_by'] = Variable<String>(updatedBy);
    }
    return map;
  }

  PresencasCompanion toCompanion(bool nullToAbsent) {
    return PresencasCompanion(
      id: Value(id),
      excluido: Value(excluido),
      updatedAt: Value(updatedAt),
      aulaId: Value(aulaId),
      alunoId: Value(alunoId),
      updatedBy: updatedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedBy),
    );
  }

  factory Presenca.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Presenca(
      id: serializer.fromJson<String>(json['id']),
      excluido: serializer.fromJson<int>(json['excluido']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      aulaId: serializer.fromJson<String>(json['aulaId']),
      alunoId: serializer.fromJson<String>(json['alunoId']),
      updatedBy: serializer.fromJson<String?>(json['updatedBy']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'excluido': serializer.toJson<int>(excluido),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'aulaId': serializer.toJson<String>(aulaId),
      'alunoId': serializer.toJson<String>(alunoId),
      'updatedBy': serializer.toJson<String?>(updatedBy),
    };
  }

  Presenca copyWith({
    String? id,
    int? excluido,
    String? updatedAt,
    String? aulaId,
    String? alunoId,
    Value<String?> updatedBy = const Value.absent(),
  }) => Presenca(
    id: id ?? this.id,
    excluido: excluido ?? this.excluido,
    updatedAt: updatedAt ?? this.updatedAt,
    aulaId: aulaId ?? this.aulaId,
    alunoId: alunoId ?? this.alunoId,
    updatedBy: updatedBy.present ? updatedBy.value : this.updatedBy,
  );
  Presenca copyWithCompanion(PresencasCompanion data) {
    return Presenca(
      id: data.id.present ? data.id.value : this.id,
      excluido: data.excluido.present ? data.excluido.value : this.excluido,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      aulaId: data.aulaId.present ? data.aulaId.value : this.aulaId,
      alunoId: data.alunoId.present ? data.alunoId.value : this.alunoId,
      updatedBy: data.updatedBy.present ? data.updatedBy.value : this.updatedBy,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Presenca(')
          ..write('id: $id, ')
          ..write('excluido: $excluido, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('aulaId: $aulaId, ')
          ..write('alunoId: $alunoId, ')
          ..write('updatedBy: $updatedBy')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, excluido, updatedAt, aulaId, alunoId, updatedBy);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Presenca &&
          other.id == this.id &&
          other.excluido == this.excluido &&
          other.updatedAt == this.updatedAt &&
          other.aulaId == this.aulaId &&
          other.alunoId == this.alunoId &&
          other.updatedBy == this.updatedBy);
}

class PresencasCompanion extends UpdateCompanion<Presenca> {
  final Value<String> id;
  final Value<int> excluido;
  final Value<String> updatedAt;
  final Value<String> aulaId;
  final Value<String> alunoId;
  final Value<String?> updatedBy;
  final Value<int> rowid;
  const PresencasCompanion({
    this.id = const Value.absent(),
    this.excluido = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.aulaId = const Value.absent(),
    this.alunoId = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PresencasCompanion.insert({
    required String id,
    this.excluido = const Value.absent(),
    required String updatedAt,
    required String aulaId,
    required String alunoId,
    this.updatedBy = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       aulaId = Value(aulaId),
       alunoId = Value(alunoId);
  static Insertable<Presenca> custom({
    Expression<String>? id,
    Expression<int>? excluido,
    Expression<String>? updatedAt,
    Expression<String>? aulaId,
    Expression<String>? alunoId,
    Expression<String>? updatedBy,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (excluido != null) 'excluido': excluido,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (aulaId != null) 'aula_id': aulaId,
      if (alunoId != null) 'aluno_id': alunoId,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PresencasCompanion copyWith({
    Value<String>? id,
    Value<int>? excluido,
    Value<String>? updatedAt,
    Value<String>? aulaId,
    Value<String>? alunoId,
    Value<String?>? updatedBy,
    Value<int>? rowid,
  }) {
    return PresencasCompanion(
      id: id ?? this.id,
      excluido: excluido ?? this.excluido,
      updatedAt: updatedAt ?? this.updatedAt,
      aulaId: aulaId ?? this.aulaId,
      alunoId: alunoId ?? this.alunoId,
      updatedBy: updatedBy ?? this.updatedBy,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (excluido.present) {
      map['excluido'] = Variable<int>(excluido.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (aulaId.present) {
      map['aula_id'] = Variable<String>(aulaId.value);
    }
    if (alunoId.present) {
      map['aluno_id'] = Variable<String>(alunoId.value);
    }
    if (updatedBy.present) {
      map['updated_by'] = Variable<String>(updatedBy.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PresencasCompanion(')
          ..write('id: $id, ')
          ..write('excluido: $excluido, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('aulaId: $aulaId, ')
          ..write('alunoId: $alunoId, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxTable extends Outbox with TableInfo<$OutboxTable, OutboxData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tabelaMeta = const VerificationMeta('tabela');
  @override
  late final GeneratedColumn<String> tabela = GeneratedColumn<String>(
    'tabela',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _registroIdMeta = const VerificationMeta(
    'registroId',
  );
  @override
  late final GeneratedColumn<String> registroId = GeneratedColumn<String>(
    'registro_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tentativasMeta = const VerificationMeta(
    'tentativas',
  );
  @override
  late final GeneratedColumn<int> tentativas = GeneratedColumn<int>(
    'tentativas',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _erroMeta = const VerificationMeta('erro');
  @override
  late final GeneratedColumn<String> erro = GeneratedColumn<String>(
    'erro',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _criadoEmMeta = const VerificationMeta(
    'criadoEm',
  );
  @override
  late final GeneratedColumn<String> criadoEm = GeneratedColumn<String>(
    'criado_em',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tabela,
    registroId,
    payload,
    tentativas,
    erro,
    criadoEm,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tabela')) {
      context.handle(
        _tabelaMeta,
        tabela.isAcceptableOrUnknown(data['tabela']!, _tabelaMeta),
      );
    } else if (isInserting) {
      context.missing(_tabelaMeta);
    }
    if (data.containsKey('registro_id')) {
      context.handle(
        _registroIdMeta,
        registroId.isAcceptableOrUnknown(data['registro_id']!, _registroIdMeta),
      );
    } else if (isInserting) {
      context.missing(_registroIdMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('tentativas')) {
      context.handle(
        _tentativasMeta,
        tentativas.isAcceptableOrUnknown(data['tentativas']!, _tentativasMeta),
      );
    }
    if (data.containsKey('erro')) {
      context.handle(
        _erroMeta,
        erro.isAcceptableOrUnknown(data['erro']!, _erroMeta),
      );
    }
    if (data.containsKey('criado_em')) {
      context.handle(
        _criadoEmMeta,
        criadoEm.isAcceptableOrUnknown(data['criado_em']!, _criadoEmMeta),
      );
    } else if (isInserting) {
      context.missing(_criadoEmMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {tabela, registroId},
  ];
  @override
  OutboxData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tabela: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tabela'],
      )!,
      registroId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}registro_id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      tentativas: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tentativas'],
      )!,
      erro: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}erro'],
      ),
      criadoEm: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}criado_em'],
      )!,
    );
  }

  @override
  $OutboxTable createAlias(String alias) {
    return $OutboxTable(attachedDatabase, alias);
  }
}

class OutboxData extends DataClass implements Insertable<OutboxData> {
  final String id;
  final String tabela;
  final String registroId;
  final String payload;
  final int tentativas;

  /// Código de rejeição da API (ex.: fora_da_matricula). Com erro, o item não é reenviado.
  final String? erro;
  final String criadoEm;
  const OutboxData({
    required this.id,
    required this.tabela,
    required this.registroId,
    required this.payload,
    required this.tentativas,
    this.erro,
    required this.criadoEm,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tabela'] = Variable<String>(tabela);
    map['registro_id'] = Variable<String>(registroId);
    map['payload'] = Variable<String>(payload);
    map['tentativas'] = Variable<int>(tentativas);
    if (!nullToAbsent || erro != null) {
      map['erro'] = Variable<String>(erro);
    }
    map['criado_em'] = Variable<String>(criadoEm);
    return map;
  }

  OutboxCompanion toCompanion(bool nullToAbsent) {
    return OutboxCompanion(
      id: Value(id),
      tabela: Value(tabela),
      registroId: Value(registroId),
      payload: Value(payload),
      tentativas: Value(tentativas),
      erro: erro == null && nullToAbsent ? const Value.absent() : Value(erro),
      criadoEm: Value(criadoEm),
    );
  }

  factory OutboxData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxData(
      id: serializer.fromJson<String>(json['id']),
      tabela: serializer.fromJson<String>(json['tabela']),
      registroId: serializer.fromJson<String>(json['registroId']),
      payload: serializer.fromJson<String>(json['payload']),
      tentativas: serializer.fromJson<int>(json['tentativas']),
      erro: serializer.fromJson<String?>(json['erro']),
      criadoEm: serializer.fromJson<String>(json['criadoEm']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tabela': serializer.toJson<String>(tabela),
      'registroId': serializer.toJson<String>(registroId),
      'payload': serializer.toJson<String>(payload),
      'tentativas': serializer.toJson<int>(tentativas),
      'erro': serializer.toJson<String?>(erro),
      'criadoEm': serializer.toJson<String>(criadoEm),
    };
  }

  OutboxData copyWith({
    String? id,
    String? tabela,
    String? registroId,
    String? payload,
    int? tentativas,
    Value<String?> erro = const Value.absent(),
    String? criadoEm,
  }) => OutboxData(
    id: id ?? this.id,
    tabela: tabela ?? this.tabela,
    registroId: registroId ?? this.registroId,
    payload: payload ?? this.payload,
    tentativas: tentativas ?? this.tentativas,
    erro: erro.present ? erro.value : this.erro,
    criadoEm: criadoEm ?? this.criadoEm,
  );
  OutboxData copyWithCompanion(OutboxCompanion data) {
    return OutboxData(
      id: data.id.present ? data.id.value : this.id,
      tabela: data.tabela.present ? data.tabela.value : this.tabela,
      registroId: data.registroId.present
          ? data.registroId.value
          : this.registroId,
      payload: data.payload.present ? data.payload.value : this.payload,
      tentativas: data.tentativas.present
          ? data.tentativas.value
          : this.tentativas,
      erro: data.erro.present ? data.erro.value : this.erro,
      criadoEm: data.criadoEm.present ? data.criadoEm.value : this.criadoEm,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxData(')
          ..write('id: $id, ')
          ..write('tabela: $tabela, ')
          ..write('registroId: $registroId, ')
          ..write('payload: $payload, ')
          ..write('tentativas: $tentativas, ')
          ..write('erro: $erro, ')
          ..write('criadoEm: $criadoEm')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, tabela, registroId, payload, tentativas, erro, criadoEm);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxData &&
          other.id == this.id &&
          other.tabela == this.tabela &&
          other.registroId == this.registroId &&
          other.payload == this.payload &&
          other.tentativas == this.tentativas &&
          other.erro == this.erro &&
          other.criadoEm == this.criadoEm);
}

class OutboxCompanion extends UpdateCompanion<OutboxData> {
  final Value<String> id;
  final Value<String> tabela;
  final Value<String> registroId;
  final Value<String> payload;
  final Value<int> tentativas;
  final Value<String?> erro;
  final Value<String> criadoEm;
  final Value<int> rowid;
  const OutboxCompanion({
    this.id = const Value.absent(),
    this.tabela = const Value.absent(),
    this.registroId = const Value.absent(),
    this.payload = const Value.absent(),
    this.tentativas = const Value.absent(),
    this.erro = const Value.absent(),
    this.criadoEm = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutboxCompanion.insert({
    required String id,
    required String tabela,
    required String registroId,
    required String payload,
    this.tentativas = const Value.absent(),
    this.erro = const Value.absent(),
    required String criadoEm,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tabela = Value(tabela),
       registroId = Value(registroId),
       payload = Value(payload),
       criadoEm = Value(criadoEm);
  static Insertable<OutboxData> custom({
    Expression<String>? id,
    Expression<String>? tabela,
    Expression<String>? registroId,
    Expression<String>? payload,
    Expression<int>? tentativas,
    Expression<String>? erro,
    Expression<String>? criadoEm,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tabela != null) 'tabela': tabela,
      if (registroId != null) 'registro_id': registroId,
      if (payload != null) 'payload': payload,
      if (tentativas != null) 'tentativas': tentativas,
      if (erro != null) 'erro': erro,
      if (criadoEm != null) 'criado_em': criadoEm,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutboxCompanion copyWith({
    Value<String>? id,
    Value<String>? tabela,
    Value<String>? registroId,
    Value<String>? payload,
    Value<int>? tentativas,
    Value<String?>? erro,
    Value<String>? criadoEm,
    Value<int>? rowid,
  }) {
    return OutboxCompanion(
      id: id ?? this.id,
      tabela: tabela ?? this.tabela,
      registroId: registroId ?? this.registroId,
      payload: payload ?? this.payload,
      tentativas: tentativas ?? this.tentativas,
      erro: erro ?? this.erro,
      criadoEm: criadoEm ?? this.criadoEm,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tabela.present) {
      map['tabela'] = Variable<String>(tabela.value);
    }
    if (registroId.present) {
      map['registro_id'] = Variable<String>(registroId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (tentativas.present) {
      map['tentativas'] = Variable<int>(tentativas.value);
    }
    if (erro.present) {
      map['erro'] = Variable<String>(erro.value);
    }
    if (criadoEm.present) {
      map['criado_em'] = Variable<String>(criadoEm.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxCompanion(')
          ..write('id: $id, ')
          ..write('tabela: $tabela, ')
          ..write('registroId: $registroId, ')
          ..write('payload: $payload, ')
          ..write('tentativas: $tentativas, ')
          ..write('erro: $erro, ')
          ..write('criadoEm: $criadoEm, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EstadoSyncTable extends EstadoSync
    with TableInfo<$EstadoSyncTable, EstadoSyncData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EstadoSyncTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _chaveMeta = const VerificationMeta('chave');
  @override
  late final GeneratedColumn<String> chave = GeneratedColumn<String>(
    'chave',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valorMeta = const VerificationMeta('valor');
  @override
  late final GeneratedColumn<String> valor = GeneratedColumn<String>(
    'valor',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [chave, valor];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'estado_sync';
  @override
  VerificationContext validateIntegrity(
    Insertable<EstadoSyncData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('chave')) {
      context.handle(
        _chaveMeta,
        chave.isAcceptableOrUnknown(data['chave']!, _chaveMeta),
      );
    } else if (isInserting) {
      context.missing(_chaveMeta);
    }
    if (data.containsKey('valor')) {
      context.handle(
        _valorMeta,
        valor.isAcceptableOrUnknown(data['valor']!, _valorMeta),
      );
    } else if (isInserting) {
      context.missing(_valorMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {chave};
  @override
  EstadoSyncData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EstadoSyncData(
      chave: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chave'],
      )!,
      valor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}valor'],
      )!,
    );
  }

  @override
  $EstadoSyncTable createAlias(String alias) {
    return $EstadoSyncTable(attachedDatabase, alias);
  }
}

class EstadoSyncData extends DataClass implements Insertable<EstadoSyncData> {
  final String chave;
  final String valor;
  const EstadoSyncData({required this.chave, required this.valor});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['chave'] = Variable<String>(chave);
    map['valor'] = Variable<String>(valor);
    return map;
  }

  EstadoSyncCompanion toCompanion(bool nullToAbsent) {
    return EstadoSyncCompanion(chave: Value(chave), valor: Value(valor));
  }

  factory EstadoSyncData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EstadoSyncData(
      chave: serializer.fromJson<String>(json['chave']),
      valor: serializer.fromJson<String>(json['valor']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'chave': serializer.toJson<String>(chave),
      'valor': serializer.toJson<String>(valor),
    };
  }

  EstadoSyncData copyWith({String? chave, String? valor}) =>
      EstadoSyncData(chave: chave ?? this.chave, valor: valor ?? this.valor);
  EstadoSyncData copyWithCompanion(EstadoSyncCompanion data) {
    return EstadoSyncData(
      chave: data.chave.present ? data.chave.value : this.chave,
      valor: data.valor.present ? data.valor.value : this.valor,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EstadoSyncData(')
          ..write('chave: $chave, ')
          ..write('valor: $valor')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(chave, valor);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EstadoSyncData &&
          other.chave == this.chave &&
          other.valor == this.valor);
}

class EstadoSyncCompanion extends UpdateCompanion<EstadoSyncData> {
  final Value<String> chave;
  final Value<String> valor;
  final Value<int> rowid;
  const EstadoSyncCompanion({
    this.chave = const Value.absent(),
    this.valor = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EstadoSyncCompanion.insert({
    required String chave,
    required String valor,
    this.rowid = const Value.absent(),
  }) : chave = Value(chave),
       valor = Value(valor);
  static Insertable<EstadoSyncData> custom({
    Expression<String>? chave,
    Expression<String>? valor,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (chave != null) 'chave': chave,
      if (valor != null) 'valor': valor,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EstadoSyncCompanion copyWith({
    Value<String>? chave,
    Value<String>? valor,
    Value<int>? rowid,
  }) {
    return EstadoSyncCompanion(
      chave: chave ?? this.chave,
      valor: valor ?? this.valor,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (chave.present) {
      map['chave'] = Variable<String>(chave.value);
    }
    if (valor.present) {
      map['valor'] = Variable<String>(valor.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EstadoSyncCompanion(')
          ..write('chave: $chave, ')
          ..write('valor: $valor, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$BancoLocal extends GeneratedDatabase {
  _$BancoLocal(QueryExecutor e) : super(e);
  $BancoLocalManager get managers => $BancoLocalManager(this);
  late final $TurmasTable turmas = $TurmasTable(this);
  late final $QuadrosAulasTable quadrosAulas = $QuadrosAulasTable(this);
  late final $AlunosTable alunos = $AlunosTable(this);
  late final $MatriculasTable matriculas = $MatriculasTable(this);
  late final $AulasTable aulas = $AulasTable(this);
  late final $PresencasTable presencas = $PresencasTable(this);
  late final $OutboxTable outbox = $OutboxTable(this);
  late final $EstadoSyncTable estadoSync = $EstadoSyncTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    turmas,
    quadrosAulas,
    alunos,
    matriculas,
    aulas,
    presencas,
    outbox,
    estadoSync,
  ];
}

typedef $$TurmasTableCreateCompanionBuilder = TurmasCompanion Function({
  required String id,
  Value<int> excluido,
  required String updatedAt,
  required String nome,
  Value<int?> frequenciaMinima,
  Value<String?> cabecalhoImpressao,
  Value<String> regras,
  Value<int> rowid,
});
typedef $$TurmasTableUpdateCompanionBuilder = TurmasCompanion Function({
  Value<String> id,
  Value<int> excluido,
  Value<String> updatedAt,
  Value<String> nome,
  Value<int?> frequenciaMinima,
  Value<String?> cabecalhoImpressao,
  Value<String> regras,
  Value<int> rowid,
});

class $$TurmasTableFilterComposer extends Composer<_$BancoLocal, $TurmasTable> {
  $$TurmasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get excluido => $composableBuilder(
    column: $table.excluido,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get frequenciaMinima => $composableBuilder(
    column: $table.frequenciaMinima,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cabecalhoImpressao => $composableBuilder(
    column: $table.cabecalhoImpressao,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get regras => $composableBuilder(
    column: $table.regras,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TurmasTableOrderingComposer
    extends Composer<_$BancoLocal, $TurmasTable> {
  $$TurmasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get excluido => $composableBuilder(
    column: $table.excluido,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get frequenciaMinima => $composableBuilder(
    column: $table.frequenciaMinima,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cabecalhoImpressao => $composableBuilder(
    column: $table.cabecalhoImpressao,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get regras => $composableBuilder(
    column: $table.regras,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TurmasTableAnnotationComposer
    extends Composer<_$BancoLocal, $TurmasTable> {
  $$TurmasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get excluido =>
      $composableBuilder(column: $table.excluido, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  GeneratedColumn<int> get frequenciaMinima => $composableBuilder(
    column: $table.frequenciaMinima,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cabecalhoImpressao => $composableBuilder(
    column: $table.cabecalhoImpressao,
    builder: (column) => column,
  );

  GeneratedColumn<String> get regras =>
      $composableBuilder(column: $table.regras, builder: (column) => column);
}

class $$TurmasTableTableManager
    extends
        RootTableManager<
          _$BancoLocal,
          $TurmasTable,
          Turma,
          $$TurmasTableFilterComposer,
          $$TurmasTableOrderingComposer,
          $$TurmasTableAnnotationComposer,
          $$TurmasTableCreateCompanionBuilder,
          $$TurmasTableUpdateCompanionBuilder,
          (Turma, BaseReferences<_$BancoLocal, $TurmasTable, Turma>),
          Turma,
          PrefetchHooks Function()
        > {
  $$TurmasTableTableManager(_$BancoLocal db, $TurmasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TurmasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TurmasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TurmasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> excluido = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<String> nome = const Value.absent(),
                Value<int?> frequenciaMinima = const Value.absent(),
                Value<String?> cabecalhoImpressao = const Value.absent(),
                Value<String> regras = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TurmasCompanion(
                id: id,
                excluido: excluido,
                updatedAt: updatedAt,
                nome: nome,
                frequenciaMinima: frequenciaMinima,
                cabecalhoImpressao: cabecalhoImpressao,
                regras: regras,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<int> excluido = const Value.absent(),
                required String updatedAt,
                required String nome,
                Value<int?> frequenciaMinima = const Value.absent(),
                Value<String?> cabecalhoImpressao = const Value.absent(),
                Value<String> regras = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TurmasCompanion.insert(
                id: id,
                excluido: excluido,
                updatedAt: updatedAt,
                nome: nome,
                frequenciaMinima: frequenciaMinima,
                cabecalhoImpressao: cabecalhoImpressao,
                regras: regras,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TurmasTable, Turma>(table),
                  BaseReferences<_$BancoLocal, $TurmasTable, Turma>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TurmasTableProcessedTableManager =
    ProcessedTableManager<
      _$BancoLocal,
      $TurmasTable,
      Turma,
      $$TurmasTableFilterComposer,
      $$TurmasTableOrderingComposer,
      $$TurmasTableAnnotationComposer,
      $$TurmasTableCreateCompanionBuilder,
      $$TurmasTableUpdateCompanionBuilder,
      (Turma, BaseReferences<_$BancoLocal, $TurmasTable, Turma>),
      Turma,
      PrefetchHooks Function()
    >;
typedef $$QuadrosAulasTableCreateCompanionBuilder =
    QuadrosAulasCompanion Function({
      required String id,
      Value<int> excluido,
      required String updatedAt,
      required String turmaId,
      required String vigenciaInicio,
      Value<String?> vigenciaFim,
      required int domingo,
      required int segunda,
      required int terca,
      required int quarta,
      required int quinta,
      required int sexta,
      required int sabado,
      Value<int> rowid,
    });
typedef $$QuadrosAulasTableUpdateCompanionBuilder =
    QuadrosAulasCompanion Function({
      Value<String> id,
      Value<int> excluido,
      Value<String> updatedAt,
      Value<String> turmaId,
      Value<String> vigenciaInicio,
      Value<String?> vigenciaFim,
      Value<int> domingo,
      Value<int> segunda,
      Value<int> terca,
      Value<int> quarta,
      Value<int> quinta,
      Value<int> sexta,
      Value<int> sabado,
      Value<int> rowid,
    });

class $$QuadrosAulasTableFilterComposer
    extends Composer<_$BancoLocal, $QuadrosAulasTable> {
  $$QuadrosAulasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get excluido => $composableBuilder(
    column: $table.excluido,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get turmaId => $composableBuilder(
    column: $table.turmaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vigenciaInicio => $composableBuilder(
    column: $table.vigenciaInicio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vigenciaFim => $composableBuilder(
    column: $table.vigenciaFim,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get domingo => $composableBuilder(
    column: $table.domingo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get segunda => $composableBuilder(
    column: $table.segunda,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get terca => $composableBuilder(
    column: $table.terca,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quarta => $composableBuilder(
    column: $table.quarta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quinta => $composableBuilder(
    column: $table.quinta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sexta => $composableBuilder(
    column: $table.sexta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sabado => $composableBuilder(
    column: $table.sabado,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QuadrosAulasTableOrderingComposer
    extends Composer<_$BancoLocal, $QuadrosAulasTable> {
  $$QuadrosAulasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get excluido => $composableBuilder(
    column: $table.excluido,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get turmaId => $composableBuilder(
    column: $table.turmaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vigenciaInicio => $composableBuilder(
    column: $table.vigenciaInicio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vigenciaFim => $composableBuilder(
    column: $table.vigenciaFim,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get domingo => $composableBuilder(
    column: $table.domingo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get segunda => $composableBuilder(
    column: $table.segunda,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get terca => $composableBuilder(
    column: $table.terca,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quarta => $composableBuilder(
    column: $table.quarta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quinta => $composableBuilder(
    column: $table.quinta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sexta => $composableBuilder(
    column: $table.sexta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sabado => $composableBuilder(
    column: $table.sabado,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QuadrosAulasTableAnnotationComposer
    extends Composer<_$BancoLocal, $QuadrosAulasTable> {
  $$QuadrosAulasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get excluido =>
      $composableBuilder(column: $table.excluido, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get turmaId =>
      $composableBuilder(column: $table.turmaId, builder: (column) => column);

  GeneratedColumn<String> get vigenciaInicio => $composableBuilder(
    column: $table.vigenciaInicio,
    builder: (column) => column,
  );

  GeneratedColumn<String> get vigenciaFim => $composableBuilder(
    column: $table.vigenciaFim,
    builder: (column) => column,
  );

  GeneratedColumn<int> get domingo =>
      $composableBuilder(column: $table.domingo, builder: (column) => column);

  GeneratedColumn<int> get segunda =>
      $composableBuilder(column: $table.segunda, builder: (column) => column);

  GeneratedColumn<int> get terca =>
      $composableBuilder(column: $table.terca, builder: (column) => column);

  GeneratedColumn<int> get quarta =>
      $composableBuilder(column: $table.quarta, builder: (column) => column);

  GeneratedColumn<int> get quinta =>
      $composableBuilder(column: $table.quinta, builder: (column) => column);

  GeneratedColumn<int> get sexta =>
      $composableBuilder(column: $table.sexta, builder: (column) => column);

  GeneratedColumn<int> get sabado =>
      $composableBuilder(column: $table.sabado, builder: (column) => column);
}

class $$QuadrosAulasTableTableManager
    extends
        RootTableManager<
          _$BancoLocal,
          $QuadrosAulasTable,
          QuadrosAula,
          $$QuadrosAulasTableFilterComposer,
          $$QuadrosAulasTableOrderingComposer,
          $$QuadrosAulasTableAnnotationComposer,
          $$QuadrosAulasTableCreateCompanionBuilder,
          $$QuadrosAulasTableUpdateCompanionBuilder,
          (
            QuadrosAula,
            BaseReferences<_$BancoLocal, $QuadrosAulasTable, QuadrosAula>,
          ),
          QuadrosAula,
          PrefetchHooks Function()
        > {
  $$QuadrosAulasTableTableManager(_$BancoLocal db, $QuadrosAulasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuadrosAulasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuadrosAulasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuadrosAulasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> excluido = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<String> turmaId = const Value.absent(),
                Value<String> vigenciaInicio = const Value.absent(),
                Value<String?> vigenciaFim = const Value.absent(),
                Value<int> domingo = const Value.absent(),
                Value<int> segunda = const Value.absent(),
                Value<int> terca = const Value.absent(),
                Value<int> quarta = const Value.absent(),
                Value<int> quinta = const Value.absent(),
                Value<int> sexta = const Value.absent(),
                Value<int> sabado = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuadrosAulasCompanion(
                id: id,
                excluido: excluido,
                updatedAt: updatedAt,
                turmaId: turmaId,
                vigenciaInicio: vigenciaInicio,
                vigenciaFim: vigenciaFim,
                domingo: domingo,
                segunda: segunda,
                terca: terca,
                quarta: quarta,
                quinta: quinta,
                sexta: sexta,
                sabado: sabado,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<int> excluido = const Value.absent(),
                required String updatedAt,
                required String turmaId,
                required String vigenciaInicio,
                Value<String?> vigenciaFim = const Value.absent(),
                required int domingo,
                required int segunda,
                required int terca,
                required int quarta,
                required int quinta,
                required int sexta,
                required int sabado,
                Value<int> rowid = const Value.absent(),
              }) => QuadrosAulasCompanion.insert(
                id: id,
                excluido: excluido,
                updatedAt: updatedAt,
                turmaId: turmaId,
                vigenciaInicio: vigenciaInicio,
                vigenciaFim: vigenciaFim,
                domingo: domingo,
                segunda: segunda,
                terca: terca,
                quarta: quarta,
                quinta: quinta,
                sexta: sexta,
                sabado: sabado,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$QuadrosAulasTable, QuadrosAula>(table),
                  BaseReferences<_$BancoLocal, $QuadrosAulasTable, QuadrosAula>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QuadrosAulasTableProcessedTableManager =
    ProcessedTableManager<
      _$BancoLocal,
      $QuadrosAulasTable,
      QuadrosAula,
      $$QuadrosAulasTableFilterComposer,
      $$QuadrosAulasTableOrderingComposer,
      $$QuadrosAulasTableAnnotationComposer,
      $$QuadrosAulasTableCreateCompanionBuilder,
      $$QuadrosAulasTableUpdateCompanionBuilder,
      (
        QuadrosAula,
        BaseReferences<_$BancoLocal, $QuadrosAulasTable, QuadrosAula>,
      ),
      QuadrosAula,
      PrefetchHooks Function()
    >;
typedef $$AlunosTableCreateCompanionBuilder = AlunosCompanion Function({
  required String id,
  Value<int> excluido,
  required String updatedAt,
  required String codigo,
  required String nome,
  Value<int> ativo,
  Value<int> rowid,
});
typedef $$AlunosTableUpdateCompanionBuilder = AlunosCompanion Function({
  Value<String> id,
  Value<int> excluido,
  Value<String> updatedAt,
  Value<String> codigo,
  Value<String> nome,
  Value<int> ativo,
  Value<int> rowid,
});

class $$AlunosTableFilterComposer extends Composer<_$BancoLocal, $AlunosTable> {
  $$AlunosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get excluido => $composableBuilder(
    column: $table.excluido,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get codigo => $composableBuilder(
    column: $table.codigo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ativo => $composableBuilder(
    column: $table.ativo,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AlunosTableOrderingComposer
    extends Composer<_$BancoLocal, $AlunosTable> {
  $$AlunosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get excluido => $composableBuilder(
    column: $table.excluido,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get codigo => $composableBuilder(
    column: $table.codigo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ativo => $composableBuilder(
    column: $table.ativo,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AlunosTableAnnotationComposer
    extends Composer<_$BancoLocal, $AlunosTable> {
  $$AlunosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get excluido =>
      $composableBuilder(column: $table.excluido, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get codigo =>
      $composableBuilder(column: $table.codigo, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  GeneratedColumn<int> get ativo =>
      $composableBuilder(column: $table.ativo, builder: (column) => column);
}

class $$AlunosTableTableManager
    extends
        RootTableManager<
          _$BancoLocal,
          $AlunosTable,
          Aluno,
          $$AlunosTableFilterComposer,
          $$AlunosTableOrderingComposer,
          $$AlunosTableAnnotationComposer,
          $$AlunosTableCreateCompanionBuilder,
          $$AlunosTableUpdateCompanionBuilder,
          (Aluno, BaseReferences<_$BancoLocal, $AlunosTable, Aluno>),
          Aluno,
          PrefetchHooks Function()
        > {
  $$AlunosTableTableManager(_$BancoLocal db, $AlunosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AlunosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AlunosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AlunosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> excluido = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<String> codigo = const Value.absent(),
                Value<String> nome = const Value.absent(),
                Value<int> ativo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AlunosCompanion(
                id: id,
                excluido: excluido,
                updatedAt: updatedAt,
                codigo: codigo,
                nome: nome,
                ativo: ativo,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<int> excluido = const Value.absent(),
                required String updatedAt,
                required String codigo,
                required String nome,
                Value<int> ativo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AlunosCompanion.insert(
                id: id,
                excluido: excluido,
                updatedAt: updatedAt,
                codigo: codigo,
                nome: nome,
                ativo: ativo,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AlunosTable, Aluno>(table),
                  BaseReferences<_$BancoLocal, $AlunosTable, Aluno>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AlunosTableProcessedTableManager =
    ProcessedTableManager<
      _$BancoLocal,
      $AlunosTable,
      Aluno,
      $$AlunosTableFilterComposer,
      $$AlunosTableOrderingComposer,
      $$AlunosTableAnnotationComposer,
      $$AlunosTableCreateCompanionBuilder,
      $$AlunosTableUpdateCompanionBuilder,
      (Aluno, BaseReferences<_$BancoLocal, $AlunosTable, Aluno>),
      Aluno,
      PrefetchHooks Function()
    >;
typedef $$MatriculasTableCreateCompanionBuilder = MatriculasCompanion Function({
  required String id,
  Value<int> excluido,
  required String updatedAt,
  required String alunoId,
  required String turmaId,
  required String dataInicio,
  Value<String?> dataFim,
  required String situacao,
  Value<int> rowid,
});
typedef $$MatriculasTableUpdateCompanionBuilder = MatriculasCompanion Function({
  Value<String> id,
  Value<int> excluido,
  Value<String> updatedAt,
  Value<String> alunoId,
  Value<String> turmaId,
  Value<String> dataInicio,
  Value<String?> dataFim,
  Value<String> situacao,
  Value<int> rowid,
});

class $$MatriculasTableFilterComposer
    extends Composer<_$BancoLocal, $MatriculasTable> {
  $$MatriculasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get excluido => $composableBuilder(
    column: $table.excluido,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get alunoId => $composableBuilder(
    column: $table.alunoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get turmaId => $composableBuilder(
    column: $table.turmaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dataInicio => $composableBuilder(
    column: $table.dataInicio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dataFim => $composableBuilder(
    column: $table.dataFim,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get situacao => $composableBuilder(
    column: $table.situacao,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MatriculasTableOrderingComposer
    extends Composer<_$BancoLocal, $MatriculasTable> {
  $$MatriculasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get excluido => $composableBuilder(
    column: $table.excluido,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get alunoId => $composableBuilder(
    column: $table.alunoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get turmaId => $composableBuilder(
    column: $table.turmaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dataInicio => $composableBuilder(
    column: $table.dataInicio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dataFim => $composableBuilder(
    column: $table.dataFim,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get situacao => $composableBuilder(
    column: $table.situacao,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MatriculasTableAnnotationComposer
    extends Composer<_$BancoLocal, $MatriculasTable> {
  $$MatriculasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get excluido =>
      $composableBuilder(column: $table.excluido, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get alunoId =>
      $composableBuilder(column: $table.alunoId, builder: (column) => column);

  GeneratedColumn<String> get turmaId =>
      $composableBuilder(column: $table.turmaId, builder: (column) => column);

  GeneratedColumn<String> get dataInicio => $composableBuilder(
    column: $table.dataInicio,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dataFim =>
      $composableBuilder(column: $table.dataFim, builder: (column) => column);

  GeneratedColumn<String> get situacao =>
      $composableBuilder(column: $table.situacao, builder: (column) => column);
}

class $$MatriculasTableTableManager
    extends
        RootTableManager<
          _$BancoLocal,
          $MatriculasTable,
          Matricula,
          $$MatriculasTableFilterComposer,
          $$MatriculasTableOrderingComposer,
          $$MatriculasTableAnnotationComposer,
          $$MatriculasTableCreateCompanionBuilder,
          $$MatriculasTableUpdateCompanionBuilder,
          (
            Matricula,
            BaseReferences<_$BancoLocal, $MatriculasTable, Matricula>,
          ),
          Matricula,
          PrefetchHooks Function()
        > {
  $$MatriculasTableTableManager(_$BancoLocal db, $MatriculasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MatriculasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MatriculasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MatriculasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> excluido = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<String> alunoId = const Value.absent(),
                Value<String> turmaId = const Value.absent(),
                Value<String> dataInicio = const Value.absent(),
                Value<String?> dataFim = const Value.absent(),
                Value<String> situacao = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MatriculasCompanion(
                id: id,
                excluido: excluido,
                updatedAt: updatedAt,
                alunoId: alunoId,
                turmaId: turmaId,
                dataInicio: dataInicio,
                dataFim: dataFim,
                situacao: situacao,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<int> excluido = const Value.absent(),
                required String updatedAt,
                required String alunoId,
                required String turmaId,
                required String dataInicio,
                Value<String?> dataFim = const Value.absent(),
                required String situacao,
                Value<int> rowid = const Value.absent(),
              }) => MatriculasCompanion.insert(
                id: id,
                excluido: excluido,
                updatedAt: updatedAt,
                alunoId: alunoId,
                turmaId: turmaId,
                dataInicio: dataInicio,
                dataFim: dataFim,
                situacao: situacao,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MatriculasTable, Matricula>(table),
                  BaseReferences<_$BancoLocal, $MatriculasTable, Matricula>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MatriculasTableProcessedTableManager =
    ProcessedTableManager<
      _$BancoLocal,
      $MatriculasTable,
      Matricula,
      $$MatriculasTableFilterComposer,
      $$MatriculasTableOrderingComposer,
      $$MatriculasTableAnnotationComposer,
      $$MatriculasTableCreateCompanionBuilder,
      $$MatriculasTableUpdateCompanionBuilder,
      (Matricula, BaseReferences<_$BancoLocal, $MatriculasTable, Matricula>),
      Matricula,
      PrefetchHooks Function()
    >;
typedef $$AulasTableCreateCompanionBuilder = AulasCompanion Function({
  required String id,
  Value<int> excluido,
  required String updatedAt,
  required String turmaId,
  required String dataAula,
  required String tipo,
  Value<int> rowid,
});
typedef $$AulasTableUpdateCompanionBuilder = AulasCompanion Function({
  Value<String> id,
  Value<int> excluido,
  Value<String> updatedAt,
  Value<String> turmaId,
  Value<String> dataAula,
  Value<String> tipo,
  Value<int> rowid,
});

class $$AulasTableFilterComposer extends Composer<_$BancoLocal, $AulasTable> {
  $$AulasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get excluido => $composableBuilder(
    column: $table.excluido,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get turmaId => $composableBuilder(
    column: $table.turmaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dataAula => $composableBuilder(
    column: $table.dataAula,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AulasTableOrderingComposer extends Composer<_$BancoLocal, $AulasTable> {
  $$AulasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get excluido => $composableBuilder(
    column: $table.excluido,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get turmaId => $composableBuilder(
    column: $table.turmaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dataAula => $composableBuilder(
    column: $table.dataAula,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AulasTableAnnotationComposer
    extends Composer<_$BancoLocal, $AulasTable> {
  $$AulasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get excluido =>
      $composableBuilder(column: $table.excluido, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get turmaId =>
      $composableBuilder(column: $table.turmaId, builder: (column) => column);

  GeneratedColumn<String> get dataAula =>
      $composableBuilder(column: $table.dataAula, builder: (column) => column);

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);
}

class $$AulasTableTableManager
    extends
        RootTableManager<
          _$BancoLocal,
          $AulasTable,
          Aula,
          $$AulasTableFilterComposer,
          $$AulasTableOrderingComposer,
          $$AulasTableAnnotationComposer,
          $$AulasTableCreateCompanionBuilder,
          $$AulasTableUpdateCompanionBuilder,
          (Aula, BaseReferences<_$BancoLocal, $AulasTable, Aula>),
          Aula,
          PrefetchHooks Function()
        > {
  $$AulasTableTableManager(_$BancoLocal db, $AulasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AulasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AulasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AulasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> excluido = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<String> turmaId = const Value.absent(),
                Value<String> dataAula = const Value.absent(),
                Value<String> tipo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AulasCompanion(
                id: id,
                excluido: excluido,
                updatedAt: updatedAt,
                turmaId: turmaId,
                dataAula: dataAula,
                tipo: tipo,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<int> excluido = const Value.absent(),
                required String updatedAt,
                required String turmaId,
                required String dataAula,
                required String tipo,
                Value<int> rowid = const Value.absent(),
              }) => AulasCompanion.insert(
                id: id,
                excluido: excluido,
                updatedAt: updatedAt,
                turmaId: turmaId,
                dataAula: dataAula,
                tipo: tipo,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AulasTable, Aula>(table),
                  BaseReferences<_$BancoLocal, $AulasTable, Aula>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AulasTableProcessedTableManager =
    ProcessedTableManager<
      _$BancoLocal,
      $AulasTable,
      Aula,
      $$AulasTableFilterComposer,
      $$AulasTableOrderingComposer,
      $$AulasTableAnnotationComposer,
      $$AulasTableCreateCompanionBuilder,
      $$AulasTableUpdateCompanionBuilder,
      (Aula, BaseReferences<_$BancoLocal, $AulasTable, Aula>),
      Aula,
      PrefetchHooks Function()
    >;
typedef $$PresencasTableCreateCompanionBuilder = PresencasCompanion Function({
  required String id,
  Value<int> excluido,
  required String updatedAt,
  required String aulaId,
  required String alunoId,
  Value<String?> updatedBy,
  Value<int> rowid,
});
typedef $$PresencasTableUpdateCompanionBuilder = PresencasCompanion Function({
  Value<String> id,
  Value<int> excluido,
  Value<String> updatedAt,
  Value<String> aulaId,
  Value<String> alunoId,
  Value<String?> updatedBy,
  Value<int> rowid,
});

class $$PresencasTableFilterComposer
    extends Composer<_$BancoLocal, $PresencasTable> {
  $$PresencasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get excluido => $composableBuilder(
    column: $table.excluido,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aulaId => $composableBuilder(
    column: $table.aulaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get alunoId => $composableBuilder(
    column: $table.alunoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PresencasTableOrderingComposer
    extends Composer<_$BancoLocal, $PresencasTable> {
  $$PresencasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get excluido => $composableBuilder(
    column: $table.excluido,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aulaId => $composableBuilder(
    column: $table.aulaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get alunoId => $composableBuilder(
    column: $table.alunoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PresencasTableAnnotationComposer
    extends Composer<_$BancoLocal, $PresencasTable> {
  $$PresencasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get excluido =>
      $composableBuilder(column: $table.excluido, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get aulaId =>
      $composableBuilder(column: $table.aulaId, builder: (column) => column);

  GeneratedColumn<String> get alunoId =>
      $composableBuilder(column: $table.alunoId, builder: (column) => column);

  GeneratedColumn<String> get updatedBy =>
      $composableBuilder(column: $table.updatedBy, builder: (column) => column);
}

class $$PresencasTableTableManager
    extends
        RootTableManager<
          _$BancoLocal,
          $PresencasTable,
          Presenca,
          $$PresencasTableFilterComposer,
          $$PresencasTableOrderingComposer,
          $$PresencasTableAnnotationComposer,
          $$PresencasTableCreateCompanionBuilder,
          $$PresencasTableUpdateCompanionBuilder,
          (Presenca, BaseReferences<_$BancoLocal, $PresencasTable, Presenca>),
          Presenca,
          PrefetchHooks Function()
        > {
  $$PresencasTableTableManager(_$BancoLocal db, $PresencasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PresencasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PresencasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PresencasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> excluido = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<String> aulaId = const Value.absent(),
                Value<String> alunoId = const Value.absent(),
                Value<String?> updatedBy = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PresencasCompanion(
                id: id,
                excluido: excluido,
                updatedAt: updatedAt,
                aulaId: aulaId,
                alunoId: alunoId,
                updatedBy: updatedBy,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<int> excluido = const Value.absent(),
                required String updatedAt,
                required String aulaId,
                required String alunoId,
                Value<String?> updatedBy = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PresencasCompanion.insert(
                id: id,
                excluido: excluido,
                updatedAt: updatedAt,
                aulaId: aulaId,
                alunoId: alunoId,
                updatedBy: updatedBy,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PresencasTable, Presenca>(table),
                  BaseReferences<_$BancoLocal, $PresencasTable, Presenca>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PresencasTableProcessedTableManager =
    ProcessedTableManager<
      _$BancoLocal,
      $PresencasTable,
      Presenca,
      $$PresencasTableFilterComposer,
      $$PresencasTableOrderingComposer,
      $$PresencasTableAnnotationComposer,
      $$PresencasTableCreateCompanionBuilder,
      $$PresencasTableUpdateCompanionBuilder,
      (Presenca, BaseReferences<_$BancoLocal, $PresencasTable, Presenca>),
      Presenca,
      PrefetchHooks Function()
    >;
typedef $$OutboxTableCreateCompanionBuilder = OutboxCompanion Function({
  required String id,
  required String tabela,
  required String registroId,
  required String payload,
  Value<int> tentativas,
  Value<String?> erro,
  required String criadoEm,
  Value<int> rowid,
});
typedef $$OutboxTableUpdateCompanionBuilder = OutboxCompanion Function({
  Value<String> id,
  Value<String> tabela,
  Value<String> registroId,
  Value<String> payload,
  Value<int> tentativas,
  Value<String?> erro,
  Value<String> criadoEm,
  Value<int> rowid,
});

class $$OutboxTableFilterComposer extends Composer<_$BancoLocal, $OutboxTable> {
  $$OutboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tabela => $composableBuilder(
    column: $table.tabela,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get registroId => $composableBuilder(
    column: $table.registroId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tentativas => $composableBuilder(
    column: $table.tentativas,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get erro => $composableBuilder(
    column: $table.erro,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get criadoEm => $composableBuilder(
    column: $table.criadoEm,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxTableOrderingComposer
    extends Composer<_$BancoLocal, $OutboxTable> {
  $$OutboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tabela => $composableBuilder(
    column: $table.tabela,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get registroId => $composableBuilder(
    column: $table.registroId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tentativas => $composableBuilder(
    column: $table.tentativas,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get erro => $composableBuilder(
    column: $table.erro,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get criadoEm => $composableBuilder(
    column: $table.criadoEm,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxTableAnnotationComposer
    extends Composer<_$BancoLocal, $OutboxTable> {
  $$OutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tabela =>
      $composableBuilder(column: $table.tabela, builder: (column) => column);

  GeneratedColumn<String> get registroId => $composableBuilder(
    column: $table.registroId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get tentativas => $composableBuilder(
    column: $table.tentativas,
    builder: (column) => column,
  );

  GeneratedColumn<String> get erro =>
      $composableBuilder(column: $table.erro, builder: (column) => column);

  GeneratedColumn<String> get criadoEm =>
      $composableBuilder(column: $table.criadoEm, builder: (column) => column);
}

class $$OutboxTableTableManager
    extends
        RootTableManager<
          _$BancoLocal,
          $OutboxTable,
          OutboxData,
          $$OutboxTableFilterComposer,
          $$OutboxTableOrderingComposer,
          $$OutboxTableAnnotationComposer,
          $$OutboxTableCreateCompanionBuilder,
          $$OutboxTableUpdateCompanionBuilder,
          (OutboxData, BaseReferences<_$BancoLocal, $OutboxTable, OutboxData>),
          OutboxData,
          PrefetchHooks Function()
        > {
  $$OutboxTableTableManager(_$BancoLocal db, $OutboxTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tabela = const Value.absent(),
                Value<String> registroId = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> tentativas = const Value.absent(),
                Value<String?> erro = const Value.absent(),
                Value<String> criadoEm = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxCompanion(
                id: id,
                tabela: tabela,
                registroId: registroId,
                payload: payload,
                tentativas: tentativas,
                erro: erro,
                criadoEm: criadoEm,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tabela,
                required String registroId,
                required String payload,
                Value<int> tentativas = const Value.absent(),
                Value<String?> erro = const Value.absent(),
                required String criadoEm,
                Value<int> rowid = const Value.absent(),
              }) => OutboxCompanion.insert(
                id: id,
                tabela: tabela,
                registroId: registroId,
                payload: payload,
                tentativas: tentativas,
                erro: erro,
                criadoEm: criadoEm,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OutboxTable, OutboxData>(table),
                  BaseReferences<_$BancoLocal, $OutboxTable, OutboxData>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$BancoLocal,
      $OutboxTable,
      OutboxData,
      $$OutboxTableFilterComposer,
      $$OutboxTableOrderingComposer,
      $$OutboxTableAnnotationComposer,
      $$OutboxTableCreateCompanionBuilder,
      $$OutboxTableUpdateCompanionBuilder,
      (OutboxData, BaseReferences<_$BancoLocal, $OutboxTable, OutboxData>),
      OutboxData,
      PrefetchHooks Function()
    >;
typedef $$EstadoSyncTableCreateCompanionBuilder = EstadoSyncCompanion Function({
  required String chave,
  required String valor,
  Value<int> rowid,
});
typedef $$EstadoSyncTableUpdateCompanionBuilder = EstadoSyncCompanion Function({
  Value<String> chave,
  Value<String> valor,
  Value<int> rowid,
});

class $$EstadoSyncTableFilterComposer
    extends Composer<_$BancoLocal, $EstadoSyncTable> {
  $$EstadoSyncTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get chave => $composableBuilder(
    column: $table.chave,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valor => $composableBuilder(
    column: $table.valor,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EstadoSyncTableOrderingComposer
    extends Composer<_$BancoLocal, $EstadoSyncTable> {
  $$EstadoSyncTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get chave => $composableBuilder(
    column: $table.chave,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valor => $composableBuilder(
    column: $table.valor,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EstadoSyncTableAnnotationComposer
    extends Composer<_$BancoLocal, $EstadoSyncTable> {
  $$EstadoSyncTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get chave =>
      $composableBuilder(column: $table.chave, builder: (column) => column);

  GeneratedColumn<String> get valor =>
      $composableBuilder(column: $table.valor, builder: (column) => column);
}

class $$EstadoSyncTableTableManager
    extends
        RootTableManager<
          _$BancoLocal,
          $EstadoSyncTable,
          EstadoSyncData,
          $$EstadoSyncTableFilterComposer,
          $$EstadoSyncTableOrderingComposer,
          $$EstadoSyncTableAnnotationComposer,
          $$EstadoSyncTableCreateCompanionBuilder,
          $$EstadoSyncTableUpdateCompanionBuilder,
          (
            EstadoSyncData,
            BaseReferences<_$BancoLocal, $EstadoSyncTable, EstadoSyncData>,
          ),
          EstadoSyncData,
          PrefetchHooks Function()
        > {
  $$EstadoSyncTableTableManager(_$BancoLocal db, $EstadoSyncTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EstadoSyncTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EstadoSyncTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EstadoSyncTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> chave = const Value.absent(),
            Value<String> valor = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => EstadoSyncCompanion(chave: chave, valor: valor, rowid: rowid),
          createCompanionCallback:
              ({
                required String chave,
                required String valor,
                Value<int> rowid = const Value.absent(),
              }) => EstadoSyncCompanion.insert(
                chave: chave,
                valor: valor,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EstadoSyncTable, EstadoSyncData>(table),
                  BaseReferences<
                    _$BancoLocal,
                    $EstadoSyncTable,
                    EstadoSyncData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EstadoSyncTableProcessedTableManager =
    ProcessedTableManager<
      _$BancoLocal,
      $EstadoSyncTable,
      EstadoSyncData,
      $$EstadoSyncTableFilterComposer,
      $$EstadoSyncTableOrderingComposer,
      $$EstadoSyncTableAnnotationComposer,
      $$EstadoSyncTableCreateCompanionBuilder,
      $$EstadoSyncTableUpdateCompanionBuilder,
      (
        EstadoSyncData,
        BaseReferences<_$BancoLocal, $EstadoSyncTable, EstadoSyncData>,
      ),
      EstadoSyncData,
      PrefetchHooks Function()
    >;

class $BancoLocalManager {
  final _$BancoLocal _db;
  $BancoLocalManager(this._db);
  $$TurmasTableTableManager get turmas =>
      $$TurmasTableTableManager(_db, _db.turmas);
  $$QuadrosAulasTableTableManager get quadrosAulas =>
      $$QuadrosAulasTableTableManager(_db, _db.quadrosAulas);
  $$AlunosTableTableManager get alunos =>
      $$AlunosTableTableManager(_db, _db.alunos);
  $$MatriculasTableTableManager get matriculas =>
      $$MatriculasTableTableManager(_db, _db.matriculas);
  $$AulasTableTableManager get aulas =>
      $$AulasTableTableManager(_db, _db.aulas);
  $$PresencasTableTableManager get presencas =>
      $$PresencasTableTableManager(_db, _db.presencas);
  $$OutboxTableTableManager get outbox =>
      $$OutboxTableTableManager(_db, _db.outbox);
  $$EstadoSyncTableTableManager get estadoSync =>
      $$EstadoSyncTableTableManager(_db, _db.estadoSync);
}
