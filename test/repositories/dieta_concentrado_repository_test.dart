import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leche_control/data/domain/grupos.dart';
import 'package:leche_control/data/local/database.dart';
import 'package:leche_control/data/repositories/pesas_repository.dart';

import '../support/local_db_seed.dart';

/// La dieta se arma con **la última pesa de cada vaca**, no con la última pesa
/// de la finca: lo que se prueba acá es que cada vaca traiga la suya y que no
/// entren las que no comen concentrado de producción.
void main() {
  late AppDatabase db;
  late PesasRepository repo;
  const lecheriaId = 'lecheria-1';

  setUp(() async {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    repo = PesasRepository(db);
    await seedCuentaLocal(db, usuarioId: 'user-1');
    await seedLecheria(db, usuarioId: 'user-1', lecheriaId: lecheriaId);
  });

  tearDown(() async {
    await db.close();
  });

  /// Pesa a [animalId] (o a una vaca manual) en una sesión con esa fecha.
  Future<void> pesar({
    required DateTime fecha,
    String? animalId,
    String? manual,
    required double litros,
    double? concentradoKg,
  }) async {
    final sesion = await repo.abrirSesion(lecheriaId: lecheriaId, fecha: fecha);
    await repo.registrarPesa(
      sesionId: sesion.id,
      animalId: animalId,
      identificadorManual: manual,
      litrosTotal: litros,
      concentradoKg: concentradoKg,
    );
    await repo.cerrarSesion(sesion.id);
  }

  test('cada vaca entra con su pesa más reciente', () async {
    await seedAnimal(db, lecheriaId: lecheriaId, id: 'a1', identificador: '1');
    // Dos semanas distintas: la dieta tiene que usar la segunda.
    await pesar(fecha: DateTime(2026, 8, 10), animalId: 'a1', litros: 12);
    await pesar(fecha: DateTime(2026, 8, 17), animalId: 'a1', litros: 18);

    final dieta = await repo.dietaConcentrado(lecheriaId, kgLechePorKg: 3);

    expect(dieta, hasLength(1));
    expect(dieta.single.litrosLeche, 18);
    expect(dieta.single.racionKg, 6);
    expect(dieta.single.fechaPesa, DateTime(2026, 8, 17));
  });

  test('una vaca que no se pesó esta semana entra con la anterior', () async {
    await seedAnimal(db, lecheriaId: lecheriaId, id: 'a1', identificador: '1');
    await seedAnimal(db, lecheriaId: lecheriaId, id: 'a2', identificador: '2');

    // La 1 se pesó las dos semanas; la 2 solo la primera.
    await pesar(fecha: DateTime(2026, 8, 10), animalId: 'a1', litros: 12);
    await pesar(fecha: DateTime(2026, 8, 10), animalId: 'a2', litros: 9);
    await pesar(fecha: DateTime(2026, 8, 17), animalId: 'a1', litros: 18);

    final dieta = await repo.dietaConcentrado(lecheriaId, kgLechePorKg: 3);

    // Ninguna se queda sin ración, y cada fila dice de qué día viene.
    expect(dieta.map((r) => r.identificador), ['1', '2']);
    expect(dieta[0].fechaPesa, DateTime(2026, 8, 17));
    expect(dieta[1].fechaPesa, DateTime(2026, 8, 10));
    expect(dieta[1].racionKg, 3);
  });

  test('trae el concentrado anotado y la diferencia', () async {
    await seedAnimal(db, lecheriaId: lecheriaId, id: 'a1', identificador: '1');
    await pesar(
      fecha: DateTime(2026, 8, 17),
      animalId: 'a1',
      litros: 18,
      concentradoKg: 4,
    );

    final fila = (await repo.dietaConcentrado(
      lecheriaId,
      kgLechePorKg: 3,
    )).single;

    expect(fila.concentradoActualKg, 4);
    expect(fila.racionKg, 6);
    expect(fila.diferenciaKg, 2);
  });

  test('las vacas secas quedan fuera de la dieta', () async {
    await seedAnimal(
      db,
      lecheriaId: lecheriaId,
      id: 'a1',
      identificador: '1',
      grupo: GrupoAnimal.secas,
    );
    // Se pesó cuando estaba en ordeño, pero hoy está seca: no come
    // concentrado de producción.
    await pesar(fecha: DateTime(2026, 8, 17), animalId: 'a1', litros: 10);

    expect(await repo.dietaConcentrado(lecheriaId, kgLechePorKg: 3), isEmpty);
  });

  test('las vacas manuales entran, marcadas como tales', () async {
    await pesar(fecha: DateTime(2026, 8, 17), manual: '77', litros: 15);

    final fila = (await repo.dietaConcentrado(
      lecheriaId,
      kgLechePorKg: 3,
    )).single;

    // No tienen ficha que consultar, pero su leche es real.
    expect(fila.identificador, '77');
    expect(fila.esManual, isTrue);
    expect(fila.racionKg, 5);
  });

  test('una pesa borrada no manda en la dieta', () async {
    await seedAnimal(db, lecheriaId: lecheriaId, id: 'a1', identificador: '1');
    await pesar(fecha: DateTime(2026, 8, 10), animalId: 'a1', litros: 12);
    await pesar(fecha: DateTime(2026, 8, 17), animalId: 'a1', litros: 30);

    // Se borra la pesa nueva (se anotó mal): la dieta vuelve a la anterior.
    await (db.update(db.pesasLeche)..where((t) => t.litros.equals(30))).write(
      PesasLecheCompanion(deletedAt: Value(DateTime(2026, 8, 18))),
    );

    final fila = (await repo.dietaConcentrado(
      lecheriaId,
      kgLechePorKg: 3,
    )).single;
    expect(fila.litrosLeche, 12);
  });

  test('las vacas se ordenan como las lee una persona', () async {
    for (final id in ['10', '2', '1']) {
      await seedAnimal(
        db,
        lecheriaId: lecheriaId,
        id: 'a$id',
        identificador: id,
      );
      await pesar(fecha: DateTime(2026, 8, 17), animalId: 'a$id', litros: 12);
    }

    final dieta = await repo.dietaConcentrado(lecheriaId, kgLechePorKg: 3);
    expect(dieta.map((r) => r.identificador), ['1', '2', '10']);
  });
}
