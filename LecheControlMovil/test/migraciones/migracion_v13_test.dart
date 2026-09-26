import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' show Value;
import 'package:leche_control/data/local/database.dart';

import 'tablas_que_se_recrean.dart';

/// v12 -> v13: la fecha de nacimiento del animal.
///
/// Parece la migración más boba del proyecto —una columna nula— y es la que
/// más fácil se rompe, porque `animales` se recrea en dos pasos anteriores.
/// La columna va declarada en los `newColumns` de esos pasos, así que:
///
/// - quien venga de **antes de la v12** la recibe en la recreación, y volver a
///   agregarla con `addColumn` falla con «duplicate column»;
/// - quien venga **de la v12** no pasa por ninguna recreación, y sin el
///   `addColumn` se queda sin la columna y la app no abre.
///
/// Los dos caminos tienen que terminar igual. Eso es lo que se prueba acá, y
/// es la clase de error que ya mordió una vez en este proyecto.
void main() {
  /// El esquema de `animales` tal como quedó en la v12: con el padre, sin la
  /// fecha de nacimiento.
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

  const insertarNovilla =
      "INSERT INTO animales (id,lecheria_id,identificador,sexo,grupo,origen,"
      "created_at,updated_at) VALUES ('n1','l1','N-1','hembra','novillas',"
      "'nacido','2026-01-01T00:00:00.000','2026-01-01T00:00:00.000')";

  test('desde la v12 agrega la columna sin tocar los animales', () async {
    final executor = NativeDatabase.memory(
      setup: (raw) {
        for (final sql in tablasQueSeRecrean) {
          // `animales` se crea con el esquema de la v12, no con el genérico.
          if (!sql.contains('CREATE TABLE IF NOT EXISTS animales')) {
            raw.execute(sql);
          }
        }
        raw.execute(configReportePreV15);
        raw.execute(animalesV12);
        raw.execute(insertarNovilla);
        raw.execute('PRAGMA user_version = 12');
      },
    );

    final db = AppDatabase.forExecutor(executor);
    addTearDown(db.close);

    final novilla = await db.select(db.animales).getSingle();
    expect(novilla.identificador, 'N-1');
    expect(novilla.fechaNacimiento, isNull);

    // Y la columna sirve de verdad: se le puede escribir.
    await (db.update(db.animales)..where((t) => t.id.equals('n1'))).write(
      AnimalesCompanion(fechaNacimiento: Value(DateTime(2025, 5, 26))),
    );
    final guardada = await db.select(db.animales).getSingle();
    expect(guardada.fechaNacimiento, DateTime(2025, 5, 26));
  });

  test(
    'desde antes de la v12 la recibe en la recreación, sin duplicarla',
    () async {
      // El camino largo: acá `animales` se recrea por el paso de los toros y la
      // columna llega por `newColumns`. Si el `addColumn` de la v13 no se
      // saltara, esto reventaría con «duplicate column».
      final executor = NativeDatabase.memory(
        setup: (raw) {
          for (final sql in tablasQueSeRecrean) {
            raw.execute(sql);
          }
          raw.execute(configReportePreV15);
          raw.execute(insertarNovilla);
          raw.execute('PRAGMA user_version = 11');
        },
      );

      final db = AppDatabase.forExecutor(executor);
      addTearDown(db.close);

      final novilla = await db.select(db.animales).getSingle();
      expect(novilla.identificador, 'N-1', reason: 'el animal no se pierde');
      expect(novilla.fechaNacimiento, isNull);

      // Y el grupo `toros` —lo que agregó el paso de la v12— sigue aceptándose.
      await (db.update(db.animales)..where((t) => t.id.equals('n1'))).write(
        const AnimalesCompanion(grupo: Value('toros'), sexo: Value('macho')),
      );
      expect((await db.select(db.animales).getSingle()).grupo, 'toros');
    },
  );
}
