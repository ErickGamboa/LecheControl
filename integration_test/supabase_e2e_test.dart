import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:leche_control/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:leche_control/main.dart' as app;
import 'helpers/integration_helpers.dart';
import 'helpers/supabase_assert.dart';

/// Usuario Supabase real, sembrado de antemano (ver `docs/QA_AUTOMATION.md`).
/// Si no está definido, el test se salta en vez de fallar — así puede vivir
/// en CI/local sin credenciales sin romper la corrida.
const _email = String.fromEnvironment('LECHE_E2E_EMAIL');
const _password = String.fromEnvironment('LECHE_E2E_PASSWORD');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'visible: login, lechería, alta de animal, pesa, gastos y rentabilidad '
    'contra Supabase real',
    (tester) async {
      if (_email.isEmpty || _password.isEmpty) {
        markTestSkipped(
          'Define LECHE_E2E_EMAIL y LECHE_E2E_PASSWORD con un usuario '
          'Supabase sembrado para correr este e2e visible '
          '(ver docs/QA_AUTOMATION.md).',
        );
        return;
      }
      e2eAttachBinding(binding);

      final stamp = DateTime.now().millisecondsSinceEpoch;
      final lecheriaNombre = 'E2E Lechería $stamp';
      final identificador = 'E2E-${stamp % 1000000}';

      await e2eStep('arrancar la app');
      await app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await pauseIntegration(tester);

      // Empezar siempre desde login, aunque el simulador conserve sesión de
      // una corrida anterior.
      await e2eStep('cerrar sesión previa si la había');
      await Supabase.instance.client.auth.signOut();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 1) Login real contra Supabase.
      await e2eStep('login con credenciales reales');
      await waitFor(tester, find.byKey(const ValueKey('login.email')));
      await tester.enterText(find.byKey(const ValueKey('login.email')), _email);
      await pauseIntegration(tester);
      await tester.enterText(
        find.byKey(const ValueKey('login.password')),
        _password,
      );
      await pauseIntegration(tester);
      await invokeButton(tester, find.byKey(const ValueKey('login.submit')));

      // 2) Esperar a que baje la cuenta (spinner) y luego home o crear lechería.
      await e2eStep('esperar home o formulario de lechería nueva');
      final home = find.byKey(const ValueKey('home.trabajo'));
      final crearLecheriaField = find.byKey(const ValueKey('lecheria.nombre'));
      final finLogin = DateTime.now().add(const Duration(seconds: 45));
      while (DateTime.now().isBefore(finLogin) &&
          home.evaluate().isEmpty &&
          crearLecheriaField.evaluate().isEmpty) {
        await tester.pump(const Duration(milliseconds: 250));
      }

      if (crearLecheriaField.evaluate().isNotEmpty) {
        await e2eStep('crear la lechería (primera corrida del usuario e2e)');
        await tester.enterText(crearLecheriaField, lecheriaNombre);
        await pauseIntegration(tester);
        await invokeButton(
          tester,
          find.byKey(const ValueKey('lecheria.crear')),
        );
        // Esperar a que el stream de lechería refleje el alta local.
        await waitFor(tester, home, timeoutSeconds: 20, label: 'home.trabajo');
      } else {
        await waitFor(tester, home, timeoutSeconds: 25, label: 'home.trabajo');
      }
      await pauseIntegration(tester);

      // 3) Módulo Trabajo: dar de alta un animal nuevo en ordeño.
      await e2eStep('abrir Trabajo y dar de alta un animal nuevo');
      await tapKey(
        tester,
        const ValueKey('home.trabajo'),
        label: 'home.trabajo',
      );
      await waitFor(
        tester,
        find.byKey(const ValueKey('trabajo.identificador')),
        label: 'trabajo.identificador',
      );
      await pauseIntegration(tester);

      await tester.enterText(
        find.byKey(const ValueKey('trabajo.identificador')),
        identificador,
      );
      await pauseIntegration(tester);
      await tester.tap(find.byKey(const ValueKey('trabajo.buscar')));
      await pumpBounded(tester);

      await invokeButton(
        tester,
        find.byKey(const ValueKey('trabajo.alta.abrir')),
      );
      await waitFor(
        tester,
        find.byKey(const ValueKey('trabajo.alta.guardar')),
        label: 'trabajo.alta.guardar',
      );
      await pauseIntegration(tester);
      // El identificador ya viene precargado desde el buscador; el grupo por
      // defecto ("En ordeño") es el que necesitamos para pesa y rentabilidad.
      await invokeButton(
        tester,
        find.byKey(const ValueKey('trabajo.alta.guardar')),
      );
      await waitFor(
        tester,
        find.byKey(const ValueKey('trabajo.animal.tarjeta')),
        label: 'trabajo.animal.tarjeta',
      );
      await pauseIntegration(tester, multiplier: 2);

      await e2eStep('volver al home desde Trabajo');
      await tapBack(tester);
      await waitFor(
        tester,
        find.byKey(const ValueKey('home.syncStatus')),
        label: 'home.syncStatus',
      );

      // 4) Módulo Pesa de leche: registrar litros del animal recién creado.
      await e2eStep('registrar litros en Pesa de leche');
      await tapKey(tester, const ValueKey('home.pesa'), label: 'home.pesa');
      await waitFor(
        tester,
        find.byKey(const ValueKey('pesa.identificador')),
        label: 'pesa.identificador',
      );
      await pauseIntegration(tester);

      await tester.enterText(
        find.byKey(const ValueKey('pesa.identificador')),
        identificador,
      );
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await pumpBounded(tester);
      await waitFor(
        tester,
        find.byKey(const ValueKey('pesa.litros')),
        label: 'pesa.litros',
      );
      await pauseIntegration(tester);
      await tester.enterText(find.byKey(const ValueKey('pesa.litros')), '18.5');
      await pauseIntegration(tester);
      await invokeButton(tester, find.byKey(const ValueKey('pesa.guardar')));
      await pumpBounded(tester);

      await e2eStep('volver al home desde Pesa de leche');
      await tapBack(tester);
      await waitFor(
        tester,
        find.byKey(const ValueKey('home.syncStatus')),
        label: 'home.syncStatus',
      );

      // 5) Módulo Gastos: fijar precio del litro y del concentrado del mes.
      await e2eStep('configurar precios en Gastos');
      await tapKey(tester, const ValueKey('home.gastos'), label: 'home.gastos');
      await waitFor(
        tester,
        find.byKey(const ValueKey('gastos.editarParametros')),
        label: 'gastos.editarParametros',
      );
      await pauseIntegration(tester);

      await tester.tap(find.byKey(const ValueKey('gastos.editarParametros')));
      await waitFor(
        tester,
        find.byKey(const ValueKey('gastos.precioLitro')),
        label: 'gastos.precioLitro',
      );
      await pauseIntegration(tester);
      await tester.enterText(
        find.byKey(const ValueKey('gastos.precioLitro')),
        '400',
      );
      await pauseIntegration(tester);
      await tester.enterText(
        find.byKey(const ValueKey('gastos.precioConcentrado')),
        '350',
      );
      await pauseIntegration(tester);
      await tester.enterText(
        find.byKey(const ValueKey('gastos.umbralSecado')),
        '8',
      );
      await pauseIntegration(tester);
      await invokeButton(
        tester,
        find.byKey(const ValueKey('gastos.guardarParametros')),
      );
      await pumpBounded(tester);

      await e2eStep('volver al home desde Gastos');
      await tapBack(tester);
      await waitFor(
        tester,
        find.byKey(const ValueKey('home.syncStatus')),
        label: 'home.syncStatus',
      );

      // 6) Módulo Rentabilidad: ver la fila calculada para el animal.
      await e2eStep('ver la fila de rentabilidad del animal');
      await tapKey(
        tester,
        const ValueKey('home.rentabilidad'),
        label: 'home.rentabilidad',
      );
      await waitFor(
        tester,
        find.byKey(const ValueKey('rentabilidad.lista')),
        label: 'rentabilidad.lista',
      );
      await scrollUntilVisible(tester, find.text(identificador));
      expect(find.text(identificador), findsWidgets);
      await pauseIntegration(tester, multiplier: 2);

      await e2eStep('volver al home desde Rentabilidad');
      await tapBack(tester);
      await waitFor(
        tester,
        find.byKey(const ValueKey('home.syncStatus')),
        label: 'home.syncStatus',
      );

      // 7) Forzar sync y confirmar que el animal quedó en la nube.
      await e2eStep('esperar sincronización con Supabase');
      await syncService.sincronizar();
      await pumpBounded(tester, ticks: 80);
      await waitForSupabaseRow(
        table: 'animales',
        column: 'identificador',
        equals: identificador,
        timeout: const Duration(seconds: 60),
      );
    },
  );
}
