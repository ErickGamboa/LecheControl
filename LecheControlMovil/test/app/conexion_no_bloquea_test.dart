// La detección de red es una PISTA, no un permiso.
//
// `connectivity_plus` dice si hay una interfaz de red levantada, no si
// internet responde, y su primera lectura al arrancar puede contestar `none`
// teniendo la red perfecta. `sincronizarSiSePuede` usaba ese valor como
// compuerta: si salía mal, la app no sincronizaba **ni una vez** y se quedaba
// en «Preparando tu cuenta…» hasta reinstalar. Y el reintento tampoco
// ayudaba, porque también moría en la misma compuerta.
//
// Estas pruebas fijan que eso no vuelva.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:leche_control/connectivity/estado_conexion.dart';

void main() {
  test('ante la duda se asume que hay red', () {
    // Arrancar en `false` es lo que dejaba la app inservible cuando la
    // detección se equivocaba: nadie intentaba nada.
    final estado = EstadoConexion();
    addTearDown(estado.dispose);
    expect(estado.hayConexion.value, isTrue);
  });

  test('el repaso periódico existe y es frecuente', () {
    // Es la red que corrige una primera lectura equivocada: los eventos de
    // cambio no llegan nunca si la red no cambia (un WiFi de casa), así que
    // sin repaso el valor se queda mal para siempre.
    expect(EstadoConexion.repasoCada.inSeconds, lessThanOrEqualTo(60));
    expect(EstadoConexion.repasoCada.inSeconds, greaterThan(0));
  });

  test('sincronizar no consulta la detección de red', () async {
    // La prueba de verdad: que el código de `sincronizarSiSePuede` no
    // dependa de `hayConexion`. Se lee el fuente porque lo que se quiere
    // fijar es justamente que esa línea no vuelva a aparecer: llamar a la
    // función pediría una sesión de Supabase, que en un test no existe.
    final fuente = await _leer('lib/services.dart');
    final cuerpo = _cuerpoDe(fuente, 'Future<void> sincronizarSiSePuede()');

    expect(
      cuerpo.contains('hayConexion'),
      isFalse,
      reason:
          'sincronizarSiSePuede volvió a usar la detección de red como '
          'compuerta. Una primera lectura equivocada deja la app sin '
          'sincronizar nunca (ver el comentario de la función).',
    );
    expect(
      cuerpo.contains('currentSession'),
      isTrue,
      reason: 'sin sesión sí hay que salir: no hay a nombre de quién pedir',
    );
  });

  test('la red de seguridad también cubre la primera bajada', () async {
    // `hayPendientes()` mira lo que falta SUBIR. Una instalación nueva no
    // tiene nada pendiente, así que si su primera bajada falla, sin esto la
    // red de seguridad no entra nunca.
    final fuente = await _leer('lib/app_bootstrap.dart');
    expect(fuente.contains('faltaLaPrimeraBajada'), isTrue);
  });
}

Future<String> _leer(String ruta) async {
  // Los tests corren con la raíz del paquete como directorio de trabajo.
  return await File(ruta).readAsString();
}

/// El cuerpo de una función, desde su firma hasta la llave que la cierra.
String _cuerpoDe(String fuente, String firma) {
  final inicio = fuente.indexOf(firma);
  if (inicio < 0) {
    throw StateError('No se encontró «$firma»: ¿le cambiaron el nombre?');
  }
  var profundidad = 0;
  var vioLlave = false;
  for (var i = inicio; i < fuente.length; i++) {
    if (fuente[i] == '{') {
      profundidad++;
      vioLlave = true;
    } else if (fuente[i] == '}') {
      profundidad--;
      if (vioLlave && profundidad == 0) return fuente.substring(inicio, i + 1);
    }
  }
  throw StateError('No se pudo delimitar el cuerpo de «$firma»');
}
