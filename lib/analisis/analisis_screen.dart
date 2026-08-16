import 'package:flutter/material.dart';

import '../app/theme.dart';
import 'analisis_finanzas_screen.dart';
import 'analisis_leche_screen.dart';

/// Análisis (Módulo 6): mirar la finca **a lo largo del tiempo**, no la
/// semana de hoy.
///
/// El resto de la app trabaja siempre sobre la semana en curso —se pesa esta
/// semana, se anotan los gastos de esta semana—. Acá se abren todas: cómo
/// viene la leche semana a semana y cómo vienen las utilidades. Son dos
/// preguntas distintas, así que se elige cuál antes de entrar.
class AnalisisScreen extends StatelessWidget {
  const AnalisisScreen({
    super.key,
    required this.lecheriaId,
    required this.nombreLecheria,
  });

  final String lecheriaId;
  final String nombreLecheria;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Análisis')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(LecheSpacing.lg),
          children: [
            Text(
              '¿Qué querés analizar?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: LecheSpacing.md),
            _OpcionAnalisis(
              valueKey: 'analisis.leche',
              icono: Icons.water_drop_outlined,
              color: kVerdeLeche,
              titulo: 'Leche',
              detalle:
                  'Todas las pesas, semana por semana: litros, vacas y '
                  'promedio. Desde acá se abre el reporte de cualquiera.',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AnalisisLecheScreen(
                    lecheriaId: lecheriaId,
                    nombreLecheria: nombreLecheria,
                  ),
                ),
              ),
            ),
            const SizedBox(height: LecheSpacing.md),
            _OpcionAnalisis(
              valueKey: 'analisis.finanzas',
              icono: Icons.savings_outlined,
              color: kAzulLeche,
              titulo: 'Finanzas',
              detalle:
                  'Ingresos, gastos y utilidad de todas las semanas, con el '
                  'acumulado y el precio real por kilo.',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      AnalisisFinanzasScreen(lecheriaId: lecheriaId),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpcionAnalisis extends StatelessWidget {
  const _OpcionAnalisis({
    required this.valueKey,
    required this.icono,
    required this.color,
    required this.titulo,
    required this.detalle,
    required this.onTap,
  });

  final String valueKey;
  final IconData icono;
  final Color color;
  final String titulo;
  final String detalle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    return Card(
      key: ValueKey(valueKey),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(LecheSpacing.lg),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(LecheSpacing.md),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: oscuro ? 0.20 : 0.10),
                  borderRadius: BorderRadius.circular(LecheRadius.md),
                ),
                child: Icon(icono, size: 28, color: color),
              ),
              const SizedBox(width: LecheSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(detalle, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
