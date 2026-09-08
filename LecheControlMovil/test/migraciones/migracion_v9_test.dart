import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leche_control/data/local/database.dart';

/// v8 -> v9: el cursor de bajada pasa a ser por usuario.
///
/// Es la migración que corre en el teléfono de cada ganadero al actualizar, y
/// ahí ya hay datos: animales, pesas, finanzas. La tabla de cursores se
/// **recrea** —cambia la clave primaria, no se le puede agregar la columna— y
/// eso significa perder los cursores. Es a propósito y no cuesta nada: quedar
/// sin cursor solo hace que la próxima bajada venga completa, y de paso
/// destraba a cualquier cuenta que hoy esté detrás de un cursor ajeno.
///
/// Lo que **no** se puede perder es el resto: eso es lo que se prueba acá.
void main() {
  test('recrea los cursores sin tocar los datos del ganadero', () async {
    final executor = NativeDatabase.memory(
      setup: (raw) {
        // Esquema v8 de `sync_cursores`: la clave era solo la tabla.
        raw.execute('''
      CREATE TABLE sync_cursores (
        tabla TEXT NOT NULL PRIMARY KEY,
        ultima_bajada TEXT,
        ultima_bajada_id TEXT
      )''');
        raw.execute(
          "INSERT INTO sync_cursores (tabla, ultima_bajada, ultima_bajada_id) "
          "VALUES ('usuarios','2026-09-07T20:44:37.000','user-a')",
        );

        // Y datos de verdad del ganadero, que tienen que sobrevivir.
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
        fecha_compra TEXT,
        madre_id TEXT,
        fecha_probable_parto TEXT,
        retiro_leche_hasta TEXT,
        fecha_ultimo_parto TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        pendiente INTEGER NOT NULL DEFAULT 0
      )''');
        raw.execute(
          "INSERT INTO animales (id,lecheria_id,identificador,sexo,grupo,"
          "origen,created_at,updated_at) VALUES ('a1','l1','1001','hembra',"
          "'en_ordeno','nacido','2026-08-01T00:00:00.000',"
          "'2026-08-01T00:00:00.000')",
        );
        raw.execute('PRAGMA user_version = 8');
      },
    );

    final db = AppDatabase.forExecutor(executor);
    addTearDown(db.close);

    // Los cursores arrancan de cero: la próxima bajada viene completa.
    expect(await db.select(db.syncCursores).get(), isEmpty);

    // Y la tabla nueva acepta el mismo nombre de tabla para dos usuarios,
    // que es justo lo que antes no se podía.
    await db.into(db.syncCursores).insert(
      SyncCursorRow(
        tabla: 'usuarios',
        usuarioId: 'user-a',
        ultimaBajada: DateTime.utc(2026, 9, 7, 20, 44, 37),
        ultimaBajadaId: 'user-a',
      ),
    );
    await db.into(db.syncCursores).insert(
      SyncCursorRow(
        tabla: 'usuarios',
        usuarioId: 'user-b',
        ultimaBajada: DateTime.utc(2026, 9, 7, 20, 36, 39),
        ultimaBajadaId: 'user-b',
      ),
    );
    expect(await db.select(db.syncCursores).get(), hasLength(2));

    // Lo del ganadero sigue intacto.
    final animal = await db.select(db.animales).getSingle();
    expect(animal.id, 'a1');
    expect(animal.identificador, '1001');
  });
}
