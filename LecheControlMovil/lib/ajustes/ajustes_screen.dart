import 'package:flutter/material.dart';

import 'curva_screen.dart';
import 'dieta_screen.dart';
import 'tope_kg_screen.dart';

/// Menú de ajustes de métricas de la lechería.
///
/// Antes el botón de la barra del home entraba directo a la curva de
/// referencia. Ahora hay más de una cosa que calibrar, así que primero se
/// elige qué: de acá salen la curva, el tope de kilos y la dieta.
class AjustesScreen extends StatelessWidget {
  const AjustesScreen({super.key, required this.lecheriaId});

  final String lecheriaId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajuste de métricas')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            _Opcion(
              clave: 'ajustes.curva',
              icono: Icons.show_chart,
              titulo: 'Ajuste de curva de referencia',
              detalle:
                  'Cuántos litros se esperan de una vaca según los días que '
                  'lleva de parida. Es con lo que el reporte califica a cada '
                  'una.',
              destino: CurvaScreen(lecheriaId: lecheriaId),
            ),
            _Opcion(
              clave: 'ajustes.topeKg',
              icono: Icons.local_shipping_outlined,
              titulo: 'Ajuste de tope de kg entregados',
              detalle:
                  'Cuántos kilos de leche puede entregar la finca por semana. '
                  'Si se pasa, la app avisa al anotar el ingreso.',
              destino: TopeKgScreen(lecheriaId: lecheriaId),
            ),
            _Opcion(
              clave: 'ajustes.dieta',
              icono: Icons.grass_outlined,
              titulo: 'Ajuste de dieta de concentrado',
              detalle:
                  'Cuántos kilos de leche pagan un kilo de concentrado. Es '
                  'con lo que se saca la ración de cada vaca.',
              destino: DietaScreen(lecheriaId: lecheriaId),
            ),
          ],
        ),
      ),
    );
  }
}

class _Opcion extends StatelessWidget {
  const _Opcion({
    required this.clave,
    required this.icono,
    required this.titulo,
    required this.detalle,
    required this.destino,
  });

  final String clave;
  final IconData icono;
  final String titulo;
  final String detalle;
  final Widget destino;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: ValueKey(clave),
      leading: Icon(icono),
      title: Text(titulo),
      subtitle: Text(detalle),
      trailing: const Icon(Icons.chevron_right),
      isThreeLine: true,
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => destino)),
    );
  }
}
