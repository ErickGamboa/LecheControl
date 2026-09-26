import 'package:flutter/material.dart';

import '../app/widgets/quick_number_field.dart';
import '../data/domain/secar.dart';
import '../services.dart';

/// A cuántos días del parto le corresponde secarse a la vaca.
///
/// Es la regla con la que se arma «Vacas por secar»: la preñada a la que le
/// faltan esos días o menos entra en la lista y no sale hasta que se seque.
///
/// Se configura por finca porque el período seco no es igual en todas. Sesenta
/// y cinco días es lo que se maneja de corriente, pero con otra raza, con
/// vacas que llegan flacas al secado o con otro manejo, el número cambia.
class DiasSecarScreen extends StatefulWidget {
  const DiasSecarScreen({super.key, required this.lecheriaId});

  final String lecheriaId;

  @override
  State<DiasSecarScreen> createState() => _DiasSecarScreenState();
}

class _DiasSecarScreenState extends State<DiasSecarScreen> {
  final _ctrl = TextEditingController();
  bool _cargando = true;
  bool _guardando = false;

  /// Fuera de esto no se guarda. Por debajo de 30 el período seco no alcanza
  /// para nada, y por encima de 120 la lista se llena de vacas que todavía no
  /// hay que tocar, que es la manera más rápida de que nadie la vuelva a
  /// mirar.
  static const _minimo = 30;
  static const _maximo = 120;

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
    final dias = await curvaRepo.diasParaSecarDe(widget.lecheriaId);
    if (!mounted) return;
    setState(() {
      _ctrl.text = '$dias';
      _cargando = false;
    });
  }

  Future<void> _guardar() async {
    final dias = int.tryParse(_ctrl.text.trim());
    if (dias == null || dias < _minimo || dias > _maximo) {
      _avisar('Escribí un número de días entre $_minimo y $_maximo.');
      return;
    }

    setState(() => _guardando = true);
    await curvaRepo.editarDiasParaSecar(
      lecheriaId: widget.lecheriaId,
      dias: dias,
    );
    sincronizarSiSePuede();
    if (!mounted) return;
    setState(() => _guardando = false);
    _avisar('Listo: se avisa a los $dias días del parto.');
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
      appBar: AppBar(title: const Text('Días para secar')),
      body: SafeArea(
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'A cuántos días del parto le corresponde secarse a la '
                    'vaca.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 20),
                  QuickNumberField(
                    key: const ValueKey('ajustes.diasSecar.campo'),
                    controller: _ctrl,
                    labelText: 'Días antes del parto',
                    suffixText: 'días',
                    onSubmitted: (_) => _guardar(),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Con esto se arma «Vacas por secar»: la preñada a la que '
                    'le faltan esos días o menos aparece en la lista, y no '
                    'sale hasta que se registre el secado. Lo de corriente '
                    'son $diasParaSecarPorDefecto días; se acepta de $_minimo '
                    'a $_maximo.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const ValueKey('ajustes.diasSecar.guardar'),
                    onPressed: _guardando ? null : _guardar,
                    child: Text(_guardando ? 'Guardando…' : 'Guardar'),
                  ),
                ],
              ),
      ),
    );
  }
}
