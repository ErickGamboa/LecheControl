import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../data/domain/grupos.dart';
import '../data/domain/palpacion.dart';
import '../services.dart';
import 'palpacion_previa_pdf_screen.dart';

/// Vacas por palpar (Módulo 6 — Análisis): la hoja que se le pasa al
/// veterinario cuando viene a la finca.
///
/// Nadie marca a mano qué vaca hay que revisar: la lista sale sola de la hoja
/// de vida. Entran las **recién paridas** —revisión de posparto— y las que ya
/// se **sirvieron y no confirman preñez** —diagnóstico de gestación—. La regla
/// completa está en `domain/palpacion.dart`.
///
/// Las más atrasadas van arriba: la vaca que lleva 60 días servida sin
/// confirmar es la que más apura.
class PalpacionScreen extends StatefulWidget {
  const PalpacionScreen({
    super.key,
    required this.lecheriaId,
    required this.nombreLecheria,
  });

  final String lecheriaId;

  /// Va en el encabezado del PDF: la hoja tiene que decir de qué finca es.
  final String nombreLecheria;

  @override
  State<PalpacionScreen> createState() => _PalpacionScreenState();
}

class _PalpacionScreenState extends State<PalpacionScreen> {
  late Future<List<VacaPorPalpar>> _futuro;
  bool _exportando = false;

  @override
  void initState() {
    super.initState();
    _futuro = palpacionRepo.porPalpar(widget.lecheriaId);
  }

  /// Abre la hoja en PDF para verla. Desde ahí se comparte, o se le toma una
  /// captura y listo.
  Future<void> _verPdf() async {
    if (_exportando) return;
    setState(() => _exportando = true);
    try {
      final vacas = await _futuro;
      if (!mounted) return;
      if (vacas.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay vacas por palpar que exportar.'),
          ),
        );
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PalpacionPreviaPdfScreen(
            nombreLecheria: widget.nombreLecheria,
            vacas: vacas,
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
        title: const Text('Vacas por palpar'),
        actions: [
          IconButton(
            key: const ValueKey('palpacion.verPdf'),
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
        child: FutureBuilder<List<VacaPorPalpar>>(
          future: _futuro,
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final vacas = snap.data!;
            if (vacas.isEmpty) return const _SinVacas();

            return ListView(
              padding: const EdgeInsets.all(LecheSpacing.lg),
              children: [
                _Resumen(vacas: vacas),
                const SizedBox(height: LecheSpacing.lg),
                for (final v in vacas) _FilaVaca(vaca: v),
                const SizedBox(height: LecheSpacing.lg),
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

/// Color de cada motivo. El posparto va en ámbar porque tiene fecha de
/// vencimiento: en dos semanas la vaca sale sola de la lista.
Color _colorMotivo(MotivoPalpacion motivo) => switch (motivo) {
  MotivoPalpacion.posparto => kAmbarLeche,
  MotivoPalpacion.servidaSinConfirmar => kAzulLeche,
};

class _Resumen extends StatelessWidget {
  const _Resumen({required this.vacas});

  final List<VacaPorPalpar> vacas;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final posparto = vacas
        .where((v) => v.motivo == MotivoPalpacion.posparto)
        .length;
    final servidas = vacas.length - posparto;

    return Card(
      key: const ValueKey('palpacion.resumen'),
      child: Padding(
        padding: const EdgeInsets.all(LecheSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${vacas.length} ${vacas.length == 1 ? 'VACA' : 'VACAS'} '
              'POR PALPAR',
              style: textos.titleSmall,
            ),
            const SizedBox(height: LecheSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Conteo(
                  cantidad: posparto,
                  etiqueta: posparto == 1 ? 'Recién parida' : 'Recién paridas',
                  color: _colorMotivo(MotivoPalpacion.posparto),
                ),
                _Conteo(
                  cantidad: servidas,
                  etiqueta: 'Servidas sin confirmar',
                  color: _colorMotivo(MotivoPalpacion.servidaSinConfirmar),
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

class _FilaVaca extends StatelessWidget {
  const _FilaVaca({required this.vaca});

  final VacaPorPalpar vaca;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final color = _colorMotivo(vaca.motivo);
    final esPosparto = vaca.motivo == MotivoPalpacion.posparto;

    // Los días son lo que decide el orden de la fila, así que se dicen con
    // todas las letras en vez de dejar un número suelto que hay que
    // interpretar.
    final desde = esPosparto
        ? 'Parió hace ${_dias(vaca.dias)}'
        : 'Servida hace ${_dias(vaca.dias)}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(LecheSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(vaca.identificador, style: textos.titleMedium),
                      const SizedBox(width: LecheSpacing.sm),
                      Text(
                        GrupoAnimal.etiqueta(vaca.grupo),
                        style: textos.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(desde, style: textos.bodyMedium),
                  if (vaca.detalleServicio.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(vaca.detalleServicio, style: textos.bodySmall),
                  ],
                ],
              ),
            ),
            const SizedBox(width: LecheSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: LecheSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(LecheRadius.sm),
              ),
              child: Text(
                vaca.motivo.etiquetaCorta,
                style: textos.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _dias(int dias) => switch (dias) {
    0 => 'hoy',
    1 => '1 día',
    _ => '$dias días',
  };
}

/// Con qué criterio se armó la lista. Va al pie y no arriba: se lee una vez
/// para entenderla y después estorba.
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
            Text('CÓMO SE ARMA ESTA LISTA', style: textos.titleSmall),
            const SizedBox(height: LecheSpacing.sm),
            Text(
              '· Recién paridas: parieron hace $diasRevisionPosparto días o '
              'menos.\n'
              '· Servidas: se les anotó celo, monta o inseminación y todavía '
              'no están preñadas.\n\n'
              'Una vaca sale de la lista cuando se le registra la palpación, y '
              'las recién paridas salen solas al pasar los '
              '$diasRevisionPosparto días.',
              style: textos.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _SinVacas extends StatelessWidget {
  const _SinVacas();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 56,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: LecheSpacing.lg),
            Text(
              'No hay vacas por palpar',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: LecheSpacing.sm),
            Text(
              'Ninguna parió en los últimos $diasRevisionPosparto días y '
              'todas las que se sirvieron ya tienen su palpación registrada.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
