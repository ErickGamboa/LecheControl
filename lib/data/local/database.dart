import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

// ============================================================================
// Base de datos local (SQLite vía Drift) de LecheControl.
//
// Cada tabla de dominio refleja su equivalente en Supabase, más columnas de
// control de sincronización:
//   - updatedAt: cuándo se modificó por última vez (para "gana el último").
//   - pendiente: true si el registro tiene cambios locales sin subir todavía.
// Las tablas de dominio agregan deletedAt (borrado suave, D-08 en el spec:
// "nada se borra").
// ============================================================================

/// Catálogo de licencias (referencia, se baja del servidor). Define cuántas
/// lecherías permite cada plan.
@DataClassName('PlanRow')
class Planes extends Table {
  TextColumn get codigo => text()(); // 'invitado' | 'light' | 'medium' | 'pro'
  TextColumn get nombre => text()();
  IntColumn get limiteLecherias => integer()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {codigo};
}

/// Cuenta = unidad de licenciamiento. Cada lechería pertenece a una cuenta.
@DataClassName('CuentaRow')
class Cuentas extends Table {
  TextColumn get id => text()();
  TextColumn get nombre => text()();
  TextColumn get duenoId => text()();
  TextColumn get plan => text()(); // 'invitado' | 'light' | 'medium' | 'pro'
  TextColumn get estado => text()(); // 'activa' | 'suspendida'
  // Fin de la prueba gratis. null = sin prueba (pagado o invitado).
  DateTimeColumn get pruebaTermina => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get pendiente => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (plan IN ('invitado','light','medium','pro'))",
    "CHECK (estado IN ('activa','suspendida'))",
  ];
}

@DataClassName('UsuarioRow')
class Usuarios extends Table {
  TextColumn get id => text()();
  TextColumn get nombre => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get cuentaId => text().nullable()(); // cuenta propia del usuario
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get pendiente => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Una lechería (por ahora una por cuenta, ver spec Módulo 0).
@DataClassName('LecheriaRow')
class Lecherias extends Table {
  TextColumn get id => text()();
  TextColumn get nombre => text()();
  TextColumn get creadaPor => text()();
  TextColumn get cuentaId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get pendiente => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('LecheriaMiembroRow')
class LecheriaMiembros extends Table {
  TextColumn get id => text()();
  TextColumn get lecheriaId => text()();
  TextColumn get usuarioId => text()();
  TextColumn get rol => text()(); // 'admin' | 'operario'
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get pendiente => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => ["CHECK (rol IN ('admin','operario'))"];
}

/// Animal del hato. `grupo` define en qué módulo aparece (ordeño, secas,
/// novillas, terneros, en tratamiento) y sirve para repartir costos fijos.
@DataClassName('AnimalRow')
class Animales extends Table {
  TextColumn get id => text()();
  TextColumn get lecheriaId => text()();
  TextColumn get identificador => text()();
  TextColumn get sexo => text()(); // 'hembra' | 'macho'
  TextColumn get grupo => text()();
  TextColumn get estado => text().withDefault(const Constant('activo'))();
  TextColumn get estadoReproductivo =>
      text().withDefault(const Constant('desconocido'))();
  TextColumn get origen => text()(); // 'comprado' | 'nacido'
  RealColumn get precioCompra => real().nullable()();
  DateTimeColumn get fechaCompra => dateTime().nullable()();
  TextColumn get madreId => text().nullable()();
  DateTimeColumn get fechaProbableParto => dateTime().nullable()();
  DateTimeColumn get retiroLecheHasta => dateTime().nullable()();

