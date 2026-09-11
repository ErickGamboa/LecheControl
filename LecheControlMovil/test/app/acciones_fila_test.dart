// El patrón de corregir y eliminar es uno solo para toda la app: el menú de
// tres puntos con las dos opciones, y un borrado que pregunta diciendo qué se
// va. Si esto se rompe, se rompe en Finanzas, en la pesa y en la hoja de vida
// a la vez.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leche_control/app/theme.dart';
import 'package:leche_control/app/widgets/acciones_fila.dart';

void main() {
  Future<void> montar(WidgetTester tester, Widget hijo) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: LecheTheme.light,
        home: Scaffold(body: Center(child: hijo)),
      ),
    );
  }

  group('MenuFila', () {
    testWidgets('ofrece corregir y eliminar', (tester) async {
      await montar(tester, MenuFila(onEditar: () {}, onEliminar: () {}));

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Corregir'), findsOneWidget);
      expect(find.text('Eliminar'), findsOneWidget);
    });

    testWidgets('cada opción avisa a quien corresponde', (tester) async {
      var corrigio = false;
      var elimino = false;
      await montar(
        tester,
        MenuFila(
          onEditar: () => corrigio = true,
          onEliminar: () => elimino = true,
        ),
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      expect(elimino, isTrue);
      expect(corrigio, isFalse);
    });

    testWidgets('sin eliminar, la opción no aparece', (tester) async {
      await montar(tester, MenuFila(onEditar: () {}));

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Corregir'), findsOneWidget);
      expect(find.text('Eliminar'), findsNothing);
    });

    testWidgets('sin ninguna de las dos no dibuja nada', (tester) async {
      await montar(tester, const MenuFila());

      expect(find.byIcon(Icons.more_vert), findsNothing);
    });

    testWidgets('los textos se pueden cambiar por lista', (tester) async {
      await montar(
        tester,
        MenuFila(
          onEditar: () {},
          onEliminar: () {},
          textoEditar: 'Reabrir para corregir',
          textoEliminar: 'Eliminar la pesa',
        ),
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Reabrir para corregir'), findsOneWidget);
      expect(find.text('Eliminar la pesa'), findsOneWidget);
    });
  });

  group('confirmarEliminar', () {
    /// Monta un botón que abre la pregunta y guarda la respuesta.
    Future<bool?> preguntar(
      WidgetTester tester, {
      required String queSeVa,
      String? advertencia,
      required String queSeToca,
    }) async {
      bool? respuesta;
      await tester.pumpWidget(
        MaterialApp(
          theme: LecheTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  respuesta = await confirmarEliminar(
                    context,
                    titulo: 'Eliminar el gasto',
                    queSeVa: queSeVa,
                    advertencia: advertencia,
                  );
                },
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(queSeToca));
      await tester.pumpAndSettle();
      return respuesta;
    }

    testWidgets('dice qué se va a eliminar, no un «está seguro» pelado', (
      tester,
    ) async {
      await preguntar(
        tester,
        queSeVa: 'Concentrado por ₡12.000.',
        advertencia: 'Esto no se puede deshacer.',
        queSeToca: 'Cancelar',
      );

      // El diálogo ya se cerró; se vuelve a abrir para leerlo.
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(find.text('Concentrado por ₡12.000.'), findsOneWidget);
      expect(find.text('Esto no se puede deshacer.'), findsOneWidget);
    });

    testWidgets('cancelar devuelve que no', (tester) async {
      final respuesta = await preguntar(
        tester,
        queSeVa: 'Concentrado por ₡12.000.',
        queSeToca: 'Cancelar',
      );

      expect(respuesta, isFalse);
    });

    testWidgets('confirmar devuelve que sí', (tester) async {
      final respuesta = await preguntar(
        tester,
        queSeVa: 'Concentrado por ₡12.000.',
        queSeToca: 'Eliminar',
      );

      expect(respuesta, isTrue);
    });
  });
}
