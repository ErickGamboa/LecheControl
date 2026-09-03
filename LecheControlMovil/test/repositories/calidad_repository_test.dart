// La calidad es un registro por semana. Lo que se prueba acá es que no se
// dupliquen semanas, que corregir no cree una segunda verdad y que una
// lectura que se quedó sin ningún valor desaparezca en vez de hacer un hueco
// en los gráficos.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leche_control/data/local/database.dart';
import 'package:leche_control/data/repositories/calidad_repository.dart';
import 'package:leche_control/data/repositories/finanzas_repository.dart';

import '../support/local_db_seed.dart';

void main() {
  late AppDatabase db;
  late CalidadRepository repo;
  const lecheriaId = 'lecheria-1';
  final miercoles = DateTime(2026, 8, 12);

  setUp(() async {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    repo = CalidadRepository(db, finanzasRepository: FinanzasRepository(db));
    await seedCuentaLocal(db, usuarioId: 'user-1');
    await seedLecheria(db, usuarioId: 'user-1', lecheriaId: lecheriaId);
  });

  tearDown(() async {
    await db.close();
  });

  test('guarda los tres análisis de la semana y quedan pendientes', () async {
    final semana = await repo.abrirSemana(
      lecheriaId: lecheriaId,
      fecha: miercoles,
    );
    await repo.guardar(
      lecheriaId: lecheriaId,
      semanaId: semana.id,
      solidosTotalesPct: 12.6,
      celulasSomaticas: 210000,
      conteoBacterial: 285000,
    );

    final guardado = await repo.deSemana(semana.id);
    expect(guardado, isNotNull);
    expect(guardado!.solidosTotalesPct, 12.6);
    expect(guardado.celulasSomaticas, 210000);
    expect(guardado.conteoBacterial, 285000);
    // Offline-first: la fila nace pendiente de subir.
    expect(guardado.pendiente, isTrue);
  });

  test('se puede anotar solo un análisis y completar después', () async {
    final semana = await repo.abrirSemana(
      lecheriaId: lecheriaId,
      fecha: miercoles,
    );
    await repo.guardar(
      lecheriaId: lecheriaId,
      semanaId: semana.id,
      conteoBacterial: 400000,
    );
    await repo.guardar(
      lecheriaId: lecheriaId,
      semanaId: semana.id,
      conteoBacterial: 400000,
      celulasSomaticas: 320000,
    );

    final filas = await db.select(db.calidadLeche).get();
    expect(filas, hasLength(1), reason: 'corregir no crea otra fila');
    expect(filas.single.celulasSomaticas, 320000);
    expect(filas.single.solidosTotalesPct, isNull);
  });

  test('otro día de la misma semana sigue siendo la misma semana', () async {
    final lunes = await repo.abrirSemana(
      lecheriaId: lecheriaId,
      fecha: DateTime(2026, 8, 10),
    );
    final domingo = await repo.abrirSemana(
      lecheriaId: lecheriaId,
      fecha: DateTime(2026, 8, 16),
    );
    expect(domingo.id, lunes.id);
  });

  test('borrar los tres valores borra la lectura', () async {
    final semana = await repo.abrirSemana(
      lecheriaId: lecheriaId,
      fecha: miercoles,
    );
    await repo.guardar(
      lecheriaId: lecheriaId,
      semanaId: semana.id,
      solidosTotalesPct: 12,
    );
    await repo.guardar(lecheriaId: lecheriaId, semanaId: semana.id);

    expect(await repo.deSemana(semana.id), isNull);
    // Borrado suave: la fila sigue ahí para que el sync la baje al resto de
    // los dispositivos.
    final crudas = await db.select(db.calidadLeche).get();
    expect(crudas.single.deletedAt, isNotNull);
    expect(crudas.single.pendiente, isTrue);
  });

  test('guardar una semana vacía no crea nada', () async {
    final semana = await repo.abrirSemana(
      lecheriaId: lecheriaId,
      fecha: miercoles,
    );
    await repo.guardar(lecheriaId: lecheriaId, semanaId: semana.id);
    expect(await db.select(db.calidadLeche).get(), isEmpty);
  });

  test('el historial viene de la semana más nueva a la más vieja', () async {
    for (final (fecha, ufc) in [
      (DateTime(2026, 8, 5), 500000.0),
      (DateTime(2026, 8, 12), 300000.0),
      (DateTime(2026, 8, 19), 200000.0),
    ]) {
      final semana = await repo.abrirSemana(
        lecheriaId: lecheriaId,
        fecha: fecha,
      );
      await repo.guardar(
        lecheriaId: lecheriaId,
        semanaId: semana.id,
        conteoBacterial: ufc,
      );
    }

    final historial = await repo.historial(lecheriaId);
    expect(historial.map((h) => h.calidad.conteoBacterial), [
      200000,
      300000,
      500000,
    ]);
    expect(historial.first.semana.fechaInicio, DateTime(2026, 8, 17));
  });

  test('el historial deja afuera las lecturas borradas', () async {
    final semana = await repo.abrirSemana(
      lecheriaId: lecheriaId,
      fecha: miercoles,
    );
    await repo.guardar(
      lecheriaId: lecheriaId,
      semanaId: semana.id,
      conteoBacterial: 300000,
    );
    await repo.guardar(lecheriaId: lecheriaId, semanaId: semana.id);

    expect(await repo.historial(lecheriaId), isEmpty);
  });
}
