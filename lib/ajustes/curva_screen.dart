import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../app/widgets/quick_number_field.dart';
import '../data/local/database.dart';
import '../data/repositories/curva_repository.dart';
import '../services.dart';

/// Editor de la curva de referencia de lactancia (Módulo 3).
///
/// Los siete tramos dicen cuántos litros se esperan de una vaca según cuántos
/// días lleva de parida. Vienen precargados con valores generales; esta
/// pantalla es donde dejan de ser prestados y pasan a ser los de la finca.
///
/// Abajo aparece **lo que el hato produce de verdad** en cada tramo, sacado de
/// todas las pesas registradas, con un botón para adoptarlo tramo por tramo.
class CurvaScreen extends StatefulWidget {
  const CurvaScreen({super.key, required this.lecheriaId});

  final String lecheriaId;

  @override
  State<CurvaScreen> createState() => _CurvaScreenState();
}

class _CurvaScreenState extends State<CurvaScreen> {
  late Future<List<PromedioRealTramo>> _reales;

  @override
  void initState() {
    super.initState();
    _recargarReales();
  }

  void _recargarReales() {
    _reales = curvaRepo.promediosRealesDelHato(widget.lecheriaId);
  }

  Future<void> _editarTramo(CurvaReferenciaRow tramo) async {
    // El diálogo es dueño de su propio controlador y lo libera en su dispose.
    // Crearlo acá y destruirlo apenas vuelve `showDialog` rompe la app: la
    // animación de cierre sigue corriendo y el campo intenta usar un
    // controlador ya destruido.
    final litros = await showDialog<double>(
      context: context,
      builder: (_) => _EditarTramoDialog(
        rango: _rango(tramo),
        valorInicial: tramo.litrosEsperados,
      ),
    );
    if (litros == null) return;
    await curvaRepo.editarTramo(tramoId: tramo.id, litrosEsperados: litros);
    sincronizarSiSePuede();
  }

  Future<void> _adoptar(PromedioRealTramo real) async {
    final promedio = real.promedio;
    if (promedio == null) return;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Adoptar ${promedio.toStringAsFixed(1)} L'),
        content: Text(
          'El tramo ${_rango(real.tramo)} pasa de '
          '${real.tramo.litrosEsperados.toStringAsFixed(1)} L a '
          '${promedio.toStringAsFixed(1)} L, que es lo que tu hato produce '
          'de verdad ahí (${real.observaciones} pesas).\n\n'
          'Ojo: si tu hato viene produciendo poco, adoptar el promedio baja '
          'la vara y esas vacas van a empezar a salir bien evaluadas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Adoptar'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;
    await curvaRepo.editarTramo(
      tramoId: real.tramo.id,
      litrosEsperados: double.parse(promedio.toStringAsFixed(1)),
    );
    sincronizarSiSePuede();
    if (mounted) setState(_recargarReales);
  }

  static String _rango(CurvaReferenciaRow t) => t.diaHasta == null
      ? 'más de ${t.diaDesde - 1} días'
      : '${t.diaDesde} a ${t.diaHasta} días';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Curva de referencia')),
      body: StreamBuilder<List<CurvaReferenciaRow>>(
        stream: curvaRepo.observarTramos(widget.lecheriaId),
        builder: (context, snap) {
          final tramos = snap.data ?? const <CurvaReferenciaRow>[];
          if (tramos.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Esta lechería todavía no tiene curva de referencia.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Cuántos litros se esperan de una vaca según cuántos días '
                'lleva desde su parto. Tocá un tramo para cambiarlo.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Entre un tramo y el siguiente la app hace la transición '
                'suave, así que ninguna vaca cambia de evaluación por cumplir '
                'un día más.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              for (final t in tramos)
                Card(
                  elevation: 1,
                  child: ListTile(
                    key: ValueKey('curva.tramo.${t.diaDesde}'),
                    title: Text(_rango(t)),
                    trailing: Text(
                      '${t.litrosEsperados.toStringAsFixed(1)} L',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: kAzulLeche,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () => _editarTramo(t),
                  ),
                ),
              const SizedBox(height: 24),
              _Recalibracion(futuro: _reales, onAdoptar: _adoptar),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}

/// Pide los litros esperados de un tramo. Devuelve el valor por
/// `Navigator.pop`, o null si se canceló o quedó un número inválido.
class _EditarTramoDialog extends StatefulWidget {
  const _EditarTramoDialog({required this.rango, required this.valorInicial});

  final String rango;
  final double valorInicial;

  @override
  State<_EditarTramoDialog> createState() => _EditarTramoDialogState();
}

class _EditarTramoDialogState extends State<_EditarTramoDialog> {
  late final _ctrl = TextEditingController(
    text: widget.valorInicial.toStringAsFixed(1),
  );
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _guardar() {
    final litros = double.tryParse(_ctrl.text.trim().replaceAll(',', '.'));
    if (litros == null || litros < 0) {
      setState(() => _error = 'Poné un número de litros válido.');
      return;
    }
    Navigator.pop(context, litros);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Esperado para ${widget.rango}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Cuántos litros debería dar una vaca que lleva ${widget.rango} '
            'de parida.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          QuickNumberField(
            key: const ValueKey('curva.editarTramo.litros'),
            controller: _ctrl,
            labelText: 'Litros esperados',
            suffixText: 'L',
            autofocus: true,
            onSubmitted: (_) => _guardar(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const ValueKey('curva.editarTramo.guardar'),
          onPressed: _guardar,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

/// Lo que el hato produce de verdad, al lado de lo que dice la tabla.
class _Recalibracion extends StatelessWidget {
  const _Recalibracion({required this.futuro, required this.onAdoptar});

  final Future<List<PromedioRealTramo>> futuro;
  final void Function(PromedioRealTramo) onAdoptar;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PromedioRealTramo>>(
      future: futuro,
      builder: (context, snap) {
        final reales = snap.data ?? const <PromedioRealTramo>[];
        final conDatos = reales.where((r) => r.promedio != null).toList();
        if (conDatos.isEmpty) {
          return Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TU HATO REAL',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'A medida que vayas pesando, acá va a aparecer lo que tu '
                    'hato produce de verdad en cada tramo, para que puedas '
                    'reemplazar estos valores por los tuyos.',
                  ),
                ],
              ),
            ),
          );
        }

        final confiables = conDatos.where((r) => r.confiable).length;
        return Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TU HATO REAL',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  confiables == 0
                      ? 'Todavía hay pocas pesas por tramo: los promedios se '
                            'mueven mucho. Esperá unas semanas más antes de '
                            'adoptarlos.'
                      : '$confiables de ${conDatos.length} tramos ya tienen '
                            'suficientes pesas como para tomárselos en serio.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                for (final r in conDatos)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_CurvaScreenState._rango(r.tramo)),
                              Text(
                                '${r.tramo.litrosEsperados.toStringAsFixed(1)} L '
                                'esperados · ${r.promedio!.toStringAsFixed(1)} L '
                                'reales · ${r.observaciones} pesas',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          key: ValueKey('curva.adoptar.${r.tramo.diaDesde}'),
                          onPressed: r.confiable ? () => onAdoptar(r) : null,
                          child: const Text('Adoptar'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
