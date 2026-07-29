import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leche_control/data/domain/grupos.dart';
import 'package:leche_control/data/local/database.dart';
import 'package:leche_control/data/repositories/gastos_repository.dart';
import 'package:leche_control/data/repositories/pesas_repository.dart';
import 'package:leche_control/data/repositories/rentabilidad_repository.dart';

import '../support/local_db_seed.dart';

void main() {
  late AppDatabase db;
  late GastosRepository gastosRepo;
  late PesasRepository pesasRepo;
  late RentabilidadRepository repo;
  const lecheriaId = 'lecheria-1';
  final hoy = DateTime(2026, 3, 15);

  setUp(() async {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    gastosRepo = GastosRepository(db);
    pesasRepo = PesasRepository(db);
    repo = RentabilidadRepository(db, gastos: gastosRepo, pesas: pesasRepo);
    await seedCuentaLocal(db, usuarioId: 'user-1');
    await seedLecheria(db, usuarioId: 'user-1', lecheriaId: lecheriaId);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> registrarUltimaProduccion(String animalId, double litros) async {
    final sesion = await pesasRepo.abrirSesion(
      lecheriaId: lecheriaId,
      fecha: hoy,
    );
    await pesasRepo.registrarPesa(
      sesionId: sesion.id,
      animalId: animalId,
      litros: litros,
    );
  }

  test(
    'devuelve lista vacía si el período no tiene parámetros cargados',
    () async {
      await seedAnimal(db, lecheriaId: lecheriaId, id: 'animal-1');

      final filas = await repo.calcularTabla(lecheriaId, hoy: hoy);

      expect(filas, isEmpty);
    },
  );

  test('devuelve lista vacía si no hay vacas en ordeño', () async {
    await gastosRepo.upsertParametrosPeriodo(
      lecheriaId: lecheriaId,
      anio: hoy.year,
      mes: hoy.month,
      precioLitro: 10,
      precioConcentradoKg: 5,
    );
    await seedAnimal(db, lecheriaId: lecheriaId, grupo: GrupoAnimal.secas);

    final filas = await repo.calcularTabla(lecheriaId, hoy: hoy);

    expect(filas, isEmpty);
  });

  test(
    'calcula ingreso, costo y utilidad diaria: ingreso = litros * precio, '
    'costo = concentrado + costo fijo repartido, utilidad = ingreso - costo',
    () async {
      await gastosRepo.upsertParametrosPeriodo(
        lecheriaId: lecheriaId,
        anio: hoy.year,
        mes: hoy.month,
        precioLitro: 10,
        precioConcentradoKg: 4,
      );
      final periodo = await gastosRepo.obtenerPeriodo(
        lecheriaId,
        hoy.year,
        hoy.month,
      );
      // 30 días en marzo de 2026: costo fijo diario total = 300/31... marzo
      // tiene 31 días, así que usamos un monto que dé un resultado exacto.
      await gastosRepo.addCostoFijo(
        lecheriaId: lecheriaId,
        periodoId: periodo!.id,
        categoria: 'Luz',
        monto: 310, // 310 / 31 días = 10/día
      );
      await seedAnimal(
        db,
        lecheriaId: lecheriaId,
        id: 'animal-1',
        concentradoKgDia: 2, // 2 * 4 = 8/día de concentrado
      );
      await registrarUltimaProduccion('animal-1', 15); // 15 * 10 = 150

      final filas = await repo.calcularTabla(lecheriaId, hoy: hoy);

      expect(filas, hasLength(1));
      final fila = filas.single;
      expect(fila.litrosDia, 15);
      expect(fila.ingresoDia, 150);
      expect(fila.costoConcentradoDia, 8);
      expect(fila.costoFijoVaca, 10);
      expect(fila.costoTotalDia, 18);
      expect(fila.utilidadDia, 132); // 150 - 18
      expect(fila.enRetiro, isFalse);
    },
  );

  test('ingreso es 0 cuando el animal está en retiro de leche, aunque haya '
      'producción registrada; el costo sigue aplicando', () async {
    await gastosRepo.upsertParametrosPeriodo(
      lecheriaId: lecheriaId,
      anio: hoy.year,
      mes: hoy.month,
      precioLitro: 10,
      precioConcentradoKg: 4,
    );
    await seedAnimal(
      db,
      lecheriaId: lecheriaId,
      id: 'animal-1',
      concentradoKgDia: 2,
      retiroLecheHasta: hoy.add(const Duration(days: 2)),
    );
    await registrarUltimaProduccion('animal-1', 15);

    final filas = await repo.calcularTabla(lecheriaId, hoy: hoy);

    final fila = filas.single;
    expect(fila.enRetiro, isTrue);
    expect(fila.ingresoDia, 0);
    expect(fila.costoConcentradoDia, 8);
    expect(fila.utilidadDia, -8); // 0 - 8
  });

  test(
    'reparte el costo fijo del período entre todas las vacas en ordeño',
    () async {
      await gastosRepo.upsertParametrosPeriodo(
        lecheriaId: lecheriaId,
        anio: hoy.year,
        mes: hoy.month,
        precioLitro: 10,
        precioConcentradoKg: 0,
      );
      final periodo = await gastosRepo.obtenerPeriodo(
        lecheriaId,
        hoy.year,
        hoy.month,
      );
      await gastosRepo.addCostoFijo(
        lecheriaId: lecheriaId,
        periodoId: periodo!.id,
        categoria: 'Luz',
        monto: 620, // 620 / 31 días = 20/día repartidos entre 2 vacas = 10 c/u
      );
      await seedAnimal(db, lecheriaId: lecheriaId, id: 'animal-1');
      await seedAnimal(
        db,
        lecheriaId: lecheriaId,
        id: 'animal-2',
        identificador: 'A-2',
      );
      await registrarUltimaProduccion('animal-1', 10);
      await registrarUltimaProduccion('animal-2', 5);

      final filas = await repo.calcularTabla(lecheriaId, hoy: hoy);

      expect(filas, hasLength(2));
      for (final fila in filas) {
        expect(fila.costoFijoVaca, 10);
      }
    },
  );

  test('utilidadTotalPeriodo suma la utilidad de todas las filas', () async {
    await gastosRepo.upsertParametrosPeriodo(
      lecheriaId: lecheriaId,
      anio: hoy.year,
      mes: hoy.month,
      precioLitro: 10,
      precioConcentradoKg: 0,
    );
    await seedAnimal(db, lecheriaId: lecheriaId, id: 'animal-1');
    await seedAnimal(
      db,
      lecheriaId: lecheriaId,
      id: 'animal-2',
      identificador: 'A-2',
    );
    await registrarUltimaProduccion('animal-1', 10); // 100
    await registrarUltimaProduccion('animal-2', 5); // 50

    final filas = await repo.calcularTabla(lecheriaId, hoy: hoy);

    expect(repo.utilidadTotalPeriodo(filas), 150);
  });

  test(
    'candidatasASecar incluye vacas bajo el umbral o con utilidad negativa',
    () async {
      await gastosRepo.upsertParametrosPeriodo(
        lecheriaId: lecheriaId,
        anio: hoy.year,
        mes: hoy.month,
        precioLitro: 10,
        precioConcentradoKg: 0,
      );
      await seedAnimal(
        db,
        lecheriaId: lecheriaId,
        id: 'animal-baja',
        identificador: 'BAJA',
      );
      await seedAnimal(
        db,
        lecheriaId: lecheriaId,
        id: 'animal-alta',
        identificador: 'ALTA',
      );
      await registrarUltimaProduccion('animal-baja', 3);
      await registrarUltimaProduccion('animal-alta', 20);

      final filas = await repo.calcularTabla(lecheriaId, hoy: hoy);
      final candidatas = repo.candidatasASecar(filas, 8);

      expect(candidatas.map((f) => f.animal.id), ['animal-baja']);
    },
  );
}
