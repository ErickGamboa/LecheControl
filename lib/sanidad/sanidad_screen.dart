import 'package:flutter/material.dart';

import '../app/formato.dart';
import '../app/widgets/pedir_identificador_dialog.dart';
import '../data/domain/grupos.dart';
import '../data/local/database.dart';
import '../services.dart';
import 'sanidad_aplicar_sheet.dart';

/// Pantalla de Sanidad (Módulo 7): catálogo de medicamentos (con costo por
/// envase y días de retiro) y acceso rápido para aplicar uno a un animal.
class SanidadScreen extends StatefulWidget {
  const SanidadScreen({
    super.key,
    required this.lecheriaId,
    required this.usuarioId,
  });

  final String lecheriaId;
  final String usuarioId;

  @override
  State<SanidadScreen> createState() => _SanidadScreenState();
}

class _SanidadScreenState extends State<SanidadScreen> {
  Future<void> _aplicarAAnimal() async {
    final identificador = await pedirIdentificador(
      context,
      titulo: 'Identificador del animal',
    );
    if (identificador == null || identificador.trim().isEmpty) return;
    final animal = await animalesRepo.buscarPorIdentificador(
      widget.lecheriaId,
      identificador.trim(),
    );
    if (!mounted) return;
    if (animal == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Animal no encontrado')));
      return;
    }
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SanidadAplicarSheet(
        animalId: animal.id,
        lecheriaId: widget.lecheriaId,
        usuarioId: widget.usuarioId,
      ),
    );
  }

  Future<void> _crearOEditar([MedicamentoRow? existente]) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _MedicamentoSheet(
        lecheriaId: widget.lecheriaId,
        existente: existente,
      ),
    );
  }

  Future<void> _eliminar(MedicamentoRow m) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar medicamento'),
        content: Text('¿Eliminar "${m.nombre}" del catálogo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmado == true) {
      await medicamentosRepo.eliminarMedicamento(m.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sanidad')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _crearOEditar(),
        icon: const Icon(Icons.add),
        label: const Text('Medicamento'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: _aplicarAAnimal,
              icon: const Icon(Icons.nfc),
              label: const Text('Aplicar medicamento a un animal'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<MedicamentoRow>>(
              stream: medicamentosRepo.observarMedicamentos(widget.lecheriaId),
              builder: (context, snapshot) {
                final medicamentos = snapshot.data ?? const [];
                if (medicamentos.isEmpty) {
                  return const Center(
                    child: Text('Todavía no hay medicamentos registrados.'),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: medicamentos.length,
                  itemBuilder: (context, i) {
                    final m = medicamentos[i];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.medical_services_outlined),
                        title: Text(m.nombre),
                        subtitle: Text(
                          '${TipoDosisMedicamento.etiqueta(m.tipoDosis)} · '
                          'Costo envase: ${colones(m.costoEnvase)}'
                          '${m.diasRetiroLeche > 0 ? ' · ${m.diasRetiroLeche}d retiro' : ''}',
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'editar') _crearOEditar(m);
                            if (v == 'eliminar') _eliminar(m);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'editar',
                              child: Text('Editar'),
                            ),
                            PopupMenuItem(
                              value: 'eliminar',
                              child: Text('Eliminar'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicamentoSheet extends StatefulWidget {
  const _MedicamentoSheet({required this.lecheriaId, this.existente});

  final String lecheriaId;
  final MedicamentoRow? existente;

  @override
  State<_MedicamentoSheet> createState() => _MedicamentoSheetState();
}

class _MedicamentoSheetState extends State<_MedicamentoSheet> {
  late final _nombreCtrl = TextEditingController(
    text: widget.existente?.nombre,
  );
  late final _costoCtrl = TextEditingController(
    text: widget.existente?.costoEnvase.toStringAsFixed(0),
  );
  late final _mlEnvaseCtrl = TextEditingController(
    text: widget.existente?.mlEnvase?.toStringAsFixed(0),
  );
  late final _dosisFijaCtrl = TextEditingController(
    text: widget.existente?.dosisFijaMl?.toStringAsFixed(1),
  );
  late final _aplicacionesCtrl = TextEditingController(
    text: widget.existente?.aplicacionesEnvase?.toStringAsFixed(0),
  );
  late final _retiroCtrl = TextEditingController(
    text: widget.existente?.diasRetiroLeche.toString() ?? '0',
  );
  late String _tipoDosis =
      widget.existente?.tipoDosis ?? TipoDosisMedicamento.fija;
  bool _guardando = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _costoCtrl.dispose();
    _mlEnvaseCtrl.dispose();
    _dosisFijaCtrl.dispose();
    _aplicacionesCtrl.dispose();
    _retiroCtrl.dispose();
    super.dispose();
  }

  double? _num(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.'));

  Future<void> _guardar() async {
    if (_nombreCtrl.text.trim().isEmpty) return;
    setState(() => _guardando = true);
    final costo = _num(_costoCtrl) ?? 0;
    final diasRetiro = int.tryParse(_retiroCtrl.text) ?? 0;
    if (widget.existente != null) {
      await medicamentosRepo.editarMedicamento(
        medicamentoId: widget.existente!.id,
        nombre: _nombreCtrl.text,
        costoEnvase: costo,
        tipoDosis: _tipoDosis,
        mlEnvase: _tipoDosis == TipoDosisMedicamento.fija
            ? _num(_mlEnvaseCtrl)
            : null,
        dosisFijaMl: _tipoDosis == TipoDosisMedicamento.fija
            ? _num(_dosisFijaCtrl)
            : null,
        aplicacionesEnvase: _tipoDosis == TipoDosisMedicamento.porAplicacion
            ? _num(_aplicacionesCtrl)
            : null,
        diasRetiroLeche: diasRetiro,
      );
    } else {
      await medicamentosRepo.crearMedicamento(
        lecheriaId: widget.lecheriaId,
        nombre: _nombreCtrl.text,
        costoEnvase: costo,
        tipoDosis: _tipoDosis,
        mlEnvase: _tipoDosis == TipoDosisMedicamento.fija
            ? _num(_mlEnvaseCtrl)
            : null,
        dosisFijaMl: _tipoDosis == TipoDosisMedicamento.fija
            ? _num(_dosisFijaCtrl)
            : null,
        aplicacionesEnvase: _tipoDosis == TipoDosisMedicamento.porAplicacion
            ? _num(_aplicacionesCtrl)
            : null,
        diasRetiroLeche: diasRetiro,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existente != null
                  ? 'Editar medicamento'
                  : 'Nuevo medicamento',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _costoCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Costo del envase',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: [
                for (final t in TipoDosisMedicamento.todos)
                  ButtonSegment(
                    value: t,
                    label: Text(TipoDosisMedicamento.etiqueta(t)),
                  ),
              ],
              selected: {_tipoDosis},
              onSelectionChanged: (s) => setState(() => _tipoDosis = s.first),
            ),
            const SizedBox(height: 12),
            if (_tipoDosis == TipoDosisMedicamento.fija) ...[
              TextField(
                controller: _mlEnvaseCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Ml del envase',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _dosisFijaCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Dosis habitual (ml)',
                  border: OutlineInputBorder(),
                ),
              ),
            ] else
              TextField(
                controller: _aplicacionesCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Aplicaciones que rinde el envase',
                  border: OutlineInputBorder(),
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _retiroCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Días de retiro de leche',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _guardando ? null : _guardar,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _guardando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
