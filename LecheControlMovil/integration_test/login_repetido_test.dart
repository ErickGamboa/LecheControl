// Entrar, salir y volver a entrar con la MISMA cuenta, tres veces seguidas.
//
// Esto es el bug que reportó el ganadero, tal cual: «si cierro sesión e
// intento entrar a la misma cuenta de appletest sale la pantalla de reintentar
// o cerrar sesión», y «después de varios intentos, que no debería ser así,
// entro pero me dice que le ponga nombre a la lechería y no debería porque ya
// hay una en esa cuenta con datos».
//
// Así que el test no se conforma con entrar una vez: hace el ciclo completo
// varias veces y en cada una exige las dos cosas que fallaban:
//   1. Llegar al home, no a «Preparando tu cuenta…».
//   2. Que la lechería de la cuenta esté ahí, con sus animales. Si pide crear
//      una, la bajada no llegó y el ganadero está viendo una finca vacía.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:leche_control/data/domain/grupos.dart';
import 'package:leche_control/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:leche_control/main.dart' as app;
import 'helpers/integration_helpers.dart';

const _email = String.fromEnvironment('LECHE_E2E_EMAIL');
const _password = String.fromEnvironment('LECHE_E2E_PASSWORD');

/// Cuántas veces se repite el ciclo entrar → salir → entrar.
const _vueltas = 3;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('entrar y salir varias veces con la misma cuenta', (
    tester,
  ) async {
    if (_email.isEmpty || _password.isEmpty) {
      markTestSkipped(
        'Define LECHE_E2E_EMAIL y LECHE_E2E_PASSWORD (ver '
        'docs/QA_AUTOMATION.md).',
      );
      return;
    }
    e2eAttachBinding(binding);

    final home = find.byKey(const ValueKey('home.syncStatus'));
    final pedirNombreLecheria = find.byKey(const ValueKey('lecheria.nombre'));
    final campoCorreo = find.byKey(const ValueKey('login.email'));

    await e2eStep('arrancar la app');
    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await e2eStep('empezar sin sesión');
    await Supabase.instance.client.auth.signOut();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    for (var vuelta = 1; vuelta <= _vueltas; vuelta++) {
      await e2eStep('vuelta $vuelta: login');
      await waitFor(tester, campoCorreo, timeoutSeconds: 30, label: 'login');
      await tester.enterText(campoCorreo, _email);
      await tester.enterText(
        find.byKey(const ValueKey('login.password')),
        _password,
      );
      await invokeButton(tester, find.byKey(const ValueKey('login.submit')));

      // La cuenta baja del servidor antes de mostrar el home. Si esto se
      // vence, es la pantalla de «Preparando tu cuenta…» que no avanza.
      await waitFor(
        tester,
        home,
        timeoutSeconds: 60,
        label: 'home (vuelta $vuelta)',
      );

      expect(
        pedirNombreLecheria,
        findsNothing,
        reason:
            'vuelta $vuelta: pidió crear una lechería, y la cuenta ya tiene '
            'una en el servidor. La bajada no llegó',
      );

      // Y no basta con que muestre el home: los datos de la cuenta tienen que
      // estar de verdad en el teléfono.
      final usuarioId = Supabase.instance.client.auth.currentUser!.id;
      final lecheria = await lecheriasRepo.obtenerActiva(usuarioId);
      expect(lecheria, isNotNull, reason: 'vuelta $vuelta: entró sin lechería');
      var total = 0;
      for (final grupo in GrupoAnimal.todos) {
        total += await animalesRepo.contarPorGrupo(lecheria!.id, grupo);
      }
      expect(
        total,
        greaterThan(0),
        reason:
            'vuelta $vuelta: la lechería "${lecheria!.nombre}" bajó vacía; los '
            'animales de la cuenta no llegaron',
      );
      await e2eStep(
        'vuelta $vuelta: adentro en "${lecheria.nombre}" con $total animales',
      );

      await e2eStep('vuelta $vuelta: cerrar sesión');
      await tapKey(
        tester,
        const ValueKey('home.cerrarSesion'),
        label: 'home.cerrarSesion',
      );
      await waitFor(
        tester,
        campoCorreo,
        timeoutSeconds: 30,
        label: 'login (después de salir, vuelta $vuelta)',
      );
    }
  });
}
