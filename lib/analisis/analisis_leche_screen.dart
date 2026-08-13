import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../data/domain/semana.dart';
import '../data/repositories/pesas_repository.dart';
import '../pesa/reporte_screen.dart';
import '../services.dart';
import 'widgets/barras_semanales.dart';

/// Análisis de leche: todas las pesas, semana por semana.
///
/// Reemplaza al viejo "historial": además de listarlas, compara. Una pesa
/// suelta no dice nada; lo que importa es si la finca viene subiendo o
/// bajando, y eso solo se ve poniendo las semanas una al lado de la otra.
class AnalisisLecheScreen extends StatelessWidget {
  const AnalisisLecheScreen({
    super.key,
    required this.lecheriaId,
    required this.nombreLecheria,
  });

  final String lecheriaId;
  final String nombreLecheria;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Análisis de leche')),
      body: StreamBuilder<List<SesionConTotales>>(
        stream: pesasRepo.observarSesiones(lecheriaId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Una sesión sin vacas es la que la app abre sola al entrar a la
          // pantalla de pesa. Contarla como semana torcería los promedios.
          final pesas = (snap.data ?? const <SesionConTotales>[])
              .where((s) => s.vacas > 0)
              .toList();

          if (pesas.isEmpty) return const _SinPesas();

          final litrosTotales = pesas.fold<double>(0, (a, p) => a + p.litros);
          final promedioSemanal = litrosTotales / pesas.length;
          // Las pesas vienen de la más reciente a la más vieja; el gráfico se
          // lee al revés, del pasado hacia hoy.
          final cronologicas = pesas.reversed.toList();

          return ListView(
            padding: const EdgeInsets.all(LecheSpacing.lg),
            children: [
              _Totales(
                semanas: pesas.length,
                litrosTotales: litrosTotales,
                promedioSemanal: promedioSemanal,
              ),
              const SizedBox(height: LecheSpacing.lg),
              BarrasSemanales(
                titulo: 'LITROS POR SEMANA',
                color: kVerdeLeche,
                barras: [
                  for (final p in cronologicas)
                    BarraSemanal(
                      etiqueta: _etiquetaCorta(p.sesion.fecha),
                      valor: p.litros,
                      texto: '${p.litros.toStringAsFixed(0)} L',
                    ),
                ],
              ),
              const SizedBox(height: LecheSpacing.lg),
              Text(
                'SEMANAS PESADAS',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: LecheSpacing.sm),
              for (var i = 0; i < pesas.length; i++)
                _FilaSemana(
                  datos: pesas[i],
                  // Contra la semana anterior en el tiempo, que por el orden
                  // de la lista es la siguiente posición.
                  anterior: i + 1 < pesas.length ? pesas[i + 1] : null,
                  lecheriaId: lecheriaId,
                  nombreLecheria: nombreLecheria,
                ),
              const SizedBox(height: LecheSpacing.xl),
            ],
          );
        },
      ),
    );
  }
}

String _etiquetaCorta(DateTime fecha) {
  final lunes = lunesDe(fecha);
  return '${lunes.day}/${lunes.month}';
}

class _Totales extends StatelessWidget {
  const _Totales({
    required this.semanas,
    required this.litrosTotales,
    required this.promedioSemanal,
  });

  final int semanas;
  final double litrosTotales;
  final double promedioSemanal;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(LecheSpacing.lg),
        child: Row(
          children: [
            _Dato(
              etiqueta: 'Semanas',
              valor: '$semanas',
            ),
            _Dato(
              etiqueta: 'Litros en total',
              valor: litrosTotales.toStringAsFixed(0),
            ),
            _Dato(
              etiqueta: 'Promedio semanal',
              valor: '${promedioSemanal.toStringAsFixed(0)} L',
            ),
          ],
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            valor,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(etiqueta, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _FilaSemana extends StatelessWidget {
  const _FilaSemana({
    required this.datos,
    required this.anterior,
    required this.lecheriaId,
    required this.nombreLecheria,
  });

  final SesionConTotales datos;
  final SesionConTotales? anterior;
  final String lecheriaId;
  final String nombreLecheria;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final fecha = datos.sesion.fecha;
    final previa = anterior;
    final diferencia = previa == null ? null : datos.litros - previa.litros;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: LecheSpacing.lg,
          vertical: LecheSpacing.sm,
        ),
        leading: CircleAvatar(
          backgroundColor: colores.primaryContainer,
          foregroundColor: colores.onPrimaryContainer,
          child: const Icon(Icons.calendar_month_outlined),
        ),
        title: Text(etiquetaSemana(lunesDe(fecha), domingoDe(fecha))),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${datos.vacas} vacas · ${datos.litros.toStringAsFixed(1)} L · '
            'promedio ${datos.promedio.toStringAsFixed(1)} L',
          ),
        ),
        trailing: diferencia == null
            ? const Icon(Icons.chevron_right)
            : _Variacion(diferencia: diferencia),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReporteScreen(
              lecheriaId: lecheriaId,
              sesionId: datos.sesion.id,
              nombreLecheria: nombreLecheria,
            ),
          ),
        ),
      ),
    );
  }
}

/// Cuánto subió o bajó contra la semana anterior.
class _Variacion extends StatelessWidget {
  const _Variacion({required this.diferencia});

  final double diferencia;

  @override
  Widget build(BuildContext context) {
    // Media docena de litros arriba o abajo en todo el hato es ruido de la
    // ordeña, no una tendencia: se marca como estable.
    final estable = diferencia.abs() < 5;
    final subio = diferencia > 0;
    final color = estable
        ? Theme.of(context).colorScheme.outline
        : (subio ? kExito : kPeligro);

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          estable
              ? Icons.remove
              : (subio ? Icons.arrow_upward : Icons.arrow_downward),
          size: 16,
          color: color,
        ),
        Text(
          '${subio ? '+' : ''}${diferencia.toStringAsFixed(0)} L',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

class _SinPesas extends StatelessWidget {
  const _SinPesas();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.water_drop_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: LecheSpacing.lg),
            Text(
              'Todavía no hay pesas guardadas',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: LecheSpacing.sm),
            Text(
              'Cuando peses la primera vaca, la semana va a aparecer acá.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
