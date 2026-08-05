import 'package:flutter/material.dart';

import '../app/formato.dart';
import '../data/local/database.dart';
import '../services.dart';

/// Gastos y parámetros del período (Módulo 4): precio del litro, precio del
/// concentrado y umbral de secado del mes calendario actual, más la lista de
/// costos fijos (luz, salarios, agua, etc.) que se reparten entre las vacas
/// en ordeño.
class GastosScreen extends StatefulWidget {
  const GastosScreen({super.key, required this.lecheriaId});

  final String lecheriaId;

  @override
  State<GastosScreen> createState() => _GastosScreenState();
}

class _GastosScreenState extends State<GastosScreen> {
  Future<void> _editarParametros(ParametrosPeriodoRow? actual) async {
    final ahora = DateTime.now();
    final precioLitroCtrl = TextEditingController(
      text: actual?.precioLitro.toStringAsFixed(0) ?? '',
    );
    final precioConcentradoCtrl = TextEditingController(
      text: actual?.precioConcentradoKg.toStringAsFixed(0) ?? '',
    );
    final umbralCtrl = TextEditingController(
      text: actual?.umbralSecadoLitros.toStringAsFixed(1) ?? '8',
    );
    final guardar = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Parámetros de ${ahora.month}/${ahora.year}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('gastos.precioLitro'),
              controller: precioLitroCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Precio del litro de leche',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('gastos.precioConcentrado'),
              controller: precioConcentradoCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Precio del kg de concentrado',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('gastos.umbralSecado'),
              controller: umbralCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Umbral de secado (litros/día)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              key: const ValueKey('gastos.guardarParametros'),
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    if (guardar != true) return;
    await gastosRepo.upsertParametrosPeriodo(
      lecheriaId: widget.lecheriaId,
      anio: ahora.year,
      mes: ahora.month,
      precioLitro:
          double.tryParse(precioLitroCtrl.text.replaceAll(',', '.')) ?? 0,
      precioConcentradoKg:
          double.tryParse(precioConcentradoCtrl.text.replaceAll(',', '.')) ?? 0,
      umbralSecadoLitros:
          double.tryParse(umbralCtrl.text.replaceAll(',', '.')) ?? 8,
    );
    sincronizarSiSePuede();
  }

  Future<void> _agregarCostoFijo(String periodoId) async {
    final categoriaCtrl = TextEditingController();
    final montoCtrl = TextEditingController();
    final guardar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo costo fijo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const ValueKey('gastos.costo.categoria'),
              controller: categoriaCtrl,
              decoration: const InputDecoration(
                labelText: 'Categoría (ej. Luz, Salario)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('gastos.costo.monto'),
              controller: montoCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Monto',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const ValueKey('gastos.costo.guardar'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
    if (guardar != true || categoriaCtrl.text.trim().isEmpty) return;
    await gastosRepo.addCostoFijo(
      lecheriaId: widget.lecheriaId,
      periodoId: periodoId,
      categoria: categoriaCtrl.text,
      monto: double.tryParse(montoCtrl.text.replaceAll(',', '.')) ?? 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gastos')),
      body: StreamBuilder<ParametrosPeriodoRow?>(
        stream: gastosRepo.observarPeriodoActual(widget.lecheriaId),
        builder: (context, snapshot) {
          final periodo = snapshot.data;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  key: const ValueKey('gastos.editarParametros'),
                  title: const Text('Parámetros del mes'),
                  subtitle: periodo == null
                      ? const Text('Todavía no configurados')
                      : Text(
                          'Litro: ${colones(periodo.precioLitro)} · '
                          'Concentrado: ${colones(periodo.precioConcentradoKg)}/kg · '
                          'Umbral secado: ${periodo.umbralSecadoLitros.toStringAsFixed(1)} L',
                        ),
                  trailing: const Icon(Icons.edit),
                  onTap: () => _editarParametros(periodo),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Costos fijos del mes',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (periodo != null)
                    TextButton.icon(
                      key: const ValueKey('gastos.agregarCosto'),
                      onPressed: () => _agregarCostoFijo(periodo.id),
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar'),
                    ),
                ],
              ),
              if (periodo == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Configurá los parámetros del mes para poder '
                      'agregar costos fijos.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                StreamBuilder<List<CostoFijoRow>>(
                  stream: gastosRepo.observarCostosFijos(periodo.id),
                  builder: (context, snapshot) {
                    final costos = snapshot.data ?? const [];
                    if (costos.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('Todavía no hay costos fijos cargados.'),
                      );
                    }
                    final total = costos.fold<double>(0, (a, c) => a + c.monto);
                    return Column(
                      children: [
                        for (final c in costos)
                          Card(
                            child: ListTile(
                              title: Text(c.categoria),
                              trailing: Text(colones(c.monto)),
                              onLongPress: () =>
                                  gastosRepo.eliminarCostoFijo(c.id),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Total: ${colones(total)}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}
