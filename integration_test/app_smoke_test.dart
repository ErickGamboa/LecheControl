import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:leche_control/main.dart' as app;
import 'package:leche_control/services.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app arranca y muestra pantalla de login', (tester) async {
    await app.main();
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    // En un dispositivo/simulador reutilizado (p. ej. de una corrida de
    // `LECHE_DEMO` anterior) puede quedar una sesión local offline activa;
    // la limpiamos para que este smoke test sea determinístico.
    if (sesionLocalRepo.offlineActiva) {
      await sesionLocalRepo.borrar();
      await tester.pumpAndSettle();
    }

    // Sin `LECHE_SUPABASE_URL`/`LECHE_SUPABASE_ANON_KEY` configurados,
    // `AuthGate` se queda en modo offline/demo y, sin sesión local guardada,
    // muestra `LoginScreen` directamente (ver `app_bootstrap.dart`).
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byKey(const ValueKey('login.email')), findsOneWidget);
    expect(find.byKey(const ValueKey('login.password')), findsOneWidget);
    expect(find.byKey(const ValueKey('login.submit')), findsOneWidget);
  });
}
