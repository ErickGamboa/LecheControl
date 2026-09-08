// La base local pertenece a UNA cuenta a la vez.
//
// Antes no estaba marcada y nadie la limpiaba al cerrar sesión, así que los
// datos de dos cuentas quedaban mezclados en el mismo archivo. Pasó lo peor:
// se entraba con una cuenta y aparecía la lechería y los animales de la otra.
// Y de rebote, el teléfono de quien probaba la app se quedaba con la finca de
// verdad de un ganadero.

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leche_control/data/local/database.dart';
import 'package:leche_control/data/repositories/lecherias_repository.dart';

import '../support/local_db_seed.dart';

/// La misma regla que `prepararBaseParaUsuario`, sobre una base inyectada.
///
/// La de `services.dart` trabaja sobre la base global, que en un test no
/// existe; esto replica su decisión para poder probarla. Lo que se está
/// fijando es la **regla**: dueño distinto, base limpia.
Future<void> prepararPara(AppDatabase db, String usuarioId) async {
  const fila = 'actual';
  final dueno = await (db.select(
    db.duenoDatosLocales,
  )..where((t) => t.id.equals(fila))).getSingleOrNull();

  if (dueno?.usuarioId == usuarioId) return;

  if (dueno != null) {
    await db.transaction(() async {
      for (final t in <TableInfo<Table, dynamic>>[
        db.eventosAnimal,
        db.animales,
        db.lecheriaMiembros,
        db.lecherias,
        db.usuarios,
        db.cuentas,
        db.syncCursores,
        db.syncEstados,
      ]) {
        await db.delete(t).go();
      }
    });
  }

  await db.into(db.duenoDatosLocales).insertOnConflictUpdate(
    DuenoLocalRow(id: fila, usuarioId: usuarioId, desde: DateTime.now()),
  );
}

void main() {
  late AppDatabase db;
  late LecheriasRepository lecherias;

  setUp(() async {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    lecherias = LecheriasRepository(db);
  });

  tearDown(() async => db.close());

  /// Deja en la base una cuenta con su lechería y un animal, como queda
  /// después de sincronizar o de trabajar sin conexión.
  Future<void> sembrarCuenta({
    required String usuarioId,
    required String lecheriaId,
    required String nombreLecheria,
    required String animal,
  }) async {
    await seedCuentaLocal(
      db,
      usuarioId: usuarioId,
      cuentaId: 'cuenta-$usuarioId',
      email: '$usuarioId@ejemplo.com',
    );
    await seedLecheria(
      db,
      usuarioId: usuarioId,
      lecheriaId: lecheriaId,
      nombre: nombreLecheria,
      cuentaId: 'cuenta-$usuarioId',
    );
    await seedAnimal(
      db,
      lecheriaId: lecheriaId,
      id: 'animal-$usuarioId',
      identificador: animal,
    );
  }

  test('al entrar otra cuenta no queda nada de la anterior', () async {
    await sembrarCuenta(
      usuarioId: 'apple',
      lecheriaId: 'lech-apple',
      nombreLecheria: 'Lechería de prueba',
      animal: '777',
    );
    await prepararPara(db, 'apple');

    // Apple ve lo suyo.
    expect((await lecherias.obtenerActiva('apple'))?.nombre,
        'Lechería de prueba');

    // Entra otra cuenta en el mismo teléfono.
    await prepararPara(db, 'erick');

    expect(
      await db.select(db.lecherias).get(),
      isEmpty,
      reason: 'la lechería de la otra cuenta siguió en el teléfono',
    );
    expect(
      await db.select(db.animales).get(),
      isEmpty,
      reason: 'los animales de la otra cuenta siguieron en el teléfono',
    );
    expect(await db.select(db.cuentas).get(), isEmpty);
    expect(
      await lecherias.obtenerActiva('erick'),
      isNull,
      reason: 'la cuenta nueva no puede heredar la lechería de la anterior',
    );
  });

  test('volver a entrar con la misma cuenta no borra nada', () async {
    await sembrarCuenta(
      usuarioId: 'erick',
      lecheriaId: 'lech-erick',
      nombreLecheria: 'LecheriaErick',
      animal: '30',
    );
    await prepararPara(db, 'erick');
    await prepararPara(db, 'erick');
    await prepararPara(db, 'erick');

    expect((await lecherias.obtenerActiva('erick'))?.nombre, 'LecheriaErick');
    expect(await db.select(db.animales).get(), hasLength(1));
  });

  test('con la base sin marcar no se borra nada: es del que entra', () async {
    // Es lo que pasa al actualizar la app: los datos que hay son de quien
    // está entrando. Borrarlos sería tirarle el trabajo por una migración.
    await sembrarCuenta(
      usuarioId: 'erick',
      lecheriaId: 'lech-erick',
      nombreLecheria: 'LecheriaErick',
      animal: '30',
    );
    expect(await db.select(db.duenoDatosLocales).get(), isEmpty);

    await prepararPara(db, 'erick');

    expect((await lecherias.obtenerActiva('erick'))?.nombre, 'LecheriaErick');
    expect(
      (await db.select(db.duenoDatosLocales).getSingle()).usuarioId,
      'erick',
    );
  });

  test('también se van los cursores y el estado del sync', () async {
    await sembrarCuenta(
      usuarioId: 'apple',
      lecheriaId: 'lech-apple',
      nombreLecheria: 'Lechería de prueba',
      animal: '777',
    );
    await db.into(db.syncCursores).insert(
      SyncCursorRow(
        tabla: 'usuarios',
        usuarioId: 'apple',
        ultimaBajada: DateTime.utc(2026, 9, 7),
        ultimaBajadaId: 'apple',
      ),
    );
    await db.into(db.syncEstados).insert(
      SyncEstadosCompanion.insert(
        tabla: 'usuarios',
        ultimoError: const Value('algo falló'),
      ),
    );
    await prepararPara(db, 'apple');

    await prepararPara(db, 'erick');

    expect(await db.select(db.syncCursores).get(), isEmpty);
    expect(await db.select(db.syncEstados).get(), isEmpty);
  });
}
