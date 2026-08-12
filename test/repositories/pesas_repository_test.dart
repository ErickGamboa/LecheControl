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

    test('con dos sesiones abiertas del día, reutiliza la primera', () async {
      // Pasa de verdad: dos dispositivos pesando sin señal el mismo día,
      // cada uno crea la suya, y al sincronizar quedan las dos.
      await db
          .into(db.pesasSesiones)
          .insert(
            PesasSesionesCompanion.insert(
              id: 'sesion-a',
              lecheriaId: lecheriaId,
              fecha: DateTime(2026, 3, 10, 6),
              createdAt: DateTime(2026, 3, 10, 6),
              updatedAt: DateTime(2026, 3, 10, 6),
            ),
          );
      await db
          .into(db.pesasSesiones)
          .insert(
            PesasSesionesCompanion.insert(
              id: 'sesion-b',
              lecheriaId: lecheriaId,
              fecha: DateTime(2026, 3, 10, 15),
              createdAt: DateTime(2026, 3, 10, 15),
              updatedAt: DateTime(2026, 3, 10, 15),
            ),
          );

      final sesion = await repo.abrirSesion(
        lecheriaId: lecheriaId,
        fecha: DateTime(2026, 3, 10, 18),
      );

      expect(sesion.id, 'sesion-a');
      expect(
        await db.select(db.pesasSesiones).get(),
        hasLength(2),
        reason: 'no se debe crear una tercera',
      );
    });

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
        litrosTotal: 18.5,
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
          litrosTotal: 18.5,
        );

        final existente = await repo.registrarPesa(
          sesionId: sesion.id,
          animalId: animalId,
          litrosTotal: 20,
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
        litrosTotal: 18.5,
      );

      final resultado = await repo.registrarPesa(
        sesionId: sesion.id,
        animalId: animalId,
        litrosTotal: 20,
        corregir: true,
      );

      expect(resultado, isNull);
      final pesas = await db.select(db.pesasLeche).get();
      expect(pesas, hasLength(1), reason: 'corrige, no duplica');
      expect(pesas.single.litros, 20);
    });

    test('suma mañana y tarde para el total del día', () async {
      final sesion = await repo.abrirSesion(lecheriaId: lecheriaId);

      await repo.registrarPesa(
        sesionId: sesion.id,
        animalId: animalId,
        litrosManana: 9.5,
        litrosTarde: 8,
        concentradoKg: 4.5,
      );

      final pesa = (await db.select(db.pesasLeche).get()).single;
      expect(pesa.litros, 17.5);
      expect(pesa.litrosManana, 9.5);
      expect(pesa.litrosTarde, 8);
      expect(pesa.concentradoKg, 4.5);
    });

    test(
      'acepta un solo ordeño (la vaca que solo se ordeña de mañana)',
      () async {
        final sesion = await repo.abrirSesion(lecheriaId: lecheriaId);

        await repo.registrarPesa(
          sesionId: sesion.id,
          animalId: animalId,
          litrosManana: 12,
        );

        final pesa = (await db.select(db.pesasLeche).get()).single;
        expect(pesa.litros, 12);
        expect(pesa.litrosTarde, isNull);
      },
    );

    test('pesa una vaca manual, sin ficha en el inventario', () async {
      final sesion = await repo.abrirSesion(lecheriaId: lecheriaId);

      await repo.registrarPesa(
        sesionId: sesion.id,
        identificadorManual: '8890',
        litrosManana: 6.7,
        litrosTarde: 6.5,
      );

      final pesa = (await db.select(db.pesasLeche).get()).single;
      expect(pesa.animalId, isNull);
      expect(pesa.identificadorManual, '8890');
      expect(pesa.litros, closeTo(13.2, 0.001));
    });

    test('la vaca manual tampoco se duplica en la misma sesión', () async {
      final sesion = await repo.abrirSesion(lecheriaId: lecheriaId);
      await repo.registrarPesa(
        sesionId: sesion.id,
        identificadorManual: '8890',
        litrosManana: 6,
      );

      final existente = await repo.registrarPesa(
        sesionId: sesion.id,
        identificadorManual: '8890',
        litrosManana: 9,
      );

      expect(existente, isNotNull);
      expect(await db.select(db.pesasLeche).get(), hasLength(1));
    });
  });

  group('faltantesDeSesion', () {
    test('lista las vacas en ordeño que todavía no se pesaron', () async {
      await seedAnimal(
        db,
        lecheriaId: lecheriaId,
        id: 'animal-2',
        identificador: 'A-2',
      );
      final sesion = await repo.abrirSesion(lecheriaId: lecheriaId);
      await repo.registrarPesa(
        sesionId: sesion.id,
        animalId: animalId,
        litrosManana: 10,
      );

      final faltantes = await repo.faltantesDeSesion(
        lecheriaId: lecheriaId,
        sesionId: sesion.id,
      );

      expect(faltantes.map((a) => a.id), ['animal-2']);
    });

    test('una vaca manual no tacha a ninguna del inventario', () async {
      final sesion = await repo.abrirSesion(lecheriaId: lecheriaId);
      await repo.registrarPesa(
        sesionId: sesion.id,
        identificadorManual: '8890',
        litrosManana: 6,
      );

      final faltantes = await repo.faltantesDeSesion(
        lecheriaId: lecheriaId,
        sesionId: sesion.id,
      );

      expect(
        faltantes.map((a) => a.id),
        [animalId],
        reason: 'la manual es extra: no cubre a la vaca registrada',
      );
    });
  });

  group('observarDetalleSesion', () {
    test('trae la ficha de la vaca, y null para las manuales', () async {
      final sesion = await repo.abrirSesion(lecheriaId: lecheriaId);
      await repo.registrarPesa(
        sesionId: sesion.id,
        animalId: animalId,
        litrosManana: 10,
      );
      await repo.registrarPesa(
        sesionId: sesion.id,
        identificadorManual: '8890',
        litrosManana: 6,
      );

      final detalle = await repo.observarDetalleSesion(sesion.id).first;

      expect(detalle, hasLength(2));
      final manual = detalle.firstWhere((d) => d.esManual);
      final registrada = detalle.firstWhere((d) => !d.esManual);
      expect(manual.animal, isNull);
      expect(manual.etiqueta, '8890 *');
      expect(registrada.animal!.id, animalId);
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
        litrosTotal: 10,
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
        litrosTotal: 12,
      );
      await repo.registrarPesa(
        sesionId: hoy.id,
        animalId: 'animal-2',
        litrosTotal: 8,
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
        litrosTotal: 10,
      );
      await repo.cerrarSesion(sesion1.id);
      final sesion2 = await repo.abrirSesion(
        lecheriaId: lecheriaId,
        fecha: DateTime(2026, 3, 10, 6),
      );
      await repo.registrarPesa(
        sesionId: sesion2.id,
        animalId: animalId,
        litrosTotal: 14,
      );

      expect(await repo.ultimaProduccion(animalId), 14);
    },
  );
}
