/// Las tablas que algún paso de migración **recrea**, en su forma anterior a
/// la v12.
///
/// **Por qué existe.** Cada prueba de migración arma un esquema viejo mínimo:
/// solo la tabla que a ese paso le importa. Eso alcanzaba mientras los pasos
/// se tocaran a sí mismos, pero `animales` y `eventos_animal` se recrean en la
/// v12 —el grupo `toros` vive en un CHECK y SQLite no sabe cambiar uno—, y una
/// migración no puede recrear una tabla que en la base no está.
///
/// Un teléfono de verdad siempre las tiene: ninguna versión de LecheControl ha
/// existido sin animales ni sin hoja de vida. Así que ponerlas acá no es
/// inventar un escenario, es dejar de fingir uno que no pasa.
///
/// Se exponen como SQL y no como una función que reciba la base, para no
/// tener que importar `package:sqlite3` —que es dependencia indirecta— solo
/// por el tipo del parámetro.
const tablasQueSeRecrean = <String>[
  '''
  CREATE TABLE IF NOT EXISTS animales (
    id TEXT NOT NULL PRIMARY KEY,
    lecheria_id TEXT NOT NULL,
    identificador TEXT NOT NULL,
    sexo TEXT NOT NULL,
    grupo TEXT NOT NULL,
    estado TEXT NOT NULL DEFAULT 'activo',
    estado_reproductivo TEXT NOT NULL DEFAULT 'desconocido',
    origen TEXT NOT NULL,
    precio_compra REAL,
    fecha_compra TEXT,
    madre_id TEXT,
    fecha_probable_parto TEXT,
    retiro_leche_hasta TEXT,
    fecha_ultimo_parto TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    deleted_at TEXT,
    pendiente INTEGER NOT NULL DEFAULT 0
  )''',
  '''
  CREATE TABLE IF NOT EXISTS eventos_animal (
    id TEXT NOT NULL PRIMARY KEY,
    animal_id TEXT NOT NULL,
    lecheria_id TEXT NOT NULL,
    tipo TEXT NOT NULL,
    fecha TEXT NOT NULL,
    detalle TEXT,
    medicamento_id TEXT,
    dosis TEXT,
    dias_retiro INTEGER,
    costo REAL,
    resultado TEXT,
    toro_pajilla TEXT,
    sexo_cria TEXT,
    grupo_anterior TEXT,
    grupo_nuevo TEXT,
    motivo_baja TEXT,
    precio_venta REAL,
    cria_animal_id TEXT,
    registrado_por TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    deleted_at TEXT,
    pendiente INTEGER NOT NULL DEFAULT 0
  )''',
];

/// `config_reporte` tal como quedó en la v7 y se mantuvo hasta la v14.
///
/// Va aparte de [tablasQueSeRecrean] porque no todas las pruebas la quieren
/// así: las de la v5 a la v7 arman su propia versión, más vieja, porque es
/// justo la columna que ese paso agrega lo que están probando.
///
/// La necesitan las pruebas de la v8 en adelante, desde que el paso v14 -> v15
/// le agrega `dias_para_secar`: una migración no puede agregarle una columna a
/// una tabla que en la base no está. Y en un teléfono de verdad siempre está
/// —ninguna versión de LecheControl ha existido sin la config del reporte—,
/// así que ponerla acá no inventa un escenario, deja de fingir uno que no
/// pasa.
const configReportePreV15 = '''
  CREATE TABLE IF NOT EXISTS config_reporte (
    id TEXT NOT NULL PRIMARY KEY,
    lecheria_id TEXT NOT NULL,
    pct_excelente REAL NOT NULL DEFAULT 100,
    pct_bueno REAL NOT NULL DEFAULT 85,
    pct_vigilar REAL NOT NULL DEFAULT 70,
    pct_bajo REAL NOT NULL DEFAULT 60,
    umbral_secado_litros REAL NOT NULL DEFAULT 8,
    tope_kg_leche REAL,
    kg_leche_por_kg_concentrado REAL NOT NULL DEFAULT 3,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    deleted_at TEXT,
    pendiente INTEGER NOT NULL DEFAULT 0
  )''';
