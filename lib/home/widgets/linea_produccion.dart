import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/domain/semana.dart';
import '../../data/repositories/pesas_repository.dart';

/// Una semana del gráfico del home.
class PuntoProduccion {
  const PuntoProduccion({
    required this.lunes,
    required this.litros,
    this.enCurso = false,
  });

  final DateTime lunes;

  /// Litros de la pesa de esa semana. **null cuando no hubo pesa**, que no es
  /// lo mismo que cero: la línea se corta en vez de desplomarse.
  final double? litros;

  /// La pesa de esa semana todavía está abierta, así que el número va a
  /// seguir subiendo conforme se pesen las vacas que faltan. Se dibuja hueca
  /// y con el segmento punteado para que una pesa a medias no se lea como una
  /// caída de producción.
  final bool enCurso;

  String get etiqueta => '${lunes.day}/${lunes.month}';
}

/// Reparte las pesas en las últimas [semanas] semanas de calendario.
///
/// Por semana de calendario y no "las últimas cuatro pesas": si faltó una
/// semana, el hueco tiene que verse en el lugar que le toca. Y una pesa sin
/// vacas —la que la app abre sola al entrar a la pantalla de pesa— cuenta
/// como semana sin pesar, no como semana de cero litros; si no, entrar a
/// mirar la pantalla dibujaría un desplome.
List<PuntoProduccion> armarSemanas(
  List<SesionConTotales> sesiones, {
  DateTime? hoy,
  int semanas = 4,
}) {
  final estaSemana = lunesDe(hoy ?? DateTime.now());
  return [
    for (var atras = semanas - 1; atras >= 0; atras--)
      () {
        final lunes = estaSemana.subtract(Duration(days: 7 * atras));
        // Vienen de la más nueva a la más vieja: la primera que caiga en la
        // semana es la que vale.
        for (final s in sesiones) {
          if (s.vacas > 0 && lunesDe(s.sesion.fecha) == lunes) {
            return PuntoProduccion(
              lunes: lunes,
              litros: s.litros,
              enCurso: !s.sesion.cerrada,
            );
          }
        }
        return PuntoProduccion(lunes: lunes, litros: null);
      }(),
  ];
}

/// Litros por semana de las últimas semanas, en puntos unidos por una línea.
///
/// No arranca en cero a propósito. Con cuatro semanas entre 300 y 320 L, un
/// gráfico anclado en cero muestra cuatro alturas idénticas y la variación
/// —que es justo lo que se viene a ver— desaparece. Encuadrar solo el rango
/// usado exagera la pendiente, y por eso al lado va el número: la forma dice
/// para dónde va, el número dice cuánto.
class LineaProduccion extends StatelessWidget {
  const LineaProduccion({
    super.key,
    required this.puntos,
    this.onTap,
  });

  final List<PuntoProduccion> puntos;
  final VoidCallback? onTap;

  /// Última semana con pesa, que es la que se rotula.
  PuntoProduccion? get _ultimo {
    for (final p in puntos.reversed) {
      if (p.litros != null) return p;
    }
    return null;
  }

