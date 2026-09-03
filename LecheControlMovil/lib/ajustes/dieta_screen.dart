import 'package:flutter/material.dart';

import '../app/widgets/quick_number_field.dart';
import '../services.dart';

/// La regla de concentrado de la finca: cuántos kilos de leche pagan un kilo
/// de concentrado.
///
/// Con 3, una vaca que da 18 L debería comer 6 kg. El número cambia con el
/// precio de la leche y del concentrado, así que lo maneja el ganadero y no
/// está clavado en el código.
class DietaScreen extends StatefulWidget {
  const DietaScreen({super.key, required this.lecheriaId});

  final String lecheriaId;

  @override
  State<DietaScreen> createState() => _DietaScreenState();
}

class _DietaScreenState extends State<DietaScreen> {
  final _ctrl = TextEditingController();
  bool _cargando = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    final kg = await curvaRepo.kgLechePorKgConcentradoDe(widget.lecheriaId);
    if (!mounted) return;
    setState(() {
      _ctrl.text = _sinDecimalesInutiles(kg);
      _cargando = false;
    });
  }

  static String _sinDecimalesInutiles(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  Future<void> _guardar() async {
    final texto = _ctrl.text.trim().replaceAll(',', '.');
    final kg = double.tryParse(texto);
    if (kg == null || kg <= 0) {
      _avisar('Escribí cuántos kilos de leche pagan un kilo de concentrado.');
      return;
    }

    setState(() => _guardando = true);
    await curvaRepo.editarKgLechePorKgConcentrado(
      lecheriaId: widget.lecheriaId,
      kgLechePorKg: kg,
    );
    sincronizarSiSePuede();
    if (!mounted) return;
    setState(() => _guardando = false);
    _avisar('Regla guardada.');
  }

  void _avisar(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Dieta de concentrado')),
      body: SafeArea(
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'Por cada tantos kilos de leche que da una vaca, se le da '
                    'un kilo de concentrado.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 20),
                  QuickNumberField(
                    key: const ValueKey('ajustes.dieta.campo'),
                    controller: _ctrl,
                    labelText: 'Kilos de leche por kilo de concentrado',
                    suffixText: 'kg',
                    onSubmitted: (_) => _guardar(),
                  ),
                  const SizedBox(height: 12),
                  _Ejemplo(controller: _ctrl),
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const ValueKey('ajustes.dieta.guardar'),
                    onPressed: _guardando ? null : _guardar,
                    child: Text(_guardando ? 'Guardando…' : 'Guardar'),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Traduce el número a algo que se entienda sin sacar la cuenta. Se escribe
/// "3" y abajo dice qué significa para una vaca de verdad.
class _Ejemplo extends StatelessWidget {
  const _Ejemplo({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, valor, _) {
        final kg = double.tryParse(valor.text.trim().replaceAll(',', '.'));
        final texto = (kg == null || kg <= 0)
            ? 'Escribí un número mayor que cero.'
            : 'Con esto, una vaca que da 18 L come '
                  '${(18 / kg).toStringAsFixed(1)} kg de concentrado.';
        return Text(
          texto,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
        );
      },
    );
  }
}
