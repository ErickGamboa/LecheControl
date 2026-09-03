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

          final ingresos = semanas.fold<double>(
            0,
            (a, r) => a + r.totalIngresos,
          );
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
              _PrecioPorKiloSeccion(precio: PrecioPorKilo.desde(semanas)),
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

/// El precio que la planta paga por kilo, semana a semana.
///
/// Es el número que más manda en la finca y el único que no se digita: sale de
/// dividir lo que pagaron entre los kilos que recibieron. Sube y baja solo
/// —según cómo venga la leche— y hasta ahora solo se podía ver una semana a la
/// vez, que es como no verlo.
class _PrecioPorKiloSeccion extends StatelessWidget {
  const _PrecioPorKiloSeccion({required this.precio});

  final PrecioPorKilo precio;

  @override
  Widget build(BuildContext context) {
    if (!precio.hayDatos) return const _SinPrecio();

    final textos = Theme.of(context).textTheme;
    final ultima = precio.ultima;
    final cambio = precio.cambio;

    // La escala arranca abajo del precio más bajo, no en cero: entre ₡380 y
    // ₡410 hay una diferencia que decide la semana, y desde cero las barras
    // saldrían todas iguales. El margen deja que la peor semana siga
    // dibujando barra en vez de quedar en cero.
    final margen = (precio.mejor - precio.peor) * 0.35;
    final piso = (precio.peor - (margen > 0 ? margen : precio.peor * 0.1))
        .clamp(0.0, double.infinity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          key: const ValueKey('analisis.precioKilo'),
          child: Padding(
            padding: const EdgeInsets.all(LecheSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PRECIO POR KILO', style: textos.titleSmall),
                const SizedBox(height: LecheSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      colones(ultima.precio),
                      style: textos.headlineSmall?.copyWith(color: kAzulLeche),
                    ),
                    const SizedBox(width: LecheSpacing.sm),
                    if (cambio != null && cambio != 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              cambio > 0
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              size: 14,
                              color: cambio > 0 ? kExito : kPeligro,
                            ),
                            Text(
                              colones(cambio.abs()),
                              style: textos.bodyMedium?.copyWith(
                                color: cambio > 0 ? kExito : kPeligro,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                Text(
                  '${etiquetaSemana(ultima.semana.fechaInicio, ultima.semana.fechaFin)}'
                  ' · ${ultima.kg.toStringAsFixed(0)} kg entregados',
                  style: textos.bodySmall,
                ),
                const Divider(height: LecheSpacing.xl),
                // Alineados arriba: si una etiqueta se parte en dos
                // renglones, las otras dos no tienen por qué bajarse con
                // ella.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Dato(
                      etiqueta: 'Promedio real',
                      valor: colones(precio.promedio),
                    ),
                    _Dato(
                      etiqueta: 'Mejor semana',
                      valor: colones(precio.mejor),
                    ),
                    _Dato(etiqueta: 'Peor semana', valor: colones(precio.peor)),
                  ],
                ),
                const SizedBox(height: LecheSpacing.sm),
                Text(
                  'El promedio pesa cada semana por los kilos que entregó, '
                  'así que es lo que de verdad se cobró por kilo.',
                  style: textos.bodySmall,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: LecheSpacing.md),
        BarrasSemanales(
          key: const ValueKey('analisis.precioKilo.grafico'),
          titulo: 'PRECIO POR KILO, SEMANA A SEMANA',
          nota:
              'La escala arranca en ${colones(piso)} para que se note la '
              'diferencia entre semanas.',
          color: kAzulLeche,
          piso: piso,
          barras: [
            for (final s in precio.semanas.reversed)
              BarraSemanal(
                etiqueta:
                    '${s.semana.fechaInicio.day}/${s.semana.fechaInicio.month}',
                valor: s.precio,
                texto: colones(s.precio),
              ),
          ],
        ),
      ],
    );
  }
}

/// Cuando hay semanas con plata pero nadie anotó los kilos: sin kilos no hay
/// precio que calcular, y decirlo es más útil que dejar el hueco.
class _SinPrecio extends StatelessWidget {
  const _SinPrecio();

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const ValueKey('analisis.precioKilo.sinDatos'),
      child: Padding(
        padding: const EdgeInsets.all(LecheSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PRECIO POR KILO',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: LecheSpacing.sm),
            Text(
              'Todavía no se puede calcular. Al anotar el ingreso de leche en '
              'Finanzas hay que poner también los kilos que recibió la planta: '
              'el precio sale de dividir uno entre otro.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
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
          Text(valor, style: Theme.of(context).textTheme.titleSmall),
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