  /// Base para los días de lactancia (DLac) del reporte de producción. La fija
  /// el evento de parto; es editable a mano para cargar de una vez las vacas
  /// que ya estaban en la finca antes de usar la app.
  DateTimeColumn get fechaUltimoParto => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get pendiente => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (sexo IN ('hembra','macho'))",
    "CHECK (grupo IN ('en_ordeno','secas','novillas','terneros','en_tratamiento'))",
    "CHECK (estado IN ('activo','vendido','muerto','descartado'))",
    "CHECK (estado_reproductivo IN ('vacia','preñada','desconocido'))",
    "CHECK (origen IN ('comprado','nacido'))",
    'CHECK (precio_compra IS NULL OR precio_compra >= 0)',
  ];
}

/// Hoja de vida: todo evento que le pasa a un animal (Módulo 1 y 6).
@DataClassName('EventoAnimalRow')
class EventosAnimal extends Table {
  TextColumn get id => text()();
  TextColumn get animalId => text()();
  TextColumn get lecheriaId => text()();
  TextColumn get tipo => text()();
  DateTimeColumn get fecha => dateTime()();
  TextColumn get detalle => text().nullable()(); // texto libre / JSON-ish
  TextColumn get medicamentoId => text().nullable()();
  TextColumn get dosis => text().nullable()();
  IntColumn get diasRetiro => integer().nullable()();
  RealColumn get costo => real().nullable()();
  TextColumn get resultado => text().nullable()(); // 'preñada' | 'vacia'
  TextColumn get toroPajilla => text().nullable()();
  TextColumn get sexoCria => text().nullable()();
  TextColumn get grupoAnterior => text().nullable()();
  TextColumn get grupoNuevo => text().nullable()();
  TextColumn get motivoBaja => text().nullable()();
  RealColumn get precioVenta => real().nullable()();
  TextColumn get criaAnimalId => text().nullable()();
  TextColumn get registradoPor => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get pendiente => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (tipo IN ('sanidad','celo','monta','inseminacion','palpacion',"
        "'secado','parto','cambio_grupo','baja','concentrado'))",
    'CHECK (costo IS NULL OR costo >= 0)',
  ];
}

/// Sesión semanal de pesa de leche (Módulo 3).
@DataClassName('PesaSesionRow')
class PesasSesiones extends Table {
  TextColumn get id => text()();
  TextColumn get lecheriaId => text()();
  DateTimeColumn get fecha => dateTime()();
  BoolColumn get cerrada => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get pendiente => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Lo pesado de una vaca dentro de una sesión: leche de la mañana, de la
/// tarde y kilos de concentrado que comió ese día.
///
/// `animalId` es nulo cuando se trata de una **vaca manual**: una que se pesa
/// pero no está en el inventario, y por eso no tiene días de lactancia. En ese
/// caso se identifica por `identificadorManual`. Siempre viene uno de los dos,
/// nunca los dos ni ninguno.
@DataClassName('PesaLecheRow')
class PesasLeche extends Table {
  TextColumn get id => text()();
  TextColumn get sesionId => text()();
  TextColumn get animalId => text().nullable()();
  TextColumn get identificadorManual => text().nullable()();

  /// Total del día = mañana + tarde. Lo calcula el repositorio al guardar.
  RealColumn get litros => real()();
  RealColumn get litrosManana => real().nullable()();
  RealColumn get litrosTarde => real().nullable()();
  RealColumn get concentradoKg => real().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get pendiente => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK (litros >= 0)',
    'CHECK (litros_manana IS NULL OR litros_manana >= 0)',
    'CHECK (litros_tarde IS NULL OR litros_tarde >= 0)',
    'CHECK (concentrado_kg IS NULL OR concentrado_kg >= 0)',
    'CHECK ((animal_id IS NOT NULL AND identificador_manual IS NULL) '
        'OR (animal_id IS NULL AND identificador_manual IS NOT NULL))',
  ];
}

/// Litros que se esperan de una vaca según cuántos días lleva de parida.
/// Siete tramos editables por lechería (Módulo 3 — reporte de producción).
///
/// Para una vaca concreta el esperado NO es el escalón del tramo: se
/// interpola entre el punto central de cada tramo, para que la curva suba y
/// baje suave y una vaca no salte de "Excelente" a "Muy Bajo" por cumplir un
/// día más. Punto central = (diaDesde + diaHasta) / 2; para el último tramo
/// (diaHasta nulo, "más de 305 días") se usa diaDesde + 25.
@DataClassName('CurvaReferenciaRow')
class CurvaReferencia extends Table {
  TextColumn get id => text()();
  TextColumn get lecheriaId => text()();
  IntColumn get orden => integer()();
  IntColumn get diaDesde => integer()();
  IntColumn get diaHasta => integer().nullable()();
  RealColumn get litrosEsperados => real()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get pendiente => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK (dia_desde >= 0)',
    'CHECK (dia_hasta IS NULL OR dia_hasta > dia_desde)',
    'CHECK (litros_esperados >= 0)',
  ];
}

/// Cómo se etiqueta una vaca según (lo que dio ÷ lo que se esperaba), y el
/// umbral de litros para sugerir secado. Una fila por lechería.
@DataClassName('ConfigReporteRow')
class ConfigReporte extends Table {
  TextColumn get id => text()();
  TextColumn get lecheriaId => text()();
  RealColumn get pctExcelente => real().withDefault(const Constant(100))();
  RealColumn get pctBueno => real().withDefault(const Constant(85))();
  RealColumn get pctVigilar => real().withDefault(const Constant(70))();
  RealColumn get pctBajo => real().withDefault(const Constant(60))();
  RealColumn get umbralSecadoLitros => real().withDefault(const Constant(8))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get pendiente => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Semana de la finca (lunes a domingo), unidad de las finanzas.
@DataClassName('SemanaRow')
class Semanas extends Table {
  TextColumn get id => text()();
  TextColumn get lecheriaId => text()();
  DateTimeColumn get fechaInicio => dateTime()(); // lunes
  DateTimeColumn get fechaFin => dateTime()(); // domingo
  BoolColumn get cerrada => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get pendiente => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Plata que entró en la semana. No se calcula: se digita lo que
/// efectivamente se recibió.
@DataClassName('IngresoSemanaRow')
class IngresosSemana extends Table {
  TextColumn get id => text()();
  TextColumn get lecheriaId => text()();
  TextColumn get semanaId => text()();
  TextColumn get tipo => text()(); // 'leche' | 'venta_ganado' | 'otro'
  RealColumn get monto => real()();

