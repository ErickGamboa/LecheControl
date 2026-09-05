import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../data/domain/grupos.dart';
import '../data/domain/partos_proyectados.dart';
import '../data/repositories/partos_repository.dart';
import '../services.dart';
import 'partos_previa_pdf_screen.dart';
import 'widgets/barras_semanales.dart';

/// Partos por mes (Módulo 6 — Análisis): el calendario de lo que viene.
///
/// El resto de la app mira hacia atrás —lo que dio la semana pasada, lo que se
/// gastó el mes pasado—. Esta es la única que mira hacia adelante: qué vacas
/// paren de aquí a un año y en qué mes se juntan.
///
/// Sirve para dos cosas muy concretas: saber en qué mes se le llena el ordeño
/// —y cuánta leche va a haber que entregar— y en cuál se le vacía, que es
/// cuando conviene tener novillas listas o adelantar servicios.
///
/// La cuenta es la de la finca: la vaca queda preñada y pare unos nueve meses
/// después. La regla completa está en `domain/partos_proyectados.dart`.
class PartosScreen extends StatefulWidget {
  const PartosScreen({
    super.key,
    required this.lecheriaId,
    required this.nombreLecheria,
    this.repositorio,
  });

  final String lecheriaId;

  /// Va en el encabezado del PDF: la hoja tiene que decir de qué finca es.
  final String nombreLecheria;

  /// Con qué repositorio se arma el calendario. En la app va siempre el de
  /// `services.dart`; se puede pasar otro para montar la pantalla contra una
  /// base en memoria y ver cómo queda con un hato armado a mano.
  final PartosRepository? repositorio;

  @override
  State<PartosScreen> createState() => _PartosScreenState();
}

class _PartosScreenState extends State<PartosScreen> {
  late Future<ProyeccionPartos> _futuro;
  bool _exportando = false;

  @override
  void initState() {
    super.initState();
    _futuro = (widget.repositorio ?? partosRepo).proyeccion(widget.lecheriaId);
  }

