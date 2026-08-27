// La sincronización tiene que subir TODO de una y no parar hasta terminar.
// Antes había un límite de 20 s para toda la sincronización: con un día de
// campo cargado se cortaba a la mitad, subía un pedazo y el ganadero tenía
// que volver a apretar el botón. Estos tests fijan lo contrario.

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
  final ts = DateTime(2026, 8, 26);

  setUp(() async {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    remoto = FakeSyncRemoteGateway();
    // Sin esperas: los reintentos no tienen por qué dormir el test.
    sync = SyncService(db, remote: remoto, esperasReintento: const []);
    await seedCuentaLocal(db, usuarioId: 'user-1');
    await seedLecheria(db, usuarioId: 'user-1', lecheriaId: lecheriaId);
  });

  tearDown(() async {
    await db.close();
  });

  /// Deja [cuantas] pesas pendientes de subir, cada una en su propia sesión.
  Future<void> sembrarPendientes(int cuantas) async {
    for (var i = 0; i < cuantas; i++) {
      await db
          .into(db.pesasSesiones)
          .insert(
            PesasSesionesCompanion.insert(
              id: 'sesion-$i',
              lecheriaId: lecheriaId,
              fecha: ts,
              createdAt: ts,
              updatedAt: ts,
              pendiente: const Value(true),
            ),
          );
      await db
          .into(db.pesasLeche)
          .insert(
            PesasLecheCompanion.insert(
              id: 'pesa-$i',
              sesionId: 'sesion-$i',
              identificadorManual: Value('vaca-$i'),
              litros: 20,
              createdAt: ts,
              updatedAt: ts,
              pendiente: const Value(true),
            ),
          );
    }
  }

  Future<int> pendientesTotales() async {
    final mapa = await sync.pendientesPorTabla();
    return mapa.values.fold<int>(0, (a, b) => a + b);
  }

  test('sube todas las filas de una sola sincronización', () async {
    await sembrarPendientes(40);
    expect(await pendientesTotales(), 80);

    await sync.sincronizar();

    expect(
      await pendientesTotales(),
      0,
      reason: 'no puede quedar nada a medio subir',
    );
    // Las 40 sesiones y sus 40 pesas, todas en una sola pasada.
    expect(remoto.subidas.length, 80);
  });

  test('insiste hasta terminar cuando la red se corta a mitad', () async {
    await sembrarPendientes(5);
    // La red falla la primera vez en tres filas y anda en el reintento.
    remoto.fallarSubidasUnaVez.addAll([
      'pesas_leche:pesa-1',
      'pesas_leche:pesa-3',
      'pesas_sesiones:sesion-4',
    ]);

    await sync.sincronizar();

    expect(
      await pendientesTotales(),
      0,
      reason: 'una falla pasajera no puede dejar la fila abajo',
    );
    expect(remoto.intentosPorFila['pesas_leche:pesa-1'], 2);
  });

  test('una fila que falla siempre no arrastra a las demás', () async {
    await sembrarPendientes(4);
    remoto.fallarSubidas.add('pesas_leche:pesa-2');

    await sync.sincronizar();

    // La rebelde queda pendiente; las otras tres subieron.
    final pendientes = await (db.select(
      db.pesasLeche,
    )..where((t) => t.pendiente.equals(true))).get();
    expect(pendientes.map((p) => p.id), ['pesa-2']);
    expect(remoto.subidas.where((w) => w.tabla == 'pesas_leche').length, 3);
  });

  test('lo que se guarda durante la subida también sale', () async {
    await sembrarPendientes(2);
    var yaPedido = false;

    // A mitad de la subida entra un pedido nuevo, como cuando el ganadero
    // guarda otra pesa mientras la app está subiendo. Antes ese pedido se
    // descartaba con un `return` seco y el cambio esperaba el próximo
    // disparo.
    remoto.alSubir = () async {
      if (yaPedido) return;
      yaPedido = true;
      await db
          .into(db.pesasSesiones)
          .insert(
            PesasSesionesCompanion.insert(
              id: 'sesion-tardia',
              lecheriaId: lecheriaId,
              fecha: ts,
              createdAt: ts,
              updatedAt: ts,
              pendiente: const Value(true),
            ),
          );
      sync.sincronizar(); // sin await: llega mientras la vuelta está en curso
    };

    await sync.sincronizar();

    expect(await pendientesTotales(), 0);
    expect(
      remoto.subidas.any((w) => w.id == 'sesion-tardia'),
      isTrue,
      reason: 'la fila guardada durante la subida tiene que haber subido',
    );
  });

  test('hayPendientes distingue si quedó algo por subir', () async {
    // Es lo que mira el reintento automático para no despertar la red cuando
    // no hay nada que mandar.
    expect(await sync.hayPendientes(), isFalse);

    await sembrarPendientes(1);
    expect(await sync.hayPendientes(), isTrue);

    await sync.sincronizar();
    expect(await sync.hayPendientes(), isFalse);
  });

  test('el progreso arranca y termina inactivo', () async {
    await sembrarPendientes(3);
    expect(sync.progreso.value.activo, isFalse);

    final vistos = <int>[];
    sync.progreso.addListener(() {
      if (sync.progreso.value.activo) vistos.add(sync.progreso.value.total);
    });

    await sync.sincronizar();

    expect(vistos, isNotEmpty, reason: 'tiene que reportar el total');
    expect(sync.progreso.value.activo, isFalse);
    expect(sync.sincronizando.value, isFalse);
  });

  test('sin usuario no intenta nada', () async {
    final sinSesion = SyncService(
      db,
      remote: FakeSyncRemoteGateway(tieneUsuario: false),
      esperasReintento: const [],
    );
    await sembrarPendientes(2);

    await sinSesion.sincronizar();

    expect(await pendientesTotales(), greaterThan(0));
  });
}
