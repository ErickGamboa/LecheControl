// Los dos menús que reparten el trabajo de la leche: Registro (dónde se
// anota) y Análisis (dónde se mira). Si una opción desaparece, el ganadero no
// tiene otro camino para llegar a esa pantalla.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leche_control/analisis/analisis_screen.dart';
import 'package:leche_control/app/theme.dart';
import 'package:leche_control/pesa/registro_leche_screen.dart';

void main() {
  Future<void> montar(WidgetTester tester, Widget pantalla) async {
    await tester.pumpWidget(
      MaterialApp(theme: LecheTheme.light, home: pantalla),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('Registro de leche ofrece pesa y calidad', (tester) async {
    await montar(
      tester,
      const RegistroLecheScreen(
        lecheriaId: 'lecheria-1',
        nombreLecheria: 'LecheriaErick',
      ),
    );

    expect(find.text('Registro de leche'), findsOneWidget);
    expect(find.byKey(const ValueKey('registro.pesa')), findsOneWidget);
    expect(find.byKey(const ValueKey('registro.calidad')), findsOneWidget);
  });

  testWidgets('Análisis ofrece las cuatro miradas', (tester) async {
    await montar(
      tester,
      const AnalisisScreen(
        lecheriaId: 'lecheria-1',
        nombreLecheria: 'LecheriaErick',
      ),
    );

    for (final clave in [
      'analisis.leche',
      'analisis.calidad',
      'analisis.finanzas',
      'analisis.dieta',
    ]) {
      expect(
        find.byKey(ValueKey(clave)),
        findsOneWidget,
        reason: 'falta la opción $clave',
      );
    }
  });
}
