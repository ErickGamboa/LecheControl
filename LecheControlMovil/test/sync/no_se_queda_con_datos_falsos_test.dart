// Tres formas distintas en que el teléfono se quedaba con un dato falso que
// el servidor ya había corregido, y que solo se curaban desinstalando la app.
// Estos tests fijan que ninguna vuelva.

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leche_control/data/local/database.dart';
import 'package:leche_control/data/sync/sync_service.dart';

import '../support/fake_sync_remote_gateway.dart';
import '../support/local_db_seed.dart';

void main() {
  late AppDatabase db;
  late FakeSyncRemoteGateway remoto;
  late SyncService sync;
  const lecheriaId = 'lecheria-1';
  final ts = DateTime(2026, 9, 14, 12, 3);

  setUp(() async {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    remoto = FakeSyncRemoteGateway();
    sync = SyncService(db, remote: remoto, esperasReintento: const []);
    await seedCuentaLocal(db, usuarioId: 'user-1');
    await seedLecheria(db, usuarioId: 'user-1', lecheriaId: lecheriaId);
  });

  tearDown(() async => db.close());

  Future<void> animalPendiente(String id, {required String arete}) async {
    await db
        .into(db.animales)
        .insert(
          AnimalesCompanion.insert(
            id: id,
            lecheriaId: lecheriaId,
            identificador: arete,
            sexo: 'hembra',
            grupo: 'en_ordeno',
            origen: 'nacido',
            createdAt: ts,
            updatedAt: ts,
            pendiente: const Value(true),
          ),
        );
  }

  Map<String, dynamic> animalRemoto(
    String id, {
    required String arete,
    String grupo = 'secas',
  }) => {
    'id': id,
    'lecheria_id': lecheriaId,
    'identificador': arete,
    'sexo': 'hembra',
    'grupo': grupo,
    'estado': 'activo',
    'estado_reproductivo': 'vacia',
    'origen': 'nacido',
    'created_at': ts.toUtc().toIso8601String(),
    'updated_at': DateTime(2026, 9, 15).toUtc().toIso8601String(),
  };

  group('las fechas suben en UTC', () {
    test('una fecha local no viaja como si fuera UTC', () async {
      // El error costaba 6 horas en Costa Rica: Drift devuelve la fecha en
      // hora local y `toIso8601String()` sobre una fecha local no lleva la
      // `Z`, así que Postgres la leía como UTC.
      await animalPendiente('animal-1', arete: '542117');

      await sync.sincronizar();

      final subida = remoto.subidas.firstWhere((s) => s.tabla == 'animales');
      final createdAt = subida.datos['created_at'] as String;
      expect(
        createdAt.endsWith('Z'),
        isTrue,
        reason: 'debe viajar marcada como UTC, no como hora de pared',
      );
      expect(DateTime.parse(createdAt).isAtSameMomentAs(ts), isTrue);
    });
  });

  group('una fila que no se puede aplicar no mata la tabla', () {
    test('las demás filas siguen bajando y se anota el fallo', () async {
      // El servidor manda una vaca con otro `id` pero el mismo arete que una
      // que ya existe local: choca con el índice único local. Antes esa
      // excepción cortaba la bajada de `animales` entera y, como el cursor no
      // avanzaba, volvía a chocar en cada sincronización. Para siempre.
      await seedAnimal(
        db,
        lecheriaId: lecheriaId,
        id: 'animal-viejo',
        identificador: 'repetida',
      );
      remoto.descargas['animales'] = [
        animalRemoto('animal-choca', arete: 'repetida'),
        animalRemoto('animal-sana', arete: 'sin-choque'),
      ];

      await sync.sincronizar();

      final bajadas = await db.select(db.animales).get();
      expect(
        bajadas.where((a) => a.id == 'animal-sana'),
        hasLength(1),
        reason: 'la fila siguiente a la que falló igual tiene que entrar',
      );
      final fallos = await sync.fallos();
      expect(fallos.map((f) => f.filaId), contains('animal-choca'));
    });
  });

  group('el candado del dato congelado se suelta', () {
    test('tras muchos intentos fallidos gana el servidor', () async {
      // Fila local pendiente cuya subida falla siempre. El guard de la bajada
      // la protege por estar pendiente, y el flag solo lo limpia una subida
      // exitosa: sin límite, el dato falso se quedaba para siempre.
      await animalPendiente('animal-1', arete: 'vieja');
      remoto.fallarSubidas.add('animales:animal-1');
      remoto.descargas['animales'] = [
        animalRemoto('animal-1', arete: 'corregida', grupo: 'novillas'),
      ];

      for (var i = 0; i < kIntentosAntesDeCederAlServidor; i++) {
        await sync.sincronizar();
      }

      final fila = await (db.select(
        db.animales,
      )..where((t) => t.id.equals('animal-1'))).getSingle();
      expect(
        fila.identificador,
        'corregida',
        reason: 'pasado el límite el servidor tiene que poder entrar',
      );
    });

    test('un fallo pasajero sí queda protegido', () async {
      await animalPendiente('animal-1', arete: 'local-sin-subir');
      remoto.fallarSubidas.add('animales:animal-1');
      remoto.descargas['animales'] = [
        animalRemoto('animal-1', arete: 'del-servidor'),
      ];

      await sync.sincronizar();

      final fila = await (db.select(
        db.animales,
      )..where((t) => t.id.equals('animal-1'))).getSingle();
      expect(
        fila.identificador,
        'local-sin-subir',
        reason: 'un cambio local recién hecho no se pisa',
      );
    });
  });

  group('volver a bajar todo', () {
    test('olvidar los cursores hace que baje de nuevo', () async {
      remoto.descargas['animales'] = [
        animalRemoto('animal-1', arete: 'una'),
      ];
      await sync.sincronizar();
      await db.delete(db.animales).go(); // como si el dato se hubiera perdido

      await sync.sincronizar();
      expect(
        await db.select(db.animales).get(),
        isEmpty,
        reason: 'con el cursor puesto ya no la vuelve a pedir',
      );

      await sync.olvidarCursores();
      await sync.sincronizar();

      expect(await db.select(db.animales).get(), hasLength(1));
    });
  });
}
