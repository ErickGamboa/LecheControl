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

/// Las marcas del eje vertical para un rango de litros: números redondos que
/// contienen a [minimo] y [maximo].
///
/// Se redondean hacia afuera a propósito. Poner el mínimo y el máximo exactos
/// (p. ej. 293 y 317) obliga a leer dos números raros para entender la
/// escala; con 280, 300 y 320 se lee de un vistazo, y de paso la línea deja
/// de tocar el borde de la tarjeta.
///
/// Con una sola semana —o con todas iguales— no hay rango que marcar y
/// devuelve ese único valor.
List<double> ticksDeEje(double minimo, double maximo) {
  if (maximo - minimo < 0.01) return [maximo];

  final paso = _pasoLindo((maximo - minimo) / 2);
  final desde = (minimo / paso).floorToDouble() * paso;
  final hasta = (maximo / paso).ceilToDouble() * paso;

  final marcas = <double>[];
  // El margen contra el error de coma flotante evita perder la última marca
  // cuando la suma cae un pelo por encima.
  for (var v = desde; v <= hasta + paso / 1000; v += paso) {
    marcas.add(v);
  }
  return marcas;
}

/// El número redondo más cercano a [bruto] de la familia 1-2-5-10.
double _pasoLindo(double bruto) {
  if (bruto <= 0) return 1;
  final magnitud = math
      .pow(10, (math.log(bruto) / math.ln10).floor())
      .toDouble();
  final normalizado = bruto / magnitud;
  final multiplo = normalizado <= 1
      ? 1.0
      : normalizado <= 2
      ? 2.0
      : normalizado <= 5
      ? 5.0
      : 10.0;
  return multiplo * magnitud;
}

/// Litros por semana de las últimas semanas, en puntos unidos por una línea.
///
/// No arranca en cero a propósito. Con cuatro semanas entre 300 y 320 L, un
/// gráfico anclado en cero muestra cuatro alturas idénticas y la variación
/// —que es justo lo que se viene a ver— desaparece. Encuadrar solo el rango
/// usado exagera la pendiente, y por eso al lado va el número: la forma dice
/// para dónde va, el número dice cuánto.
class LineaProduccion extends StatelessWidget {
  const LineaProduccion({super.key, required this.puntos, this.onTap});

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
    final conDato = [
      for (final p in puntos)
        if (p.litros != null) p,
    ];
    if (conDato.length < 2 || conDato.last.enCurso) return null;
    return conDato.last.litros! - conDato[conDato.length - 2].litros!;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ultimo = _ultimo;
    final variacion = _variacion;
    // Mismo gris y mismo tamaño para las fechas de abajo y los litros del
    // eje: son la misma clase de dato, la regla contra la que se lee.
    final estiloEje =
        theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline) ??
        const TextStyle(fontSize: 12);

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
                height: 104,
                child: ultimo == null
                    ? Center(
                        child: Text(
                          'Cuando peses la primera vaca, acá se ve la '
                          'producción de cada semana.',
                          textAlign: TextAlign.center,
                          style: estiloEje,
                        ),
                      )
                    : CustomPaint(
                        size: Size.infinite,
                        painter: _PinturaLinea(
                          puntos: puntos,
                          color: kVerdeLeche,
                          // El punto de la pesa en curso va hueco: se pinta
                          // el fondo de la tarjeta adentro del círculo.
                          fondo:
                              theme.cardTheme.color ??
                              theme.colorScheme.surface,
                          lineaGuia: theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.5),
                          estiloEje: estiloEje,
                        ),
                      ),
              ),
              const SizedBox(height: LecheSpacing.sm),
              Padding(
                // El mismo hueco que el pintor le deja al eje vertical, para
                // que cada fecha caiga debajo de su punto.
                padding: const EdgeInsets.only(left: _PinturaLinea.anchoEje),
                child: Row(
                  children: [
                    for (final p in puntos)
                      Expanded(
                        child: Text(
                          p.etiqueta,
                          textAlign: TextAlign.center,
                          style: estiloEje,
                        ),
                      ),
                  ],
                ),
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
      estable ? 'estable' : '${subio ? '+' : ''}${litros.toStringAsFixed(0)} L',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
    );
  }
}

class _PinturaLinea extends CustomPainter {
  const _PinturaLinea({
    required this.puntos,
    required this.color,
    required this.fondo,
    required this.lineaGuia,
    required this.estiloEje,
  });

  final List<PuntoProduccion> puntos;
  final Color color;
  final Color fondo;
  final Color lineaGuia;
  final TextStyle estiloEje;

  /// Lo que se reserva a la izquierda para los litros del eje. Da para cuatro
  /// cifras, que es lo que produce en una semana un hato grande.
  static const double anchoEje = 40;

  /// Separación entre el número del eje y el inicio del gráfico.
  static const double _respiroEje = 6;

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

    final columna = (size.width - anchoEje) / puntos.length;
    // El margen deja entrar el punto más gordo sin que se coma el borde, y
    // que el número de arriba del eje no quede cortado.
    const margen = _radioUltimo + 4;
    final arriba = margen;
    final abajo = size.height - margen;

    final marcas = ticksDeEje(
      valores.reduce(math.min),
      valores.reduce(math.max),
    );
    final ejeMin = marcas.first;
    final ejeMax = marcas.last;

    double x(int i) => anchoEje + columna * (i + 0.5);
    double y(double valor) {
      // Con un solo punto —o con todas las semanas iguales— no hay rango que
      // repartir: va a media altura en vez de dividir entre cero.
      if (ejeMax - ejeMin < 0.01) return (arriba + abajo) / 2;
      return abajo - (valor - ejeMin) / (ejeMax - ejeMin) * (abajo - arriba);
    }

    _pintarEje(canvas, size, marcas, y);

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

  /// Los litros de cada marca, con su guía tenue cruzando el gráfico.
  void _pintarEje(
    Canvas canvas,
    Size size,
    List<double> marcas,
    double Function(double) y,
  ) {
    final guia = Paint()
      ..color = lineaGuia
      ..strokeWidth = 1;

    for (final marca in marcas) {
      final altura = y(marca);
      canvas.drawLine(
        Offset(anchoEje, altura),
        Offset(size.width, altura),
        guia,
      );

      // Una sola línea siempre: un número partido en dos renglones se lee
      // como dos números distintos.
      final texto = TextPainter(
        text: TextSpan(text: marca.toStringAsFixed(0), style: estiloEje),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: anchoEje - _respiroEje);
      // Pegados a la línea y alineados a la derecha, para que el eje se lea
      // como una columna y no como números sueltos.
      texto.paint(
        canvas,
        Offset(anchoEje - _respiroEje - texto.width, altura - texto.height / 2),
      );
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
    if (anterior.color != color ||
        anterior.fondo != fondo ||
        anterior.lineaGuia != lineaGuia ||
        anterior.estiloEje != estiloEje) {
      return true;
    }
    if (anterior.puntos.length != puntos.length) return true;
    for (var i = 0; i < puntos.length; i++) {
      final a = anterior.puntos[i];
      final b = puntos[i];
      if (a.litros != b.litros ||
          a.enCurso != b.enCurso ||
          a.lunes != b.lunes) {
        return true;
      }
    }
    return false;
  }
}
