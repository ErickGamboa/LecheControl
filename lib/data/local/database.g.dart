// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $PlanesTable extends Planes with TableInfo<$PlanesTable, PlanRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlanesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _codigoMeta = const VerificationMeta('codigo');
  @override
  late final GeneratedColumn<String> codigo = GeneratedColumn<String>(
    'codigo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _limiteLecheriasMeta = const VerificationMeta(
    'limiteLecherias',
  );
  @override
  late final GeneratedColumn<int> limiteLecherias = GeneratedColumn<int>(
    'limite_lecherias',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    codigo,
    nombre,
    limiteLecherias,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'planes';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlanRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('codigo')) {
      context.handle(
        _codigoMeta,
        codigo.isAcceptableOrUnknown(data['codigo']!, _codigoMeta),
      );
    } else if (isInserting) {
      context.missing(_codigoMeta);
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('limite_lecherias')) {
      context.handle(
        _limiteLecheriasMeta,
        limiteLecherias.isAcceptableOrUnknown(
          data['limite_lecherias']!,
          _limiteLecheriasMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_limiteLecheriasMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {codigo};
  @override
  PlanRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlanRow(
      codigo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}codigo'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      limiteLecherias: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}limite_lecherias'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PlanesTable createAlias(String alias) {
    return $PlanesTable(attachedDatabase, alias);
  }
}

class PlanRow extends DataClass implements Insertable<PlanRow> {
  final String codigo;
  final String nombre;
  final int limiteLecherias;
  final DateTime updatedAt;
  const PlanRow({
    required this.codigo,
    required this.nombre,
    required this.limiteLecherias,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['codigo'] = Variable<String>(codigo);
    map['nombre'] = Variable<String>(nombre);
    map['limite_lecherias'] = Variable<int>(limiteLecherias);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PlanesCompanion toCompanion(bool nullToAbsent) {
    return PlanesCompanion(
      codigo: Value(codigo),
      nombre: Value(nombre),
      limiteLecherias: Value(limiteLecherias),
      updatedAt: Value(updatedAt),
    );
  }

  factory PlanRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlanRow(
      codigo: serializer.fromJson<String>(json['codigo']),
      nombre: serializer.fromJson<String>(json['nombre']),
      limiteLecherias: serializer.fromJson<int>(json['limiteLecherias']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'codigo': serializer.toJson<String>(codigo),
      'nombre': serializer.toJson<String>(nombre),
      'limiteLecherias': serializer.toJson<int>(limiteLecherias),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PlanRow copyWith({
    String? codigo,
    String? nombre,
    int? limiteLecherias,
    DateTime? updatedAt,
  }) => PlanRow(
    codigo: codigo ?? this.codigo,
    nombre: nombre ?? this.nombre,
    limiteLecherias: limiteLecherias ?? this.limiteLecherias,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PlanRow copyWithCompanion(PlanesCompanion data) {
    return PlanRow(
      codigo: data.codigo.present ? data.codigo.value : this.codigo,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      limiteLecherias: data.limiteLecherias.present
          ? data.limiteLecherias.value
          : this.limiteLecherias,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanRow(')
          ..write('codigo: $codigo, ')
          ..write('nombre: $nombre, ')
          ..write('limiteLecherias: $limiteLecherias, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(codigo, nombre, limiteLecherias, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanRow &&
          other.codigo == this.codigo &&
          other.nombre == this.nombre &&
          other.limiteLecherias == this.limiteLecherias &&
          other.updatedAt == this.updatedAt);
}

class PlanesCompanion extends UpdateCompanion<PlanRow> {
  final Value<String> codigo;
  final Value<String> nombre;
  final Value<int> limiteLecherias;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PlanesCompanion({
    this.codigo = const Value.absent(),
    this.nombre = const Value.absent(),
    this.limiteLecherias = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlanesCompanion.insert({
    required String codigo,
    required String nombre,
    required int limiteLecherias,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : codigo = Value(codigo),
       nombre = Value(nombre),
       limiteLecherias = Value(limiteLecherias),
       updatedAt = Value(updatedAt);
  static Insertable<PlanRow> custom({
    Expression<String>? codigo,
    Expression<String>? nombre,
    Expression<int>? limiteLecherias,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (codigo != null) 'codigo': codigo,
      if (nombre != null) 'nombre': nombre,
      if (limiteLecherias != null) 'limite_lecherias': limiteLecherias,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlanesCompanion copyWith({
    Value<String>? codigo,
    Value<String>? nombre,
    Value<int>? limiteLecherias,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return PlanesCompanion(
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      limiteLecherias: limiteLecherias ?? this.limiteLecherias,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (codigo.present) {
      map['codigo'] = Variable<String>(codigo.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (limiteLecherias.present) {
      map['limite_lecherias'] = Variable<int>(limiteLecherias.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlanesCompanion(')
          ..write('codigo: $codigo, ')
          ..write('nombre: $nombre, ')
          ..write('limiteLecherias: $limiteLecherias, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CuentasTable extends Cuentas with TableInfo<$CuentasTable, CuentaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CuentasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _duenoIdMeta = const VerificationMeta(
    'duenoId',
  );
  @override
  late final GeneratedColumn<String> duenoId = GeneratedColumn<String>(
    'dueno_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _planMeta = const VerificationMeta('plan');
  @override
  late final GeneratedColumn<String> plan = GeneratedColumn<String>(
    'plan',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _estadoMeta = const VerificationMeta('estado');
  @override
  late final GeneratedColumn<String> estado = GeneratedColumn<String>(
    'estado',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pruebaTerminaMeta = const VerificationMeta(
    'pruebaTermina',
  );
  @override
  late final GeneratedColumn<DateTime> pruebaTermina =
      GeneratedColumn<DateTime>(
        'prueba_termina',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pendienteMeta = const VerificationMeta(
    'pendiente',
  );
  @override
  late final GeneratedColumn<bool> pendiente = GeneratedColumn<bool>(
    'pendiente',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pendiente" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nombre,
    duenoId,
    plan,
    estado,
    pruebaTermina,
    createdAt,
    updatedAt,
    deletedAt,
    pendiente,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cuentas';
  @override
  VerificationContext validateIntegrity(
    Insertable<CuentaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('dueno_id')) {
      context.handle(
        _duenoIdMeta,
        duenoId.isAcceptableOrUnknown(data['dueno_id']!, _duenoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_duenoIdMeta);
    }
    if (data.containsKey('plan')) {
      context.handle(
        _planMeta,
        plan.isAcceptableOrUnknown(data['plan']!, _planMeta),
      );
    } else if (isInserting) {
      context.missing(_planMeta);
    }
    if (data.containsKey('estado')) {
      context.handle(
        _estadoMeta,
        estado.isAcceptableOrUnknown(data['estado']!, _estadoMeta),
      );
    } else if (isInserting) {
      context.missing(_estadoMeta);
    }
    if (data.containsKey('prueba_termina')) {
      context.handle(
        _pruebaTerminaMeta,
        pruebaTermina.isAcceptableOrUnknown(
          data['prueba_termina']!,
          _pruebaTerminaMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('pendiente')) {
      context.handle(
        _pendienteMeta,
        pendiente.isAcceptableOrUnknown(data['pendiente']!, _pendienteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CuentaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CuentaRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      duenoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dueno_id'],
      )!,
      plan: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan'],
      )!,
      estado: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}estado'],
      )!,
      pruebaTermina: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}prueba_termina'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      pendiente: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pendiente'],
      )!,
    );
  }

  @override
  $CuentasTable createAlias(String alias) {
    return $CuentasTable(attachedDatabase, alias);
  }
}

class CuentaRow extends DataClass implements Insertable<CuentaRow> {
  final String id;
  final String nombre;
  final String duenoId;
  final String plan;
  final String estado;
  final DateTime? pruebaTermina;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool pendiente;
  const CuentaRow({
    required this.id,
    required this.nombre,
    required this.duenoId,
    required this.plan,
    required this.estado,
    this.pruebaTermina,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.pendiente,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['nombre'] = Variable<String>(nombre);
    map['dueno_id'] = Variable<String>(duenoId);
    map['plan'] = Variable<String>(plan);
    map['estado'] = Variable<String>(estado);
    if (!nullToAbsent || pruebaTermina != null) {
      map['prueba_termina'] = Variable<DateTime>(pruebaTermina);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['pendiente'] = Variable<bool>(pendiente);
    return map;
  }

  CuentasCompanion toCompanion(bool nullToAbsent) {
    return CuentasCompanion(
      id: Value(id),
      nombre: Value(nombre),
      duenoId: Value(duenoId),
      plan: Value(plan),
      estado: Value(estado),
      pruebaTermina: pruebaTermina == null && nullToAbsent
          ? const Value.absent()
          : Value(pruebaTermina),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      pendiente: Value(pendiente),
    );
  }

  factory CuentaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CuentaRow(
      id: serializer.fromJson<String>(json['id']),
      nombre: serializer.fromJson<String>(json['nombre']),
      duenoId: serializer.fromJson<String>(json['duenoId']),
      plan: serializer.fromJson<String>(json['plan']),
      estado: serializer.fromJson<String>(json['estado']),
      pruebaTermina: serializer.fromJson<DateTime?>(json['pruebaTermina']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      pendiente: serializer.fromJson<bool>(json['pendiente']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nombre': serializer.toJson<String>(nombre),
      'duenoId': serializer.toJson<String>(duenoId),
      'plan': serializer.toJson<String>(plan),
      'estado': serializer.toJson<String>(estado),
      'pruebaTermina': serializer.toJson<DateTime?>(pruebaTermina),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'pendiente': serializer.toJson<bool>(pendiente),
    };
  }

  CuentaRow copyWith({
    String? id,
    String? nombre,
    String? duenoId,
    String? plan,
    String? estado,
    Value<DateTime?> pruebaTermina = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    bool? pendiente,
  }) => CuentaRow(
    id: id ?? this.id,
    nombre: nombre ?? this.nombre,
    duenoId: duenoId ?? this.duenoId,
    plan: plan ?? this.plan,
    estado: estado ?? this.estado,
    pruebaTermina: pruebaTermina.present
        ? pruebaTermina.value
        : this.pruebaTermina,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    pendiente: pendiente ?? this.pendiente,
  );
  CuentaRow copyWithCompanion(CuentasCompanion data) {
    return CuentaRow(
      id: data.id.present ? data.id.value : this.id,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      duenoId: data.duenoId.present ? data.duenoId.value : this.duenoId,
      plan: data.plan.present ? data.plan.value : this.plan,
      estado: data.estado.present ? data.estado.value : this.estado,
      pruebaTermina: data.pruebaTermina.present
          ? data.pruebaTermina.value
          : this.pruebaTermina,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      pendiente: data.pendiente.present ? data.pendiente.value : this.pendiente,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CuentaRow(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('duenoId: $duenoId, ')
          ..write('plan: $plan, ')
          ..write('estado: $estado, ')
          ..write('pruebaTermina: $pruebaTermina, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('pendiente: $pendiente')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    nombre,
    duenoId,
    plan,
    estado,
    pruebaTermina,
    createdAt,
    updatedAt,
    deletedAt,
    pendiente,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CuentaRow &&
          other.id == this.id &&
          other.nombre == this.nombre &&
          other.duenoId == this.duenoId &&
          other.plan == this.plan &&
          other.estado == this.estado &&
          other.pruebaTermina == this.pruebaTermina &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.pendiente == this.pendiente);
}

class CuentasCompanion extends UpdateCompanion<CuentaRow> {
  final Value<String> id;
  final Value<String> nombre;
  final Value<String> duenoId;
  final Value<String> plan;
  final Value<String> estado;
  final Value<DateTime?> pruebaTermina;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<bool> pendiente;
  final Value<int> rowid;
  const CuentasCompanion({
    this.id = const Value.absent(),
    this.nombre = const Value.absent(),
    this.duenoId = const Value.absent(),
    this.plan = const Value.absent(),
    this.estado = const Value.absent(),
    this.pruebaTermina = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.pendiente = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CuentasCompanion.insert({
    required String id,
    required String nombre,
    required String duenoId,
    required String plan,
    required String estado,
    this.pruebaTermina = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.pendiente = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nombre = Value(nombre),
       duenoId = Value(duenoId),
       plan = Value(plan),
       estado = Value(estado),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CuentaRow> custom({
    Expression<String>? id,
    Expression<String>? nombre,
    Expression<String>? duenoId,
    Expression<String>? plan,
    Expression<String>? estado,
    Expression<DateTime>? pruebaTermina,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<bool>? pendiente,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nombre != null) 'nombre': nombre,
      if (duenoId != null) 'dueno_id': duenoId,
      if (plan != null) 'plan': plan,
      if (estado != null) 'estado': estado,
      if (pruebaTermina != null) 'prueba_termina': pruebaTermina,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (pendiente != null) 'pendiente': pendiente,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CuentasCompanion copyWith({
    Value<String>? id,
    Value<String>? nombre,
    Value<String>? duenoId,
    Value<String>? plan,
    Value<String>? estado,
    Value<DateTime?>? pruebaTermina,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<bool>? pendiente,
    Value<int>? rowid,
  }) {
    return CuentasCompanion(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      duenoId: duenoId ?? this.duenoId,
      plan: plan ?? this.plan,
      estado: estado ?? this.estado,
      pruebaTermina: pruebaTermina ?? this.pruebaTermina,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      pendiente: pendiente ?? this.pendiente,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (duenoId.present) {
      map['dueno_id'] = Variable<String>(duenoId.value);
    }
    if (plan.present) {
      map['plan'] = Variable<String>(plan.value);
    }
    if (estado.present) {
      map['estado'] = Variable<String>(estado.value);
    }
    if (pruebaTermina.present) {
      map['prueba_termina'] = Variable<DateTime>(pruebaTermina.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (pendiente.present) {
      map['pendiente'] = Variable<bool>(pendiente.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CuentasCompanion(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('duenoId: $duenoId, ')
          ..write('plan: $plan, ')
          ..write('estado: $estado, ')
          ..write('pruebaTermina: $pruebaTermina, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('pendiente: $pendiente, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UsuariosTable extends Usuarios
    with TableInfo<$UsuariosTable, UsuarioRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsuariosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cuentaIdMeta = const VerificationMeta(
    'cuentaId',
  );
  @override
  late final GeneratedColumn<String> cuentaId = GeneratedColumn<String>(
    'cuenta_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pendienteMeta = const VerificationMeta(
    'pendiente',
  );
  @override
  late final GeneratedColumn<bool> pendiente = GeneratedColumn<bool>(
    'pendiente',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pendiente" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nombre,
    email,
    cuentaId,
    createdAt,
    updatedAt,
    pendiente,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'usuarios';
  @override
  VerificationContext validateIntegrity(
    Insertable<UsuarioRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('cuenta_id')) {
      context.handle(
        _cuentaIdMeta,
        cuentaId.isAcceptableOrUnknown(data['cuenta_id']!, _cuentaIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('pendiente')) {
      context.handle(
        _pendienteMeta,
        pendiente.isAcceptableOrUnknown(data['pendiente']!, _pendienteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UsuarioRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UsuarioRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      ),
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      cuentaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cuenta_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      pendiente: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pendiente'],
      )!,
    );
  }

  @override
  $UsuariosTable createAlias(String alias) {
    return $UsuariosTable(attachedDatabase, alias);
  }
}

class UsuarioRow extends DataClass implements Insertable<UsuarioRow> {
  final String id;
  final String? nombre;
  final String? email;
  final String? cuentaId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool pendiente;
  const UsuarioRow({
    required this.id,
    this.nombre,
    this.email,
    this.cuentaId,
    required this.createdAt,
    required this.updatedAt,
    required this.pendiente,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || nombre != null) {
      map['nombre'] = Variable<String>(nombre);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || cuentaId != null) {
      map['cuenta_id'] = Variable<String>(cuentaId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['pendiente'] = Variable<bool>(pendiente);
    return map;
  }

  UsuariosCompanion toCompanion(bool nullToAbsent) {
    return UsuariosCompanion(
      id: Value(id),
      nombre: nombre == null && nullToAbsent
          ? const Value.absent()
          : Value(nombre),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      cuentaId: cuentaId == null && nullToAbsent
          ? const Value.absent()
          : Value(cuentaId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      pendiente: Value(pendiente),
    );
  }

  factory UsuarioRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UsuarioRow(
      id: serializer.fromJson<String>(json['id']),
      nombre: serializer.fromJson<String?>(json['nombre']),
      email: serializer.fromJson<String?>(json['email']),
      cuentaId: serializer.fromJson<String?>(json['cuentaId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      pendiente: serializer.fromJson<bool>(json['pendiente']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nombre': serializer.toJson<String?>(nombre),
      'email': serializer.toJson<String?>(email),
      'cuentaId': serializer.toJson<String?>(cuentaId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'pendiente': serializer.toJson<bool>(pendiente),
    };
  }

  UsuarioRow copyWith({
    String? id,
    Value<String?> nombre = const Value.absent(),
    Value<String?> email = const Value.absent(),
    Value<String?> cuentaId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? pendiente,
  }) => UsuarioRow(
    id: id ?? this.id,
    nombre: nombre.present ? nombre.value : this.nombre,
    email: email.present ? email.value : this.email,
    cuentaId: cuentaId.present ? cuentaId.value : this.cuentaId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    pendiente: pendiente ?? this.pendiente,
  );
  UsuarioRow copyWithCompanion(UsuariosCompanion data) {
    return UsuarioRow(
      id: data.id.present ? data.id.value : this.id,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      email: data.email.present ? data.email.value : this.email,
      cuentaId: data.cuentaId.present ? data.cuentaId.value : this.cuentaId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      pendiente: data.pendiente.present ? data.pendiente.value : this.pendiente,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UsuarioRow(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('email: $email, ')
          ..write('cuentaId: $cuentaId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pendiente: $pendiente')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, nombre, email, cuentaId, createdAt, updatedAt, pendiente);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UsuarioRow &&
          other.id == this.id &&
          other.nombre == this.nombre &&
          other.email == this.email &&
          other.cuentaId == this.cuentaId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.pendiente == this.pendiente);
}

class UsuariosCompanion extends UpdateCompanion<UsuarioRow> {
  final Value<String> id;
  final Value<String?> nombre;
  final Value<String?> email;
  final Value<String?> cuentaId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> pendiente;
  final Value<int> rowid;
  const UsuariosCompanion({
    this.id = const Value.absent(),
    this.nombre = const Value.absent(),
    this.email = const Value.absent(),
    this.cuentaId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.pendiente = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsuariosCompanion.insert({
    required String id,
    this.nombre = const Value.absent(),
    this.email = const Value.absent(),
    this.cuentaId = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.pendiente = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<UsuarioRow> custom({
    Expression<String>? id,
    Expression<String>? nombre,
    Expression<String>? email,
    Expression<String>? cuentaId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? pendiente,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nombre != null) 'nombre': nombre,
      if (email != null) 'email': email,
      if (cuentaId != null) 'cuenta_id': cuentaId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (pendiente != null) 'pendiente': pendiente,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsuariosCompanion copyWith({
    Value<String>? id,
    Value<String?>? nombre,
    Value<String?>? email,
    Value<String?>? cuentaId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<bool>? pendiente,
    Value<int>? rowid,
  }) {
    return UsuariosCompanion(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      cuentaId: cuentaId ?? this.cuentaId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pendiente: pendiente ?? this.pendiente,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (cuentaId.present) {
      map['cuenta_id'] = Variable<String>(cuentaId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (pendiente.present) {
      map['pendiente'] = Variable<bool>(pendiente.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsuariosCompanion(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('email: $email, ')
          ..write('cuentaId: $cuentaId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pendiente: $pendiente, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LecheriasTable extends Lecherias
    with TableInfo<$LecheriasTable, LecheriaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LecheriasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _creadaPorMeta = const VerificationMeta(
    'creadaPor',
  );
  @override
  late final GeneratedColumn<String> creadaPor = GeneratedColumn<String>(
    'creada_por',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cuentaIdMeta = const VerificationMeta(
    'cuentaId',
  );
  @override
  late final GeneratedColumn<String> cuentaId = GeneratedColumn<String>(
    'cuenta_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pendienteMeta = const VerificationMeta(
    'pendiente',
  );
  @override
  late final GeneratedColumn<bool> pendiente = GeneratedColumn<bool>(
    'pendiente',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pendiente" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nombre,
    creadaPor,
    cuentaId,
    createdAt,
    updatedAt,
    deletedAt,
    pendiente,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lecherias';
  @override
  VerificationContext validateIntegrity(
    Insertable<LecheriaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('creada_por')) {
      context.handle(
        _creadaPorMeta,
        creadaPor.isAcceptableOrUnknown(data['creada_por']!, _creadaPorMeta),
      );
    } else if (isInserting) {
      context.missing(_creadaPorMeta);
    }
    if (data.containsKey('cuenta_id')) {
      context.handle(
        _cuentaIdMeta,
        cuentaId.isAcceptableOrUnknown(data['cuenta_id']!, _cuentaIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('pendiente')) {
      context.handle(
        _pendienteMeta,
        pendiente.isAcceptableOrUnknown(data['pendiente']!, _pendienteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LecheriaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LecheriaRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      creadaPor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}creada_por'],
      )!,
      cuentaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cuenta_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      pendiente: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pendiente'],
      )!,
    );
  }

  @override
  $LecheriasTable createAlias(String alias) {
    return $LecheriasTable(attachedDatabase, alias);
  }
}

class LecheriaRow extends DataClass implements Insertable<LecheriaRow> {
  final String id;
  final String nombre;
  final String creadaPor;
  final String? cuentaId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool pendiente;
  const LecheriaRow({
    required this.id,
    required this.nombre,
    required this.creadaPor,
    this.cuentaId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.pendiente,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['nombre'] = Variable<String>(nombre);
    map['creada_por'] = Variable<String>(creadaPor);
    if (!nullToAbsent || cuentaId != null) {
      map['cuenta_id'] = Variable<String>(cuentaId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['pendiente'] = Variable<bool>(pendiente);
    return map;
  }

  LecheriasCompanion toCompanion(bool nullToAbsent) {
    return LecheriasCompanion(
      id: Value(id),
      nombre: Value(nombre),
      creadaPor: Value(creadaPor),
      cuentaId: cuentaId == null && nullToAbsent
          ? const Value.absent()
          : Value(cuentaId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      pendiente: Value(pendiente),
    );
  }

  factory LecheriaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LecheriaRow(
      id: serializer.fromJson<String>(json['id']),
      nombre: serializer.fromJson<String>(json['nombre']),
      creadaPor: serializer.fromJson<String>(json['creadaPor']),
      cuentaId: serializer.fromJson<String?>(json['cuentaId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      pendiente: serializer.fromJson<bool>(json['pendiente']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nombre': serializer.toJson<String>(nombre),
      'creadaPor': serializer.toJson<String>(creadaPor),
      'cuentaId': serializer.toJson<String?>(cuentaId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'pendiente': serializer.toJson<bool>(pendiente),
    };
  }

  LecheriaRow copyWith({
    String? id,
    String? nombre,
    String? creadaPor,
    Value<String?> cuentaId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    bool? pendiente,
  }) => LecheriaRow(
    id: id ?? this.id,
    nombre: nombre ?? this.nombre,
    creadaPor: creadaPor ?? this.creadaPor,
    cuentaId: cuentaId.present ? cuentaId.value : this.cuentaId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    pendiente: pendiente ?? this.pendiente,
  );
  LecheriaRow copyWithCompanion(LecheriasCompanion data) {
    return LecheriaRow(
      id: data.id.present ? data.id.value : this.id,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      creadaPor: data.creadaPor.present ? data.creadaPor.value : this.creadaPor,
      cuentaId: data.cuentaId.present ? data.cuentaId.value : this.cuentaId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      pendiente: data.pendiente.present ? data.pendiente.value : this.pendiente,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LecheriaRow(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('creadaPor: $creadaPor, ')
          ..write('cuentaId: $cuentaId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('pendiente: $pendiente')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    nombre,
    creadaPor,
    cuentaId,
    createdAt,
    updatedAt,
    deletedAt,
    pendiente,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LecheriaRow &&
          other.id == this.id &&
          other.nombre == this.nombre &&
          other.creadaPor == this.creadaPor &&
          other.cuentaId == this.cuentaId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.pendiente == this.pendiente);
}

class LecheriasCompanion extends UpdateCompanion<LecheriaRow> {
  final Value<String> id;
  final Value<String> nombre;
  final Value<String> creadaPor;
  final Value<String?> cuentaId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<bool> pendiente;
  final Value<int> rowid;
  const LecheriasCompanion({
    this.id = const Value.absent(),
    this.nombre = const Value.absent(),
    this.creadaPor = const Value.absent(),
    this.cuentaId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.pendiente = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LecheriasCompanion.insert({
    required String id,
    required String nombre,
    required String creadaPor,
    this.cuentaId = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.pendiente = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nombre = Value(nombre),
       creadaPor = Value(creadaPor),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<LecheriaRow> custom({
    Expression<String>? id,
    Expression<String>? nombre,
    Expression<String>? creadaPor,
    Expression<String>? cuentaId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<bool>? pendiente,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nombre != null) 'nombre': nombre,
      if (creadaPor != null) 'creada_por': creadaPor,
      if (cuentaId != null) 'cuenta_id': cuentaId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (pendiente != null) 'pendiente': pendiente,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LecheriasCompanion copyWith({
    Value<String>? id,
    Value<String>? nombre,
    Value<String>? creadaPor,
    Value<String?>? cuentaId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<bool>? pendiente,
    Value<int>? rowid,
  }) {
    return LecheriasCompanion(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      creadaPor: creadaPor ?? this.creadaPor,
      cuentaId: cuentaId ?? this.cuentaId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      pendiente: pendiente ?? this.pendiente,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (creadaPor.present) {
      map['creada_por'] = Variable<String>(creadaPor.value);
    }
    if (cuentaId.present) {
      map['cuenta_id'] = Variable<String>(cuentaId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (pendiente.present) {
      map['pendiente'] = Variable<bool>(pendiente.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LecheriasCompanion(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('creadaPor: $creadaPor, ')
          ..write('cuentaId: $cuentaId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('pendiente: $pendiente, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LecheriaMiembrosTable extends LecheriaMiembros
    with TableInfo<$LecheriaMiembrosTable, LecheriaMiembroRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LecheriaMiembrosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lecheriaIdMeta = const VerificationMeta(
    'lecheriaId',
  );
  @override
  late final GeneratedColumn<String> lecheriaId = GeneratedColumn<String>(
    'lecheria_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usuarioIdMeta = const VerificationMeta(
    'usuarioId',
  );
  @override
  late final GeneratedColumn<String> usuarioId = GeneratedColumn<String>(
    'usuario_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rolMeta = const VerificationMeta('rol');
  @override
  late final GeneratedColumn<String> rol = GeneratedColumn<String>(
    'rol',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pendienteMeta = const VerificationMeta(
    'pendiente',
  );
  @override
  late final GeneratedColumn<bool> pendiente = GeneratedColumn<bool>(
    'pendiente',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pendiente" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    lecheriaId,
    usuarioId,
    rol,
    createdAt,
    updatedAt,
    deletedAt,
    pendiente,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lecheria_miembros';
  @override
  VerificationContext validateIntegrity(
    Insertable<LecheriaMiembroRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('lecheria_id')) {
      context.handle(
        _lecheriaIdMeta,
        lecheriaId.isAcceptableOrUnknown(data['lecheria_id']!, _lecheriaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_lecheriaIdMeta);
    }
    if (data.containsKey('usuario_id')) {
      context.handle(
        _usuarioIdMeta,
        usuarioId.isAcceptableOrUnknown(data['usuario_id']!, _usuarioIdMeta),
      );
    } else if (isInserting) {
      context.missing(_usuarioIdMeta);
    }
    if (data.containsKey('rol')) {
      context.handle(
        _rolMeta,
        rol.isAcceptableOrUnknown(data['rol']!, _rolMeta),
      );
    } else if (isInserting) {
      context.missing(_rolMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('pendiente')) {
      context.handle(
        _pendienteMeta,
        pendiente.isAcceptableOrUnknown(data['pendiente']!, _pendienteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LecheriaMiembroRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LecheriaMiembroRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      lecheriaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lecheria_id'],
      )!,
      usuarioId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}usuario_id'],
      )!,
      rol: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rol'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      pendiente: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pendiente'],
      )!,
    );
  }

  @override
  $LecheriaMiembrosTable createAlias(String alias) {
    return $LecheriaMiembrosTable(attachedDatabase, alias);
  }
}

class LecheriaMiembroRow extends DataClass
    implements Insertable<LecheriaMiembroRow> {
  final String id;
  final String lecheriaId;
  final String usuarioId;
  final String rol;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool pendiente;
  const LecheriaMiembroRow({
    required this.id,
    required this.lecheriaId,
    required this.usuarioId,
    required this.rol,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.pendiente,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['lecheria_id'] = Variable<String>(lecheriaId);
    map['usuario_id'] = Variable<String>(usuarioId);
    map['rol'] = Variable<String>(rol);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['pendiente'] = Variable<bool>(pendiente);
    return map;
  }

  LecheriaMiembrosCompanion toCompanion(bool nullToAbsent) {
    return LecheriaMiembrosCompanion(
      id: Value(id),
      lecheriaId: Value(lecheriaId),
      usuarioId: Value(usuarioId),
      rol: Value(rol),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      pendiente: Value(pendiente),
    );
  }

  factory LecheriaMiembroRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LecheriaMiembroRow(
      id: serializer.fromJson<String>(json['id']),
      lecheriaId: serializer.fromJson<String>(json['lecheriaId']),
      usuarioId: serializer.fromJson<String>(json['usuarioId']),
      rol: serializer.fromJson<String>(json['rol']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      pendiente: serializer.fromJson<bool>(json['pendiente']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'lecheriaId': serializer.toJson<String>(lecheriaId),
      'usuarioId': serializer.toJson<String>(usuarioId),
      'rol': serializer.toJson<String>(rol),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'pendiente': serializer.toJson<bool>(pendiente),
    };
  }

  LecheriaMiembroRow copyWith({
    String? id,
    String? lecheriaId,
    String? usuarioId,
    String? rol,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    bool? pendiente,
  }) => LecheriaMiembroRow(
    id: id ?? this.id,
    lecheriaId: lecheriaId ?? this.lecheriaId,
    usuarioId: usuarioId ?? this.usuarioId,
    rol: rol ?? this.rol,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    pendiente: pendiente ?? this.pendiente,
  );
  LecheriaMiembroRow copyWithCompanion(LecheriaMiembrosCompanion data) {
    return LecheriaMiembroRow(
      id: data.id.present ? data.id.value : this.id,
      lecheriaId: data.lecheriaId.present
          ? data.lecheriaId.value
          : this.lecheriaId,
      usuarioId: data.usuarioId.present ? data.usuarioId.value : this.usuarioId,
      rol: data.rol.present ? data.rol.value : this.rol,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      pendiente: data.pendiente.present ? data.pendiente.value : this.pendiente,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LecheriaMiembroRow(')
          ..write('id: $id, ')
          ..write('lecheriaId: $lecheriaId, ')
          ..write('usuarioId: $usuarioId, ')
          ..write('rol: $rol, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('pendiente: $pendiente')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    lecheriaId,
    usuarioId,
    rol,
    createdAt,
    updatedAt,
    deletedAt,
    pendiente,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LecheriaMiembroRow &&
          other.id == this.id &&
          other.lecheriaId == this.lecheriaId &&
          other.usuarioId == this.usuarioId &&
          other.rol == this.rol &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.pendiente == this.pendiente);
}

class LecheriaMiembrosCompanion extends UpdateCompanion<LecheriaMiembroRow> {
  final Value<String> id;
  final Value<String> lecheriaId;
  final Value<String> usuarioId;
  final Value<String> rol;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<bool> pendiente;
  final Value<int> rowid;
  const LecheriaMiembrosCompanion({
    this.id = const Value.absent(),
    this.lecheriaId = const Value.absent(),
    this.usuarioId = const Value.absent(),
    this.rol = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.pendiente = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LecheriaMiembrosCompanion.insert({
    required String id,
    required String lecheriaId,
    required String usuarioId,
    required String rol,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.pendiente = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       lecheriaId = Value(lecheriaId),
       usuarioId = Value(usuarioId),
       rol = Value(rol),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<LecheriaMiembroRow> custom({
    Expression<String>? id,
    Expression<String>? lecheriaId,
    Expression<String>? usuarioId,
    Expression<String>? rol,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<bool>? pendiente,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lecheriaId != null) 'lecheria_id': lecheriaId,
      if (usuarioId != null) 'usuario_id': usuarioId,
      if (rol != null) 'rol': rol,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (pendiente != null) 'pendiente': pendiente,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LecheriaMiembrosCompanion copyWith({
    Value<String>? id,
    Value<String>? lecheriaId,
    Value<String>? usuarioId,
    Value<String>? rol,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<bool>? pendiente,
    Value<int>? rowid,
  }) {
    return LecheriaMiembrosCompanion(
      id: id ?? this.id,
      lecheriaId: lecheriaId ?? this.lecheriaId,
      usuarioId: usuarioId ?? this.usuarioId,
      rol: rol ?? this.rol,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      pendiente: pendiente ?? this.pendiente,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (lecheriaId.present) {
      map['lecheria_id'] = Variable<String>(lecheriaId.value);
    }
    if (usuarioId.present) {
      map['usuario_id'] = Variable<String>(usuarioId.value);
    }
    if (rol.present) {
      map['rol'] = Variable<String>(rol.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (pendiente.present) {
      map['pendiente'] = Variable<bool>(pendiente.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LecheriaMiembrosCompanion(')
          ..write('id: $id, ')
          ..write('lecheriaId: $lecheriaId, ')
          ..write('usuarioId: $usuarioId, ')
          ..write('rol: $rol, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('pendiente: $pendiente, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AnimalesTable extends Animales
    with TableInfo<$AnimalesTable, AnimalRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnimalesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lecheriaIdMeta = const VerificationMeta(
    'lecheriaId',
  );
  @override
  late final GeneratedColumn<String> lecheriaId = GeneratedColumn<String>(
    'lecheria_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _identificadorMeta = const VerificationMeta(
    'identificador',
  );
  @override
  late final GeneratedColumn<String> identificador = GeneratedColumn<String>(
    'identificador',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sexoMeta = const VerificationMeta('sexo');
  @override
  late final GeneratedColumn<String> sexo = GeneratedColumn<String>(
    'sexo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _grupoMeta = const VerificationMeta('grupo');
  @override
  late final GeneratedColumn<String> grupo = GeneratedColumn<String>(
    'grupo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _estadoMeta = const VerificationMeta('estado');
  @override
  late final GeneratedColumn<String> estado = GeneratedColumn<String>(
    'estado',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('activo'),
  );
  static const VerificationMeta _estadoReproductivoMeta =
      const VerificationMeta('estadoReproductivo');
  @override
  late final GeneratedColumn<String> estadoReproductivo =
      GeneratedColumn<String>(
        'estado_reproductivo',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('desconocido'),
      );
  static const VerificationMeta _origenMeta = const VerificationMeta('origen');
  @override
  late final GeneratedColumn<String> origen = GeneratedColumn<String>(
    'origen',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _precioCompraMeta = const VerificationMeta(
    'precioCompra',
  );
  @override
  late final GeneratedColumn<double> precioCompra = GeneratedColumn<double>(
    'precio_compra',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fechaCompraMeta = const VerificationMeta(
    'fechaCompra',
  );
  @override
  late final GeneratedColumn<DateTime> fechaCompra = GeneratedColumn<DateTime>(
    'fecha_compra',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _madreIdMeta = const VerificationMeta(
    'madreId',
  );
  @override
  late final GeneratedColumn<String> madreId = GeneratedColumn<String>(
    'madre_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _concentradoKgDiaMeta = const VerificationMeta(
    'concentradoKgDia',
  );
  @override
  late final GeneratedColumn<double> concentradoKgDia = GeneratedColumn<double>(
    'concentrado_kg_dia',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _fechaProbablePartoMeta =
      const VerificationMeta('fechaProbableParto');
  @override
  late final GeneratedColumn<DateTime> fechaProbableParto =
      GeneratedColumn<DateTime>(
        'fecha_probable_parto',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _retiroLecheHastaMeta = const VerificationMeta(
    'retiroLecheHasta',
  );
  @override
  late final GeneratedColumn<DateTime> retiroLecheHasta =
      GeneratedColumn<DateTime>(
        'retiro_leche_hasta',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pendienteMeta = const VerificationMeta(
    'pendiente',
  );
  @override
  late final GeneratedColumn<bool> pendiente = GeneratedColumn<bool>(
    'pendiente',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pendiente" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    lecheriaId,
    identificador,
    sexo,
    grupo,
    estado,
    estadoReproductivo,
    origen,
    precioCompra,
    fechaCompra,
    madreId,
    concentradoKgDia,
    fechaProbableParto,
    retiroLecheHasta,
    createdAt,
    updatedAt,
    deletedAt,
    pendiente,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'animales';
  @override
  VerificationContext validateIntegrity(
    Insertable<AnimalRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('lecheria_id')) {
      context.handle(
        _lecheriaIdMeta,
        lecheriaId.isAcceptableOrUnknown(data['lecheria_id']!, _lecheriaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_lecheriaIdMeta);
    }
    if (data.containsKey('identificador')) {
      context.handle(
        _identificadorMeta,
        identificador.isAcceptableOrUnknown(
          data['identificador']!,
          _identificadorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_identificadorMeta);
    }
    if (data.containsKey('sexo')) {
      context.handle(
        _sexoMeta,
        sexo.isAcceptableOrUnknown(data['sexo']!, _sexoMeta),
      );
    } else if (isInserting) {
      context.missing(_sexoMeta);
    }
    if (data.containsKey('grupo')) {
      context.handle(
        _grupoMeta,
        grupo.isAcceptableOrUnknown(data['grupo']!, _grupoMeta),
      );
    } else if (isInserting) {
      context.missing(_grupoMeta);
    }
    if (data.containsKey('estado')) {
      context.handle(
        _estadoMeta,
        estado.isAcceptableOrUnknown(data['estado']!, _estadoMeta),
      );
    }
    if (data.containsKey('estado_reproductivo')) {
      context.handle(
        _estadoReproductivoMeta,
        estadoReproductivo.isAcceptableOrUnknown(
          data['estado_reproductivo']!,
          _estadoReproductivoMeta,
        ),
      );
    }
    if (data.containsKey('origen')) {
      context.handle(
        _origenMeta,
        origen.isAcceptableOrUnknown(data['origen']!, _origenMeta),
      );
    } else if (isInserting) {
      context.missing(_origenMeta);
    }
    if (data.containsKey('precio_compra')) {
      context.handle(
        _precioCompraMeta,
        precioCompra.isAcceptableOrUnknown(
          data['precio_compra']!,
          _precioCompraMeta,
        ),
      );
    }
    if (data.containsKey('fecha_compra')) {
      context.handle(
        _fechaCompraMeta,
        fechaCompra.isAcceptableOrUnknown(
          data['fecha_compra']!,
          _fechaCompraMeta,
        ),
      );
    }
    if (data.containsKey('madre_id')) {
      context.handle(
        _madreIdMeta,
        madreId.isAcceptableOrUnknown(data['madre_id']!, _madreIdMeta),
      );
    }
    if (data.containsKey('concentrado_kg_dia')) {
      context.handle(
        _concentradoKgDiaMeta,
        concentradoKgDia.isAcceptableOrUnknown(
          data['concentrado_kg_dia']!,
          _concentradoKgDiaMeta,
        ),
      );
    }
    if (data.containsKey('fecha_probable_parto')) {
      context.handle(
        _fechaProbablePartoMeta,
        fechaProbableParto.isAcceptableOrUnknown(
          data['fecha_probable_parto']!,
          _fechaProbablePartoMeta,
        ),
      );
    }
    if (data.containsKey('retiro_leche_hasta')) {
      context.handle(
        _retiroLecheHastaMeta,
        retiroLecheHasta.isAcceptableOrUnknown(
          data['retiro_leche_hasta']!,
          _retiroLecheHastaMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('pendiente')) {
      context.handle(
        _pendienteMeta,
        pendiente.isAcceptableOrUnknown(data['pendiente']!, _pendienteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AnimalRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AnimalRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      lecheriaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lecheria_id'],
      )!,
      identificador: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}identificador'],
      )!,
      sexo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sexo'],
      )!,
      grupo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grupo'],
      )!,
      estado: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}estado'],
      )!,
      estadoReproductivo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}estado_reproductivo'],
      )!,
      origen: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origen'],
      )!,
      precioCompra: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}precio_compra'],
      ),
      fechaCompra: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha_compra'],
      ),
      madreId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}madre_id'],
      ),
      concentradoKgDia: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}concentrado_kg_dia'],
      )!,
      fechaProbableParto: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha_probable_parto'],
      ),
      retiroLecheHasta: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}retiro_leche_hasta'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      pendiente: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pendiente'],
      )!,
    );
  }

  @override
  $AnimalesTable createAlias(String alias) {
    return $AnimalesTable(attachedDatabase, alias);
  }
}

class AnimalRow extends DataClass implements Insertable<AnimalRow> {
  final String id;
  final String lecheriaId;
  final String identificador;
  final String sexo;
  final String grupo;
  final String estado;
  final String estadoReproductivo;
  final String origen;
  final double? precioCompra;
  final DateTime? fechaCompra;
  final String? madreId;
  final double concentradoKgDia;
  final DateTime? fechaProbableParto;
  final DateTime? retiroLecheHasta;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool pendiente;
  const AnimalRow({
    required this.id,
    required this.lecheriaId,
    required this.identificador,
    required this.sexo,
    required this.grupo,
    required this.estado,
    required this.estadoReproductivo,
    required this.origen,
    this.precioCompra,
    this.fechaCompra,
    this.madreId,
    required this.concentradoKgDia,
    this.fechaProbableParto,
    this.retiroLecheHasta,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.pendiente,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['lecheria_id'] = Variable<String>(lecheriaId);
    map['identificador'] = Variable<String>(identificador);
    map['sexo'] = Variable<String>(sexo);
    map['grupo'] = Variable<String>(grupo);
    map['estado'] = Variable<String>(estado);
    map['estado_reproductivo'] = Variable<String>(estadoReproductivo);
    map['origen'] = Variable<String>(origen);
    if (!nullToAbsent || precioCompra != null) {
      map['precio_compra'] = Variable<double>(precioCompra);
    }
    if (!nullToAbsent || fechaCompra != null) {
      map['fecha_compra'] = Variable<DateTime>(fechaCompra);
    }
    if (!nullToAbsent || madreId != null) {
      map['madre_id'] = Variable<String>(madreId);
    }
    map['concentrado_kg_dia'] = Variable<double>(concentradoKgDia);
    if (!nullToAbsent || fechaProbableParto != null) {
      map['fecha_probable_parto'] = Variable<DateTime>(fechaProbableParto);
    }
    if (!nullToAbsent || retiroLecheHasta != null) {
      map['retiro_leche_hasta'] = Variable<DateTime>(retiroLecheHasta);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['pendiente'] = Variable<bool>(pendiente);
    return map;
  }

  AnimalesCompanion toCompanion(bool nullToAbsent) {
    return AnimalesCompanion(
      id: Value(id),
      lecheriaId: Value(lecheriaId),
      identificador: Value(identificador),
      sexo: Value(sexo),
      grupo: Value(grupo),
      estado: Value(estado),
      estadoReproductivo: Value(estadoReproductivo),
      origen: Value(origen),
      precioCompra: precioCompra == null && nullToAbsent
          ? const Value.absent()
          : Value(precioCompra),
      fechaCompra: fechaCompra == null && nullToAbsent
          ? const Value.absent()
          : Value(fechaCompra),
      madreId: madreId == null && nullToAbsent
          ? const Value.absent()
          : Value(madreId),
      concentradoKgDia: Value(concentradoKgDia),
      fechaProbableParto: fechaProbableParto == null && nullToAbsent
          ? const Value.absent()
          : Value(fechaProbableParto),
      retiroLecheHasta: retiroLecheHasta == null && nullToAbsent
          ? const Value.absent()
          : Value(retiroLecheHasta),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      pendiente: Value(pendiente),
    );
  }

  factory AnimalRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AnimalRow(
      id: serializer.fromJson<String>(json['id']),
      lecheriaId: serializer.fromJson<String>(json['lecheriaId']),
      identificador: serializer.fromJson<String>(json['identificador']),
      sexo: serializer.fromJson<String>(json['sexo']),
      grupo: serializer.fromJson<String>(json['grupo']),
      estado: serializer.fromJson<String>(json['estado']),
      estadoReproductivo: serializer.fromJson<String>(
        json['estadoReproductivo'],
      ),
      origen: serializer.fromJson<String>(json['origen']),
      precioCompra: serializer.fromJson<double?>(json['precioCompra']),
      fechaCompra: serializer.fromJson<DateTime?>(json['fechaCompra']),
      madreId: serializer.fromJson<String?>(json['madreId']),
      concentradoKgDia: serializer.fromJson<double>(json['concentradoKgDia']),
      fechaProbableParto: serializer.fromJson<DateTime?>(
        json['fechaProbableParto'],
      ),
      retiroLecheHasta: serializer.fromJson<DateTime?>(
        json['retiroLecheHasta'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      pendiente: serializer.fromJson<bool>(json['pendiente']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'lecheriaId': serializer.toJson<String>(lecheriaId),
      'identificador': serializer.toJson<String>(identificador),
      'sexo': serializer.toJson<String>(sexo),
      'grupo': serializer.toJson<String>(grupo),
      'estado': serializer.toJson<String>(estado),
      'estadoReproductivo': serializer.toJson<String>(estadoReproductivo),
      'origen': serializer.toJson<String>(origen),
      'precioCompra': serializer.toJson<double?>(precioCompra),
      'fechaCompra': serializer.toJson<DateTime?>(fechaCompra),
      'madreId': serializer.toJson<String?>(madreId),
      'concentradoKgDia': serializer.toJson<double>(concentradoKgDia),
      'fechaProbableParto': serializer.toJson<DateTime?>(fechaProbableParto),
      'retiroLecheHasta': serializer.toJson<DateTime?>(retiroLecheHasta),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'pendiente': serializer.toJson<bool>(pendiente),
    };
  }

  AnimalRow copyWith({
    String? id,
    String? lecheriaId,
    String? identificador,
    String? sexo,
    String? grupo,
    String? estado,
    String? estadoReproductivo,
    String? origen,
    Value<double?> precioCompra = const Value.absent(),
    Value<DateTime?> fechaCompra = const Value.absent(),
    Value<String?> madreId = const Value.absent(),
    double? concentradoKgDia,
    Value<DateTime?> fechaProbableParto = const Value.absent(),
    Value<DateTime?> retiroLecheHasta = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    bool? pendiente,
  }) => AnimalRow(
    id: id ?? this.id,
    lecheriaId: lecheriaId ?? this.lecheriaId,
    identificador: identificador ?? this.identificador,
    sexo: sexo ?? this.sexo,
    grupo: grupo ?? this.grupo,
    estado: estado ?? this.estado,
    estadoReproductivo: estadoReproductivo ?? this.estadoReproductivo,
    origen: origen ?? this.origen,
    precioCompra: precioCompra.present ? precioCompra.value : this.precioCompra,
    fechaCompra: fechaCompra.present ? fechaCompra.value : this.fechaCompra,
    madreId: madreId.present ? madreId.value : this.madreId,
    concentradoKgDia: concentradoKgDia ?? this.concentradoKgDia,
    fechaProbableParto: fechaProbableParto.present
        ? fechaProbableParto.value
        : this.fechaProbableParto,
    retiroLecheHasta: retiroLecheHasta.present
        ? retiroLecheHasta.value
        : this.retiroLecheHasta,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    pendiente: pendiente ?? this.pendiente,
  );
  AnimalRow copyWithCompanion(AnimalesCompanion data) {
    return AnimalRow(
      id: data.id.present ? data.id.value : this.id,
      lecheriaId: data.lecheriaId.present
          ? data.lecheriaId.value
          : this.lecheriaId,
      identificador: data.identificador.present
          ? data.identificador.value
          : this.identificador,
      sexo: data.sexo.present ? data.sexo.value : this.sexo,
      grupo: data.grupo.present ? data.grupo.value : this.grupo,
      estado: data.estado.present ? data.estado.value : this.estado,
      estadoReproductivo: data.estadoReproductivo.present
          ? data.estadoReproductivo.value
          : this.estadoReproductivo,
      origen: data.origen.present ? data.origen.value : this.origen,
      precioCompra: data.precioCompra.present
          ? data.precioCompra.value
          : this.precioCompra,
      fechaCompra: data.fechaCompra.present
          ? data.fechaCompra.value
          : this.fechaCompra,
      madreId: data.madreId.present ? data.madreId.value : this.madreId,
      concentradoKgDia: data.concentradoKgDia.present
          ? data.concentradoKgDia.value
          : this.concentradoKgDia,
      fechaProbableParto: data.fechaProbableParto.present
          ? data.fechaProbableParto.value
          : this.fechaProbableParto,
      retiroLecheHasta: data.retiroLecheHasta.present
          ? data.retiroLecheHasta.value
          : this.retiroLecheHasta,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      pendiente: data.pendiente.present ? data.pendiente.value : this.pendiente,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AnimalRow(')
          ..write('id: $id, ')
          ..write('lecheriaId: $lecheriaId, ')
          ..write('identificador: $identificador, ')
          ..write('sexo: $sexo, ')
          ..write('grupo: $grupo, ')
          ..write('estado: $estado, ')
          ..write('estadoReproductivo: $estadoReproductivo, ')
          ..write('origen: $origen, ')
          ..write('precioCompra: $precioCompra, ')
          ..write('fechaCompra: $fechaCompra, ')
          ..write('madreId: $madreId, ')
          ..write('concentradoKgDia: $concentradoKgDia, ')
          ..write('fechaProbableParto: $fechaProbableParto, ')
          ..write('retiroLecheHasta: $retiroLecheHasta, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('pendiente: $pendiente')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    lecheriaId,
    identificador,
    sexo,
    grupo,
    estado,
    estadoReproductivo,
    origen,
    precioCompra,
    fechaCompra,
    madreId,
    concentradoKgDia,
    fechaProbableParto,
    retiroLecheHasta,
    createdAt,
    updatedAt,
    deletedAt,
    pendiente,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnimalRow &&
          other.id == this.id &&
          other.lecheriaId == this.lecheriaId &&
          other.identificador == this.identificador &&
          other.sexo == this.sexo &&
          other.grupo == this.grupo &&
          other.estado == this.estado &&
          other.estadoReproductivo == this.estadoReproductivo &&
          other.origen == this.origen &&
          other.precioCompra == this.precioCompra &&
          other.fechaCompra == this.fechaCompra &&
          other.madreId == this.madreId &&
          other.concentradoKgDia == this.concentradoKgDia &&
          other.fechaProbableParto == this.fechaProbableParto &&
          other.retiroLecheHasta == this.retiroLecheHasta &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.pendiente == this.pendiente);
}

class AnimalesCompanion extends UpdateCompanion<AnimalRow> {
  final Value<String> id;
  final Value<String> lecheriaId;
  final Value<String> identificador;
  final Value<String> sexo;
  final Value<String> grupo;
  final Value<String> estado;
  final Value<String> estadoReproductivo;
  final Value<String> origen;
  final Value<double?> precioCompra;
  final Value<DateTime?> fechaCompra;
  final Value<String?> madreId;
  final Value<double> concentradoKgDia;
  final Value<DateTime?> fechaProbableParto;
  final Value<DateTime?> retiroLecheHasta;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<bool> pendiente;
  final Value<int> rowid;
  const AnimalesCompanion({
    this.id = const Value.absent(),
    this.lecheriaId = const Value.absent(),
    this.identificador = const Value.absent(),
    this.sexo = const Value.absent(),
    this.grupo = const Value.absent(),
    this.estado = const Value.absent(),
    this.estadoReproductivo = const Value.absent(),
    this.origen = const Value.absent(),
    this.precioCompra = const Value.absent(),
    this.fechaCompra = const Value.absent(),
    this.madreId = const Value.absent(),
    this.concentradoKgDia = const Value.absent(),
    this.fechaProbableParto = const Value.absent(),
    this.retiroLecheHasta = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.pendiente = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AnimalesCompanion.insert({
    required String id,
    required String lecheriaId,
    required String identificador,
    required String sexo,
    required String grupo,
    this.estado = const Value.absent(),
    this.estadoReproductivo = const Value.absent(),
    required String origen,
    this.precioCompra = const Value.absent(),
    this.fechaCompra = const Value.absent(),
    this.madreId = const Value.absent(),
    this.concentradoKgDia = const Value.absent(),
    this.fechaProbableParto = const Value.absent(),
    this.retiroLecheHasta = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.pendiente = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       lecheriaId = Value(lecheriaId),
       identificador = Value(identificador),
       sexo = Value(sexo),
       grupo = Value(grupo),
       origen = Value(origen),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<AnimalRow> custom({
    Expression<String>? id,
    Expression<String>? lecheriaId,
    Expression<String>? identificador,
    Expression<String>? sexo,
    Expression<String>? grupo,
    Expression<String>? estado,
    Expression<String>? estadoReproductivo,
    Expression<String>? origen,
    Expression<double>? precioCompra,
    Expression<DateTime>? fechaCompra,
    Expression<String>? madreId,
    Expression<double>? concentradoKgDia,
    Expression<DateTime>? fechaProbableParto,
    Expression<DateTime>? retiroLecheHasta,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<bool>? pendiente,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lecheriaId != null) 'lecheria_id': lecheriaId,
      if (identificador != null) 'identificador': identificador,
      if (sexo != null) 'sexo': sexo,
      if (grupo != null) 'grupo': grupo,
      if (estado != null) 'estado': estado,
      if (estadoReproductivo != null) 'estado_reproductivo': estadoReproductivo,
      if (origen != null) 'origen': origen,
      if (precioCompra != null) 'precio_compra': precioCompra,
      if (fechaCompra != null) 'fecha_compra': fechaCompra,
      if (madreId != null) 'madre_id': madreId,
      if (concentradoKgDia != null) 'concentrado_kg_dia': concentradoKgDia,
      if (fechaProbableParto != null)
        'fecha_probable_parto': fechaProbableParto,
      if (retiroLecheHasta != null) 'retiro_leche_hasta': retiroLecheHasta,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (pendiente != null) 'pendiente': pendiente,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AnimalesCompanion copyWith({
    Value<String>? id,
    Value<String>? lecheriaId,
    Value<String>? identificador,
    Value<String>? sexo,
    Value<String>? grupo,
    Value<String>? estado,
    Value<String>? estadoReproductivo,
    Value<String>? origen,
    Value<double?>? precioCompra,
    Value<DateTime?>? fechaCompra,
    Value<String?>? madreId,
    Value<double>? concentradoKgDia,
    Value<DateTime?>? fechaProbableParto,
    Value<DateTime?>? retiroLecheHasta,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<bool>? pendiente,
    Value<int>? rowid,
  }) {
    return AnimalesCompanion(
      id: id ?? this.id,
      lecheriaId: lecheriaId ?? this.lecheriaId,
      identificador: identificador ?? this.identificador,
      sexo: sexo ?? this.sexo,
      grupo: grupo ?? this.grupo,
      estado: estado ?? this.estado,
      estadoReproductivo: estadoReproductivo ?? this.estadoReproductivo,
      origen: origen ?? this.origen,
      precioCompra: precioCompra ?? this.precioCompra,
      fechaCompra: fechaCompra ?? this.fechaCompra,
      madreId: madreId ?? this.madreId,
      concentradoKgDia: concentradoKgDia ?? this.concentradoKgDia,
      fechaProbableParto: fechaProbableParto ?? this.fechaProbableParto,
      retiroLecheHasta: retiroLecheHasta ?? this.retiroLecheHasta,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      pendiente: pendiente ?? this.pendiente,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (lecheriaId.present) {
      map['lecheria_id'] = Variable<String>(lecheriaId.value);
    }
    if (identificador.present) {
      map['identificador'] = Variable<String>(identificador.value);
    }
    if (sexo.present) {
      map['sexo'] = Variable<String>(sexo.value);
    }
    if (grupo.present) {
      map['grupo'] = Variable<String>(grupo.value);
    }
    if (estado.present) {
      map['estado'] = Variable<String>(estado.value);
    }
    if (estadoReproductivo.present) {
      map['estado_reproductivo'] = Variable<String>(estadoReproductivo.value);
    }
    if (origen.present) {
      map['origen'] = Variable<String>(origen.value);
    }
    if (precioCompra.present) {
      map['precio_compra'] = Variable<double>(precioCompra.value);
    }
    if (fechaCompra.present) {
      map['fecha_compra'] = Variable<DateTime>(fechaCompra.value);
    }
    if (madreId.present) {
      map['madre_id'] = Variable<String>(madreId.value);
    }
    if (concentradoKgDia.present) {
      map['concentrado_kg_dia'] = Variable<double>(concentradoKgDia.value);
    }
    if (fechaProbableParto.present) {
      map['fecha_probable_parto'] = Variable<DateTime>(
        fechaProbableParto.value,
      );
    }
    if (retiroLecheHasta.present) {
      map['retiro_leche_hasta'] = Variable<DateTime>(retiroLecheHasta.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (pendiente.present) {
      map['pendiente'] = Variable<bool>(pendiente.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnimalesCompanion(')
          ..write('id: $id, ')
          ..write('lecheriaId: $lecheriaId, ')
          ..write('identificador: $identificador, ')
          ..write('sexo: $sexo, ')
          ..write('grupo: $grupo, ')
          ..write('estado: $estado, ')
          ..write('estadoReproductivo: $estadoReproductivo, ')
          ..write('origen: $origen, ')
          ..write('precioCompra: $precioCompra, ')
          ..write('fechaCompra: $fechaCompra, ')
          ..write('madreId: $madreId, ')
          ..write('concentradoKgDia: $concentradoKgDia, ')
          ..write('fechaProbableParto: $fechaProbableParto, ')
          ..write('retiroLecheHasta: $retiroLecheHasta, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('pendiente: $pendiente, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EventosAnimalTable extends EventosAnimal
    with TableInfo<$EventosAnimalTable, EventoAnimalRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventosAnimalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _animalIdMeta = const VerificationMeta(
    'animalId',
  );
  @override
  late final GeneratedColumn<String> animalId = GeneratedColumn<String>(
    'animal_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lecheriaIdMeta = const VerificationMeta(
    'lecheriaId',
  );
  @override
  late final GeneratedColumn<String> lecheriaId = GeneratedColumn<String>(
    'lecheria_id',
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
  static const VerificationMeta _fechaMeta = const VerificationMeta('fecha');
  @override
  late final GeneratedColumn<DateTime> fecha = GeneratedColumn<DateTime>(
    'fecha',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _detalleMeta = const VerificationMeta(
    'detalle',
  );
  @override
  late final GeneratedColumn<String> detalle = GeneratedColumn<String>(
    'detalle',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _medicamentoIdMeta = const VerificationMeta(
    'medicamentoId',
  );
  @override
  late final GeneratedColumn<String> medicamentoId = GeneratedColumn<String>(
    'medicamento_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dosisMeta = const VerificationMeta('dosis');
  @override
  late final GeneratedColumn<String> dosis = GeneratedColumn<String>(
    'dosis',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _diasRetiroMeta = const VerificationMeta(
    'diasRetiro',
  );
  @override
  late final GeneratedColumn<int> diasRetiro = GeneratedColumn<int>(
    'dias_retiro',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _costoMeta = const VerificationMeta('costo');
  @override
  late final GeneratedColumn<double> costo = GeneratedColumn<double>(
    'costo',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resultadoMeta = const VerificationMeta(
    'resultado',
  );
  @override
  late final GeneratedColumn<String> resultado = GeneratedColumn<String>(
    'resultado',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _toroPajillaMeta = const VerificationMeta(
    'toroPajilla',
  );
  @override
  late final GeneratedColumn<String> toroPajilla = GeneratedColumn<String>(
    'toro_pajilla',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sexoCriaMeta = const VerificationMeta(
    'sexoCria',
  );
  @override
  late final GeneratedColumn<String> sexoCria = GeneratedColumn<String>(
    'sexo_cria',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _grupoAnteriorMeta = const VerificationMeta(
    'grupoAnterior',
  );
  @override
  late final GeneratedColumn<String> grupoAnterior = GeneratedColumn<String>(
    'grupo_anterior',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _grupoNuevoMeta = const VerificationMeta(
    'grupoNuevo',
  );
  @override
  late final GeneratedColumn<String> grupoNuevo = GeneratedColumn<String>(
    'grupo_nuevo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _motivoBajaMeta = const VerificationMeta(
    'motivoBaja',
  );
  @override
  late final GeneratedColumn<String> motivoBaja = GeneratedColumn<String>(
    'motivo_baja',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _precioVentaMeta = const VerificationMeta(
    'precioVenta',
  );
  @override
  late final GeneratedColumn<double> precioVenta = GeneratedColumn<double>(
    'precio_venta',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _criaAnimalIdMeta = const VerificationMeta(
    'criaAnimalId',
  );
  @override
  late final GeneratedColumn<String> criaAnimalId = GeneratedColumn<String>(
    'cria_animal_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _registradoPorMeta = const VerificationMeta(
    'registradoPor',
  );
  @override
  late final GeneratedColumn<String> registradoPor = GeneratedColumn<String>(
    'registrado_por',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pendienteMeta = const VerificationMeta(
    'pendiente',
  );
  @override
  late final GeneratedColumn<bool> pendiente = GeneratedColumn<bool>(
    'pendiente',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pendiente" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    animalId,
    lecheriaId,
    tipo,
    fecha,
    detalle,
    medicamentoId,
    dosis,
    diasRetiro,
    costo,
    resultado,
    toroPajilla,
    sexoCria,
    grupoAnterior,
    grupoNuevo,
    motivoBaja,
    precioVenta,
    criaAnimalId,
    registradoPor,
    createdAt,
    updatedAt,
    deletedAt,
    pendiente,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'eventos_animal';
  @override
  VerificationContext validateIntegrity(
    Insertable<EventoAnimalRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('animal_id')) {
      context.handle(
        _animalIdMeta,
        animalId.isAcceptableOrUnknown(data['animal_id']!, _animalIdMeta),
      );
    } else if (isInserting) {
      context.missing(_animalIdMeta);
    }
    if (data.containsKey('lecheria_id')) {
      context.handle(
        _lecheriaIdMeta,
        lecheriaId.isAcceptableOrUnknown(data['lecheria_id']!, _lecheriaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_lecheriaIdMeta);
    }
    if (data.containsKey('tipo')) {
      context.handle(
        _tipoMeta,
        tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta),
      );
    } else if (isInserting) {
      context.missing(_tipoMeta);
    }
    if (data.containsKey('fecha')) {
      context.handle(
        _fechaMeta,
        fecha.isAcceptableOrUnknown(data['fecha']!, _fechaMeta),
      );
    } else if (isInserting) {
      context.missing(_fechaMeta);
    }
    if (data.containsKey('detalle')) {
      context.handle(
        _detalleMeta,
        detalle.isAcceptableOrUnknown(data['detalle']!, _detalleMeta),
      );
    }
    if (data.containsKey('medicamento_id')) {
      context.handle(
        _medicamentoIdMeta,
        medicamentoId.isAcceptableOrUnknown(
          data['medicamento_id']!,
          _medicamentoIdMeta,
        ),
      );
    }
    if (data.containsKey('dosis')) {
      context.handle(
        _dosisMeta,
        dosis.isAcceptableOrUnknown(data['dosis']!, _dosisMeta),
      );
    }
    if (data.containsKey('dias_retiro')) {
      context.handle(
        _diasRetiroMeta,
        diasRetiro.isAcceptableOrUnknown(data['dias_retiro']!, _diasRetiroMeta),
      );
    }
    if (data.containsKey('costo')) {
      context.handle(
        _costoMeta,
        costo.isAcceptableOrUnknown(data['costo']!, _costoMeta),
      );
    }
    if (data.containsKey('resultado')) {
      context.handle(
        _resultadoMeta,
        resultado.isAcceptableOrUnknown(data['resultado']!, _resultadoMeta),
      );
    }
    if (data.containsKey('toro_pajilla')) {
      context.handle(
        _toroPajillaMeta,
        toroPajilla.isAcceptableOrUnknown(
          data['toro_pajilla']!,
          _toroPajillaMeta,
        ),
      );
    }
    if (data.containsKey('sexo_cria')) {
      context.handle(
        _sexoCriaMeta,
        sexoCria.isAcceptableOrUnknown(data['sexo_cria']!, _sexoCriaMeta),
      );
    }
    if (data.containsKey('grupo_anterior')) {
      context.handle(
        _grupoAnteriorMeta,
        grupoAnterior.isAcceptableOrUnknown(
          data['grupo_anterior']!,
          _grupoAnteriorMeta,
        ),
      );
    }
    if (data.containsKey('grupo_nuevo')) {
      context.handle(
        _grupoNuevoMeta,
        grupoNuevo.isAcceptableOrUnknown(data['grupo_nuevo']!, _grupoNuevoMeta),
      );
    }
    if (data.containsKey('motivo_baja')) {
      context.handle(
        _motivoBajaMeta,
        motivoBaja.isAcceptableOrUnknown(data['motivo_baja']!, _motivoBajaMeta),
      );
    }
    if (data.containsKey('precio_venta')) {
      context.handle(
        _precioVentaMeta,
        precioVenta.isAcceptableOrUnknown(
          data['precio_venta']!,
          _precioVentaMeta,
        ),
      );
    }
    if (data.containsKey('cria_animal_id')) {
      context.handle(
        _criaAnimalIdMeta,
        criaAnimalId.isAcceptableOrUnknown(
          data['cria_animal_id']!,
          _criaAnimalIdMeta,
        ),
      );
    }
    if (data.containsKey('registrado_por')) {
      context.handle(
        _registradoPorMeta,
        registradoPor.isAcceptableOrUnknown(
          data['registrado_por']!,
          _registradoPorMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('pendiente')) {
      context.handle(
        _pendienteMeta,
        pendiente.isAcceptableOrUnknown(data['pendiente']!, _pendienteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EventoAnimalRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EventoAnimalRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      animalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}animal_id'],
      )!,
      lecheriaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lecheria_id'],
      )!,
      tipo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo'],
      )!,
      fecha: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha'],
      )!,
      detalle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}detalle'],
      ),
      medicamentoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medicamento_id'],
      ),
      dosis: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dosis'],
      ),
      diasRetiro: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dias_retiro'],
      ),
      costo: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}costo'],
      ),
      resultado: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resultado'],
      ),
      toroPajilla: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}toro_pajilla'],
      ),
      sexoCria: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sexo_cria'],
      ),
      grupoAnterior: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grupo_anterior'],
      ),
      grupoNuevo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grupo_nuevo'],
      ),
      motivoBaja: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}motivo_baja'],
      ),
      precioVenta: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}precio_venta'],
      ),
      criaAnimalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cria_animal_id'],
      ),
      registradoPor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}registrado_por'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      pendiente: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pendiente'],
      )!,
    );
  }

  @override
  $EventosAnimalTable createAlias(String alias) {
    return $EventosAnimalTable(attachedDatabase, alias);
  }
}

class EventoAnimalRow extends DataClass implements Insertable<EventoAnimalRow> {
  final String id;
  final String animalId;
  final String lecheriaId;
  final String tipo;
  final DateTime fecha;
  final String? detalle;
  final String? medicamentoId;
  final String? dosis;
  final int? diasRetiro;
  final double? costo;
  final String? resultado;
  final String? toroPajilla;
  final String? sexoCria;
  final String? grupoAnterior;
  final String? grupoNuevo;
  final String? motivoBaja;
  final double? precioVenta;
  final String? criaAnimalId;
  final String? registradoPor;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool pendiente;
  const EventoAnimalRow({
    required this.id,
    required this.animalId,
    required this.lecheriaId,
    required this.tipo,
    required this.fecha,
    this.detalle,
    this.medicamentoId,
    this.dosis,
    this.diasRetiro,
    this.costo,
    this.resultado,
    this.toroPajilla,
    this.sexoCria,
    this.grupoAnterior,
    this.grupoNuevo,
    this.motivoBaja,
    this.precioVenta,
    this.criaAnimalId,
    this.registradoPor,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.pendiente,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['animal_id'] = Variable<String>(animalId);
    map['lecheria_id'] = Variable<String>(lecheriaId);
    map['tipo'] = Variable<String>(tipo);
    map['fecha'] = Variable<DateTime>(fecha);
    if (!nullToAbsent || detalle != null) {
      map['detalle'] = Variable<String>(detalle);
    }
    if (!nullToAbsent || medicamentoId != null) {
      map['medicamento_id'] = Variable<String>(medicamentoId);
    }
    if (!nullToAbsent || dosis != null) {
      map['dosis'] = Variable<String>(dosis);
    }
    if (!nullToAbsent || diasRetiro != null) {
      map['dias_retiro'] = Variable<int>(diasRetiro);
    }
    if (!nullToAbsent || costo != null) {
      map['costo'] = Variable<double>(costo);
    }
    if (!nullToAbsent || resultado != null) {
      map['resultado'] = Variable<String>(resultado);
    }
    if (!nullToAbsent || toroPajilla != null) {
      map['toro_pajilla'] = Variable<String>(toroPajilla);
    }
    if (!nullToAbsent || sexoCria != null) {
      map['sexo_cria'] = Variable<String>(sexoCria);
    }
    if (!nullToAbsent || grupoAnterior != null) {
      map['grupo_anterior'] = Variable<String>(grupoAnterior);
    }
    if (!nullToAbsent || grupoNuevo != null) {
      map['grupo_nuevo'] = Variable<String>(grupoNuevo);
    }
    if (!nullToAbsent || motivoBaja != null) {
      map['motivo_baja'] = Variable<String>(motivoBaja);
    }
    if (!nullToAbsent || precioVenta != null) {
      map['precio_venta'] = Variable<double>(precioVenta);
    }
    if (!nullToAbsent || criaAnimalId != null) {
      map['cria_animal_id'] = Variable<String>(criaAnimalId);
    }
    if (!nullToAbsent || registradoPor != null) {
      map['registrado_por'] = Variable<String>(registradoPor);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['pendiente'] = Variable<bool>(pendiente);
    return map;
  }

  EventosAnimalCompanion toCompanion(bool nullToAbsent) {
    return EventosAnimalCompanion(
      id: Value(id),
      animalId: Value(animalId),
      lecheriaId: Value(lecheriaId),
      tipo: Value(tipo),
      fecha: Value(fecha),
      detalle: detalle == null && nullToAbsent
          ? const Value.absent()
          : Value(detalle),
      medicamentoId: medicamentoId == null && nullToAbsent
          ? const Value.absent()
          : Value(medicamentoId),
      dosis: dosis == null && nullToAbsent
          ? const Value.absent()
          : Value(dosis),
      diasRetiro: diasRetiro == null && nullToAbsent
          ? const Value.absent()
          : Value(diasRetiro),
      costo: costo == null && nullToAbsent
          ? const Value.absent()
          : Value(costo),
      resultado: resultado == null && nullToAbsent
          ? const Value.absent()
          : Value(resultado),
      toroPajilla: toroPajilla == null && nullToAbsent
          ? const Value.absent()
          : Value(toroPajilla),
      sexoCria: sexoCria == null && nullToAbsent
          ? const Value.absent()
          : Value(sexoCria),
      grupoAnterior: grupoAnterior == null && nullToAbsent
          ? const Value.absent()
          : Value(grupoAnterior),
      grupoNuevo: grupoNuevo == null && nullToAbsent
          ? const Value.absent()
          : Value(grupoNuevo),
      motivoBaja: motivoBaja == null && nullToAbsent
          ? const Value.absent()
          : Value(motivoBaja),
      precioVenta: precioVenta == null && nullToAbsent
          ? const Value.absent()
          : Value(precioVenta),
      criaAnimalId: criaAnimalId == null && nullToAbsent
          ? const Value.absent()
          : Value(criaAnimalId),
      registradoPor: registradoPor == null && nullToAbsent
          ? const Value.absent()
          : Value(registradoPor),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      pendiente: Value(pendiente),
    );
  }

  factory EventoAnimalRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EventoAnimalRow(
      id: serializer.fromJson<String>(json['id']),
      animalId: serializer.fromJson<String>(json['animalId']),
      lecheriaId: serializer.fromJson<String>(json['lecheriaId']),
      tipo: serializer.fromJson<String>(json['tipo']),
      fecha: serializer.fromJson<DateTime>(json['fecha']),
      detalle: serializer.fromJson<String?>(json['detalle']),
      medicamentoId: serializer.fromJson<String?>(json['medicamentoId']),
      dosis: serializer.fromJson<String?>(json['dosis']),
      diasRetiro: serializer.fromJson<int?>(json['diasRetiro']),
      costo: serializer.fromJson<double?>(json['costo']),
      resultado: serializer.fromJson<String?>(json['resultado']),
      toroPajilla: serializer.fromJson<String?>(json['toroPajilla']),
      sexoCria: serializer.fromJson<String?>(json['sexoCria']),
      grupoAnterior: serializer.fromJson<String?>(json['grupoAnterior']),
      grupoNuevo: serializer.fromJson<String?>(json['grupoNuevo']),
      motivoBaja: serializer.fromJson<String?>(json['motivoBaja']),
      precioVenta: serializer.fromJson<double?>(json['precioVenta']),
      criaAnimalId: serializer.fromJson<String?>(json['criaAnimalId']),
      registradoPor: serializer.fromJson<String?>(json['registradoPor']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      pendiente: serializer.fromJson<bool>(json['pendiente']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'animalId': serializer.toJson<String>(animalId),
      'lecheriaId': serializer.toJson<String>(lecheriaId),
      'tipo': serializer.toJson<String>(tipo),
      'fecha': serializer.toJson<DateTime>(fecha),
      'detalle': serializer.toJson<String?>(detalle),
      'medicamentoId': serializer.toJson<String?>(medicamentoId),
      'dosis': serializer.toJson<String?>(dosis),
      'diasRetiro': serializer.toJson<int?>(diasRetiro),
      'costo': serializer.toJson<double?>(costo),
      'resultado': serializer.toJson<String?>(resultado),
      'toroPajilla': serializer.toJson<String?>(toroPajilla),
      'sexoCria': serializer.toJson<String?>(sexoCria),
      'grupoAnterior': serializer.toJson<String?>(grupoAnterior),
      'grupoNuevo': serializer.toJson<String?>(grupoNuevo),
      'motivoBaja': serializer.toJson<String?>(motivoBaja),
      'precioVenta': serializer.toJson<double?>(precioVenta),
      'criaAnimalId': serializer.toJson<String?>(criaAnimalId),
      'registradoPor': serializer.toJson<String?>(registradoPor),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'pendiente': serializer.toJson<bool>(pendiente),
    };
  }

  EventoAnimalRow copyWith({
    String? id,
    String? animalId,
    String? lecheriaId,
    String? tipo,
    DateTime? fecha,
    Value<String?> detalle = const Value.absent(),
    Value<String?> medicamentoId = const Value.absent(),
    Value<String?> dosis = const Value.absent(),
    Value<int?> diasRetiro = const Value.absent(),
    Value<double?> costo = const Value.absent(),
    Value<String?> resultado = const Value.absent(),
    Value<String?> toroPajilla = const Value.absent(),
    Value<String?> sexoCria = const Value.absent(),
    Value<String?> grupoAnterior = const Value.absent(),
    Value<String?> grupoNuevo = const Value.absent(),
    Value<String?> motivoBaja = const Value.absent(),
    Value<double?> precioVenta = const Value.absent(),
    Value<String?> criaAnimalId = const Value.absent(),
    Value<String?> registradoPor = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    bool? pendiente,
  }) => EventoAnimalRow(
    id: id ?? this.id,
    animalId: animalId ?? this.animalId,
    lecheriaId: lecheriaId ?? this.lecheriaId,
    tipo: tipo ?? this.tipo,
    fecha: fecha ?? this.fecha,
    detalle: detalle.present ? detalle.value : this.detalle,
    medicamentoId: medicamentoId.present
        ? medicamentoId.value
        : this.medicamentoId,
    dosis: dosis.present ? dosis.value : this.dosis,
    diasRetiro: diasRetiro.present ? diasRetiro.value : this.diasRetiro,
    costo: costo.present ? costo.value : this.costo,
    resultado: resultado.present ? resultado.value : this.resultado,
    toroPajilla: toroPajilla.present ? toroPajilla.value : this.toroPajilla,
    sexoCria: sexoCria.present ? sexoCria.value : this.sexoCria,
    grupoAnterior: grupoAnterior.present
        ? grupoAnterior.value
        : this.grupoAnterior,
    grupoNuevo: grupoNuevo.present ? grupoNuevo.value : this.grupoNuevo,
    motivoBaja: motivoBaja.present ? motivoBaja.value : this.motivoBaja,
    precioVenta: precioVenta.present ? precioVenta.value : this.precioVenta,
    criaAnimalId: criaAnimalId.present ? criaAnimalId.value : this.criaAnimalId,
    registradoPor: registradoPor.present
        ? registradoPor.value
        : this.registradoPor,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    pendiente: pendiente ?? this.pendiente,
  );
  EventoAnimalRow copyWithCompanion(EventosAnimalCompanion data) {
    return EventoAnimalRow(
      id: data.id.present ? data.id.value : this.id,
      animalId: data.animalId.present ? data.animalId.value : this.animalId,
      lecheriaId: data.lecheriaId.present
          ? data.lecheriaId.value
          : this.lecheriaId,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      fecha: data.fecha.present ? data.fecha.value : this.fecha,
      detalle: data.detalle.present ? data.detalle.value : this.detalle,
      medicamentoId: data.medicamentoId.present
          ? data.medicamentoId.value
          : this.medicamentoId,
      dosis: data.dosis.present ? data.dosis.value : this.dosis,
      diasRetiro: data.diasRetiro.present
          ? data.diasRetiro.value
          : this.diasRetiro,
      costo: data.costo.present ? data.costo.value : this.costo,
      resultado: data.resultado.present ? data.resultado.value : this.resultado,
      toroPajilla: data.toroPajilla.present
          ? data.toroPajilla.value
          : this.toroPajilla,
      sexoCria: data.sexoCria.present ? data.sexoCria.value : this.sexoCria,
      grupoAnterior: data.grupoAnterior.present
          ? data.grupoAnterior.value
          : this.grupoAnterior,
      grupoNuevo: data.grupoNuevo.present
          ? data.grupoNuevo.value
          : this.grupoNuevo,
      motivoBaja: data.motivoBaja.present
          ? data.motivoBaja.value
          : this.motivoBaja,
      precioVenta: data.precioVenta.present
          ? data.precioVenta.value
          : this.precioVenta,
      criaAnimalId: data.criaAnimalId.present
          ? data.criaAnimalId.value
          : this.criaAnimalId,
      registradoPor: data.registradoPor.present
          ? data.registradoPor.value
          : this.registradoPor,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      pendiente: data.pendiente.present ? data.pendiente.value : this.pendiente,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EventoAnimalRow(')
          ..write('id: $id, ')
          ..write('animalId: $animalId, ')
          ..write('lecheriaId: $lecheriaId, ')
          ..write('tipo: $tipo, ')
          ..write('fecha: $fecha, ')
          ..write('detalle: $detalle, ')
          ..write('medicamentoId: $medicamentoId, ')
          ..write('dosis: $dosis, ')
          ..write('diasRetiro: $diasRetiro, ')
          ..write('costo: $costo, ')
          ..write('resultado: $resultado, ')
          ..write('toroPajilla: $toroPajilla, ')
          ..write('sexoCria: $sexoCria, ')
          ..write('grupoAnterior: $grupoAnterior, ')
          ..write('grupoNuevo: $grupoNuevo, ')
          ..write('motivoBaja: $motivoBaja, ')
          ..write('precioVenta: $precioVenta, ')
          ..write('criaAnimalId: $criaAnimalId, ')
          ..write('registradoPor: $registradoPor, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('pendiente: $pendiente')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    animalId,
    lecheriaId,
    tipo,
    fecha,
    detalle,
    medicamentoId,
    dosis,
    diasRetiro,
    costo,
    resultado,
    toroPajilla,
    sexoCria,
    grupoAnterior,
    grupoNuevo,
    motivoBaja,
    precioVenta,
    criaAnimalId,
    registradoPor,
    createdAt,
    updatedAt,
    deletedAt,
    pendiente,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventoAnimalRow &&
          other.id == this.id &&
          other.animalId == this.animalId &&
          other.lecheriaId == this.lecheriaId &&
          other.tipo == this.tipo &&
          other.fecha == this.fecha &&
          other.detalle == this.detalle &&
          other.medicamentoId == this.medicamentoId &&
          other.dosis == this.dosis &&
          other.diasRetiro == this.diasRetiro &&
          other.costo == this.costo &&
          other.resultado == this.resultado &&
          other.toroPajilla == this.toroPajilla &&
          other.sexoCria == this.sexoCria &&
          other.grupoAnterior == this.grupoAnterior &&
          other.grupoNuevo == this.grupoNuevo &&
          other.motivoBaja == this.motivoBaja &&
          other.precioVenta == this.precioVenta &&
          other.criaAnimalId == this.criaAnimalId &&
          other.registradoPor == this.registradoPor &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.pendiente == this.pendiente);
}

class EventosAnimalCompanion extends UpdateCompanion<EventoAnimalRow> {
  final Value<String> id;
  final Value<String> animalId;
  final Value<String> lecheriaId;
  final Value<String> tipo;
  final Value<DateTime> fecha;
  final Value<String?> detalle;
  final Value<String?> medicamentoId;
  final Value<String?> dosis;
  final Value<int?> diasRetiro;
  final Value<double?> costo;
  final Value<String?> resultado;
  final Value<String?> toroPajilla;
  final Value<String?> sexoCria;
  final Value<String?> grupoAnterior;
  final Value<String?> grupoNuevo;
  final Value<String?> motivoBaja;
  final Value<double?> precioVenta;
  final Value<String?> criaAnimalId;
  final Value<String?> registradoPor;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<bool> pendiente;
  final Value<int> rowid;
  const EventosAnimalCompanion({
    this.id = const Value.absent(),
    this.animalId = const Value.absent(),
    this.lecheriaId = const Value.absent(),
    this.tipo = const Value.absent(),
    this.fecha = const Value.absent(),
    this.detalle = const Value.absent(),
    this.medicamentoId = const Value.absent(),
    this.dosis = const Value.absent(),
    this.diasRetiro = const Value.absent(),
    this.costo = const Value.absent(),
    this.resultado = const Value.absent(),
    this.toroPajilla = const Value.absent(),
    this.sexoCria = const Value.absent(),
    this.grupoAnterior = const Value.absent(),
    this.grupoNuevo = const Value.absent(),
    this.motivoBaja = const Value.absent(),
    this.precioVenta = const Value.absent(),
    this.criaAnimalId = const Value.absent(),
    this.registradoPor = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.pendiente = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EventosAnimalCompanion.insert({
    required String id,
    required String animalId,
    required String lecheriaId,
    required String tipo,
    required DateTime fecha,
    this.detalle = const Value.absent(),
    this.medicamentoId = const Value.absent(),
    this.dosis = const Value.absent(),
    this.diasRetiro = const Value.absent(),
    this.costo = const Value.absent(),
    this.resultado = const Value.absent(),
    this.toroPajilla = const Value.absent(),
    this.sexoCria = const Value.absent(),
    this.grupoAnterior = const Value.absent(),
    this.grupoNuevo = const Value.absent(),
    this.motivoBaja = const Value.absent(),
    this.precioVenta = const Value.absent(),
    this.criaAnimalId = const Value.absent(),
    this.registradoPor = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.pendiente = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       animalId = Value(animalId),
       lecheriaId = Value(lecheriaId),
       tipo = Value(tipo),
       fecha = Value(fecha),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<EventoAnimalRow> custom({
    Expression<String>? id,
    Expression<String>? animalId,
    Expression<String>? lecheriaId,
    Expression<String>? tipo,
    Expression<DateTime>? fecha,
    Expression<String>? detalle,
    Expression<String>? medicamentoId,
    Expression<String>? dosis,
    Expression<int>? diasRetiro,
    Expression<double>? costo,
    Expression<String>? resultado,
    Expression<String>? toroPajilla,
    Expression<String>? sexoCria,
    Expression<String>? grupoAnterior,
    Expression<String>? grupoNuevo,
    Expression<String>? motivoBaja,
    Expression<double>? precioVenta,
    Expression<String>? criaAnimalId,
    Expression<String>? registradoPor,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<bool>? pendiente,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (animalId != null) 'animal_id': animalId,
      if (lecheriaId != null) 'lecheria_id': lecheriaId,
      if (tipo != null) 'tipo': tipo,
      if (fecha != null) 'fecha': fecha,
      if (detalle != null) 'detalle': detalle,
      if (medicamentoId != null) 'medicamento_id': medicamentoId,
      if (dosis != null) 'dosis': dosis,
      if (diasRetiro != null) 'dias_retiro': diasRetiro,
      if (costo != null) 'costo': costo,
      if (resultado != null) 'resultado': resultado,
      if (toroPajilla != null) 'toro_pajilla': toroPajilla,
      if (sexoCria != null) 'sexo_cria': sexoCria,
      if (grupoAnterior != null) 'grupo_anterior': grupoAnterior,
      if (grupoNuevo != null) 'grupo_nuevo': grupoNuevo,
      if (motivoBaja != null) 'motivo_baja': motivoBaja,
      if (precioVenta != null) 'precio_venta': precioVenta,
      if (criaAnimalId != null) 'cria_animal_id': criaAnimalId,
      if (registradoPor != null) 'registrado_por': registradoPor,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (pendiente != null) 'pendiente': pendiente,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EventosAnimalCompanion copyWith({
    Value<String>? id,
    Value<String>? animalId,
    Value<String>? lecheriaId,
    Value<String>? tipo,
    Value<DateTime>? fecha,
    Value<String?>? detalle,
    Value<String?>? medicamentoId,
    Value<String?>? dosis,
    Value<int?>? diasRetiro,
    Value<double?>? costo,
    Value<String?>? resultado,
    Value<String?>? toroPajilla,
    Value<String?>? sexoCria,
    Value<String?>? grupoAnterior,
    Value<String?>? grupoNuevo,
    Value<String?>? motivoBaja,
    Value<double?>? precioVenta,
    Value<String?>? criaAnimalId,
    Value<String?>? registradoPor,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<bool>? pendiente,
    Value<int>? rowid,
  }) {
    return EventosAnimalCompanion(
      id: id ?? this.id,
      animalId: animalId ?? this.animalId,
      lecheriaId: lecheriaId ?? this.lecheriaId,
      tipo: tipo ?? this.tipo,
      fecha: fecha ?? this.fecha,
      detalle: detalle ?? this.detalle,
      medicamentoId: medicamentoId ?? this.medicamentoId,
      dosis: dosis ?? this.dosis,
      diasRetiro: diasRetiro ?? this.diasRetiro,
      costo: costo ?? this.costo,
      resultado: resultado ?? this.resultado,
      toroPajilla: toroPajilla ?? this.toroPajilla,
      sexoCria: sexoCria ?? this.sexoCria,
      grupoAnterior: grupoAnterior ?? this.grupoAnterior,
      grupoNuevo: grupoNuevo ?? this.grupoNuevo,
      motivoBaja: motivoBaja ?? this.motivoBaja,
      precioVenta: precioVenta ?? this.precioVenta,
      criaAnimalId: criaAnimalId ?? this.criaAnimalId,
      registradoPor: registradoPor ?? this.registradoPor,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      pendiente: pendiente ?? this.pendiente,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (animalId.present) {
      map['animal_id'] = Variable<String>(animalId.value);
    }
    if (lecheriaId.present) {
      map['lecheria_id'] = Variable<String>(lecheriaId.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (fecha.present) {
      map['fecha'] = Variable<DateTime>(fecha.value);
    }
    if (detalle.present) {
      map['detalle'] = Variable<String>(detalle.value);
    }
    if (medicamentoId.present) {
      map['medicamento_id'] = Variable<String>(medicamentoId.value);
    }
    if (dosis.present) {
      map['dosis'] = Variable<String>(dosis.value);
    }
    if (diasRetiro.present) {
      map['dias_retiro'] = Variable<int>(diasRetiro.value);
    }
    if (costo.present) {
      map['costo'] = Variable<double>(costo.value);
    }
    if (resultado.present) {
      map['resultado'] = Variable<String>(resultado.value);
    }
    if (toroPajilla.present) {
      map['toro_pajilla'] = Variable<String>(toroPajilla.value);
    }
    if (sexoCria.present) {
      map['sexo_cria'] = Variable<String>(sexoCria.value);
    }
    if (grupoAnterior.present) {
      map['grupo_anterior'] = Variable<String>(grupoAnterior.value);
    }
    if (grupoNuevo.present) {
      map['grupo_nuevo'] = Variable<String>(grupoNuevo.value);
    }
    if (motivoBaja.present) {
      map['motivo_baja'] = Variable<String>(motivoBaja.value);
    }
    if (precioVenta.present) {
      map['precio_venta'] = Variable<double>(precioVenta.value);
    }
    if (criaAnimalId.present) {
      map['cria_animal_id'] = Variable<String>(criaAnimalId.value);
    }
    if (registradoPor.present) {
      map['registrado_por'] = Variable<String>(registradoPor.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (pendiente.present) {
      map['pendiente'] = Variable<bool>(pendiente.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventosAnimalCompanion(')
          ..write('id: $id, ')
          ..write('animalId: $animalId, ')
          ..write('lecheriaId: $lecheriaId, ')
          ..write('tipo: $tipo, ')
          ..write('fecha: $fecha, ')
          ..write('detalle: $detalle, ')
          ..write('medicamentoId: $medicamentoId, ')
          ..write('dosis: $dosis, ')
          ..write('diasRetiro: $diasRetiro, ')
          ..write('costo: $costo, ')
          ..write('resultado: $resultado, ')
          ..write('toroPajilla: $toroPajilla, ')
          ..write('sexoCria: $sexoCria, ')
          ..write('grupoAnterior: $grupoAnterior, ')
          ..write('grupoNuevo: $grupoNuevo, ')
          ..write('motivoBaja: $motivoBaja, ')
          ..write('precioVenta: $precioVenta, ')
          ..write('criaAnimalId: $criaAnimalId, ')
          ..write('registradoPor: $registradoPor, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('pendiente: $pendiente, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PesasSesionesTable extends PesasSesiones
    with TableInfo<$PesasSesionesTable, PesaSesionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PesasSesionesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lecheriaIdMeta = const VerificationMeta(
    'lecheriaId',
  );
  @override
  late final GeneratedColumn<String> lecheriaId = GeneratedColumn<String>(
    'lecheria_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fechaMeta = const VerificationMeta('fecha');
  @override
  late final GeneratedColumn<DateTime> fecha = GeneratedColumn<DateTime>(
    'fecha',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cerradaMeta = const VerificationMeta(
    'cerrada',
  );
  @override
  late final GeneratedColumn<bool> cerrada = GeneratedColumn<bool>(
    'cerrada',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("cerrada" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pendienteMeta = const VerificationMeta(
    'pendiente',
  );
  @override
  late final GeneratedColumn<bool> pendiente = GeneratedColumn<bool>(
    'pendiente',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pendiente" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    lecheriaId,
    fecha,
    cerrada,
    createdAt,
    updatedAt,
    deletedAt,
    pendiente,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pesas_sesiones';
  @override
  VerificationContext validateIntegrity(
    Insertable<PesaSesionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('lecheria_id')) {
      context.handle(
        _lecheriaIdMeta,
        lecheriaId.isAcceptableOrUnknown(data['lecheria_id']!, _lecheriaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_lecheriaIdMeta);
    }
    if (data.containsKey('fecha')) {
      context.handle(
        _fechaMeta,
        fecha.isAcceptableOrUnknown(data['fecha']!, _fechaMeta),
      );
    } else if (isInserting) {
      context.missing(_fechaMeta);
    }
    if (data.containsKey('cerrada')) {
      context.handle(
        _cerradaMeta,
        cerrada.isAcceptableOrUnknown(data['cerrada']!, _cerradaMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('pendiente')) {
      context.handle(
        _pendienteMeta,
        pendiente.isAcceptableOrUnknown(data['pendiente']!, _pendienteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PesaSesionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PesaSesionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      lecheriaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lecheria_id'],
      )!,
      fecha: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha'],
      )!,
      cerrada: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}cerrada'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      pendiente: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pendiente'],
      )!,
    );
  }

  @override
  $PesasSesionesTable createAlias(String alias) {
    return $PesasSesionesTable(attachedDatabase, alias);
  }
}

class PesaSesionRow extends DataClass implements Insertable<PesaSesionRow> {
  final String id;
  final String lecheriaId;
  final DateTime fecha;
  final bool cerrada;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool pendiente;
  const PesaSesionRow({
    required this.id,
    required this.lecheriaId,
    required this.fecha,
    required this.cerrada,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.pendiente,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['lecheria_id'] = Variable<String>(lecheriaId);
    map['fecha'] = Variable<DateTime>(fecha);
    map['cerrada'] = Variable<bool>(cerrada);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['pendiente'] = Variable<bool>(pendiente);
    return map;
  }

  PesasSesionesCompanion toCompanion(bool nullToAbsent) {
    return PesasSesionesCompanion(
      id: Value(id),
      lecheriaId: Value(lecheriaId),
      fecha: Value(fecha),
      cerrada: Value(cerrada),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      pendiente: Value(pendiente),
    );
  }

  factory PesaSesionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PesaSesionRow(
      id: serializer.fromJson<String>(json['id']),
      lecheriaId: serializer.fromJson<String>(json['lecheriaId']),
      fecha: serializer.fromJson<DateTime>(json['fecha']),
      cerrada: serializer.fromJson<bool>(json['cerrada']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      pendiente: serializer.fromJson<bool>(json['pendiente']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'lecheriaId': serializer.toJson<String>(lecheriaId),
      'fecha': serializer.toJson<DateTime>(fecha),
      'cerrada': serializer.toJson<bool>(cerrada),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'pendiente': serializer.toJson<bool>(pendiente),
    };
  }

  PesaSesionRow copyWith({
    String? id,
    String? lecheriaId,
    DateTime? fecha,
    bool? cerrada,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    bool? pendiente,
  }) => PesaSesionRow(
    id: id ?? this.id,
    lecheriaId: lecheriaId ?? this.lecheriaId,
    fecha: fecha ?? this.fecha,
    cerrada: cerrada ?? this.cerrada,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    pendiente: pendiente ?? this.pendiente,
  );
  PesaSesionRow copyWithCompanion(PesasSesionesCompanion data) {
    return PesaSesionRow(
      id: data.id.present ? data.id.value : this.id,
      lecheriaId: data.lecheriaId.present
          ? data.lecheriaId.value
          : this.lecheriaId,
      fecha: data.fecha.present ? data.fecha.value : this.fecha,
      cerrada: data.cerrada.present ? data.cerrada.value : this.cerrada,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      pendiente: data.pendiente.present ? data.pendiente.value : this.pendiente,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PesaSesionRow(')
          ..write('id: $id, ')
          ..write('lecheriaId: $lecheriaId, ')
          ..write('fecha: $fecha, ')
          ..write('cerrada: $cerrada, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('pendiente: $pendiente')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    lecheriaId,
    fecha,
    cerrada,
    createdAt,
    updatedAt,
    deletedAt,
    pendiente,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PesaSesionRow &&
          other.id == this.id &&
          other.lecheriaId == this.lecheriaId &&
          other.fecha == this.fecha &&
          other.cerrada == this.cerrada &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.pendiente == this.pendiente);
}

class PesasSesionesCompanion extends UpdateCompanion<PesaSesionRow> {
  final Value<String> id;
  final Value<String> lecheriaId;
  final Value<DateTime> fecha;
  final Value<bool> cerrada;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<bool> pendiente;
  final Value<int> rowid;
  const PesasSesionesCompanion({
    this.id = const Value.absent(),
    this.lecheriaId = const Value.absent(),
    this.fecha = const Value.absent(),
    this.cerrada = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.pendiente = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PesasSesionesCompanion.insert({
    required String id,
    required String lecheriaId,
    required DateTime fecha,
    this.cerrada = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.pendiente = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       lecheriaId = Value(lecheriaId),
       fecha = Value(fecha),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<PesaSesionRow> custom({
    Expression<String>? id,
    Expression<String>? lecheriaId,
    Expression<DateTime>? fecha,
    Expression<bool>? cerrada,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<bool>? pendiente,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lecheriaId != null) 'lecheria_id': lecheriaId,
      if (fecha != null) 'fecha': fecha,
      if (cerrada != null) 'cerrada': cerrada,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (pendiente != null) 'pendiente': pendiente,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PesasSesionesCompanion copyWith({
    Value<String>? id,
    Value<String>? lecheriaId,
    Value<DateTime>? fecha,
    Value<bool>? cerrada,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<bool>? pendiente,
    Value<int>? rowid,
  }) {
    return PesasSesionesCompanion(
      id: id ?? this.id,
      lecheriaId: lecheriaId ?? this.lecheriaId,
      fecha: fecha ?? this.fecha,
      cerrada: cerrada ?? this.cerrada,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      pendiente: pendiente ?? this.pendiente,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (lecheriaId.present) {
      map['lecheria_id'] = Variable<String>(lecheriaId.value);
    }
    if (fecha.present) {
      map['fecha'] = Variable<DateTime>(fecha.value);
    }
    if (cerrada.present) {
      map['cerrada'] = Variable<bool>(cerrada.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (pendiente.present) {
      map['pendiente'] = Variable<bool>(pendiente.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PesasSesionesCompanion(')
          ..write('id: $id, ')
          ..write('lecheriaId: $lecheriaId, ')
          ..write('fecha: $fecha, ')
          ..write('cerrada: $cerrada, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('pendiente: $pendiente, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PesasLecheTable extends PesasLeche
    with TableInfo<$PesasLecheTable, PesaLecheRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PesasLecheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sesionIdMeta = const VerificationMeta(
    'sesionId',
  );
  @override
  late final GeneratedColumn<String> sesionId = GeneratedColumn<String>(
    'sesion_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _animalIdMeta = const VerificationMeta(
    'animalId',
  );
  @override
  late final GeneratedColumn<String> animalId = GeneratedColumn<String>(
    'animal_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _litrosMeta = const VerificationMeta('litros');
  @override
  late final GeneratedColumn<double> litros = GeneratedColumn<double>(
    'litros',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pendienteMeta = const VerificationMeta(
    'pendiente',
  );
  @override
  late final GeneratedColumn<bool> pendiente = GeneratedColumn<bool>(
    'pendiente',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pendiente" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sesionId,
    animalId,
    litros,
    createdAt,
    updatedAt,
    deletedAt,
    pendiente,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pesas_leche';
  @override
  VerificationContext validateIntegrity(
    Insertable<PesaLecheRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sesion_id')) {
      context.handle(
        _sesionIdMeta,
        sesionId.isAcceptableOrUnknown(data['sesion_id']!, _sesionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sesionIdMeta);
    }
    if (data.containsKey('animal_id')) {
      context.handle(
        _animalIdMeta,
        animalId.isAcceptableOrUnknown(data['animal_id']!, _animalIdMeta),
      );
    } else if (isInserting) {
      context.missing(_animalIdMeta);
    }
    if (data.containsKey('litros')) {
      context.handle(
        _litrosMeta,
        litros.isAcceptableOrUnknown(data['litros']!, _litrosMeta),
      );
    } else if (isInserting) {
      context.missing(_litrosMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('pendiente')) {
      context.handle(
        _pendienteMeta,
        pendiente.isAcceptableOrUnknown(data['pendiente']!, _pendienteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PesaLecheRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PesaLecheRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sesionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sesion_id'],
      )!,
      animalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}animal_id'],
      )!,
      litros: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}litros'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      pendiente: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pendiente'],
      )!,
    );
  }

  @override
  $PesasLecheTable createAlias(String alias) {
    return $PesasLecheTable(attachedDatabase, alias);
  }
}

class PesaLecheRow extends DataClass implements Insertable<PesaLecheRow> {
  final String id;
  final String sesionId;
  final String animalId;
  final double litros;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool pendiente;
  const PesaLecheRow({
    required this.id,
    required this.sesionId,
    required this.animalId,
    required this.litros,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.pendiente,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sesion_id'] = Variable<String>(sesionId);
    map['animal_id'] = Variable<String>(animalId);
    map['litros'] = Variable<double>(litros);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['pendiente'] = Variable<bool>(pendiente);
    return map;
  }

  PesasLecheCompanion toCompanion(bool nullToAbsent) {
    return PesasLecheCompanion(
      id: Value(id),
      sesionId: Value(sesionId),
      animalId: Value(animalId),
      litros: Value(litros),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      pendiente: Value(pendiente),
    );
  }

  factory PesaLecheRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PesaLecheRow(
      id: serializer.fromJson<String>(json['id']),
      sesionId: serializer.fromJson<String>(json['sesionId']),
      animalId: serializer.fromJson<String>(json['animalId']),
      litros: serializer.fromJson<double>(json['litros']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      pendiente: serializer.fromJson<bool>(json['pendiente']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sesionId': serializer.toJson<String>(sesionId),
      'animalId': serializer.toJson<String>(animalId),
      'litros': serializer.toJson<double>(litros),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'pendiente': serializer.toJson<bool>(pendiente),
    };
  }

  PesaLecheRow copyWith({
    String? id,
    String? sesionId,
    String? animalId,
    double? litros,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    bool? pendiente,
  }) => PesaLecheRow(
    id: id ?? this.id,
    sesionId: sesionId ?? this.sesionId,
    animalId: animalId ?? this.animalId,
    litros: litros ?? this.litros,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    pendiente: pendiente ?? this.pendiente,
  );
  PesaLecheRow copyWithCompanion(PesasLecheCompanion data) {
    return PesaLecheRow(
      id: data.id.present ? data.id.value : this.id,
      sesionId: data.sesionId.present ? data.sesionId.value : this.sesionId,
      animalId: data.animalId.present ? data.animalId.value : this.animalId,
      litros: data.litros.present ? data.litros.value : this.litros,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      pendiente: data.pendiente.present ? data.pendiente.value : this.pendiente,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PesaLecheRow(')
          ..write('id: $id, ')
          ..write('sesionId: $sesionId, ')
          ..write('animalId: $animalId, ')
          ..write('litros: $litros, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('pendiente: $pendiente')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sesionId,
    animalId,
    litros,
    createdAt,
    updatedAt,
    deletedAt,
    pendiente,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PesaLecheRow &&
          other.id == this.id &&
          other.sesionId == this.sesionId &&
          other.animalId == this.animalId &&
          other.litros == this.litros &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.pendiente == this.pendiente);
}

class PesasLecheCompanion extends UpdateCompanion<PesaLecheRow> {
  final Value<String> id;
  final Value<String> sesionId;
  final Value<String> animalId;
  final Value<double> litros;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<bool> pendiente;
  final Value<int> rowid;
  const PesasLecheCompanion({
    this.id = const Value.absent(),
    this.sesionId = const Value.absent(),
    this.animalId = const Value.absent(),
    this.litros = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.pendiente = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PesasLecheCompanion.insert({
    required String id,
    required String sesionId,
    required String animalId,
    required double litros,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.pendiente = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sesionId = Value(sesionId),
       animalId = Value(animalId),
       litros = Value(litros),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<PesaLecheRow> custom({
    Expression<String>? id,
    Expression<String>? sesionId,
    Expression<String>? animalId,
    Expression<double>? litros,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<bool>? pendiente,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sesionId != null) 'sesion_id': sesionId,
      if (animalId != null) 'animal_id': animalId,
      if (litros != null) 'litros': litros,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (pendiente != null) 'pendiente': pendiente,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PesasLecheCompanion copyWith({
    Value<String>? id,
    Value<String>? sesionId,
    Value<String>? animalId,
    Value<double>? litros,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<bool>? pendiente,
    Value<int>? rowid,
  }) {
    return PesasLecheCompanion(
      id: id ?? this.id,
      sesionId: sesionId ?? this.sesionId,
      animalId: animalId ?? this.animalId,
      litros: litros ?? this.litros,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      pendiente: pendiente ?? this.pendiente,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sesionId.present) {
      map['sesion_id'] = Variable<String>(sesionId.value);
    }
    if (animalId.present) {
      map['animal_id'] = Variable<String>(animalId.value);
    }
    if (litros.present) {
      map['litros'] = Variable<double>(litros.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (pendiente.present) {
      map['pendiente'] = Variable<bool>(pendiente.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PesasLecheCompanion(')
          ..write('id: $id, ')
          ..write('sesionId: $sesionId, ')
          ..write('animalId: $animalId, ')
          ..write('litros: $litros, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('pendiente: $pendiente, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ParametrosPeriodoTable extends ParametrosPeriodo
    with TableInfo<$ParametrosPeriodoTable, ParametrosPeriodoRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ParametrosPeriodoTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lecheriaIdMeta = const VerificationMeta(
    'lecheriaId',
  );
  @override
  late final GeneratedColumn<String> lecheriaId = GeneratedColumn<String>(
    'lecheria_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _anioMeta = const VerificationMeta('anio');
  @override
  late final GeneratedColumn<int> anio = GeneratedColumn<int>(
    'anio',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mesMeta = const VerificationMeta('mes');
  @override
  late final GeneratedColumn<int> mes = GeneratedColumn<int>(
    'mes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _precioLitroMeta = const VerificationMeta(
    'precioLitro',
  );
  @override
  late final GeneratedColumn<double> precioLitro = GeneratedColumn<double>(
    'precio_litro',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _precioConcentradoKgMeta =
      const VerificationMeta('precioConcentradoKg');
  @override
  late final GeneratedColumn<double> precioConcentradoKg =
      GeneratedColumn<double>(
        'precio_concentrado_kg',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _umbralSecadoLitrosMeta =
      const VerificationMeta('umbralSecadoLitros');
  @override
  late final GeneratedColumn<double> umbralSecadoLitros =
      GeneratedColumn<double>(
        'umbral_secado_litros',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(8),
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pendienteMeta = const VerificationMeta(
    'pendiente',
  );
  @override
  late final GeneratedColumn<bool> pendiente = GeneratedColumn<bool>(
    'pendiente',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pendiente" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    lecheriaId,
    anio,
    mes,
    precioLitro,
    precioConcentradoKg,
    umbralSecadoLitros,
    createdAt,
    updatedAt,
    deletedAt,
    pendiente,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'parametros_periodo';
  @override
  VerificationContext validateIntegrity(
    Insertable<ParametrosPeriodoRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('lecheria_id')) {
      context.handle(
        _lecheriaIdMeta,
        lecheriaId.isAcceptableOrUnknown(data['lecheria_id']!, _lecheriaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_lecheriaIdMeta);
    }
    if (data.containsKey('anio')) {
      context.handle(
        _anioMeta,
        anio.isAcceptableOrUnknown(data['anio']!, _anioMeta),
      );
    } else if (isInserting) {
      context.missing(_anioMeta);
    }
    if (data.containsKey('mes')) {
      context.handle(
        _mesMeta,
        mes.isAcceptableOrUnknown(data['mes']!, _mesMeta),
      );
    } else if (isInserting) {
      context.missing(_mesMeta);
    }
    if (data.containsKey('precio_litro')) {
      context.handle(
        _precioLitroMeta,
        precioLitro.isAcceptableOrUnknown(
          data['precio_litro']!,
          _precioLitroMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_precioLitroMeta);
    }
    if (data.containsKey('precio_concentrado_kg')) {
      context.handle(
        _precioConcentradoKgMeta,
        precioConcentradoKg.isAcceptableOrUnknown(
          data['precio_concentrado_kg']!,
          _precioConcentradoKgMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_precioConcentradoKgMeta);
    }
    if (data.containsKey('umbral_secado_litros')) {
      context.handle(
        _umbralSecadoLitrosMeta,
        umbralSecadoLitros.isAcceptableOrUnknown(
          data['umbral_secado_litros']!,
          _umbralSecadoLitrosMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('pendiente')) {
      context.handle(
        _pendienteMeta,
        pendiente.isAcceptableOrUnknown(data['pendiente']!, _pendienteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ParametrosPeriodoRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ParametrosPeriodoRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      lecheriaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lecheria_id'],
      )!,
      anio: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}anio'],
      )!,
      mes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mes'],
      )!,
      precioLitro: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}precio_litro'],
      )!,
      precioConcentradoKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}precio_concentrado_kg'],
      )!,
      umbralSecadoLitros: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}umbral_secado_litros'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      pendiente: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pendiente'],
      )!,
    );
  }

  @override
  $ParametrosPeriodoTable createAlias(String alias) {
    return $ParametrosPeriodoTable(attachedDatabase, alias);
  }
}

class ParametrosPeriodoRow extends DataClass
    implements Insertable<ParametrosPeriodoRow> {
  final String id;
  final String lecheriaId;
  final int anio;
  final int mes;
  final double precioLitro;
  final double precioConcentradoKg;
  final double umbralSecadoLitros;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool pendiente;
  const ParametrosPeriodoRow({
    required this.id,
    required this.lecheriaId,
    required this.anio,
    required this.mes,
    required this.precioLitro,
    required this.precioConcentradoKg,
    required this.umbralSecadoLitros,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.pendiente,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['lecheria_id'] = Variable<String>(lecheriaId);
    map['anio'] = Variable<int>(anio);
    map['mes'] = Variable<int>(mes);
    map['precio_litro'] = Variable<double>(precioLitro);
    map['precio_concentrado_kg'] = Variable<double>(precioConcentradoKg);
    map['umbral_secado_litros'] = Variable<double>(umbralSecadoLitros);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['pendiente'] = Variable<bool>(pendiente);
    return map;
  }

  ParametrosPeriodoCompanion toCompanion(bool nullToAbsent) {
    return ParametrosPeriodoCompanion(
      id: Value(id),
      lecheriaId: Value(lecheriaId),
      anio: Value(anio),
      mes: Value(mes),
      precioLitro: Value(precioLitro),
      precioConcentradoKg: Value(precioConcentradoKg),
      umbralSecadoLitros: Value(umbralSecadoLitros),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      pendiente: Value(pendiente),
    );
  }

  factory ParametrosPeriodoRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ParametrosPeriodoRow(
      id: serializer.fromJson<String>(json['id']),
      lecheriaId: serializer.fromJson<String>(json['lecheriaId']),
      anio: serializer.fromJson<int>(json['anio']),
      mes: serializer.fromJson<int>(json['mes']),
      precioLitro: serializer.fromJson<double>(json['precioLitro']),
      precioConcentradoKg: serializer.fromJson<double>(
        json['precioConcentradoKg'],
      ),
      umbralSecadoLitros: serializer.fromJson<double>(
        json['umbralSecadoLitros'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      pendiente: serializer.fromJson<bool>(json['pendiente']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'lecheriaId': serializer.toJson<String>(lecheriaId),
      'anio': serializer.toJson<int>(anio),
      'mes': serializer.toJson<int>(mes),
      'precioLitro': serializer.toJson<double>(precioLitro),
      'precioConcentradoKg': serializer.toJson<double>(precioConcentradoKg),
      'umbralSecadoLitros': serializer.toJson<double>(umbralSecadoLitros),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'pendiente': serializer.toJson<bool>(pendiente),
    };
  }

  ParametrosPeriodoRow copyWith({
    String? id,
    String? lecheriaId,
    int? anio,
    int? mes,
    double? precioLitro,
    double? precioConcentradoKg,
    double? umbralSecadoLitros,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    bool? pendiente,
  }) => ParametrosPeriodoRow(
    id: id ?? this.id,
    lecheriaId: lecheriaId ?? this.lecheriaId,
    anio: anio ?? this.anio,
    mes: mes ?? this.mes,
    precioLitro: precioLitro ?? this.precioLitro,
    precioConcentradoKg: precioConcentradoKg ?? this.precioConcentradoKg,
    umbralSecadoLitros: umbralSecadoLitros ?? this.umbralSecadoLitros,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    pendiente: pendiente ?? this.pendiente,
  );
  ParametrosPeriodoRow copyWithCompanion(ParametrosPeriodoCompanion data) {
    return ParametrosPeriodoRow(
      id: data.id.present ? data.id.value : this.id,
      lecheriaId: data.lecheriaId.present
          ? data.lecheriaId.value
          : this.lecheriaId,
      anio: data.anio.present ? data.anio.value : this.anio,
      mes: data.mes.present ? data.mes.value : this.mes,
      precioLitro: data.precioLitro.present
          ? data.precioLitro.value
          : this.precioLitro,
      precioConcentradoKg: data.precioConcentradoKg.present
          ? data.precioConcentradoKg.value
          : this.precioConcentradoKg,
      umbralSecadoLitros: data.umbralSecadoLitros.present
          ? data.umbralSecadoLitros.value
          : this.umbralSecadoLitros,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      pendiente: data.pendiente.present ? data.pendiente.value : this.pendiente,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ParametrosPeriodoRow(')
          ..write('id: $id, ')
          ..write('lecheriaId: $lecheriaId, ')
          ..write('anio: $anio, ')
          ..write('mes: $mes, ')
          ..write('precioLitro: $precioLitro, ')
          ..write('precioConcentradoKg: $precioConcentradoKg, ')
          ..write('umbralSecadoLitros: $umbralSecadoLitros, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('pendiente: $pendiente')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    lecheriaId,
    anio,
    mes,
    precioLitro,
    precioConcentradoKg,
    umbralSecadoLitros,
    createdAt,
    updatedAt,
    deletedAt,
    pendiente,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ParametrosPeriodoRow &&
          other.id == this.id &&
          other.lecheriaId == this.lecheriaId &&
          other.anio == this.anio &&
          other.mes == this.mes &&
          other.precioLitro == this.precioLitro &&
          other.precioConcentradoKg == this.precioConcentradoKg &&
          other.umbralSecadoLitros == this.umbralSecadoLitros &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.pendiente == this.pendiente);
}

class ParametrosPeriodoCompanion extends UpdateCompanion<ParametrosPeriodoRow> {
  final Value<String> id;
  final Value<String> lecheriaId;
  final Value<int> anio;
  final Value<int> mes;
  final Value<double> precioLitro;
  final Value<double> precioConcentradoKg;
  final Value<double> umbralSecadoLitros;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<bool> pendiente;
  final Value<int> rowid;
  const ParametrosPeriodoCompanion({
    this.id = const Value.absent(),
    this.lecheriaId = const Value.absent(),
    this.anio = const Value.absent(),
    this.mes = const Value.absent(),
    this.precioLitro = const Value.absent(),
    this.precioConcentradoKg = const Value.absent(),
    this.umbralSecadoLitros = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.pendiente = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ParametrosPeriodoCompanion.insert({
    required String id,
    required String lecheriaId,
    required int anio,
    required int mes,
    required double precioLitro,
    required double precioConcentradoKg,
    this.umbralSecadoLitros = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.pendiente = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       lecheriaId = Value(lecheriaId),
       anio = Value(anio),
       mes = Value(mes),
       precioLitro = Value(precioLitro),
       precioConcentradoKg = Value(precioConcentradoKg),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ParametrosPeriodoRow> custom({
    Expression<String>? id,
    Expression<String>? lecheriaId,
    Expression<int>? anio,
    Expression<int>? mes,
    Expression<double>? precioLitro,
    Expression<double>? precioConcentradoKg,
    Expression<double>? umbralSecadoLitros,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<bool>? pendiente,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lecheriaId != null) 'lecheria_id': lecheriaId,
      if (anio != null) 'anio': anio,
      if (mes != null) 'mes': mes,
      if (precioLitro != null) 'precio_litro': precioLitro,
      if (precioConcentradoKg != null)
        'precio_concentrado_kg': precioConcentradoKg,
      if (umbralSecadoLitros != null)
        'umbral_secado_litros': umbralSecadoLitros,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (pendiente != null) 'pendiente': pendiente,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ParametrosPeriodoCompanion copyWith({
    Value<String>? id,
    Value<String>? lecheriaId,
    Value<int>? anio,
    Value<int>? mes,
    Value<double>? precioLitro,
    Value<double>? precioConcentradoKg,
    Value<double>? umbralSecadoLitros,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<bool>? pendiente,
    Value<int>? rowid,
  }) {
    return ParametrosPeriodoCompanion(
      id: id ?? this.id,
      lecheriaId: lecheriaId ?? this.lecheriaId,
      anio: anio ?? this.anio,
      mes: mes ?? this.mes,
      precioLitro: precioLitro ?? this.precioLitro,
      precioConcentradoKg: precioConcentradoKg ?? this.precioConcentradoKg,
      umbralSecadoLitros: umbralSecadoLitros ?? this.umbralSecadoLitros,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      pendiente: pendiente ?? this.pendiente,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (lecheriaId.present) {
      map['lecheria_id'] = Variable<String>(lecheriaId.value);
    }
    if (anio.present) {
      map['anio'] = Variable<int>(anio.value);
    }
    if (mes.present) {
      map['mes'] = Variable<int>(mes.value);
    }
    if (precioLitro.present) {
      map['precio_litro'] = Variable<double>(precioLitro.value);
    }
    if (precioConcentradoKg.present) {
      map['precio_concentrado_kg'] = Variable<double>(
        precioConcentradoKg.value,
      );
    }
    if (umbralSecadoLitros.present) {
      map['umbral_secado_litros'] = Variable<double>(umbralSecadoLitros.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (pendiente.present) {
      map['pendiente'] = Variable<bool>(pendiente.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ParametrosPeriodoCompanion(')
          ..write('id: $id, ')
          ..write('lecheriaId: $lecheriaId, ')
          ..write('anio: $anio, ')
          ..write('mes: $mes, ')
          ..write('precioLitro: $precioLitro, ')
          ..write('precioConcentradoKg: $precioConcentradoKg, ')
          ..write('umbralSecadoLitros: $umbralSecadoLitros, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('pendiente: $pendiente, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CostosFijosTable extends CostosFijos
    with TableInfo<$CostosFijosTable, CostoFijoRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CostosFijosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lecheriaIdMeta = const VerificationMeta(
    'lecheriaId',
  );
  @override
  late final GeneratedColumn<String> lecheriaId = GeneratedColumn<String>(
    'lecheria_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _periodoIdMeta = const VerificationMeta(
    'periodoId',
  );
  @override
  late final GeneratedColumn<String> periodoId = GeneratedColumn<String>(
    'periodo_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoriaMeta = const VerificationMeta(
    'categoria',
  );
  @override
  late final GeneratedColumn<String> categoria = GeneratedColumn<String>(
    'categoria',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _montoMeta = const VerificationMeta('monto');
  @override
  late final GeneratedColumn<double> monto = GeneratedColumn<double>(
    'monto',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pendienteMeta = const VerificationMeta(
    'pendiente',
  );
  @override
  late final GeneratedColumn<bool> pendiente = GeneratedColumn<bool>(
    'pendiente',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pendiente" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    lecheriaId,
    periodoId,
    categoria,
    monto,
    createdAt,
    updatedAt,
    deletedAt,
    pendiente,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'costos_fijos';
  @override
  VerificationContext validateIntegrity(
    Insertable<CostoFijoRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('lecheria_id')) {
      context.handle(
        _lecheriaIdMeta,
        lecheriaId.isAcceptableOrUnknown(data['lecheria_id']!, _lecheriaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_lecheriaIdMeta);
    }
    if (data.containsKey('periodo_id')) {
      context.handle(
        _periodoIdMeta,
        periodoId.isAcceptableOrUnknown(data['periodo_id']!, _periodoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_periodoIdMeta);
    }
    if (data.containsKey('categoria')) {
      context.handle(
        _categoriaMeta,
        categoria.isAcceptableOrUnknown(data['categoria']!, _categoriaMeta),
      );
    } else if (isInserting) {
      context.missing(_categoriaMeta);
    }
    if (data.containsKey('monto')) {
      context.handle(
        _montoMeta,
        monto.isAcceptableOrUnknown(data['monto']!, _montoMeta),
      );
    } else if (isInserting) {
      context.missing(_montoMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('pendiente')) {
      context.handle(
        _pendienteMeta,
        pendiente.isAcceptableOrUnknown(data['pendiente']!, _pendienteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CostoFijoRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CostoFijoRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      lecheriaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lecheria_id'],
      )!,
      periodoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}periodo_id'],
      )!,
      categoria: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}categoria'],
      )!,
      monto: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}monto'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      pendiente: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pendiente'],
      )!,
    );
  }

  @override
  $CostosFijosTable createAlias(String alias) {
    return $CostosFijosTable(attachedDatabase, alias);
  }
}

class CostoFijoRow extends DataClass implements Insertable<CostoFijoRow> {
  final String id;
  final String lecheriaId;
  final String periodoId;
  final String categoria;
  final double monto;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool pendiente;
  const CostoFijoRow({
    required this.id,
    required this.lecheriaId,
    required this.periodoId,
    required this.categoria,
    required this.monto,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.pendiente,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['lecheria_id'] = Variable<String>(lecheriaId);
    map['periodo_id'] = Variable<String>(periodoId);
    map['categoria'] = Variable<String>(categoria);
    map['monto'] = Variable<double>(monto);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['pendiente'] = Variable<bool>(pendiente);
    return map;
  }

  CostosFijosCompanion toCompanion(bool nullToAbsent) {
    return CostosFijosCompanion(
      id: Value(id),
      lecheriaId: Value(lecheriaId),
      periodoId: Value(periodoId),
      categoria: Value(categoria),
      monto: Value(monto),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      pendiente: Value(pendiente),
    );
  }

  factory CostoFijoRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CostoFijoRow(
      id: serializer.fromJson<String>(json['id']),
      lecheriaId: serializer.fromJson<String>(json['lecheriaId']),
      periodoId: serializer.fromJson<String>(json['periodoId']),
      categoria: serializer.fromJson<String>(json['categoria']),
      monto: serializer.fromJson<double>(json['monto']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      pendiente: serializer.fromJson<bool>(json['pendiente']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'lecheriaId': serializer.toJson<String>(lecheriaId),
      'periodoId': serializer.toJson<String>(periodoId),
      'categoria': serializer.toJson<String>(categoria),
      'monto': serializer.toJson<double>(monto),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'pendiente': serializer.toJson<bool>(pendiente),
    };
  }

  CostoFijoRow copyWith({
    String? id,
    String? lecheriaId,
    String? periodoId,
    String? categoria,
    double? monto,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    bool? pendiente,
  }) => CostoFijoRow(
    id: id ?? this.id,
    lecheriaId: lecheriaId ?? this.lecheriaId,
    periodoId: periodoId ?? this.periodoId,
    categoria: categoria ?? this.categoria,
    monto: monto ?? this.monto,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    pendiente: pendiente ?? this.pendiente,
  );
  CostoFijoRow copyWithCompanion(CostosFijosCompanion data) {
    return CostoFijoRow(
      id: data.id.present ? data.id.value : this.id,
      lecheriaId: data.lecheriaId.present
          ? data.lecheriaId.value
          : this.lecheriaId,
      periodoId: data.periodoId.present ? data.periodoId.value : this.periodoId,
      categoria: data.categoria.present ? data.categoria.value : this.categoria,
      monto: data.monto.present ? data.monto.value : this.monto,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      pendiente: data.pendiente.present ? data.pendiente.value : this.pendiente,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CostoFijoRow(')
          ..write('id: $id, ')
          ..write('lecheriaId: $lecheriaId, ')
          ..write('periodoId: $periodoId, ')
          ..write('categoria: $categoria, ')
          ..write('monto: $monto, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('pendiente: $pendiente')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    lecheriaId,
    periodoId,
    categoria,
    monto,
    createdAt,
    updatedAt,
    deletedAt,
    pendiente,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CostoFijoRow &&
          other.id == this.id &&
          other.lecheriaId == this.lecheriaId &&
          other.periodoId == this.periodoId &&
          other.categoria == this.categoria &&
          other.monto == this.monto &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.pendiente == this.pendiente);
}

class CostosFijosCompanion extends UpdateCompanion<CostoFijoRow> {
  final Value<String> id;
  final Value<String> lecheriaId;
  final Value<String> periodoId;
  final Value<String> categoria;
  final Value<double> monto;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<bool> pendiente;
  final Value<int> rowid;
  const CostosFijosCompanion({
    this.id = const Value.absent(),
    this.lecheriaId = const Value.absent(),
    this.periodoId = const Value.absent(),
    this.categoria = const Value.absent(),
    this.monto = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.pendiente = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CostosFijosCompanion.insert({
    required String id,
    required String lecheriaId,
    required String periodoId,
    required String categoria,
    required double monto,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.pendiente = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       lecheriaId = Value(lecheriaId),
       periodoId = Value(periodoId),
       categoria = Value(categoria),
       monto = Value(monto),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CostoFijoRow> custom({
    Expression<String>? id,
    Expression<String>? lecheriaId,
    Expression<String>? periodoId,
    Expression<String>? categoria,
    Expression<double>? monto,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<bool>? pendiente,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lecheriaId != null) 'lecheria_id': lecheriaId,
      if (periodoId != null) 'periodo_id': periodoId,
      if (categoria != null) 'categoria': categoria,
      if (monto != null) 'monto': monto,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (pendiente != null) 'pendiente': pendiente,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CostosFijosCompanion copyWith({
    Value<String>? id,
    Value<String>? lecheriaId,
    Value<String>? periodoId,
    Value<String>? categoria,
    Value<double>? monto,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<bool>? pendiente,
    Value<int>? rowid,
  }) {
    return CostosFijosCompanion(
      id: id ?? this.id,
      lecheriaId: lecheriaId ?? this.lecheriaId,
      periodoId: periodoId ?? this.periodoId,
      categoria: categoria ?? this.categoria,
      monto: monto ?? this.monto,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      pendiente: pendiente ?? this.pendiente,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (lecheriaId.present) {
      map['lecheria_id'] = Variable<String>(lecheriaId.value);
    }
    if (periodoId.present) {
      map['periodo_id'] = Variable<String>(periodoId.value);
    }
    if (categoria.present) {
      map['categoria'] = Variable<String>(categoria.value);
    }
    if (monto.present) {
      map['monto'] = Variable<double>(monto.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (pendiente.present) {
      map['pendiente'] = Variable<bool>(pendiente.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CostosFijosCompanion(')
          ..write('id: $id, ')
          ..write('lecheriaId: $lecheriaId, ')
          ..write('periodoId: $periodoId, ')
          ..write('categoria: $categoria, ')
          ..write('monto: $monto, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('pendiente: $pendiente, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MedicamentosTable extends Medicamentos
    with TableInfo<$MedicamentosTable, MedicamentoRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MedicamentosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lecheriaIdMeta = const VerificationMeta(
    'lecheriaId',
  );
  @override
  late final GeneratedColumn<String> lecheriaId = GeneratedColumn<String>(
    'lecheria_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _costoEnvaseMeta = const VerificationMeta(
    'costoEnvase',
  );
  @override
  late final GeneratedColumn<double> costoEnvase = GeneratedColumn<double>(
    'costo_envase',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tipoDosisMeta = const VerificationMeta(
    'tipoDosis',
  );
  @override
  late final GeneratedColumn<String> tipoDosis = GeneratedColumn<String>(
    'tipo_dosis',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mlEnvaseMeta = const VerificationMeta(
    'mlEnvase',
  );
  @override
  late final GeneratedColumn<double> mlEnvase = GeneratedColumn<double>(
    'ml_envase',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _aplicacionesEnvaseMeta =
      const VerificationMeta('aplicacionesEnvase');
  @override
  late final GeneratedColumn<double> aplicacionesEnvase =
      GeneratedColumn<double>(
        'aplicaciones_envase',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _dosisFijaMlMeta = const VerificationMeta(
    'dosisFijaMl',
  );
  @override
  late final GeneratedColumn<double> dosisFijaMl = GeneratedColumn<double>(
    'dosis_fija_ml',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _diasRetiroLecheMeta = const VerificationMeta(
    'diasRetiroLeche',
  );
  @override
  late final GeneratedColumn<int> diasRetiroLeche = GeneratedColumn<int>(
    'dias_retiro_leche',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pendienteMeta = const VerificationMeta(
    'pendiente',
  );
  @override
  late final GeneratedColumn<bool> pendiente = GeneratedColumn<bool>(
    'pendiente',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pendiente" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    lecheriaId,
    nombre,
    costoEnvase,
    tipoDosis,
    mlEnvase,
    aplicacionesEnvase,
    dosisFijaMl,
    diasRetiroLeche,
    createdAt,
    updatedAt,
    deletedAt,
    pendiente,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'medicamentos';
  @override
  VerificationContext validateIntegrity(
    Insertable<MedicamentoRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('lecheria_id')) {
      context.handle(
        _lecheriaIdMeta,
        lecheriaId.isAcceptableOrUnknown(data['lecheria_id']!, _lecheriaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_lecheriaIdMeta);
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('costo_envase')) {
      context.handle(
        _costoEnvaseMeta,
        costoEnvase.isAcceptableOrUnknown(
          data['costo_envase']!,
          _costoEnvaseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_costoEnvaseMeta);
    }
    if (data.containsKey('tipo_dosis')) {
      context.handle(
        _tipoDosisMeta,
        tipoDosis.isAcceptableOrUnknown(data['tipo_dosis']!, _tipoDosisMeta),
      );
    } else if (isInserting) {
      context.missing(_tipoDosisMeta);
    }
    if (data.containsKey('ml_envase')) {
      context.handle(
        _mlEnvaseMeta,
        mlEnvase.isAcceptableOrUnknown(data['ml_envase']!, _mlEnvaseMeta),
      );
    }
    if (data.containsKey('aplicaciones_envase')) {
      context.handle(
        _aplicacionesEnvaseMeta,
        aplicacionesEnvase.isAcceptableOrUnknown(
          data['aplicaciones_envase']!,
          _aplicacionesEnvaseMeta,
        ),
      );
    }
    if (data.containsKey('dosis_fija_ml')) {
      context.handle(
        _dosisFijaMlMeta,
        dosisFijaMl.isAcceptableOrUnknown(
          data['dosis_fija_ml']!,
          _dosisFijaMlMeta,
        ),
      );
    }
    if (data.containsKey('dias_retiro_leche')) {
      context.handle(
        _diasRetiroLecheMeta,
        diasRetiroLeche.isAcceptableOrUnknown(
          data['dias_retiro_leche']!,
          _diasRetiroLecheMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('pendiente')) {
      context.handle(
        _pendienteMeta,
        pendiente.isAcceptableOrUnknown(data['pendiente']!, _pendienteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MedicamentoRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MedicamentoRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      lecheriaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lecheria_id'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      costoEnvase: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}costo_envase'],
      )!,
      tipoDosis: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo_dosis'],
      )!,
      mlEnvase: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ml_envase'],
      ),
      aplicacionesEnvase: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}aplicaciones_envase'],
      ),
      dosisFijaMl: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}dosis_fija_ml'],
      ),
      diasRetiroLeche: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dias_retiro_leche'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      pendiente: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pendiente'],
      )!,
    );
  }

  @override
  $MedicamentosTable createAlias(String alias) {
    return $MedicamentosTable(attachedDatabase, alias);
  }
}

class MedicamentoRow extends DataClass implements Insertable<MedicamentoRow> {
  final String id;
  final String lecheriaId;
  final String nombre;
  final double costoEnvase;
  final String tipoDosis;
  final double? mlEnvase;
  final double? aplicacionesEnvase;
  final double? dosisFijaMl;
  final int diasRetiroLeche;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool pendiente;
  const MedicamentoRow({
    required this.id,
    required this.lecheriaId,
    required this.nombre,
    required this.costoEnvase,
    required this.tipoDosis,
    this.mlEnvase,
    this.aplicacionesEnvase,
    this.dosisFijaMl,
    required this.diasRetiroLeche,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.pendiente,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['lecheria_id'] = Variable<String>(lecheriaId);
    map['nombre'] = Variable<String>(nombre);
    map['costo_envase'] = Variable<double>(costoEnvase);
    map['tipo_dosis'] = Variable<String>(tipoDosis);
    if (!nullToAbsent || mlEnvase != null) {
      map['ml_envase'] = Variable<double>(mlEnvase);
    }
    if (!nullToAbsent || aplicacionesEnvase != null) {
      map['aplicaciones_envase'] = Variable<double>(aplicacionesEnvase);
    }
    if (!nullToAbsent || dosisFijaMl != null) {
      map['dosis_fija_ml'] = Variable<double>(dosisFijaMl);
    }
    map['dias_retiro_leche'] = Variable<int>(diasRetiroLeche);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['pendiente'] = Variable<bool>(pendiente);
    return map;
  }

  MedicamentosCompanion toCompanion(bool nullToAbsent) {
    return MedicamentosCompanion(
      id: Value(id),
      lecheriaId: Value(lecheriaId),
      nombre: Value(nombre),
      costoEnvase: Value(costoEnvase),
      tipoDosis: Value(tipoDosis),
      mlEnvase: mlEnvase == null && nullToAbsent
          ? const Value.absent()
          : Value(mlEnvase),
      aplicacionesEnvase: aplicacionesEnvase == null && nullToAbsent
          ? const Value.absent()
          : Value(aplicacionesEnvase),
      dosisFijaMl: dosisFijaMl == null && nullToAbsent
          ? const Value.absent()
          : Value(dosisFijaMl),
      diasRetiroLeche: Value(diasRetiroLeche),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      pendiente: Value(pendiente),
    );
  }

  factory MedicamentoRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MedicamentoRow(
      id: serializer.fromJson<String>(json['id']),
      lecheriaId: serializer.fromJson<String>(json['lecheriaId']),
      nombre: serializer.fromJson<String>(json['nombre']),
      costoEnvase: serializer.fromJson<double>(json['costoEnvase']),
      tipoDosis: serializer.fromJson<String>(json['tipoDosis']),
      mlEnvase: serializer.fromJson<double?>(json['mlEnvase']),
      aplicacionesEnvase: serializer.fromJson<double?>(
        json['aplicacionesEnvase'],
      ),
      dosisFijaMl: serializer.fromJson<double?>(json['dosisFijaMl']),
      diasRetiroLeche: serializer.fromJson<int>(json['diasRetiroLeche']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      pendiente: serializer.fromJson<bool>(json['pendiente']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'lecheriaId': serializer.toJson<String>(lecheriaId),
      'nombre': serializer.toJson<String>(nombre),
      'costoEnvase': serializer.toJson<double>(costoEnvase),
      'tipoDosis': serializer.toJson<String>(tipoDosis),
      'mlEnvase': serializer.toJson<double?>(mlEnvase),
      'aplicacionesEnvase': serializer.toJson<double?>(aplicacionesEnvase),
      'dosisFijaMl': serializer.toJson<double?>(dosisFijaMl),
      'diasRetiroLeche': serializer.toJson<int>(diasRetiroLeche),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'pendiente': serializer.toJson<bool>(pendiente),
    };
  }

  MedicamentoRow copyWith({
    String? id,
    String? lecheriaId,
    String? nombre,
    double? costoEnvase,
    String? tipoDosis,
    Value<double?> mlEnvase = const Value.absent(),
    Value<double?> aplicacionesEnvase = const Value.absent(),
    Value<double?> dosisFijaMl = const Value.absent(),
    int? diasRetiroLeche,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    bool? pendiente,
  }) => MedicamentoRow(
    id: id ?? this.id,
    lecheriaId: lecheriaId ?? this.lecheriaId,
    nombre: nombre ?? this.nombre,
    costoEnvase: costoEnvase ?? this.costoEnvase,
    tipoDosis: tipoDosis ?? this.tipoDosis,
    mlEnvase: mlEnvase.present ? mlEnvase.value : this.mlEnvase,
    aplicacionesEnvase: aplicacionesEnvase.present
        ? aplicacionesEnvase.value
        : this.aplicacionesEnvase,
    dosisFijaMl: dosisFijaMl.present ? dosisFijaMl.value : this.dosisFijaMl,
    diasRetiroLeche: diasRetiroLeche ?? this.diasRetiroLeche,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    pendiente: pendiente ?? this.pendiente,
  );
  MedicamentoRow copyWithCompanion(MedicamentosCompanion data) {
    return MedicamentoRow(
      id: data.id.present ? data.id.value : this.id,
      lecheriaId: data.lecheriaId.present
          ? data.lecheriaId.value
          : this.lecheriaId,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      costoEnvase: data.costoEnvase.present
          ? data.costoEnvase.value
          : this.costoEnvase,
      tipoDosis: data.tipoDosis.present ? data.tipoDosis.value : this.tipoDosis,
      mlEnvase: data.mlEnvase.present ? data.mlEnvase.value : this.mlEnvase,
      aplicacionesEnvase: data.aplicacionesEnvase.present
          ? data.aplicacionesEnvase.value
          : this.aplicacionesEnvase,
      dosisFijaMl: data.dosisFijaMl.present
          ? data.dosisFijaMl.value
          : this.dosisFijaMl,
      diasRetiroLeche: data.diasRetiroLeche.present
          ? data.diasRetiroLeche.value
          : this.diasRetiroLeche,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      pendiente: data.pendiente.present ? data.pendiente.value : this.pendiente,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MedicamentoRow(')
          ..write('id: $id, ')
          ..write('lecheriaId: $lecheriaId, ')
          ..write('nombre: $nombre, ')
          ..write('costoEnvase: $costoEnvase, ')
          ..write('tipoDosis: $tipoDosis, ')
          ..write('mlEnvase: $mlEnvase, ')
          ..write('aplicacionesEnvase: $aplicacionesEnvase, ')
          ..write('dosisFijaMl: $dosisFijaMl, ')
          ..write('diasRetiroLeche: $diasRetiroLeche, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('pendiente: $pendiente')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    lecheriaId,
    nombre,
    costoEnvase,
    tipoDosis,
    mlEnvase,
    aplicacionesEnvase,
    dosisFijaMl,
    diasRetiroLeche,
    createdAt,
    updatedAt,
    deletedAt,
    pendiente,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MedicamentoRow &&
          other.id == this.id &&
          other.lecheriaId == this.lecheriaId &&
          other.nombre == this.nombre &&
          other.costoEnvase == this.costoEnvase &&
          other.tipoDosis == this.tipoDosis &&
          other.mlEnvase == this.mlEnvase &&
          other.aplicacionesEnvase == this.aplicacionesEnvase &&
          other.dosisFijaMl == this.dosisFijaMl &&
          other.diasRetiroLeche == this.diasRetiroLeche &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.pendiente == this.pendiente);
}

class MedicamentosCompanion extends UpdateCompanion<MedicamentoRow> {
  final Value<String> id;
  final Value<String> lecheriaId;
  final Value<String> nombre;
  final Value<double> costoEnvase;
  final Value<String> tipoDosis;
  final Value<double?> mlEnvase;
  final Value<double?> aplicacionesEnvase;
  final Value<double?> dosisFijaMl;
  final Value<int> diasRetiroLeche;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<bool> pendiente;
  final Value<int> rowid;
  const MedicamentosCompanion({
    this.id = const Value.absent(),
    this.lecheriaId = const Value.absent(),
    this.nombre = const Value.absent(),
    this.costoEnvase = const Value.absent(),
    this.tipoDosis = const Value.absent(),
    this.mlEnvase = const Value.absent(),
    this.aplicacionesEnvase = const Value.absent(),
    this.dosisFijaMl = const Value.absent(),
    this.diasRetiroLeche = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.pendiente = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MedicamentosCompanion.insert({
    required String id,
    required String lecheriaId,
    required String nombre,
    required double costoEnvase,
    required String tipoDosis,
    this.mlEnvase = const Value.absent(),
    this.aplicacionesEnvase = const Value.absent(),
    this.dosisFijaMl = const Value.absent(),
    this.diasRetiroLeche = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.pendiente = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       lecheriaId = Value(lecheriaId),
       nombre = Value(nombre),
       costoEnvase = Value(costoEnvase),
       tipoDosis = Value(tipoDosis),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<MedicamentoRow> custom({
    Expression<String>? id,
    Expression<String>? lecheriaId,
    Expression<String>? nombre,
    Expression<double>? costoEnvase,
    Expression<String>? tipoDosis,
    Expression<double>? mlEnvase,
    Expression<double>? aplicacionesEnvase,
    Expression<double>? dosisFijaMl,
    Expression<int>? diasRetiroLeche,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<bool>? pendiente,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lecheriaId != null) 'lecheria_id': lecheriaId,
      if (nombre != null) 'nombre': nombre,
      if (costoEnvase != null) 'costo_envase': costoEnvase,
      if (tipoDosis != null) 'tipo_dosis': tipoDosis,
      if (mlEnvase != null) 'ml_envase': mlEnvase,
      if (aplicacionesEnvase != null) 'aplicaciones_envase': aplicacionesEnvase,
      if (dosisFijaMl != null) 'dosis_fija_ml': dosisFijaMl,
      if (diasRetiroLeche != null) 'dias_retiro_leche': diasRetiroLeche,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (pendiente != null) 'pendiente': pendiente,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MedicamentosCompanion copyWith({
    Value<String>? id,
    Value<String>? lecheriaId,
    Value<String>? nombre,
    Value<double>? costoEnvase,
    Value<String>? tipoDosis,
    Value<double?>? mlEnvase,
    Value<double?>? aplicacionesEnvase,
    Value<double?>? dosisFijaMl,
    Value<int>? diasRetiroLeche,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<bool>? pendiente,
    Value<int>? rowid,
  }) {
    return MedicamentosCompanion(
      id: id ?? this.id,
      lecheriaId: lecheriaId ?? this.lecheriaId,
      nombre: nombre ?? this.nombre,
      costoEnvase: costoEnvase ?? this.costoEnvase,
      tipoDosis: tipoDosis ?? this.tipoDosis,
      mlEnvase: mlEnvase ?? this.mlEnvase,
      aplicacionesEnvase: aplicacionesEnvase ?? this.aplicacionesEnvase,
      dosisFijaMl: dosisFijaMl ?? this.dosisFijaMl,
      diasRetiroLeche: diasRetiroLeche ?? this.diasRetiroLeche,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      pendiente: pendiente ?? this.pendiente,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (lecheriaId.present) {
      map['lecheria_id'] = Variable<String>(lecheriaId.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (costoEnvase.present) {
      map['costo_envase'] = Variable<double>(costoEnvase.value);
    }
    if (tipoDosis.present) {
      map['tipo_dosis'] = Variable<String>(tipoDosis.value);
    }
    if (mlEnvase.present) {
      map['ml_envase'] = Variable<double>(mlEnvase.value);
    }
    if (aplicacionesEnvase.present) {
      map['aplicaciones_envase'] = Variable<double>(aplicacionesEnvase.value);
    }
    if (dosisFijaMl.present) {
      map['dosis_fija_ml'] = Variable<double>(dosisFijaMl.value);
    }
    if (diasRetiroLeche.present) {
      map['dias_retiro_leche'] = Variable<int>(diasRetiroLeche.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (pendiente.present) {
      map['pendiente'] = Variable<bool>(pendiente.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MedicamentosCompanion(')
          ..write('id: $id, ')
          ..write('lecheriaId: $lecheriaId, ')
          ..write('nombre: $nombre, ')
          ..write('costoEnvase: $costoEnvase, ')
          ..write('tipoDosis: $tipoDosis, ')
          ..write('mlEnvase: $mlEnvase, ')
          ..write('aplicacionesEnvase: $aplicacionesEnvase, ')
          ..write('dosisFijaMl: $dosisFijaMl, ')
          ..write('diasRetiroLeche: $diasRetiroLeche, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('pendiente: $pendiente, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConfigAlertasTable extends ConfigAlertas
    with TableInfo<$ConfigAlertasTable, ConfigAlertaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConfigAlertasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lecheriaIdMeta = const VerificationMeta(
    'lecheriaId',
  );
  @override
  late final GeneratedColumn<String> lecheriaId = GeneratedColumn<String>(
    'lecheria_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _diasCeloEsperadoMeta = const VerificationMeta(
    'diasCeloEsperado',
  );
  @override
  late final GeneratedColumn<int> diasCeloEsperado = GeneratedColumn<int>(
    'dias_celo_esperado',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(21),
  );
  static const VerificationMeta _diasConfirmarPreniezMeta =
      const VerificationMeta('diasConfirmarPreniez');
  @override
  late final GeneratedColumn<int> diasConfirmarPreniez = GeneratedColumn<int>(
    'dias_confirmar_preniez',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(45),
  );
  static const VerificationMeta _diasVaciosAltosMeta = const VerificationMeta(
    'diasVaciosAltos',
  );
  @override
  late final GeneratedColumn<int> diasVaciosAltos = GeneratedColumn<int>(
    'dias_vacios_altos',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(150),
  );
  static const VerificationMeta _diasAntesSecarMeta = const VerificationMeta(
    'diasAntesSecar',
  );
  @override
  late final GeneratedColumn<int> diasAntesSecar = GeneratedColumn<int>(
    'dias_antes_secar',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(60),
  );
  static const VerificationMeta _diasAntesPartoMeta = const VerificationMeta(
    'diasAntesParto',
  );
  @override
  late final GeneratedColumn<int> diasAntesParto = GeneratedColumn<int>(
    'dias_antes_parto',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(14),
  );
  static const VerificationMeta _diasAvisoFinRetiroMeta =
      const VerificationMeta('diasAvisoFinRetiro');
  @override
  late final GeneratedColumn<int> diasAvisoFinRetiro = GeneratedColumn<int>(
    'dias_aviso_fin_retiro',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pendienteMeta = const VerificationMeta(
    'pendiente',
  );
  @override
  late final GeneratedColumn<bool> pendiente = GeneratedColumn<bool>(
    'pendiente',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pendiente" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    lecheriaId,
    diasCeloEsperado,
    diasConfirmarPreniez,
    diasVaciosAltos,
    diasAntesSecar,
    diasAntesParto,
    diasAvisoFinRetiro,
    createdAt,
    updatedAt,
    deletedAt,
    pendiente,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'config_alertas';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConfigAlertaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('lecheria_id')) {
      context.handle(
        _lecheriaIdMeta,
        lecheriaId.isAcceptableOrUnknown(data['lecheria_id']!, _lecheriaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_lecheriaIdMeta);
    }
    if (data.containsKey('dias_celo_esperado')) {
      context.handle(
        _diasCeloEsperadoMeta,
        diasCeloEsperado.isAcceptableOrUnknown(
          data['dias_celo_esperado']!,
          _diasCeloEsperadoMeta,
        ),
      );
    }
    if (data.containsKey('dias_confirmar_preniez')) {
      context.handle(
        _diasConfirmarPreniezMeta,
        diasConfirmarPreniez.isAcceptableOrUnknown(
          data['dias_confirmar_preniez']!,
          _diasConfirmarPreniezMeta,
        ),
      );
    }
    if (data.containsKey('dias_vacios_altos')) {
      context.handle(
        _diasVaciosAltosMeta,
        diasVaciosAltos.isAcceptableOrUnknown(
          data['dias_vacios_altos']!,
          _diasVaciosAltosMeta,
        ),
      );
    }
    if (data.containsKey('dias_antes_secar')) {
      context.handle(
        _diasAntesSecarMeta,
        diasAntesSecar.isAcceptableOrUnknown(
          data['dias_antes_secar']!,
          _diasAntesSecarMeta,
        ),
      );
    }
    if (data.containsKey('dias_antes_parto')) {
      context.handle(
        _diasAntesPartoMeta,
        diasAntesParto.isAcceptableOrUnknown(
          data['dias_antes_parto']!,
          _diasAntesPartoMeta,
        ),
      );
    }
    if (data.containsKey('dias_aviso_fin_retiro')) {
      context.handle(
        _diasAvisoFinRetiroMeta,
        diasAvisoFinRetiro.isAcceptableOrUnknown(
          data['dias_aviso_fin_retiro']!,
          _diasAvisoFinRetiroMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('pendiente')) {
      context.handle(
        _pendienteMeta,
        pendiente.isAcceptableOrUnknown(data['pendiente']!, _pendienteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConfigAlertaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConfigAlertaRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      lecheriaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lecheria_id'],
      )!,
      diasCeloEsperado: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dias_celo_esperado'],
      )!,
      diasConfirmarPreniez: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dias_confirmar_preniez'],
      )!,
      diasVaciosAltos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dias_vacios_altos'],
      )!,
      diasAntesSecar: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dias_antes_secar'],
      )!,
      diasAntesParto: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dias_antes_parto'],
      )!,
      diasAvisoFinRetiro: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dias_aviso_fin_retiro'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      pendiente: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pendiente'],
      )!,
    );
  }

  @override
  $ConfigAlertasTable createAlias(String alias) {
    return $ConfigAlertasTable(attachedDatabase, alias);
  }
}

class ConfigAlertaRow extends DataClass implements Insertable<ConfigAlertaRow> {
  final String id;
  final String lecheriaId;
  final int diasCeloEsperado;
  final int diasConfirmarPreniez;
  final int diasVaciosAltos;
  final int diasAntesSecar;
  final int diasAntesParto;
  final int diasAvisoFinRetiro;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool pendiente;
  const ConfigAlertaRow({
    required this.id,
    required this.lecheriaId,
    required this.diasCeloEsperado,
    required this.diasConfirmarPreniez,
    required this.diasVaciosAltos,
    required this.diasAntesSecar,
    required this.diasAntesParto,
    required this.diasAvisoFinRetiro,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.pendiente,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['lecheria_id'] = Variable<String>(lecheriaId);
    map['dias_celo_esperado'] = Variable<int>(diasCeloEsperado);
    map['dias_confirmar_preniez'] = Variable<int>(diasConfirmarPreniez);
    map['dias_vacios_altos'] = Variable<int>(diasVaciosAltos);
    map['dias_antes_secar'] = Variable<int>(diasAntesSecar);
    map['dias_antes_parto'] = Variable<int>(diasAntesParto);
    map['dias_aviso_fin_retiro'] = Variable<int>(diasAvisoFinRetiro);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['pendiente'] = Variable<bool>(pendiente);
    return map;
  }

  ConfigAlertasCompanion toCompanion(bool nullToAbsent) {
    return ConfigAlertasCompanion(
      id: Value(id),
      lecheriaId: Value(lecheriaId),
      diasCeloEsperado: Value(diasCeloEsperado),
      diasConfirmarPreniez: Value(diasConfirmarPreniez),
      diasVaciosAltos: Value(diasVaciosAltos),
      diasAntesSecar: Value(diasAntesSecar),
      diasAntesParto: Value(diasAntesParto),
      diasAvisoFinRetiro: Value(diasAvisoFinRetiro),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      pendiente: Value(pendiente),
    );
  }

  factory ConfigAlertaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConfigAlertaRow(
      id: serializer.fromJson<String>(json['id']),
      lecheriaId: serializer.fromJson<String>(json['lecheriaId']),
      diasCeloEsperado: serializer.fromJson<int>(json['diasCeloEsperado']),
      diasConfirmarPreniez: serializer.fromJson<int>(
        json['diasConfirmarPreniez'],
      ),
      diasVaciosAltos: serializer.fromJson<int>(json['diasVaciosAltos']),
      diasAntesSecar: serializer.fromJson<int>(json['diasAntesSecar']),
      diasAntesParto: serializer.fromJson<int>(json['diasAntesParto']),
      diasAvisoFinRetiro: serializer.fromJson<int>(json['diasAvisoFinRetiro']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      pendiente: serializer.fromJson<bool>(json['pendiente']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'lecheriaId': serializer.toJson<String>(lecheriaId),
      'diasCeloEsperado': serializer.toJson<int>(diasCeloEsperado),
      'diasConfirmarPreniez': serializer.toJson<int>(diasConfirmarPreniez),
      'diasVaciosAltos': serializer.toJson<int>(diasVaciosAltos),
      'diasAntesSecar': serializer.toJson<int>(diasAntesSecar),
      'diasAntesParto': serializer.toJson<int>(diasAntesParto),
      'diasAvisoFinRetiro': serializer.toJson<int>(diasAvisoFinRetiro),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'pendiente': serializer.toJson<bool>(pendiente),
    };
  }

  ConfigAlertaRow copyWith({
    String? id,
    String? lecheriaId,
    int? diasCeloEsperado,
    int? diasConfirmarPreniez,
    int? diasVaciosAltos,
    int? diasAntesSecar,
    int? diasAntesParto,
    int? diasAvisoFinRetiro,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    bool? pendiente,
  }) => ConfigAlertaRow(
    id: id ?? this.id,
    lecheriaId: lecheriaId ?? this.lecheriaId,
    diasCeloEsperado: diasCeloEsperado ?? this.diasCeloEsperado,
    diasConfirmarPreniez: diasConfirmarPreniez ?? this.diasConfirmarPreniez,
    diasVaciosAltos: diasVaciosAltos ?? this.diasVaciosAltos,
    diasAntesSecar: diasAntesSecar ?? this.diasAntesSecar,
    diasAntesParto: diasAntesParto ?? this.diasAntesParto,
    diasAvisoFinRetiro: diasAvisoFinRetiro ?? this.diasAvisoFinRetiro,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    pendiente: pendiente ?? this.pendiente,
  );
  ConfigAlertaRow copyWithCompanion(ConfigAlertasCompanion data) {
    return ConfigAlertaRow(
      id: data.id.present ? data.id.value : this.id,
      lecheriaId: data.lecheriaId.present
          ? data.lecheriaId.value
          : this.lecheriaId,
      diasCeloEsperado: data.diasCeloEsperado.present
          ? data.diasCeloEsperado.value
          : this.diasCeloEsperado,
      diasConfirmarPreniez: data.diasConfirmarPreniez.present
          ? data.diasConfirmarPreniez.value
          : this.diasConfirmarPreniez,
      diasVaciosAltos: data.diasVaciosAltos.present
          ? data.diasVaciosAltos.value
          : this.diasVaciosAltos,
      diasAntesSecar: data.diasAntesSecar.present
          ? data.diasAntesSecar.value
          : this.diasAntesSecar,
      diasAntesParto: data.diasAntesParto.present
          ? data.diasAntesParto.value
          : this.diasAntesParto,
      diasAvisoFinRetiro: data.diasAvisoFinRetiro.present
          ? data.diasAvisoFinRetiro.value
          : this.diasAvisoFinRetiro,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      pendiente: data.pendiente.present ? data.pendiente.value : this.pendiente,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConfigAlertaRow(')
          ..write('id: $id, ')
          ..write('lecheriaId: $lecheriaId, ')
          ..write('diasCeloEsperado: $diasCeloEsperado, ')
          ..write('diasConfirmarPreniez: $diasConfirmarPreniez, ')
          ..write('diasVaciosAltos: $diasVaciosAltos, ')
          ..write('diasAntesSecar: $diasAntesSecar, ')
          ..write('diasAntesParto: $diasAntesParto, ')
          ..write('diasAvisoFinRetiro: $diasAvisoFinRetiro, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('pendiente: $pendiente')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    lecheriaId,
    diasCeloEsperado,
    diasConfirmarPreniez,
    diasVaciosAltos,
    diasAntesSecar,
    diasAntesParto,
    diasAvisoFinRetiro,
    createdAt,
    updatedAt,
    deletedAt,
    pendiente,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConfigAlertaRow &&
          other.id == this.id &&
          other.lecheriaId == this.lecheriaId &&
          other.diasCeloEsperado == this.diasCeloEsperado &&
          other.diasConfirmarPreniez == this.diasConfirmarPreniez &&
          other.diasVaciosAltos == this.diasVaciosAltos &&
          other.diasAntesSecar == this.diasAntesSecar &&
          other.diasAntesParto == this.diasAntesParto &&
          other.diasAvisoFinRetiro == this.diasAvisoFinRetiro &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.pendiente == this.pendiente);
}

class ConfigAlertasCompanion extends UpdateCompanion<ConfigAlertaRow> {
  final Value<String> id;
  final Value<String> lecheriaId;
  final Value<int> diasCeloEsperado;
  final Value<int> diasConfirmarPreniez;
  final Value<int> diasVaciosAltos;
  final Value<int> diasAntesSecar;
  final Value<int> diasAntesParto;
  final Value<int> diasAvisoFinRetiro;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<bool> pendiente;
  final Value<int> rowid;
  const ConfigAlertasCompanion({
    this.id = const Value.absent(),
    this.lecheriaId = const Value.absent(),
    this.diasCeloEsperado = const Value.absent(),
    this.diasConfirmarPreniez = const Value.absent(),
    this.diasVaciosAltos = const Value.absent(),
    this.diasAntesSecar = const Value.absent(),
    this.diasAntesParto = const Value.absent(),
    this.diasAvisoFinRetiro = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.pendiente = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConfigAlertasCompanion.insert({
    required String id,
    required String lecheriaId,
    this.diasCeloEsperado = const Value.absent(),
    this.diasConfirmarPreniez = const Value.absent(),
    this.diasVaciosAltos = const Value.absent(),
    this.diasAntesSecar = const Value.absent(),
    this.diasAntesParto = const Value.absent(),
    this.diasAvisoFinRetiro = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.pendiente = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       lecheriaId = Value(lecheriaId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ConfigAlertaRow> custom({
    Expression<String>? id,
    Expression<String>? lecheriaId,
    Expression<int>? diasCeloEsperado,
    Expression<int>? diasConfirmarPreniez,
    Expression<int>? diasVaciosAltos,
    Expression<int>? diasAntesSecar,
    Expression<int>? diasAntesParto,
    Expression<int>? diasAvisoFinRetiro,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<bool>? pendiente,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lecheriaId != null) 'lecheria_id': lecheriaId,
      if (diasCeloEsperado != null) 'dias_celo_esperado': diasCeloEsperado,
      if (diasConfirmarPreniez != null)
        'dias_confirmar_preniez': diasConfirmarPreniez,
      if (diasVaciosAltos != null) 'dias_vacios_altos': diasVaciosAltos,
      if (diasAntesSecar != null) 'dias_antes_secar': diasAntesSecar,
      if (diasAntesParto != null) 'dias_antes_parto': diasAntesParto,
      if (diasAvisoFinRetiro != null)
        'dias_aviso_fin_retiro': diasAvisoFinRetiro,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (pendiente != null) 'pendiente': pendiente,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConfigAlertasCompanion copyWith({
    Value<String>? id,
    Value<String>? lecheriaId,
    Value<int>? diasCeloEsperado,
    Value<int>? diasConfirmarPreniez,
    Value<int>? diasVaciosAltos,
    Value<int>? diasAntesSecar,
    Value<int>? diasAntesParto,
    Value<int>? diasAvisoFinRetiro,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<bool>? pendiente,
    Value<int>? rowid,
  }) {
    return ConfigAlertasCompanion(
      id: id ?? this.id,
      lecheriaId: lecheriaId ?? this.lecheriaId,
      diasCeloEsperado: diasCeloEsperado ?? this.diasCeloEsperado,
      diasConfirmarPreniez: diasConfirmarPreniez ?? this.diasConfirmarPreniez,
      diasVaciosAltos: diasVaciosAltos ?? this.diasVaciosAltos,
      diasAntesSecar: diasAntesSecar ?? this.diasAntesSecar,
      diasAntesParto: diasAntesParto ?? this.diasAntesParto,
      diasAvisoFinRetiro: diasAvisoFinRetiro ?? this.diasAvisoFinRetiro,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      pendiente: pendiente ?? this.pendiente,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (lecheriaId.present) {
      map['lecheria_id'] = Variable<String>(lecheriaId.value);
    }
    if (diasCeloEsperado.present) {
      map['dias_celo_esperado'] = Variable<int>(diasCeloEsperado.value);
    }
    if (diasConfirmarPreniez.present) {
      map['dias_confirmar_preniez'] = Variable<int>(diasConfirmarPreniez.value);
    }
    if (diasVaciosAltos.present) {
      map['dias_vacios_altos'] = Variable<int>(diasVaciosAltos.value);
    }
    if (diasAntesSecar.present) {
      map['dias_antes_secar'] = Variable<int>(diasAntesSecar.value);
    }
    if (diasAntesParto.present) {
      map['dias_antes_parto'] = Variable<int>(diasAntesParto.value);
    }
    if (diasAvisoFinRetiro.present) {
      map['dias_aviso_fin_retiro'] = Variable<int>(diasAvisoFinRetiro.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (pendiente.present) {
      map['pendiente'] = Variable<bool>(pendiente.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConfigAlertasCompanion(')
          ..write('id: $id, ')
          ..write('lecheriaId: $lecheriaId, ')
          ..write('diasCeloEsperado: $diasCeloEsperado, ')
          ..write('diasConfirmarPreniez: $diasConfirmarPreniez, ')
          ..write('diasVaciosAltos: $diasVaciosAltos, ')
          ..write('diasAntesSecar: $diasAntesSecar, ')
          ..write('diasAntesParto: $diasAntesParto, ')
          ..write('diasAvisoFinRetiro: $diasAvisoFinRetiro, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('pendiente: $pendiente, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncCursoresTable extends SyncCursores
    with TableInfo<$SyncCursoresTable, SyncCursorRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncCursoresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tablaMeta = const VerificationMeta('tabla');
  @override
  late final GeneratedColumn<String> tabla = GeneratedColumn<String>(
    'tabla',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ultimaBajadaMeta = const VerificationMeta(
    'ultimaBajada',
  );
  @override
  late final GeneratedColumn<DateTime> ultimaBajada = GeneratedColumn<DateTime>(
    'ultima_bajada',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ultimaBajadaIdMeta = const VerificationMeta(
    'ultimaBajadaId',
  );
  @override
  late final GeneratedColumn<String> ultimaBajadaId = GeneratedColumn<String>(
    'ultima_bajada_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [tabla, ultimaBajada, ultimaBajadaId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_cursores';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncCursorRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tabla')) {
      context.handle(
        _tablaMeta,
        tabla.isAcceptableOrUnknown(data['tabla']!, _tablaMeta),
      );
    } else if (isInserting) {
      context.missing(_tablaMeta);
    }
    if (data.containsKey('ultima_bajada')) {
      context.handle(
        _ultimaBajadaMeta,
        ultimaBajada.isAcceptableOrUnknown(
          data['ultima_bajada']!,
          _ultimaBajadaMeta,
        ),
      );
    }
    if (data.containsKey('ultima_bajada_id')) {
      context.handle(
        _ultimaBajadaIdMeta,
        ultimaBajadaId.isAcceptableOrUnknown(
          data['ultima_bajada_id']!,
          _ultimaBajadaIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tabla};
  @override
  SyncCursorRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncCursorRow(
      tabla: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tabla'],
      )!,
      ultimaBajada: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ultima_bajada'],
      ),
      ultimaBajadaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ultima_bajada_id'],
      ),
    );
  }

  @override
  $SyncCursoresTable createAlias(String alias) {
    return $SyncCursoresTable(attachedDatabase, alias);
  }
}

class SyncCursorRow extends DataClass implements Insertable<SyncCursorRow> {
  final String tabla;
  final DateTime? ultimaBajada;
  final String? ultimaBajadaId;
  const SyncCursorRow({
    required this.tabla,
    this.ultimaBajada,
    this.ultimaBajadaId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tabla'] = Variable<String>(tabla);
    if (!nullToAbsent || ultimaBajada != null) {
      map['ultima_bajada'] = Variable<DateTime>(ultimaBajada);
    }
    if (!nullToAbsent || ultimaBajadaId != null) {
      map['ultima_bajada_id'] = Variable<String>(ultimaBajadaId);
    }
    return map;
  }

  SyncCursoresCompanion toCompanion(bool nullToAbsent) {
    return SyncCursoresCompanion(
      tabla: Value(tabla),
      ultimaBajada: ultimaBajada == null && nullToAbsent
          ? const Value.absent()
          : Value(ultimaBajada),
      ultimaBajadaId: ultimaBajadaId == null && nullToAbsent
          ? const Value.absent()
          : Value(ultimaBajadaId),
    );
  }

  factory SyncCursorRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncCursorRow(
      tabla: serializer.fromJson<String>(json['tabla']),
      ultimaBajada: serializer.fromJson<DateTime?>(json['ultimaBajada']),
      ultimaBajadaId: serializer.fromJson<String?>(json['ultimaBajadaId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tabla': serializer.toJson<String>(tabla),
      'ultimaBajada': serializer.toJson<DateTime?>(ultimaBajada),
      'ultimaBajadaId': serializer.toJson<String?>(ultimaBajadaId),
    };
  }

  SyncCursorRow copyWith({
    String? tabla,
    Value<DateTime?> ultimaBajada = const Value.absent(),
    Value<String?> ultimaBajadaId = const Value.absent(),
  }) => SyncCursorRow(
    tabla: tabla ?? this.tabla,
    ultimaBajada: ultimaBajada.present ? ultimaBajada.value : this.ultimaBajada,
    ultimaBajadaId: ultimaBajadaId.present
        ? ultimaBajadaId.value
        : this.ultimaBajadaId,
  );
  SyncCursorRow copyWithCompanion(SyncCursoresCompanion data) {
    return SyncCursorRow(
      tabla: data.tabla.present ? data.tabla.value : this.tabla,
      ultimaBajada: data.ultimaBajada.present
          ? data.ultimaBajada.value
          : this.ultimaBajada,
      ultimaBajadaId: data.ultimaBajadaId.present
          ? data.ultimaBajadaId.value
          : this.ultimaBajadaId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursorRow(')
          ..write('tabla: $tabla, ')
          ..write('ultimaBajada: $ultimaBajada, ')
          ..write('ultimaBajadaId: $ultimaBajadaId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(tabla, ultimaBajada, ultimaBajadaId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncCursorRow &&
          other.tabla == this.tabla &&
          other.ultimaBajada == this.ultimaBajada &&
          other.ultimaBajadaId == this.ultimaBajadaId);
}

class SyncCursoresCompanion extends UpdateCompanion<SyncCursorRow> {
  final Value<String> tabla;
  final Value<DateTime?> ultimaBajada;
  final Value<String?> ultimaBajadaId;
  final Value<int> rowid;
  const SyncCursoresCompanion({
    this.tabla = const Value.absent(),
    this.ultimaBajada = const Value.absent(),
    this.ultimaBajadaId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncCursoresCompanion.insert({
    required String tabla,
    this.ultimaBajada = const Value.absent(),
    this.ultimaBajadaId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : tabla = Value(tabla);
  static Insertable<SyncCursorRow> custom({
    Expression<String>? tabla,
    Expression<DateTime>? ultimaBajada,
    Expression<String>? ultimaBajadaId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tabla != null) 'tabla': tabla,
      if (ultimaBajada != null) 'ultima_bajada': ultimaBajada,
      if (ultimaBajadaId != null) 'ultima_bajada_id': ultimaBajadaId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncCursoresCompanion copyWith({
    Value<String>? tabla,
    Value<DateTime?>? ultimaBajada,
    Value<String?>? ultimaBajadaId,
    Value<int>? rowid,
  }) {
    return SyncCursoresCompanion(
      tabla: tabla ?? this.tabla,
      ultimaBajada: ultimaBajada ?? this.ultimaBajada,
      ultimaBajadaId: ultimaBajadaId ?? this.ultimaBajadaId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tabla.present) {
      map['tabla'] = Variable<String>(tabla.value);
    }
    if (ultimaBajada.present) {
      map['ultima_bajada'] = Variable<DateTime>(ultimaBajada.value);
    }
    if (ultimaBajadaId.present) {
      map['ultima_bajada_id'] = Variable<String>(ultimaBajadaId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursoresCompanion(')
          ..write('tabla: $tabla, ')
          ..write('ultimaBajada: $ultimaBajada, ')
          ..write('ultimaBajadaId: $ultimaBajadaId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncEstadosTable extends SyncEstados
    with TableInfo<$SyncEstadosTable, SyncEstadoRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncEstadosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tablaMeta = const VerificationMeta('tabla');
  @override
  late final GeneratedColumn<String> tabla = GeneratedColumn<String>(
    'tabla',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ultimaSincronizacionOkMeta =
      const VerificationMeta('ultimaSincronizacionOk');
  @override
  late final GeneratedColumn<DateTime> ultimaSincronizacionOk =
      GeneratedColumn<DateTime>(
        'ultima_sincronizacion_ok',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _ultimoErrorMeta = const VerificationMeta(
    'ultimoError',
  );
  @override
  late final GeneratedColumn<String> ultimoError = GeneratedColumn<String>(
    'ultimo_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ultimoErrorEnMeta = const VerificationMeta(
    'ultimoErrorEn',
  );
  @override
  late final GeneratedColumn<DateTime> ultimoErrorEn =
      GeneratedColumn<DateTime>(
        'ultimo_error_en',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    tabla,
    ultimaSincronizacionOk,
    ultimoError,
    ultimoErrorEn,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_estados';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncEstadoRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tabla')) {
      context.handle(
        _tablaMeta,
        tabla.isAcceptableOrUnknown(data['tabla']!, _tablaMeta),
      );
    } else if (isInserting) {
      context.missing(_tablaMeta);
    }
    if (data.containsKey('ultima_sincronizacion_ok')) {
      context.handle(
        _ultimaSincronizacionOkMeta,
        ultimaSincronizacionOk.isAcceptableOrUnknown(
          data['ultima_sincronizacion_ok']!,
          _ultimaSincronizacionOkMeta,
        ),
      );
    }
    if (data.containsKey('ultimo_error')) {
      context.handle(
        _ultimoErrorMeta,
        ultimoError.isAcceptableOrUnknown(
          data['ultimo_error']!,
          _ultimoErrorMeta,
        ),
      );
    }
    if (data.containsKey('ultimo_error_en')) {
      context.handle(
        _ultimoErrorEnMeta,
        ultimoErrorEn.isAcceptableOrUnknown(
          data['ultimo_error_en']!,
          _ultimoErrorEnMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tabla};
  @override
  SyncEstadoRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncEstadoRow(
      tabla: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tabla'],
      )!,
      ultimaSincronizacionOk: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ultima_sincronizacion_ok'],
      ),
      ultimoError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ultimo_error'],
      ),
      ultimoErrorEn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ultimo_error_en'],
      ),
    );
  }

  @override
  $SyncEstadosTable createAlias(String alias) {
    return $SyncEstadosTable(attachedDatabase, alias);
  }
}

class SyncEstadoRow extends DataClass implements Insertable<SyncEstadoRow> {
  final String tabla;
  final DateTime? ultimaSincronizacionOk;
  final String? ultimoError;
  final DateTime? ultimoErrorEn;
  const SyncEstadoRow({
    required this.tabla,
    this.ultimaSincronizacionOk,
    this.ultimoError,
    this.ultimoErrorEn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tabla'] = Variable<String>(tabla);
    if (!nullToAbsent || ultimaSincronizacionOk != null) {
      map['ultima_sincronizacion_ok'] = Variable<DateTime>(
        ultimaSincronizacionOk,
      );
    }
    if (!nullToAbsent || ultimoError != null) {
      map['ultimo_error'] = Variable<String>(ultimoError);
    }
    if (!nullToAbsent || ultimoErrorEn != null) {
      map['ultimo_error_en'] = Variable<DateTime>(ultimoErrorEn);
    }
    return map;
  }

  SyncEstadosCompanion toCompanion(bool nullToAbsent) {
    return SyncEstadosCompanion(
      tabla: Value(tabla),
      ultimaSincronizacionOk: ultimaSincronizacionOk == null && nullToAbsent
          ? const Value.absent()
          : Value(ultimaSincronizacionOk),
      ultimoError: ultimoError == null && nullToAbsent
          ? const Value.absent()
          : Value(ultimoError),
      ultimoErrorEn: ultimoErrorEn == null && nullToAbsent
          ? const Value.absent()
          : Value(ultimoErrorEn),
    );
  }

  factory SyncEstadoRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncEstadoRow(
      tabla: serializer.fromJson<String>(json['tabla']),
      ultimaSincronizacionOk: serializer.fromJson<DateTime?>(
        json['ultimaSincronizacionOk'],
      ),
      ultimoError: serializer.fromJson<String?>(json['ultimoError']),
      ultimoErrorEn: serializer.fromJson<DateTime?>(json['ultimoErrorEn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tabla': serializer.toJson<String>(tabla),
      'ultimaSincronizacionOk': serializer.toJson<DateTime?>(
        ultimaSincronizacionOk,
      ),
      'ultimoError': serializer.toJson<String?>(ultimoError),
      'ultimoErrorEn': serializer.toJson<DateTime?>(ultimoErrorEn),
    };
  }

  SyncEstadoRow copyWith({
    String? tabla,
    Value<DateTime?> ultimaSincronizacionOk = const Value.absent(),
    Value<String?> ultimoError = const Value.absent(),
    Value<DateTime?> ultimoErrorEn = const Value.absent(),
  }) => SyncEstadoRow(
    tabla: tabla ?? this.tabla,
    ultimaSincronizacionOk: ultimaSincronizacionOk.present
        ? ultimaSincronizacionOk.value
        : this.ultimaSincronizacionOk,
    ultimoError: ultimoError.present ? ultimoError.value : this.ultimoError,
    ultimoErrorEn: ultimoErrorEn.present
        ? ultimoErrorEn.value
        : this.ultimoErrorEn,
  );
  SyncEstadoRow copyWithCompanion(SyncEstadosCompanion data) {
    return SyncEstadoRow(
      tabla: data.tabla.present ? data.tabla.value : this.tabla,
      ultimaSincronizacionOk: data.ultimaSincronizacionOk.present
          ? data.ultimaSincronizacionOk.value
          : this.ultimaSincronizacionOk,
      ultimoError: data.ultimoError.present
          ? data.ultimoError.value
          : this.ultimoError,
      ultimoErrorEn: data.ultimoErrorEn.present
          ? data.ultimoErrorEn.value
          : this.ultimoErrorEn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncEstadoRow(')
          ..write('tabla: $tabla, ')
          ..write('ultimaSincronizacionOk: $ultimaSincronizacionOk, ')
          ..write('ultimoError: $ultimoError, ')
          ..write('ultimoErrorEn: $ultimoErrorEn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(tabla, ultimaSincronizacionOk, ultimoError, ultimoErrorEn);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncEstadoRow &&
          other.tabla == this.tabla &&
          other.ultimaSincronizacionOk == this.ultimaSincronizacionOk &&
          other.ultimoError == this.ultimoError &&
          other.ultimoErrorEn == this.ultimoErrorEn);
}

class SyncEstadosCompanion extends UpdateCompanion<SyncEstadoRow> {
  final Value<String> tabla;
  final Value<DateTime?> ultimaSincronizacionOk;
  final Value<String?> ultimoError;
  final Value<DateTime?> ultimoErrorEn;
  final Value<int> rowid;
  const SyncEstadosCompanion({
    this.tabla = const Value.absent(),
    this.ultimaSincronizacionOk = const Value.absent(),
    this.ultimoError = const Value.absent(),
    this.ultimoErrorEn = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncEstadosCompanion.insert({
    required String tabla,
    this.ultimaSincronizacionOk = const Value.absent(),
    this.ultimoError = const Value.absent(),
    this.ultimoErrorEn = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : tabla = Value(tabla);
  static Insertable<SyncEstadoRow> custom({
    Expression<String>? tabla,
    Expression<DateTime>? ultimaSincronizacionOk,
    Expression<String>? ultimoError,
    Expression<DateTime>? ultimoErrorEn,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tabla != null) 'tabla': tabla,
      if (ultimaSincronizacionOk != null)
        'ultima_sincronizacion_ok': ultimaSincronizacionOk,
      if (ultimoError != null) 'ultimo_error': ultimoError,
      if (ultimoErrorEn != null) 'ultimo_error_en': ultimoErrorEn,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncEstadosCompanion copyWith({
    Value<String>? tabla,
    Value<DateTime?>? ultimaSincronizacionOk,
    Value<String?>? ultimoError,
    Value<DateTime?>? ultimoErrorEn,
    Value<int>? rowid,
  }) {
    return SyncEstadosCompanion(
      tabla: tabla ?? this.tabla,
      ultimaSincronizacionOk:
          ultimaSincronizacionOk ?? this.ultimaSincronizacionOk,
      ultimoError: ultimoError ?? this.ultimoError,
      ultimoErrorEn: ultimoErrorEn ?? this.ultimoErrorEn,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tabla.present) {
      map['tabla'] = Variable<String>(tabla.value);
    }
    if (ultimaSincronizacionOk.present) {
      map['ultima_sincronizacion_ok'] = Variable<DateTime>(
        ultimaSincronizacionOk.value,
      );
    }
    if (ultimoError.present) {
      map['ultimo_error'] = Variable<String>(ultimoError.value);
    }
    if (ultimoErrorEn.present) {
      map['ultimo_error_en'] = Variable<DateTime>(ultimoErrorEn.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncEstadosCompanion(')
          ..write('tabla: $tabla, ')
          ..write('ultimaSincronizacionOk: $ultimaSincronizacionOk, ')
          ..write('ultimoError: $ultimoError, ')
          ..write('ultimoErrorEn: $ultimoErrorEn, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SesionesLocalesTable extends SesionesLocales
    with TableInfo<$SesionesLocalesTable, SesionLocalRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SesionesLocalesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usuarioIdMeta = const VerificationMeta(
    'usuarioId',
  );
  @override
  late final GeneratedColumn<String> usuarioId = GeneratedColumn<String>(
    'usuario_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ultimoLoginOnlineMeta = const VerificationMeta(
    'ultimoLoginOnline',
  );
  @override
  late final GeneratedColumn<DateTime> ultimoLoginOnline =
      GeneratedColumn<DateTime>(
        'ultimo_login_online',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _offlineActivaMeta = const VerificationMeta(
    'offlineActiva',
  );
  @override
  late final GeneratedColumn<bool> offlineActiva = GeneratedColumn<bool>(
    'offline_activa',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("offline_activa" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    usuarioId,
    email,
    nombre,
    ultimoLoginOnline,
    offlineActiva,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sesiones_locales';
  @override
  VerificationContext validateIntegrity(
    Insertable<SesionLocalRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('usuario_id')) {
      context.handle(
        _usuarioIdMeta,
        usuarioId.isAcceptableOrUnknown(data['usuario_id']!, _usuarioIdMeta),
      );
    } else if (isInserting) {
      context.missing(_usuarioIdMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    }
    if (data.containsKey('ultimo_login_online')) {
      context.handle(
        _ultimoLoginOnlineMeta,
        ultimoLoginOnline.isAcceptableOrUnknown(
          data['ultimo_login_online']!,
          _ultimoLoginOnlineMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ultimoLoginOnlineMeta);
    }
    if (data.containsKey('offline_activa')) {
      context.handle(
        _offlineActivaMeta,
        offlineActiva.isAcceptableOrUnknown(
          data['offline_activa']!,
          _offlineActivaMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SesionLocalRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SesionLocalRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      usuarioId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}usuario_id'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      ),
      ultimoLoginOnline: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ultimo_login_online'],
      )!,
      offlineActiva: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}offline_activa'],
      )!,
    );
  }

  @override
  $SesionesLocalesTable createAlias(String alias) {
    return $SesionesLocalesTable(attachedDatabase, alias);
  }
}

class SesionLocalRow extends DataClass implements Insertable<SesionLocalRow> {
  final String id;
  final String usuarioId;
  final String? email;
  final String? nombre;
  final DateTime ultimoLoginOnline;
  final bool offlineActiva;
  const SesionLocalRow({
    required this.id,
    required this.usuarioId,
    this.email,
    this.nombre,
    required this.ultimoLoginOnline,
    required this.offlineActiva,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['usuario_id'] = Variable<String>(usuarioId);
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || nombre != null) {
      map['nombre'] = Variable<String>(nombre);
    }
    map['ultimo_login_online'] = Variable<DateTime>(ultimoLoginOnline);
    map['offline_activa'] = Variable<bool>(offlineActiva);
    return map;
  }

  SesionesLocalesCompanion toCompanion(bool nullToAbsent) {
    return SesionesLocalesCompanion(
      id: Value(id),
      usuarioId: Value(usuarioId),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      nombre: nombre == null && nullToAbsent
          ? const Value.absent()
          : Value(nombre),
      ultimoLoginOnline: Value(ultimoLoginOnline),
      offlineActiva: Value(offlineActiva),
    );
  }

  factory SesionLocalRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SesionLocalRow(
      id: serializer.fromJson<String>(json['id']),
      usuarioId: serializer.fromJson<String>(json['usuarioId']),
      email: serializer.fromJson<String?>(json['email']),
      nombre: serializer.fromJson<String?>(json['nombre']),
      ultimoLoginOnline: serializer.fromJson<DateTime>(
        json['ultimoLoginOnline'],
      ),
      offlineActiva: serializer.fromJson<bool>(json['offlineActiva']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'usuarioId': serializer.toJson<String>(usuarioId),
      'email': serializer.toJson<String?>(email),
      'nombre': serializer.toJson<String?>(nombre),
      'ultimoLoginOnline': serializer.toJson<DateTime>(ultimoLoginOnline),
      'offlineActiva': serializer.toJson<bool>(offlineActiva),
    };
  }

  SesionLocalRow copyWith({
    String? id,
    String? usuarioId,
    Value<String?> email = const Value.absent(),
    Value<String?> nombre = const Value.absent(),
    DateTime? ultimoLoginOnline,
    bool? offlineActiva,
  }) => SesionLocalRow(
    id: id ?? this.id,
    usuarioId: usuarioId ?? this.usuarioId,
    email: email.present ? email.value : this.email,
    nombre: nombre.present ? nombre.value : this.nombre,
    ultimoLoginOnline: ultimoLoginOnline ?? this.ultimoLoginOnline,
    offlineActiva: offlineActiva ?? this.offlineActiva,
  );
  SesionLocalRow copyWithCompanion(SesionesLocalesCompanion data) {
    return SesionLocalRow(
      id: data.id.present ? data.id.value : this.id,
      usuarioId: data.usuarioId.present ? data.usuarioId.value : this.usuarioId,
      email: data.email.present ? data.email.value : this.email,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      ultimoLoginOnline: data.ultimoLoginOnline.present
          ? data.ultimoLoginOnline.value
          : this.ultimoLoginOnline,
      offlineActiva: data.offlineActiva.present
          ? data.offlineActiva.value
          : this.offlineActiva,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SesionLocalRow(')
          ..write('id: $id, ')
          ..write('usuarioId: $usuarioId, ')
          ..write('email: $email, ')
          ..write('nombre: $nombre, ')
          ..write('ultimoLoginOnline: $ultimoLoginOnline, ')
          ..write('offlineActiva: $offlineActiva')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    usuarioId,
    email,
    nombre,
    ultimoLoginOnline,
    offlineActiva,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SesionLocalRow &&
          other.id == this.id &&
          other.usuarioId == this.usuarioId &&
          other.email == this.email &&
          other.nombre == this.nombre &&
          other.ultimoLoginOnline == this.ultimoLoginOnline &&
          other.offlineActiva == this.offlineActiva);
}

class SesionesLocalesCompanion extends UpdateCompanion<SesionLocalRow> {
  final Value<String> id;
  final Value<String> usuarioId;
  final Value<String?> email;
  final Value<String?> nombre;
  final Value<DateTime> ultimoLoginOnline;
  final Value<bool> offlineActiva;
  final Value<int> rowid;
  const SesionesLocalesCompanion({
    this.id = const Value.absent(),
    this.usuarioId = const Value.absent(),
    this.email = const Value.absent(),
    this.nombre = const Value.absent(),
    this.ultimoLoginOnline = const Value.absent(),
    this.offlineActiva = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SesionesLocalesCompanion.insert({
    required String id,
    required String usuarioId,
    this.email = const Value.absent(),
    this.nombre = const Value.absent(),
    required DateTime ultimoLoginOnline,
    this.offlineActiva = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       usuarioId = Value(usuarioId),
       ultimoLoginOnline = Value(ultimoLoginOnline);
  static Insertable<SesionLocalRow> custom({
    Expression<String>? id,
    Expression<String>? usuarioId,
    Expression<String>? email,
    Expression<String>? nombre,
    Expression<DateTime>? ultimoLoginOnline,
    Expression<bool>? offlineActiva,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (usuarioId != null) 'usuario_id': usuarioId,
      if (email != null) 'email': email,
      if (nombre != null) 'nombre': nombre,
      if (ultimoLoginOnline != null) 'ultimo_login_online': ultimoLoginOnline,
      if (offlineActiva != null) 'offline_activa': offlineActiva,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SesionesLocalesCompanion copyWith({
    Value<String>? id,
    Value<String>? usuarioId,
    Value<String?>? email,
    Value<String?>? nombre,
    Value<DateTime>? ultimoLoginOnline,
    Value<bool>? offlineActiva,
    Value<int>? rowid,
  }) {
    return SesionesLocalesCompanion(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      email: email ?? this.email,
      nombre: nombre ?? this.nombre,
      ultimoLoginOnline: ultimoLoginOnline ?? this.ultimoLoginOnline,
      offlineActiva: offlineActiva ?? this.offlineActiva,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (usuarioId.present) {
      map['usuario_id'] = Variable<String>(usuarioId.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (ultimoLoginOnline.present) {
      map['ultimo_login_online'] = Variable<DateTime>(ultimoLoginOnline.value);
    }
    if (offlineActiva.present) {
      map['offline_activa'] = Variable<bool>(offlineActiva.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SesionesLocalesCompanion(')
          ..write('id: $id, ')
          ..write('usuarioId: $usuarioId, ')
          ..write('email: $email, ')
          ..write('nombre: $nombre, ')
          ..write('ultimoLoginOnline: $ultimoLoginOnline, ')
          ..write('offlineActiva: $offlineActiva, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PlanesTable planes = $PlanesTable(this);
  late final $CuentasTable cuentas = $CuentasTable(this);
  late final $UsuariosTable usuarios = $UsuariosTable(this);
  late final $LecheriasTable lecherias = $LecheriasTable(this);
  late final $LecheriaMiembrosTable lecheriaMiembros = $LecheriaMiembrosTable(
    this,
  );
  late final $AnimalesTable animales = $AnimalesTable(this);
  late final $EventosAnimalTable eventosAnimal = $EventosAnimalTable(this);
  late final $PesasSesionesTable pesasSesiones = $PesasSesionesTable(this);
  late final $PesasLecheTable pesasLeche = $PesasLecheTable(this);
  late final $ParametrosPeriodoTable parametrosPeriodo =
      $ParametrosPeriodoTable(this);
  late final $CostosFijosTable costosFijos = $CostosFijosTable(this);
  late final $MedicamentosTable medicamentos = $MedicamentosTable(this);
  late final $ConfigAlertasTable configAlertas = $ConfigAlertasTable(this);
  late final $SyncCursoresTable syncCursores = $SyncCursoresTable(this);
  late final $SyncEstadosTable syncEstados = $SyncEstadosTable(this);
  late final $SesionesLocalesTable sesionesLocales = $SesionesLocalesTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    planes,
    cuentas,
    usuarios,
    lecherias,
    lecheriaMiembros,
    animales,
    eventosAnimal,
    pesasSesiones,
    pesasLeche,
    parametrosPeriodo,
    costosFijos,
    medicamentos,
    configAlertas,
    syncCursores,
    syncEstados,
    sesionesLocales,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$PlanesTableCreateCompanionBuilder =
    PlanesCompanion Function({
      required String codigo,
      required String nombre,
      required int limiteLecherias,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$PlanesTableUpdateCompanionBuilder =
    PlanesCompanion Function({
      Value<String> codigo,
      Value<String> nombre,
      Value<int> limiteLecherias,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$PlanesTableFilterComposer
    extends Composer<_$AppDatabase, $PlanesTable> {
  $$PlanesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get codigo => $composableBuilder(
    column: $table.codigo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get limiteLecherias => $composableBuilder(
    column: $table.limiteLecherias,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlanesTableOrderingComposer
    extends Composer<_$AppDatabase, $PlanesTable> {
  $$PlanesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get codigo => $composableBuilder(
    column: $table.codigo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get limiteLecherias => $composableBuilder(
    column: $table.limiteLecherias,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlanesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlanesTable> {
  $$PlanesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get codigo =>
      $composableBuilder(column: $table.codigo, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<int> get limiteLecherias => $composableBuilder(
    column: $table.limiteLecherias,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PlanesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlanesTable,
          PlanRow,
          $$PlanesTableFilterComposer,
          $$PlanesTableOrderingComposer,
          $$PlanesTableAnnotationComposer,
          $$PlanesTableCreateCompanionBuilder,
          $$PlanesTableUpdateCompanionBuilder,
          (PlanRow, BaseReferences<_$AppDatabase, $PlanesTable, PlanRow>),
          PlanRow,
          PrefetchHooks Function()
        > {
  $$PlanesTableTableManager(_$AppDatabase db, $PlanesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlanesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlanesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlanesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> codigo = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<int> limiteLecherias = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlanesCompanion(
                codigo: codigo,
                nombre: nombre,
                limiteLecherias: limiteLecherias,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String codigo,
                required String nombre,
                required int limiteLecherias,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => PlanesCompanion.insert(
                codigo: codigo,
                nombre: nombre,
                limiteLecherias: limiteLecherias,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlanesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlanesTable,
      PlanRow,
      $$PlanesTableFilterComposer,
      $$PlanesTableOrderingComposer,
      $$PlanesTableAnnotationComposer,
      $$PlanesTableCreateCompanionBuilder,
      $$PlanesTableUpdateCompanionBuilder,
      (PlanRow, BaseReferences<_$AppDatabase, $PlanesTable, PlanRow>),
      PlanRow,
      PrefetchHooks Function()
    >;
typedef $$CuentasTableCreateCompanionBuilder =
    CuentasCompanion Function({
      required String id,
      required String nombre,
      required String duenoId,
      required String plan,
      required String estado,
      Value<DateTime?> pruebaTermina,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<bool> pendiente,
      Value<int> rowid,
    });
typedef $$CuentasTableUpdateCompanionBuilder =
    CuentasCompanion Function({
      Value<String> id,
      Value<String> nombre,
      Value<String> duenoId,
      Value<String> plan,
      Value<String> estado,
      Value<DateTime?> pruebaTermina,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<bool> pendiente,
      Value<int> rowid,
    });

class $$CuentasTableFilterComposer
    extends Composer<_$AppDatabase, $CuentasTable> {
  $$CuentasTableFilterComposer({
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

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get duenoId => $composableBuilder(
    column: $table.duenoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plan => $composableBuilder(
    column: $table.plan,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get estado => $composableBuilder(
    column: $table.estado,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get pruebaTermina => $composableBuilder(
    column: $table.pruebaTermina,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendiente => $composableBuilder(
    column: $table.pendiente,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CuentasTableOrderingComposer
    extends Composer<_$AppDatabase, $CuentasTable> {
  $$CuentasTableOrderingComposer({
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

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get duenoId => $composableBuilder(
    column: $table.duenoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plan => $composableBuilder(
    column: $table.plan,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get estado => $composableBuilder(
    column: $table.estado,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get pruebaTermina => $composableBuilder(
    column: $table.pruebaTermina,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendiente => $composableBuilder(
    column: $table.pendiente,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CuentasTableAnnotationComposer
    extends Composer<_$AppDatabase, $CuentasTable> {
  $$CuentasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<String> get duenoId =>
      $composableBuilder(column: $table.duenoId, builder: (column) => column);

  GeneratedColumn<String> get plan =>
      $composableBuilder(column: $table.plan, builder: (column) => column);

  GeneratedColumn<String> get estado =>
      $composableBuilder(column: $table.estado, builder: (column) => column);

  GeneratedColumn<DateTime> get pruebaTermina => $composableBuilder(
    column: $table.pruebaTermina,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<bool> get pendiente =>
      $composableBuilder(column: $table.pendiente, builder: (column) => column);
}

class $$CuentasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CuentasTable,
          CuentaRow,
          $$CuentasTableFilterComposer,
          $$CuentasTableOrderingComposer,
          $$CuentasTableAnnotationComposer,
          $$CuentasTableCreateCompanionBuilder,
          $$CuentasTableUpdateCompanionBuilder,
          (CuentaRow, BaseReferences<_$AppDatabase, $CuentasTable, CuentaRow>),
          CuentaRow,
          PrefetchHooks Function()
        > {
  $$CuentasTableTableManager(_$AppDatabase db, $CuentasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CuentasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CuentasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CuentasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<String> duenoId = const Value.absent(),
                Value<String> plan = const Value.absent(),
                Value<String> estado = const Value.absent(),
                Value<DateTime?> pruebaTermina = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<bool> pendiente = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CuentasCompanion(
                id: id,
                nombre: nombre,
                duenoId: duenoId,
                plan: plan,
                estado: estado,
                pruebaTermina: pruebaTermina,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                pendiente: pendiente,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String nombre,
                required String duenoId,
                required String plan,
                required String estado,
                Value<DateTime?> pruebaTermina = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<bool> pendiente = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CuentasCompanion.insert(
                id: id,
                nombre: nombre,
                duenoId: duenoId,
                plan: plan,
                estado: estado,
                pruebaTermina: pruebaTermina,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                pendiente: pendiente,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CuentasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CuentasTable,
      CuentaRow,
      $$CuentasTableFilterComposer,
      $$CuentasTableOrderingComposer,
      $$CuentasTableAnnotationComposer,
      $$CuentasTableCreateCompanionBuilder,
      $$CuentasTableUpdateCompanionBuilder,
      (CuentaRow, BaseReferences<_$AppDatabase, $CuentasTable, CuentaRow>),
      CuentaRow,
      PrefetchHooks Function()
    >;
typedef $$UsuariosTableCreateCompanionBuilder =
    UsuariosCompanion Function({
      required String id,
      Value<String?> nombre,
      Value<String?> email,
      Value<String?> cuentaId,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<bool> pendiente,
      Value<int> rowid,
    });
typedef $$UsuariosTableUpdateCompanionBuilder =
    UsuariosCompanion Function({
      Value<String> id,
      Value<String?> nombre,
      Value<String?> email,
      Value<String?> cuentaId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> pendiente,
      Value<int> rowid,
    });

class $$UsuariosTableFilterComposer
    extends Composer<_$AppDatabase, $UsuariosTable> {
  $$UsuariosTableFilterComposer({
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

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cuentaId => $composableBuilder(
    column: $table.cuentaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendiente => $composableBuilder(
    column: $table.pendiente,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UsuariosTableOrderingComposer
    extends Composer<_$AppDatabase, $UsuariosTable> {
  $$UsuariosTableOrderingComposer({
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

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cuentaId => $composableBuilder(
    column: $table.cuentaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendiente => $composableBuilder(
    column: $table.pendiente,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UsuariosTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsuariosTable> {
  $$UsuariosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get cuentaId =>
      $composableBuilder(column: $table.cuentaId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get pendiente =>
      $composableBuilder(column: $table.pendiente, builder: (column) => column);
}

class $$UsuariosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UsuariosTable,
          UsuarioRow,
          $$UsuariosTableFilterComposer,
          $$UsuariosTableOrderingComposer,
          $$UsuariosTableAnnotationComposer,
          $$UsuariosTableCreateCompanionBuilder,
          $$UsuariosTableUpdateCompanionBuilder,
          (
            UsuarioRow,
            BaseReferences<_$AppDatabase, $UsuariosTable, UsuarioRow>,
          ),
          UsuarioRow,
          PrefetchHooks Function()
        > {
  $$UsuariosTableTableManager(_$AppDatabase db, $UsuariosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsuariosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsuariosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsuariosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> nombre = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> cuentaId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> pendiente = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsuariosCompanion(
                id: id,
                nombre: nombre,
                email: email,
                cuentaId: cuentaId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                pendiente: pendiente,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> nombre = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> cuentaId = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<bool> pendiente = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsuariosCompanion.insert(
                id: id,
                nombre: nombre,
                email: email,
                cuentaId: cuentaId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                pendiente: pendiente,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UsuariosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UsuariosTable,
      UsuarioRow,
      $$UsuariosTableFilterComposer,
      $$UsuariosTableOrderingComposer,
      $$UsuariosTableAnnotationComposer,
      $$UsuariosTableCreateCompanionBuilder,
      $$UsuariosTableUpdateCompanionBuilder,
      (UsuarioRow, BaseReferences<_$AppDatabase, $UsuariosTable, UsuarioRow>),
      UsuarioRow,
      PrefetchHooks Function()
    >;
typedef $$LecheriasTableCreateCompanionBuilder =
    LecheriasCompanion Function({
      required String id,
      required String nombre,
      required String creadaPor,
      Value<String?> cuentaId,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<bool> pendiente,
      Value<int> rowid,
    });
typedef $$LecheriasTableUpdateCompanionBuilder =
    LecheriasCompanion Function({
      Value<String> id,
      Value<String> nombre,
      Value<String> creadaPor,
      Value<String?> cuentaId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<bool> pendiente,
      Value<int> rowid,
    });

class $$LecheriasTableFilterComposer
    extends Composer<_$AppDatabase, $LecheriasTable> {
  $$LecheriasTableFilterComposer({
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

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get creadaPor => $composableBuilder(
    column: $table.creadaPor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cuentaId => $composableBuilder(
    column: $table.cuentaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendiente => $composableBuilder(
    column: $table.pendiente,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LecheriasTableOrderingComposer
    extends Composer<_$AppDatabase, $LecheriasTable> {
  $$LecheriasTableOrderingComposer({
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

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get creadaPor => $composableBuilder(
    column: $table.creadaPor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cuentaId => $composableBuilder(
    column: $table.cuentaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendiente => $composableBuilder(
    column: $table.pendiente,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LecheriasTableAnnotationComposer
    extends Composer<_$AppDatabase, $LecheriasTable> {
  $$LecheriasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<String> get creadaPor =>
      $composableBuilder(column: $table.creadaPor, builder: (column) => column);

  GeneratedColumn<String> get cuentaId =>
      $composableBuilder(column: $table.cuentaId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<bool> get pendiente =>
      $composableBuilder(column: $table.pendiente, builder: (column) => column);
}

class $$LecheriasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LecheriasTable,
          LecheriaRow,
          $$LecheriasTableFilterComposer,
          $$LecheriasTableOrderingComposer,
          $$LecheriasTableAnnotationComposer,
          $$LecheriasTableCreateCompanionBuilder,
          $$LecheriasTableUpdateCompanionBuilder,
          (
            LecheriaRow,
            BaseReferences<_$AppDatabase, $LecheriasTable, LecheriaRow>,
          ),
          LecheriaRow,
          PrefetchHooks Function()
        > {
  $$LecheriasTableTableManager(_$AppDatabase db, $LecheriasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LecheriasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LecheriasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LecheriasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<String> creadaPor = const Value.absent(),
                Value<String?> cuentaId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<bool> pendiente = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LecheriasCompanion(
                id: id,
                nombre: nombre,
                creadaPor: creadaPor,
                cuentaId: cuentaId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                pendiente: pendiente,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String nombre,
                required String creadaPor,
                Value<String?> cuentaId = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<bool> pendiente = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LecheriasCompanion.insert(
                id: id,
                nombre: nombre,
                creadaPor: creadaPor,
                cuentaId: cuentaId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                pendiente: pendiente,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LecheriasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LecheriasTable,
      LecheriaRow,
      $$LecheriasTableFilterComposer,
      $$LecheriasTableOrderingComposer,
      $$LecheriasTableAnnotationComposer,
      $$LecheriasTableCreateCompanionBuilder,
      $$LecheriasTableUpdateCompanionBuilder,
      (
        LecheriaRow,
        BaseReferences<_$AppDatabase, $LecheriasTable, LecheriaRow>,
      ),
      LecheriaRow,
      PrefetchHooks Function()
    >;
typedef $$LecheriaMiembrosTableCreateCompanionBuilder =
    LecheriaMiembrosCompanion Function({
      required String id,
      required String lecheriaId,
      required String usuarioId,
      required String rol,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<bool> pendiente,
      Value<int> rowid,
    });
typedef $$LecheriaMiembrosTableUpdateCompanionBuilder =
    LecheriaMiembrosCompanion Function({
      Value<String> id,
      Value<String> lecheriaId,
      Value<String> usuarioId,
      Value<String> rol,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<bool> pendiente,
      Value<int> rowid,
    });

class $$LecheriaMiembrosTableFilterComposer
    extends Composer<_$AppDatabase, $LecheriaMiembrosTable> {
  $$LecheriaMiembrosTableFilterComposer({
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

  ColumnFilters<String> get lecheriaId => $composableBuilder(
    column: $table.lecheriaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get usuarioId => $composableBuilder(
    column: $table.usuarioId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rol => $composableBuilder(
    column: $table.rol,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendiente => $composableBuilder(
    column: $table.pendiente,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LecheriaMiembrosTableOrderingComposer
    extends Composer<_$AppDatabase, $LecheriaMiembrosTable> {
  $$LecheriaMiembrosTableOrderingComposer({
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

  ColumnOrderings<String> get lecheriaId => $composableBuilder(
    column: $table.lecheriaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get usuarioId => $composableBuilder(
    column: $table.usuarioId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rol => $composableBuilder(
    column: $table.rol,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendiente => $composableBuilder(
    column: $table.pendiente,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LecheriaMiembrosTableAnnotationComposer
    extends Composer<_$AppDatabase, $LecheriaMiembrosTable> {
  $$LecheriaMiembrosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get lecheriaId => $composableBuilder(
    column: $table.lecheriaId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get usuarioId =>
      $composableBuilder(column: $table.usuarioId, builder: (column) => column);

  GeneratedColumn<String> get rol =>
      $composableBuilder(column: $table.rol, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<bool> get pendiente =>
      $composableBuilder(column: $table.pendiente, builder: (column) => column);
}

class $$LecheriaMiembrosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LecheriaMiembrosTable,
          LecheriaMiembroRow,
          $$LecheriaMiembrosTableFilterComposer,
          $$LecheriaMiembrosTableOrderingComposer,
          $$LecheriaMiembrosTableAnnotationComposer,
          $$LecheriaMiembrosTableCreateCompanionBuilder,
          $$LecheriaMiembrosTableUpdateCompanionBuilder,
          (
            LecheriaMiembroRow,
            BaseReferences<
              _$AppDatabase,
              $LecheriaMiembrosTable,
              LecheriaMiembroRow
            >,
          ),
          LecheriaMiembroRow,
          PrefetchHooks Function()
        > {
  $$LecheriaMiembrosTableTableManager(
    _$AppDatabase db,
    $LecheriaMiembrosTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LecheriaMiembrosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LecheriaMiembrosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LecheriaMiembrosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> lecheriaId = const Value.absent(),
                Value<String> usuarioId = const Value.absent(),
                Value<String> rol = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<bool> pendiente = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LecheriaMiembrosCompanion(
                id: id,
                lecheriaId: lecheriaId,
                usuarioId: usuarioId,
                rol: rol,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                pendiente: pendiente,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String lecheriaId,
                required String usuarioId,
                required String rol,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<bool> pendiente = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LecheriaMiembrosCompanion.insert(
                id: id,
                lecheriaId: lecheriaId,
                usuarioId: usuarioId,
                rol: rol,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                pendiente: pendiente,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LecheriaMiembrosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LecheriaMiembrosTable,
      LecheriaMiembroRow,
      $$LecheriaMiembrosTableFilterComposer,
      $$LecheriaMiembrosTableOrderingComposer,
      $$LecheriaMiembrosTableAnnotationComposer,
      $$LecheriaMiembrosTableCreateCompanionBuilder,
      $$LecheriaMiembrosTableUpdateCompanionBuilder,
      (
        LecheriaMiembroRow,
        BaseReferences<
          _$AppDatabase,
          $LecheriaMiembrosTable,
          LecheriaMiembroRow
        >,
      ),
      LecheriaMiembroRow,
      PrefetchHooks Function()
    >;
typedef $$AnimalesTableCreateCompanionBuilder =
    AnimalesCompanion Function({
      required String id,
      required String lecheriaId,
      required String identificador,
      required String sexo,
      required String grupo,
      Value<String> estado,
      Value<String> estadoReproductivo,
      required String origen,
      Value<double?> precioCompra,
      Value<DateTime?> fechaCompra,
      Value<String?> madreId,
      Value<double> concentradoKgDia,
      Value<DateTime?> fechaProbableParto,
      Value<DateTime?> retiroLecheHasta,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<bool> pendiente,
      Value<int> rowid,
    });
typedef $$AnimalesTableUpdateCompanionBuilder =
    AnimalesCompanion Function({
      Value<String> id,
      Value<String> lecheriaId,
      Value<String> identificador,
      Value<String> sexo,
      Value<String> grupo,
      Value<String> estado,
      Value<String> estadoReproductivo,
      Value<String> origen,
      Value<double?> precioCompra,
      Value<DateTime?> fechaCompra,
      Value<String?> madreId,
      Value<double> concentradoKgDia,
      Value<DateTime?> fechaProbableParto,
      Value<DateTime?> retiroLecheHasta,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<bool> pendiente,
      Value<int> rowid,
    });

class $$AnimalesTableFilterComposer
    extends Composer<_$AppDatabase, $AnimalesTable> {
  $$AnimalesTableFilterComposer({
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

  ColumnFilters<String> get lecheriaId => $composableBuilder(
    column: $table.lecheriaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get identificador => $composableBuilder(
    column: $table.identificador,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sexo => $composableBuilder(
    column: $table.sexo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get grupo => $composableBuilder(
    column: $table.grupo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get estado => $composableBuilder(
    column: $table.estado,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get estadoReproductivo => $composableBuilder(
    column: $table.estadoReproductivo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get origen => $composableBuilder(
    column: $table.origen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get precioCompra => $composableBuilder(
    column: $table.precioCompra,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fechaCompra => $composableBuilder(
    column: $table.fechaCompra,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get madreId => $composableBuilder(
    column: $table.madreId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get concentradoKgDia => $composableBuilder(
    column: $table.concentradoKgDia,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fechaProbableParto => $composableBuilder(
    column: $table.fechaProbableParto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get retiroLecheHasta => $composableBuilder(
    column: $table.retiroLecheHasta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendiente => $composableBuilder(
    column: $table.pendiente,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AnimalesTableOrderingComposer
    extends Composer<_$AppDatabase, $AnimalesTable> {
  $$AnimalesTableOrderingComposer({
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

  ColumnOrderings<String> get lecheriaId => $composableBuilder(
    column: $table.lecheriaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get identificador => $composableBuilder(
    column: $table.identificador,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sexo => $composableBuilder(
    column: $table.sexo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get grupo => $composableBuilder(
    column: $table.grupo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get estado => $composableBuilder(
    column: $table.estado,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get estadoReproductivo => $composableBuilder(
    column: $table.estadoReproductivo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origen => $composableBuilder(
    column: $table.origen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get precioCompra => $composableBuilder(
    column: $table.precioCompra,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fechaCompra => $composableBuilder(
    column: $table.fechaCompra,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get madreId => $composableBuilder(
    column: $table.madreId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get concentradoKgDia => $composableBuilder(
    column: $table.concentradoKgDia,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fechaProbableParto => $composableBuilder(
    column: $table.fechaProbableParto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get retiroLecheHasta => $composableBuilder(
    column: $table.retiroLecheHasta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendiente => $composableBuilder(
    column: $table.pendiente,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AnimalesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AnimalesTable> {
  $$AnimalesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get lecheriaId => $composableBuilder(
    column: $table.lecheriaId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get identificador => $composableBuilder(
    column: $table.identificador,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sexo =>
      $composableBuilder(column: $table.sexo, builder: (column) => column);

  GeneratedColumn<String> get grupo =>
      $composableBuilder(column: $table.grupo, builder: (column) => column);

  GeneratedColumn<String> get estado =>
      $composableBuilder(column: $table.estado, builder: (column) => column);

  GeneratedColumn<String> get estadoReproductivo => $composableBuilder(
    column: $table.estadoReproductivo,
    builder: (column) => column,
  );

  GeneratedColumn<String> get origen =>
      $composableBuilder(column: $table.origen, builder: (column) => column);

  GeneratedColumn<double> get precioCompra => $composableBuilder(
    column: $table.precioCompra,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fechaCompra => $composableBuilder(
    column: $table.fechaCompra,
    builder: (column) => column,
  );

  GeneratedColumn<String> get madreId =>
      $composableBuilder(column: $table.madreId, builder: (column) => column);

  GeneratedColumn<double> get concentradoKgDia => $composableBuilder(
    column: $table.concentradoKgDia,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fechaProbableParto => $composableBuilder(
    column: $table.fechaProbableParto,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get retiroLecheHasta => $composableBuilder(
    column: $table.retiroLecheHasta,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<bool> get pendiente =>
      $composableBuilder(column: $table.pendiente, builder: (column) => column);
}

class $$AnimalesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AnimalesTable,
          AnimalRow,
          $$AnimalesTableFilterComposer,
          $$AnimalesTableOrderingComposer,
          $$AnimalesTableAnnotationComposer,
          $$AnimalesTableCreateCompanionBuilder,
          $$AnimalesTableUpdateCompanionBuilder,
          (AnimalRow, BaseReferences<_$AppDatabase, $AnimalesTable, AnimalRow>),
          AnimalRow,
          PrefetchHooks Function()
        > {
  $$AnimalesTableTableManager(_$AppDatabase db, $AnimalesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AnimalesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AnimalesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AnimalesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> lecheriaId = const Value.absent(),
                Value<String> identificador = const Value.absent(),
                Value<String> sexo = const Value.absent(),
                Value<String> grupo = const Value.absent(),
                Value<String> estado = const Value.absent(),
                Value<String> estadoReproductivo = const Value.absent(),
                Value<String> origen = const Value.absent(),
                Value<double?> precioCompra = const Value.absent(),
                Value<DateTime?> fechaCompra = const Value.absent(),
                Value<String?> madreId = const Value.absent(),
                Value<double> concentradoKgDia = const Value.absent(),
                Value<DateTime?> fechaProbableParto = const Value.absent(),
                Value<DateTime?> retiroLecheHasta = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<bool> pendiente = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AnimalesCompanion(
                id: id,
                lecheriaId: lecheriaId,
                identificador: identificador,
                sexo: sexo,
                grupo: grupo,
                estado: estado,
                estadoReproductivo: estadoReproductivo,
                origen: origen,
                precioCompra: precioCompra,
                fechaCompra: fechaCompra,
                madreId: madreId,
                concentradoKgDia: concentradoKgDia,
                fechaProbableParto: fechaProbableParto,
                retiroLecheHasta: retiroLecheHasta,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                pendiente: pendiente,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String lecheriaId,
                required String identificador,
                required String sexo,
                required String grupo,
                Value<String> estado = const Value.absent(),
                Value<String> estadoReproductivo = const Value.absent(),
                required String origen,
                Value<double?> precioCompra = const Value.absent(),
                Value<DateTime?> fechaCompra = const Value.absent(),
                Value<String?> madreId = const Value.absent(),
                Value<double> concentradoKgDia = const Value.absent(),
                Value<DateTime?> fechaProbableParto = const Value.absent(),
                Value<DateTime?> retiroLecheHasta = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<bool> pendiente = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AnimalesCompanion.insert(
                id: id,
                lecheriaId: lecheriaId,
                identificador: identificador,
                sexo: sexo,
                grupo: grupo,
                estado: estado,
                estadoReproductivo: estadoReproductivo,
                origen: origen,
                precioCompra: precioCompra,
                fechaCompra: fechaCompra,
                madreId: madreId,
                concentradoKgDia: concentradoKgDia,
                fechaProbableParto: fechaProbableParto,
                retiroLecheHasta: retiroLecheHasta,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                pendiente: pendiente,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AnimalesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AnimalesTable,
      AnimalRow,
      $$AnimalesTableFilterComposer,
      $$AnimalesTableOrderingComposer,
      $$AnimalesTableAnnotationComposer,
      $$AnimalesTableCreateCompanionBuilder,
      $$AnimalesTableUpdateCompanionBuilder,
      (AnimalRow, BaseReferences<_$AppDatabase, $AnimalesTable, AnimalRow>),
      AnimalRow,
      PrefetchHooks Function()
    >;
typedef $$EventosAnimalTableCreateCompanionBuilder =
    EventosAnimalCompanion Function({
      required String id,
      required String animalId,
      required String lecheriaId,
      required String tipo,
      required DateTime fecha,
      Value<String?> detalle,
      Value<String?> medicamentoId,
      Value<String?> dosis,
      Value<int?> diasRetiro,
      Value<double?> costo,
      Value<String?> resultado,
      Value<String?> toroPajilla,
      Value<String?> sexoCria,
      Value<String?> grupoAnterior,
      Value<String?> grupoNuevo,
      Value<String?> motivoBaja,
      Value<double?> precioVenta,
      Value<String?> criaAnimalId,
      Value<String?> registradoPor,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<bool> pendiente,
      Value<int> rowid,
    });
typedef $$EventosAnimalTableUpdateCompanionBuilder =
    EventosAnimalCompanion Function({
      Value<String> id,
      Value<String> animalId,
      Value<String> lecheriaId,
      Value<String> tipo,
      Value<DateTime> fecha,
      Value<String?> detalle,
      Value<String?> medicamentoId,
      Value<String?> dosis,
      Value<int?> diasRetiro,
      Value<double?> costo,
      Value<String?> resultado,
      Value<String?> toroPajilla,
      Value<String?> sexoCria,
      Value<String?> grupoAnterior,
      Value<String?> grupoNuevo,
      Value<String?> motivoBaja,
      Value<double?> precioVenta,
      Value<String?> criaAnimalId,
      Value<String?> registradoPor,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<bool> pendiente,
      Value<int> rowid,
    });

class $$EventosAnimalTableFilterComposer
    extends Composer<_$AppDatabase, $EventosAnimalTable> {
  $$EventosAnimalTableFilterComposer({
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

  ColumnFilters<String> get animalId => $composableBuilder(
    column: $table.animalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lecheriaId => $composableBuilder(
    column: $table.lecheriaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get detalle => $composableBuilder(
    column: $table.detalle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get medicamentoId => $composableBuilder(
    column: $table.medicamentoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dosis => $composableBuilder(
    column: $table.dosis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get diasRetiro => $composableBuilder(
    column: $table.diasRetiro,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get costo => $composableBuilder(
    column: $table.costo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resultado => $composableBuilder(
    column: $table.resultado,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toroPajilla => $composableBuilder(
    column: $table.toroPajilla,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sexoCria => $composableBuilder(
    column: $table.sexoCria,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get grupoAnterior => $composableBuilder(
    column: $table.grupoAnterior,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get grupoNuevo => $composableBuilder(
    column: $table.grupoNuevo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get motivoBaja => $composableBuilder(
    column: $table.motivoBaja,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get precioVenta => $composableBuilder(
    column: $table.precioVenta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get criaAnimalId => $composableBuilder(
    column: $table.criaAnimalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get registradoPor => $composableBuilder(
    column: $table.registradoPor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendiente => $composableBuilder(
    column: $table.pendiente,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EventosAnimalTableOrderingComposer
    extends Composer<_$AppDatabase, $EventosAnimalTable> {
  $$EventosAnimalTableOrderingComposer({
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

  ColumnOrderings<String> get animalId => $composableBuilder(
    column: $table.animalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lecheriaId => $composableBuilder(
    column: $table.lecheriaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get detalle => $composableBuilder(
    column: $table.detalle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get medicamentoId => $composableBuilder(
    column: $table.medicamentoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dosis => $composableBuilder(
    column: $table.dosis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get diasRetiro => $composableBuilder(
    column: $table.diasRetiro,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get costo => $composableBuilder(
    column: $table.costo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resultado => $composableBuilder(
    column: $table.resultado,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toroPajilla => $composableBuilder(
    column: $table.toroPajilla,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sexoCria => $composableBuilder(
    column: $table.sexoCria,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get grupoAnterior => $composableBuilder(
    column: $table.grupoAnterior,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get grupoNuevo => $composableBuilder(
    column: $table.grupoNuevo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get motivoBaja => $composableBuilder(
    column: $table.motivoBaja,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get precioVenta => $composableBuilder(
    column: $table.precioVenta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get criaAnimalId => $composableBuilder(
    column: $table.criaAnimalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get registradoPor => $composableBuilder(
    column: $table.registradoPor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendiente => $composableBuilder(
    column: $table.pendiente,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EventosAnimalTableAnnotationComposer
    extends Composer<_$AppDatabase, $EventosAnimalTable> {
  $$EventosAnimalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get animalId =>
      $composableBuilder(column: $table.animalId, builder: (column) => column);

  GeneratedColumn<String> get lecheriaId => $composableBuilder(
    column: $table.lecheriaId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<DateTime> get fecha =>
      $composableBuilder(column: $table.fecha, builder: (column) => column);

  GeneratedColumn<String> get detalle =>
      $composableBuilder(column: $table.detalle, builder: (column) => column);

  GeneratedColumn<String> get medicamentoId => $composableBuilder(
    column: $table.medicamentoId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dosis =>
      $composableBuilder(column: $table.dosis, builder: (column) => column);

  GeneratedColumn<int> get diasRetiro => $composableBuilder(
    column: $table.diasRetiro,
    builder: (column) => column,
  );

  GeneratedColumn<double> get costo =>
      $composableBuilder(column: $table.costo, builder: (column) => column);

  GeneratedColumn<String> get resultado =>
      $composableBuilder(column: $table.resultado, builder: (column) => column);

  GeneratedColumn<String> get toroPajilla => $composableBuilder(
    column: $table.toroPajilla,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sexoCria =>
      $composableBuilder(column: $table.sexoCria, builder: (column) => column);

  GeneratedColumn<String> get grupoAnterior => $composableBuilder(
    column: $table.grupoAnterior,
    builder: (column) => column,
  );

  GeneratedColumn<String> get grupoNuevo => $composableBuilder(
    column: $table.grupoNuevo,
    builder: (column) => column,
  );

  GeneratedColumn<String> get motivoBaja => $composableBuilder(
    column: $table.motivoBaja,
    builder: (column) => column,
  );

  GeneratedColumn<double> get precioVenta => $composableBuilder(
    column: $table.precioVenta,
    builder: (column) => column,
  );

  GeneratedColumn<String> get criaAnimalId => $composableBuilder(
    column: $table.criaAnimalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get registradoPor => $composableBuilder(
    column: $table.registradoPor,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<bool> get pendiente =>
      $composableBuilder(column: $table.pendiente, builder: (column) => column);
}

class $$EventosAnimalTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EventosAnimalTable,
          EventoAnimalRow,
          $$EventosAnimalTableFilterComposer,
          $$EventosAnimalTableOrderingComposer,
          $$EventosAnimalTableAnnotationComposer,
          $$EventosAnimalTableCreateCompanionBuilder,
          $$EventosAnimalTableUpdateCompanionBuilder,
          (
            EventoAnimalRow,
            BaseReferences<_$AppDatabase, $EventosAnimalTable, EventoAnimalRow>,
          ),
          EventoAnimalRow,
          PrefetchHooks Function()
        > {
  $$EventosAnimalTableTableManager(_$AppDatabase db, $EventosAnimalTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventosAnimalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventosAnimalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventosAnimalTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> animalId = const Value.absent(),
                Value<String> lecheriaId = const Value.absent(),
                Value<String> tipo = const Value.absent(),
                Value<DateTime> fecha = const Value.absent(),
                Value<String?> detalle = const Value.absent(),
                Value<String?> medicamentoId = const Value.absent(),
                Value<String?> dosis = const Value.absent(),
                Value<int?> diasRetiro = const Value.absent(),
                Value<double?> costo = const Value.absent(),
                Value<String?> resultado = const Value.absent(),
                Value<String?> toroPajilla = const Value.absent(),
                Value<String?> sexoCria = const Value.absent(),
                Value<String?> grupoAnterior = const Value.absent(),
                Value<String?> grupoNuevo = const Value.absent(),
                Value<String?> motivoBaja = const Value.absent(),
                Value<double?> precioVenta = const Value.absent(),
                Value<String?> criaAnimalId = const Value.absent(),
                Value<String?> registradoPor = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<bool> pendiente = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventosAnimalCompanion(
                id: id,
                animalId: animalId,
                lecheriaId: lecheriaId,
                tipo: tipo,
                fecha: fecha,
                detalle: detalle,
                medicamentoId: medicamentoId,
                dosis: dosis,
                diasRetiro: diasRetiro,
                costo: costo,
                resultado: resultado,
                toroPajilla: toroPajilla,
                sexoCria: sexoCria,
                grupoAnterior: grupoAnterior,
                grupoNuevo: grupoNuevo,
                motivoBaja: motivoBaja,
                precioVenta: precioVenta,
                criaAnimalId: criaAnimalId,
                registradoPor: registradoPor,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                pendiente: pendiente,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String animalId,
                required String lecheriaId,
                required String tipo,
                required DateTime fecha,
                Value<String?> detalle = const Value.absent(),
                Value<String?> medicamentoId = const Value.absent(),
                Value<String?> dosis = const Value.absent(),
                Value<int?> diasRetiro = const Value.absent(),
                Value<double?> costo = const Value.absent(),
                Value<String?> resultado = const Value.absent(),
                Value<String?> toroPajilla = const Value.absent(),
                Value<String?> sexoCria = const Value.absent(),
                Value<String?> grupoAnterior = const Value.absent(),
                Value<String?> grupoNuevo = const Value.absent(),
                Value<String?> motivoBaja = const Value.absent(),
                Value<double?> precioVenta = const Value.absent(),
                Value<String?> criaAnimalId = const Value.absent(),
                Value<String?> registradoPor = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<bool> pendiente = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventosAnimalCompanion.insert(
                id: id,
                animalId: animalId,
                lecheriaId: lecheriaId,
                tipo: tipo,
                fecha: fecha,
                detalle: detalle,
                medicamentoId: medicamentoId,
                dosis: dosis,
                diasRetiro: diasRetiro,
                costo: costo,
                resultado: resultado,
                toroPajilla: toroPajilla,
                sexoCria: sexoCria,
                grupoAnterior: grupoAnterior,
                grupoNuevo: grupoNuevo,
                motivoBaja: motivoBaja,
                precioVenta: precioVenta,
                criaAnimalId: criaAnimalId,
                registradoPor: registradoPor,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                pendiente: pendiente,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EventosAnimalTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EventosAnimalTable,
      EventoAnimalRow,
      $$EventosAnimalTableFilterComposer,
      $$EventosAnimalTableOrderingComposer,
      $$EventosAnimalTableAnnotationComposer,
      $$EventosAnimalTableCreateCompanionBuilder,
      $$EventosAnimalTableUpdateCompanionBuilder,
      (
        EventoAnimalRow,
        BaseReferences<_$AppDatabase, $EventosAnimalTable, EventoAnimalRow>,
      ),
      EventoAnimalRow,
      PrefetchHooks Function()
    >;
typedef $$PesasSesionesTableCreateCompanionBuilder =
    PesasSesionesCompanion Function({
      required String id,
      required String lecheriaId,
      required DateTime fecha,
      Value<bool> cerrada,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<bool> pendiente,
      Value<int> rowid,
    });
typedef $$PesasSesionesTableUpdateCompanionBuilder =
    PesasSesionesCompanion Function({
      Value<String> id,
      Value<String> lecheriaId,
      Value<DateTime> fecha,
      Value<bool> cerrada,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<bool> pendiente,
      Value<int> rowid,
    });

class $$PesasSesionesTableFilterComposer
    extends Composer<_$AppDatabase, $PesasSesionesTable> {
  $$PesasSesionesTableFilterComposer({
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

  ColumnFilters<String> get lecheriaId => $composableBuilder(
    column: $table.lecheriaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get cerrada => $composableBuilder(
    column: $table.cerrada,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendiente => $composableBuilder(
    column: $table.pendiente,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PesasSesionesTableOrderingComposer
    extends Composer<_$AppDatabase, $PesasSesionesTable> {
  $$PesasSesionesTableOrderingComposer({
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

  ColumnOrderings<String> get lecheriaId => $composableBuilder(
    column: $table.lecheriaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get cerrada => $composableBuilder(
    column: $table.cerrada,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendiente => $composableBuilder(
    column: $table.pendiente,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PesasSesionesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PesasSesionesTable> {
  $$PesasSesionesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get lecheriaId => $composableBuilder(
    column: $table.lecheriaId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fecha =>
      $composableBuilder(column: $table.fecha, builder: (column) => column);

  GeneratedColumn<bool> get cerrada =>
      $composableBuilder(column: $table.cerrada, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<bool> get pendiente =>
      $composableBuilder(column: $table.pendiente, builder: (column) => column);
}

class $$PesasSesionesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PesasSesionesTable,
          PesaSesionRow,
          $$PesasSesionesTableFilterComposer,
          $$PesasSesionesTableOrderingComposer,
          $$PesasSesionesTableAnnotationComposer,
          $$PesasSesionesTableCreateCompanionBuilder,
          $$PesasSesionesTableUpdateCompanionBuilder,
          (
            PesaSesionRow,
            BaseReferences<_$AppDatabase, $PesasSesionesTable, PesaSesionRow>,
          ),
          PesaSesionRow,
          PrefetchHooks Function()
        > {
  $$PesasSesionesTableTableManager(_$AppDatabase db, $PesasSesionesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PesasSesionesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PesasSesionesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PesasSesionesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> lecheriaId = const Value.absent(),
                Value<DateTime> fecha = const Value.absent(),
                Value<bool> cerrada = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<bool> pendiente = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PesasSesionesCompanion(
                id: id,
                lecheriaId: lecheriaId,
                fecha: fecha,
                cerrada: cerrada,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                pendiente: pendiente,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String lecheriaId,
                required DateTime fecha,
                Value<bool> cerrada = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<bool> pendiente = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PesasSesionesCompanion.insert(
                id: id,
                lecheriaId: lecheriaId,
                fecha: fecha,
                cerrada: cerrada,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                pendiente: pendiente,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PesasSesionesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PesasSesionesTable,
      PesaSesionRow,
      $$PesasSesionesTableFilterComposer,
      $$PesasSesionesTableOrderingComposer,
      $$PesasSesionesTableAnnotationComposer,
      $$PesasSesionesTableCreateCompanionBuilder,
      $$PesasSesionesTableUpdateCompanionBuilder,
      (
        PesaSesionRow,
        BaseReferences<_$AppDatabase, $PesasSesionesTable, PesaSesionRow>,
      ),
      PesaSesionRow,
      PrefetchHooks Function()
    >;
typedef $$PesasLecheTableCreateCompanionBuilder =
    PesasLecheCompanion Function({
      required String id,
      required String sesionId,
      required String animalId,
      required double litros,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<bool> pendiente,
      Value<int> rowid,
    });
typedef $$PesasLecheTableUpdateCompanionBuilder =
    PesasLecheCompanion Function({
      Value<String> id,
      Value<String> sesionId,
      Value<String> animalId,
      Value<double> litros,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<bool> pendiente,
      Value<int> rowid,
    });

class $$PesasLecheTableFilterComposer
    extends Composer<_$AppDatabase, $PesasLecheTable> {
  $$PesasLecheTableFilterComposer({
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

  ColumnFilters<String> get sesionId => $composableBuilder(
    column: $table.sesionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get animalId => $composableBuilder(
    column: $table.animalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get litros => $composableBuilder(
    column: $table.litros,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendiente => $composableBuilder(
    column: $table.pendiente,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PesasLecheTableOrderingComposer
    extends Composer<_$AppDatabase, $PesasLecheTable> {
  $$PesasLecheTableOrderingComposer({
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

  ColumnOrderings<String> get sesionId => $composableBuilder(
    column: $table.sesionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get animalId => $composableBuilder(
    column: $table.animalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get litros => $composableBuilder(
    column: $table.litros,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendiente => $composableBuilder(
    column: $table.pendiente,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PesasLecheTableAnnotationComposer
    extends Composer<_$AppDatabase, $PesasLecheTable> {
  $$PesasLecheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sesionId =>
      $composableBuilder(column: $table.sesionId, builder: (column) => column);

  GeneratedColumn<String> get animalId =>
      $composableBuilder(column: $table.animalId, builder: (column) => column);

  GeneratedColumn<double> get litros =>
      $composableBuilder(column: $table.litros, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<bool> get pendiente =>
      $composableBuilder(column: $table.pendiente, builder: (column) => column);
}

class $$PesasLecheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PesasLecheTable,
          PesaLecheRow,
          $$PesasLecheTableFilterComposer,
          $$PesasLecheTableOrderingComposer,
          $$PesasLecheTableAnnotationComposer,
          $$PesasLecheTableCreateCompanionBuilder,
          $$PesasLecheTableUpdateCompanionBuilder,
          (
            PesaLecheRow,
            BaseReferences<_$AppDatabase, $PesasLecheTable, PesaLecheRow>,
          ),
          PesaLecheRow,
          PrefetchHooks Function()
        > {
  $$PesasLecheTableTableManager(_$AppDatabase db, $PesasLecheTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PesasLecheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PesasLecheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PesasLecheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sesionId = const Value.absent(),
                Value<String> animalId = const Value.absent(),
                Value<double> litros = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<bool> pendiente = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PesasLecheCompanion(
                id: id,
                sesionId: sesionId,
                animalId: animalId,
                litros: litros,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                pendiente: pendiente,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sesionId,
                required String animalId,
                required double litros,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<bool> pendiente = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PesasLecheCompanion.insert(
                id: id,
                sesionId: sesionId,
                animalId: animalId,
                litros: litros,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                pendiente: pendiente,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PesasLecheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PesasLecheTable,
      PesaLecheRow,
      $$PesasLecheTableFilterComposer,
      $$PesasLecheTableOrderingComposer,
      $$PesasLecheTableAnnotationComposer,
      $$PesasLecheTableCreateCompanionBuilder,
      $$PesasLecheTableUpdateCompanionBuilder,
      (
        PesaLecheRow,
        BaseReferences<_$AppDatabase, $PesasLecheTable, PesaLecheRow>,
      ),
      PesaLecheRow,
      PrefetchHooks Function()
    >;
typedef $$ParametrosPeriodoTableCreateCompanionBuilder =
    ParametrosPeriodoCompanion Function({
      required String id,
      required String lecheriaId,
      required int anio,
      required int mes,
      required double precioLitro,
      required double precioConcentradoKg,
      Value<double> umbralSecadoLitros,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<bool> pendiente,
      Value<int> rowid,
    });
typedef $$ParametrosPeriodoTableUpdateCompanionBuilder =
    ParametrosPeriodoCompanion Function({
      Value<String> id,
      Value<String> lecheriaId,
      Value<int> anio,
      Value<int> mes,
      Value<double> precioLitro,
      Value<double> precioConcentradoKg,
      Value<double> umbralSecadoLitros,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<bool> pendiente,
      Value<int> rowid,
    });

class $$ParametrosPeriodoTableFilterComposer
    extends Composer<_$AppDatabase, $ParametrosPeriodoTable> {
  $$ParametrosPeriodoTableFilterComposer({
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

  ColumnFilters<String> get lecheriaId => $composableBuilder(
    column: $table.lecheriaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get anio => $composableBuilder(
    column: $table.anio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mes => $composableBuilder(
    column: $table.mes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get precioLitro => $composableBuilder(
    column: $table.precioLitro,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get precioConcentradoKg => $composableBuilder(
    column: $table.precioConcentradoKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get umbralSecadoLitros => $composableBuilder(
    column: $table.umbralSecadoLitros,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendiente => $composableBuilder(
    column: $table.pendiente,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ParametrosPeriodoTableOrderingComposer
    extends Composer<_$AppDatabase, $ParametrosPeriodoTable> {
  $$ParametrosPeriodoTableOrderingComposer({
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

  ColumnOrderings<String> get lecheriaId => $composableBuilder(
    column: $table.lecheriaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get anio => $composableBuilder(
    column: $table.anio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mes => $composableBuilder(
    column: $table.mes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get precioLitro => $composableBuilder(
    column: $table.precioLitro,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get precioConcentradoKg => $composableBuilder(
    column: $table.precioConcentradoKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get umbralSecadoLitros => $composableBuilder(
    column: $table.umbralSecadoLitros,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendiente => $composableBuilder(
    column: $table.pendiente,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ParametrosPeriodoTableAnnotationComposer
    extends Composer<_$AppDatabase, $ParametrosPeriodoTable> {
  $$ParametrosPeriodoTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get lecheriaId => $composableBuilder(
    column: $table.lecheriaId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get anio =>
      $composableBuilder(column: $table.anio, builder: (column) => column);

  GeneratedColumn<int> get mes =>
      $composableBuilder(column: $table.mes, builder: (column) => column);

  GeneratedColumn<double> get precioLitro => $composableBuilder(
    column: $table.precioLitro,
    builder: (column) => column,
  );

  GeneratedColumn<double> get precioConcentradoKg => $composableBuilder(
    column: $table.precioConcentradoKg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get umbralSecadoLitros => $composableBuilder(
    column: $table.umbralSecadoLitros,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<bool> get pendiente =>
      $composableBuilder(column: $table.pendiente, builder: (column) => column);
}

class $$ParametrosPeriodoTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ParametrosPeriodoTable,
          ParametrosPeriodoRow,
          $$ParametrosPeriodoTableFilterComposer,
          $$ParametrosPeriodoTableOrderingComposer,
          $$ParametrosPeriodoTableAnnotationComposer,
          $$ParametrosPeriodoTableCreateCompanionBuilder,
          $$ParametrosPeriodoTableUpdateCompanionBuilder,
          (
            ParametrosPeriodoRow,
            BaseReferences<
              _$AppDatabase,
              $ParametrosPeriodoTable,
              ParametrosPeriodoRow
            >,
          ),
          ParametrosPeriodoRow,
          PrefetchHooks Function()
        > {
  $$ParametrosPeriodoTableTableManager(
    _$AppDatabase db,
    $ParametrosPeriodoTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ParametrosPeriodoTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ParametrosPeriodoTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ParametrosPeriodoTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> lecheriaId = const Value.absent(),
                Value<int> anio = const Value.absent(),
                Value<int> mes = const Value.absent(),
                Value<double> precioLitro = const Value.absent(),
                Value<double> precioConcentradoKg = const Value.absent(),
                Value<double> umbralSecadoLitros = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<bool> pendiente = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ParametrosPeriodoCompanion(
                id: id,
                lecheriaId: lecheriaId,
                anio: anio,
                mes: mes,
                precioLitro: precioLitro,
                precioConcentradoKg: precioConcentradoKg,
                umbralSecadoLitros: umbralSecadoLitros,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                pendiente: pendiente,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String lecheriaId,
                required int anio,
                required int mes,
                required double precioLitro,
                required double precioConcentradoKg,
                Value<double> umbralSecadoLitros = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<bool> pendiente = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ParametrosPeriodoCompanion.insert(
                id: id,
                lecheriaId: lecheriaId,
                anio: anio,
                mes: mes,
                precioLitro: precioLitro,
                precioConcentradoKg: precioConcentradoKg,
                umbralSecadoLitros: umbralSecadoLitros,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                pendiente: pendiente,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ParametrosPeriodoTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ParametrosPeriodoTable,
      ParametrosPeriodoRow,
      $$ParametrosPeriodoTableFilterComposer,
      $$ParametrosPeriodoTableOrderingComposer,
      $$ParametrosPeriodoTableAnnotationComposer,
      $$ParametrosPeriodoTableCreateCompanionBuilder,
      $$ParametrosPeriodoTableUpdateCompanionBuilder,
      (
        ParametrosPeriodoRow,
        BaseReferences<
          _$AppDatabase,
          $ParametrosPeriodoTable,
          ParametrosPeriodoRow
        >,
      ),
      ParametrosPeriodoRow,
      PrefetchHooks Function()
    >;
typedef $$CostosFijosTableCreateCompanionBuilder =
    CostosFijosCompanion Function({
      required String id,
      required String lecheriaId,
      required String periodoId,
      required String categoria,
      required double monto,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<bool> pendiente,
      Value<int> rowid,
    });
typedef $$CostosFijosTableUpdateCompanionBuilder =
    CostosFijosCompanion Function({
      Value<String> id,
      Value<String> lecheriaId,
      Value<String> periodoId,
      Value<String> categoria,
      Value<double> monto,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<bool> pendiente,
      Value<int> rowid,
    });

class $$CostosFijosTableFilterComposer
    extends Composer<_$AppDatabase, $CostosFijosTable> {
  $$CostosFijosTableFilterComposer({
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

  ColumnFilters<String> get lecheriaId => $composableBuilder(
    column: $table.lecheriaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get periodoId => $composableBuilder(
    column: $table.periodoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoria => $composableBuilder(
    column: $table.categoria,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get monto => $composableBuilder(
    column: $table.monto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendiente => $composableBuilder(
    column: $table.pendiente,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CostosFijosTableOrderingComposer
    extends Composer<_$AppDatabase, $CostosFijosTable> {
  $$CostosFijosTableOrderingComposer({
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

  ColumnOrderings<String> get lecheriaId => $composableBuilder(
    column: $table.lecheriaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get periodoId => $composableBuilder(
    column: $table.periodoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoria => $composableBuilder(
    column: $table.categoria,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get monto => $composableBuilder(
    column: $table.monto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendiente => $composableBuilder(
    column: $table.pendiente,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CostosFijosTableAnnotationComposer
    extends Composer<_$AppDatabase, $CostosFijosTable> {
  $$CostosFijosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get lecheriaId => $composableBuilder(
    column: $table.lecheriaId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get periodoId =>
      $composableBuilder(column: $table.periodoId, builder: (column) => column);

  GeneratedColumn<String> get categoria =>
      $composableBuilder(column: $table.categoria, builder: (column) => column);

  GeneratedColumn<double> get monto =>
      $composableBuilder(column: $table.monto, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<bool> get pendiente =>
      $composableBuilder(column: $table.pendiente, builder: (column) => column);
}

class $$CostosFijosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CostosFijosTable,
          CostoFijoRow,
          $$CostosFijosTableFilterComposer,
          $$CostosFijosTableOrderingComposer,
          $$CostosFijosTableAnnotationComposer,
          $$CostosFijosTableCreateCompanionBuilder,
          $$CostosFijosTableUpdateCompanionBuilder,
          (
            CostoFijoRow,
            BaseReferences<_$AppDatabase, $CostosFijosTable, CostoFijoRow>,
          ),
          CostoFijoRow,
          PrefetchHooks Function()
        > {
  $$CostosFijosTableTableManager(_$AppDatabase db, $CostosFijosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CostosFijosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CostosFijosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CostosFijosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> lecheriaId = const Value.absent(),
                Value<String> periodoId = const Value.absent(),
                Value<String> categoria = const Value.absent(),
                Value<double> monto = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<bool> pendiente = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CostosFijosCompanion(
                id: id,
                lecheriaId: lecheriaId,
                periodoId: periodoId,
                categoria: categoria,
                monto: monto,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                pendiente: pendiente,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String lecheriaId,
                required String periodoId,
                required String categoria,
                required double monto,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<bool> pendiente = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CostosFijosCompanion.insert(
                id: id,
                lecheriaId: lecheriaId,
                periodoId: periodoId,
                categoria: categoria,
                monto: monto,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                pendiente: pendiente,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CostosFijosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CostosFijosTable,
      CostoFijoRow,
      $$CostosFijosTableFilterComposer,
      $$CostosFijosTableOrderingComposer,
      $$CostosFijosTableAnnotationComposer,
      $$CostosFijosTableCreateCompanionBuilder,
      $$CostosFijosTableUpdateCompanionBuilder,
      (
        CostoFijoRow,
        BaseReferences<_$AppDatabase, $CostosFijosTable, CostoFijoRow>,
      ),
      CostoFijoRow,
      PrefetchHooks Function()
    >;
typedef $$MedicamentosTableCreateCompanionBuilder =
    MedicamentosCompanion Function({
      required String id,
      required String lecheriaId,
      required String nombre,
      required double costoEnvase,
      required String tipoDosis,
      Value<double?> mlEnvase,
      Value<double?> aplicacionesEnvase,
      Value<double?> dosisFijaMl,
      Value<int> diasRetiroLeche,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<bool> pendiente,
      Value<int> rowid,
    });
typedef $$MedicamentosTableUpdateCompanionBuilder =
    MedicamentosCompanion Function({
      Value<String> id,
      Value<String> lecheriaId,
      Value<String> nombre,
      Value<double> costoEnvase,
      Value<String> tipoDosis,
      Value<double?> mlEnvase,
      Value<double?> aplicacionesEnvase,
      Value<double?> dosisFijaMl,
      Value<int> diasRetiroLeche,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<bool> pendiente,
      Value<int> rowid,
    });

class $$MedicamentosTableFilterComposer
    extends Composer<_$AppDatabase, $MedicamentosTable> {
  $$MedicamentosTableFilterComposer({
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

  ColumnFilters<String> get lecheriaId => $composableBuilder(
    column: $table.lecheriaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get costoEnvase => $composableBuilder(
    column: $table.costoEnvase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipoDosis => $composableBuilder(
    column: $table.tipoDosis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get mlEnvase => $composableBuilder(
    column: $table.mlEnvase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get aplicacionesEnvase => $composableBuilder(
    column: $table.aplicacionesEnvase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get dosisFijaMl => $composableBuilder(
    column: $table.dosisFijaMl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get diasRetiroLeche => $composableBuilder(
    column: $table.diasRetiroLeche,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendiente => $composableBuilder(
    column: $table.pendiente,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MedicamentosTableOrderingComposer
    extends Composer<_$AppDatabase, $MedicamentosTable> {
  $$MedicamentosTableOrderingComposer({
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

  ColumnOrderings<String> get lecheriaId => $composableBuilder(
    column: $table.lecheriaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get costoEnvase => $composableBuilder(
    column: $table.costoEnvase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipoDosis => $composableBuilder(
    column: $table.tipoDosis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get mlEnvase => $composableBuilder(
    column: $table.mlEnvase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get aplicacionesEnvase => $composableBuilder(
    column: $table.aplicacionesEnvase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get dosisFijaMl => $composableBuilder(
    column: $table.dosisFijaMl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get diasRetiroLeche => $composableBuilder(
    column: $table.diasRetiroLeche,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendiente => $composableBuilder(
    column: $table.pendiente,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MedicamentosTableAnnotationComposer
    extends Composer<_$AppDatabase, $MedicamentosTable> {
  $$MedicamentosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get lecheriaId => $composableBuilder(
    column: $table.lecheriaId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<double> get costoEnvase => $composableBuilder(
    column: $table.costoEnvase,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tipoDosis =>
      $composableBuilder(column: $table.tipoDosis, builder: (column) => column);

  GeneratedColumn<double> get mlEnvase =>
      $composableBuilder(column: $table.mlEnvase, builder: (column) => column);

  GeneratedColumn<double> get aplicacionesEnvase => $composableBuilder(
    column: $table.aplicacionesEnvase,
    builder: (column) => column,
  );

  GeneratedColumn<double> get dosisFijaMl => $composableBuilder(
    column: $table.dosisFijaMl,
    builder: (column) => column,
  );

  GeneratedColumn<int> get diasRetiroLeche => $composableBuilder(
    column: $table.diasRetiroLeche,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<bool> get pendiente =>
      $composableBuilder(column: $table.pendiente, builder: (column) => column);
}

class $$MedicamentosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MedicamentosTable,
          MedicamentoRow,
          $$MedicamentosTableFilterComposer,
          $$MedicamentosTableOrderingComposer,
          $$MedicamentosTableAnnotationComposer,
          $$MedicamentosTableCreateCompanionBuilder,
          $$MedicamentosTableUpdateCompanionBuilder,
          (
            MedicamentoRow,
            BaseReferences<_$AppDatabase, $MedicamentosTable, MedicamentoRow>,
          ),
          MedicamentoRow,
          PrefetchHooks Function()
        > {
  $$MedicamentosTableTableManager(_$AppDatabase db, $MedicamentosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MedicamentosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MedicamentosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MedicamentosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> lecheriaId = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<double> costoEnvase = const Value.absent(),
                Value<String> tipoDosis = const Value.absent(),
                Value<double?> mlEnvase = const Value.absent(),
                Value<double?> aplicacionesEnvase = const Value.absent(),
                Value<double?> dosisFijaMl = const Value.absent(),
                Value<int> diasRetiroLeche = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<bool> pendiente = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MedicamentosCompanion(
                id: id,
                lecheriaId: lecheriaId,
                nombre: nombre,
                costoEnvase: costoEnvase,
                tipoDosis: tipoDosis,
                mlEnvase: mlEnvase,
                aplicacionesEnvase: aplicacionesEnvase,
                dosisFijaMl: dosisFijaMl,
                diasRetiroLeche: diasRetiroLeche,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                pendiente: pendiente,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String lecheriaId,
                required String nombre,
                required double costoEnvase,
                required String tipoDosis,
                Value<double?> mlEnvase = const Value.absent(),
                Value<double?> aplicacionesEnvase = const Value.absent(),
                Value<double?> dosisFijaMl = const Value.absent(),
                Value<int> diasRetiroLeche = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<bool> pendiente = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MedicamentosCompanion.insert(
                id: id,
                lecheriaId: lecheriaId,
                nombre: nombre,
                costoEnvase: costoEnvase,
                tipoDosis: tipoDosis,
                mlEnvase: mlEnvase,
                aplicacionesEnvase: aplicacionesEnvase,
                dosisFijaMl: dosisFijaMl,
                diasRetiroLeche: diasRetiroLeche,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                pendiente: pendiente,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MedicamentosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MedicamentosTable,
      MedicamentoRow,
      $$MedicamentosTableFilterComposer,
      $$MedicamentosTableOrderingComposer,
      $$MedicamentosTableAnnotationComposer,
      $$MedicamentosTableCreateCompanionBuilder,
      $$MedicamentosTableUpdateCompanionBuilder,
      (
        MedicamentoRow,
        BaseReferences<_$AppDatabase, $MedicamentosTable, MedicamentoRow>,
      ),
      MedicamentoRow,
      PrefetchHooks Function()
    >;
typedef $$ConfigAlertasTableCreateCompanionBuilder =
    ConfigAlertasCompanion Function({
      required String id,
      required String lecheriaId,
      Value<int> diasCeloEsperado,
      Value<int> diasConfirmarPreniez,
      Value<int> diasVaciosAltos,
      Value<int> diasAntesSecar,
      Value<int> diasAntesParto,
      Value<int> diasAvisoFinRetiro,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<bool> pendiente,
      Value<int> rowid,
    });
typedef $$ConfigAlertasTableUpdateCompanionBuilder =
    ConfigAlertasCompanion Function({
      Value<String> id,
      Value<String> lecheriaId,
      Value<int> diasCeloEsperado,
      Value<int> diasConfirmarPreniez,
      Value<int> diasVaciosAltos,
      Value<int> diasAntesSecar,
      Value<int> diasAntesParto,
      Value<int> diasAvisoFinRetiro,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<bool> pendiente,
      Value<int> rowid,
    });

class $$ConfigAlertasTableFilterComposer
    extends Composer<_$AppDatabase, $ConfigAlertasTable> {
  $$ConfigAlertasTableFilterComposer({
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

  ColumnFilters<String> get lecheriaId => $composableBuilder(
    column: $table.lecheriaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get diasCeloEsperado => $composableBuilder(
    column: $table.diasCeloEsperado,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get diasConfirmarPreniez => $composableBuilder(
    column: $table.diasConfirmarPreniez,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get diasVaciosAltos => $composableBuilder(
    column: $table.diasVaciosAltos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get diasAntesSecar => $composableBuilder(
    column: $table.diasAntesSecar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get diasAntesParto => $composableBuilder(
    column: $table.diasAntesParto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get diasAvisoFinRetiro => $composableBuilder(
    column: $table.diasAvisoFinRetiro,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendiente => $composableBuilder(
    column: $table.pendiente,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ConfigAlertasTableOrderingComposer
    extends Composer<_$AppDatabase, $ConfigAlertasTable> {
  $$ConfigAlertasTableOrderingComposer({
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

  ColumnOrderings<String> get lecheriaId => $composableBuilder(
    column: $table.lecheriaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get diasCeloEsperado => $composableBuilder(
    column: $table.diasCeloEsperado,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get diasConfirmarPreniez => $composableBuilder(
    column: $table.diasConfirmarPreniez,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get diasVaciosAltos => $composableBuilder(
    column: $table.diasVaciosAltos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get diasAntesSecar => $composableBuilder(
    column: $table.diasAntesSecar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get diasAntesParto => $composableBuilder(
    column: $table.diasAntesParto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get diasAvisoFinRetiro => $composableBuilder(
    column: $table.diasAvisoFinRetiro,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendiente => $composableBuilder(
    column: $table.pendiente,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConfigAlertasTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConfigAlertasTable> {
  $$ConfigAlertasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get lecheriaId => $composableBuilder(
    column: $table.lecheriaId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get diasCeloEsperado => $composableBuilder(
    column: $table.diasCeloEsperado,
    builder: (column) => column,
  );

  GeneratedColumn<int> get diasConfirmarPreniez => $composableBuilder(
    column: $table.diasConfirmarPreniez,
    builder: (column) => column,
  );

  GeneratedColumn<int> get diasVaciosAltos => $composableBuilder(
    column: $table.diasVaciosAltos,
    builder: (column) => column,
  );

  GeneratedColumn<int> get diasAntesSecar => $composableBuilder(
    column: $table.diasAntesSecar,
    builder: (column) => column,
  );

  GeneratedColumn<int> get diasAntesParto => $composableBuilder(
    column: $table.diasAntesParto,
    builder: (column) => column,
  );

  GeneratedColumn<int> get diasAvisoFinRetiro => $composableBuilder(
    column: $table.diasAvisoFinRetiro,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<bool> get pendiente =>
      $composableBuilder(column: $table.pendiente, builder: (column) => column);
}

class $$ConfigAlertasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConfigAlertasTable,
          ConfigAlertaRow,
          $$ConfigAlertasTableFilterComposer,
          $$ConfigAlertasTableOrderingComposer,
          $$ConfigAlertasTableAnnotationComposer,
          $$ConfigAlertasTableCreateCompanionBuilder,
          $$ConfigAlertasTableUpdateCompanionBuilder,
          (
            ConfigAlertaRow,
            BaseReferences<_$AppDatabase, $ConfigAlertasTable, ConfigAlertaRow>,
          ),
          ConfigAlertaRow,
          PrefetchHooks Function()
        > {
  $$ConfigAlertasTableTableManager(_$AppDatabase db, $ConfigAlertasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConfigAlertasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConfigAlertasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConfigAlertasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> lecheriaId = const Value.absent(),
                Value<int> diasCeloEsperado = const Value.absent(),
                Value<int> diasConfirmarPreniez = const Value.absent(),
                Value<int> diasVaciosAltos = const Value.absent(),
                Value<int> diasAntesSecar = const Value.absent(),
                Value<int> diasAntesParto = const Value.absent(),
                Value<int> diasAvisoFinRetiro = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<bool> pendiente = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConfigAlertasCompanion(
                id: id,
                lecheriaId: lecheriaId,
                diasCeloEsperado: diasCeloEsperado,
                diasConfirmarPreniez: diasConfirmarPreniez,
                diasVaciosAltos: diasVaciosAltos,
                diasAntesSecar: diasAntesSecar,
                diasAntesParto: diasAntesParto,
                diasAvisoFinRetiro: diasAvisoFinRetiro,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                pendiente: pendiente,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String lecheriaId,
                Value<int> diasCeloEsperado = const Value.absent(),
                Value<int> diasConfirmarPreniez = const Value.absent(),
                Value<int> diasVaciosAltos = const Value.absent(),
                Value<int> diasAntesSecar = const Value.absent(),
                Value<int> diasAntesParto = const Value.absent(),
                Value<int> diasAvisoFinRetiro = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<bool> pendiente = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConfigAlertasCompanion.insert(
                id: id,
                lecheriaId: lecheriaId,
                diasCeloEsperado: diasCeloEsperado,
                diasConfirmarPreniez: diasConfirmarPreniez,
                diasVaciosAltos: diasVaciosAltos,
                diasAntesSecar: diasAntesSecar,
                diasAntesParto: diasAntesParto,
                diasAvisoFinRetiro: diasAvisoFinRetiro,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                pendiente: pendiente,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ConfigAlertasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConfigAlertasTable,
      ConfigAlertaRow,
      $$ConfigAlertasTableFilterComposer,
      $$ConfigAlertasTableOrderingComposer,
      $$ConfigAlertasTableAnnotationComposer,
      $$ConfigAlertasTableCreateCompanionBuilder,
      $$ConfigAlertasTableUpdateCompanionBuilder,
      (
        ConfigAlertaRow,
        BaseReferences<_$AppDatabase, $ConfigAlertasTable, ConfigAlertaRow>,
      ),
      ConfigAlertaRow,
      PrefetchHooks Function()
    >;
typedef $$SyncCursoresTableCreateCompanionBuilder =
    SyncCursoresCompanion Function({
      required String tabla,
      Value<DateTime?> ultimaBajada,
      Value<String?> ultimaBajadaId,
      Value<int> rowid,
    });
typedef $$SyncCursoresTableUpdateCompanionBuilder =
    SyncCursoresCompanion Function({
      Value<String> tabla,
      Value<DateTime?> ultimaBajada,
      Value<String?> ultimaBajadaId,
      Value<int> rowid,
    });

class $$SyncCursoresTableFilterComposer
    extends Composer<_$AppDatabase, $SyncCursoresTable> {
  $$SyncCursoresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tabla => $composableBuilder(
    column: $table.tabla,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get ultimaBajada => $composableBuilder(
    column: $table.ultimaBajada,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ultimaBajadaId => $composableBuilder(
    column: $table.ultimaBajadaId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncCursoresTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncCursoresTable> {
  $$SyncCursoresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tabla => $composableBuilder(
    column: $table.tabla,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get ultimaBajada => $composableBuilder(
    column: $table.ultimaBajada,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ultimaBajadaId => $composableBuilder(
    column: $table.ultimaBajadaId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncCursoresTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncCursoresTable> {
  $$SyncCursoresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tabla =>
      $composableBuilder(column: $table.tabla, builder: (column) => column);

  GeneratedColumn<DateTime> get ultimaBajada => $composableBuilder(
    column: $table.ultimaBajada,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ultimaBajadaId => $composableBuilder(
    column: $table.ultimaBajadaId,
    builder: (column) => column,
  );
}

class $$SyncCursoresTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncCursoresTable,
          SyncCursorRow,
          $$SyncCursoresTableFilterComposer,
          $$SyncCursoresTableOrderingComposer,
          $$SyncCursoresTableAnnotationComposer,
          $$SyncCursoresTableCreateCompanionBuilder,
          $$SyncCursoresTableUpdateCompanionBuilder,
          (
            SyncCursorRow,
            BaseReferences<_$AppDatabase, $SyncCursoresTable, SyncCursorRow>,
          ),
          SyncCursorRow,
          PrefetchHooks Function()
        > {
  $$SyncCursoresTableTableManager(_$AppDatabase db, $SyncCursoresTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncCursoresTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncCursoresTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncCursoresTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> tabla = const Value.absent(),
                Value<DateTime?> ultimaBajada = const Value.absent(),
                Value<String?> ultimaBajadaId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncCursoresCompanion(
                tabla: tabla,
                ultimaBajada: ultimaBajada,
                ultimaBajadaId: ultimaBajadaId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tabla,
                Value<DateTime?> ultimaBajada = const Value.absent(),
                Value<String?> ultimaBajadaId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncCursoresCompanion.insert(
                tabla: tabla,
                ultimaBajada: ultimaBajada,
                ultimaBajadaId: ultimaBajadaId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncCursoresTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncCursoresTable,
      SyncCursorRow,
      $$SyncCursoresTableFilterComposer,
      $$SyncCursoresTableOrderingComposer,
      $$SyncCursoresTableAnnotationComposer,
      $$SyncCursoresTableCreateCompanionBuilder,
      $$SyncCursoresTableUpdateCompanionBuilder,
      (
        SyncCursorRow,
        BaseReferences<_$AppDatabase, $SyncCursoresTable, SyncCursorRow>,
      ),
      SyncCursorRow,
      PrefetchHooks Function()
    >;
typedef $$SyncEstadosTableCreateCompanionBuilder =
    SyncEstadosCompanion Function({
      required String tabla,
      Value<DateTime?> ultimaSincronizacionOk,
      Value<String?> ultimoError,
      Value<DateTime?> ultimoErrorEn,
      Value<int> rowid,
    });
typedef $$SyncEstadosTableUpdateCompanionBuilder =
    SyncEstadosCompanion Function({
      Value<String> tabla,
      Value<DateTime?> ultimaSincronizacionOk,
      Value<String?> ultimoError,
      Value<DateTime?> ultimoErrorEn,
      Value<int> rowid,
    });

class $$SyncEstadosTableFilterComposer
    extends Composer<_$AppDatabase, $SyncEstadosTable> {
  $$SyncEstadosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tabla => $composableBuilder(
    column: $table.tabla,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get ultimaSincronizacionOk => $composableBuilder(
    column: $table.ultimaSincronizacionOk,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ultimoError => $composableBuilder(
    column: $table.ultimoError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get ultimoErrorEn => $composableBuilder(
    column: $table.ultimoErrorEn,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncEstadosTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncEstadosTable> {
  $$SyncEstadosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tabla => $composableBuilder(
    column: $table.tabla,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get ultimaSincronizacionOk => $composableBuilder(
    column: $table.ultimaSincronizacionOk,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ultimoError => $composableBuilder(
    column: $table.ultimoError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get ultimoErrorEn => $composableBuilder(
    column: $table.ultimoErrorEn,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncEstadosTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncEstadosTable> {
  $$SyncEstadosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tabla =>
      $composableBuilder(column: $table.tabla, builder: (column) => column);

  GeneratedColumn<DateTime> get ultimaSincronizacionOk => $composableBuilder(
    column: $table.ultimaSincronizacionOk,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ultimoError => $composableBuilder(
    column: $table.ultimoError,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get ultimoErrorEn => $composableBuilder(
    column: $table.ultimoErrorEn,
    builder: (column) => column,
  );
}

class $$SyncEstadosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncEstadosTable,
          SyncEstadoRow,
          $$SyncEstadosTableFilterComposer,
          $$SyncEstadosTableOrderingComposer,
          $$SyncEstadosTableAnnotationComposer,
          $$SyncEstadosTableCreateCompanionBuilder,
          $$SyncEstadosTableUpdateCompanionBuilder,
          (
            SyncEstadoRow,
            BaseReferences<_$AppDatabase, $SyncEstadosTable, SyncEstadoRow>,
          ),
          SyncEstadoRow,
          PrefetchHooks Function()
        > {
  $$SyncEstadosTableTableManager(_$AppDatabase db, $SyncEstadosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncEstadosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncEstadosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncEstadosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> tabla = const Value.absent(),
                Value<DateTime?> ultimaSincronizacionOk = const Value.absent(),
                Value<String?> ultimoError = const Value.absent(),
                Value<DateTime?> ultimoErrorEn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncEstadosCompanion(
                tabla: tabla,
                ultimaSincronizacionOk: ultimaSincronizacionOk,
                ultimoError: ultimoError,
                ultimoErrorEn: ultimoErrorEn,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tabla,
                Value<DateTime?> ultimaSincronizacionOk = const Value.absent(),
                Value<String?> ultimoError = const Value.absent(),
                Value<DateTime?> ultimoErrorEn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncEstadosCompanion.insert(
                tabla: tabla,
                ultimaSincronizacionOk: ultimaSincronizacionOk,
                ultimoError: ultimoError,
                ultimoErrorEn: ultimoErrorEn,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncEstadosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncEstadosTable,
      SyncEstadoRow,
      $$SyncEstadosTableFilterComposer,
      $$SyncEstadosTableOrderingComposer,
      $$SyncEstadosTableAnnotationComposer,
      $$SyncEstadosTableCreateCompanionBuilder,
      $$SyncEstadosTableUpdateCompanionBuilder,
      (
        SyncEstadoRow,
        BaseReferences<_$AppDatabase, $SyncEstadosTable, SyncEstadoRow>,
      ),
      SyncEstadoRow,
      PrefetchHooks Function()
    >;
typedef $$SesionesLocalesTableCreateCompanionBuilder =
    SesionesLocalesCompanion Function({
      required String id,
      required String usuarioId,
      Value<String?> email,
      Value<String?> nombre,
      required DateTime ultimoLoginOnline,
      Value<bool> offlineActiva,
      Value<int> rowid,
    });
typedef $$SesionesLocalesTableUpdateCompanionBuilder =
    SesionesLocalesCompanion Function({
      Value<String> id,
      Value<String> usuarioId,
      Value<String?> email,
      Value<String?> nombre,
      Value<DateTime> ultimoLoginOnline,
      Value<bool> offlineActiva,
      Value<int> rowid,
    });

class $$SesionesLocalesTableFilterComposer
    extends Composer<_$AppDatabase, $SesionesLocalesTable> {
  $$SesionesLocalesTableFilterComposer({
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

  ColumnFilters<String> get usuarioId => $composableBuilder(
    column: $table.usuarioId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get ultimoLoginOnline => $composableBuilder(
    column: $table.ultimoLoginOnline,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get offlineActiva => $composableBuilder(
    column: $table.offlineActiva,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SesionesLocalesTableOrderingComposer
    extends Composer<_$AppDatabase, $SesionesLocalesTable> {
  $$SesionesLocalesTableOrderingComposer({
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

  ColumnOrderings<String> get usuarioId => $composableBuilder(
    column: $table.usuarioId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get ultimoLoginOnline => $composableBuilder(
    column: $table.ultimoLoginOnline,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get offlineActiva => $composableBuilder(
    column: $table.offlineActiva,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SesionesLocalesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SesionesLocalesTable> {
  $$SesionesLocalesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get usuarioId =>
      $composableBuilder(column: $table.usuarioId, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<DateTime> get ultimoLoginOnline => $composableBuilder(
    column: $table.ultimoLoginOnline,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get offlineActiva => $composableBuilder(
    column: $table.offlineActiva,
    builder: (column) => column,
  );
}

class $$SesionesLocalesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SesionesLocalesTable,
          SesionLocalRow,
          $$SesionesLocalesTableFilterComposer,
          $$SesionesLocalesTableOrderingComposer,
          $$SesionesLocalesTableAnnotationComposer,
          $$SesionesLocalesTableCreateCompanionBuilder,
          $$SesionesLocalesTableUpdateCompanionBuilder,
          (
            SesionLocalRow,
            BaseReferences<
              _$AppDatabase,
              $SesionesLocalesTable,
              SesionLocalRow
            >,
          ),
          SesionLocalRow,
          PrefetchHooks Function()
        > {
  $$SesionesLocalesTableTableManager(
    _$AppDatabase db,
    $SesionesLocalesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SesionesLocalesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SesionesLocalesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SesionesLocalesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> usuarioId = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> nombre = const Value.absent(),
                Value<DateTime> ultimoLoginOnline = const Value.absent(),
                Value<bool> offlineActiva = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SesionesLocalesCompanion(
                id: id,
                usuarioId: usuarioId,
                email: email,
                nombre: nombre,
                ultimoLoginOnline: ultimoLoginOnline,
                offlineActiva: offlineActiva,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String usuarioId,
                Value<String?> email = const Value.absent(),
                Value<String?> nombre = const Value.absent(),
                required DateTime ultimoLoginOnline,
                Value<bool> offlineActiva = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SesionesLocalesCompanion.insert(
                id: id,
                usuarioId: usuarioId,
                email: email,
                nombre: nombre,
                ultimoLoginOnline: ultimoLoginOnline,
                offlineActiva: offlineActiva,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SesionesLocalesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SesionesLocalesTable,
      SesionLocalRow,
      $$SesionesLocalesTableFilterComposer,
      $$SesionesLocalesTableOrderingComposer,
      $$SesionesLocalesTableAnnotationComposer,
      $$SesionesLocalesTableCreateCompanionBuilder,
      $$SesionesLocalesTableUpdateCompanionBuilder,
      (
        SesionLocalRow,
        BaseReferences<_$AppDatabase, $SesionesLocalesTable, SesionLocalRow>,
      ),
      SesionLocalRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PlanesTableTableManager get planes =>
      $$PlanesTableTableManager(_db, _db.planes);
  $$CuentasTableTableManager get cuentas =>
      $$CuentasTableTableManager(_db, _db.cuentas);
  $$UsuariosTableTableManager get usuarios =>
      $$UsuariosTableTableManager(_db, _db.usuarios);
  $$LecheriasTableTableManager get lecherias =>
      $$LecheriasTableTableManager(_db, _db.lecherias);
  $$LecheriaMiembrosTableTableManager get lecheriaMiembros =>
      $$LecheriaMiembrosTableTableManager(_db, _db.lecheriaMiembros);
  $$AnimalesTableTableManager get animales =>
      $$AnimalesTableTableManager(_db, _db.animales);
  $$EventosAnimalTableTableManager get eventosAnimal =>
      $$EventosAnimalTableTableManager(_db, _db.eventosAnimal);
  $$PesasSesionesTableTableManager get pesasSesiones =>
      $$PesasSesionesTableTableManager(_db, _db.pesasSesiones);
  $$PesasLecheTableTableManager get pesasLeche =>
      $$PesasLecheTableTableManager(_db, _db.pesasLeche);
  $$ParametrosPeriodoTableTableManager get parametrosPeriodo =>
      $$ParametrosPeriodoTableTableManager(_db, _db.parametrosPeriodo);
  $$CostosFijosTableTableManager get costosFijos =>
      $$CostosFijosTableTableManager(_db, _db.costosFijos);
  $$MedicamentosTableTableManager get medicamentos =>
      $$MedicamentosTableTableManager(_db, _db.medicamentos);
  $$ConfigAlertasTableTableManager get configAlertas =>
      $$ConfigAlertasTableTableManager(_db, _db.configAlertas);
  $$SyncCursoresTableTableManager get syncCursores =>
      $$SyncCursoresTableTableManager(_db, _db.syncCursores);
  $$SyncEstadosTableTableManager get syncEstados =>
      $$SyncEstadosTableTableManager(_db, _db.syncEstados);
  $$SesionesLocalesTableTableManager get sesionesLocales =>
      $$SesionesLocalesTableTableManager(_db, _db.sesionesLocales);
}
