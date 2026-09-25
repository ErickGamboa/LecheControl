import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' show Value;
import 'package:leche_control/data/local/database.dart';

import 'tablas_que_se_recrean.dart';

/// v13 -> v14: el alias del animal.
///
/// Segunda columna que se le agrega a `animales` después de la v12, y tropieza
/// con lo mismo que la primera: la tabla se recrea en dos pasos anteriores, así
/// que la columna va declarada en los `newColumns` de esos pasos. De ahí que
/// haya tres caminos y no dos, y que los tres tengan que terminar igual:
///
/// - quien venga de **antes de la v12** la recibe en la recreación, y volver a
///   agregarla con `addColumn` falla con «duplicate column»;
/// - quien venga **de la v12 o la v13** no pasa por ninguna recreación, y sin
///   el `addColumn` se queda sin la columna y la app no abre.
///
/// Es la clase de error que ya mordió una vez en este proyecto, y que no da la
/// cara en el teléfono del que desarrolla —que siempre instala limpio— sino en
/// el del ganadero que viene arrastrando la app desde hace meses.
void main() {
  /// `animales` tal como quedó en la v12: con el padre, sin fecha de
  /// nacimiento y sin alias.
  const animalesV12 = '''
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
      fecha_compra TEXT,
      madre_id TEXT,
      padre_id TEXT,
      padre_pajilla TEXT,
      fecha_probable_parto TEXT,
      retiro_leche_hasta TEXT,
      fecha_ultimo_parto TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      deleted_at TEXT,
      pendiente INTEGER NOT NULL DEFAULT 0
    )''';

  /// Y tal como quedó en la v13: igual, más la fecha de nacimiento.
  const animalesV13 = '''
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
      fecha_compra TEXT,
      fecha_nacimiento TEXT,
      madre_id TEXT,
      padre_id TEXT,
      padre_pajilla TEXT,
      fecha_probable_parto TEXT,
      retiro_leche_hasta TEXT,
      fecha_ultimo_parto TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      deleted_at TEXT,
      pendiente INTEGER NOT NULL DEFAULT 0
    )''';

  const insertarVaca =
      "INSERT INTO animales (id,lecheria_id,identificador,sexo,grupo,origen,"
      "created_at,updated_at) VALUES ('v1','l1','1542','hembra','en_ordeno',"
      "'nacido','2026-01-01T00:00:00.000','2026-01-01T00:00:00.000')";

  /// Abre la base con `animales` en el esquema dado y el `user_version` dado,
  /// que es lo que dispara la migración.
  AppDatabase abrirDesde(String esquemaAnimales, int version) {
    final executor = NativeDatabase.memory(
      setup: (raw) {
        for (final sql in tablasQueSeRecrean) {
          // `animales` se crea con el esquema de esa versión, no con el
          // genérico de hoy.
          if (!sql.contains('CREATE TABLE IF NOT EXISTS animales')) {
            raw.execute(sql);
          }
        }
        raw.execute(esquemaAnimales);
        raw.execute(insertarVaca);
        raw.execute('PRAGMA user_version = $version');
      },
    );
    return AppDatabase.forExecutor(executor);
  }

  /// Que la vaca siga ahí y que la columna sirva de verdad: que se le pueda
  /// escribir y leer un alias.
  Future<void> elAliasFunciona(AppDatabase db) async {
    final vaca = await db.select(db.animales).getSingle();
    expect(vaca.identificador, '1542', reason: 'el animal no se pierde');
    expect(vaca.alias, isNull, reason: 'nadie tenía alias antes de la v14');

    await (db.update(db.animales)..where((t) => t.id.equals('v1'))).write(
      const AnimalesCompanion(alias: Value('99')),
    );
    expect((await db.select(db.animales).getSingle()).alias, '99');
  }

  test('desde la v13 agrega la columna sin tocar los animales', () async {
    final db = abrirDesde(animalesV13, 13);
    addTearDown(db.close);
    await elAliasFunciona(db);
  });

  test('desde la v12 también, sin pasar por ninguna recreación', () async {
    // Este salta dos versiones de una: recibe la fecha de nacimiento y el
    // alias en el mismo arranque.
    final db = abrirDesde(animalesV12, 12);
    addTearDown(db.close);
    expect(
      (await db.select(db.animales).getSingle()).fechaNacimiento,
      isNull,
      reason: 'la columna de la v13 también tiene que estar',
    );
    await elAliasFunciona(db);
  });

  test(
    'desde antes de la v12 la recibe en la recreación, sin duplicarla',
    () async {
      // El camino largo: acá `animales` se recrea por el paso de los toros y la
      // columna llega por `newColumns`. Si el `addColumn` de la v14 no se
      // saltara, esto reventaría con «duplicate column».
      final executor = NativeDatabase.memory(
        setup: (raw) {
          for (final sql in tablasQueSeRecrean) {
            raw.execute(sql);
          }
          raw.execute(insertarVaca);
          raw.execute('PRAGMA user_version = 11');
        },
      );
      final db = AppDatabase.forExecutor(executor);
      addTearDown(db.close);
      await elAliasFunciona(db);
    },
  );
}
