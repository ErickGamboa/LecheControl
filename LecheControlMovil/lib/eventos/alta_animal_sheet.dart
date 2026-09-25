import 'package:flutter/material.dart';

import '../app/widgets/campo_nacimiento.dart';
import '../data/domain/grupos.dart';
import '../data/repositories/animales_repository.dart';
import '../services.dart';

/// Hoja para dar de alta un animal nuevo (Módulo 1 y 2): identificador, sexo,
/// grupo y origen (comprado con precio/fecha, o nacido en la finca).
class AltaAnimalSheet extends StatefulWidget {
  const AltaAnimalSheet({
    super.key,
    required this.lecheriaId,
    this.identificadorInicial,
  });

  final String lecheriaId;
  final String? identificadorInicial;

  @override
  State<AltaAnimalSheet> createState() => _AltaAnimalSheetState();
}

class _AltaAnimalSheetState extends State<AltaAnimalSheet> {
  late final TextEditingController _identCtrl = TextEditingController(
    text: widget.identificadorInicial,
  );
  final _aliasCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();
  String _sexo = Sexo.hembra;
  String _grupo = GrupoAnimal.enOrdeno;
  String _origen = OrigenAnimal.nacido;
  DateTime _fechaCompra = DateTime.now();
  DateTime? _fechaUltimoParto;
  DateTime? _fechaNacimiento;
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _identCtrl.dispose();
    _aliasCtrl.dispose();
    _precioCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final identificador = _identCtrl.text.trim();
    if (identificador.isEmpty) {
      setState(() => _error = 'Ingresá el identificador');
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await animalesRepo.altaAnimal(
        lecheriaId: widget.lecheriaId,
        identificador: identificador,
        alias: _aliasCtrl.text,
        sexo: _sexo,
        grupo: _grupo,
        origen: _origen,
        precioCompra: _origen == OrigenAnimal.comprado
            ? double.tryParse(_precioCtrl.text.replaceAll(',', '.'))
            : null,
        fechaCompra: _origen == OrigenAnimal.comprado ? _fechaCompra : null,
        fechaNacimiento: _fechaNacimiento,
        fechaUltimoParto: _grupo == GrupoAnimal.enOrdeno
            ? _fechaUltimoParto
            : null,
      );
      sincronizarSiSePuede();
      if (mounted) Navigator.pop(context, true);
    } on AnimalDuplicadoException {
      setState(() {
        _error = 'Ya existe un animal activo con ese identificador';
        _guardando = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudo guardar: $e';
        _guardando = false;
      });
    }
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
              'Registrar animal nuevo',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('trabajo.alta.identificador'),
              controller: _identCtrl,
              decoration: const InputDecoration(
                labelText: 'Identificador',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('trabajo.alta.alias'),
              controller: _aliasCtrl,
              decoration: const InputDecoration(
                labelText: 'Alias (opcional)',
                // El «para buscarla» es lo que explica para qué sirve: sin
                // eso, «alias» suena a capricho y nadie lo llena.
                helperText: 'Cómo le dicen en la finca. Sirve para buscarla.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text('Sexo', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: [
                for (final s in Sexo.todos)
                  ButtonSegment(
                    value: s,
                    label: KeyedSubtree(
                      key: ValueKey(
                        s == Sexo.hembra
                            ? 'trabajo.alta.sexoHembra'
                            : 'trabajo.alta.sexoMacho',
                      ),
                      child: Text(Sexo.etiqueta(s)),
                    ),
                  ),
              ],
              selected: {_sexo},
              // En un grupo de solo machos el sexo no se elige: ya está dicho.
              onSelectionChanged: GrupoAnimal.soloMachos.contains(_grupo)
                  ? null
                  : (s) => setState(() => _sexo = s.first),
            ),
            const SizedBox(height: 16),
            Text('Grupo', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              key: const ValueKey('trabajo.alta.grupo'),
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final g in GrupoAnimal.altaDisponibles)
                  ChoiceChip(
                    key: ValueKey('trabajo.alta.grupo.$g'),
                    label: Text(GrupoAnimal.etiqueta(g)),
                    selected: _grupo == g,
                    onSelected: (_) => setState(() {
                      _grupo = g;
                      // Un toro es macho y no hay caso en que no lo sea. Se
                      // fija solo en vez de dejar que alguien guarde un toro
                      // hembra y después haya que explicar por qué no aparece
                      // al anotar una monta.
                      if (GrupoAnimal.soloMachos.contains(g)) {
                        _sexo = Sexo.macho;
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Origen', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: [
                for (final o in OrigenAnimal.todos)
                  ButtonSegment(
                    value: o,
                    label: KeyedSubtree(
                      key: ValueKey(
                        o == OrigenAnimal.nacido
                            ? 'trabajo.alta.origenNacido'
                            : 'trabajo.alta.origenComprado',
                      ),
                      child: Text(OrigenAnimal.etiqueta(o)),
                    ),
                  ),
              ],
              selected: {_origen},
              onSelectionChanged: (s) => setState(() => _origen = s.first),
            ),
            if (_origen == OrigenAnimal.comprado) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _precioCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Precio de compra',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fecha de compra'),
                subtitle: Text(
                  '${_fechaCompra.day}/${_fechaCompra.month}/${_fechaCompra.year}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final elegida = await showDatePicker(
                    context: context,
                    initialDate: _fechaCompra,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (elegida != null) setState(() => _fechaCompra = elegida);
                },
              ),
            ],
            // Solo tiene sentido para una vaca que ya está dando leche. Sin
            // esta fecha no hay días de lactancia, y sin ellos la vaca queda
            // fuera de la comparación contra la curva en el reporte.
            if (_grupo == GrupoAnimal.enOrdeno) ...[
              const SizedBox(height: 16),
              Text(
                'Último parto',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              ListTile(
                key: const ValueKey('trabajo.alta.ultimoParto'),
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _fechaUltimoParto == null
                      ? 'Sin registrar'
                      : '${_fechaUltimoParto!.day}/${_fechaUltimoParto!.month}/'
                            '${_fechaUltimoParto!.year}',
                ),
                subtitle: Text(
                  _fechaUltimoParto == null
                      ? 'Sin esta fecha la vaca no va a tener días de '
                            'lactancia en el reporte'
                      : '${DateTime.now().difference(_fechaUltimoParto!).inDays} '
                            'días de lactancia',
                  style: TextStyle(
                    color: _fechaUltimoParto == null
                        ? Colors.orange.shade800
                        : null,
                  ),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final ahora = DateTime.now();
                  final elegida = await showDatePicker(
                    context: context,
                    initialDate: _fechaUltimoParto ?? ahora,
                    firstDate: DateTime(ahora.year - 3),
                    lastDate: ahora,
                  );
                  if (elegida != null) {
                    setState(() => _fechaUltimoParto = elegida);
                  }
                },
              ),
            ],
            // La fecha de nacimiento se le pide a todo el hato menos a la vaca
            // en ordeño, donde el dato que manda es el último parto y no
            // cuándo nació. Al toro y al ternero también: para ellos no abre
            // Vacas por servir —eso es cosa de la hembra que no ha parido—
            // pero sí es la única forma de saber qué edad tienen. El propio
            // campo ajusta el mensaje según el grupo.
            if (_grupo != GrupoAnimal.enOrdeno) ...[
              const SizedBox(height: 16),
              Text(
                'Fecha de nacimiento',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              CampoNacimiento(
                valueKey: 'trabajo.alta.nacimiento',
                sexo: _sexo,
                grupo: _grupo,
                fecha: _fechaNacimiento,
                onElegida: (f) => setState(() => _fechaNacimiento = f),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              key: const ValueKey('trabajo.alta.guardar'),
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
