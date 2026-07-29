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
  RealColumn get concentradoKgDia => real().withDefault(const Constant(0))();
  DateTimeColumn get fechaProbableParto => dateTime().nullable()();
  DateTimeColumn get retiroLecheHasta => dateTime().nullable()();
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
    'CHECK (concentrado_kg_dia >= 0)',
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

/// Litros pesados de un animal dentro de una sesión.
@DataClassName('PesaLecheRow')
class PesasLeche extends Table {
  TextColumn get id => text()();
  TextColumn get sesionId => text()();
  TextColumn get animalId => text()();
  RealColumn get litros => real()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get pendiente => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['CHECK (litros >= 0)'];
}

/// Parámetros de precio del período (mes calendario), Módulo 4.
@DataClassName('ParametrosPeriodoRow')
class ParametrosPeriodo extends Table {
  TextColumn get id => text()();
  TextColumn get lecheriaId => text()();
  IntColumn get anio => integer()();
  IntColumn get mes => integer()();
  RealColumn get precioLitro => real()();
  RealColumn get precioConcentradoKg => real()();
  RealColumn get umbralSecadoLitros => real().withDefault(const Constant(8))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get pendiente => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK (mes BETWEEN 1 AND 12)',
    'CHECK (precio_litro >= 0)',
    'CHECK (precio_concentrado_kg >= 0)',
    'CHECK (umbral_secado_litros >= 0)',
  ];
}

/// Costo fijo del período (luz, salario, agua, alquiler…), Módulo 4.
@DataClassName('CostoFijoRow')
class CostosFijos extends Table {
  TextColumn get id => text()();
  TextColumn get lecheriaId => text()();
  TextColumn get periodoId => text()();
  TextColumn get categoria => text()();
  RealColumn get monto => real()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get pendiente => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['CHECK (monto >= 0)'];
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

/// Umbrales configurables de alertas reproductivas y de manejo (Módulo 9).
@DataClassName('ConfigAlertaRow')
class ConfigAlertas extends Table {
  TextColumn get id => text()();
  TextColumn get lecheriaId => text()();
  IntColumn get diasCeloEsperado => integer().withDefault(const Constant(21))();
  IntColumn get diasConfirmarPreniez =>
      integer().withDefault(const Constant(45))();
  IntColumn get diasVaciosAltos => integer().withDefault(const Constant(150))();
  IntColumn get diasAntesSecar => integer().withDefault(const Constant(60))();
  IntColumn get diasAntesParto => integer().withDefault(const Constant(14))();
  IntColumn get diasAvisoFinRetiro =>
      integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get pendiente => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
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
    ParametrosPeriodo,
    CostosFijos,
    Medicamentos,
    ConfigAlertas,
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
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _crearIndicesUnicosLocales();
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
      'idx_parametros_periodo_lecheria_anio_mes '
      'ON parametros_periodo (lecheria_id, anio, mes) '
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
