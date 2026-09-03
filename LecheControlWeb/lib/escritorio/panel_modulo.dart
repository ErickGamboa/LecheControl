import 'package:flutter/material.dart';
import 'package:leche_control/app/theme.dart';
import 'package:leche_control/data/local/database.dart';

import 'modulos_escritorio.dart';

/// Ancho máximo del contenido de un módulo.
///
/// Las pantallas son las del teléfono: listas, formularios y tarjetas de una
/// sola columna. Estiradas a lo ancho de un monitor quedan como renglones de
/// punta a punta —el identificador de la vaca a la izquierda y el menú de tres
/// puntos a medio metro, a la derecha— y hay que barrer la pantalla con la
/// vista para leer una fila.
const double kAnchoMaximoContenido = 1120;

/// Aire a los lados del módulo.
///
/// Va además del tope de ancho, no en su lugar: en un monitor grande manda el
/// tope y sobra margen, pero en un portátil de 1280 el contenido llega al tope
/// y sin este margen quedaría pegado a la barra lateral y al borde derecho.
const double kMargenLateralPanel = LecheSpacing.xl;

/// El módulo abierto, con su propio `Navigator`.
///
/// Es lo que hace que el menú no se tape. Las pantallas del teléfono navegan
/// con `Navigator.of(context).push(...)`, que sube al `Navigator` más cercano:
/// si no hubiera uno acá adentro, encontraría el de la app y la hoja de vida
/// de una vaca se abriría encima de todo, barra lateral incluida. Con un
/// `Navigator` por sección, el `push` se queda dentro del panel, el marco
/// sigue en pantalla y la pantalla hija trae su propio botón de volver.
///
/// Además cada sección recuerda dónde iba: se puede dejar Inventario abierto
/// en la hoja de vida de una vaca, irse a Finanzas y volver a Inventario a esa
/// misma hoja de vida, como en cualquier programa de escritorio.
///
/// Las hojas modales (`showModalBottomSheet`) también se quedan dentro del
/// panel, porque su valor por omisión es el `Navigator` más cercano. Los
/// diálogos (`showDialog`) sí usan el de la app y se centran en la ventana
/// completa, que es lo correcto para una confirmación.
class PanelModulo extends StatelessWidget {
  const PanelModulo({
    super.key,
    required this.modulo,
    required this.lecheria,
    required this.usuarioId,
    required this.navigatorKey,
  });

  final ModuloEscritorio modulo;
  final LecheriaRow lecheria;
  final String usuarioId;
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context) {
    final navegador = Navigator(
      key: navigatorKey,
      onGenerateRoute: (ajustes) => MaterialPageRoute(
        settings: ajustes,
        builder: (_) => modulo.construir(lecheria, usuarioId),
      ),
    );

    // El tope y el margen van por fuera del `Navigator`, no adentro, para que
    // también los respeten las pantallas hijas: si no, se entraría a un módulo
    // con su aire y la pantalla siguiente saltaría de punta a punta.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kMargenLateralPanel),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kAnchoMaximoContenido),
          // Esquinas de arriba redondeadas: como los módulos traen su propia
          // `AppBar` oscura y ahora no llega a los bordes, sin esto la franja
          // queda cortada a escuadra contra la barra superior y se lee como un
          // desalineo. Redondeada se lee como lo que es: el módulo apoyado
          // sobre el marco. Abajo no hace falta, porque el fondo de la
          // pantalla y el del panel son el mismo crema y no hay borde que
          // cortar.
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(LecheRadius.md),
            ),
            child: navegador,
          ),
        ),
      ),
    );
  }
}