  /// Abre el calendario en PDF para verlo. Desde ahí se comparte, o se le toma
  /// una captura y listo.
  Future<void> _verPdf() async {
    if (_exportando) return;
    setState(() => _exportando = true);
    try {
      final proyeccion = await _futuro;
      if (!mounted) return;
      if (proyeccion.totalPreniadas == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Todavía no hay vacas preñadas que proyectar.'),
          ),
        );
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PartosPreviaPdfScreen(
            nombreLecheria: widget.nombreLecheria,
            proyeccion: proyeccion,
            generadoEl: DateTime.now(),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partos por mes'),
        actions: [
          IconButton(
            key: const ValueKey('partos.verPdf'),
            tooltip: 'Ver en PDF',
            onPressed: _exportando ? null : _verPdf,
            icon: _exportando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<ProyeccionPartos>(
          future: _futuro,
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final proyeccion = snap.data!;
            if (proyeccion.totalPreniadas == 0) return const _SinPreniadas();

            return ListView(
              padding: const EdgeInsets.all(LecheSpacing.lg),
              children: [
                _Resumen(proyeccion: proyeccion),
                const SizedBox(height: LecheSpacing.md),
                if (proyeccion.totalEnCalendario > 0) ...[
                  BarrasSemanales(
                    titulo: 'VACAS QUE PAREN CADA MES',
                    color: kVerdeLeche,
                    alto: 110,
                    // El calendario mira hacia adelante: se arranca por el mes
                    // en curso, no por el último.
                    desdeElFinal: false,
                    barras: [
                      for (final mes in proyeccion.meses)
                        BarraSemanal(
                          etiqueta: mes.etiquetaCorta,
                          valor: mes.cantidad.toDouble(),
                          texto: '${mes.cantidad}',
                        ),
                    ],
                  ),
                  const SizedBox(height: LecheSpacing.md),
                ],
                for (var i = 0; i < proyeccion.meses.length; i++)
                  _TarjetaMes(mes: proyeccion.meses[i], esMesEnCurso: i == 0),
                if (proyeccion.sinFecha.isNotEmpty) ...[
                  const SizedBox(height: LecheSpacing.md),
                  _SinFecha(identificadores: proyeccion.sinFecha),
                ],
                if (proyeccion.fueraDeRango.isNotEmpty) ...[
                  const SizedBox(height: LecheSpacing.md),
                  _FueraDeRango(vacas: proyeccion.fueraDeRango),
                ],
                const SizedBox(height: LecheSpacing.md),
                const _Criterio(),
                const SizedBox(height: LecheSpacing.xl),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Cómo se pinta una vaca según lo que le falta: la que ya se pasó de fecha en
/// rojo, la que está por parir en ámbar y el resto en verde. Así el mes se lee
/// de un vistazo sin tener que leer los días.
Color _colorSegunDias(int dias) {
  if (dias < 0) return kPeligro;
  if (dias <= diasParaPronta) return kAmbarLeche;
  return kVerdeLeche;
}

/// Lo que falta, dicho con todas las letras. Un número suelto de días obliga a
/// interpretar; esto se lee y ya.
String _cuantoFalta(int dias) => switch (dias) {
  < -1 => 'Pasada de fecha por ${-dias} días',
  -1 => 'Pasada de fecha por 1 día',
  0 => 'Le corresponde parir hoy',
  1 => 'Falta 1 día',
  _ => 'Faltan $dias días',
};

class _Resumen extends StatelessWidget {
  const _Resumen({required this.proyeccion});

  final ProyeccionPartos proyeccion;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final total = proyeccion.totalPreniadas;
    final proximo = proyeccion.proximoMesConPartos;
    final pico = proyeccion.mesConMasPartos;

    return Card(
      key: const ValueKey('partos.resumen'),
      child: Padding(
        padding: const EdgeInsets.all(LecheSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$total ${total == 1 ? 'VACA PREÑADA' : 'VACAS PREÑADAS'}',
              style: textos.titleSmall,
            ),
            const SizedBox(height: LecheSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Conteo(
                  cantidad: proximo?.cantidad ?? 0,
                  etiqueta: proximo == null
                      ? 'Sin partos en los próximos '
                            '${proyeccion.meses.length} meses'
                      : 'Paren en ${proximo.etiqueta}',
                  color: kVerdeLeche,
                ),
                _Conteo(
                  cantidad: pico?.cantidad ?? 0,
                  etiqueta: pico == null
                      ? '—'
                      : 'Mes más cargado: ${pico.etiqueta}',
                  color: kAzulLeche,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Conteo extends StatelessWidget {
  const _Conteo({
    required this.cantidad,
    required this.etiqueta,
    required this.color,
  });

  final int cantidad;
  final String etiqueta;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$cantidad',
            style: textos.headlineSmall?.copyWith(color: color),
          ),
          const SizedBox(height: 2),
          Text(etiqueta, style: textos.bodySmall),
        ],
      ),
    );
  }
}

/// Un mes del calendario. Los vacíos también salen: que en noviembre no pare
/// ninguna es justo lo que se viene a ver acá.
class _TarjetaMes extends StatelessWidget {
  const _TarjetaMes({required this.mes, required this.esMesEnCurso});

  final MesDePartos mes;
  final bool esMesEnCurso;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final colores = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: LecheSpacing.md),
      child: Card(
        key: ValueKey('partos.mes.${mes.anio}-${mes.mes}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: LecheSpacing.lg,
                vertical: LecheSpacing.md,
              ),
              // El mes en curso va marcado: es el que se mira primero al
              // abrir la pantalla.
              color: esMesEnCurso
                  ? kVerdeLeche.withValues(alpha: 0.10)
                  : colores.surfaceContainerHighest.withValues(alpha: 0.4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      mes.etiqueta,
                      style: textos.titleSmall?.copyWith(
                        color: mes.vacio ? colores.outline : null,
                      ),
                    ),
                  ),
                  if (esMesEnCurso) ...[
                    Text(
                      'Este mes',
                      style: textos.bodySmall?.copyWith(color: kVerdeLeche),
                    ),
                    const SizedBox(width: LecheSpacing.sm),
                  ],
                  _Pastilla(cantidad: mes.cantidad),
                ],
              ),
            ),
            if (mes.vacio)
              Padding(
                padding: const EdgeInsets.all(LecheSpacing.lg),
                child: Text(
                  'Ninguna vaca pare en este mes.',
                  style: textos.bodySmall?.copyWith(color: colores.outline),
                ),
              )
            else
              for (var i = 0; i < mes.vacas.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                _FilaVaca(vaca: mes.vacas[i]),
              ],
          ],
        ),
      ),
    );
  }
}

/// El conteo del mes, redondo al lado del nombre. Los meses sin partos la
/// llevan apagada para que no compitan con los que sí traen vacas.
class _Pastilla extends StatelessWidget {
  const _Pastilla({required this.cantidad});

  final int cantidad;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final hay = cantidad > 0;
    final color = hay ? kVerdeLeche : colores.outline;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LecheSpacing.md,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: hay ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(LecheRadius.sm),
      ),
      child: Text(
        '$cantidad',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color),
      ),
    );
  }
}

class _FilaVaca extends StatelessWidget {
  const _FilaVaca({required this.vaca});

  final VacaPorParir vaca;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final dias = vaca.dias();
    final color = _colorSegunDias(dias);

