// La barra lateral es lo único que este proyecto dibuja y que no existe en el
// teléfono, así que es lo que hay que probar acá. No monta ninguna pantalla
// del producto, así que no toca la base local.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leche_control/app/theme.dart';
import 'package:leche_control_web/escritorio/barra_lateral.dart';
import 'package:leche_control_web/escritorio/modulos_escritorio.dart';

void main() {
  Future<List<int>> montar(
    WidgetTester tester, {
    int indiceActivo = 0,
    Brightness brillo = Brightness.light,
  }) async {
    final seleccionados = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: brillo == Brightness.light ? LecheTheme.light : LecheTheme.dark,
        home: Scaffold(
          body: Row(
            children: [
              BarraLateral(
                indiceActivo: indiceActivo,
                onSeleccionar: seleccionados.add,
              ),
            ],
          ),
        ),
      ),
    );
    return seleccionados;
  }

  testWidgets('se puede llegar a todos los módulos y a Ajustes', (
    tester,
  ) async {
    await montar(tester);

    for (final modulo in panelesEscritorio) {
      expect(
        find.byKey(ValueKey('escritorio.menu.${modulo.clave}')),
        findsOneWidget,
        reason: 'falta ${modulo.clave} en el menú',
      );
    }
  });

  testWidgets('también está cerrar sesión', (tester) async {
    await montar(tester);
    expect(find.byKey(const ValueKey('escritorio.menu.salir')), findsOneWidget);
  });

  testWidgets('tocar un módulo avisa con su índice', (tester) async {
    final seleccionados = await montar(tester);

    await tester.tap(find.byKey(const ValueKey('escritorio.menu.finanzas')));
    expect(seleccionados, [
      panelesEscritorio.indexWhere((m) => m.clave == 'finanzas'),
    ]);

    await tester.tap(find.byKey(const ValueKey('escritorio.menu.ajustes')));
    expect(seleccionados.last, panelesEscritorio.indexOf(moduloAjustes));
  });

  testWidgets('muestra el nombre de la marca', (tester) async {
    await montar(tester);
    expect(find.textContaining('LECHE'), findsOneWidget);
  });

  testWidgets('el logo se dibuja en claro y en oscuro', (tester) async {
    for (final brillo in Brightness.values) {
      await montar(tester, brillo: brillo);
      expect(
        find.byType(Image),
        findsOneWidget,
        reason: 'el logo no aparece en $brillo',
      );
    }
  });
}
