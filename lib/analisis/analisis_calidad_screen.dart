import 'package:flutter/material.dart';

import '../app/formato.dart';
import '../app/theme.dart';
import '../data/domain/calidad_leche.dart';
import '../data/domain/semana.dart';
import '../data/repositories/calidad_repository.dart';
import '../pesa/widgets/guia_calidad_leche.dart';
import '../services.dart';
import 'widgets/barras_semanales.dart';

/// Los tres análisis que manda la planta, cada uno con cómo se lee y cómo se
/// dibuja. Tenerlos en una lista es lo que evita escribir tres veces la misma
/// tarjeta, el mismo gráfico y el mismo renglón.
enum _Analisis {
  solidos(
    titulo: 'Sólidos totales',
    color: kVerdeLeche,
    // Los sólidos son el único de los tres donde **más es mejor**.
    masEsMejor: true,
  ),
  somaticas(titulo: 'Células somáticas', color: kAzulLeche, masEsMejor: false),
  bacterial(titulo: 'Conteo bacterial', color: kAmbarLeche, masEsMejor: false);

  const _Analisis({
    required this.titulo,
    required this.color,
    required this.masEsMejor,
  });

  final String titulo;
  final Color color;
  final bool masEsMejor;

  double? valorDe(CalidadDeSemana s) => switch (this) {
    _Analisis.solidos => s.calidad.solidosTotalesPct,
    _Analisis.somaticas => s.calidad.celulasSomaticas,
    _Analisis.bacterial => s.calidad.conteoBacterial,
  };

  RangoCalidad? escalonDeValor(double? valor) => switch (this) {
    _Analisis.solidos => nivelSolidosTotales(valor),
    _Analisis.somaticas => nivelCelulasSomaticas(valor),
    _Analisis.bacterial => gradoBacterial(valor),
  };

  /// El valor como se escribe en pantalla.
  String texto(double valor) => switch (this) {
    _Analisis.solidos => '${decimales(valor)} %',
    _ => miles(valor.round()),
  };

  /// El valor como cabe encima de una barra: los conteos van en miles, porque
  /// "1.550.000" encima de una barra de 34 píxeles no se lee.
  String textoCorto(double valor) => switch (this) {
    _Analisis.solidos => decimales(valor, cifras: 1),
    _ => '${(valor / 1000).round()}k',
  };

  String get tituloGrafico => switch (this) {
    _Analisis.solidos => 'SÓLIDOS TOTALES (%)',
    _Analisis.somaticas => 'CÉLULAS SOMÁTICAS (MILES/mL)',
    _Analisis.bacterial => 'CONTEO BACTERIAL (MILES UFC/mL)',
  };
}

/// Análisis de calidad de leche: cómo viene la leche que se entrega, semana a
/// semana.
///
/// La pantalla de captura muestra una semana a la vez, que es lo que sirve
/// para anotar lo que llegó de la planta. Lo que no se ve ahí es si la finca
/// va mejorando o empeorando, y eso es lo único que hace esta: poner las
/// semanas una al lado de la otra.
class AnalisisCalidadScreen extends StatefulWidget {
  const AnalisisCalidadScreen({
    super.key,
    required this.lecheriaId,
    required this.nombreLecheria,
  });

  final String lecheriaId;
  final String nombreLecheria;

  @override
  State<AnalisisCalidadScreen> createState() => _AnalisisCalidadScreenState();
}

class _AnalisisCalidadScreenState extends State<AnalisisCalidadScreen> {
  late Future<List<CalidadDeSemana>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = calidadRepo.historial(widget.lecheriaId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calidad de leche')),
      body: FutureBuilder<List<CalidadDeSemana>>(
        future: _futuro,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final semanas = snap.data ?? const <CalidadDeSemana>[];
          if (semanas.isEmpty) return const _SinDatos();

          // `historial` viene de la más reciente a la más vieja; los gráficos
          // se leen al revés, de izquierda a derecha en el tiempo.
          final cronologicas = semanas.reversed.toList();
          final ultima = semanas.first;

          return ListView(
            padding: const EdgeInsets.all(LecheSpacing.lg),
            children: [
              _UltimaSemana(semanas: semanas),
              const SizedBox(height: LecheSpacing.lg),
              for (final analisis in _Analisis.values) ...[
                _GraficoAnalisis(analisis: analisis, semanas: cronologicas),
                const SizedBox(height: LecheSpacing.lg),
              ],
              Text(
                'SEMANA POR SEMANA',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: LecheSpacing.sm),
              for (final s in semanas) _FilaSemana(semana: s),
              const SizedBox(height: LecheSpacing.lg),
              Text(
                'CÓMO SE LEE',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: LecheSpacing.sm),
              // Con la última semana marcada: la tabla no es un cuadro suelto,
              // dice dónde está parada la finca hoy.
              GuiaCalidadLeche(
                resaltarSolidos: ultima.calidad.solidosTotalesPct,
                resaltarSomaticas: ultima.calidad.celulasSomaticas,
                resaltarBacterial: ultima.calidad.conteoBacterial,
              ),
              const SizedBox(height: LecheSpacing.xl),
            ],
          );
        },
      ),
    );
  }
}

/// Cómo vino la última semana medida: los tres análisis, su grado y cuánto
/// cambiaron contra la vez anterior que se midió ese mismo análisis.
class _UltimaSemana extends StatelessWidget {
  const _UltimaSemana({required this.semanas});

  /// De la más reciente a la más vieja.
  final List<CalidadDeSemana> semanas;

