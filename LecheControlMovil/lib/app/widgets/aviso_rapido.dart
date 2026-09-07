import 'dart:async';

import 'package:flutter/material.dart';

import '../theme.dart';

/// El check verde o la equis roja que aparece en el centro de la pantalla
/// cuando se registra un evento.
///
/// **Por qué en el centro y no en un SnackBar.** Los eventos de Trabajo se
/// anotan de pie junto a la vaca, mirando el teléfono de reojo. Un mensaje
/// abajo, chiquito y del color del tema, no se ve: el ganadero se queda sin
/// saber si el evento quedó, y en la duda vuelve a apretar. Un check grande en
/// medio de la pantalla se ve sin leer nada, y la equis roja también.
///
/// **Por qué no espera un toque.** No es una pregunta ni un mensaje que haya
/// que atender: es el acuse de recibo de algo que ya pasó. Se va solo y no
/// tapa el paso —va dentro de un [IgnorePointer]—, así que el siguiente evento
/// se puede empezar a anotar sin esperarlo.
///
/// La equis, en cambio, **sí dice qué falló**: si el evento no quedó, el
/// ganadero necesita saber si volver a intentar o si hay algo que arreglar.
abstract final class AvisoRapido {
  /// Cuánto se queda en pantalla. Alcanza para verlo de reojo y es menos de lo
  /// que toma anotar el evento siguiente.
  static const duracionExito = Duration(milliseconds: 1100);

  /// El fallo se queda más: hay que alcanzar a leer el motivo.
  static const duracionFallo = Duration(milliseconds: 2200);

  /// Se registró. [detalle] dice qué quedó anotado, p. ej. "Parto anotado".
  static void exito(BuildContext context, String detalle) =>
      _mostrar(context, detalle: detalle, bien: true);

  /// No se registró. [detalle] dice qué falló, con palabras del ganadero.
  static void fallo(BuildContext context, String detalle) =>
      _mostrar(context, detalle: detalle, bien: false);

  static void _mostrar(
    BuildContext context, {
    required String detalle,
    required bool bien,
  }) {
    // El diálogo del evento ya se cerró cuando esto sale, así que el contexto
    // puede estar desmontado. Sin este guarda, anotar un evento y salirse de
    // la pantalla en el mismo segundo revienta.
    if (!context.mounted) return;
    // `rootOverlay` para que quede encima de todo: de los diálogos que
    // queden abiertos, de las hojas de abajo y del teclado propio de la app.
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    late OverlayEntry entrada;
    entrada = OverlayEntry(
      builder: (_) => _Aviso(
        detalle: detalle,
        bien: bien,
        alTerminar: () {
          if (entrada.mounted) entrada.remove();
        },
      ),
    );
    overlay.insert(entrada);
  }
}

class _Aviso extends StatefulWidget {
  const _Aviso({
    required this.detalle,
    required this.bien,
    required this.alTerminar,
  });

  final String detalle;
  final bool bien;
  final VoidCallback alTerminar;

  @override
  State<_Aviso> createState() => _AvisoState();
}

class _AvisoState extends State<_Aviso> with SingleTickerProviderStateMixin {
  late final AnimationController _control = AnimationController(
    duration: const Duration(milliseconds: 180),
    vsync: this,
  );
  Timer? _salida;

  @override
  void initState() {
    super.initState();
    _control.forward();
    final visible = widget.bien
        ? AvisoRapido.duracionExito
        : AvisoRapido.duracionFallo;
    _salida = Timer(visible, () async {
      if (!mounted) return;
      await _control.reverse();
      widget.alTerminar();
    });
  }

  @override
  void dispose() {
    _salida?.cancel();
    _control.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.bien ? kExito : kPeligro;

    return IgnorePointer(
      child: Center(
        child: FadeTransition(
          opacity: _control,
          child: ScaleTransition(
            // Entra creciendo apenas: lo justo para que el ojo lo cace.
            scale: Tween<double>(begin: 0.85, end: 1).animate(
              CurvedAnimation(parent: _control, curve: Curves.easeOutBack),
            ),
            child: Semantics(
              liveRegion: true,
              label: '${widget.bien ? 'Registrado' : 'No se registró'}. '
                  '${widget.detalle}',
              child: Container(
                key: ValueKey(
                  widget.bien ? 'avisoRapido.exito' : 'avisoRapido.fallo',
                ),
                margin: const EdgeInsets.symmetric(
                  horizontal: LecheSpacing.xl,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: LecheSpacing.xl,
                  vertical: LecheSpacing.xl,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(LecheRadius.lg),
                  border: Border.all(color: color, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.bien ? Icons.check_circle : Icons.cancel,
                      color: color,
                      size: 72,
                    ),
                    const SizedBox(height: LecheSpacing.md),
                    Text(
                      widget.detalle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
