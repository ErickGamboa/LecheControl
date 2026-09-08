import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leche_control/data/local/database.dart';

/// v9 -> v10: la base local queda marcada con la cuenta a la que pertenece.
///
/// La tabla nueva arranca **vacía a propósito**. En este punto de la migración
/// no se sabe quién está en sesión, así que marcarla acá sería inventar. Lo
/// hace `prepararBaseParaUsuario` al entrar, y como está vacía, el primero
/// que entre se adueña de lo que ya había sin borrar nada.
///
/// Eso es lo importante de esta migración: al actualizar la app, **el
/// ganadero no puede perder su lechería**.
void main() {
  test('marca la base sin borrarle nada al que ya la usaba', () async {
    final executor = NativeDatabase.memory(
      setup: (raw) {
        raw.execute('''
      CREATE TABLE lecherias (
        id TEXT NOT NULL PRIMARY KEY,
        nombre TEXT NOT NULL,
        creada_por TEXT NOT NULL,
        cuenta_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        pendiente INTEGER NOT NULL DEFAULT 0
      )''');
        raw.execute(
          "INSERT INTO lecherias (id,nombre,creada_por,created_at,updated_at) "
          "VALUES ('l1','LecheriaErick','u1','2026-07-30T19:55:35.000',"
          "'2026-07-30T19:55:35.000')",
        );
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
          "origen,created_at,updated_at) VALUES ('a1','l1','30','hembra',"
          "'en_ordeno','nacido','2026-08-01T00:00:00.000',"
          "'2026-08-01T00:00:00.000')",
        );
        raw.execute('PRAGMA user_version = 9');
      },
    );

    final db = AppDatabase.forExecutor(executor);
    addTearDown(db.close);

    // La tabla nueva existe y está vacía: nadie se adueñó todavía.
    expect(await db.select(db.duenoDatosLocales).get(), isEmpty);

    // Y lo del ganadero sigue entero. Esto es lo que no se puede romper.
    expect((await db.select(db.lecherias).getSingle()).nombre, 'LecheriaErick');
    expect((await db.select(db.animales).getSingle()).identificador, '30');
  });
}