    return Padding(
      padding: const EdgeInsets.all(LecheSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DiaDelParto(dia: vaca.fechaProbable.day, color: color),
          const SizedBox(width: LecheSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Flexible y con puntos suspensivos: hay fincas que
                    // identifican la vaca por nombre y no por número, y un
                    // "NOVILLA-BLANQUITA-2024" se sale de la fila.
                    Flexible(
                      child: Text(
                        vaca.identificador,
                        style: textos.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: LecheSpacing.sm),
                    Text(
                      GrupoAnimal.etiqueta(vaca.grupo),
                      style: textos.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _cuantoFalta(dias),
                  style: textos.bodyMedium?.copyWith(
                    color: dias < 0 ? kPeligro : null,
                  ),
                ),
                if (vaca.detalleServicio.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(vaca.detalleServicio, style: textos.bodySmall),
                ],
              ],
            ),
          ),
          // Solo se marca la estimada: la confirmada es lo normal, y ponerle
          // etiqueta a todas dejaría la lista llena de ruido.
          if (vaca.origen == OrigenFechaParto.estimada) ...[
            const SizedBox(width: LecheSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: LecheSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: kAmbarLeche.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(LecheRadius.sm),
              ),
              child: Text(
                'Estimada',
                style: textos.bodySmall?.copyWith(
                  color: kAmbarLeche,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// El día del mes en que le corresponde parir, en grande a la par de la vaca.
/// El mes ya lo dice la tarjeta, así que acá solo va el número.
class _DiaDelParto extends StatelessWidget {
  const _DiaDelParto({required this.dia, required this.color});

  final int dia;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(LecheRadius.sm),
      ),
      child: Text(
        '$dia',
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(color: color),
      ),
    );
  }
}

/// Preñadas que no se pueden proyectar. Se muestran en vez de esconderlas: es
/// un dato que falta en la hoja de vida y solo se arregla si alguien lo ve.
class _SinFecha extends StatelessWidget {
  const _SinFecha({required this.identificadores});

  final List<String> identificadores;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final cuantas = identificadores.length;

    return Card(
      key: const ValueKey('partos.sinFecha'),
      child: Padding(
        padding: const EdgeInsets.all(LecheSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.help_outline,
                  size: 18,
                  color: kAmbarLeche,
                ),
                const SizedBox(width: LecheSpacing.sm),
                Expanded(
                  child: Text(
                    '$cuantas ${cuantas == 1 ? 'PREÑADA' : 'PREÑADAS'} SIN '
                    'FECHA DE PARTO',
                    style: textos.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: LecheSpacing.sm),
            Text(identificadores.join(' · '), style: textos.bodyMedium),
            const SizedBox(height: LecheSpacing.sm),
            Text(
              'Están marcadas como preñadas pero no tienen fecha probable de '
              'parto anotada ni un servicio del cual sacarla. Se les registra '
              'la palpación en la hoja de vida y entran solas al calendario.',
              style: textos.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Fechas que caen más allá del último mes. Con nueve meses de gestación no
/// existe una preñez así: es una fecha mal digitada y conviene que se vea.
class _FueraDeRango extends StatelessWidget {
  const _FueraDeRango({required this.vacas});

  final List<VacaPorParir> vacas;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Card(
      key: const ValueKey('partos.fueraDeRango'),
      child: Padding(
        padding: const EdgeInsets.all(LecheSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CON FECHA MUY LEJANA', style: textos.titleSmall),
            const SizedBox(height: LecheSpacing.sm),
            for (final v in vacas)
              Text(
                '${v.identificador} · ${v.fechaProbable.day}/'
                '${v.fechaProbable.month}/${v.fechaProbable.year}',
                style: textos.bodyMedium,
              ),
            const SizedBox(height: LecheSpacing.sm),
            Text(
              'La fecha de parto anotada cae más allá de los '
              '$mesesDeProyeccion meses del calendario. Una preñez dura unos '
              'nueve meses, así que casi siempre es una fecha digitada mal.',
              style: textos.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Con qué criterio se armó el calendario. Va al pie y no arriba: se lee una
/// vez para entenderlo y después estorba.
class _Criterio extends StatelessWidget {
  const _Criterio();

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(LecheSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CÓMO SE SACA ESTE CALENDARIO', style: textos.titleSmall),
            const SizedBox(height: LecheSpacing.sm),
            Text(
              '· La preñez se cuenta en $diasGestacion días: los nueve meses '
              'de los que se habla en la finca.\n'
              '· Fecha confirmada: la que anotó la palpación. Es la del '
              'veterinario y manda sobre cualquier cuenta.\n'
              '· Fecha estimada: el último servicio más la gestación, para la '
              'vaca preñada a la que no se le anotó fecha probable.\n'
              '· La vaca que se pasa de fecha se queda en el mes en curso '
              'hasta que se le registre el parto.\n\n'
              'Solo entran las hembras activas marcadas como preñadas. Al '
              'registrarle el parto, la vaca vuelve a vacía y sale sola del '
              'calendario.',
              style: textos.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _SinPreniadas extends StatelessWidget {
  const _SinPreniadas();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: LecheSpacing.lg),
            Text(
              'Todavía no hay partos que proyectar',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: LecheSpacing.sm),
            Text(
              'Ninguna vaca está marcada como preñada. El calendario se llena '
              'solo: cuando la palpación confirma una preñez, la vaca aparece '
              'en el mes en que le corresponde parir.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
