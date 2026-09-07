// LecheControl es siempre clara. No es una preferencia: con el teléfono en
// oscuro, lo que el ganadero digitaba en los campos salía casi del color del
// fondo y no se leía. Un dato que no se ve mientras se escribe es un dato que
// se anota mal, así que esto se prueba.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leche_control/app/theme.dart';
import 'package:leche_control/app_bootstrap.dart';

/// Qué tan distintos son dos colores, del 0 (iguales) al 21 (negro sobre
/// blanco). Es la razón de contraste de la WCAG; 4.5 es el mínimo para texto
/// normal y lo que se digita tiene que pasar eso holgado.
double _contraste(Color a, Color b) {
  final claro = a.computeLuminance() > b.computeLuminance() ? a : b;
  final oscuro = claro == a ? b : a;
  return (claro.computeLuminance() + 0.05) / (oscuro.computeLuminance() + 0.05);
}

void main() {
  test('el tema de la app es claro', () {
    expect(LecheTheme.light.brightness, Brightness.light);
  });

  test('los campos son blancos con letra oscura', () {
    final tema = LecheTheme.light;
    final relleno = tema.inputDecorationTheme.fillColor!;
    final letra = tema.textTheme.bodyLarge!.color!;

    expect(relleno, Colors.white);
    expect(
      _contraste(letra, relleno),
      greaterThan(7),
      reason: 'lo que se digita tiene que leerse de sobra sobre el relleno',
    );
  });

  test('todos los estilos de texto traen su color escrito', () {
    // Sin color propio, un estilo lo hereda de donde caiga: basta un widget
    // que herede de otro lado para que la letra salga clara sobre blanco.
    final textos = LecheTheme.light.textTheme;
    final estilos = <String, TextStyle?>{
      'bodyLarge': textos.bodyLarge,
      'bodyMedium': textos.bodyMedium,
      'bodySmall': textos.bodySmall,
      'titleLarge': textos.titleLarge,
      'titleMedium': textos.titleMedium,
      'titleSmall': textos.titleSmall,
      'headlineSmall': textos.headlineSmall,
      'labelLarge': textos.labelLarge,
    };
    for (final entrada in estilos.entries) {
      expect(
        entrada.value?.color,
        isNotNull,
        reason: '${entrada.key} quedó sin color',
      );
    }
  });

  testWidgets('la app no sigue el modo oscuro del teléfono', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(const LecheControlApp());
    await tester.pump(const Duration(milliseconds: 50));

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.light);
    expect(
      app.darkTheme,
      isNull,
      reason: 'no hay tema oscuro: si alguien lo devuelve, hay que decidirlo',
    );

    // Y lo que de verdad importa: el tema que le llega a las pantallas.
    final contexto = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(contexto).brightness, Brightness.light);
  });

  testWidgets('con el teléfono en oscuro, el campo sigue legible', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(
      MaterialApp(
        theme: LecheTheme.light,
        themeMode: ThemeMode.light,
        home: const Scaffold(
          body: TextField(decoration: InputDecoration(labelText: 'Arete')),
        ),
      ),
    );

    // El color con el que el campo va a pintar lo que se escriba: es lo que
    // hace `EditableText` cuando el `TextField` no trae `style` propio.
    final contexto = tester.element(find.byType(TextField));
    final tema = Theme.of(contexto);
    final letra =
        tema.textTheme.bodyLarge!.color ?? tema.colorScheme.onSurface;

    expect(
      _contraste(letra, tema.inputDecorationTheme.fillColor!),
      greaterThan(7),
    );
  });
}
