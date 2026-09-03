import 'package:flutter/material.dart';
import 'package:leche_control/app/theme.dart';
import 'package:leche_control/services.dart';

import 'modulos_escritorio.dart';

/// Ancho fijo de la barra lateral. Fijo y no proporcional: los nombres de los
/// módulos miden lo que miden, y en un monitor ancho una barra proporcional se
/// volvería una franja vacía.
const double kAnchoBarraLateral = 248;

/// La barra lateral: logo arriba, los módulos en el medio, y al pie —debajo de
/// un separador— el ajuste de métricas y cerrar sesión.
///
/// Siempre visible, nunca colapsable: por encima de 1000 px sobra el ancho, y
/// un menú que se esconde obliga a recordar dónde estaba.
class BarraLateral extends StatelessWidget {
  const BarraLateral({
    super.key,
    required this.indiceActivo,
    required this.onSeleccionar,
  });

  /// Índice dentro de [panelesEscritorio].
  final int indiceActivo;
  final ValueChanged<int> onSeleccionar;

  static final int _indiceAjustes = panelesEscritorio.indexOf(moduloAjustes);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: kAnchoBarraLateral,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          right: BorderSide(color: theme.dividerColor.withValues(alpha: 0.6)),
        ),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          children: [
            const _MarcaLateral(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: LecheSpacing.sm,
                ),
                children: [
                  for (var i = 0; i < modulosEscritorio.length; i++)
                    _ItemLateral(
                      modulo: modulosEscritorio[i],
                      activo: i == indiceActivo,
                      onTap: () => onSeleccionar(i),
                    ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: theme.dividerColor.withValues(alpha: 0.6),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: LecheSpacing.sm,
                vertical: LecheSpacing.sm,
              ),
              child: Column(
                children: [
                  _ItemLateral(
                    modulo: moduloAjustes,
                    activo: indiceActivo == _indiceAjustes,
                    onTap: () => onSeleccionar(_indiceAjustes),
                  ),
                  _ItemLateral(
                    modulo: const ModuloEscritorio(
                      clave: 'salir',
                      titulo: 'Cerrar sesión',
                      icono: Icons.logout,
                      color: kAzulLeche,
                      construir: _nunca,
                    ),
                    activo: false,
                    // La misma función que el teléfono: borra la sesión local
                    // y cierra en Supabase. No hay una versión web de esto.
                    onTap: cerrarSesion,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _nunca(Object? a, Object? b) =>
    throw StateError('Cerrar sesión no monta un panel.');

/// El logo y el nombre, arriba de todo.
class _MarcaLateral extends StatelessWidget {
  const _MarcaLateral();

  static const double _ladoLogo = 56;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final logo = Image.asset(
      'assets/logo_lechecontrol.png',
      width: _ladoLogo,
      height: _ladoLogo,
      fit: BoxFit.contain,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LecheSpacing.lg,
        LecheSpacing.xl,
        LecheSpacing.lg,
        LecheSpacing.lg,
      ),
      child: Row(
        children: [
          // El PNG es transparente y el dibujo es azul marino y verde: en modo
          // oscuro se hunde contra el fondo. Va sobre un disco claro, igual
          // que en el login del teléfono, y disco y no cuadro porque el borde
          // recto se lee como una caja pegada encima.
          if (theme.brightness == Brightness.dark)
            Container(
              width: _ladoLogo + 10,
              height: _ladoLogo + 10,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: logo,
            )
          else
            logo,
          const SizedBox(width: LecheSpacing.md),
          // Cada palabra con el color de su letra en el logo, como en el
          // login: LECHE con el azul de la "L", CONTROL con el verde de la
          // "C". Salen del esquema y no de las constantes para que en oscuro
          // usen las versiones aclaradas, que son las que se leen.
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'LECHE\n',
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                  TextSpan(
                    text: 'CONTROL',
                    style: TextStyle(color: theme.colorScheme.secondary),
                  ),
                ],
              ),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                height: 1.15,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemLateral extends StatelessWidget {
  const _ItemLateral({
    required this.modulo,
    required this.activo,
    required this.onTap,
  });

  final ModuloEscritorio modulo;
  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final oscuro = theme.brightness == Brightness.dark;

    // El módulo activo se marca con su propio color de fondo apenas teñido,
    // el mismo tinte que usan las tarjetas del teléfono.
    final fondo = activo
        ? modulo.color.withValues(alpha: oscuro ? 0.24 : 0.12)
        : Colors.transparent;
    final colorTexto = activo
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: fondo,
        borderRadius: BorderRadius.circular(LecheRadius.sm),
        child: InkWell(
          key: ValueKey('escritorio.menu.${modulo.clave}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(LecheRadius.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: LecheSpacing.md,
              vertical: LecheSpacing.md,
            ),
            child: Row(
              children: [
                Icon(
                  modulo.icono,
                  size: 22,
                  color: activo ? modulo.color : colorTexto,
                ),
                const SizedBox(width: LecheSpacing.md),
                Expanded(
                  child: Text(
                    modulo.titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorTexto,
                      fontWeight: activo ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
