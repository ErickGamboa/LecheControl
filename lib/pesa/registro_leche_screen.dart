import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../app/widgets/opcion_menu_card.dart';
import 'calidad_leche_screen.dart';
import 'pesa_screen.dart';

/// Registro de leche (Módulo 3): todo lo que se anota de la leche de la
/// semana, que son dos cosas distintas.
///
/// **Cuánta** leche dio cada vaca —la pesa de siempre, vaca por vaca en el
/// corral— y **cómo viene** esa leche —los análisis que manda la planta de lo
/// que se le entregó—. Se anotan en momentos distintos, por personas distintas
/// y con datos que no se parecen en nada, así que se elige cuál antes de
/// entrar en vez de mezclarlas en una sola pantalla.
class RegistroLecheScreen extends StatelessWidget {
  const RegistroLecheScreen({
    super.key,
    required this.lecheriaId,
    required this.nombreLecheria,
  });

  final String lecheriaId;
  final String nombreLecheria;

  void _abrir(BuildContext context, Widget pantalla) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => pantalla));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro de leche')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(LecheSpacing.lg),
          children: [
            Text(
              '¿Qué querés registrar?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: LecheSpacing.md),
            OpcionMenuCard(
              valueKey: 'registro.pesa',
              icono: Icons.water_drop_outlined,
              color: kVerdeLeche,
              titulo: 'Pesa de leche',
              detalle:
                  'Vaca por vaca: litros de la mañana, de la tarde y kilos '
                  'de concentrado. Al cerrar sale el reporte de producción.',
              onTap: () => _abrir(
                context,
                PesaScreen(
                  lecheriaId: lecheriaId,
                  nombreLecheria: nombreLecheria,
                ),
              ),
            ),
            const SizedBox(height: LecheSpacing.md),
            OpcionMenuCard(
              valueKey: 'registro.calidad',
              icono: Icons.science_outlined,
              color: kAzulLeche,
              titulo: 'Calidad de leche',
              detalle:
                  'Lo que reporta la planta cada semana: sólidos totales, '
                  'células somáticas y conteo bacterial.',
              onTap: () => _abrir(
                context,
                CalidadLecheScreen(
                  lecheriaId: lecheriaId,
                  nombreLecheria: nombreLecheria,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
