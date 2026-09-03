import 'package:flutter/material.dart';

import '../app/widgets/pedir_identificador_dialog.dart';
import '../data/local/database.dart';
import '../services.dart';
import 'sanidad_aplicar_sheet.dart';

/// Pantalla de Sanidad (Módulo 7): catálogo de medicamentos (nombre, dosis y
/// ml del envase) y acceso rápido para aplicarlos a un animal.
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
      // Con el contexto del diálogo, no el de la pantalla: ver la nota en
      // `trabajo_screen.dart`. Con el de la pantalla, en la versión de
      // escritorio se cierra la sección en vez del diálogo.
      builder: (contextoDialogo) => AlertDialog(
        title: const Text('Eliminar medicamento'),
        content: Text('¿Eliminar "${m.nombre}" del catálogo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contextoDialogo, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(contextoDialogo, true),
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
                        subtitle: Text(descripcionMedicamento(m)),
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

/// Cómo se lee un medicamento en una lista: la dosis primero, que es lo que
/// se necesita saber a la hora de aplicarlo, y el envase después.
String descripcionMedicamento(MedicamentoRow m) {
  final partes = <String>[
    if (m.dosisAplicacion != null) m.dosisAplicacion!,
    if (m.mlEnvase != null) 'Envase de ${_sinCeros(m.mlEnvase!)} ml',
  ];
  return partes.isEmpty ? 'Sin dosis anotada' : partes.join(' · ');
}

String _sinCeros(double valor) {
  final texto = valor.toStringAsFixed(1);
  return texto.endsWith('.0') ? texto.substring(0, texto.length - 2) : texto;
}

/// Alta/edición de un medicamento del catálogo: nombre, cómo se dosifica y
/// cuántos ml trae el envase. Nada más — el costo entra por Finanzas como
/// gasto de la semana.
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
  late final _dosisCtrl = TextEditingController(
    text: widget.existente?.dosisAplicacion,
  );
  late final _mlEnvaseCtrl = TextEditingController(
    text: widget.existente?.mlEnvase == null
        ? null
        : _sinCeros(widget.existente!.mlEnvase!),
  );
  bool _guardando = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _dosisCtrl.dispose();
    _mlEnvaseCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_nombreCtrl.text.trim().isEmpty) return;
    setState(() => _guardando = true);
    final mlEnvase = double.tryParse(
      _mlEnvaseCtrl.text.trim().replaceAll(',', '.'),
    );
    if (widget.existente != null) {
      await medicamentosRepo.editarMedicamento(
        medicamentoId: widget.existente!.id,
        nombre: _nombreCtrl.text,
        dosisAplicacion: _dosisCtrl.text,
        mlEnvase: mlEnvase,
      );
    } else {
      await medicamentosRepo.crearMedicamento(
        lecheriaId: widget.lecheriaId,
        nombre: _nombreCtrl.text,
        dosisAplicacion: _dosisCtrl.text,
        mlEnvase: mlEnvase,
      );
    }
    sincronizarSiSePuede();
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
              key: const ValueKey('sanidad.medicamento.nombre'),
              controller: _nombreCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            // Texto libre y no números: en el frasco la dosis viene escrita
            // así, y así se la lee el que la aplica.
            TextField(
              key: const ValueKey('sanidad.medicamento.dosis'),
              controller: _dosisCtrl,
              decoration: const InputDecoration(
                labelText: 'Dosis de aplicación',
                hintText: '10 ml cada 50 kilos',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('sanidad.medicamento.mlEnvase'),
              controller: _mlEnvaseCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Ml del envase',
                suffixText: 'ml',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              key: const ValueKey('sanidad.medicamento.guardar'),
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
