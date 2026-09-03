// La regla de quién se palpa ya se prueba sola en test/domain. Acá se prueba
// lo que el repositorio agrega: que arme bien la lista desde la base —el
// último servicio de cada vaca, la última palpación— y que no meta animales
// que no van.

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leche_control/data/domain/grupos.dart';
import 'package:leche_control/data/domain/palpacion.dart';
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

  test('junta las recién paridas con las servidas sin confirmar', () async {
    await seedAnimal(
      db,
      lecheriaId: lecheriaId,
      id: 'a1',
      identificador: '1001',
      fechaUltimoParto: DateTime(2026, 8, 22),
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

    expect(lista.map((v) => v.identificador), ['1001', '1002']);
    expect(lista.first.motivo, MotivoPalpacion.posparto);
    expect(lista.first.dias, 4);
    expect(lista.last.motivo, MotivoPalpacion.servidaSinConfirmar);
    expect(lista.last.detalleServicio, 'Inseminación · Pajilla 44');
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
      fechaUltimoParto: DateTime(2026, 8, 22),
    );
    await seedAnimal(
      db,
      lecheriaId: lecheriaId,
      id: 'vendida',
      identificador: '1003',
      fechaUltimoParto: DateTime(2026, 8, 22),
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
      fechaUltimoParto: DateTime(2026, 8, 22),
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
