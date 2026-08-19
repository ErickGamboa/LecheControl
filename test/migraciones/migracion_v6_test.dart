import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leche_control/data/domain/grupos.dart';
import 'package:leche_control/data/local/database.dart';

/// v5 -> v6 sobre una base con datos: entra el tope de kilos y el evento de
/// observación.
///
/// El evento de observación obliga a recrear `eventos_animal` (el tipo vive en
/// un CHECK y SQLite no sabe cambiar uno), así que lo que hay que probar es
/// que **la hoja de vida que ya tenía el ganadero no se pierde** en el
/// camino.
void main() {
  /// Esquema v5 de las dos tablas que cambian, armado antes de que drift abra
  /// la base: si no existieran correría onCreate en vez de la migración.
  NativeDatabase baseV5() => NativeDatabase.memory(
    setup: (raw) {
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
      raw.execute(
        "INSERT INTO config_reporte (id,lecheria_id,created_at,updated_at) "
        "VALUES ('c1','l1','2026-01-01T00:00:00.000',"
        "'2026-01-01T00:00:00.000')",
      );
      raw.execute(
        'INSERT INTO eventos_animal (id,animal_id,lecheria_id,tipo,fecha,'
        "detalle,created_at,updated_at) VALUES ('e1','a1','l1','parto',"
        "'2026-02-10T00:00:00.000','nació hembra',"
        "'2026-02-10T00:00:00.000','2026-02-10T00:00:00.000')",
      );
      raw.execute('PRAGMA user_version = 5');
    },
  );

  test('el tope de kilos entra vacío, no en cero', () async {
    final db = AppDatabase.forExecutor(baseV5());
    addTearDown(db.close);

    final config = await db.select(db.configReporte).getSingle();
    // Vacío y no 0: un tope de cero haría saltar la alerta con la primera
    // entrega de la semana.
    expect(config.topeKgLeche, isNull);
    // Y lo que ya estaba configurado sigue en su lugar.
    expect(config.umbralSecadoLitros, 8);
  });

  test('recrear eventos_animal no borra la hoja de vida', () async {
    final db = AppDatabase.forExecutor(baseV5());
    addTearDown(db.close);

    final eventos = await db.select(db.eventosAnimal).get();
    expect(eventos, hasLength(1));
    expect(eventos.single.tipo, TipoEventoAnimal.parto);
    expect(eventos.single.detalle, 'nació hembra');
  });

  test('después de migrar se puede guardar una observación', () async {
    final db = AppDatabase.forExecutor(baseV5());
    addTearDown(db.close);

    final ahora = DateTime.utc(2026, 8, 18);
    await db
        .into(db.eventosAnimal)
        .insert(
          EventosAnimalCompanion.insert(
            id: 'e2',
            animalId: 'a1',
            lecheriaId: 'l1',
            tipo: TipoEventoAnimal.observacion,
            fecha: ahora,
            detalle: const Value('cojea de la pata de atrás'),
            createdAt: ahora,
            updatedAt: ahora,
          ),
        );

    final observacion =
        await (db.select(db.eventosAnimal)
              ..where((t) => t.tipo.equals(TipoEventoAnimal.observacion)))
            .getSingle();
    expect(observacion.detalle, 'cojea de la pata de atrás');
  });

  test('un tipo de evento inventado sigue rechazado', () async {
    final db = AppDatabase.forExecutor(baseV5());
    addTearDown(db.close);

    final ahora = DateTime.utc(2026, 8, 18);
    // El CHECK se amplió para que entre `observacion`, no para que entre
    // cualquier cosa: si se aflojara, un typo en el código se guardaría
    // silenciosamente.
    await expectLater(
      db
          .into(db.eventosAnimal)
          .insert(
            EventosAnimalCompanion.insert(
              id: 'e3',
              animalId: 'a1',
              lecheriaId: 'l1',
              tipo: 'observaciones',
              fecha: ahora,
              createdAt: ahora,
              updatedAt: ahora,
            ),
          ),
      throwsA(anything),
    );
  });
}