  /// Diferencia contra la semana con pesa anterior a la última.
  ///
  /// null mientras la pesa siga abierta: comparar una semana a medias contra
  /// una completa siempre da una caída, y esa caída no existe.
  double? get _variacion {
    final conDato = [for (final p in puntos) if (p.litros != null) p];
    if (conDato.length < 2 || conDato.last.enCurso) return null;
    return conDato.last.litros! - conDato[conDato.length - 2].litros!;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ultimo = _ultimo;
    final variacion = _variacion;

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(LecheSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      'PRODUCCIÓN SEMANAL',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  if (ultimo != null)
                    Text(
                      '${ultimo.litros!.toStringAsFixed(0)} L',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: kVerdeLeche,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (variacion != null) ...[
                    const SizedBox(width: LecheSpacing.sm),
                    _Variacion(litros: variacion),
                  ] else if (ultimo != null && ultimo.enCurso) ...[
                    const SizedBox(width: LecheSpacing.sm),
                    Text(
                      'pesando',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: LecheSpacing.md),
              SizedBox(
                height: 78,
                child: ultimo == null
                    ? Center(
                        child: Text(
                          'Cuando peses la primera vaca, acá se ve la '
                          'producción de cada semana.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      )
                    : CustomPaint(
                        size: Size.infinite,
                        painter: _PinturaLinea(
                          puntos: puntos,
                          color: kVerdeLeche,
                          // El punto de la pesa en curso va hueco: se pinta
                          // el fondo de la tarjeta adentro del círculo.
                          fondo: theme.cardTheme.color ?? theme.colorScheme.surface,
                        ),
                      ),
              ),
              const SizedBox(height: LecheSpacing.sm),
              Row(
                children: [
                  for (final p in puntos)
                    Expanded(
                      child: Text(
                        p.etiqueta,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cuánto subió o bajó contra la semana anterior.
class _Variacion extends StatelessWidget {
  const _Variacion({required this.litros});

  final double litros;

  @override
  Widget build(BuildContext context) {
    // Media docena de litros en todo el hato es ruido de la ordeña, no una
    // tendencia. Mismo criterio que en Análisis.
    final estable = litros.abs() < 5;
    final subio = litros > 0;
    final color = estable
        ? Theme.of(context).colorScheme.outline
        : (subio ? kExito : kPeligro);

    return Text(
      estable
          ? 'estable'
          : '${subio ? '+' : ''}${litros.toStringAsFixed(0)} L',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
    );
  }
}

class _PinturaLinea extends CustomPainter {
  const _PinturaLinea({
    required this.puntos,
    required this.color,
    required this.fondo,
  });

  final List<PuntoProduccion> puntos;
  final Color color;
  final Color fondo;

  static const double _radio = 3.5;
  static const double _radioUltimo = 5.5;

  @override
  void paint(Canvas canvas, Size size) {
    if (puntos.isEmpty) return;
    final valores = [
      for (final p in puntos)
        if (p.litros != null) p.litros!,
    ];
    if (valores.isEmpty) return;

    final columna = size.width / puntos.length;
    // El margen deja entrar el punto más gordo sin que se coma el borde.
    const margen = _radioUltimo + 2;
    final arriba = margen;
    final abajo = size.height - margen;

    final minimo = valores.reduce(math.min);
    final maximo = valores.reduce(math.max);

    double x(int i) => columna * (i + 0.5);
    double y(double valor) {
      // Con un solo punto —o con todas las semanas iguales— no hay rango que
      // repartir: va a media altura en vez de dividir entre cero.
      if (maximo - minimo < 0.01) return (arriba + abajo) / 2;
      return abajo - (valor - minimo) / (maximo - minimo) * (abajo - arriba);
    }

    final trazo = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i + 1 < puntos.length; i++) {
      final desde = puntos[i];
      final hasta = puntos[i + 1];
      // Semana sin pesa: la línea se corta. Unir por encima del hueco diría
      // que hubo continuidad donde no la hubo.
      if (desde.litros == null || hasta.litros == null) continue;
      final a = Offset(x(i), y(desde.litros!));
      final b = Offset(x(i + 1), y(hasta.litros!));
      if (hasta.enCurso) {
        _punteado(canvas, a, b, trazo);
      } else {
        canvas.drawLine(a, b, trazo);
      }
    }

    var ultimoConDato = -1;
    for (var i = 0; i < puntos.length; i++) {
      if (puntos[i].litros != null) ultimoConDato = i;
    }

    for (var i = 0; i < puntos.length; i++) {
      final p = puntos[i];
      if (p.litros == null) continue;
      final centro = Offset(x(i), y(p.litros!));
      final radio = i == ultimoConDato ? _radioUltimo : _radio;
      if (p.enCurso) {
        canvas
          ..drawCircle(centro, radio, Paint()..color = fondo)
          ..drawCircle(
            centro,
            radio,
            Paint()
              ..color = color
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.5,
          );
      } else {
        canvas.drawCircle(centro, radio, Paint()..color = color);
      }
    }
  }

  void _punteado(Canvas canvas, Offset a, Offset b, Paint pincel) {
    const guion = 5.0;
    const hueco = 4.0;
    final largo = (b - a).distance;
    if (largo == 0) return;
    final direccion = (b - a) / largo;
    var recorrido = 0.0;
    while (recorrido < largo) {
      final fin = math.min(recorrido + guion, largo);
      canvas.drawLine(a + direccion * recorrido, a + direccion * fin, pincel);
      recorrido = fin + hueco;
    }
  }

  @override
  bool shouldRepaint(_PinturaLinea anterior) {
    if (anterior.color != color || anterior.fondo != fondo) return true;
    if (anterior.puntos.length != puntos.length) return true;
    for (var i = 0; i < puntos.length; i++) {
      final a = anterior.puntos[i];
      final b = puntos[i];
      if (a.litros != b.litros || a.enCurso != b.enCurso || a.lunes != b.lunes) {
        return true;
      }
    }
    return false;
  }
}