  /// Solo para tipo `leche`: litros que la planta pagó. `monto / litros` da el
  /// precio real por litro de la semana, que es lo que usa la rentabilidad
  /// por vaca (plata real, no un precio estimado).
  RealColumn get litros => real().nullable()();

  /// Solo para tipo `venta_ganado`: qué animal se vendió, para su hoja de vida.
  TextColumn get animalId => text().nullable()();
  TextColumn get detalle => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get pendiente => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (tipo IN ('leche','venta_ganado','otro'))",
    'CHECK (monto >= 0)',
    'CHECK (litros IS NULL OR litros >= 0)',
  ];
}

/// Plata que salió en la semana (salario del peón, concentrado, medicamentos,
/// cerca…). La categoría es texto libre, sugerido desde `CategoriasGasto`.
@DataClassName('GastoSemanaRow')
class GastosSemana extends Table {
  TextColumn get id => text()();
  TextColumn get lecheriaId => text()();
  TextColumn get semanaId => text()();
  TextColumn get categoria => text()();
  RealColumn get monto => real()();
  TextColumn get detalle => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get pendiente => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['CHECK (monto >= 0)'];
}

/// Categorías sugeridas de gasto, para que meter uno sea tocar y no escribir.
@DataClassName('CategoriaGastoRow')
class CategoriasGasto extends Table {
  TextColumn get id => text()();
  TextColumn get lecheriaId => text()();
  TextColumn get nombre => text()();
  IntColumn get orden => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get pendiente => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Catálogo de medicamentos de la lechería (Módulo 7).
@DataClassName('MedicamentoRow')
class Medicamentos extends Table {
  TextColumn get id => text()();
  TextColumn get lecheriaId => text()();
  TextColumn get nombre => text()();
  RealColumn get costoEnvase => real()();
  TextColumn get tipoDosis => text()(); // 'fija' | 'por_aplicacion'
  RealColumn get mlEnvase => real().nullable()();
  RealColumn get aplicacionesEnvase => real().nullable()();
  RealColumn get dosisFijaMl => real().nullable()();
  IntColumn get diasRetiroLeche => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get pendiente => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (tipo_dosis IN ('fija','por_aplicacion'))",
    'CHECK (costo_envase >= 0)',
    'CHECK (dias_retiro_leche >= 0)',
  ];
}

/// Guarda, por cada tabla, la fecha (y el id, para desempatar filas con el
/// mismo `updated_at`) del último registro que bajamos del servidor.
@DataClassName('SyncCursorRow')
class SyncCursores extends Table {
  TextColumn get tabla => text()();
  DateTimeColumn get ultimaBajada => dateTime().nullable()();
  TextColumn get ultimaBajadaId => text().nullable()();

  @override
  Set<Column> get primaryKey => {tabla};
}

/// Estado de sincronización por tabla, solo local: para que el usuario/soporte
/// pueda ver "N cambios pendientes" y el último error sin leer logs.
@DataClassName('SyncEstadoRow')
class SyncEstados extends Table {
  TextColumn get tabla => text()();
  DateTimeColumn get ultimaSincronizacionOk => dateTime().nullable()();
  TextColumn get ultimoError => text().nullable()();
  DateTimeColumn get ultimoErrorEn => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {tabla};
}

/// Identidad verificada localmente para permitir entrar sin conexión después
/// de un inicio de sesión exitoso en este dispositivo (Módulo 0).
@DataClassName('SesionLocalRow')
class SesionesLocales extends Table {
  TextColumn get id => text()(); // fila única: 'actual'
  TextColumn get usuarioId => text()();
  TextColumn get email => text().nullable()();
  TextColumn get nombre => text().nullable()();
  DateTimeColumn get ultimoLoginOnline => dateTime()();
  BoolColumn get offlineActiva =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    Planes,
    Cuentas,
    Usuarios,
    Lecherias,
    LecheriaMiembros,
    Animales,
    EventosAnimal,
    PesasSesiones,
    PesasLeche,
    CurvaReferencia,
    ConfigReporte,
    Semanas,
    IngresosSemana,
    GastosSemana,
    CategoriasGasto,
    Medicamentos,
    SyncCursores,
    SyncEstados,
    SesionesLocales,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_abrirConexion());

