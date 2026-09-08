// El que inicia sesión y todavía no tiene su fila de cuenta ve una pantalla
// de espera. Esa pantalla llegó a ser un callejón sin salida: giraba para
// siempre, no reintentaba —el reintento de fondo solo corre si hay algo
// pendiente que subir, y un usuario nuevo no tiene nada— y no traía botón de
// cerrar sesión. Para salir había que borrar los datos de la app.
//
// Se prueba contra `CuentaGate` de verdad. No hace falta base ni red: sin
// cuenta local el stream emite null, que es justo el caso que interesa.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leche_control/app/theme.dart';
import 'package:leche_control/cuenta/cuenta_gate.dart';

void main() {
  final reintentar = find.byKey(const ValueKey('cuenta.reintentar'));
  final cerrarSesion = find.byKey(const ValueKey('cuenta.cerrarSesion'));

  Future<void> montar(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: LecheTheme.light,
        home: const CuentaGate(usuarioId: 'user-sin-cuenta', sinConexion: false),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('primero avisa que está preparando la cuenta', (tester) async {
    await montar(tester);

    expect(find.text('Preparando tu cuenta…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // Todavía no se rinde: está trabajando de verdad.
    expect(reintentar, findsNothing);
  });

  testWidgets('si no llega, deja de girar y da las dos salidas', (
    tester,
  ) async {
    await montar(tester);

    await tester.pump(const Duration(seconds: 21));
    await tester.pump();

    expect(find.text('No pudimos preparar tu cuenta'), findsOneWidget);
    expect(
      find.byType(CircularProgressIndicator),
      findsNothing,
      reason: 'seguir girando después de rendirse solo confunde',
    );
    expect(reintentar, findsOneWidget);
    expect(
      cerrarSesion,
      findsOneWidget,
      reason: 'sin esta salida hay que borrar los datos de la app para salir',
    );
  });

  // Lo que muestra el recuadro se prueba en `diagnostico_sync_test.dart`:
  // esa lógica lee la base y acá no hay una de verdad. Lo que importa fijar
  // en esta pantalla es que el aviso y los botones salgan **sin esperar** el
  // diagnóstico, para que un diagnóstico lento no la deje inservible.

  testWidgets('tras avisar, sigue intentando sola de fondo', (tester) async {
    // Es lo que hace que se cure sin reinstalar nada: el ganadero puede estar
    // en un punto con señal intermitente, y cuando vuelve, la pantalla pasa
    // sola. Antes una sola falla de red dejaba la app trabada para siempre.
    await montar(tester);
    await tester.pump(const Duration(seconds: 21));
    await tester.pump();
    expect(find.text('No pudimos preparar tu cuenta'), findsOneWidget);

    // Deja pasar varios ciclos del reintento lento sin que nada reviente.
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(seconds: 16));
    }

    expect(find.text('No pudimos preparar tu cuenta'), findsOneWidget);
    expect(cerrarSesion, findsOneWidget);
  });

  testWidgets('reintentar vuelve a poner a trabajar la pantalla', (
    tester,
  ) async {
    await montar(tester);
    await tester.pump(const Duration(seconds: 21));
    await tester.pump();
    expect(reintentar, findsOneWidget);

    await tester.tap(reintentar);
    await tester.pump();

    expect(find.text('Preparando tu cuenta…'), findsOneWidget);
    expect(reintentar, findsNothing);

    // Y se vuelve a rendir si tampoco llega esta vez.
    await tester.pump(const Duration(seconds: 21));
    await tester.pump();
    expect(reintentar, findsOneWidget);
  });

  testWidgets('sin conexión no espera nada: se sigue de largo', (tester) async {
    // La app es offline-first. Al que está en el corral sin señal no se le
    // pide internet: pasa al gate de lechería con lo que tenga guardado.
    await tester.pumpWidget(
      MaterialApp(
        theme: LecheTheme.light,
        home: const CuentaGate(usuarioId: 'user-sin-cuenta', sinConexion: true),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Preparando tu cuenta…'), findsNothing);
  });
}
