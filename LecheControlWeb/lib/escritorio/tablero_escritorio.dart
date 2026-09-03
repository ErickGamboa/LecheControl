import 'package:flutter/material.dart';
import 'package:leche_control/app/theme.dart';
import 'package:leche_control/data/local/database.dart';
import 'package:leche_control/home/widgets/produccion_semanal.dart';
import 'package:leche_control/home/widgets/resumen_hato.dart';

/// El «Inicio» de la computadora: cómo está el hato y para dónde va la leche.
///
/// No es una pantalla nueva ni una regla nueva: son los **mismos dos widgets**
/// que el teléfono pone arriba de su grilla (`ResumenHato` y
/// `ProduccionSemanal`, del paquete móvil), en la misma posición y con los
/// mismos datos. Lo único que cambia es que acá pueden usar el ancho.
///
/// Lo que sí se queda afuera es la grilla de seis tarjetas del teléfono. En el
/// teléfono es el único camino a los módulos; en la computadora ese camino es
/// la barra lateral, que está siempre a la vista. Repetirla obligaba además a
/// angostar el panel a ancho de celular —la grilla tiene dos columnas y
/// proporción fijas—, y con eso el gráfico, que es lo que de verdad gana con
/// un monitor, quedaba del tamaño de un teléfono.
///
/// Tampoco lleva `AppBar`: el nombre de la lechería, dónde estoy y el estado
/// de la sincronización ya están en la barra superior del marco, y Ajustes y
/// Cerrar sesión al pie de la barra lateral. Ponerlos otra vez era decir dos
/// veces lo mismo en dos franjas pegadas.
class TableroEscritorio extends StatelessWidget {
  const TableroEscritorio({super.key, required this.lecheria});

  final LecheriaRow lecheria;

  /// Alto del gráfico acá.
  ///
  /// En el teléfono son 104 px porque abajo van seis tarjetas. Acá abajo no
  /// va nada, así que el gráfico se lleva el espacio: es la única pieza del
  /// tablero que mejora de verdad con una pantalla grande.
  static const double _altoGrafico = 320;

  @override
  Widget build(BuildContext context) {
    // El tope de ancho y el aire a los lados los pone el panel que lo
    // contiene (`PanelModulo`), igual que a todos los demás módulos: así el
    // tablero y las listas de Inventario arrancan en la misma línea.
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: LecheSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ResumenHato(lecheriaId: lecheria.id),
          const SizedBox(height: LecheSpacing.xl),
          ProduccionSemanal(
            lecheriaId: lecheria.id,
            nombreLecheria: lecheria.nombre,
            altoGrafico: _altoGrafico,
          ),
        ],
      ),
    );
  }
}
