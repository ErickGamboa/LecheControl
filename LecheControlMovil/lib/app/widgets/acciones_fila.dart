import 'package:flutter/material.dart';

/// Las dos formas de arreglar un dato mal digitado, siempre iguales en toda
/// la app: **tocar la fila** para corregirla y el **menú de tres puntos** para
/// corregirla o eliminarla.
///
/// El menú y no solo el deslizar: la app también corre en una computadora, y
/// ahí deslizar con el mouse no se descubre. Donde se pueda deslizar, el
/// deslizar queda como atajo del teléfono, nunca como la única salida.
class MenuFila extends StatelessWidget {
  const MenuFila({
    super.key,
    this.onEditar,
    this.onEliminar,
    this.textoEditar = 'Corregir',
    this.textoEliminar = 'Eliminar',
    this.tooltip = 'Corregir o eliminar',
  });

  /// null deja la opción fuera del menú (hay filas que se corrigen pero no se
  /// eliminan, y al revés).
  final VoidCallback? onEditar;
  final VoidCallback? onEliminar;
  final String textoEditar;
  final String textoEliminar;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    if (onEditar == null && onEliminar == null) {
      return const SizedBox.shrink();
    }
    final colores = Theme.of(context).colorScheme;
    return PopupMenuButton<String>(
      tooltip: tooltip,
      icon: const Icon(Icons.more_vert),
      onSelected: (v) {
        if (v == 'editar') onEditar?.call();
        if (v == 'eliminar') onEliminar?.call();
      },
      itemBuilder: (_) => [
        if (onEditar != null)
          PopupMenuItem(
            value: 'editar',
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.edit_outlined),
              title: Text(textoEditar),
            ),
          ),
        if (onEliminar != null)
          PopupMenuItem(
            value: 'eliminar',
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.delete_outline, color: colores.error),
              title: Text(
                textoEliminar,
                style: TextStyle(color: colores.error),
              ),
            ),
          ),
      ],
    );
  }
}

/// Pregunta antes de borrar, diciendo **qué** se va a borrar.
///
/// Un "¿Está seguro?" pelado no sirve de nada: lo que evita el error es leer
/// el dato en el mensaje ("el gasto de ₡12.000 en Concentrado") y darse cuenta
/// de que no era ese. Por eso [queSeVa] es obligatorio.
Future<bool> confirmarEliminar(
  BuildContext context, {
  required String titulo,
  required String queSeVa,
  String? advertencia,
  String textoBoton = 'Eliminar',
}) async {
  final confirmado = await showDialog<bool>(
    context: context,
    // Con el contexto del diálogo, no el de la pantalla: con el de la
    // pantalla, en la versión de escritorio se cierra el módulo entero en vez
    // del diálogo (misma nota que en `trabajo_screen.dart`).
    builder: (contextoDialogo) => AlertDialog(
      // Rojo y no el verde del tema: el icono de un borrado tiene que decir
      // lo mismo que el botón que lo hace.
      iconColor: Theme.of(contextoDialogo).colorScheme.error,
      icon: const Icon(Icons.delete_outline),
      title: Text(titulo),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(queSeVa),
          if (advertencia != null) ...[
            const SizedBox(height: 12),
            Text(
              advertencia,
              style: Theme.of(contextoDialogo).textTheme.bodySmall,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(contextoDialogo, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const ValueKey('confirmarEliminar.aceptar'),
          onPressed: () => Navigator.pop(contextoDialogo, true),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(contextoDialogo).colorScheme.error,
            foregroundColor: Theme.of(contextoDialogo).colorScheme.onError,
          ),
          child: Text(textoBoton),
        ),
      ],
    ),
  );
  return confirmado == true;
}

/// Fondo rojo que asoma al deslizar una fila hacia la izquierda.
class FondoDeslizarBorrar extends StatelessWidget {
  const FondoDeslizarBorrar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.error,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 16),
      child: Icon(
        Icons.delete,
        color: Theme.of(context).colorScheme.onError,
      ),
    );
  }
}
