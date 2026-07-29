// Smoke test: la app debe arrancar y mostrar la pantalla de login cuando no
// hay sesión (Supabase no configurado en el entorno de test, así que
// AuthGate cae directo al modo offline/login local).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:leche_control/app/theme.dart';
import 'package:leche_control/auth/auth_gate.dart';

void main() {
  testWidgets('La app arranca y muestra la pantalla de login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        title: 'LecheControl',
        theme: LecheTheme.light,
        home: const AuthGate(),
      ),
    );
    // Deja correr el timer interno de drift_flutter (apertura perezosa de la
    // base de datos) para que no quede pendiente al terminar el test.
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('LecheControl'), findsWidgets);
    expect(find.text('Iniciá sesión'), findsOneWidget);
  });
}
