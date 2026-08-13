import 'package:flutter/material.dart';

import '../data/domain/semana.dart';
import '../data/repositories/pesas_repository.dart';
import '../services.dart';
import 'reporte_screen.dart';

/// Historial de pesas: todas las semanas que se han pesado, de la más
/// reciente a la más vieja.
///
/// Sin esta pantalla el trabajo de la semana pasada quedaba guardado pero
/// invisible: la pantalla de pesa abre siempre la sesión **de hoy**, así que
/// cada semana nueva arrancaba en blanco y no había forma de volver a ver el
/// reporte de la anterior.
class HistorialPesasScreen extends StatelessWidget {
  const HistorialPesasScreen({
    super.key,
    required this.lecheriaId,
    required this.nombreLecheria,
  });

  final String lecheriaId;
  final String nombreLecheria;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de pesas')),
      body: StreamBuilder<List<SesionConTotales>>(
        stream: pesasRepo.observarSesiones(lecheriaId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Una sesión sin vacas es la que la app abre sola al entrar a la
          // pantalla de pesa. Mostrarla como "pesa" sería mentir: no se pesó
          // nada todavía.
          final sesiones = (snap.data ?? const <SesionConTotales>[])
              .where((s) => s.vacas > 0)
              .toList();

          if (sesiones.isEmpty) {
            return const _Vacio();
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: sesiones.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) => _FilaSesion(
              datos: sesiones[i],
              lecheriaId: lecheriaId,
              nombreLecheria: nombreLecheria,
            ),
          );
        },
      ),
    );
  }
}

class _Vacio extends StatelessWidget {
  const _Vacio();

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_toggle_off,
              size: 56,
              color: colores.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Todavía no hay pesas guardadas',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Cuando peses la primera vaca, la semana va a aparecer acá.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaSesion extends StatelessWidget {
  const _FilaSesion({
    required this.datos,
    required this.lecheriaId,
    required this.nombreLecheria,
  });

  final SesionConTotales datos;
  final String lecheriaId;
  final String nombreLecheria;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    final fecha = datos.sesion.fecha;
    final abierta = !datos.sesion.cerrada;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        backgroundColor: colores.primaryContainer,
        foregroundColor: colores.onPrimaryContainer,
        child: const Icon(Icons.calendar_month_outlined),
      ),
      title: Text(
        'Semana del ${etiquetaSemana(lunesDe(fecha), domingoDe(fecha))}',
        style: textos.titleSmall,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          '${datos.vacas} vacas · ${datos.litros.toStringAsFixed(1)} L · '
          'promedio ${datos.promedio.toStringAsFixed(1)} L',
        ),
      ),
      trailing: abierta
          ? Chip(
              label: const Text('Abierta'),
              visualDensity: VisualDensity.compact,
              side: BorderSide(color: colores.outlineVariant),
            )
          : const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReporteScreen(
            lecheriaId: lecheriaId,
            sesionId: datos.sesion.id,
            nombreLecheria: nombreLecheria,
          ),
        ),
      ),
    );
  }
}
