// Lo que la palpación y el parto guardan en la ficha, probado sin pasar por
// la pantalla: manejando el emulador a ciegas es fácil que un toque caiga en
// otro campo y uno termine creyendo que el código falla —o peor, que funciona—.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leche_control/data/domain/grupos.dart';
import 'package:leche_control/data/local/database.dart';
import 'package:leche_control/data/repositories/eventos_repository.dart';

import '../support/local_db_seed.dart';

void main() {
  late AppDatabase db;
  late EventosRepository repo;
  const lecheriaId = 'lecheria-1';

  setUp(() async {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    repo = EventosRepository(db);
    await seedCuentaLocal(db, usuarioId: 'user-1');
    await seedLecheria(db, usuarioId: 'user-1', lecheriaId: lecheriaId);
  });

  tearDown(() async => db.close());

  Future<EventoAnimalRow> ultimo(String tipo) => (db.select(
    db.eventosAnimal,
  )..where((t) => t.tipo.equals(tipo))).getSingle();

  group('palpación vacía', () {
    test('guarda las observaciones y el tratamiento', () async {
      await seedAnimal(db, lecheriaId: lecheriaId, id: 'a1');

      await repo.registrarPalpacion(
        animalId: 'a1',
        lecheriaId: lecheriaId,
        resultado: ResultadoPalpacion.vacia,
        observaciones: 'quiste en ovario derecho',
        tratamiento: 'lutalyse 5 ml',
      );

      final e = await ultimo(TipoEventoAnimal.palpacion);
      expect(e.detalle, 'quiste en ovario derecho');
      expect(e.tratamiento, 'lutalyse 5 ml');
    });

    test('los dos son opcionales y en blanco no se guardan', () async {
      await seedAnimal(db, lecheriaId: lecheriaId, id: 'a1');

      await repo.registrarPalpacion(
        animalId: 'a1',
        lecheriaId: lecheriaId,
        resultado: ResultadoPalpacion.vacia,
        observaciones: '   ',
        tratamiento: '',
      );

      final e = await ultimo(TipoEventoAnimal.palpacion);
      expect(e.detalle, isNull);
      expect(e.tratamiento, isNull);
    });

    test(
      'en una preñada no se guardan: ahí lo que importa es la fecha',
      () async {
        await seedAnimal(db, lecheriaId: lecheriaId, id: 'a1');

        await repo.registrarPalpacion(
          animalId: 'a1',
          lecheriaId: lecheriaId,
          resultado: ResultadoPalpacion.preniada,
          fechaProbableParto: DateTime(2027, 6, 25),
          observaciones: 'no debería quedar',
          tratamiento: 'tampoco',
        );

        final e = await ultimo(TipoEventoAnimal.palpacion);
        expect(e.detalle, isNull);
        expect(e.tratamiento, isNull);
        final a = await (db.select(
          db.animales,
        )..where((t) => t.id.equals('a1'))).getSingle();
        expect(a.fechaProbableParto, DateTime(2027, 6, 25));
      },
    );
  });

  group('el padre de la cría', () {
    test('sale del toro de la última monta', () async {
      await seedAnimal(db, lecheriaId: lecheriaId, id: 'madre');
      await seedAnimal(
        db,
        lecheriaId: lecheriaId,
        id: 'toro',
        identificador: 'TORO-1',
        sexo: Sexo.macho,
        grupo: GrupoAnimal.toros,
      );
      await repo.registrarServicio(
        animalId: 'madre',
        lecheriaId: lecheriaId,
        tipo: TipoEventoAnimal.monta,
        toroId: 'toro',
        toroPajilla: 'TORO-1',
        fecha: DateTime(2026, 1, 10),
      );

      await repo.registrarParto(
        animalId: 'madre',
        lecheriaId: lecheriaId,
        sexoCria: Sexo.hembra,
        identificadorCria: 'CRIA-1',
        fecha: DateTime(2026, 10, 20),
      );

      final cria = await (db.select(
        db.animales,
      )..where((t) => t.identificador.equals('CRIA-1'))).getSingle();
      expect(cria.madreId, 'madre');
      expect(cria.padreId, 'toro');
      expect(cria.padrePajilla, 'TORO-1');
    });

    test('con inseminación queda la pajilla y sin toro del hato', () async {
      await seedAnimal(db, lecheriaId: lecheriaId, id: 'madre');
      await repo.registrarServicio(
        animalId: 'madre',
        lecheriaId: lecheriaId,
        tipo: TipoEventoAnimal.inseminacion,
        toroPajilla: 'Holstein 7HO14350',
        fecha: DateTime(2026, 1, 10),
      );

      await repo.registrarParto(
        animalId: 'madre',
        lecheriaId: lecheriaId,
        sexoCria: Sexo.macho,
        identificadorCria: 'CRIA-1',
        fecha: DateTime(2026, 10, 20),
      );

      final cria = await (db.select(
        db.animales,
      )..where((t) => t.identificador.equals('CRIA-1'))).getSingle();
      expect(cria.padreId, isNull);
      expect(cria.padrePajilla, 'Holstein 7HO14350');
    });

    test('el celo no es padre de nadie', () async {
      await seedAnimal(db, lecheriaId: lecheriaId, id: 'madre');
      await repo.registrarServicio(
        animalId: 'madre',
        lecheriaId: lecheriaId,
        tipo: TipoEventoAnimal.celo,
        fecha: DateTime(2026, 1, 10),
      );

      await repo.registrarParto(
        animalId: 'madre',
        lecheriaId: lecheriaId,
        sexoCria: Sexo.hembra,
        identificadorCria: 'CRIA-1',
        fecha: DateTime(2026, 10, 20),
      );

      final cria = await (db.select(
        db.animales,
      )..where((t) => t.identificador.equals('CRIA-1'))).getSingle();
      expect(cria.padreId, isNull);
      expect(cria.padrePajilla, isNull);
    });

    test('un servicio posterior al parto no cuenta como padre', () async {
      // La madre se volvió a servir después de parir: ese servicio es de la
      // preñez siguiente, no del ternero que acaba de nacer.
      await seedAnimal(db, lecheriaId: lecheriaId, id: 'madre');
      await repo.registrarServicio(
        animalId: 'madre',
        lecheriaId: lecheriaId,
        tipo: TipoEventoAnimal.inseminacion,
        toroPajilla: 'El bueno',
        fecha: DateTime(2026, 1, 10),
      );
      await repo.registrarServicio(
        animalId: 'madre',
        lecheriaId: lecheriaId,
        tipo: TipoEventoAnimal.inseminacion,
        toroPajilla: 'El de después',
        fecha: DateTime(2026, 11, 5),
      );

      await repo.registrarParto(
        animalId: 'madre',
        lecheriaId: lecheriaId,
        sexoCria: Sexo.hembra,
        identificadorCria: 'CRIA-1',
        fecha: DateTime(2026, 10, 20),
      );

      final cria = await (db.select(
        db.animales,
      )..where((t) => t.identificador.equals('CRIA-1'))).getSingle();
      expect(cria.padrePajilla, 'El bueno');
    });
  });
}
