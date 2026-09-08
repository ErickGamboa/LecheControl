// El cursor de bajada es por usuario, y esto es por qué.
//
// La bajada es incremental: pide las filas con `(updated_at, id) >` el
// cursor. Y lo que cada usuario ve del servidor lo decide RLS: solo lo suyo.
//
// Con un cursor por tabla —sin el usuario— pasaba lo siguiente en un teléfono
// donde se usan dos cuentas: al sincronizar la cuenta A el cursor quedaba en
// la fecha de la fila de A, y al entrar después con la cuenta B, si la fila de
// B era **más vieja**, quedaba detrás del cursor y no bajaba nunca. La app se
// quedaba esperando una cuenta que el servidor tenía y le habría dado.
//
// Pasó de verdad con dos cuentas cuyos `usuarios.updated_at` eran 20:44 y
// 20:36: la primera funcionaba siempre y la segunda se trababa en cuanto la
// otra hubiera entrado una vez en ese teléfono.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leche_control/data/local/database.dart';
import 'package:leche_control/data/sync/sync_service.dart';

import '../support/fake_sync_remote_gateway.dart';

void main() {
  late AppDatabase db;

  // La cuenta que entró primero. Su fila es la MÁS NUEVA.
  const usuarioA = 'user-a';
  final filaA = DateTime.utc(2026, 9, 7, 20, 44, 37);

  // La cuenta que entra después. Su fila es MÁS VIEJA que la de A: es la que
  // quedaba detrás del cursor y no bajaba nunca.
  const usuarioB = 'user-b';
  final filaB = DateTime.utc(2026, 9, 7, 20, 36, 39);

  setUp(() {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
  });

  tearDown(() async => db.close());

  /// El perfil que el servidor le entrega a [usuario] —solo el suyo, como
  /// hace RLS.
  Map<String, dynamic> perfilDe(String usuario, DateTime cuando) => {
    'id': usuario,
    'nombre': usuario,
    'email': '$usuario@ejemplo.com',
    'cuenta_id': 'cuenta-$usuario',
    'created_at': cuando.toIso8601String(),
    'updated_at': cuando.toIso8601String(),
  };

  Future<void> sincronizarComo(
    String usuario,
    Map<String, dynamic> perfil,
  ) async {
    final remoto = FakeSyncRemoteGateway(usuarioId: usuario);
    // Como hace RLS: el servidor solo le entrega su propia fila.
    remoto.descargas['usuarios'] = [perfil];
    await SyncService(
      db,
      remote: remoto,
      esperasReintento: const [],
    ).sincronizar();
  }

  test('la cuenta que entra después baja su perfil aunque sea más vieja', () async {
    // 1. Entra A: baja su perfil y el cursor queda en la fecha de A.
    await sincronizarComo(usuarioA, perfilDe(usuarioA, filaA));
    final trasA = await db.select(db.usuarios).get();
    expect(trasA.map((u) => u.id), [usuarioA]);

    // 2. Entra B en el mismo teléfono. Su fila es más vieja que la de A.
    await sincronizarComo(usuarioB, perfilDe(usuarioB, filaB));

    final trasB = await db.select(db.usuarios).get();
    expect(
      trasB.map((u) => u.id),
      containsAll([usuarioA, usuarioB]),
      reason:
          'el perfil de la segunda cuenta no bajó: quedó detrás del cursor '
          'de la primera, que es justo el bug que este cambio arregla',
    );
  });

  test('cada usuario lleva su propio cursor', () async {
    await sincronizarComo(usuarioA, perfilDe(usuarioA, filaA));
    await sincronizarComo(usuarioB, perfilDe(usuarioB, filaB));

    final cursores = await db.select(db.syncCursores).get();
    final deUsuarios = cursores.where((c) => c.tabla == 'usuarios');

    expect(deUsuarios.map((c) => c.usuarioId), containsAll([usuarioA, usuarioB]));
    expect(
      deUsuarios.firstWhere((c) => c.usuarioId == usuarioA).ultimaBajada,
      filaA,
    );
    expect(
      deUsuarios.firstWhere((c) => c.usuarioId == usuarioB).ultimaBajada,
      filaB,
      reason: 'el cursor de B no puede quedar en la fecha de A',
    );
  });

  test('volver a entrar con la misma cuenta no rebaja lo que ya tiene', () async {
    // El cursor sigue sirviendo para lo que es —no repetir trabajo—; solo
    // dejó de ser compartido entre cuentas.
    await sincronizarComo(usuarioA, perfilDe(usuarioA, filaA));

    final cursor = (await db.select(db.syncCursores).get())
        .firstWhere((c) => c.tabla == 'usuarios' && c.usuarioId == usuarioA);
    expect(cursor.ultimaBajada, filaA);
    expect(cursor.ultimaBajadaId, usuarioA);
  });
}
