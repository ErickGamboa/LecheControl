import 'package:flutter/material.dart';
import 'package:leche_control/app/theme.dart';
import 'package:leche_control/data/sync/sync_service.dart';
import 'package:leche_control/services.dart';

/// Alto de la barra superior del escritorio.
const double kAltoBarraSuperior = 56;

/// La barra superior: dónde estoy a la izquierda, cómo va la sincronización a
/// la derecha.
///
/// A propósito **no** es un `AppBar`. Cada módulo trae el suyo —con su título
/// y sus botones, los del teléfono— justo debajo. Esta franja es el marco de
/// la ventana, no el encabezado del módulo, y se ve distinta para que se lea
/// como tal: más baja, con el fondo de la barra lateral y una línea abajo.
class BarraSuperior extends StatelessWidget {
  const BarraSuperior({
    super.key,
    required this.nombreLecheria,
    required this.tituloModulo,
  });

  final String nombreLecheria;
  final String tituloModulo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: kAltoBarraSuperior,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.6)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: LecheSpacing.lg),
      child: Row(
        children: [
          // Dónde estoy: la lechería y, después del separador, el módulo.
          // La lechería en gris y el módulo en negro porque lo que cambia al
          // navegar es el módulo, y es lo que hay que poder leer de un ojeada.
          Flexible(
            child: Text(
              nombreLecheria,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: LecheSpacing.sm),
            child: Icon(
              Icons.chevron_right,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Flexible(
            flex: 2,
            child: Text(
              tituloModulo,
              key: const ValueKey('escritorio.dondeEstoy'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          const _EstadoSync(),
        ],
      ),
    );
  }
}

/// Cómo va la sincronización, en texto y no solo en un ícono: en un monitor
/// sobra el ancho, y "Subiendo 3 de 12…" dice mucho más que una nube.
///
/// Es solo informativo. No lleva botón de "sincronizar ahora" —regla del
/// `AGENTS.md` del móvil—: la app sube todo sola al guardar, al recuperar la
/// señal y cada dos minutos si quedó algo, así que el botón únicamente
/// serviría para hacer dudar de si hay que apretarlo.
class _EstadoSync extends StatelessWidget {
  const _EstadoSync();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<bool>(
      valueListenable: estadoConexion.hayConexion,
      builder: (context, hayConexion, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: syncService.sincronizando,
          builder: (context, sincronizando, _) {
            return ValueListenableBuilder<SyncProgreso>(
              valueListenable: syncService.progreso,
              builder: (context, avance, _) {
                final (icono, texto, color) = switch ((
                  hayConexion,
                  sincronizando,
                  avance.activo,
                )) {
                  (false, _, _) => (
                    Icons.cloud_off_outlined,
                    'Sin conexión',
                    theme.colorScheme.onSurfaceVariant,
                  ),
                  (true, true, true) => (
                    Icons.sync,
                    'Subiendo ${avance.hechas} de ${avance.total}…',
                    kAmbarLeche,
                  ),
                  (true, true, false) => (
                    Icons.sync,
                    'Sincronizando…',
                    kAmbarLeche,
                  ),
                  (true, false, _) => (
                    Icons.cloud_done_outlined,
                    'Todo al día',
                    kVerdeLeche,
                  ),
                };

                return Tooltip(
                  message: hayConexion
                      ? 'La app sincroniza sola: no hay que apretar nada.'
                      : 'Lo que guardes queda en este navegador y se sube '
                            'solo cuando vuelva la señal.',
                  child: Row(
                    key: const ValueKey('escritorio.estadoSync'),
                    children: [
                      Icon(icono, size: 18, color: color),
                      const SizedBox(width: LecheSpacing.sm),
                      Text(
                        texto,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: color,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
