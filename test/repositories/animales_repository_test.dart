import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leche_control/data/domain/grupos.dart';
import 'package:leche_control/data/local/database.dart';
import 'package:leche_control/data/repositories/animales_repository.dart';

import '../support/local_db_seed.dart';

void main() {
  late AppDatabase db;
  late AnimalesRepository repo;
  const lecheriaId = 'lecheria-1';

  setUp(() async {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    repo = AnimalesRepository(db);
    await seedCuentaLocal(db, usuarioId: 'user-1');
    await seedLecheria(db, usuarioId: 'user-1', lecheriaId: lecheriaId);
  });

  tearDown(() async {
    await db.close();
  });

  group('altaAnimal', () {
    test('crea el animal pendiente con los valores por defecto', () async {
      final id = await repo.altaAnimal(
        lecheriaId: lecheriaId,
        identificador: 'A-100',
        sexo: Sexo.hembra,
        grupo: GrupoAnimal.enOrdeno,
        origen: OrigenAnimal.nacido,
      );

      final animal = await (db.select(
        db.animales,
      )..where((t) => t.id.equals(id))).getSingle();

      expect(animal.identificador, 'A-100');
      expect(animal.lecheriaId, lecheriaId);
      expect(animal.sexo, Sexo.hembra);
      expect(animal.grupo, GrupoAnimal.enOrdeno);
      expect(animal.origen, OrigenAnimal.nacido);
      expect(animal.estado, EstadoAnimal.activo);
      expect(animal.estadoReproductivo, EstadoReproductivo.desconocido);
      expect(animal.pendiente, isTrue);
      expect(animal.deletedAt, isNull);
    });

    test('guarda precio y fecha de compra solo cuando el origen es '
        'comprado', () async {
      final fechaCompra = DateTime(2026, 1, 15);
      final id = await repo.altaAnimal(
        lecheriaId: lecheriaId,
        identificador: 'A-101',
        sexo: Sexo.hembra,
        grupo: GrupoAnimal.enOrdeno,
        origen: OrigenAnimal.comprado,
        precioCompra: 500,
        fechaCompra: fechaCompra,
      );

      final animal = await (db.select(
        db.animales,
      )..where((t) => t.id.equals(id))).getSingle();

      expect(animal.precioCompra, 500);
      expect(animal.fechaCompra, fechaCompra);
    });

    test(
      'rechaza un identificador duplicado activo en la misma lechería',
      () async {
        await repo.altaAnimal(
          lecheriaId: lecheriaId,
          identificador: 'A-100',
          sexo: Sexo.hembra,
          grupo: GrupoAnimal.enOrdeno,
          origen: OrigenAnimal.nacido,
        );

        expect(
          () => repo.altaAnimal(
            lecheriaId: lecheriaId,
            identificador: 'A-100',
            sexo: Sexo.macho,
            grupo: GrupoAnimal.terneros,
            origen: OrigenAnimal.nacido,
          ),
          throwsA(isA<AnimalDuplicadoException>()),
        );

        final animales = await db.select(db.animales).get();
        expect(animales, hasLength(1));
      },
    );

    test(
      'permite reusar el identificador de un animal en otra lechería',
      () async {
        const otraLecheria = 'lecheria-2';
        await seedLecheria(
          db,
          usuarioId: 'user-1',
          lecheriaId: otraLecheria,
          nombre: 'Otra lechería',
        );
        await repo.altaAnimal(
          lecheriaId: lecheriaId,
          identificador: 'A-100',
          sexo: Sexo.hembra,
          grupo: GrupoAnimal.enOrdeno,
          origen: OrigenAnimal.nacido,
        );

        await repo.altaAnimal(
          lecheriaId: otraLecheria,
          identificador: 'A-100',
          sexo: Sexo.hembra,
          grupo: GrupoAnimal.enOrdeno,
          origen: OrigenAnimal.nacido,
        );

        expect(await db.select(db.animales).get(), hasLength(2));
      },
    );
  });

  group('buscarPorIdentificador', () {
    test('encuentra el animal dentro de su lechería', () async {
      await repo.altaAnimal(
        lecheriaId: lecheriaId,
        identificador: 'A-100',
        sexo: Sexo.hembra,
        grupo: GrupoAnimal.enOrdeno,
        origen: OrigenAnimal.nacido,
      );

      final encontrado = await repo.buscarPorIdentificador(lecheriaId, 'A-100');

      expect(encontrado, isNotNull);
      expect(encontrado!.identificador, 'A-100');
    });

    test('devuelve null si no existe o pertenece a otra lechería', () async {
      expect(
        await repo.buscarPorIdentificador(lecheriaId, 'NO-EXISTE'),
        isNull,
      );
    });
  });

  group('registrarBaja', () {
    test(
      'aplica una baja suave: cambia el estado pero no borra la fila',
      () async {
        final id = await repo.altaAnimal(
          lecheriaId: lecheriaId,
          identificador: 'A-100',
          sexo: Sexo.hembra,
          grupo: GrupoAnimal.enOrdeno,
          origen: OrigenAnimal.nacido,
        );

        await repo.registrarBaja(
          animalId: id,
          lecheriaId: lecheriaId,
          motivo: MotivoBaja.venta,
          precioVenta: 1200,
          registradoPor: 'user-1',
        );

        final animal = await (db.select(
          db.animales,
        )..where((t) => t.id.equals(id))).getSingle();
        expect(animal.estado, EstadoAnimal.vendido);
        expect(animal.deletedAt, isNull, reason: 'D-08: nada se borra');
        expect(animal.pendiente, isTrue);

        final eventos = await db.select(db.eventosAnimal).get();
        expect(eventos, hasLength(1));
        expect(eventos.single.tipo, TipoEventoAnimal.baja);
        expect(eventos.single.motivoBaja, MotivoBaja.venta);
        expect(eventos.single.precioVenta, 1200);
      },
    );

    test('el animal dado de baja desaparece del inventario activo pero '
        'aparece en el historial de bajas', () async {
      final id = await repo.altaAnimal(
        lecheriaId: lecheriaId,
        identificador: 'A-100',
        sexo: Sexo.hembra,
        grupo: GrupoAnimal.enOrdeno,
        origen: OrigenAnimal.nacido,
      );
      await repo.registrarBaja(
        animalId: id,
        lecheriaId: lecheriaId,
        motivo: MotivoBaja.muerte,
      );

      final inventario = await repo.observarInventario(lecheriaId).first;
      final historial = await repo.observarHistorialBajas(lecheriaId).first;

      expect(inventario, isEmpty);
      expect(historial, hasLength(1));
      expect(historial.single.id, id);
      expect(historial.single.estado, EstadoAnimal.muerto);
    });
  });

  test(
    'cambiarGrupo mueve al animal y deja constancia en la hoja de vida',
    () async {
      final id = await repo.altaAnimal(
        lecheriaId: lecheriaId,
        identificador: 'A-100',
        sexo: Sexo.hembra,
        grupo: GrupoAnimal.novillas,
        origen: OrigenAnimal.nacido,
      );

      await repo.cambiarGrupo(
        animalId: id,
        lecheriaId: lecheriaId,
        nuevoGrupo: GrupoAnimal.enOrdeno,
        registradoPor: 'user-1',
      );

      final animal = await (db.select(
        db.animales,
      )..where((t) => t.id.equals(id))).getSingle();
      expect(animal.grupo, GrupoAnimal.enOrdeno);

      final eventos = await db.select(db.eventosAnimal).get();
      expect(eventos.single.tipo, TipoEventoAnimal.cambioGrupo);
      expect(eventos.single.grupoAnterior, GrupoAnimal.novillas);
      expect(eventos.single.grupoNuevo, GrupoAnimal.enOrdeno);
    },
  );
}
