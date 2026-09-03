import 'package:flutter/material.dart';

import '../../app/theme.dart';

class BarraSemanal {
  const BarraSemanal({
    required this.etiqueta,
    required this.valor,
    required this.texto,
    this.color,
  });

  /// Qué semana es, corto: "10/8".
  final String etiqueta;

  /// Lo que mide la barra. Puede ser negativo (una semana con pérdida).
  final double valor;

  /// El valor ya formateado, como se muestra encima de la barra.
  final String texto;

  /// Color propio de esta barra, cuando el color dice algo del valor y no de
  /// la serie: en calidad de leche cada semana se pinta del color de su grado,
  /// así que un mes malo se ve rojo sin tener que leer los números.
  ///
  /// null = el color del gráfico.
  final Color? color;
}

/// Gráfico de barras simple, semana a semana.
///
/// Está hecho a mano con `Container`s en vez de traer una librería de
/// gráficos: es una sola barra por semana y así la app no carga una
/// dependencia entera para dibujar rectángulos.
///
/// Se desplaza de lado cuando hay muchas semanas, y la escala arranca en cero
/// —o en el valor más negativo, si hubo semanas con pérdida— para que las
/// alturas se puedan comparar entre sí sin engañar.
class BarrasSemanales extends StatelessWidget {
  const BarrasSemanales({
    super.key,
    required this.titulo,
    required this.barras,
    required this.color,
    this.colorNegativo,
    this.alto = 140,
    this.piso,
    this.nota,
  });

  final String titulo;
  final List<BarraSemanal> barras;
  final Color color;

  /// Color para las barras bajo cero. Si es null se usa [color].
  final Color? colorNegativo;
  final double alto;

  /// Desde dónde arranca la escala, cuando cero no sirve.
  ///
  /// El precio por kilo se mueve entre ₡350 y ₡430: medido desde cero, las
  /// semanas salen todas del mismo alto y el gráfico no dice nada, que es
  /// justo lo que se venía a ver. Con un piso, la diferencia se nota.
  ///
  /// Recortar la escala **exagera** las diferencias, así que quien lo usa
  /// tiene que decir desde dónde arranca en [nota]. Y el valor exacto va
  /// escrito encima de cada barra igual, así que el número nunca depende de la
  /// altura.
  ///
  /// null = el comportamiento de siempre: cero (o el valor más negativo).
  final double? piso;

  /// Un renglón chico bajo el título, para advertir de la escala recortada.
  final String? nota;

  @override
  Widget build(BuildContext context) {
    if (barras.isEmpty) return const SizedBox.shrink();

    final valores = barras.map((b) => b.valor).toList();
    final maximo = valores.reduce((a, b) => a > b ? a : b);
    final minimo = valores.reduce((a, b) => a < b ? a : b);
    // El rango va de cero (o del mínimo, si hay negativos) al máximo. Si
    // todas las semanas dieran exactamente lo mismo, el rango sería cero y
    // no se podría dividir: ahí se usa 1 y todas salen igual de altas.
    final techo = maximo > 0 ? maximo : 0.0;
    final base = piso ?? (minimo < 0 ? minimo : 0.0);
    final rango = (techo - base) == 0 ? 1.0 : techo - base;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(LecheSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: Theme.of(context).textTheme.titleSmall),
            if (nota != null) ...[
              const SizedBox(height: 2),
              Text(nota!, style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: LecheSpacing.md),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              // La última semana es la que más interesa: se arranca viéndola.
              reverse: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final b in barras.reversed)
                    _Barra(
                      barra: b,
                      alto: alto,
                      // Proporción del alto disponible, siempre positiva.
                      // Sin piso propio se mide la magnitud desde cero (así
                      // una semana con pérdida crece hacia arriba y se pinta
                      // de rojo); con piso, la altura es lo que sobresale de
                      // él.
                      fraccion: piso == null
                          ? b.valor.abs() / rango
                          : ((b.valor - base) / rango).clamp(0.0, 1.0),
                      color:
                          b.color ??
                          (b.valor < 0 ? (colorNegativo ?? color) : color),
                    ),
                ].reversed.toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Barra extends StatelessWidget {
  const _Barra({
    required this.barra,
    required this.alto,
    required this.fraccion,
    required this.color,
  });

  final BarraSemanal barra;
  final double alto;
  final double fraccion;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    // Una barra de cero píxeles no se ve; se le deja un mínimo para que la
    // semana exista en el gráfico aunque haya dado muy poco.
    final altoBarra = (alto * fraccion).clamp(3.0, alto);

    return Padding(
      padding: const EdgeInsets.only(right: LecheSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            barra.texto,
            style: textos.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 34,
            height: altoBarra,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.85),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(6),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(barra.etiqueta, style: textos.bodySmall),
        ],
      ),
    );
  }
}
