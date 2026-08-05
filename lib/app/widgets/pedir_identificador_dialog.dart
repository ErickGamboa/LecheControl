import 'package:flutter/material.dart';

import 'scan_field.dart';

/// Pide un identificador de animal (RFID o manual) en un diálogo y devuelve
/// lo ingresado, o `null` si se canceló.
///
/// El diálogo es dueño del `TextEditingController` y del `FocusNode`, y los
/// destruye en su propio `dispose()`. Eso importa: si el llamador los crea y
/// hace `dispose()` apenas retorna `showDialog`, los destruye mientras el
/// diálogo todavía está animando la salida, y el `TextField` de dentro se
/// vuelve a construir con un `FocusNode` ya muerto ("A FocusNode was used
/// after being disposed").
Future<String?> pedirIdentificador(
  BuildContext context, {
  required String titulo,
  String labelText = 'Identificador',
  String textoAceptar = 'Buscar',
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _PedirIdentificadorDialog(
      titulo: titulo,
      labelText: labelText,
      textoAceptar: textoAceptar,
    ),
  );
}

class _PedirIdentificadorDialog extends StatefulWidget {
  const _PedirIdentificadorDialog({
    required this.titulo,
    required this.labelText,
    required this.textoAceptar,
  });

  final String titulo;
  final String labelText;
  final String textoAceptar;

  @override
  State<_PedirIdentificadorDialog> createState() =>
      _PedirIdentificadorDialogState();
}

class _PedirIdentificadorDialogState extends State<_PedirIdentificadorDialog> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo),
      content: ScanField(
        controller: _ctrl,
        focusNode: _focus,
        labelText: widget.labelText,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.done,
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _ctrl.text),
          child: Text(widget.textoAceptar),
        ),
      ],
    );
  }
}
