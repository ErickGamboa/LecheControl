import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../data/domain/grupos.dart';
import '../data/domain/palpacion.dart';
import '../services.dart';
import '../hoja_vida/hoja_vida_screen.dart';
import '../eventos/palpacion_dialog.dart';
import 'palpacion_previa_pdf_screen.dart';

/// Vacas por palpar (Módulo 6 — Análisis): la hoja que se le pasa al
/// veterinario cuando viene a la finca.
///
/// Nadie marca a mano qué vaca hay que revisar: la lista sale sola de la hoja
/// de vida. Entran las que se **sirvieron y no confirman preñez** —diagnóstico
/// de gestación— y las que **parieron y siguen sin diagnóstico**. La regla
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
    _cargar();
  }

  void _cargar() {
    _futuro = palpacionRepo.porPalpar(widget.lecheriaId);
  }

  /// Al tocar una vaca hay dos cosas razonables que querer: ver qué se le ha
  /// hecho, o palparla ya. Se preguntan en vez de adivinar, porque el que va
  /// bajando la hoja con el veterinario quiere lo segundo y el que está
  /// revisando quiere lo primero.
  ///
  /// Vuelva de donde vuelva, **se regresa a esta lista** y se recarga: si la
  /// vaca ya se palpó, tiene que desaparecer sin que nadie tenga que salir y
  /// entrar de nuevo.
  Future<void> _tocarVaca(VacaPorPalpar vaca) async {
    final accion = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text('Vaca ${vaca.identificador}'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, 'hoja'),
            child: const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.description_outlined),
              title: Text('Ver la hoja de vida'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, 'palpar'),
            child: const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.fact_check_outlined),
              title: Text('Registrar palpación'),
            ),
          ),
        ],
      ),
    );
    if (!mounted || accion == null) return;

    if (accion == 'hoja') {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => HojaVidaScreen(animalId: vaca.animalId),
        ),
      );
    } else {
      await mostrarPalpacionDialog(
        context,
        animalId: vaca.animalId,
        lecheriaId: widget.lecheriaId,
        identificador: vaca.identificador,
      );
    }
    if (mounted) setState(_cargar);
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
                for (final v in vacas)
                  _FilaVaca(vaca: v, onTap: () => _tocarVaca(v)),
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

/// Color de cada motivo. La parida sin diagnóstico va en ámbar porque es la
/// que nadie pidió: entró a la lista por olvido, no porque se haya hecho algo
/// con ella.
Color _colorMotivo(MotivoPalpacion motivo) => switch (motivo) {
  MotivoPalpacion.paridaSinDiagnostico => kAmbarLeche,
  MotivoPalpacion.servidaSinConfirmar => kAzulLeche,
};

class _Resumen extends StatelessWidget {
  const _Resumen({required this.vacas});

  final List<VacaPorPalpar> vacas;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final sinDiagnostico = vacas
        .where((v) => v.motivo == MotivoPalpacion.paridaSinDiagnostico)
        .length;
    final servidas = vacas.length - sinDiagnostico;

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
                  cantidad: sinDiagnostico,
                  etiqueta: 'Paridas sin diagnóstico',
                  color: _colorMotivo(MotivoPalpacion.paridaSinDiagnostico),
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
  const _FilaVaca({required this.vaca, required this.onTap});

  final VacaPorPalpar vaca;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final color = _colorMotivo(vaca.motivo);
    final esSinDiagnostico =
        vaca.motivo == MotivoPalpacion.paridaSinDiagnostico;

    // Los días son lo que decide el orden de la fila, así que se dicen con
    // todas las letras en vez de dejar un número suelto que hay que
    // interpretar.
    final desde = esSinDiagnostico
        ? 'Parió hace ${_dias(vaca.dias)}, sin diagnóstico'
        : 'Servida hace ${_dias(vaca.dias)}';

    return Card(
      key: ValueKey('palpacion.vaca.${vaca.animalId}'),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
              '· Servidas: se les anotó monta o inseminación y todavía no '
              'están preñadas. El celo no cuenta: es que la vaca está en '
              'calor, no que se sirvió.\n'
              '· Sin diagnóstico: parieron hace más de $diasSinDiagnostico '
              'días y nadie les ha registrado preñez ni vacío.\n\n'
              'En los dos casos la vaca sale de la lista cuando se le registra '
              'la palpación. Ninguna sale sola por el paso del tiempo.',
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
              'Ninguna parió en los últimos $diasSinDiagnostico días y '
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
