// Anotar un evento con la fecha del papel, días después de que pasó.
//
// Es lo que hace «Pasar apuntes»: el peón anota en la libreta el día 1 y el
// dueño se sienta el día 5 a digitarlo. Lo que se prueba acá es que la app
// guarde las **dos** cosas y no las confunda: cuándo pasó el evento y cuándo
// se digitó.
//
// La distinción no es de purista. Si `created_at` se va con la fecha del
// papel, se pierde el único rastro de cuándo entró el dato —y con él la forma
// de saber si la finca digita al día o con dos semanas de atraso—; y un
// `updated_at` viejo es además un mal dato para el sync, que ordena por él.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leche_control/data/domain/grupos.dart';
import 'package:leche_control/data/local/database.dart';
import 'package:leche_control/data/repositories/eventos_repository.dart';
import 'package:leche_control/data/repositories/medicamentos_repository.dart';
import 'package:leche_control/data/repositories/sanidad_repository.dart';

import '../support/local_db_seed.dart';

void main() {
  late AppDatabase db;
  late EventosRepository eventos;
  late SanidadRepository sanidad;
  late MedicamentosRepository medicamentos;
  const lecheriaId = 'lecheria-1';
  const animalId = 'animal-1';

  /// Hace diez días, a medianoche: una fecha de papel cualquiera.
  final haceDiezDias = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  ).subtract(const Duration(days: 10));

  setUp(() async {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    eventos = EventosRepository(db);
    sanidad = SanidadRepository(db);
    medicamentos = MedicamentosRepository(db);
    await seedCuentaLocal(db, usuarioId: 'user-1');
    await seedLecheria(db, usuarioId: 'user-1', lecheriaId: lecheriaId);
    await seedAnimal(
      db,
      id: animalId,
      lecheriaId: lecheriaId,
      identificador: '4101',
      grupo: GrupoAnimal.enOrdeno,
    );
  });

  tearDown(() async => db.close());

  Future<EventoAnimalRow> unico() => db.select(db.eventosAnimal).getSingle();

  /// Que la marca de digitado sea de ahora y no del papel. Se da un minuto de
  /// margen para no atarse al reloj.
  void seDigitoAhora(DateTime marca) {
    expect(
      DateTime.now().difference(marca).inMinutes.abs(),
      lessThanOrEqualTo(1),
      reason: 'la marca de digitado tiene que ser de ahora, no del papel',
    );
  }

  group('un servicio de hace diez días', () {
    test('queda con la fecha del papel', () async {
      await eventos.registrarServicio(
        animalId: animalId,
        lecheriaId: lecheriaId,
        tipo: TipoEventoAnimal.celo,
        fecha: haceDiezDias,
      );
      expect((await unico()).fecha, haceDiezDias);
    });

    test('pero se anota como digitado hoy', () async {
      await eventos.registrarServicio(
        animalId: animalId,
        lecheriaId: lecheriaId,
        tipo: TipoEventoAnimal.celo,
        fecha: haceDiezDias,
      );
      final e = await unico();
      seDigitoAhora(e.createdAt);
      seDigitoAhora(e.updatedAt);
    });
  });

  test('sin fecha, el evento es de hoy y punto', () async {
    // El registro en campo no manda fecha: lo que se anota acaba de pasar.
    await eventos.registrarServicio(
      animalId: animalId,
      lecheriaId: lecheriaId,
      tipo: TipoEventoAnimal.celo,
    );
    final e = await unico();
    seDigitoAhora(e.fecha);
    seDigitoAhora(e.createdAt);
  });

  test('dos eventos del mismo animal pueden ser de días distintos', () async {
    // El caso que mandó a hacer todo esto: la hoja del peón viene ordenada por
    // animal, no por día. «4101: celo el 12, observación el 20».
    await eventos.registrarServicio(
      animalId: animalId,
      lecheriaId: lecheriaId,
      tipo: TipoEventoAnimal.celo,
      fecha: haceDiezDias,
    );
    await eventos.registrarObservacion(
      animalId: animalId,
      lecheriaId: lecheriaId,
      texto: 'Cojea de la pata izquierda.',
      fecha: haceDiezDias.add(const Duration(days: 5)),
    );

    final todos = await db.select(db.eventosAnimal).get();
    final celo = todos.firstWhere((e) => e.tipo == TipoEventoAnimal.celo);
    final obs = todos.firstWhere((e) => e.tipo == TipoEventoAnimal.observacion);
    expect(celo.fecha, haceDiezDias);
    expect(obs.fecha, haceDiezDias.add(const Duration(days: 5)));
  });

  test('el parto viejo mueve el último parto de la vaca a ese día', () async {
    await eventos.registrarParto(
      animalId: animalId,
      lecheriaId: lecheriaId,
      sexoCria: Sexo.hembra,
      fecha: haceDiezDias,
    );
    final vaca = await (db.select(
      db.animales,
    )..where((t) => t.id.equals(animalId))).getSingle();
    expect(
      vaca.fechaUltimoParto,
      haceDiezDias,
      reason: 'los días de lactancia se cuentan desde que parió de verdad',
    );
    seDigitoAhora(vaca.updatedAt);
  });

  test('el medicamento queda con el día en que se aplicó', () async {
    // La sanidad es la que más se pasa del papel: el peón trata en el corral y
    // anota. Que el evento quede en su día es lo que deja saber después cuánto
    // hace que se trató a esa vaca.
    final medicamentoId = await medicamentos.crearMedicamento(
      lecheriaId: lecheriaId,
      nombre: 'Oxitetraciclina LA',
      dosisAplicacion: '20 ml',
    );

    await sanidad.aplicarMedicamentos(
      animalId: animalId,
      lecheriaId: lecheriaId,
      medicamentoIds: [medicamentoId],
      fecha: haceDiezDias,
    );

    final e = await unico();
    expect(e.fecha, haceDiezDias);
    expect(e.detalle, 'Oxitetraciclina LA');
    seDigitoAhora(e.createdAt);
  });
}
