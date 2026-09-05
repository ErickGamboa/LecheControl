// El reparto en meses ya se prueba solo en test/domain. Acá se prueba lo que
// el repositorio agrega: de dónde saca la fecha de cada vaca —la que anotó la
// palpación o la cuenta desde el servicio— y a quién deja por fuera.

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leche_control/data/domain/grupos.dart';
import 'package:leche_control/data/domain/partos_proyectados.dart';
import 'package:leche_control/data/local/database.dart';
import 'package:leche_control/data/repositories/partos_repository.dart';

import '../support/local_db_seed.dart';

void main() {
  late AppDatabase db;
  late PartosRepository repo;
  const lecheriaId = 'lecheria-1';
  final hoy = DateTime(2026, 9, 5);
  var contador = 0;

  Future<void> servicio({
    required String animalId,
    required DateTime fecha,
    String tipo = TipoEventoAnimal.inseminacion,
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
    repo = PartosRepository(db);
    await seedCuentaLocal(db, usuarioId: 'user-1');
    await seedLecheria(db, usuarioId: 'user-1', lecheriaId: lecheriaId);
  });

  tearDown(() async {
    await db.close();
  });

  /// Todas las vacas del calendario, sin importar en qué mes cayeron.
  List<VacaPorParir> enCalendario(ProyeccionPartos p) =>
      [for (final m in p.meses) ...m.vacas];

  test('la fecha anotada por la palpación manda', () async {
    await seedAnimal(
      db,
      lecheriaId: lecheriaId,
      id: 'a1',
      identificador: '1001',
      grupo: GrupoAnimal.secas,
      estadoReproductivo: EstadoReproductivo.preniada,
      fechaProbableParto: DateTime(2026, 12, 10),
    );
    // Un servicio que daría otra fecha: la del veterinario le gana.
    await servicio(animalId: 'a1', fecha: DateTime(2026, 4, 1));

    final p = await repo.proyeccion(lecheriaId, hoy: hoy);
    final vaca = enCalendario(p).single;

    expect(vaca.identificador, '1001');
    expect(vaca.fechaProbable, DateTime(2026, 12, 10));
    expect(vaca.origen, OrigenFechaParto.confirmada);
    expect(p.meses[3].etiqueta, 'Diciembre 2026');
    expect(p.meses[3].cantidad, 1);
  });

  test('sin fecha anotada, la saca del último servicio', () async {
    await seedAnimal(
      db,
      lecheriaId: lecheriaId,
      id: 'a1',
      identificador: '1001',
      estadoReproductivo: EstadoReproductivo.preniada,
    );
    await servicio(animalId: 'a1', fecha: DateTime(2026, 2, 1));
    await servicio(
      animalId: 'a1',
      fecha: DateTime(2026, 3, 10),
      toroPajilla: 'Pajilla 44',
    );

    final p = await repo.proyeccion(lecheriaId, hoy: hoy);
    final vaca = enCalendario(p).single;

    // El último servicio, no el primero: 10 de marzo + 283 días.
    expect(vaca.fechaProbable, partoProbableDesdeServicio(DateTime(2026, 3, 10)));
    expect(vaca.origen, OrigenFechaParto.estimada);
    expect(vaca.detalleServicio, 'Inseminación · Pajilla 44');
  });

  test('un servicio anterior al último parto no proyecta nada', () async {
    // Se sirvió, quedó preñada y parió. Que después la marcaran preñada otra
    // vez sin servicio nuevo no revive aquel servicio viejo.
    await seedAnimal(
      db,
      lecheriaId: lecheriaId,
      id: 'a1',
      identificador: '1001',
      estadoReproductivo: EstadoReproductivo.preniada,
      fechaUltimoParto: DateTime(2026, 6, 1),
    );
    await servicio(animalId: 'a1', fecha: DateTime(2025, 8, 1));

    final p = await repo.proyeccion(lecheriaId, hoy: hoy);

    expect(enCalendario(p), isEmpty);
    expect(p.sinFecha, ['1001']);
    expect(p.totalPreniadas, 1);
  });

  test('la preñada sin fecha ni servicio se aparta', () async {
    await seedAnimal(
      db,
      lecheriaId: lecheriaId,
      id: 'a1',
      identificador: '1001',
      estadoReproductivo: EstadoReproductivo.preniada,
    );

    final p = await repo.proyeccion(lecheriaId, hoy: hoy);

    expect(enCalendario(p), isEmpty);
    expect(p.sinFecha, ['1001']);
  });

  test('las vacías y las de estado desconocido no entran', () async {
    await seedAnimal(
      db,
      lecheriaId: lecheriaId,
      id: 'a1',
      identificador: '1001',
      estadoReproductivo: EstadoReproductivo.vacia,
      fechaProbableParto: DateTime(2026, 11, 1),
    );
    await seedAnimal(
      db,
      lecheriaId: lecheriaId,
      id: 'a2',
      identificador: '1002',
      estadoReproductivo: EstadoReproductivo.desconocido,
    );
    await servicio(animalId: 'a2', fecha: DateTime(2026, 3, 10));

    final p = await repo.proyeccion(lecheriaId, hoy: hoy);

    expect(p.totalPreniadas, 0);
  });

  test('el macho preñado no existe: solo entran hembras activas', () async {
    await seedAnimal(
      db,
      lecheriaId: lecheriaId,
      id: 'a1',
      identificador: '1001',
      sexo: Sexo.macho,
      estadoReproductivo: EstadoReproductivo.preniada,
      fechaProbableParto: DateTime(2026, 11, 1),
    );
    await seedAnimal(
      db,
      lecheriaId: lecheriaId,
      id: 'a2',
      identificador: '1002',
      estadoReproductivo: EstadoReproductivo.preniada,
      fechaProbableParto: DateTime(2026, 11, 5),
    );
    await (db.update(db.animales)..where((t) => t.id.equals('a2'))).write(
      const AnimalesCompanion(estado: Value(EstadoAnimal.vendido)),
    );

    final p = await repo.proyeccion(lecheriaId, hoy: hoy);

    expect(p.totalPreniadas, 0);
  });

  test('las vacas de otra lechería no se cuelan', () async {
    await seedLecheria(
      db,
      usuarioId: 'user-1',
      lecheriaId: 'lecheria-2',
      nombre: 'La otra',
    );
    await seedAnimal(
      db,
      lecheriaId: 'lecheria-2',
      id: 'a1',
      identificador: '1001',
      estadoReproductivo: EstadoReproductivo.preniada,
      fechaProbableParto: DateTime(2026, 11, 1),
    );

    final p = await repo.proyeccion(lecheriaId, hoy: hoy);

    expect(p.totalPreniadas, 0);
  });

  test('la que se pasó de fecha sale en el mes en curso', () async {
    await seedAnimal(
      db,
      lecheriaId: lecheriaId,
      id: 'a1',
      identificador: '1001',
      estadoReproductivo: EstadoReproductivo.preniada,
      fechaProbableParto: DateTime(2026, 7, 15),
    );

    final p = await repo.proyeccion(lecheriaId, hoy: hoy);

    expect(p.meses.first.etiqueta, 'Setiembre 2026');
    expect(p.meses.first.vacas.single.identificador, '1001');
    expect(p.meses.first.vacas.single.pasadaDeFecha(hoy: hoy), isTrue);
  });
}
