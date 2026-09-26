// LecheControl no cobra nada y no se vence. Antes una cuenta marcada como
// suspendida, o con la prueba vencida, dejaba al ganadero afuera de sus
// propios datos y lo mandaba a una pantalla a contactar soporte. Estas
// pruebas fijan que eso no vuelva: la cuenta puede venir del servidor con
// cualquier estado y la app trabaja igual.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leche_control/data/local/database.dart';
import 'package:leche_control/data/repositories/lecherias_repository.dart';

import '../support/local_db_seed.dart';

void main() {
  late AppDatabase db;
  late LecheriasRepository repo;
  const usuarioId = 'user-1';

  setUp(() async {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    repo = LecheriasRepository(db);
  });

  tearDown(() async => db.close());

  test('una cuenta suspendida crea y usa su lechería igual', () async {
    await seedCuentaLocal(
      db,
      usuarioId: usuarioId,
      estado: 'suspendida',
      limiteLecherias: 1,
    );

    await repo.crearLecheria(nombre: 'La Esperanza', creadaPor: usuarioId);

    final lecheria = await repo.obtenerActiva(usuarioId);
    expect(lecheria?.nombre, 'La Esperanza');
  });

  test('la prueba vencida hace años no cambia nada', () async {
    await seedCuentaLocal(
      db,
      usuarioId: usuarioId,
      plan: 'light',
      pruebaTermina: DateTime(2020, 1, 1),
      limiteLecherias: 1,
    );

    await repo.crearLecheria(nombre: 'La Esperanza', creadaPor: usuarioId);

    expect((await repo.obtenerActiva(usuarioId))?.nombre, 'La Esperanza');
  });

  test('suspendida y vencida a la vez: sigue entrando', () async {
    await seedCuentaLocal(
      db,
      usuarioId: usuarioId,
      estado: 'suspendida',
      pruebaTermina: DateTime(2020, 1, 1),
      limiteLecherias: 1,
    );

    await repo.crearLecheria(nombre: 'La Esperanza', creadaPor: usuarioId);

    expect((await repo.obtenerActiva(usuarioId))?.nombre, 'La Esperanza');
  });

  test('sin la cuenta bajada pide sincronizar, no autorizar', () async {
    // Sin `seedCuentaLocal`: es el usuario que todavía no sincronizó nunca.
    expect(
      () => repo.crearLecheria(nombre: 'La Esperanza', creadaPor: usuarioId),
      throwsA(isA<CuentaNoSincronizadaException>()),
    );
  });

  group('el tope de lecherías', () {
    test('es estructural: una por cuenta', () async {
      await seedCuentaLocal(db, usuarioId: usuarioId, limiteLecherias: 1);
      await repo.crearLecheria(nombre: 'La Primera', creadaPor: usuarioId);

      expect(
        () => repo.crearLecheria(nombre: 'La Segunda', creadaPor: usuarioId),
        throwsA(isA<LimiteLecheriasException>()),
      );
    });

    test('lo dice sin nombrar planes ni pedir plata', () {
      const mensajes = [
        LimiteLecheriasException(1),
        LimiteLecheriasException(3),
      ];
      // Las palabras que no pueden aparecer nunca en lo que lee el ganadero.
      const prohibidas = [
        'plan',
        'licencia',
        'pag',
        'suscri',
        'prueba',
        'premium',
        'mejor',
      ];

      for (final e in mensajes) {
        final texto = e.mensaje.toLowerCase();
        expect(texto, isNotEmpty);
        for (final palabra in prohibidas) {
          expect(
            texto.contains(palabra),
            isFalse,
            reason: '«${e.mensaje}» insinúa pago con "$palabra"',
          );
        }
      }
    });

    test('no deja ver cuántas fincas caben', () {
      // El tope no se nombra ni de refilón: ni el número, ni «una sola», ni
      // «ya tiene todas». Al ganadero no le importa y decirlo hace que
      // parezca que hay algo más que comprar. Donde se nota el tope es en
      // que el botón de agregar no aparece, y con eso alcanza.
      for (final limite in [1, 3, 99]) {
        final texto = LimiteLecheriasException(limite).mensaje;
        expect(texto, isNotEmpty);
        expect(
          RegExp(r'[0-9]').hasMatch(texto),
          isFalse,
          reason: '«$texto» deja ver el tope',
        );
        expect(texto.toLowerCase(), isNot(contains('sola')));
        expect(texto.toLowerCase(), isNot(contains('máximo')));
      }

      // Y el mensaje es siempre el mismo, para que comparar dos cuentas no
      // diga nada tampoco.
      expect(
        const LimiteLecheriasException(1).mensaje,
        const LimiteLecheriasException(3).mensaje,
      );
    });
  });
}
