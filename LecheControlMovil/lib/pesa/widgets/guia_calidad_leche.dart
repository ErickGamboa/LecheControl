import 'package:flutter/material.dart';

import '../../app/formato.dart';
import '../../app/theme.dart';
import '../../data/domain/calidad_leche.dart';

/// Color con el que se pinta cada escalón de calidad. Vive en la capa de UI
/// porque el dominio no conoce Flutter: allá solo hay un [NivelCalidad].
Color colorNivel(NivelCalidad nivel) => switch (nivel) {
  NivelCalidad.excelente => kExito,
  NivelCalidad.bueno => kVerdeLeche,
  NivelCalidad.vigilar => kAviso,
  NivelCalidad.malo => kPeligro,
};

/// Las tablas con las que el ganadero interpreta lo que le manda la planta.
///
/// Van plegadas: son de consulta, no de lectura obligatoria, y desplegadas se
/// comerían la pantalla en la que hay que anotar tres números. Se muestran
/// tanto donde se anota la calidad como donde se analiza, porque la pregunta
/// —"¿y esto está bien o mal?"— aparece en los dos lados.
///
/// [resaltarBacterial], [resaltarSomaticas] y [resaltarSolidos] marcan el
/// renglón en el que cayó la semana que se está viendo: con el escalón
/// señalado, la tabla deja de ser un cuadro de números y pasa a decir dónde
/// está parada la finca.
class GuiaCalidadLeche extends StatelessWidget {
  const GuiaCalidadLeche({
    super.key,
    this.resaltarSolidos,
    this.resaltarSomaticas,
    this.resaltarBacterial,
  });

  final double? resaltarSolidos;
  final double? resaltarSomaticas;
  final double? resaltarBacterial;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          _Tabla(
            valueKey: 'calidad.guia.solidos',
            titulo: 'Sólidos totales (%)',
            subtitulo: 'Referencia de manejo, no tabla de pago',
            tabla: tablaSolidosTotales,
            resaltar: resaltarSolidos,
            rango: (r) => r.hasta == null
                ? '${_pct(r.desde)} o más'
                : '${_pct(r.desde)} – ${_pct(r.hasta!)}',
          ),
          const Divider(height: 1),
          _Tabla(
            valueKey: 'calidad.guia.somaticas',
            titulo: 'Células somáticas (cél./mL)',
            subtitulo: 'Referencia de manejo, no tabla de pago',
            tabla: tablaCelulasSomaticas,
            resaltar: resaltarSomaticas,
            rango: (r) => r.hasta == null
                ? 'Más de ${miles(r.desde)}'
                : '${miles(r.desde)} – ${miles(r.hasta!)}',
          ),
          const Divider(height: 1),
          _Tabla(
            valueKey: 'calidad.guia.bacterial',
            titulo: 'Recuento bacterial (UFC/mL)',
            subtitulo: 'Grado y ajuste al valor, según la planta',
            tabla: tablaRecuentoBacterial,
            resaltar: resaltarBacterial,
            rango: (r) => r.hasta == null
                ? 'Mayor de ${miles(r.desde)}'
                : 'De ${miles(r.desde)} a ${miles(r.hasta!)}',
          ),
          const Divider(height: 1),
          const _TablaPrecios(),
        ],
      ),
    );
  }

  static String _pct(double valor) => valor == valor.roundToDouble()
      ? '${valor.round()} %'
      : '${decimales(valor, cifras: 1)} %';
}

/// El escalón en el que cayó un análisis: el nombre del grado y, al lado, qué
/// significa. Es lo que se ve tanto al digitar como en el análisis semanal.
class EtiquetaEscalon extends StatelessWidget {
  const EtiquetaEscalon({
    super.key,
    required this.escalon,
    this.compacta = false,
  });

  final RangoCalidad escalon;

  /// Sin la nota explicativa: para las listas, donde solo cabe el grado.
  final bool compacta;

  @override
  Widget build(BuildContext context) {
    final color = colorNivel(escalon.nivel);
    final textos = Theme.of(context).textTheme;

    final chip = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LecheSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(LecheRadius.sm),
      ),
      child: Text(
        escalon.etiqueta,
        style: textos.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    if (compacta) return chip;

    return Row(
      children: [
        chip,
        const SizedBox(width: LecheSpacing.sm),
        Expanded(child: Text(escalon.nota, style: textos.bodySmall)),
      ],
    );
  }
}

class _Tabla extends StatelessWidget {
  const _Tabla({
    required this.valueKey,
    required this.titulo,
    required this.subtitulo,
    required this.tabla,
    required this.rango,
    required this.resaltar,
  });

