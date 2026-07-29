import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leche_control/data/local/database.dart';
import 'package:leche_control/data/repositories/pesas_repository.dart';

import '../support/local_db_seed.dart';

void main() {
  late AppDatabase db;
  late PesasRepository repo;
  const lecheriaId = 'lecheria-1';
  const animalId = 'animal-1';

  setUp(() async {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    repo = PesasRepository(db);
    await seedCuentaLocal(db, usuarioId: 'user-1');
    await seedLecheria(db, usuarioId: 'user-1', lecheriaId: lecheriaId);
    await seedAnimal(db, lecheriaId: lecheriaId, id: animalId);
  });

  tearDown(() async {
    await db.close();
  });

  group('abrirSesion', () {
    test('crea una sesión pendiente para el día', () async {
      final sesion = await repo.abrirSesion(
        lecheriaId: lecheriaId,
        fecha: DateTime(2026, 3, 10, 6),
      );

      expect(sesion.lecheriaId, lecheriaId);
      expect(sesion.cerrada, isFalse);
      expect(sesion.pendiente, isTrue);
    });

    test(
      'reutiliza la sesión abierta del mismo día en vez de duplicar',
      () async {
        final primera = await repo.abrirSesion(
          lecheriaId: lecheriaId,
          fecha: DateTime(2026, 3, 10, 6),
        );
        final segunda = await repo.abrirSesion(
          lecheriaId: lecheriaId,
          fecha: DateTime(2026, 3, 10, 18),
        );

        expect(segunda.id, primera.id);
        expect(await db.select(db.pesasSesiones).get(), hasLength(1));
      },
    );

    test('abre una sesión nueva si la del día ya está cerrada', () async {
      final primera = await repo.abrirSesion(
        lecheriaId: lecheriaId,
        fecha: DateTime(2026, 3, 10, 6),
      );
      await repo.cerrarSesion(primera.id);

      final segunda = await repo.abrirSesion(
        lecheriaId: lecheriaId,
        fecha: DateTime(2026, 3, 10, 18),
      );

      expect(segunda.id, isNot(primera.id));
      expect(await db.select(db.pesasSesiones).get(), hasLength(2));
    });
  });

  group('registrarPesa', () {
    test('registra los litros de un animal en la sesión', () async {
      final sesion = await repo.abrirSesion(lecheriaId: lecheriaId);

      final existente = await repo.registrarPesa(
        sesionId: sesion.id,
        animalId: animalId,
        litros: 18.5,
      );

      expect(existente, isNull, reason: 'null significa que se guardó');
      final pesas = await db.select(db.pesasLeche).get();
      expect(pesas, hasLength(1));
      expect(pesas.single.litros, 18.5);
      expect(pesas.single.pendiente, isTrue);
    });

    test(
      'no duplica la pesa del mismo animal en la sesión sin pedir corregir',
      () async {
        final sesion = await repo.abrirSesion(lecheriaId: lecheriaId);
        await repo.registrarPesa(
          sesionId: sesion.id,
          animalId: animalId,
          litros: 18.5,
        );

        final existente = await repo.registrarPesa(
          sesionId: sesion.id,
          animalId: animalId,
          litros: 20,
        );

        expect(existente, isNotNull);
        expect(existente!.litros, 18.5);
        final pesas = await db.select(db.pesasLeche).get();
        expect(pesas, hasLength(1), reason: 'no se debe duplicar la fila');
        expect(pesas.single.litros, 18.5, reason: 'no se debe sobrescribir');
      },
    );

    test('corrige la pesa existente cuando se pide explícitamente', () async {
      final sesion = await repo.abrirSesion(lecheriaId: lecheriaId);
      await repo.registrarPesa(
        sesionId: sesion.id,
        animalId: animalId,
        litros: 18.5,
      );

      final resultado = await repo.registrarPesa(
        sesionId: sesion.id,
        animalId: animalId,
        litros: 20,
        corregir: true,
      );

      expect(resultado, isNull);
      final pesas = await db.select(db.pesasLeche).get();
      expect(pesas, hasLength(1), reason: 'corrige, no duplica');
      expect(pesas.single.litros, 20);
    });
  });

  test(
    'resumenSesion calcula totales y variación contra la anterior',
    () async {
      final ayer = await repo.abrirSesion(
        lecheriaId: lecheriaId,
        fecha: DateTime(2026, 3, 9, 6),
      );
      await repo.registrarPesa(
        sesionId: ayer.id,
        animalId: animalId,
        litros: 10,
      );
      await repo.cerrarSesion(ayer.id);

      final hoy = await repo.abrirSesion(
        lecheriaId: lecheriaId,
        fecha: DateTime(2026, 3, 10, 6),
      );
      await seedAnimal(
        db,
        lecheriaId: lecheriaId,
        id: 'animal-2',
        identificador: 'A-2',
      );
      await repo.registrarPesa(
        sesionId: hoy.id,
        animalId: animalId,
        litros: 12,
      );
      await repo.registrarPesa(
        sesionId: hoy.id,
        animalId: 'animal-2',
        litros: 8,
      );

      final resumen = await repo.resumenSesion(hoy.id);

      expect(resumen.totalVacas, 2);
      expect(resumen.totalLitros, 20);
      expect(resumen.promedio, 10);
      expect(resumen.maximo, 12);
      expect(resumen.minimo, 8);
      expect(resumen.variacionRespectoAnterior, 10);
    },
  );

  test(
    'ultimaProduccion devuelve los litros de la sesión más reciente',
    () async {
      final sesion1 = await repo.abrirSesion(
        lecheriaId: lecheriaId,
        fecha: DateTime(2026, 3, 9, 6),
      );
      await repo.registrarPesa(
        sesionId: sesion1.id,
        animalId: animalId,
        litros: 10,
      );
      await repo.cerrarSesion(sesion1.id);
      final sesion2 = await repo.abrirSesion(
        lecheriaId: lecheriaId,
        fecha: DateTime(2026, 3, 10, 6),
      );
      await repo.registrarPesa(
        sesionId: sesion2.id,
        animalId: animalId,
        litros: 14,
      );

      expect(await repo.ultimaProduccion(animalId), 14);
    },
  );
}
