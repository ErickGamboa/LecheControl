import 'package:flutter/material.dart';

import '../app/widgets/quick_number_field.dart';
import '../data/domain/grupos.dart';
import '../data/local/database.dart';
import '../services.dart';

/// Hoja para aplicar un medicamento del catálogo a un animal (Módulo 7):
/// elegir medicamento, indicar ml si es de dosis fija, y confirmar. Calcula
/// el costo y, si corresponde, deja al animal en retiro de leche.
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
  MedicamentoRow? _seleccionado;
  final _mlCtrl = TextEditingController();
  bool _guardando = false;

  @override
  void dispose() {
    _mlCtrl.dispose();
    super.dispose();
  }

  Future<void> _aplicar() async {
    final medicamento = _seleccionado;
    if (medicamento == null) return;
    setState(() => _guardando = true);
    final ml = medicamento.tipoDosis == TipoDosisMedicamento.fija
        ? double.tryParse(_mlCtrl.text.replaceAll(',', '.')) ??
              medicamento.dosisFijaMl
        : null;
    await sanidadRepo.aplicarMedicamento(
      animalId: widget.animalId,
      lecheriaId: widget.lecheriaId,
      medicamentoId: medicamento.id,
      mlAplicados: ml,
      registradoPor: widget.usuarioId,
    );
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
          final medicamentos = snapshot.data ?? const [];
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
                Text('Aplicar medicamento', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                for (final m in medicamentos)
                  RadioListTile<MedicamentoRow>(
                    value: m,
                    groupValue: _seleccionado,
                    onChanged: (v) => setState(() => _seleccionado = v),
                    title: Text(m.nombre),
                    subtitle: Text(
                      m.tipoDosis == TipoDosisMedicamento.fija
                          ? 'Dosis fija · ${m.dosisFijaMl?.toStringAsFixed(1) ?? '-'} ml'
                          : 'Por aplicación'
                                '${m.diasRetiroLeche > 0 ? ' · ${m.diasRetiroLeche} días de retiro' : ''}',
                    ),
                  ),
                if (_seleccionado?.tipoDosis == TipoDosisMedicamento.fija) ...[
                  const SizedBox(height: 8),
                  QuickNumberField(
                    controller: _mlCtrl,
                    labelText: 'Ml aplicados',
                    suffixText: 'ml',
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: (_seleccionado == null || _guardando)
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
                      : const Text('Aplicar'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
