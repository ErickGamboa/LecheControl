import 'package:flutter/material.dart';

import '../data/domain/grupos.dart';
import '../data/local/database.dart';
import '../hoja_vida/hoja_vida_screen.dart';
import '../services.dart';
import 'acciones_animal.dart';

/// Inventario del hato (Módulo 2): lista de animales activos con búsqueda y
/// filtro por grupo, acceso a la hoja de vida y baja rápida.
///
/// También es donde se arreglan los errores del alta: corregir la ficha,
/// eliminar un animal que nunca debió registrarse y —desde el filtro
/// «Bajas»— devolver al hato el que se dio de baja por equivocación.
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

  /// Las bajas no están en el inventario: es otra lista. Se mira desde acá
  /// para tener dónde deshacer una baja mal hecha.
  bool _verBajas = false;
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
    sincronizarSiSePuede();
  }

  Future<void> _accion(String cual, AnimalRow animal) async {
    switch (cual) {
      case 'ficha':
        await corregirFichaAnimal(context, animal);
      case 'baja':
        await _bajaRapida(animal);
      case 'eliminar':
        await eliminarAnimal(context, animal);
      case 'devolver':
        await devolverAlHato(context, animal);
    }
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
                  selected: _grupo == null && !_soloProntas && !_verBajas,
                  onSelected: (_) => setState(() {
                    _grupo = null;
                    _soloProntas = false;
                    _verBajas = false;
                  }),
                ),
                for (final g in GrupoAnimal.todos)
                  ChoiceChip(
                    label: Text(GrupoAnimal.etiqueta(g)),
                    selected: _grupo == g && !_verBajas,
                    onSelected: (_) => setState(() {
                      _grupo = g;
                      _verBajas = false;
                    }),
                  ),
                ChoiceChip(
                  key: const ValueKey('inventario.filtro.prontas'),
                  label: const Text('Prontas'),
                  selected: _soloProntas,
                  onSelected: (v) => setState(() {
                    _soloProntas = v;
                    if (v) _verBajas = false;
                  }),
                ),
                ChoiceChip(
                  key: const ValueKey('inventario.filtro.bajas'),
                  avatar: const Icon(Icons.history, size: 18),
                  label: const Text('Bajas'),
                  selected: _verBajas,
                  onSelected: (v) => setState(() {
                    _verBajas = v;
                    if (v) {
                      _grupo = null;
                      _soloProntas = false;
                    }
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<List<AnimalRow>>(
              stream: _verBajas
                  ? animalesRepo.observarHistorialBajas(widget.lecheriaId)
                  : animalesRepo.observarInventario(
                      widget.lecheriaId,
                      grupo: _grupo,
                      busqueda: _busqueda,
                      soloProntas: _soloProntas,
                    ),
              builder: (context, snapshot) {
                var animales = snapshot.data ?? const <AnimalRow>[];
                // El historial de bajas no filtra por texto en la consulta;
                // acá son pocos y se filtran en memoria.
                if (_verBajas && _busqueda.trim().isNotEmpty) {
                  final texto = _busqueda.trim().toLowerCase();
                  animales = animales
                      .where(
                        (a) => a.identificador.toLowerCase().contains(texto),
                      )
                      .toList();
                }
                if (animales.isEmpty) {
                  return Center(
                    child: Text(
                      _verBajas
                          ? 'Todavía no hay animales dados de baja.'
                          : _soloProntas
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
                            if (_verBajas)
                              EstadoAnimal.etiqueta(a.estado)
                            else ...[
                              GrupoAnimal.etiqueta(a.grupo),
                              EstadoReproductivo.etiqueta(a.estadoReproductivo),
                              if (pronta)
                                etiquetaPronta(a.fechaProbableParto),
                            ],
                          ].join(' · '),
                        ),
                        trailing: PopupMenuButton<String>(
                          key: ValueKey('inventario.menu.${a.id}'),
                          tooltip: 'Acciones',
                          onSelected: (v) => _accion(v, a),
                          itemBuilder: (_) => [
                            if (_verBajas)
                              const PopupMenuItem(
                                value: 'devolver',
                                child: Text('Devolver al hato'),
                              )
                            else ...[
                              const PopupMenuItem(
                                value: 'ficha',
                                child: Text('Corregir la ficha'),
                              ),
                              const PopupMenuItem(
                                value: 'baja',
                                child: Text('Dar de baja'),
                              ),
                              const PopupMenuItem(
                                value: 'eliminar',
                                child: Text('Eliminar'),
                              ),
                            ],
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