  final String valueKey;
  final String titulo;
  final String subtitulo;
  final List<RangoCalidad> tabla;
  final String Function(RangoCalidad) rango;
  final double? resaltar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final actual = escalonDe(resaltar, tabla);

    return ExpansionTile(
      key: ValueKey(valueKey),
      shape: const Border(),
      collapsedShape: const Border(),
      title: Text(titulo, style: textos.titleSmall),
      subtitle: Text(subtitulo, style: textos.bodySmall),
      childrenPadding: const EdgeInsets.only(
        left: LecheSpacing.lg,
        right: LecheSpacing.lg,
        bottom: LecheSpacing.lg,
      ),
      children: [
        for (final r in tabla)
          _Renglon(
            rango: rango(r),
            etiqueta: r.etiqueta,
            nota: r.nota,
            color: colorNivel(r.nivel),
            esActual: identical(r, actual),
          ),
      ],
    );
  }
}

class _Renglon extends StatelessWidget {
  const _Renglon({
    required this.rango,
    required this.etiqueta,
    required this.nota,
    required this.color,
    required this.esActual,
  });

  final String rango;
  final String etiqueta;
  final String nota;
  final Color color;
  final bool esActual;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: LecheSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: LecheSpacing.sm,
        vertical: LecheSpacing.sm,
      ),
      decoration: BoxDecoration(
        // El renglón de la semana que se está viendo va teñido de su color;
        // los demás, sin fondo, para que se note cuál es de un vistazo.
        color: esActual ? color.withValues(alpha: 0.12) : null,
        borderRadius: BorderRadius.circular(LecheRadius.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              rango,
              style: esActual
                  ? textos.bodyMedium?.copyWith(fontWeight: FontWeight.w600)
                  : textos.bodyMedium,
            ),
          ),
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  etiqueta,
                  style: textos.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(nota, style: textos.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lo que la planta paga por kilo de sólido. No se cruza con nada: está para
/// explicar por qué los sólidos importan.
class _TablaPrecios extends StatelessWidget {
  const _TablaPrecios();

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return ExpansionTile(
      key: const ValueKey('calidad.guia.precios'),
      shape: const Border(),
      collapsedShape: const Border(),
      title: Text('Precios por kilo de sólido', style: textos.titleSmall),
      subtitle: Text('Lo que paga la planta', style: textos.bodySmall),
      childrenPadding: const EdgeInsets.only(
        left: LecheSpacing.lg,
        right: LecheSpacing.lg,
        bottom: LecheSpacing.lg,
      ),
      children: [
        // Cuatro columnas en un teléfono angosto: con `DataTable` la última
        // ("NS > 20 %") quedaba fuera de pantalla y había que descubrir que
        // la tabla se corría de lado. Con `Table` y letra chica las cuatro
        // entran de una, que es lo que una tabla de referencia tiene que
        // hacer: verse entera de un vistazo.
        Table(
          columnWidths: const {
            0: FlexColumnWidth(2.4),
            1: FlexColumnWidth(1.7),
            2: FlexColumnWidth(1.7),
            3: FlexColumnWidth(1.7),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              children: [
                const SizedBox.shrink(),
                for (final titulo in ['Suscrita', 'No suscr.', 'NS > 20 %'])
                  _CeldaPrecio(texto: titulo, encabezado: true),
              ],
            ),
            for (final p in tablaPreciosSolidos)
              TableRow(
                children: [
                  _CeldaPrecio(texto: p.componente, alaIzquierda: true),
                  _CeldaPrecio(texto: colonesConCentimos(p.suscrita)),
                  _CeldaPrecio(texto: colonesConCentimos(p.noSuscrita)),
                  _CeldaPrecio(texto: colonesConCentimos(p.noSuscritaSobre20)),
                ],
              ),
          ],
        ),
        const SizedBox(height: LecheSpacing.sm),
        Text(
          'La app no calcula el pago: la plata que entra se anota en Finanzas, '
          'que es la que de verdad se recibió.',
          style: textos.bodySmall,
        ),
      ],
    );
  }
}

/// Una celda de la tabla de precios. Los números van a la derecha para que las
/// tres columnas se puedan comparar de arriba abajo.
class _CeldaPrecio extends StatelessWidget {
  const _CeldaPrecio({
    required this.texto,
    this.encabezado = false,
    this.alaIzquierda = false,
  });

  final String texto;
  final bool encabezado;
  final bool alaIzquierda;

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(context).textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        texto,
        textAlign: alaIzquierda ? TextAlign.start : TextAlign.end,
        style: encabezado
            ? estilo?.copyWith(fontWeight: FontWeight.w600)
            : estilo,
      ),
    );
  }
}
