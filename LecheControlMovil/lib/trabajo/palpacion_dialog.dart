import 'package:flutter/material.dart';

import '../app/widgets/aviso_rapido.dart';
import '../data/domain/grupos.dart';
import '../services.dart';

/// El diálogo de palpación, en su propio archivo porque se abre desde dos
/// lados: desde Trabajo, cuando se tiene la vaca enfrente, y desde la lista de
/// vacas por palpar, cuando se va bajando la hoja del veterinario.
///
/// Devuelve `true` si quedó anotada, para que el que lo abrió sepa si tiene
/// que refrescar su lista.
///
/// **Los campos cambian según el resultado, y es a propósito.** En una preñada
/// lo único que hace falta es la fecha probable de parto. En una vacía lo que
/// hace falta es lo contrario: qué le encontraron y qué le pusieron. Mostrar
/// los cuatro campos siempre obligaría a saltarse dos en cada palpación, que
/// es la forma más rápida de que nadie llene ninguno.
Future<bool> mostrarPalpacionDialog(
  BuildContext context, {
  required String animalId,
  required String lecheriaId,
  required String identificador,
  String? usuarioId,
}) async {
  var resultado = ResultadoPalpacion.preniada;
  var fechaProbableParto = DateTime.now().add(const Duration(days: 283));
  final observaciones = TextEditingController();
  final tratamiento = TextEditingController();

  try {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Text('Palpación de $identificador'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<String>(
                  segments: [
                    for (final r in ResultadoPalpacion.todos)
                      ButtonSegment(
                        value: r,
                        label: Text(ResultadoPalpacion.etiqueta(r)),
                      ),
                  ],
                  selected: {resultado},
                  onSelectionChanged: (s) =>
                      setState(() => resultado = s.first),
                ),
                if (resultado == ResultadoPalpacion.preniada) ...[
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Fecha probable de parto'),
                    subtitle: Text(
                      '${fechaProbableParto.day}/'
                      '${fechaProbableParto.month}/'
                      '${fechaProbableParto.year}',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final elegida = await showDatePicker(
                        context: dialogContext,
                        initialDate: fechaProbableParto,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 400)),
                      );
                      if (elegida != null) {
                        setState(() => fechaProbableParto = elegida);
                      }
                    },
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  TextField(
                    key: const ValueKey('palpacion.observaciones'),
                    controller: observaciones,
                    minLines: 2,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Observaciones',
                      hintText: 'Qué se le encontró (opcional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const ValueKey('palpacion.tratamiento'),
                    controller: tratamiento,
                    minLines: 1,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Tratamiento',
                      hintText: 'Qué se le aplicó (opcional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              key: const ValueKey('palpacion.guardar'),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    if (confirmado != true) return false;

    final preniada = resultado == ResultadoPalpacion.preniada;
    try {
      await eventosRepo.registrarPalpacion(
        animalId: animalId,
        lecheriaId: lecheriaId,
        resultado: resultado,
        fechaProbableParto: preniada ? fechaProbableParto : null,
        observaciones: observaciones.text,
        tratamiento: tratamiento.text,
        registradoPor: usuarioId,
      );
      if (context.mounted) {
        // El resultado y no "Palpación": lo que se quiere confirmar de un
        // vistazo es que quedó preñada, no que se hizo la palpación.
        AvisoRapido.exito(
          context,
          'Anotado: ${ResultadoPalpacion.etiqueta(resultado)}',
        );
      }
      return true;
    } catch (error, pila) {
      debugPrint('Palpación: no se pudo anotar: $error\n$pila');
      if (context.mounted) {
        AvisoRapido.fallo(context, 'No quedó anotado. Volvé a intentar.');
      }
      return false;
    }
  } finally {
    observaciones.dispose();
    tratamiento.dispose();
  }
}
