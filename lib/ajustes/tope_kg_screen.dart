import 'package:flutter/material.dart';

import '../app/widgets/quick_number_field.dart';
import '../services.dart';

/// Tope de kilos de leche que la finca espera entregar en una semana.
///
/// No es un límite que la app imponga: sirve para avisar. Cuando el ingreso de
/// leche de la semana pasa del tope, la pantalla de Finanzas muestra por
/// cuántos kilos se pasó y recuerda que la planta puede castigar el precio de
/// esos kilos de más.
///
/// Dejarlo vacío quita el tope y con eso el aviso.
class TopeKgScreen extends StatefulWidget {
  const TopeKgScreen({super.key, required this.lecheriaId});

  final String lecheriaId;

  @override
  State<TopeKgScreen> createState() => _TopeKgScreenState();
}

class _TopeKgScreenState extends State<TopeKgScreen> {
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
    final tope = await curvaRepo.topeKgLecheDe(widget.lecheriaId);
    if (!mounted) return;
    setState(() {
      // Sin tope el campo arranca vacío, no en cero: cero sería un tope real
      // que haría saltar la alerta con la primera entrega.
      _ctrl.text = tope == null ? '' : _sinDecimalesInutiles(tope);
      _cargando = false;
    });
  }

  static String _sinDecimalesInutiles(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  Future<void> _guardar() async {
    final texto = _ctrl.text.trim().replaceAll(',', '.');
    final tope = texto.isEmpty ? null : double.tryParse(texto);

    if (texto.isNotEmpty && (tope == null || tope <= 0)) {
      _avisar('Escribí un número de kilos mayor que cero, o dejá el campo '
          'vacío para quitar el tope.');
      return;
    }

    setState(() => _guardando = true);
    await curvaRepo.editarTopeKgLeche(
      lecheriaId: widget.lecheriaId,
      tope: tope,
    );
    sincronizarSiSePuede();
    if (!mounted) return;
    setState(() => _guardando = false);
    _avisar(tope == null ? 'Tope quitado.' : 'Tope guardado.');
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
      appBar: AppBar(title: const Text('Tope de kg entregados')),
      body: SafeArea(
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'Cuántos kilos de leche puede entregar la finca en una '
                    'semana.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 20),
                  QuickNumberField(
                    key: const ValueKey('ajustes.topeKg.campo'),
                    controller: _ctrl,
                    labelText: 'Tope de la semana',
                    suffixText: 'kg',
                    onSubmitted: (_) => _guardar(),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Se compara contra el total de la semana, no contra cada '
                    'entrega: si la planta paga en dos tandas, se suman las '
                    'dos. Dejá el campo vacío para quitar el tope.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const ValueKey('ajustes.topeKg.guardar'),
                    onPressed: _guardando ? null : _guardar,
                    child: Text(_guardando ? 'Guardando…' : 'Guardar'),
                  ),
                ],
              ),
      ),
    );
  }
}
