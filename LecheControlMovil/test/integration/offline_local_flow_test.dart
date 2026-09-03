import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leche_control/data/domain/grupos.dart';
import 'package:leche_control/data/domain/semana.dart';
import 'package:leche_control/data/local/database.dart';
import 'package:leche_control/data/repositories/animales_repository.dart';
import 'package:leche_control/data/repositories/curva_repository.dart';
import 'package:leche_control/data/repositories/finanzas_repository.dart';
import 'package:leche_control/data/repositories/lecherias_repository.dart';
import 'package:leche_control/data/repositories/pesas_repository.dart';
import 'package:leche_control/data/repositories/reporte_repository.dart';

import '../support/local_db_seed.dart';

/// Ejercita el flujo completo del ganadero (alta de animal, pesa semanal con
/// su reporte, y finanzas de la semana) usando solo la base local, sin tocar
/// la red ni Supabase, tal como corre la app en modo sin conexión.
void main() {
  late AppDatabase db;
  late CurvaRepository curvaRepo;
  late LecheriasRepository lecheriasRepo;
  late AnimalesRepository animalesRepo;
  late PesasRepository pesasRepo;
  late FinanzasRepository finanzasRepo;
  late ReporteRepository reporteRepo;

  const usuarioId = 'user-offline-1';

  setUp(() async {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    curvaRepo = CurvaRepository(db);
    lecheriasRepo = LecheriasRepository(db, curva: curvaRepo);
    animalesRepo = AnimalesRepository(db);
    pesasRepo = PesasRepository(db);
    finanzasRepo = FinanzasRepository(db);
    reporteRepo = ReporteRepository(db, curva: curvaRepo);
    await seedCuentaLocal(db, usuarioId: usuarioId);
  });

  tearDown(() async {
    await db.close();
  });

  test('alta de lechería + animal + pesa + reporte + finanzas, todo offline '
      'y sin llamadas de red', () async {
    // 1) Crear la lechería (Módulo 0) como haría CuentaGate.
    await lecheriasRepo.crearLecheria(
      nombre: 'Lechería El Trébol',
      creadaPor: usuarioId,
    );
    final lecheria = await lecheriasRepo.obtenerActiva(usuarioId);
    expect(lecheria, isNotNull);
    expect(lecheria!.pendiente, isTrue);
    final lecheriaId = lecheria.id;

    // Al crearse, la lechería ya trae su curva de referencia y las
    // categorías de gasto: sirve desde la primera pesa sin configurar nada.
    expect(await curvaRepo.tramosDe(lecheriaId), hasLength(7));
    expect((await curvaRepo.curvaDe(lecheriaId)).estaVacia, isFalse);

    // 2) Dar de alta una vaca parida hace 50 días (Módulo 1).
    final hoy = DateTime.now();
    final animalId = await animalesRepo.altaAnimal(
      lecheriaId: lecheriaId,
      identificador: 'VACA-01',
      sexo: Sexo.hembra,
      grupo: GrupoAnimal.enOrdeno,
      origen: OrigenAnimal.nacido,
      fechaUltimoParto: hoy.subtract(const Duration(days: 50)),
    );
    final animal = await animalesRepo.buscarPorIdentificador(
      lecheriaId,
      'VACA-01',
    );
    expect(animal, isNotNull);
    expect(animal!.id, animalId);
    expect(animal.pendiente, isTrue);

    // 3) Pesarla: mañana, tarde y concentrado (Módulo 3).
    final sesion = await pesasRepo.abrirSesion(lecheriaId: lecheriaId);
    final resultadoPesa = await pesasRepo.registrarPesa(
      sesionId: sesion.id,
      animalId: animalId,
      litrosManana: 9,
      litrosTarde: 7.5,
      concentradoKg: 4,
    );
    expect(resultadoPesa, isNull, reason: 'null significa que se guardó');
    expect(await pesasRepo.ultimaProduccion(animalId), 16.5);

    // 4) El reporte de producción la compara contra la curva.
    final reporte = await reporteRepo.generar(
      lecheriaId: lecheriaId,
      sesionId: sesion.id,
      hoy: hoy,
    );
    final fila = reporte.filas.single;
    expect(fila.identificador, 'VACA-01');
    expect(fila.diasLactancia, 50);
    expect(fila.total, 16.5);
    expect(fila.concentradoKg, 4);
    expect(fila.esperado, isNotNull, reason: 'tiene DLac y hay curva');
    expect(fila.evaluacion, isNotNull);
    expect(reporte.produccionTotal, 16.5);
    expect(reporte.hato.enProduccion, 1);

    // 5) Anotar la plata de la semana (Módulo 4).
    final semana = await finanzasRepo.abrirSemana(lecheriaId: lecheriaId);
    expect(semana.fechaInicio, lunesDe(hoy));
    await finanzasRepo.agregarIngreso(
      lecheriaId: lecheriaId,
      semanaId: semana.id,
      tipo: TipoIngreso.leche,
      monto: 38000,
      litros: 100, // ₡380/L
    );
    await finanzasRepo.agregarGasto(
      lecheriaId: lecheriaId,
      semanaId: semana.id,
      categoria: 'Salario del peón',
      monto: 8000,
    );

    final resumen = await finanzasRepo.resumenDe(semana);
    expect(resumen.totalIngresos, 38000);
    expect(resumen.totalGastos, 8000);
    expect(resumen.utilidad, 30000);
    expect(resumen.precioRealPorLitro, 380);

    // Todo lo anterior corrió contra `NativeDatabase.memory()`: ninguna fila
    // salió de la base local y todas quedaron `pendiente` para que
    // `SyncService` las suba cuando haya conexión.
    final pendientesAnimales = await (db.select(
      db.animales,
    )..where((t) => t.pendiente.equals(true))).get();
    final pendientesPesas = await (db.select(
      db.pesasLeche,
    )..where((t) => t.pendiente.equals(true))).get();
    final pendientesIngresos = await (db.select(
      db.ingresosSemana,
    )..where((t) => t.pendiente.equals(true))).get();
    expect(pendientesAnimales, hasLength(1));
    expect(pendientesPesas, hasLength(1));
    expect(pendientesIngresos, hasLength(1));
  });
}
