import 'package:flutter/material.dart';

import '../app/etiqueta_animal.dart';
import '../data/domain/grupos.dart';
import '../data/domain/semana.dart';
import '../data/local/database.dart';
import '../hoja_vida/hoja_vida_screen.dart';
import '../services.dart';
import 'acciones_animal.dart';
import 'inventario_previa_pdf_screen.dart';

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
    required this.nombreLecheria,
  });

  final String lecheriaId;
  final String usuarioId;

  /// Para el encabezado del PDF: una hoja suelta tiene que decir de qué finca
  /// es.
  final String nombreLecheria;

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

  /// Rango de **fecha de ingreso**: cuándo entró el animal al sistema, que es
  /// lo que la app guarda sola al registrarlo.
  ///
  /// No es cuándo llegó a la finca —eso nadie se lo pregunta al ganadero— sino
  /// cuándo se digitó. Sirve para lo que realmente se necesita: «quiero ver
  /// las novillas que metí del 25 de julio a hoy».
  DateTimeRange? _ingreso;

  /// Lo que el usuario está viendo, ya filtrado. Es lo que se exporta.
  List<AnimalRow> _visibles = const [];

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

  Future<void> _escogerIngreso() async {
    final hoy = DateTime.now();
    final rango = await showDateRangePicker(
      context: context,
      // Cinco años para atrás alcanza de sobra: la app no existía antes.
      firstDate: DateTime(hoy.year - 5),
      // No se puede haber digitado un animal mañana.
      lastDate: DateTime(hoy.year, hoy.month, hoy.day),
      initialDateRange: _ingreso,
      helpText: 'Fecha de ingreso al sistema',
      saveText: 'Filtrar',
    );
    if (rango == null) return;
    setState(() => _ingreso = rango);
  }

  /// Deja solo los que se digitaron dentro del rango.
  ///
  /// El día del «hasta» entra completo: quien pide «del 25 de julio al 25 de
  /// setiembre» está contando los dos días, no parando a la medianoche del
  /// 25 de setiembre.
  List<AnimalRow> _delRango(List<AnimalRow> animales) {
    final rango = _ingreso;
    if (rango == null) return animales;
    final desde = DateTime(
      rango.start.year,
      rango.start.month,
      rango.start.day,
    );
    final hasta = DateTime(
      rango.end.year,
      rango.end.month,
      rango.end.day,
    ).add(const Duration(days: 1));
    return animales
        .where(
          (a) => !a.createdAt.isBefore(desde) && a.createdAt.isBefore(hasta),
        )
        .toList();
  }

  /// Los filtros puestos, escritos con todas las letras para el encabezado del
  /// PDF. Una hoja impresa sin esto no se entiende dentro de un mes.
  String _filtrosEnPalabras() {
    final rango = _ingreso;
    final texto = _busqueda.trim();
    final partes = <String>[
      if (_verBajas)
        'Animales dados de baja'
      else if (_grupo != null)
        GrupoAnimal.etiqueta(_grupo!)
      else
        'Todos los grupos',
      if (_soloProntas) 'solo vacas prontas',
      if (texto.isNotEmpty) 'que coinciden con «$texto»',
      if (rango != null)
        'ingresados al sistema del ${diaEnPalabras(rango.start)} '
            'al ${diaEnPalabras(rango.end)}',
    ];
    return partes.join(' · ');
  }

  Future<void> _exportar() async {
    if (_visibles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay animales que exportar.')),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InventarioPreviaPdfScreen(
          nombreLecheria: widget.nombreLecheria,
          animales: _visibles,
          filtros: _filtrosEnPalabras(),
          generadoEl: DateTime.now(),
        ),
      ),
    );
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
      appBar: AppBar(
        title: const Text('Inventario'),
        actions: [
          IconButton(
            key: const ValueKey('inventario.exportar'),
            tooltip: 'Exportar a PDF',
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: _exportar,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _busquedaCtrl,
              decoration: const InputDecoration(
                labelText: 'Buscar por identificador o alias',
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
                // El de fecha de ingreso no es excluyente con los otros:
                // se suma. «Novillas» + «del 25 de julio a hoy» es justo el
                // caso para el que existe.
                _ingreso == null
                    ? ActionChip(
                        key: const ValueKey('inventario.filtro.ingreso'),
                        avatar: const Icon(Icons.event_outlined, size: 18),
                        label: const Text('Fecha de ingreso'),
                        onPressed: _escogerIngreso,
                      )
                    : InputChip(
                        key: const ValueKey('inventario.filtro.ingreso'),
                        // Sin `avatar` a propósito: puesto el filtro, ese
                        // lugar lo ocupa el visto bueno, igual que en los
                        // chips de grupo.
                        selected: true,
                        label: Text(
                          'Ingresaron ${diaEnPalabras(_ingreso!.start)} - '
                          '${diaEnPalabras(_ingreso!.end)}',
                        ),
                        onPressed: _escogerIngreso,
                        onDeleted: () => setState(() => _ingreso = null),
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
                        (a) =>
                            a.identificador.toLowerCase().contains(texto) ||
                            (a.alias?.toLowerCase().contains(texto) ?? false),
                      )
                      .toList();
                }
                animales = _delRango(animales);
                // Se guarda acá, sin setState, para que «Exportar» mande al
                // PDF exactamente la lista que el usuario tiene enfrente.
                _visibles = animales;
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
                    final pronta = esPronta(
                      a.fechaProbableParto,
                      estadoReproductivo: a.estadoReproductivo,
                    );
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            a.identificador.length >= 2
                                ? a.identificador.substring(0, 2)
                                : a.identificador,
                          ),
                        ),
                        title: Text(etiquetaAnimal(a.identificador, a.alias)),
                        subtitle: Text(
                          [
                            if (_verBajas)
                              EstadoAnimal.etiqueta(a.estado)
                            else ...[
                              GrupoAnimal.etiqueta(a.grupo),
                              EstadoReproductivo.etiqueta(a.estadoReproductivo),
                              if (pronta) etiquetaPronta(a.fechaProbableParto),
                              // La ficha que no cuadra se dice, no se esconde:
                              // callarla dejaría a la vaca fuera de Prontas y
                              // de los partos proyectados sin que nadie sepa
                              // por qué. Se arregla palpándola.
                              if (fichaReproductivaContradictoria(
                                a.estadoReproductivo,
                                a.fechaProbableParto,
                              ))
                                'revisar preñez',
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
