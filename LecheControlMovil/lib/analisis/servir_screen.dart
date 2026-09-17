import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../data/domain/grupos.dart';
import '../data/domain/servir.dart';
import '../hoja_vida/hoja_vida_screen.dart';
import '../services.dart';

/// Vacas por servir (Módulo 6 — Análisis): las que llevan
/// [diasParaServir] días o más de paridas y todavía no están preñadas.
///
/// Es la lista que nadie pide y que más cuesta: una vaca abierta no se queja,
/// solo produce cada vez menos y estira el intervalo entre partos. Acá salen
/// ordenadas por lo único que importa —cuánto llevan— y pintadas de rojo según
/// qué tan atrás vienen, para que la peor salte a la vista sin leer números.
///
/// Al tocar una vaca se abre su hoja de vida, que es donde se ve qué se le ha
/// hecho y qué falta.
class ServirScreen extends StatefulWidget {
  const ServirScreen({super.key, required this.lecheriaId});

  final String lecheriaId;

  @override
  State<ServirScreen> createState() => _ServirScreenState();
}

class _ServirScreenState extends State<ServirScreen> {
  late Future<List<VacaPorServir>> _futuro;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    _futuro = palpacionRepo.porServir(widget.lecheriaId);
  }

  /// Vuelve a leer la lista al regresar de la hoja de vida: si allá se le
  /// registró una palpación, la vaca ya no va acá.
  Future<void> _abrirHojaDeVida(VacaPorServir vaca) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HojaVidaScreen(animalId: vaca.animalId),
      ),
    );
    if (mounted) setState(_cargar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vacas por servir')),
      body: SafeArea(
        child: FutureBuilder<List<VacaPorServir>>(
          future: _futuro,
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final vacas = snap.data!;
            if (vacas.isEmpty) return const _SinVacas();

            // Los extremos de esta lista son los que reparten el color. Se
            // calculan una vez acá y no por fila.
            final mas = vacas.first.diasLactancia;
            final menos = vacas.last.diasLactancia;

            return ListView(
              padding: const EdgeInsets.all(LecheSpacing.lg),
              children: [
                _Resumen(vacas: vacas),
                const SizedBox(height: LecheSpacing.lg),
                for (final v in vacas)
                  _FilaVaca(
                    vaca: v,
                    urgencia: urgencia(v.diasLactancia, menos: menos, mas: mas),
                    onTap: () => _abrirHojaDeVida(v),
                  ),
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

class _Resumen extends StatelessWidget {
  const _Resumen({required this.vacas});

  final List<VacaPorServir> vacas;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final sinIntentar = vacas.where((v) => v.servicios == 0).length;

    return Card(
      key: const ValueKey('servir.resumen'),
      child: Padding(
        padding: const EdgeInsets.all(LecheSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${vacas.length} ${vacas.length == 1 ? 'VACA' : 'VACAS'} '
              'POR SERVIR',
              style: textos.titleSmall,
            ),
            const SizedBox(height: LecheSpacing.sm),
            Text(
              sinIntentar == 0
                  ? 'A todas se les ha intentado al menos un servicio.'
                  : sinIntentar == 1
                  ? 'A 1 no se le ha intentado ningún servicio.'
                  : 'A $sinIntentar no se les ha intentado ningún servicio.',
              style: textos.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaVaca extends StatelessWidget {
  const _FilaVaca({
    required this.vaca,
    required this.urgencia,
    required this.onTap,
  });

  final VacaPorServir vaca;

  /// De 0 a 1: qué tan atrás viene contra el resto de la lista.
  final double urgencia;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final esquema = Theme.of(context).colorScheme;

    // El rojo se difumina hacia el fondo de la tarjeta: la vaca más atrasada
    // va en rojo pleno y la menos atrasada casi sin color. No se usa un umbral
    // fijo porque lo que importa es el orden dentro de esta finca.
    final fondo = Color.lerp(
      esquema.surface,
      const Color(0xFFD32F2F),
      0.08 + urgencia * 0.22,
    );
    final borde = Color.lerp(
      esquema.outlineVariant,
      const Color(0xFFD32F2F),
      urgencia,
    );

    return Card(
      key: ValueKey('servir.vaca.${vaca.animalId}'),
      color: fondo,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: borde ?? esquema.outlineVariant, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(LecheSpacing.lg),
          child: Row(
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
                    const SizedBox(height: 4),
                    Text(vaca.resumen, style: textos.bodyMedium),
                  ],
                ),
              ),
              Text(
                '${vaca.diasLactancia}',
                style: textos.headlineSmall?.copyWith(
                  color: const Color(0xFFB71C1C),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: esquema.outline),
            ],
          ),
        ),
      ),
    );
  }
}

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
              'Entran las vacas que parieron hace $diasParaServir días o más y '
              'todavía no están preñadas, estén en ordeño o secas.\n\n'
              'El número grande son los días de lactancia. Los servicios son '
              'las montas e inseminaciones desde que parió; el celo no '
              'cuenta.\n\n'
              'Una vaca sale de la lista cuando se le registra la preñez.',
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
    final textos = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LecheSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: LecheSpacing.md),
            Text(
              'Ninguna vaca lleva $diasParaServir días o más de parida sin '
              'preñarse.',
              textAlign: TextAlign.center,
              style: textos.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
