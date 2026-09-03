import 'package:flutter/material.dart';
import 'package:leche_control/data/local/database.dart';
import 'package:leche_control/home/home_screen.dart';

import '../escritorio/shell_escritorio.dart';

/// Dónde deja de ser un teléfono y empieza a ser una computadora.
///
/// 1000 px: por debajo entran teléfonos y tablets en vertical, que reciben la
/// app tal cual; por encima, monitores y portátiles, donde una sola columna
/// centrada se vería como una app de celular estirada.
const double kCorteEscritorio = 1000;

/// Las dos distribuciones posibles.
enum Distribucion {
  /// El árbol del teléfono, tal cual.
  telefono,

  /// Barra lateral, barra superior y el módulo al centro.
  escritorio,
}

/// La regla del corte, aparte del widget que la aplica.
///
/// Está separada para poder probarla sin montar la app: los tests del corte
/// preguntan por el ancho y no por lo que dibuja `HomeScreen`, que ya tiene
/// sus propios tests en el paquete móvil (`test/app/home_screen_test.dart`).
/// Probar acá lo mismo sería la clase de duplicación que este proyecto existe
/// para evitar.
Distribucion distribucionPara(double ancho) =>
    ancho >= kCorteEscritorio ? Distribucion.escritorio : Distribucion.telefono;

/// Elige la distribución según el ancho disponible.
///
/// Se pasa a `AuthGate.construirHome`, así que corre **después** de resolver
/// sesión, cuenta y lechería: el login, la cuenta suspendida, la pantalla de
/// suscripción y el formulario de crear lechería son siempre los del paquete
/// móvil, sin marco, porque ya vienen centrados y limitados en ancho y se ven
/// bien en un monitor.
///
/// Es una función de nivel superior y no un cierre creado al construir: así
/// su identidad no cambia entre reconstrucciones y `AuthGate` no se rearma.
///
/// Debajo del corte devuelve `HomeScreen` **sin envolverlo en nada**. No hay
/// un widget intermedio, ni un padding, ni un tema propio: el navegador del
/// celular renderiza exactamente el mismo árbol que la app instalada. Es lo
/// único que garantiza que las dos versiones móviles se vean idénticas y no
/// apenas parecidas.
Widget construirHomeSegunAncho({
  required LecheriaRow lecheria,
  required String usuarioId,
}) {
  return LayoutBuilder(
    builder: (context, restricciones) {
      return switch (distribucionPara(restricciones.maxWidth)) {
        Distribucion.escritorio => ShellEscritorio(
          lecheria: lecheria,
          usuarioId: usuarioId,
        ),
        Distribucion.telefono => HomeScreen(
          lecheria: lecheria,
          usuarioId: usuarioId,
        ),
      };
    },
  );
}
