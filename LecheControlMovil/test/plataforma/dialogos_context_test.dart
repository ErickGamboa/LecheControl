// Un `showDialog` tiene que cerrarse con el contexto del diálogo, nunca con
// el de la pantalla.
//
// `showDialog` monta el diálogo en el Navigator **raíz**. Si el botón de
// cerrar hace `Navigator.pop(context)` con el contexto de la pantalla, ese pop
// busca el Navigator *más cercano*, que no siempre es el mismo:
//
//   - En el teléfono hay un solo Navigator, así que el más cercano es el raíz
//     y saca el diálogo. Funciona, pero de casualidad.
//   - En la versión de escritorio (LecheControlWeb) cada sección corre en su
//     propio Navigator, así que el más cercano es el de la sección: el pop
//     saca la pantalla del módulo en vez del diálogo, la sección se queda sin
//     rutas y la app muestra la pantalla roja de
//     "Assertion failed: _history.isNotEmpty".
//
// El error no aparece al compilar ni en los tests de las pantallas: solo al
// abrir ese diálogo, en escritorio. Por eso se revisa el código fuente.
//
// El arreglo siempre es el mismo: nombrar el parámetro del builder
// (`builder: (contextoDialogo) => ...`) y cerrar con ese.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Extrae el texto de la llamada que empieza en [inicio], contando paréntesis
/// hasta cerrar. Así se mira solo lo que está dentro de ese `showDialog` y no
/// lo que venga después en el archivo.
String _llamadaCompleta(String fuente, int inicio) {
  final abre = fuente.indexOf('(', inicio);
  if (abre == -1) return '';
  var profundidad = 0;
  for (var i = abre; i < fuente.length; i++) {
    final c = fuente[i];
    if (c == '(') profundidad++;
    if (c == ')') {
      profundidad--;
      if (profundidad == 0) return fuente.substring(abre, i + 1);
    }
  }
  return fuente.substring(abre);
}

void main() {
  test('ningún showDialog se cierra con el contexto de la pantalla', () {
    final archivos = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !f.path.endsWith('.g.dart'))
        .toList();

    expect(
      archivos,
      isNotEmpty,
      reason: 'no se encontró lib/; ¿se corrió el test desde otra carpeta?',
    );

    final culpables = <String>[];

    for (final archivo in archivos) {
      final fuente = archivo.readAsStringSync();
      for (final patron in ['showDialog', 'showGeneralDialog']) {
        var desde = 0;
        while (true) {
          final i = fuente.indexOf(patron, desde);
          if (i == -1) break;
          desde = i + patron.length;

          final llamada = _llamadaCompleta(fuente, i);
          // `builder: (_)` descarta el contexto del diálogo, así que si además
          // adentro hay un `Navigator.pop(context...)`, ese `context` solo
          // puede ser el de la pantalla.
          final descartaContexto = llamada.contains('builder: (_)');
          final cierraConPantalla = RegExp(
            r'Navigator\.pop\(\s*context\s*[,)]',
          ).hasMatch(llamada);

          if (descartaContexto && cierraConPantalla) {
            final linea = '\n'.allMatches(fuente.substring(0, i)).length + 1;
            culpables.add('${archivo.path}:$linea');
          }
        }
      }
    }

    expect(
      culpables,
      isEmpty,
      reason:
          'Estos diálogos se cierran con el contexto de la pantalla y revientan '
          'la versión de escritorio:\n  ${culpables.join('\n  ')}\n\n'
          'Arreglo: nombrar el parámetro del builder '
          '(builder: (contextoDialogo) => ...) y usar '
          'Navigator.pop(contextoDialogo, ...).',
    );
  });
}
