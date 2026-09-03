// Smoke test: la app debe arrancar y mostrar la pantalla de login cuando no
// hay sesión. Este test monta AuthGate directo, sin pasar por
// `bootstrapLecheControl`, así que `Supabase.initialize` nunca corrió y
// `supabaseClientOrNull` devuelve null: AuthGate cae al modo offline/login
// local. (SupabaseConfig sí trae credenciales por defecto, pero tener
// configuración no implica tener el cliente inicializado.)

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

    // La marca son dos tramos de distinto color dentro de un mismo texto
    // (LECHE en azul, CONTROL en verde), así que hay que mirar adentro del
    // texto enriquecido en vez de buscar la cadena entera.
    expect(find.textContaining('LECHE', findRichText: true), findsOneWidget);
    expect(find.textContaining('CONTROL', findRichText: true), findsOneWidget);
    expect(find.text('Iniciá sesión'), findsOneWidget);
  });
}
