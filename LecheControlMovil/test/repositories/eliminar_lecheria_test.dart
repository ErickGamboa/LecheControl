// Borrar una finca.
//
// Es la operación más cara de la app: el ganadero pierde de vista todo lo que
// esa finca tiene adentro y no hay botón para traerlo de vuelta. Estas pruebas
// fijan las tres cosas que tienen que pasar sí o sí: que se vaya de la lista,
// que salga a subir para que se vaya también de los otros teléfonos, y que no
// se lleve por delante a la finca de al lado.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leche_control/data/local/database.dart';
import 'package:leche_control/data/repositories/lecherias_repository.dart';

import '../support/local_db_seed.dart';

void main() {
  late AppDatabase db;
  late LecheriasRepository repo;
  const usuarioId = 'user-1';

  setUp(() async {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    repo = LecheriasRepository(db);
    await seedCuentaLocal(db, usuarioId: usuarioId, limiteLecherias: 3);
  });

  tearDown(() async => db.close());

  Future<LecheriaRow> crear(String nombre) async {
    await repo.crearLecheria(nombre: nombre, creadaPor: usuarioId);
    final todas = await repo.observarLecheriasDeUsuario(usuarioId).first;
    return todas.firstWhere((l) => l.nombre == nombre);
  }

  test('la finca borrada se va de la lista', () async {
    final primera = await crear('La Esperanza');
    await crear('El Alto');

    await repo.eliminarLecheria(primera.id);

    final quedan = await repo.observarLecheriasDeUsuario(usuarioId).first;
    expect(quedan.map((l) => l.nombre), ['El Alto']);
  });

  test('queda pendiente de subir, para que se vaya de los otros teléfonos', () async {
    final lecheria = await crear('La Esperanza');

    await repo.eliminarLecheria(lecheria.id);

    final fila = await (db.select(
      db.lecherias,
    )..where((t) => t.id.equals(lecheria.id))).getSingle();
    expect(fila.deletedAt, isNotNull);
    expect(fila.pendiente, isTrue);

    // Y el vínculo del usuario con la finca también: si se quedara vivo, el
    // servidor la seguiría mandando de vuelta en cada bajada.
    final miembros = await (db.select(
      db.lecheriaMiembros,
    )..where((t) => t.lecheriaId.equals(lecheria.id))).get();
    expect(miembros, isNotEmpty);
    expect(miembros.every((m) => m.deletedAt != null && m.pendiente), isTrue);
  });

  test('no toca la finca de al lado', () async {
    final primera = await crear('La Esperanza');
    final segunda = await crear('El Alto');

    await repo.eliminarLecheria(primera.id);

    final viva = await (db.select(
      db.lecherias,
    )..where((t) => t.id.equals(segunda.id))).getSingle();
    expect(viva.deletedAt, isNull);

    final miembros = await (db.select(
      db.lecheriaMiembros,
    )..where((t) => t.lecheriaId.equals(segunda.id))).get();
    expect(miembros.every((m) => m.deletedAt == null), isTrue);
  });

  test('borrar libera el lugar para crear otra', () async {
    // La cuenta admite tres; con las tres puestas no cabe ninguna más.
    final primera = await crear('La Esperanza');
    await crear('El Alto');
    await crear('La Isla');
    expect(await repo.puedeAgregarLecheria(usuarioId), isFalse);

    await repo.eliminarLecheria(primera.id);

    expect(await repo.puedeAgregarLecheria(usuarioId), isTrue);
  });
}
