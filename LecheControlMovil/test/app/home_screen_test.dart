// La pantalla principal es la única puerta a los módulos: si una tarjeta
// desaparece o deja de estar centrada, el ganadero no tiene otro camino.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leche_control/app/theme.dart';
import 'package:leche_control/data/local/database.dart';
import 'package:leche_control/home/home_screen.dart';

void main() {
  final lecheria = LecheriaRow(
    id: 'lecheria-1',
    nombre: 'LecheriaErick',
    creadaPor: 'user-1',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    pendiente: false,
  );

  Future<void> montar(WidgetTester tester, {Size? pantalla}) async {
    if (pantalla != null) {
      tester.view.physicalSize = pantalla;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }
    await tester.pumpWidget(
      MaterialApp(
        theme: LecheTheme.light,
        home: HomeScreen(lecheria: lecheria, usuarioId: 'user-1'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('muestra los seis módulos', (tester) async {
    await montar(tester, pantalla: const Size(400, 900));

    for (final clave in [
      'home.trabajo',
      'home.inventario',
      'home.registroLeche',
      'home.finanzas',
      'home.sanidad',
      'home.analisis',
    ]) {
      expect(
        find.byKey(ValueKey(clave)),
        findsOneWidget,
        reason: 'falta la tarjeta $clave',
      );
    }
  });

  testWidgets('muestra el conteo del hato arriba de los módulos', (
    tester,
  ) async {
    await montar(tester, pantalla: const Size(400, 900));

    for (final grupo in ['en_ordeno', 'secas', 'novillas', 'terneros']) {
      expect(
        find.byKey(ValueKey('home.hato.$grupo')),
        findsOneWidget,
        reason: 'falta el contador de $grupo',
      );
    }

    final hato = tester.getRect(find.byKey(const ValueKey('home.hato.secas')));
    final grilla = tester.getRect(find.byType(GridView));
    expect(
      hato.bottom,
      lessThanOrEqualTo(grilla.top),
      reason: 'el conteo va encima de los módulos',
    );
  });

  testWidgets('el conteo, el gráfico y la grilla reparten el alto en huecos '
      'iguales', (tester) async {
    await montar(tester, pantalla: const Size(400, 900));

    final area = tester.getRect(find.byType(SingleChildScrollView));
    final hato = tester.getRect(find.byKey(const ValueKey('home.hato.secas')));
    final grafico = tester.getRect(
      find.byKey(const ValueKey('home.produccion')),
    );
    final grilla = tester.getRect(find.byType(GridView));

    final huecos = [
      hato.top - area.top,
      grafico.top - hato.bottom,
      grilla.top - grafico.bottom,
      area.bottom - grilla.bottom,
    ];

    expect(huecos.first, greaterThan(0), reason: 'nada pegado a la barra');
    for (final hueco in huecos) {
      expect(
        (hueco - huecos.first).abs(),
        lessThan(1),
        reason: 'los cuatro huecos verticales deben medir lo mismo: $huecos',
      );
    }
  });

  testWidgets('el gráfico de producción va entre el conteo y los módulos', (
    tester,
  ) async {
    await montar(tester, pantalla: const Size(400, 900));

    final hato = tester.getRect(find.byKey(const ValueKey('home.hato.secas')));
    final grafico = tester.getRect(
      find.byKey(const ValueKey('home.produccion')),
    );
    final grilla = tester.getRect(find.byType(GridView));

    expect(grafico.top, greaterThanOrEqualTo(hato.bottom));
    expect(grafico.bottom, lessThanOrEqualTo(grilla.top));
  });

  testWidgets('el gráfico se dibuja aunque todavía no haya pesas', (
    tester,
  ) async {
    // "Siempre está pintado": sin datos el marco sigue ahí, con las cuatro
    // semanas rotuladas, en vez de desaparecer y mover todo lo demás.
    await montar(tester, pantalla: const Size(400, 900));

    expect(find.byKey(const ValueKey('home.produccion')), findsOneWidget);
    expect(find.text('PRODUCCIÓN SEMANAL'), findsOneWidget);
  });

  testWidgets('en una pantalla baja se puede bajar en vez de recortar', (
    tester,
  ) async {
    // Con las seis tarjetas no cabiendo, lo que no puede pasar es que el
    // contenido se corte sin forma de alcanzarlo.
    await montar(tester, pantalla: const Size(400, 500));

    expect(tester.takeException(), isNull);
    final scroll = tester.widget<SingleChildScrollView>(
      find.byType(SingleChildScrollView),
    );
    expect(scroll.physics, isNot(isA<NeverScrollableScrollPhysics>()));
  });
}
