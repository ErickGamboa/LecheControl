import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leche_control/data/local/database.dart';

/// v6 -> v7: entra la regla de la dieta de concentrado.
///
/// Lo que importa acá es que las lecherías que ya existen queden con una regla
/// usable sin tocar nada: si la columna llegara en null, la pantalla de dieta
/// no podría calcular ninguna ración.
void main() {
  test('la regla de concentrado arranca en 3 al migrar', () async {
    final executor = NativeDatabase.memory(
      setup: (raw) {
        // Esquema v6 de config_reporte: ya tiene el tope de kilos, todavía no
        // la regla de concentrado.
        raw.execute('''
      CREATE TABLE config_reporte (
        id TEXT NOT NULL PRIMARY KEY,
        lecheria_id TEXT NOT NULL,
        pct_excelente REAL NOT NULL DEFAULT 100,
        pct_bueno REAL NOT NULL DEFAULT 85,
        pct_vigilar REAL NOT NULL DEFAULT 70,
        pct_bajo REAL NOT NULL DEFAULT 60,
        umbral_secado_litros REAL NOT NULL DEFAULT 8,
        tope_kg_leche REAL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        pendiente INTEGER NOT NULL DEFAULT 0
      )''');
        raw.execute(
          'INSERT INTO config_reporte (id,lecheria_id,tope_kg_leche,'
          "created_at,updated_at) VALUES ('c1','l1',5000,"
          "'2026-01-01T00:00:00.000','2026-01-01T00:00:00.000')",
        );
        raw.execute('PRAGMA user_version = 6');
      },
    );

    final db = AppDatabase.forExecutor(executor);
    addTearDown(db.close);

    final config = await db.select(db.configReporte).getSingle();
    expect(config.kgLechePorKgConcentrado, 3);
    // Y lo que ya estaba configurado no se pierde en el camino.
    expect(config.topeKgLeche, 5000);
  });
}
