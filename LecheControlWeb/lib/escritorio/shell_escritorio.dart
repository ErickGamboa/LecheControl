import 'package:flutter/material.dart';
import 'package:leche_control/data/local/database.dart';

import 'barra_lateral.dart';
import 'barra_superior.dart';
import 'modulos_escritorio.dart';
import 'panel_modulo.dart';

/// El marco de escritorio: barra lateral fija a la izquierda, barra superior
/// arriba y el módulo abierto en el centro.
///
/// Sustituye a `HomeScreen` sólo por encima del corte de ancho (ver
/// `adaptador_leche.dart`), y sólo al home: todo lo de antes —login, cuenta
/// suspendida, suscripción, crear lechería— sigue siendo el del paquete móvil.
///
/// Lo que va adentro del panel central son **las mismas pantallas del
/// teléfono**, sin adaptar. La distribución cambia; el producto, no.
class ShellEscritorio extends StatefulWidget {
  const ShellEscritorio({
    super.key,
    required this.lecheria,
    required this.usuarioId,
  });

  final LecheriaRow lecheria;
  final String usuarioId;

  @override
  State<ShellEscritorio> createState() => _ShellEscritorioState();
}

class _ShellEscritorioState extends State<ShellEscritorio> {
  int _indice = 0;

  /// Un `Navigator` por sección, con su llave, para que cada una recuerde en
  /// qué pantalla iba.
  late final List<GlobalKey<NavigatorState>> _llaves = [
    for (final modulo in panelesEscritorio)
      GlobalKey<NavigatorState>(debugLabel: 'nav.${modulo.clave}'),
  ];

  /// Qué secciones ya se abrieron alguna vez.
  ///
  /// El `IndexedStack` construye todos sus hijos, y cada pantalla abre streams
  /// contra la base local en cuanto se monta: montar los ocho paneles al
  /// entrar sería pagar ocho suscripciones para mirar una. Así se monta cada
  /// panel la primera vez que se visita y desde ahí queda vivo, que es lo que
  /// le conserva el estado.
  final Set<int> _visitados = {0};

  void _seleccionar(int indice) {
    if (indice == _indice) {
      // Segundo clic en la sección donde ya estoy: vuelve a la raíz de esa
      // sección. Es lo que hace cualquier menú de escritorio y evita quedar
      // atrapado en una pantalla hija sin ver el botón de volver.
      _llaves[indice].currentState?.popUntil((ruta) => ruta.isFirst);
      return;
    }
    setState(() {
      _indice = indice;
      _visitados.add(indice);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BarraLateral(indiceActivo: _indice, onSeleccionar: _seleccionar),
          Expanded(
            child: Column(
              children: [
                BarraSuperior(
                  nombreLecheria: widget.lecheria.nombre,
                  tituloModulo: panelesEscritorio[_indice].titulo,
                ),
                Expanded(
                  child: IndexedStack(
                    index: _indice,
                    // `sizing: expand` para que los paneles escondidos tengan
                    // el mismo tamaño que el visible: si no, al cambiar de
                    // sección la pantalla se arma con otro ancho y las listas
                    // saltan.
                    sizing: StackFit.expand,
                    children: [
                      for (var i = 0; i < panelesEscritorio.length; i++)
                        if (_visitados.contains(i))
                          PanelModulo(
                            modulo: panelesEscritorio[i],
                            lecheria: widget.lecheria,
                            usuarioId: widget.usuarioId,
                            navigatorKey: _llaves[i],
                          )
                        else
                          const SizedBox.shrink(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