  /// El valor de [analisis] en la semana medida **antes** de la última que lo
  /// trae. No es "la semana pasada" a secas: si esa semana no traía ese
  /// análisis, comparar contra ella daría un salto falso.
  double? _anterior(_Analisis analisis) {
    var encontradoUltimo = false;
    for (final s in semanas) {
      final valor = analisis.valorDe(s);
      if (valor == null) continue;
      if (!encontradoUltimo) {
        encontradoUltimo = true;
        continue;
      }
      return valor;
    }
    return null;
  }

  /// La semana más reciente que trae [analisis].
  ({CalidadDeSemana semana, double valor})? _ultimo(_Analisis analisis) {
    for (final s in semanas) {
      final valor = analisis.valorDe(s);
      if (valor != null) return (semana: s, valor: valor);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(LecheSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ÚLTIMA LECTURA', style: textos.titleSmall),
            const SizedBox(height: LecheSpacing.md),
            for (final analisis in _Analisis.values) ...[
              _RenglonUltimo(
                analisis: analisis,
                ultimo: _ultimo(analisis),
                anterior: _anterior(analisis),
              ),
              if (analisis != _Analisis.values.last)
                const Divider(height: LecheSpacing.xl),
            ],
          ],
        ),
      ),
    );
  }
}

class _RenglonUltimo extends StatelessWidget {
  const _RenglonUltimo({
    required this.analisis,
    required this.ultimo,
    required this.anterior,
  });

  final _Analisis analisis;
  final ({CalidadDeSemana semana, double valor})? ultimo;
  final double? anterior;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final dato = ultimo;

    if (dato == null) {
      return Row(
        children: [
          Expanded(child: Text(analisis.titulo, style: textos.titleSmall)),
          Text('Sin anotar', style: textos.bodySmall),
        ],
      );
    }

    final escalon = analisis.escalonDeValor(dato.valor);
    final previo = anterior;
    // Un cambio "bueno" es hacia arriba en sólidos y hacia abajo en los otros
    // dos; se pinta por eso, no por el signo.
    final delta = previo == null ? null : dato.valor - previo;
    final mejora = delta == null
        ? null
        : (analisis.masEsMejor ? delta > 0 : delta < 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(analisis.titulo, style: textos.titleSmall),
                  Text(
                    etiquetaSemana(
                      dato.semana.semana.fechaInicio,
                      dato.semana.semana.fechaFin,
                    ),
                    style: textos.bodySmall,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  analisis.texto(dato.valor),
                  style: textos.titleMedium?.copyWith(
                    color: escalon == null ? null : colorNivel(escalon.nivel),
                  ),
                ),
                if (delta != null && delta != 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        delta > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 12,
                        color: mejora! ? kExito : kPeligro,
                      ),
                      Text(
                        analisis.texto(delta.abs()),
                        style: textos.bodySmall?.copyWith(
                          color: mejora ? kExito : kPeligro,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
        if (escalon != null) ...[
          const SizedBox(height: LecheSpacing.sm),
          EtiquetaEscalon(escalon: escalon),
        ],
      ],
    );
  }
}

class _GraficoAnalisis extends StatelessWidget {
  const _GraficoAnalisis({required this.analisis, required this.semanas});

  final _Analisis analisis;

  /// De la más vieja a la más reciente.
  final List<CalidadDeSemana> semanas;

  @override
  Widget build(BuildContext context) {
    // Solo las semanas que traen este análisis: una semana sin dato dibujada
    // en cero se leería como "cero células somáticas", que es lo contrario de
    // "no se midió".
    final barras = <BarraSemanal>[
      for (final s in semanas)
        if (analisis.valorDe(s) case final valor?)
          BarraSemanal(
            etiqueta:
                '${s.semana.fechaInicio.day}/${s.semana.fechaInicio.month}',
            valor: valor,
            texto: analisis.textoCorto(valor),
            color: switch (analisis.escalonDeValor(valor)) {
              final escalon? => colorNivel(escalon.nivel),
              _ => analisis.color,
            },
          ),
    ];
    if (barras.isEmpty) return const SizedBox.shrink();

    return BarrasSemanales(
      key: ValueKey('analisis.calidad.${analisis.name}'),
      titulo: analisis.tituloGrafico,
      color: analisis.color,
      barras: barras,
    );
  }
}

class _FilaSemana extends StatelessWidget {
  const _FilaSemana({required this.semana});

  final CalidadDeSemana semana;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(LecheSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              etiquetaSemana(semana.semana.fechaInicio, semana.semana.fechaFin),
              style: textos.titleSmall,
            ),
            const SizedBox(height: LecheSpacing.sm),
            for (final analisis in _Analisis.values)
              Padding(
                padding: const EdgeInsets.only(bottom: LecheSpacing.xs),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(analisis.titulo, style: textos.bodySmall),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        switch (analisis.valorDe(semana)) {
                          final valor? => analisis.texto(valor),
                          _ => '—',
                        },
                        style: textos.bodyMedium,
                        textAlign: TextAlign.end,
                      ),
                    ),
                    const SizedBox(width: LecheSpacing.sm),
                    SizedBox(
                      width: 88,
                      child: switch (analisis.escalonDeValor(
                        analisis.valorDe(semana),
                      )) {
                        final escalon? => Align(
                          alignment: Alignment.centerRight,
                          child: EtiquetaEscalon(
                            escalon: escalon,
                            compacta: true,
                          ),
                        ),
                        _ => const SizedBox.shrink(),
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SinDatos extends StatelessWidget {
  const _SinDatos();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.science_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: LecheSpacing.lg),
            Text(
              'Todavía no hay análisis de calidad',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: LecheSpacing.sm),
            Text(
              'Anotá lo que reporta la planta en Registro de leche → Calidad '
              'de leche y las semanas van a aparecer acá.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
