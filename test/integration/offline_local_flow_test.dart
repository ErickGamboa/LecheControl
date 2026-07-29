import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leche_control/data/domain/grupos.dart';
import 'package:leche_control/data/local/database.dart';
import 'package:leche_control/data/repositories/animales_repository.dart';
import 'package:leche_control/data/repositories/gastos_repository.dart';
import 'package:leche_control/data/repositories/lecherias_repository.dart';
import 'package:leche_control/data/repositories/pesas_repository.dart';
import 'package:leche_control/data/repositories/rentabilidad_repository.dart';

import '../support/local_db_seed.dart';

/// Ejercita el flujo completo del ganadero (alta de animal, pesa,
/// parámetros de gastos y rentabilidad) usando solo la base local, sin
/// tocar la red ni Supabase, tal como corre la app en modo sin conexión.
void main() {
  late AppDatabase db;
  late LecheriasRepository lecheriasRepo;
  late AnimalesRepository animalesRepo;
  late PesasRepository pesasRepo;
  late GastosRepository gastosRepo;
  late RentabilidadRepository rentabilidadRepo;

  const usuarioId = 'user-offline-1';

  setUp(() async {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    lecheriasRepo = LecheriasRepository(db);
    animalesRepo = AnimalesRepository(db);
    pesasRepo = PesasRepository(db);
    gastosRepo = GastosRepository(db);
    rentabilidadRepo = RentabilidadRepository(
      db,
      gastos: gastosRepo,
      pesas: pesasRepo,
    );
    await seedCuentaLocal(db, usuarioId: usuarioId);
  });

  tearDown(() async {
    await db.close();
  });

  test('alta de lechería + animal + pesa + parámetros + rentabilidad, todo '
      'offline y sin llamadas de red', () async {
    // 1) Crear la lechería (Módulo 0) como haría CuentaGate.
    await lecheriasRepo.crearLecheria(
      nombre: 'Lechería El Trébol',
      creadaPor: usuarioId,
    );
    final lecheria = await lecheriasRepo.obtenerActiva(usuarioId);
    expect(lecheria, isNotNull);
    expect(lecheria!.pendiente, isTrue);
    final lecheriaId = lecheria.id;

    // 2) Dar de alta un animal nuevo (Módulo 1).
    final animalId = await animalesRepo.altaAnimal(
      lecheriaId: lecheriaId,
      identificador: 'VACA-01',
      sexo: Sexo.hembra,
      grupo: GrupoAnimal.enOrdeno,
      origen: OrigenAnimal.nacido,
    );
    final animal = await animalesRepo.buscarPorIdentificador(
      lecheriaId,
      'VACA-01',
    );
    expect(animal, isNotNull);
    expect(animal!.id, animalId);
    expect(animal.pendiente, isTrue);

    // 3) Pesar la vaca en la sesión del día (Módulo 3).
    final sesion = await pesasRepo.abrirSesion(lecheriaId: lecheriaId);
    final resultadoPesa = await pesasRepo.registrarPesa(
      sesionId: sesion.id,
      animalId: animalId,
      litros: 16.5,
    );
    expect(resultadoPesa, isNull, reason: 'null significa que se guardó');
    expect(await pesasRepo.ultimaProduccion(animalId), 16.5);

    // 4) Configurar precios del mes (Módulo 4).
    final ahora = DateTime.now();
    await gastosRepo.upsertParametrosPeriodo(
      lecheriaId: lecheriaId,
      anio: ahora.year,
      mes: ahora.month,
      precioLitro: 12,
      precioConcentradoKg: 6,
      umbralSecadoLitros: 5,
    );
    final periodo = await gastosRepo.obtenerPeriodo(
      lecheriaId,
      ahora.year,
      ahora.month,
    );
    await gastosRepo.addCostoFijo(
      lecheriaId: lecheriaId,
      periodoId: periodo!.id,
      categoria: 'Luz',
      monto: 30,
    );

    // 5) Ver la fila de rentabilidad calculada localmente (Módulo 5).
    final filas = await rentabilidadRepo.calcularTabla(lecheriaId);
    expect(filas, hasLength(1));
    final fila = filas.single;
    expect(fila.animal.id, animalId);
    expect(fila.litrosDia, 16.5);
    expect(fila.ingresoDia, closeTo(198, 0.001)); // 16.5 * 12
    expect(fila.costoConcentradoDia, 0); // sin concentrado configurado
    expect(fila.utilidadDia, greaterThan(0));

    // Todo lo anterior corrió contra `NativeDatabase.memory()`: ninguna
    // fila salió de la base local y todas quedaron `pendiente` para que
    // `SyncService` las suba cuando haya conexión.
    final pendientesAnimales = await (db.select(
      db.animales,
    )..where((t) => t.pendiente.equals(true))).get();
    final pendientesPesas = await (db.select(
      db.pesasLeche,
    )..where((t) => t.pendiente.equals(true))).get();
    expect(pendientesAnimales, hasLength(1));
    expect(pendientesPesas, hasLength(1));
  });
}
