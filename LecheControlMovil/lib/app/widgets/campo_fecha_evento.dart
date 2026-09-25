import 'package:flutter/material.dart';

import '../../data/domain/semana.dart';

/// El día en que pasó el evento, dentro del diálogo que lo anota.
///
/// Arranca siempre en **hoy**, que es lo que corresponde a casi todos: el que
/// tiene la vaca al lado anota lo que acaba de pasar y no toca nada. Pero
/// queda a un toque, porque media finca trabaja al revés: el peón anota en una
/// libreta y el dueño se sienta días después a digitarlo. Sin poder corregir
/// el día, todo eso entraba con la fecha equivocada —y nadie se enteraba,
/// porque en pantalla se veía igual de bien.
///
/// **Va adentro del evento y no en una barra aparte.** La hoja del peón casi
/// nunca viene ordenada por fecha: viene por animal. «4101: celo el 12,
/// servida el 14, palpada el 20» es un renglón corriente, así que dos eventos
/// del mismo animal pueden ser de dos días distintos y el día hay que poder
/// escogerlo donde se está anotando.
class CampoFechaEvento extends StatelessWidget {
  const CampoFechaEvento({
    super.key,
    required this.fecha,
    required this.onCambiar,
    this.etiqueta = 'Pasó',
  });

  final DateTime fecha;
  final ValueChanged<DateTime> onCambiar;

  /// El verbo, sin el «el»: «Pasó», «Se secó», «Parió». La preposición la
  /// pone el widget, porque cambia según el día: «Pasó **hoy**» pero «Pasó
  /// **el** 18 de setiembre».
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hoy = esHoy(fecha);
    return InkWell(
      key: const ValueKey('evento.fecha'),
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        final elegida = await pedirFechaDeEvento(context, fecha);
        if (elegida != null) onCambiar(elegida);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.event, size: 20, color: theme.colorScheme.outline),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hoy ? '$etiqueta hoy' : '$etiqueta el ${diaEnPalabras(fecha)}',
                // Cuando no es hoy, negrita y nada más. Un color de alarma
                // diría que hay algo malo, y no lo hay: anotar lo del martes
                // pasado es tan normal como anotar lo de hoy.
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: hoy ? FontWeight.normal : FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Cambiar',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// El calendario para escoger el día de un evento, con los mismos topes en
/// todos lados: nunca en el futuro —un evento que no ha pasado no se anota— y
/// hasta un año atrás, que es más de lo que alcanza cualquier hoja de apuntes
/// y evita que un dedazo mande una monta a 2019.
Future<DateTime?> pedirFechaDeEvento(
  BuildContext context,
  DateTime actual,
) async {
  final hoy = DateTime.now();
  return showDatePicker(
    context: context,
    initialDate: actual,
    firstDate: DateTime(hoy.year - 1, hoy.month, hoy.day),
    lastDate: hoy,
    helpText: 'Cuándo pasó',
  );
}
