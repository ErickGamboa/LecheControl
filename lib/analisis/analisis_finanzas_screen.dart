import 'package:flutter/material.dart';

import '../app/formato.dart';
import '../app/theme.dart';
import '../data/domain/semana.dart';
import '../data/repositories/finanzas_repository.dart';
import '../services.dart';
import 'widgets/barras_semanales.dart';

/// Análisis de finanzas: ingresos, gastos y utilidad de todas las semanas.
///
/// La pantalla de Finanzas muestra una semana a la vez, que es lo que sirve
/// para anotar. Para saber si la finca está ganando plata hay que verlas
/// todas juntas, y eso es lo que hace esta.
class AnalisisFinanzasScreen extends StatefulWidget {
  const AnalisisFinanzasScreen({super.key, required this.lecheriaId});

  final String lecheriaId;

  @override
  State<AnalisisFinanzasScreen> createState() => _AnalisisFinanzasScreenState();
}

class _AnalisisFinanzasScreenState extends State<AnalisisFinanzasScreen> {
  late Future<List<ResumenSemana>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = finanzasRepo.resumenesDe(widget.lecheriaId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Análisis de finanzas')),
      body: FutureBuilder<List<ResumenSemana>>(
        future: _futuro,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          // Una semana que la app abrió sola pero donde nunca se anotó nada
          // no es una semana de trabajo: contarla hundiría los promedios.
          final semanas = (snap.data ?? const <ResumenSemana>[])
              .where((r) => r.ingresos.isNotEmpty || r.gastos.isNotEmpty)
              .toList();

          if (semanas.isEmpty) return const _SinSemanas();

          final ingresos = semanas.fold<double>(0, (a, r) => a + r.totalIngresos);
          final gastos = semanas.fold<double>(0, (a, r) => a + r.totalGastos);
          final cronologicas = semanas.reversed.toList();

          return ListView(
            padding: const EdgeInsets.all(LecheSpacing.lg),
            children: [
              _Acumulado(
                semanas: semanas.length,
                ingresos: ingresos,
                gastos: gastos,
              ),
              const SizedBox(height: LecheSpacing.lg),
              BarrasSemanales(
                titulo: 'UTILIDAD POR SEMANA',
                color: kExito,
                colorNegativo: kPeligro,
                barras: [
                  for (final r in cronologicas)
                    BarraSemanal(
                      etiqueta:
                          '${r.semana.fechaInicio.day}/'
                          '${r.semana.fechaInicio.month}',
                      valor: r.utilidad,
                      texto: colones(r.utilidad),
                    ),
                ],
              ),
              const SizedBox(height: LecheSpacing.lg),
              Text(
                'SEMANA POR SEMANA',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: LecheSpacing.sm),
              for (final r in semanas) _FilaSemana(resumen: r),
              const SizedBox(height: LecheSpacing.xl),
            ],
          );
        },
      ),
    );
  }
}

class _Acumulado extends StatelessWidget {
  const _Acumulado({
    required this.semanas,
    required this.ingresos,
    required this.gastos,
  });

  final int semanas;
  final double ingresos;
  final double gastos;

  @override
  Widget build(BuildContext context) {
    final utilidad = ingresos - gastos;
    final gana = utilidad >= 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(LecheSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ACUMULADO DE $semanas SEMANA${semanas == 1 ? '' : 'S'}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: LecheSpacing.md),
            Text(
              colones(utilidad),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: gana ? kExito : kPeligro,
              ),
            ),
            Text(
              gana ? 'de utilidad' : 'de pérdida',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: LecheSpacing.md),
            Row(
              children: [
                _Dato(etiqueta: 'Ingresos', valor: colones(ingresos)),
                _Dato(etiqueta: 'Gastos', valor: colones(gastos)),
                _Dato(
                  etiqueta: 'Promedio semanal',
                  valor: colones(utilidad / semanas),
                ),
              ],
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
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 2),
          Text(etiqueta, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _FilaSemana extends StatelessWidget {
  const _FilaSemana({required this.resumen});

  final ResumenSemana resumen;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final utilidad = resumen.utilidad;
    final gana = utilidad >= 0;
    final precio = resumen.precioRealPorLitro;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(LecheSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    etiquetaSemana(
                      resumen.semana.fechaInicio,
                      resumen.semana.fechaFin,
                    ),
                    style: textos.titleSmall,
                  ),
                ),
                Text(
                  colones(utilidad),
                  style: textos.titleMedium?.copyWith(
                    color: gana ? kExito : kPeligro,
                  ),
                ),
              ],
            ),
            const SizedBox(height: LecheSpacing.sm),
            Text(
              'Ingresos ${colones(resumen.totalIngresos)} · '
              'Gastos ${colones(resumen.totalGastos)}',
              style: textos.bodySmall,
            ),
            if (precio != null) ...[
              const SizedBox(height: 2),
              Text(
                '${resumen.litrosLeche.toStringAsFixed(0)} kg entregados a '
                '${colones(precio)}/kg',
                style: textos.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SinSemanas extends StatelessWidget {
  const _SinSemanas();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.savings_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: LecheSpacing.lg),
            Text(
              'Todavía no hay semanas con movimientos',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: LecheSpacing.sm),
            Text(
              'Anotá ingresos o gastos en Finanzas y las semanas van a '
              'aparecer acá.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
