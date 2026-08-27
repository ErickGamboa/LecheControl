import 'package:flutter/material.dart';

import '../theme.dart';

/// Una opción de un menú de módulo: ícono de color, título, una línea de
/// explicación y la flecha de "acá se entra".
///
/// La usan las pantallas que en vez de hacer algo preguntan primero **qué** se
/// quiere hacer (Registro de leche, Análisis). Están hechas del mismo molde a
/// propósito: son el mismo gesto en dos lugares distintos de la app.
class OpcionMenuCard extends StatelessWidget {
  const OpcionMenuCard({
    super.key,
    required this.valueKey,
    required this.icono,
    required this.color,
    required this.titulo,
    required this.detalle,
    required this.onTap,
  });

  final String valueKey;
  final IconData icono;
  final Color color;
  final String titulo;
  final String detalle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    return Card(
      key: ValueKey(valueKey),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(LecheSpacing.lg),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(LecheSpacing.md),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: oscuro ? 0.20 : 0.10),
                  borderRadius: BorderRadius.circular(LecheRadius.md),
                ),
                child: Icon(icono, size: 28, color: color),
              ),
              const SizedBox(width: LecheSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(detalle, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
