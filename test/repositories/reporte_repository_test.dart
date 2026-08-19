import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leche_control/data/domain/curva_lactancia.dart';
import 'package:leche_control/data/domain/grupos.dart';
import 'package:leche_control/data/local/database.dart';
import 'package:leche_control/data/repositories/curva_repository.dart';
import 'package:leche_control/data/repositories/pesas_repository.dart';
import 'package:leche_control/data/repositories/reporte_repository.dart';

import '../support/local_db_seed.dart';

void main() {
  late AppDatabase db;
  late CurvaRepository curvaRepo;
  late PesasRepository pesasRepo;
  late ReporteRepository repo;
  const lecheriaId = 'lecheria-1';
  final hoy = DateTime(2026, 7, 24);

  setUp(() async {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    curvaRepo = CurvaRepository(db);
    pesasRepo = PesasRepository(db);
    repo = ReporteRepository(db, curva: curvaRepo);
    await seedCuentaLocal(db, usuarioId: 'user-1');
    await seedLecheria(db, usuarioId: 'user-1', lecheriaId: lecheriaId);
    await curvaRepo.sembrarSiHaceFalta(lecheriaId);
  });

  tearDown(() async {
    await db.close();
  });

  /// Crea una vaca en ordeño parida hace [dlac] días.
  Future<String> vaca(String id, {required int dlac, String? identificador}) {
    return seedAnimal(
      db,
      lecheriaId: lecheriaId,
      id: id,
      identificador: identificador ?? id,
      fechaUltimoParto: hoy.subtract(Duration(days: dlac)),
    );
  }

  Future<PesaSesionRow> sesionCon(
    Map<String, ({double manana, double tarde})> pesadas, {
    DateTime? fecha,
  }) async {
    final sesion = await pesasRepo.abrirSesion(
      lecheriaId: lecheriaId,
      fecha: fecha ?? hoy,
    );
    for (final e in pesadas.entries) {
      await pesasRepo.registrarPesa(
        sesionId: sesion.id,
        animalId: e.key,
        litrosManana: e.value.manana,
        litrosTarde: e.value.tarde,
      );
    }
    return sesion;
  }

  test('arma una fila por vaca con su DLac, desglose y total', () async {
    await vaca('542009', dlac: 244);
    final sesion = await sesionCon({'542009': (manana: 9.5, tarde: 8)});

    final reporte = await repo.generar(
      lecheriaId: lecheriaId,
      sesionId: sesion.id,
      hoy: hoy,
    );

    final fila = reporte.filas.single;
    expect(fila.identificador, '542009');
    expect(fila.diasLactancia, 244);
    expect(fila.litrosManana, 9.5);
    expect(fila.litrosTarde, 8);
    expect(fila.total, 17.5);
    expect(fila.esManual, isFalse);
    expect(fila.tieneDesglose, isTrue);
  });

  test('compara contra la curva y califica la vaca', () async {
    await vaca('v1', dlac: 244);
    final sesion = await sesionCon({'v1': (manana: 9.5, tarde: 8)});

    final reporte = await repo.generar(
      lecheriaId: lecheriaId,
      sesionId: sesion.id,
      hoy: hoy,
    );

    final fila = reporte.filas.single;
    // 244 días cae entre el centro del tramo 181-240 (día 210.5, 18 L) y el
    // del 241-305 (día 273, 14 L).
    expect(fila.esperado, closeTo(15.86, 0.01));
    expect(fila.porcentajeDelEsperado, closeTo(110.3, 0.1));
    expect(fila.evaluacion, EvaluacionVaca.excelente);
  });

  group('vacas sin comparación', () {
    test('una vaca sin parto registrado va sin DLac ni esperado', () async {
      await seedAnimal(
        db,
        lecheriaId: lecheriaId,
        id: 'v1',
        identificador: 'V1',
      );
      final sesion = await sesionCon({'v1': (manana: 8, tarde: 7)});

      final reporte = await repo.generar(
        lecheriaId: lecheriaId,
        sesionId: sesion.id,
        hoy: hoy,
      );

      final fila = reporte.filas.single;
      expect(fila.diasLactancia, isNull);
      expect(fila.esperado, isNull);
      expect(fila.evaluacion, isNull);
      expect(fila.total, 15, reason: 'la leche sí cuenta igual');
    });

    test('la vaca manual entra al total pero no a los rankings', () async {
      await vaca('v1', dlac: 100);
      final sesion = await sesionCon({'v1': (manana: 10, tarde: 10)});
      await pesasRepo.registrarPesa(
        sesionId: sesion.id,
        identificadorManual: '8890',
        litrosManana: 6.7,
        litrosTarde: 6.5,
      );

      final reporte = await repo.generar(
        lecheriaId: lecheriaId,
        sesionId: sesion.id,
        hoy: hoy,
      );

      expect(reporte.produccionTotal, closeTo(33.2, 0.001));
      expect(reporte.hato.manuales, 1);
      final manual = reporte.filas.firstWhere((f) => f.esManual);
      expect(manual.identificador, '8890');
      expect(manual.diasLactancia, isNull);
      expect(
        reporte.mejoresSegunCurva().map((f) => f.identificador),
        ['v1'],
        reason: 'sin DLac no hay con qué compararla',
      );
    });
  });

  group('promedios coherentes', () {
    // La imagen del cliente dividía 559.5 L (que incluían 2 vacas manuales)
    // entre 36 vacas (que no las incluían). Acá numerador y denominador
    // cuentan siempre a las mismas vacas.
    test('el promedio por vaca pesada usa las vacas que se pesaron', () async {
      await vaca('v1', dlac: 100);
      await vaca('v2', dlac: 100);
      final sesion = await sesionCon({
        'v1': (manana: 10, tarde: 10),
        'v2': (manana: 5, tarde: 5),
      });
      await pesasRepo.registrarPesa(
        sesionId: sesion.id,
        identificadorManual: 'M1',
        litrosManana: 15,
      );

      final reporte = await repo.generar(
        lecheriaId: lecheriaId,
        sesionId: sesion.id,
        hoy: hoy,
      );

      expect(reporte.produccionTotal, 45);
      expect(reporte.vacasPesadas, 3);
      expect(reporte.promedioPorVacaPesada, 15);
    });

    test(
      'el promedio general reparte entre todo el hato, secas incluidas',
      () async {
        await vaca('v1', dlac: 100);
        await seedAnimal(
          db,
          lecheriaId: lecheriaId,
          id: 'seca-1',
          identificador: 'S1',
          grupo: GrupoAnimal.secas,
        );
        final sesion = await sesionCon({'v1': (manana: 10, tarde: 10)});

        final reporte = await repo.generar(
          lecheriaId: lecheriaId,
          sesionId: sesion.id,
          hoy: hoy,
        );

        expect(reporte.hato.totalRegistradas, 2);
        expect(reporte.promedioGeneral, 10);
        expect(reporte.promedioPorVacaPesada, 20);
      },
    );

    test('la distribución por rango suma las vacas pesadas', () async {
      await vaca('alta', dlac: 60);
      await vaca('media', dlac: 60);
      await vaca('baja', dlac: 60);
      await vaca('muybaja', dlac: 60);
      final sesion = await sesionCon({
        'alta': (manana: 12, tarde: 12), // 24
        'media': (manana: 7, tarde: 7), // 14
        'baja': (manana: 5, tarde: 5), // 10
        'muybaja': (manana: 2, tarde: 2), // 4
      });

      final reporte = await repo.generar(
        lecheriaId: lecheriaId,
        sesionId: sesion.id,
        hoy: hoy,
      );

      final dist = reporte.distribucionPorRango;
      expect(dist[RangoProduccion.alta], 1);
      expect(dist[RangoProduccion.media], 1);
      expect(dist[RangoProduccion.baja], 1);
      expect(dist[RangoProduccion.muyBaja], 1);
      expect(
        dist.values.fold<int>(0, (a, b) => a + b),
        reporte.vacasPesadas,
        reason: 'los porcentajes tienen que sumar 100 %',
      );
    });
  });

  group('resumen del hato', () {
    test('separa en producción, secas y prontas al parto', () async {
      await vaca('ordeno', dlac: 50);
      await seedAnimal(
        db,
        lecheriaId: lecheriaId,
        id: 'seca',
        identificador: 'S',
        grupo: GrupoAnimal.secas,
      );
      await seedAnimal(
        db,
        lecheriaId: lecheriaId,
        id: 'pronta',
        identificador: 'P',
        grupo: GrupoAnimal.secas,
        fechaProbableParto: hoy.add(const Duration(days: 10)),
      );
      // Novillas y terneros no son vacas del ordeño: no cuentan.
      await seedAnimal(
        db,
        lecheriaId: lecheriaId,
        id: 'novilla',
        identificador: 'N',
        grupo: GrupoAnimal.novillas,
      );
      final sesion = await sesionCon({'ordeno': (manana: 10, tarde: 10)});

      final reporte = await repo.generar(
        lecheriaId: lecheriaId,
        sesionId: sesion.id,
        hoy: hoy,
      );

      expect(reporte.hato.enProduccion, 1);
      expect(reporte.hato.secas, 1);
      expect(reporte.hato.prontasAlParto, 1);
      expect(reporte.hato.totalRegistradas, 3);
    });
  });

  group('curva del hato', () {
    test('deja vacío el tramo donde no hay ninguna vaca', () async {
      // La imagen del cliente mostraba 7.5 L en el tramo >305, que no tenía
      // ni una vaca. Ese número no salía de sus datos.
      await vaca('v1', dlac: 50);
      final sesion = await sesionCon({'v1': (manana: 10, tarde: 10)});

      final reporte = await repo.generar(
        lecheriaId: lecheriaId,
        sesionId: sesion.id,
        hoy: hoy,
      );

      final tramoConVaca = reporte.curvaHato.firstWhere(
        (p) => p.tramo.diaDesde == 31,
      );
      final tramoVacio = reporte.curvaHato.firstWhere(
        (p) => p.tramo.diaDesde == 306,
      );
      expect(tramoConVaca.promedioHato, 20);
      expect(tramoConVaca.vacas, 1);
      expect(tramoVacio.promedioHato, isNull);
      expect(tramoVacio.vacas, 0);
    });
  });

  group('columna Anterior', () {
    test('trae el total de esa vaca en la pesa anterior', () async {
      await vaca('v1', dlac: 100);
      final anterior = await sesionCon({
        'v1': (manana: 8, tarde: 8),
      }, fecha: hoy.subtract(const Duration(days: 7)));
      await pesasRepo.cerrarSesion(anterior.id);

      final actual = await sesionCon({'v1': (manana: 10, tarde: 10)});

      final reporte = await repo.generar(
        lecheriaId: lecheriaId,
        sesionId: actual.id,
        hoy: hoy,
      );

      final fila = reporte.filas.single;
      expect(fila.anterior, 16);
      expect(fila.diferenciaAnterior, 4);
    });

    test('queda en null en la primera pesa de la vaca', () async {
      await vaca('v1', dlac: 100);
      final sesion = await sesionCon({'v1': (manana: 10, tarde: 10)});

      final reporte = await repo.generar(
        lecheriaId: lecheriaId,
        sesionId: sesion.id,
        hoy: hoy,
      );

      expect(reporte.filas.single.anterior, isNull);
    });

    // La columna Dif. del reporte pinta esta cuenta: verde con `+` si subió,
    // rojo con `-` si bajó. El signo es lo que decide el color, así que tiene
    // que salir bien en las dos direcciones.
    test('la diferencia es negativa cuando la vaca bajó', () async {
      await vaca('v1', dlac: 100);
      final anterior = await sesionCon({
        'v1': (manana: 12, tarde: 11),
      }, fecha: hoy.subtract(const Duration(days: 7)));
      await pesasRepo.cerrarSesion(anterior.id);

      final actual = await sesionCon({'v1': (manana: 9, tarde: 8)});

      final reporte = await repo.generar(
        lecheriaId: lecheriaId,
        sesionId: actual.id,
        hoy: hoy,
      );

      final fila = reporte.filas.single;
      expect(fila.anterior, 23);
      expect(fila.total, 17);
      expect(fila.diferenciaAnterior, -6);
    });

    test('la diferencia es cero cuando dio lo mismo', () async {
      await vaca('v1', dlac: 100);
      final anterior = await sesionCon({
        'v1': (manana: 10, tarde: 10),
      }, fecha: hoy.subtract(const Duration(days: 7)));
      await pesasRepo.cerrarSesion(anterior.id);

      final actual = await sesionCon({'v1': (manana: 10, tarde: 10)});

      final reporte = await repo.generar(
        lecheriaId: lecheriaId,
        sesionId: actual.id,
        hoy: hoy,
      );

      expect(reporte.filas.single.diferenciaAnterior, 0);
    });
  });

  test('avisa cuando la lechería no tiene curva cargada', () async {
    await seedLecheria(db, usuarioId: 'user-1', lecheriaId: 'sin-curva');
    await seedAnimal(
      db,
      lecheriaId: 'sin-curva',
      id: 'v1',
      identificador: 'V1',
      fechaUltimoParto: hoy.subtract(const Duration(days: 50)),
    );
    final sesion = await pesasRepo.abrirSesion(
      lecheriaId: 'sin-curva',
      fecha: hoy,
    );
    await pesasRepo.registrarPesa(
      sesionId: sesion.id,
      animalId: 'v1',
      litrosManana: 10,
    );

    final reporte = await repo.generar(
      lecheriaId: 'sin-curva',
      sesionId: sesion.id,
      hoy: hoy,
    );

    expect(reporte.curvaVacia, isTrue);
    expect(reporte.filas.single.esperado, isNull);
    expect(reporte.mejoresSegunCurva(), isEmpty);
  });
}
