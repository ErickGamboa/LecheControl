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
