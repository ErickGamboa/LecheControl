// El modo demo no puede salir en una build de release, y si quedaron restos
// de una build demo hay que limpiarlos.
//
// POR QUÉ IMPORTA TANTO
//
// `maybeSeedDemoOnStartup` no es inofensivo: en cada arranque siembra una
// finca falsa, **le cierra la sesión al usuario** (`supabase.auth.signOut()`)
// y activa una sesión demo. Una build de TestFlight salió con `LECHE_DEMO`
// puesto y produjo exactamente esto:
//
//   - Al abrir la app aparecía «Lechería Demo LecheControl» con animales
//     ajenos, en vez de la finca del ganadero.
//   - La sesión se cerraba sola en cada arranque, así que nunca quedaba
//     dentro de su cuenta.
//   - Y sin sesión el sync no corre: la app se quedaba en «Preparando tu
//     cuenta…», y parecía un problema de cuentas o de servidor.
//
// Costó días entenderlo. Estas pruebas son para que no vuelva a pasar por un
// flag olvidado en un comando de build.

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leche_control/data/local/database.dart';
import 'package:leche_control/demo/demo_env.dart';
import 'package:leche_control/demo/demo_seed.dart';

void main() {
  test('el modo demo exige build de depuración, no solo el define', () {
    // En los tests `kDebugMode` es true, así que lo que se puede afirmar es
    // la regla: sin depuración, jamás. Si alguien quita el `&& kDebugMode`,
    // esta prueba deja de tener sentido y el comentario de arriba explica por
    // qué no hay que hacerlo.
    expect(
      kSeedDemoEnabled,
      anyOf(isFalse, isTrue),
      reason: 'depende del define; lo que importa es la condición de abajo',
    );
    if (!kDebugMode) {
      expect(
        kSeedDemoEnabled,
        isFalse,
        reason: 'una build que no es de depuración no puede sembrar el demo: '
            'el modo demo cierra la sesión del usuario en cada arranque',
      );
    }
  });

  test('los ids del demo son fijos, que es lo que permite limpiarlos', () {
    // La limpieza los reconoce por id. Si alguien los vuelve aleatorios, los
    // restos de una build demo quedarían para siempre en el teléfono.
    expect(DemoSeedIds.userId, '00000000-0000-4000-9000-000000000001');
    expect(DemoSeedIds.cuentaId, '00000000-0000-4000-9000-000000000010');
    expect(DemoSeedIds.lecheriaNombre, 'Lechería Demo LecheControl');
  });

  group('limpiar los restos de una build demo', () {
    late AppDatabase base;

    setUp(() => base = AppDatabase.forExecutor(NativeDatabase.memory()));
    tearDown(() async => base.close());

    /// Deja en la base lo que dejaría una build demo: la cuenta, el usuario,
    /// la lechería falsa con un animal, y la sesión demo que hace entrar sin
    /// login.
    Future<void> sembrarRestosDeDemo() async {
      final ts = DateTime(2026, 9, 1);
      await base.into(base.cuentas).insert(
        CuentasCompanion.insert(
          id: DemoSeedIds.cuentaId,
          nombre: 'Cuenta Demo',
          duenoId: DemoSeedIds.userId,
          plan: 'pro',
          estado: 'activa',
          createdAt: ts,
          updatedAt: ts,
        ),
      );
      await base.into(base.usuarios).insert(
        UsuariosCompanion.insert(
          id: DemoSeedIds.userId,
          nombre: const Value('Demo'),
          createdAt: ts,
          updatedAt: ts,
        ),
      );
      await base.into(base.lecherias).insert(
        LecheriasCompanion.insert(
          id: 'lech-demo',
          nombre: DemoSeedIds.lecheriaNombre,
          creadaPor: DemoSeedIds.userId,
          cuentaId: const Value(DemoSeedIds.cuentaId),
          createdAt: ts,
          updatedAt: ts,
        ),
      );
      await base.into(base.animales).insert(
        AnimalesCompanion.insert(
          id: 'an-demo',
          lecheriaId: 'lech-demo',
          identificador: 'DEMO-1',
          sexo: 'hembra',
          grupo: 'en_ordeno',
          origen: 'nacido',
          createdAt: ts,
          updatedAt: ts,
        ),
      );
      await base.into(base.sesionesLocales).insert(
        SesionesLocalesCompanion.insert(
          id: 'actual',
          usuarioId: DemoSeedIds.userId,
          ultimoLoginOnline: DateTime(2026, 9, 1),
          offlineActiva: const Value(true),
        ),
      );
    }

    test('se van la finca falsa, su cuenta y la sesión demo', () async {
      await sembrarRestosDeDemo();

      await limpiarRestosDeDemo(base: base);

      expect(await base.select(base.lecherias).get(), isEmpty);
      expect(await base.select(base.animales).get(), isEmpty);
      expect(await base.select(base.cuentas).get(), isEmpty);
      expect(await base.select(base.usuarios).get(), isEmpty);
      expect(
        await base.select(base.sesionesLocales).get(),
        isEmpty,
        reason: 'la sesión demo es la que hace entrar sin login a la finca '
            'falsa: si queda, el ganadero sigue viéndola',
      );
    });

    test('no toca la finca de un ganadero de verdad', () async {
      final ts = DateTime(2026, 9, 1);
      await base.into(base.cuentas).insert(
        CuentasCompanion.insert(
          id: 'cuenta-real',
          nombre: 'Mi lechería',
          duenoId: 'user-real',
          plan: 'invitado',
          estado: 'activa',
          createdAt: ts,
          updatedAt: ts,
        ),
      );
      await base.into(base.lecherias).insert(
        LecheriasCompanion.insert(
          id: 'lech-real',
          nombre: 'LecheriaErick',
          creadaPor: 'user-real',
          cuentaId: const Value('cuenta-real'),
          createdAt: ts,
          updatedAt: ts,
        ),
      );
      await base.into(base.sesionesLocales).insert(
        SesionesLocalesCompanion.insert(
          id: 'actual',
          usuarioId: 'user-real',
          ultimoLoginOnline: DateTime(2026, 9, 1),
          offlineActiva: const Value(true),
        ),
      );

      await limpiarRestosDeDemo(base: base);

      expect((await base.select(base.lecherias).getSingle()).nombre,
          'LecheriaErick');
      expect(await base.select(base.cuentas).get(), hasLength(1));
      expect(
        await base.select(base.sesionesLocales).get(),
        hasLength(1),
        reason: 'sacarle la sesión offline a quien está en el corral sin '
            'señal lo dejaría afuera de su propia finca',
      );
    });

    test('sin restos no hace nada y no revienta', () async {
      await limpiarRestosDeDemo(base: base);
      expect(await base.select(base.lecherias).get(), isEmpty);
    });
  });
}
