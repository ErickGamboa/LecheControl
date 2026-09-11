/// Las tres formas de arreglar un animal mal registrado: corregirle la ficha,
/// devolverlo al hato si se dio de baja al equivocado y eliminarlo si nunca
/// debió existir.
///
/// Viven acá y no dentro de una pantalla porque las usan dos —Inventario y la
/// Hoja de vida—, y tienen que preguntar y explicar exactamente lo mismo en
/// las dos.
library;

import 'package:flutter/material.dart';

import '../app/formato.dart';
import '../app/widgets/acciones_fila.dart';
import '../data/domain/grupos.dart';
import '../data/local/database.dart';
import '../data/repositories/animales_repository.dart';
import '../services.dart';

/// Abre la ficha del animal para corregirla. Devuelve si se guardó algo.
Future<bool> corregirFichaAnimal(BuildContext context, AnimalRow animal) async {
  final guardado = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _FichaAnimalSheet(animal: animal),
  );
  return guardado == true;
}

/// Devuelve al hato un animal dado de baja por error.
Future<bool> devolverAlHato(BuildContext context, AnimalRow animal) async {
  final confirmado = await showDialog<bool>(
    context: context,
    builder: (contextoDialogo) => AlertDialog(
      icon: const Icon(Icons.undo),
      title: const Text('Devolver al hato'),
      content: Text(
        '${animal.identificador} figura como '
        '${EstadoAnimal.etiqueta(animal.estado).toLowerCase()}. Vuelve al '
        'inventario como activo y se borra la baja de su hoja de vida, porque '
        'esa baja no pasó.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(contextoDialogo, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const ValueKey('animal.devolverAlHato.aceptar'),
          onPressed: () => Navigator.pop(contextoDialogo, true),
          child: const Text('Devolver al hato'),
        ),
      ],
    ),
  );
  if (confirmado != true) return false;
  await animalesRepo.deshacerBaja(animal.id);
  sincronizarSiSePuede();
  return true;
}

/// Elimina un animal registrado por error.
///
/// Si el animal ya tiene historia —un evento, una pesa, una cría— no se
/// elimina y se dice por qué: ese ya vivió en la finca, y lo que corresponde
/// es darlo de baja.
Future<bool> eliminarAnimal(BuildContext context, AnimalRow animal) async {
  final historia = await animalesRepo.historiaDe(animal.id);
  if (!context.mounted) return false;

  if (historia.eventos > 0 || historia.pesas > 0 || historia.crias > 0) {
    final tiene = [
      if (historia.eventos > 0)
        '${historia.eventos} ${historia.eventos == 1 ? 'evento' : 'eventos'} '
            'en su hoja de vida',
      if (historia.pesas > 0)
        '${historia.pesas} ${historia.pesas == 1 ? 'pesa' : 'pesas'} de leche',
      if (historia.crias > 0)
        '${historia.crias} ${historia.crias == 1 ? 'cría' : 'crías'}',
    ].join(', ');
    await showDialog<void>(
      context: context,
      builder: (contextoDialogo) => AlertDialog(
        icon: const Icon(Icons.info_outline),
        title: const Text('Este animal ya tiene historia'),
        content: Text(
          '${animal.identificador} tiene $tiene. Un animal que ya trabajó en '
          'la finca no se borra: se da de baja, y así queda en el historial '
          'con el motivo.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(contextoDialogo),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
    return false;
  }

  final comprado =
      animal.origen == OrigenAnimal.comprado && (animal.precioCompra ?? 0) > 0;
  final confirmado = await confirmarEliminar(
    context,
    titulo: 'Eliminar el animal',
    queSeVa:
        '${animal.identificador} · ${Sexo.etiqueta(animal.sexo)} · '
        '${GrupoAnimal.etiqueta(animal.grupo)}.',
    advertencia: comprado
        ? 'Se va también el gasto de ${colones(animal.precioCompra!)} que la '
              'app anotó en Finanzas por su compra.'
        : 'Todavía no tiene eventos ni pesas, así que no se pierde nada de la '
              'finca.',
  );
  if (!confirmado) return false;
  try {
    await animalesRepo.eliminarAnimal(animal.id);
  } on AnimalConHistoriaException {
    return false;
  }
  sincronizarSiSePuede();
  return true;
}

/// La ficha del animal, para arreglar lo que se digitó mal al registrarlo.
///
/// El grupo no está acá a propósito: cambiarlo es un movimiento del hato y se
/// hace desde Trabajo, que además lo deja anotado en la hoja de vida. Acá se
/// corrigen errores de dedo, no se mueven animales.
class _FichaAnimalSheet extends StatefulWidget {
  const _FichaAnimalSheet({required this.animal});

  final AnimalRow animal;

  @override
  State<_FichaAnimalSheet> createState() => _FichaAnimalSheetState();
}

class _FichaAnimalSheetState extends State<_FichaAnimalSheet> {
  late final TextEditingController _identCtrl = TextEditingController(
    text: widget.animal.identificador,
  );
  late final TextEditingController _precioCtrl = TextEditingController(
    text: widget.animal.precioCompra == null
        ? ''
        : widget.animal.precioCompra!.toStringAsFixed(0),
  );
  late String _sexo = widget.animal.sexo;
  late String _origen = widget.animal.origen;
  late DateTime _fechaCompra =
      widget.animal.fechaCompra ?? widget.animal.createdAt;
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _identCtrl.dispose();
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
      await animalesRepo.editarAnimal(
        animalId: widget.animal.id,
        identificador: identificador,
        sexo: _sexo,
        origen: _origen,
        precioCompra: _origen == OrigenAnimal.comprado
            ? double.tryParse(_precioCtrl.text.replaceAll(',', '.'))
            : null,
        fechaCompra: _origen == OrigenAnimal.comprado ? _fechaCompra : null,
      );
      sincronizarSiSePuede();
      if (mounted) Navigator.pop(context, true);
    } on AnimalDuplicadoException {
      setState(() {
        _error = 'Ya hay otro animal con ese identificador';
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
              'Corregir la ficha',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('animal.ficha.identificador'),
              controller: _identCtrl,
              decoration: const InputDecoration(
                labelText: 'Identificador',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text('Sexo', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              key: const ValueKey('animal.ficha.sexo'),
              segments: [
                for (final s in Sexo.todos)
                  ButtonSegment(value: s, label: Text(Sexo.etiqueta(s))),
              ],
              selected: {_sexo},
              onSelectionChanged: (s) => setState(() => _sexo = s.first),
            ),
            const SizedBox(height: 16),
            Text('Origen', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              key: const ValueKey('animal.ficha.origen'),
              segments: [
                for (final o in OrigenAnimal.todos)
                  ButtonSegment(value: o, label: Text(OrigenAnimal.etiqueta(o))),
              ],
              selected: {_origen},
              onSelectionChanged: (s) => setState(() => _origen = s.first),
            ),
            if (_origen == OrigenAnimal.comprado) ...[
              const SizedBox(height: 16),
              TextField(
                key: const ValueKey('animal.ficha.precio'),
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
                  '${_fechaCompra.day}/${_fechaCompra.month}/'
                  '${_fechaCompra.year}',
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
              const SizedBox(height: 4),
              Text(
                'El gasto de «Compra de ganado» que la app anotó en Finanzas '
                'se corrige junto con esto.',
                style: Theme.of(context).textTheme.bodySmall,
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
              key: const ValueKey('animal.ficha.guardar'),
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
