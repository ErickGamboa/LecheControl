import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leche_control/data/domain/grupos.dart';
import 'package:leche_control/data/local/database.dart';
import 'package:leche_control/data/repositories/medicamentos_repository.dart';
import 'package:leche_control/data/repositories/sanidad_repository.dart';

import '../support/local_db_seed.dart';

void main() {
  late AppDatabase db;
  late MedicamentosRepository medicamentos;
  late SanidadRepository repo;
  const lecheriaId = 'lecheria-1';
  late String animalId;

  setUp(() async {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    medicamentos = MedicamentosRepository(db);
    repo = SanidadRepository(db, medicamentosRepository: medicamentos);
    await seedCuentaLocal(db, usuarioId: 'user-1');
    await seedLecheria(db, usuarioId: 'user-1', lecheriaId: lecheriaId);
    animalId = await seedAnimal(db, lecheriaId: lecheriaId);
  });

  tearDown(() async {
    await db.close();
  });

  test('una aplicación puede llevar varios medicamentos', () async {
    final oxi = await medicamentos.crearMedicamento(
      lecheriaId: lecheriaId,
      nombre: 'Oxitetraciclina',
      dosisAplicacion: '10 ml cada 50 kilos',
      mlEnvase: 100,
    );
    final vitaminas = await medicamentos.crearMedicamento(
      lecheriaId: lecheriaId,
      nombre: 'Vitaminas AD3E',
    );

    await repo.aplicarMedicamentos(
      animalId: animalId,
      lecheriaId: lecheriaId,
      medicamentoIds: [oxi, vitaminas],
      registradoPor: 'user-1',
    );

    final eventos = await db.select(db.eventosAnimal).get();
    expect(eventos, hasLength(2));
    expect(eventos.every((e) => e.tipo == TipoEventoAnimal.sanidad), isTrue);
    expect(
      eventos.map((e) => e.fecha).toSet(),
      hasLength(1),
      reason: 'es una sola aplicación, con la misma fecha',
    );

    final conDosis = eventos.firstWhere((e) => e.medicamentoId == oxi);
    expect(conDosis.detalle, 'Oxitetraciclina');
    expect(conDosis.dosis, '10 ml cada 50 kilos');

    final sinDosis = eventos.firstWhere((e) => e.medicamentoId == vitaminas);
    expect(sinDosis.dosis, isNull);
  });

  test('aplicar no cambia de grupo al animal ni le cobra nada', () async {
    final id = await medicamentos.crearMedicamento(
      lecheriaId: lecheriaId,
      nombre: 'Vitaminas AD3E',
    );

    await repo.aplicarMedicamentos(
      animalId: animalId,
      lecheriaId: lecheriaId,
      medicamentoIds: [id],
    );

    final animal = await (db.select(
      db.animales,
    )..where((t) => t.id.equals(animalId))).getSingle();
    expect(animal.grupo, GrupoAnimal.enOrdeno);

    final evento = await db.select(db.eventosAnimal).getSingle();
    expect(evento.costo, isNull);
    expect(evento.diasRetiro, isNull);
    expect(evento.pendiente, isTrue);
  });

  test('sin medicamentos marcados no registra nada', () async {
    await repo.aplicarMedicamentos(
      animalId: animalId,
      lecheriaId: lecheriaId,
      medicamentoIds: const [],
    );
    expect(await db.select(db.eventosAnimal).get(), isEmpty);
  });
}