  /// Constructor para pruebas: permite usar una base en memoria y mantener los
  /// tests aislados del archivo SQLite real de la app.
  AppDatabase.forExecutor(super.executor);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _crearIndicesUnicosLocales();
    },
    // v1 -> v2: la pesa pasa a mañana/tarde/concentrado y admite vacas
    // manuales; el animal guarda su último parto (días de lactancia); entran
    // la curva de referencia y las finanzas semanales.
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(animales, animales.fechaUltimoParto);
        await m.addColumn(pesasLeche, pesasLeche.identificadorManual);
        await m.addColumn(pesasLeche, pesasLeche.litrosManana);
        await m.addColumn(pesasLeche, pesasLeche.litrosTarde);
        await m.addColumn(pesasLeche, pesasLeche.concentradoKg);
        // `animalId` deja de ser obligatorio (vacas manuales). SQLite no
        // sabe aflojar un NOT NULL, así que Drift recrea la tabla copiando
        // las filas. Las pesas viejas quedan con mañana/tarde en null: el
        // reporte las muestra como "sin desglose" en vez de inventarse un
        // reparto que nadie midió.
        await m.alterTable(TableMigration(pesasLeche));
        await m.createTable(curvaReferencia);
        await m.createTable(configReporte);
        await m.createTable(semanas);
        await m.createTable(ingresosSemana);
        await m.createTable(gastosSemana);
        await m.createTable(categoriasGasto);
        await _crearIndicesUnicosLocales();
      }
      // v2 -> v3: sale el módulo de Alertas y el período mensual. Las
      // finanzas semanales (semanas / ingresos_semana / gastos_semana) ya
      // reemplazan a parametros_periodo y costos_fijos.
      if (from < 3) {
        await customStatement('DROP TABLE IF EXISTS costos_fijos');
        await customStatement('DROP TABLE IF EXISTS parametros_periodo');
        await customStatement('DROP TABLE IF EXISTS config_alertas');
      }
      // v3 -> v4: el concentrado se mide en cada pesa
      // (`pesas_leche.concentrado_kg`), no como un valor fijo en la ficha del
      // animal. La columna también se eliminó en Supabase, así que dejarla
      // acá haría fallar la subida de cada animal.
      if (from < 4) {
        await m.alterTable(TableMigration(animales));
      }
    },
  );

  Future<void> _crearIndicesUnicosLocales() async {
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS '
      'idx_lecheria_miembros_lecheria_usuario_activos '
      'ON lecheria_miembros (lecheria_id, usuario_id) '
      'WHERE deleted_at IS NULL',
    );
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS '
      'idx_animales_lecheria_identificador_activos '
      'ON animales (lecheria_id, identificador) '
      'WHERE deleted_at IS NULL',
    );
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS '
      'idx_curva_referencia_lecheria_tramo '
      'ON curva_referencia (lecheria_id, dia_desde) '
      'WHERE deleted_at IS NULL',
    );
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_config_reporte_lecheria '
      'ON config_reporte (lecheria_id) '
      'WHERE deleted_at IS NULL',
    );
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_semanas_lecheria_inicio '
      'ON semanas (lecheria_id, fecha_inicio) '
      'WHERE deleted_at IS NULL',
    );
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_categorias_gasto_lecheria_nombre '
      'ON categorias_gasto (lecheria_id, nombre) '
      'WHERE deleted_at IS NULL',
    );
  }
}

QueryExecutor _abrirConexion() {
  // drift_flutter resuelve la ruta del archivo y las librerías nativas de
  // SQLite en Android/iOS/escritorio automáticamente.
  // `LECHE_DB_NAME` aísla e2e/demo del archivo diario del usuario.
  const nombre = String.fromEnvironment(
    'LECHE_DB_NAME',
    defaultValue: 'lechecontrol',
  );
  return driftDatabase(name: nombre);
}
