import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leche_control/data/local/database.dart';

/// v7 -> v8: entra la calidad de la leche.
///
/// El teléfono del ganadero ya tiene semanas cargadas con sus finanzas: al
/// actualizar la app tiene que aparecer la tabla nueva sin que se pierda nada
/// de lo que ya estaba.
void main() {
  test('crea calidad_leche sin tocar las semanas que ya estaban', () async {
    final executor = NativeDatabase.memory(
      setup: (raw) {
        // Esquema v7 de `semanas`: la calidad todavía no existe.
        raw.execute('''
      CREATE TABLE semanas (
        id TEXT NOT NULL PRIMARY KEY,
        lecheria_id TEXT NOT NULL,
        fecha_inicio TEXT NOT NULL,
        fecha_fin TEXT NOT NULL,
        cerrada INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        pendiente INTEGER NOT NULL DEFAULT 0
      )''');
        raw.execute(
          'INSERT INTO semanas (id,lecheria_id,fecha_inicio,fecha_fin,'
          "created_at,updated_at) VALUES ('s1','l1',"
          "'2026-08-10T00:00:00.000','2026-08-16T00:00:00.000',"
          "'2026-08-10T00:00:00.000','2026-08-10T00:00:00.000')",
        );
        raw.execute('PRAGMA user_version = 7');
      },
    );

    final db = AppDatabase.forExecutor(executor);
    addTearDown(db.close);

    // La tabla nueva existe y arranca vacía.
    expect(await db.select(db.calidadLeche).get(), isEmpty);
    // Y la semana que ya estaba cargada sigue ahí.
    final semana = await db.select(db.semanas).getSingle();
    expect(semana.id, 's1');

    // El índice único de una lectura por semana quedó creado: dos lecturas
    // para la misma semana tienen que reventar acá y no en el servidor.
    final ahora = DateTime(2026, 8, 12);
    Future<void> insertar(String id) => db
        .into(db.calidadLeche)
        .insert(
          CalidadLecheRow(
            id: id,
            lecheriaId: 'l1',
            semanaId: 's1',
            conteoBacterial: 300000,
            createdAt: ahora,
            updatedAt: ahora,
            pendiente: true,
          ),
        );

    await insertar('c1');
    await expectLater(insertar('c2'), throwsA(anything));
  });
}
