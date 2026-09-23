import 'package:flutter/material.dart';

import '../../data/domain/grupos.dart';
import '../../data/domain/servir.dart';

/// El selector de fecha de nacimiento, con lo que esa fecha significa debajo.
///
/// Vive aparte porque lo usan los dos lados: el alta de un animal nuevo y la
/// corrección de una ficha que ya existe. Sin la corrección, el hato que ya
/// está cargado nunca tendría la fecha y la lista de novillas por servir
/// quedaría vacía para siempre.
///
/// **Dice la edad y qué implica, no solo la fecha.** Una fecha suelta obliga a
/// sacar la cuenta de cabeza; lo que el ganadero necesita saber es si ya tiene
/// edad de servirse o cuánto le falta.
///
/// **Y lo que implica no es lo mismo para todos.** La fecha se le pone a
/// cualquier animal —al toro y al ternero también—, pero solo a la hembra que
/// todavía no ha parido le abre la puerta de Vacas por servir. A los demás les
/// sirve para saber la edad, y eso es lo que dice el mensaje en cada caso:
/// prometerle Vacas por servir a un toro sería mentirle al ganadero.
class CampoNacimiento extends StatelessWidget {
  const CampoNacimiento({
    super.key,
    required this.valueKey,
    required this.sexo,
    required this.grupo,
    required this.fecha,
    required this.onElegida,
  });

  final String valueKey;
  final String sexo;
  final String grupo;
  final DateTime? fecha;
  final ValueChanged<DateTime?> onElegida;

  /// Si a este animal la fecha de nacimiento le sirve para entrar a Vacas por
  /// servir: la hembra que todavía no ha parido, esté en Novillas o siga
  /// anotada entre las crías. A la que ya parió la mide el último parto.
  bool get _leAbreVacasPorServir =>
      sexo == Sexo.hembra &&
      (grupo == GrupoAnimal.novillas || grupo == GrupoAnimal.terneros);

  /// Cómo se le dice a este animal, para que el mensaje suene a finca y no a
  /// formulario.
  String get _comoSeLeDice => switch (grupo) {
    GrupoAnimal.toros => 'el toro',
    GrupoAnimal.novillas => 'la novilla',
    GrupoAnimal.terneros => sexo == Sexo.hembra ? 'la ternera' : 'el ternero',
    _ => sexo == Sexo.hembra ? 'la vaca' : 'el animal',
  };

  @override
  Widget build(BuildContext context) {
    final f = fecha;
    final ahora = DateTime.now();

    String subtitulo;
    Color? color;
    if (f == null) {
      color = Colors.orange.shade800;
      subtitulo = _leAbreVacasPorServir
          ? 'Sin esta fecha $_comoSeLeDice no va a aparecer en Vacas por '
                'servir al cumplir los $mesesParaPrimerServicio meses'
          : 'Sin esta fecha no se va a saber qué edad tiene $_comoSeLeDice';
    } else {
      final meses = mesesDesde(f, hoy: ahora);
      if (!_leAbreVacasPorServir) {
        subtitulo = '${edadEnPalabras(meses)} de edad';
      } else if (!fechaPrimerServicio(f).isAfter(ahora)) {
        subtitulo =
            '${edadEnPalabras(meses)} · ya tiene edad de servirse, '
            'aparece en Vacas por servir';
      } else {
        final faltan = mesesParaPrimerServicio - meses;
        subtitulo =
            '${edadEnPalabras(meses)} · le falta'
            '${faltan == 1 ? '' : 'n'} ${edadEnPalabras(faltan)} '
            'para servirse';
      }
    }

    return ListTile(
      key: ValueKey(valueKey),
      contentPadding: EdgeInsets.zero,
      title: Text(
        f == null ? 'Sin registrar' : '${f.day}/${f.month}/${f.year}',
      ),
      subtitle: Text(subtitulo, style: TextStyle(color: color)),
      trailing: f == null
          ? const Icon(Icons.calendar_today)
          : IconButton(
              tooltip: 'Quitar la fecha',
              icon: const Icon(Icons.close),
              onPressed: () => onElegida(null),
            ),
      onTap: () async {
        final elegida = await showDatePicker(
          context: context,
          initialDate: f ?? DateTime(ahora.year - 1, ahora.month, ahora.day),
          // Quince años atrás porque acá ya no solo hay novillas: un toro de
          // monta o una vaca vieja pasan de largo los cinco años, y con un
          // tope corto no habría forma de anotarles la fecha.
          firstDate: DateTime(ahora.year - 15),
          lastDate: ahora,
        );
        if (elegida != null) onElegida(elegida);
      },
    );
  }
}
