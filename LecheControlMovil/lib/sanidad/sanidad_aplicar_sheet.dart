import 'package:flutter/material.dart';

import '../data/local/database.dart';
import '../services.dart';
import 'sanidad_screen.dart';

/// Hoja para aplicar medicamentos del catálogo a un animal (Módulo 7).
///
/// Se pueden marcar **varios**: en el corral la vaca se agarra una sola vez y
/// se le pone todo lo que lleva. No pide ml aplicados; solo muestra el nombre
/// y la dosis tal como se anotó en el catálogo ("10 ml cada 50 kilos"), que es
/// lo que el que aplica necesita leer.
class SanidadAplicarSheet extends StatefulWidget {
  const SanidadAplicarSheet({
    super.key,
    required this.animalId,
    required this.lecheriaId,
    required this.usuarioId,
  });

  final String animalId;
  final String lecheriaId;
  final String usuarioId;

  @override
  State<SanidadAplicarSheet> createState() => _SanidadAplicarSheetState();
}

class _SanidadAplicarSheetState extends State<SanidadAplicarSheet> {
  final _seleccionados = <String>{};
  bool _guardando = false;

  Future<void> _aplicar() async {
    if (_seleccionados.isEmpty) return;
    setState(() => _guardando = true);
    await sanidadRepo.aplicarMedicamentos(
      animalId: widget.animalId,
      lecheriaId: widget.lecheriaId,
      medicamentoIds: _seleccionados.toList(),
      registradoPor: widget.usuarioId,
    );
    sincronizarSiSePuede();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: StreamBuilder<List<MedicamentoRow>>(
        stream: medicamentosRepo.observarMedicamentos(widget.lecheriaId),
        builder: (context, snapshot) {
          final medicamentos = snapshot.data ?? const <MedicamentoRow>[];
          if (medicamentos.isEmpty) {
            return SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.medical_services_outlined,
                      size: 48,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 12),
                    const Text('Todavía no registraste medicamentos.'),
                    const SizedBox(height: 8),
                    Text(
                      'Registralos en el módulo de Sanidad.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            );
          }
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Aplicar medicamentos', style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  'Marcá todos los que le vas a poner.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                for (final m in medicamentos)
                  CheckboxListTile(
                    key: ValueKey('sanidad.aplicar.${m.id}'),
                    value: _seleccionados.contains(m.id),
                    onChanged: (marcado) => setState(() {
                      if (marcado == true) {
                        _seleccionados.add(m.id);
                      } else {
                        _seleccionados.remove(m.id);
                      }
                    }),
                    title: Text(m.nombre),
                    subtitle: Text(descripcionMedicamento(m)),
                  ),
                const SizedBox(height: 20),
                FilledButton(
                  key: const ValueKey('sanidad.aplicar.confirmar'),
                  onPressed: (_seleccionados.isEmpty || _guardando)
                      ? null
                      : _aplicar,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _guardando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _seleccionados.length <= 1
                              ? 'Aplicar'
                              : 'Aplicar ${_seleccionados.length}',
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
