// El acuse de recibo de los eventos de Trabajo. Se anota de pie junto a la
// vaca, así que el ganadero tiene que saber sin leer si quedó o no: check
// verde o equis roja, grande y en el centro.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leche_control/app/theme.dart';
import 'package:leche_control/app/widgets/aviso_rapido.dart';

void main() {
  final exito = find.byKey(const ValueKey('avisoRapido.exito'));
  final fallo = find.byKey(const ValueKey('avisoRapido.fallo'));

  /// Monta una pantalla con un botón que dispara el aviso.
  Future<void> montar(
    WidgetTester tester, {
    required void Function(BuildContext) alTocar,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: LecheTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => alTocar(context),
                child: const Text('anotar'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> disparar(WidgetTester tester) async {
    await tester.tap(find.text('anotar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  testWidgets('el éxito muestra el check con lo que quedó anotado', (
    tester,
  ) async {
    await montar(
      tester,
      alTocar: (c) => AvisoRapido.exito(c, 'Anotado: Parto'),
    );
    await disparar(tester);

    expect(exito, findsOneWidget);
    expect(fallo, findsNothing);
    expect(find.text('Anotado: Parto'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('el fallo muestra la equis y dice qué hacer', (tester) async {
    await montar(
      tester,
      alTocar: (c) => AvisoRapido.fallo(c, 'No quedó anotado. Volvé a intentar.'),
    );
    await disparar(tester);

    expect(fallo, findsOneWidget);
    expect(exito, findsNothing);
    expect(find.byIcon(Icons.cancel), findsOneWidget);
    expect(find.text('No quedó anotado. Volvé a intentar.'), findsOneWidget);
  });

  testWidgets('el check se va solo', (tester) async {
    await montar(tester, alTocar: (c) => AvisoRapido.exito(c, 'Anotado'));
    await disparar(tester);
    expect(exito, findsOneWidget);

    await tester.pump(AvisoRapido.duracionExito);
    await tester.pumpAndSettle();

    expect(exito, findsNothing);
  });

  testWidgets('la equis se queda más que el check: hay que alcanzar a leerla', (
    tester,
  ) async {
    expect(
      AvisoRapido.duracionFallo,
      greaterThan(AvisoRapido.duracionExito),
    );

    await montar(tester, alTocar: (c) => AvisoRapido.fallo(c, 'No quedó'));
    await disparar(tester);

    // Cuando el check ya se habría ido, la equis todavía está.
    await tester.pump(AvisoRapido.duracionExito);
    expect(fallo, findsOneWidget);

    await tester.pump(AvisoRapido.duracionFallo);
    await tester.pumpAndSettle();
    expect(fallo, findsNothing);
  });

  testWidgets('no tapa el paso: se puede seguir tocando debajo', (
    tester,
  ) async {
    // El aviso no es una pregunta: el evento siguiente se tiene que poder
    // empezar a anotar sin esperar a que el check se vaya.
    var toques = 0;
    await montar(
      tester,
      alTocar: (c) {
        toques++;
        AvisoRapido.exito(c, 'Anotado');
      },
    );

    await disparar(tester);
    expect(exito, findsOneWidget);

    // El botón está en el centro, justo debajo del aviso.
    await tester.tap(find.text('anotar'), warnIfMissed: false);
    await tester.pump();

    expect(toques, 2, reason: 'el aviso se comió el toque de abajo');
  });

  testWidgets('anotar y salirse de la pantalla no revienta', (tester) async {
    // El diálogo del evento ya se cerró cuando el aviso sale, así que el
    // contexto puede estar desmontado.
    late BuildContext capturado;
    await tester.pumpWidget(
      MaterialApp(
        theme: LecheTheme.light,
        home: Builder(
          builder: (context) {
            capturado = context;
            return const Scaffold(body: Text('ficha'));
          },
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(theme: LecheTheme.light, home: const Scaffold()),
    );

    expect(() => AvisoRapido.exito(capturado, 'Anotado'), returnsNormally);
  });
}
