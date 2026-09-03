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

  /// "Prontas" es un filtro aparte, no un grupo: la vaca pronta sigue estando
  /// en Secas y por eso no puede ser una opción más de la fila de grupos.
  bool _soloProntas = false;
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
          // Wrap y no un ListView horizontal: los filtros no caben en el ancho
          // de un teléfono y los últimos quedaban fuera de pantalla sin
          // ninguna pista de que había más.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Todos'),
                  selected: _grupo == null && !_soloProntas,
                  onSelected: (_) => setState(() {
                    _grupo = null;
                    _soloProntas = false;
                  }),
                ),
                for (final g in GrupoAnimal.todos)
                  ChoiceChip(
                    label: Text(GrupoAnimal.etiqueta(g)),
                    selected: _grupo == g,
                    onSelected: (_) => setState(() => _grupo = g),
                  ),
                ChoiceChip(
                  key: const ValueKey('inventario.filtro.prontas'),
                  label: const Text('Prontas'),
                  selected: _soloProntas,
                  onSelected: (v) => setState(() => _soloProntas = v),
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
                soloProntas: _soloProntas,
              ),
              builder: (context, snapshot) {
                final animales = snapshot.data ?? const [];
                if (animales.isEmpty) {
                  return Center(
                    child: Text(
                      _soloProntas
                          ? 'Ninguna vaca está pronta por ahora.'
                          : 'No hay animales con ese filtro.',
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: animales.length,
                  itemBuilder: (context, i) {
                    final a = animales[i];
                    final pronta = esPronta(a.fechaProbableParto);
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
                          [
                            GrupoAnimal.etiqueta(a.grupo),
                            EstadoReproductivo.etiqueta(a.estadoReproductivo),
                            if (pronta) etiquetaPronta(a.fechaProbableParto),
                          ].join(' · '),
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
