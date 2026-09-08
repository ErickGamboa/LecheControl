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
      // Monto irrepetible: así se puede buscar exactamente esta fila en el
      // servidor sin confundirla con gastos de otra corrida.
      final montoGasto = 1000 + (stamp % 9000);

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
      await volverAlHome(tester);

      // 4) Módulo Registro de leche -> Pesa: registrar litros del animal
      //    recién creado.
      await e2eStep('registrar litros en Pesa de leche');
      await tapKey(
        tester,
        const ValueKey('home.registroLeche'),
        label: 'home.registroLeche',
      );
      await tapKey(
        tester,
        const ValueKey('registro.pesa'),
        label: 'registro.pesa',
      );
      await waitFor(
        tester,
        find.byKey(const ValueKey('pesa.elegirVaca')),
        label: 'pesa.elegirVaca',
      );
      await pauseIntegration(tester);

      // La pesa ya no se digita por identificador: se elige la vaca de la
      // lista de las que faltan en la sesión (ver `SelectorVacaSheet`).
      await invokeButton(tester, find.byKey(const ValueKey('pesa.elegirVaca')));
      await waitFor(
        tester,
        find.byKey(const ValueKey('selectorVaca.busqueda')),
        label: 'selectorVaca.busqueda',
      );
      await tester.enterText(
        find.byKey(const ValueKey('selectorVaca.busqueda')),
        identificador,
      );
      await pumpBounded(tester);
      await tapKey(
        tester,
        ValueKey('selectorVaca.vaca.$identificador'),
        label: 'selectorVaca.vaca.$identificador',
      );

      await waitFor(
        tester,
        find.byKey(const ValueKey('pesa.manana')),
        label: 'pesa.manana',
      );
      await pauseIntegration(tester);
      await tester.enterText(find.byKey(const ValueKey('pesa.manana')), '10.5');
      await tester.enterText(find.byKey(const ValueKey('pesa.tarde')), '8.0');
      await pauseIntegration(tester);
      await invokeButton(tester, find.byKey(const ValueKey('pesa.guardar')));
      await pumpBounded(tester);

      await e2eStep('volver al home desde Pesa de leche');
      await volverAlHome(tester);

      // 5) Módulo Finanzas: anotar un gasto de la semana.
      await e2eStep('anotar un gasto en Finanzas');
      await tapKey(
        tester,
        const ValueKey('home.finanzas'),
        label: 'home.finanzas',
      );
      await waitFor(
        tester,
        find.byKey(const ValueKey('finanzas.agregarGasto')),
        label: 'finanzas.agregarGasto',
      );
      await pauseIntegration(tester);

      await invokeButton(
        tester,
        find.byKey(const ValueKey('finanzas.agregarGasto')),
      );
      await waitFor(
        tester,
        find.byKey(const ValueKey('finanzas.gasto.monto')),
        label: 'finanzas.gasto.monto',
      );
      await tapKey(
        tester,
        const ValueKey('finanzas.gasto.cat.Concentrado'),
        label: 'finanzas.gasto.cat.Concentrado',
      );
      await tester.enterText(
        find.byKey(const ValueKey('finanzas.gasto.monto')),
        montoGasto.toStringAsFixed(0),
      );
      await pauseIntegration(tester);
      await invokeButton(
        tester,
        find.byKey(const ValueKey('finanzas.gasto.guardar')),
      );
      await pumpBounded(tester);

      await e2eStep('volver al home desde Finanzas');
      await volverAlHome(tester);

      // 7) Forzar sync y confirmar que el animal quedó en la nube.
      await e2eStep('esperar sincronización con Supabase');
      await syncService.sincronizar();
      await pumpBounded(tester, ticks: 80);
      final animalEnLaNube = await waitForSupabaseRow(
        table: 'animales',
        column: 'identificador',
        equals: identificador,
        timeout: const Duration(seconds: 60),
      );

      // Y la pesa también. El animal solo prueba que sube el alta; los litros
      // son lo que el ganadero digita todos los días, así que si esto no
      // llega, la sincronización no sirve de nada.
      final pesaEnLaNube = await waitForSupabaseRow(
        table: 'pesas_leche',
        column: 'animal_id',
        equals: animalEnLaNube['id'] as String,
        timeout: const Duration(seconds: 60),
      );
      expect(
        (pesaEnLaNube['litros'] as num).toDouble(),
        closeTo(18.5, 0.001),
        reason: 'los litros del día son mañana + tarde',
      );

      // Y el gasto. Sube por otro camino (cuelga de la semana, que la app
      // crea sola), así que vale la pena verlo aparte.
      final gastoEnLaNube = await waitForSupabaseRow(
        table: 'gastos_semana',
        column: 'monto',
        equals: montoGasto,
        timeout: const Duration(seconds: 60),
      );
      expect(gastoEnLaNube['categoria'], 'Concentrado');
    },
  );
}
