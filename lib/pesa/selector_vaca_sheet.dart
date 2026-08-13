import 'package:flutter/material.dart';

import '../data/domain/curva_lactancia.dart';
import '../data/local/database.dart';
import '../services.dart';

/// Lo que devuelve el selector: una vaca del inventario o un identificador
/// suelto para pesarla como **vaca manual**.
class VacaElegida {
  const VacaElegida.delInventario(AnimalRow this.animal) : manual = null;
  const VacaElegida.manual(String this.manual) : animal = null;

  final AnimalRow? animal;
  final String? manual;
}

/// Selector de vaca para la pesa: se busca y se toca, no se digita el número.
///
/// Solo lista las que **faltan** por pesar en la sesión, así que la lista se
/// va vaciando conforme avanza la ordeña y nunca hay que acordarse de cuáles
/// ya pasaron.
Future<VacaElegida?> elegirVaca(
  BuildContext context, {
  required String lecheriaId,
  required String sesionId,
}) {
  return showModalBottomSheet<VacaElegida>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) =>
        _SelectorVacaSheet(lecheriaId: lecheriaId, sesionId: sesionId),
  );
}

class _SelectorVacaSheet extends StatefulWidget {
  const _SelectorVacaSheet({required this.lecheriaId, required this.sesionId});

  final String lecheriaId;
  final String sesionId;

  @override
  State<_SelectorVacaSheet> createState() => _SelectorVacaSheetState();
}

class _SelectorVacaSheetState extends State<_SelectorVacaSheet> {
  final _busquedaCtrl = TextEditingController();
  late Future<List<AnimalRow>> _faltantes;
  String _filtro = '';

  @override
  void initState() {
    super.initState();
    _faltantes = pesasRepo.faltantesDeSesion(
      lecheriaId: widget.lecheriaId,
      sesionId: widget.sesionId,
    );
  }

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    // El teclado tapa media lista si no se le deja su espacio.
    final tecladoAlto = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: tecladoAlto),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('¿Cuál vaca?', style: textos.titleLarge),
                  const SizedBox(height: 12),
                  TextField(
                    key: const ValueKey('selectorVaca.busqueda'),
                    controller: _busquedaCtrl,
                    autofocus: false,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Buscar por número',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _filtro.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _busquedaCtrl.clear();
                                setState(() => _filtro = '');
                              },
                            ),
                    ),
                    onChanged: (v) => setState(() => _filtro = v.trim()),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<AnimalRow>>(
                future: _faltantes,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final todas = snap.data ?? const <AnimalRow>[];
                  final filtro = _filtro.toLowerCase();
                  final vacas = filtro.isEmpty
                      ? todas
                      : todas
                            .where(
                              (a) => a.identificador.toLowerCase().contains(
                                filtro,
                              ),
                            )
                            .toList();

                  return ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      if (todas.isEmpty)
                        _Aviso(
                          icono: Icons.check_circle_outline,
                          color: colores.primary,
                          titulo: 'Ya se pesaron todas',
                          detalle:
                              'No queda ninguna vaca en ordeño sin pesar en '
                              'esta sesión.',
                        )
                      else if (vacas.isEmpty)
                        _Aviso(
                          icono: Icons.search_off,
                          color: colores.outline,
                          titulo: 'Ninguna coincide con "$_filtro"',
                          detalle:
                              'Puede que ya la pesaste, o que no esté en el '
                              'inventario.',
                        ),
                      for (final a in vacas)
                        _FilaVaca(
                          animal: a,
                          onTap: () => Navigator.pop(
                            context,
                            VacaElegida.delInventario(a),
                          ),
                        ),
                      // Salida de emergencia: una vaca que no está en el
                      // inventario no puede frenar la ordeña.
                      if (_filtro.isNotEmpty &&
                          !todas.any(
                            (a) =>
                                a.identificador.toLowerCase() ==
                                _filtro.toLowerCase(),
                          )) ...[
                        const Divider(height: 24),
                        ListTile(
                          key: const ValueKey('selectorVaca.manual'),
                          leading: CircleAvatar(
                            backgroundColor: colores.tertiaryContainer,
                            foregroundColor: colores.onTertiaryContainer,
                            child: const Icon(Icons.add),
                          ),
                          title: Text('Pesar "$_filtro" como vaca manual'),
                          subtitle: const Text(
                            'Sin ficha: se le anota la leche, pero no tiene '
                            'días de lactancia',
                          ),
                          onTap: () =>
                              Navigator.pop(context, VacaElegida.manual(_filtro)),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaVaca extends StatelessWidget {
  const _FilaVaca({required this.animal, required this.onTap});

  final AnimalRow animal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final dlac = diasLactancia(animal.fechaUltimoParto);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: colores.primaryContainer,
        foregroundColor: colores.onPrimaryContainer,
        child: Text(
          animal.identificador.length <= 3
              ? animal.identificador
              : animal.identificador.substring(0, 3),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
      title: Text(animal.identificador),
      subtitle: Text(
        dlac == null ? 'Sin parto registrado' : '$dlac días de lactancia',
      ),
      onTap: onTap,
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({
    required this.icono,
    required this.color,
    required this.titulo,
    required this.detalle,
  });

  final IconData icono;
  final Color color;
  final String titulo;
  final String detalle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        children: [
          Icon(icono, size: 48, color: color),
          const SizedBox(height: 12),
          Text(
            titulo,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            detalle,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
