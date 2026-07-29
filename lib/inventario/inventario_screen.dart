import 'package:flutter/material.dart';

import '../data/domain/grupos.dart';
import '../data/local/database.dart';
import '../hoja_vida/hoja_vida_screen.dart';
import '../services.dart';

/// Inventario del hato (Módulo 2): lista de animales activos con búsqueda y
/// filtro por grupo, acceso a la hoja de vida y baja rápida.
class InventarioScreen extends StatefulWidget {
  const InventarioScreen({
    super.key,
    required this.lecheriaId,
    required this.usuarioId,
  });

  final String lecheriaId;
  final String usuarioId;

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  String? _grupo;
  final _busquedaCtrl = TextEditingController();
  String _busqueda = '';

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  Future<void> _bajaRapida(AnimalRow animal) async {
    String motivo = MotivoBaja.venta;
    final precioCtrl = TextEditingController();
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Text('Dar de baja a ${animal.identificador}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<String>(
                segments: [
                  for (final m in MotivoBaja.todos)
                    ButtonSegment(
                      value: m,
                      label: Text(MotivoBaja.etiqueta(m)),
                    ),
                ],
                selected: {motivo},
                onSelectionChanged: (s) => setState(() => motivo = s.first),
              ),
              if (motivo == MotivoBaja.venta) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: precioCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Precio de venta',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Confirmar baja'),
            ),
          ],
        ),
      ),
    );
    if (confirmado != true) return;
    await animalesRepo.registrarBaja(
      animalId: animal.id,
      lecheriaId: widget.lecheriaId,
      motivo: motivo,
      precioVenta: double.tryParse(precioCtrl.text.replaceAll(',', '.')),
      registradoPor: widget.usuarioId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventario')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _busquedaCtrl,
              decoration: const InputDecoration(
                labelText: 'Buscar por identificador',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _busqueda = v),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text('Todos'),
                    selected: _grupo == null,
                    onSelected: (_) => setState(() => _grupo = null),
                  ),
                ),
                for (final g in GrupoAnimal.todos)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(GrupoAnimal.etiqueta(g)),
                      selected: _grupo == g,
                      onSelected: (_) => setState(() => _grupo = g),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<List<AnimalRow>>(
              stream: animalesRepo.observarInventario(
                widget.lecheriaId,
                grupo: _grupo,
                busqueda: _busqueda,
              ),
              builder: (context, snapshot) {
                final animales = snapshot.data ?? const [];
                if (animales.isEmpty) {
                  return const Center(
                    child: Text('No hay animales con ese filtro.'),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: animales.length,
                  itemBuilder: (context, i) {
                    final a = animales[i];
                    final enRetiro =
                        a.retiroLecheHasta != null &&
                        a.retiroLecheHasta!.isAfter(DateTime.now());
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            a.identificador.length >= 2
                                ? a.identificador.substring(0, 2)
                                : a.identificador,
                          ),
                        ),
                        title: Text(a.identificador),
                        subtitle: Text(
                          '${GrupoAnimal.etiqueta(a.grupo)} · '
                          '${EstadoReproductivo.etiqueta(a.estadoReproductivo)}'
                          '${enRetiro ? ' · En retiro' : ''}',
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'baja') _bajaRapida(a);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'baja',
                              child: Text('Dar de baja'),
                            ),
                          ],
                        ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => HojaVidaScreen(animalId: a.id),
                          ),
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
