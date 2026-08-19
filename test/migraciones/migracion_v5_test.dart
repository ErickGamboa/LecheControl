import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leche_control/data/local/database.dart';

/// v4 -> v5 sobre una base con datos viejos: el teléfono del ganadero ya
/// tiene medicamentos cargados y quizá algún animal "en tratamiento", y al
/// actualizar la app no puede perder nada ni reventar.
void main() {
  test('migra medicamentos y saca a los animales de en_tratamiento', () async {
    // Armamos a mano el esquema v4 de las dos tablas que cambian, antes de
    // que drift abra la base (si no, correría onCreate y no la migración).
    final executor = NativeDatabase.memory(
      setup: (raw) {
        raw.execute('''
      CREATE TABLE medicamentos (
        id TEXT NOT NULL PRIMARY KEY,
        lecheria_id TEXT NOT NULL,
        nombre TEXT NOT NULL,
        costo_envase REAL NOT NULL,
        tipo_dosis TEXT NOT NULL,
        ml_envase REAL,
        aplicaciones_envase REAL,
        dosis_fija_ml REAL,
        dias_retiro_leche INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        pendiente INTEGER NOT NULL DEFAULT 0
      )''');
        raw.execute('''
      CREATE TABLE animales (
        id TEXT NOT NULL PRIMARY KEY,
        lecheria_id TEXT NOT NULL,
        identificador TEXT NOT NULL,
        sexo TEXT NOT NULL,
        grupo TEXT NOT NULL,
        estado TEXT NOT NULL DEFAULT 'activo',
        estado_reproductivo TEXT NOT NULL DEFAULT 'desconocido',
        origen TEXT NOT NULL,
        precio_compra REAL,
        fecha_compra INTEGER,
        madre_id TEXT,
        fecha_probable_parto INTEGER,
        retiro_leche_hasta INTEGER,
        fecha_ultimo_parto INTEGER,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        pendiente INTEGER NOT NULL DEFAULT 0
      )''');
        raw.execute(
          "INSERT INTO medicamentos VALUES ('m1','l1','Oxi',12000,'fija',100,"
          "NULL,10,4,'2026-01-01T00:00:00.000','2026-01-01T00:00:00.000',"
          'NULL,0)',
        );
        raw.execute(
          'INSERT INTO animales (id,lecheria_id,identificador,sexo,grupo,'
          "origen,created_at,updated_at) VALUES ('a1','l1','A-1','hembra',"
          "'en_tratamiento','nacido','2026-01-01T00:00:00.000',"
          "'2026-01-01T00:00:00.000')",
        );
        // La migración a v6 también toca estas dos, y en una base v4 de
        // verdad existen: sin ellas la migración revienta antes de llegar a
        // lo que este test mira.
        raw.execute('''
      CREATE TABLE config_reporte (
        id TEXT NOT NULL PRIMARY KEY,
        lecheria_id TEXT NOT NULL,
        pct_excelente REAL NOT NULL DEFAULT 100,
        pct_bueno REAL NOT NULL DEFAULT 85,
        pct_vigilar REAL NOT NULL DEFAULT 70,
        pct_bajo REAL NOT NULL DEFAULT 60,
        umbral_secado_litros REAL NOT NULL DEFAULT 8,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        pendiente INTEGER NOT NULL DEFAULT 0
      )''');
        raw.execute('''
      CREATE TABLE eventos_animal (
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
        pendiente INTEGER NOT NULL DEFAULT 0,
        CHECK (tipo IN ('sanidad','celo','monta','inseminacion','palpacion',
          'secado','parto','cambio_grupo','baja','concentrado')),
        CHECK (costo IS NULL OR costo >= 0)
      )''');
        raw.execute('PRAGMA user_version = 4');
      },
    );

    // La app de hoy abre esa base: tiene que correr la migración a v5.
    final db = AppDatabase.forExecutor(executor);
    await db.customSelect('SELECT 1').get();

    final medicamento = await db.select(db.medicamentos).getSingle();
    expect(medicamento.dosisAplicacion, '10 ml');
    expect(medicamento.mlEnvase, 100);

    final grupo =
        (await db
                .customSelect('SELECT grupo, pendiente FROM animales')
                .getSingle())
            .data;
    expect(grupo['grupo'], 'en_ordeno');
    expect(grupo['pendiente'], 1);

    await db.close();
  });
}
