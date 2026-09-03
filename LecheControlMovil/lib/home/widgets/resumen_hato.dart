import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/domain/grupos.dart';
import '../../services.dart';

/// Cuántos animales hay en cada grupo.
///
/// Es lo primero que se pregunta el ganadero al abrir la app, y hasta antes
/// de esto había que entrar a Inventario para saberlo.
///
/// Vive aparte de `HomeScreen` porque lo usan dos distribuciones: el home del
/// teléfono y el tablero de escritorio de LecheControlWeb. El dato, el orden
/// de los grupos y los colores se deciden una sola vez, acá.
class ResumenHato extends StatelessWidget {
  const ResumenHato({super.key, required this.lecheriaId});

  final String lecheriaId;

  /// Los cuatro grupos del hato, cada uno con su color.
  ///
  /// "En tratamiento" queda afuera a propósito: no es un grupo del hato sino
  /// una situación pasajera, y su lugar es Sanidad.
  static const _grupos = [
    (GrupoAnimal.enOrdeno, 'En ordeño', kVerdeLeche),
    (GrupoAnimal.secas, 'Secas', kAzulLeche),
    (GrupoAnimal.novillas, 'Novillas', kVerdeLeche),
    (GrupoAnimal.terneros, 'Terneros', kAmbarLeche),
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, int>>(
      stream: animalesRepo.observarConteoPorGrupo(lecheriaId),
      builder: (context, snap) {
        final conteo = snap.data;
        return Padding(
          // Sin relleno arriba ni abajo a propósito: el hueco lo pone quien lo
          // usa (ver `HomeScreen.build`).
          padding: const EdgeInsets.symmetric(horizontal: LecheSpacing.lg),
          // `IntrinsicHeight` para que los cuatro cuadritos queden del mismo
          // alto: sin esto, `stretch` no tiene contra qué estirarse (la fila
          // no tiene altura acotada) y revienta el layout.
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (codigo, etiqueta, color) in _grupos)
                  Expanded(
                    child: _ContadorGrupo(
                      valueKey: 'home.hato.$codigo',
                      etiqueta: etiqueta,
                      color: color,
                      // Mientras carga se deja el hueco en vez de escribir un
                      // cero que después salta a otro número.
                      cantidad: conteo?[codigo],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Un cuadrito por grupo: la cantidad y el nombre.
class _ContadorGrupo extends StatelessWidget {
  const _ContadorGrupo({
    required this.valueKey,
    required this.etiqueta,
    required this.color,
    required this.cantidad,
  });

  final String valueKey;
  final String etiqueta;
  final Color color;
  final int? cantidad;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Card(
      key: ValueKey(valueKey),
      margin: const EdgeInsets.symmetric(horizontal: LecheSpacing.xs),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: LecheSpacing.sm,
          vertical: LecheSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              cantidad == null ? '—' : '$cantidad',
              style: textos.headlineSmall?.copyWith(color: color),
            ),
            const SizedBox(height: 2),
            // Los nombres largos ("En ordeño") no caben en cuatro columnas a
            // tamaño normal, así que se encogen en vez de cortarse con "…":
            // un número sin saber de qué grupo es no sirve de nada.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                etiqueta,
                textAlign: TextAlign.center,
                style: textos.bodySmall,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
