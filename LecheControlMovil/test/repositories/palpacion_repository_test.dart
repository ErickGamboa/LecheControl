// La regla de quién se palpa ya se prueba sola en test/domain. Acá se prueba
// lo que el repositorio agrega: que arme bien la lista desde la base —el
// último servicio de cada vaca, la última palpación— y que no meta animales
// que no van.

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leche_control/data/domain/grupos.dart';
import 'package:leche_control/data/domain/palpacion.dart';
import 'package:leche_control/data/domain/servir.dart';
import 'package:leche_control/data/local/database.dart';
import 'package:leche_control/data/repositories/palpacion_repository.dart';

import '../support/local_db_seed.dart';

void main() {
  late AppDatabase db;
  late PalpacionRepository repo;
  const lecheriaId = 'lecheria-1';
  final hoy = DateTime(2026, 8, 26);
  var contador = 0;

  Future<void> evento({
    required String animalId,
    required String tipo,
    required DateTime fecha,
    String? toroPajilla,
  }) async {
    await db
        .into(db.eventosAnimal)
        .insert(
          EventosAnimalCompanion.insert(
            id: 'evento-${contador++}',
            animalId: animalId,
            lecheriaId: lecheriaId,
            tipo: tipo,
            fecha: fecha,
            toroPajilla: Value(toroPajilla),
            createdAt: fecha,
            updatedAt: fecha,
          ),
        );
  }

  setUp(() async {
    contador = 0;
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    repo = PalpacionRepository(db);
    await seedCuentaLocal(db, usuarioId: 'user-1');
    await seedLecheria(db, usuarioId: 'user-1', lecheriaId: lecheriaId);
  });

  tearDown(() async {
    await db.close();
  });

  test('junta las paridas sin diagnóstico con las servidas', () async {
    // Parió el 10 de agosto: 16 días, ya pasó el margen y nadie le registró
    // preñez ni vacío. Con 4 días todavía no entraría.
    await seedAnimal(
      db,
      lecheriaId: lecheriaId,
      id: 'a1',
      identificador: '1001',
      fechaUltimoParto: DateTime(2026, 8, 10),
    );
    await seedAnimal(
      db,
      lecheriaId: lecheriaId,
      id: 'a2',
      identificador: '1002',
      fechaUltimoParto: DateTime(2026, 3, 1),
    );
    await evento(
      animalId: 'a2',
      tipo: TipoEventoAnimal.inseminacion,
      fecha: DateTime(2026, 7, 1),
      toroPajilla: 'Pajilla 44',
    );

    final lista = await repo.porPalpar(lecheriaId, hoy: hoy);

    // La servida va primero: es el motivo que manda.
    expect(lista.map((v) => v.identificador), ['1002', '1001']);
    expect(lista.first.motivo, MotivoPalpacion.servidaSinConfirmar);
    expect(lista.last.motivo, MotivoPalpacion.paridaSinDiagnostico);
    expect(lista.last.dias, 16);
    expect(lista.first.detalleServicio, 'Inseminación · Pajilla 44');
  });

  test('usa el servicio más reciente cuando hay varios', () async {
    await seedAnimal(
      db,
      lecheriaId: lecheriaId,
      id: 'a1',
      identificador: '1001',
      fechaUltimoParto: DateTime(2026, 3, 1),
    );
    await evento(
      animalId: 'a1',
      tipo: TipoEventoAnimal.celo,
      fecha: DateTime(2026, 6, 1),
    );
    await evento(
      animalId: 'a1',
      tipo: TipoEventoAnimal.monta,
      fecha: DateTime(2026, 7, 20),
      toroPajilla: 'Toro Nero',
    );

    final lista = await repo.porPalpar(lecheriaId, hoy: hoy);

    expect(lista.single.fecha, DateTime(2026, 7, 20));
    expect(lista.single.detalleServicio, 'Monta · Toro Nero');
  });

  test('la palpación registrada saca a la vaca de la lista', () async {
    await seedAnimal(
      db,
      lecheriaId: lecheriaId,
      id: 'a1',
      identificador: '1001',
      fechaUltimoParto: DateTime(2026, 3, 1),
    );
    await evento(
      animalId: 'a1',
      tipo: TipoEventoAnimal.monta,
      fecha: DateTime(2026, 7, 1),
    );
    expect(await repo.porPalpar(lecheriaId, hoy: hoy), hasLength(1));

    await evento(
      animalId: 'a1',
      tipo: TipoEventoAnimal.palpacion,
      fecha: DateTime(2026, 8, 20),
    );

    expect(await repo.porPalpar(lecheriaId, hoy: hoy), isEmpty);
  });

  test('deja afuera machos, dados de baja y otras lecherías', () async {
    await seedAnimal(
      db,
      lecheriaId: lecheriaId,
      id: 'macho',
      identificador: 'M-1',
      sexo: Sexo.macho,
      fechaUltimoParto: DateTime(2026, 3, 1),
    );
    await seedAnimal(
      db,
      lecheriaId: lecheriaId,
      id: 'vendida',
      identificador: '1003',
      fechaUltimoParto: DateTime(2026, 3, 1),
    );
    await (db.update(db.animales)..where((t) => t.id.equals('vendida'))).write(
      const AnimalesCompanion(estado: Value(EstadoAnimal.vendido)),
    );
    await seedLecheria(
      db,
      usuarioId: 'user-1',
      lecheriaId: 'otra-lecheria',
      nombre: 'Otra',
    );
    await seedAnimal(
      db,
      lecheriaId: 'otra-lecheria',
      id: 'ajena',
      identificador: '9001',
      fechaUltimoParto: DateTime(2026, 3, 1),
    );

    expect(await repo.porPalpar(lecheriaId, hoy: hoy), isEmpty);
  });

  test('una novilla servida entra aunque nunca haya parido', () async {
    await seedAnimal(
      db,
      lecheriaId: lecheriaId,
      id: 'n1',
      identificador: 'N-1',
      grupo: GrupoAnimal.novillas,
    );
    await evento(
      animalId: 'n1',
      tipo: TipoEventoAnimal.inseminacion,
      fecha: DateTime(2026, 7, 1),
    );

    final lista = await repo.porPalpar(lecheriaId, hoy: hoy);
    expect(lista.single.identificador, 'N-1');
    expect(lista.single.grupo, GrupoAnimal.novillas);
  });

  test('el celo no mete a la vaca en la lista', () async {
    // El celo dice que la vaca está en calor, no que se sirvió. Antes contaba
    // como servicio y metía a palpar vacas a las que nadie les había echado
    // toro ni pajilla: no hay preñez que confirmar donde no hubo servicio.
    await seedAnimal(
      db,
      lecheriaId: lecheriaId,
      id: 'n1',
      identificador: 'N-1',
      grupo: GrupoAnimal.novillas,
    );
    await evento(
      animalId: 'n1',
      tipo: TipoEventoAnimal.celo,
      fecha: DateTime(2026, 8, 1),
    );

    expect(await repo.porPalpar(lecheriaId, hoy: hoy), isEmpty);
  });

  test('el celo tampoco desplaza al servicio de verdad', () async {
    // Se sirvió en julio y entró en calor otra vez en agosto —señal de que no
    // agarró—. La fecha que importa sigue siendo la del servicio.
    await seedAnimal(
      db,
      lecheriaId: lecheriaId,
      id: 'a1',
      identificador: '1001',
      fechaUltimoParto: DateTime(2026, 3, 1),
    );
    await evento(
      animalId: 'a1',
      tipo: TipoEventoAnimal.monta,
      fecha: DateTime(2026, 7, 1),
    );
    await evento(
      animalId: 'a1',
      tipo: TipoEventoAnimal.celo,
      fecha: DateTime(2026, 8, 5),
    );

    final lista = await repo.porPalpar(lecheriaId, hoy: hoy);
    expect(lista.single.motivo, MotivoPalpacion.servidaSinConfirmar);
    expect(lista.single.fecha, DateTime(2026, 7, 1));
  });

  group('vacas por servir', () {
    test('entra la que lleva 50 días o más y no está preñada', () async {
      await seedAnimal(
        db,
        lecheriaId: lecheriaId,
        id: 'a1',
        identificador: '1001',
        fechaUltimoParto: DateTime(2026, 7, 7), // 50 días justos
      );
      await seedAnimal(
        db,
        lecheriaId: lecheriaId,
        id: 'a2',
        identificador: '1002',
        fechaUltimoParto: DateTime(2026, 7, 8), // 49: todavía no
      );

      final lista = await repo.porServir(lecheriaId, hoy: hoy);
      expect(lista.single.identificador, '1001');
      expect(lista.single.diasLactancia, 50);
    });

    test('la preñada confirmada no entra', () async {
      await seedAnimal(
        db,
        lecheriaId: lecheriaId,
        id: 'a1',
        identificador: '1001',
        fechaUltimoParto: DateTime(2026, 3, 1),
        estadoReproductivo: EstadoReproductivo.preniada,
      );

      expect(await repo.porServir(lecheriaId, hoy: hoy), isEmpty);
    });

    test(
      'la que nunca ha parido y no tiene fecha de nacimiento no entra',
      () async {
        // Sin la fecha no hay forma de saber si ya tiene edad, y meterla a
        // ciegas sería mandar a servir a una ternera.
        await seedAnimal(
          db,
          lecheriaId: lecheriaId,
          id: 'n1',
          identificador: 'N-1',
          grupo: GrupoAnimal.novillas,
        );

        expect(await repo.porServir(lecheriaId, hoy: hoy), isEmpty);
      },
    );

    test('la novilla entra al cumplir los 15 meses', () async {
      // hoy = 26/8/2026. Cumple los 15 meses justo hoy.
      await seedAnimal(
        db,
        lecheriaId: lecheriaId,
        id: 'n1',
        identificador: 'N-1',
        grupo: GrupoAnimal.novillas,
        fechaNacimiento: DateTime(2025, 5, 26),
      );
      // A esta le falta un día.
      await seedAnimal(
        db,
        lecheriaId: lecheriaId,
        id: 'n2',
        identificador: 'N-2',
        grupo: GrupoAnimal.novillas,
        fechaNacimiento: DateTime(2025, 5, 27),
      );

      final lista = await repo.porServir(lecheriaId, hoy: hoy);
      expect(lista.single.identificador, 'N-1');
      expect(lista.single.motivo, MotivoServir.novillaPrimeriza);
      expect(lista.single.mesesEdad, 15);
      expect(lista.single.resumen, '15 meses de edad · sin servicios');
    });

    test('la novilla preñada no entra', () async {
      await seedAnimal(
        db,
        lecheriaId: lecheriaId,
        id: 'n1',
        identificador: 'N-1',
        grupo: GrupoAnimal.novillas,
        fechaNacimiento: DateTime(2024, 1, 1),
        estadoReproductivo: EstadoReproductivo.preniada,
      );

      expect(await repo.porServir(lecheriaId, hoy: hoy), isEmpty);
    });

    test('a la novilla se le cuentan todos sus servicios', () async {
      // Nunca ha parido, así que no hay parto contra el cual medir: los
      // intentos que lleva son todos los que se le hicieron.
      await seedAnimal(
        db,
        lecheriaId: lecheriaId,
        id: 'n1',
        identificador: 'N-1',
        grupo: GrupoAnimal.novillas,
        fechaNacimiento: DateTime(2024, 6, 1),
      );
      await evento(
        animalId: 'n1',
        tipo: TipoEventoAnimal.monta,
        fecha: DateTime(2026, 3, 1),
      );
      await evento(
        animalId: 'n1',
        tipo: TipoEventoAnimal.inseminacion,
        fecha: DateTime(2026, 6, 1),
      );

      final lista = await repo.porServir(lecheriaId, hoy: hoy);
      expect(lista.single.servicios, 2);
    });

    test('novillas y vacas se ordenan juntas por atraso', () async {
      // La vaca lleva 60 días de lactancia: 10 de atraso.
      await seedAnimal(
        db,
        lecheriaId: lecheriaId,
        id: 'v1',
        identificador: 'V-1',
        fechaUltimoParto: DateTime(2026, 6, 27),
      );
      // La novilla cumplió los 15 meses hace 100 días.
      await seedAnimal(
        db,
        lecheriaId: lecheriaId,
        id: 'n1',
        identificador: 'N-1',
        grupo: GrupoAnimal.novillas,
        fechaNacimiento: DateTime(2025, 2, 18),
      );

      final lista = await repo.porServir(lecheriaId, hoy: hoy);
      expect(lista.map((v) => v.identificador), ['N-1', 'V-1']);
      expect(lista.first.diasDeAtraso, greaterThan(lista.last.diasDeAtraso));
    });

    test('cuenta los servicios posteriores al parto, sin el celo', () async {
      await seedAnimal(
        db,
        lecheriaId: lecheriaId,
        id: 'a1',
        identificador: '1001',
        fechaUltimoParto: DateTime(2026, 3, 1),
      );
      // Antes del parto: no cuenta, ese fue el que la preñó.
      await evento(
        animalId: 'a1',
        tipo: TipoEventoAnimal.monta,
        fecha: DateTime(2025, 6, 1),
      );
      await evento(
        animalId: 'a1',
        tipo: TipoEventoAnimal.monta,
        fecha: DateTime(2026, 5, 1),
      );
      await evento(
        animalId: 'a1',
        tipo: TipoEventoAnimal.inseminacion,
        fecha: DateTime(2026, 6, 10),
      );
      await evento(
        animalId: 'a1',
        tipo: TipoEventoAnimal.celo,
        fecha: DateTime(2026, 7, 1),
      );

      final lista = await repo.porServir(lecheriaId, hoy: hoy);
      expect(lista.single.servicios, 2);
      expect(lista.single.resumen, '178 días de lactancia · 2 servicios');
    });

    test('la más atrasada va de primera', () async {
      for (final (id, identificador, parto) in [
        ('a1', '1001', DateTime(2026, 6, 1)),
        ('a2', '1002', DateTime(2026, 1, 15)),
        ('a3', '1003', DateTime(2026, 4, 1)),
      ]) {
        await seedAnimal(
          db,
          lecheriaId: lecheriaId,
          id: id,
          identificador: identificador,
          fechaUltimoParto: parto,
        );
      }

      final lista = await repo.porServir(lecheriaId, hoy: hoy);
      expect(lista.map((v) => v.identificador), ['1002', '1003', '1001']);
    });
  });

  test('las más atrasadas van arriba dentro de cada motivo', () async {
    for (final (id, identificador, servicio) in [
      ('a1', '1001', DateTime(2026, 7, 20)),
      ('a2', '1002', DateTime(2026, 6, 1)),
      ('a3', '1003', DateTime(2026, 8, 1)),
    ]) {
      await seedAnimal(
        db,
        lecheriaId: lecheriaId,
        id: id,
        identificador: identificador,
        fechaUltimoParto: DateTime(2026, 3, 1),
      );
      await evento(animalId: id, tipo: TipoEventoAnimal.monta, fecha: servicio);
    }

    final lista = await repo.porPalpar(lecheriaId, hoy: hoy);
    expect(lista.map((v) => v.identificador), ['1002', '1001', '1003']);
  });
}
