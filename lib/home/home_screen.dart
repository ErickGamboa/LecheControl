import 'package:flutter/material.dart';

import '../ajustes/curva_screen.dart';
import '../app/theme.dart';
import '../data/local/database.dart';
import '../finanzas/finanzas_screen.dart';
import '../inventario/inventario_screen.dart';
import '../pesa/pesa_screen.dart';
import '../sanidad/sanidad_screen.dart';
import '../services.dart';
import '../trabajo/trabajo_screen.dart';

/// Pantalla principal (Módulo 0): acceso a todos los módulos en forma de
/// grilla, estado de sincronización y aviso de modo sin conexión. Se entra
/// directo con la lechería activa del usuario (v1: una lechería por cuenta).
///
/// La hoja de vida no tiene tarjeta propia: se llega tocando el animal en
/// Inventario (o desde Trabajo), que es el mismo destino.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.lecheria,
    required this.usuarioId,
    required this.sinConexion,
  });

  final LecheriaRow lecheria;
  final String usuarioId;
  final bool sinConexion;

  Future<void> _abrir(BuildContext context, Widget pantalla) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => pantalla));
  }

  void _mostrarEstadoSync(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => _SyncStatusSheet(lecheriaId: lecheria.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modulos = <_Modulo>[
      _Modulo(
        valueKey: 'home.trabajo',
        icono: Icons.nfc,
        titulo: 'Trabajo',
        detalle: 'Leer el arete y anotar en el corral',
        color: kVerdeLeche,
        onTap: () => _abrir(
          context,
          TrabajoScreen(lecheriaId: lecheria.id, usuarioId: usuarioId),
        ),
      ),
      _Modulo(
        valueKey: 'home.inventario',
        icono: Icons.list_alt,
        titulo: 'Inventario',
        detalle: 'El hato, sus fichas y sus eventos',
        color: kAzulLeche,
        onTap: () => _abrir(
          context,
          InventarioScreen(lecheriaId: lecheria.id, usuarioId: usuarioId),
        ),
      ),
      _Modulo(
        valueKey: 'home.pesa',
        icono: Icons.water_drop_outlined,
        titulo: 'Pesa de leche',
        detalle: 'Pesa semanal y reporte de producción',
        color: kVerdeLeche,
        onTap: () => _abrir(
          context,
          PesaScreen(lecheriaId: lecheria.id, nombreLecheria: lecheria.nombre),
        ),
      ),
      _Modulo(
        valueKey: 'home.finanzas',
        icono: Icons.payments_outlined,
        titulo: 'Finanzas',
        detalle: 'Ingresos, gastos y utilidad de la semana',
        color: kAmbarLeche,
        onTap: () => _abrir(context, FinanzasScreen(lecheriaId: lecheria.id)),
      ),
      _Modulo(
        valueKey: 'home.sanidad',
        icono: Icons.medical_services_outlined,
        titulo: 'Sanidad',
        detalle: 'Tratamientos y retiros de leche',
        color: kAzulLeche,
        onTap: () => _abrir(
          context,
          SanidadScreen(lecheriaId: lecheria.id, usuarioId: usuarioId),
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(lecheria.nombre),
        actions: [
          IconButton(
            key: const ValueKey('home.syncStatus'),
            tooltip: 'Sincronización',
            onPressed: () => _mostrarEstadoSync(context),
            icon: ValueListenableBuilder<bool>(
              valueListenable: syncService.sincronizando,
              builder: (context, sincronizando, _) =>
                  Icon(sincronizando ? Icons.sync : Icons.cloud_outlined),
            ),
          ),
          IconButton(
            key: const ValueKey('home.curva'),
            tooltip: 'Curva de referencia',
            icon: const Icon(Icons.tune),
            onPressed: () =>
                _abrir(context, CurvaScreen(lecheriaId: lecheria.id)),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: cerrarSesion,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (sinConexion || !estadoConexion.hayConexion.value)
              const _OfflineBanner(),
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.all(16),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                // Justo lo que necesitan ícono + título + dos líneas de
                // explicación. Más alto deja un hueco muerto en el medio de
                // cada tarjeta; más bajo corta el texto.
                childAspectRatio: 1.0,
                children: [for (final m in modulos) _ModuloCard(modulo: m)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Modulo {
  _Modulo({
    required this.valueKey,
    required this.icono,
    required this.titulo,
    required this.detalle,
    required this.color,
    required this.onTap,
  });

  final String valueKey;
  final IconData icono;
  final String titulo;

  /// Una línea que dice para qué sirve el módulo. Con cinco tarjetas iguales
  /// el título solo no alcanza para saber dónde tocar.
  final String detalle;
  final Color color;
  final VoidCallback onTap;
}

class _ModuloCard extends StatelessWidget {
  const _ModuloCard({required this.modulo});

  final _Modulo modulo;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    // El color del módulo tiñe apenas el fondo: distingue las tarjetas de un
    // vistazo sin convertir la pantalla en un semáforo.
    final tinte = modulo.color.withValues(alpha: oscuro ? 0.18 : 0.10);

    return Card(
      key: ValueKey(modulo.valueKey),
      child: InkWell(
        onTap: modulo.onTap,
        child: Padding(
          padding: const EdgeInsets.all(LecheSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            // Centrado y no `spaceBetween`: la grilla fija el alto de la
            // tarjeta, así que separar los extremos abría un hueco muerto
            // entre el ícono y el título.
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(LecheSpacing.md),
                decoration: BoxDecoration(
                  color: tinte,
                  borderRadius: BorderRadius.circular(LecheRadius.md),
                ),
                child: Icon(modulo.icono, size: 26, color: modulo.color),
              ),
              const SizedBox(height: LecheSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    modulo.titulo,
                    style: textos.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    modulo.detalle,
                    style: textos.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        LecheSpacing.lg,
        LecheSpacing.md,
        LecheSpacing.lg,
        0,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: LecheSpacing.md,
        vertical: LecheSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: kAmbarLeche.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(LecheRadius.sm),
        border: Border.all(color: kAmbarLeche.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, color: kAviso, size: 18),
          const SizedBox(width: LecheSpacing.sm),
          Expanded(
            child: Text(
              'Trabajando sin conexión. Tus datos se guardan en el '
              'dispositivo y se sincronizan al recuperar internet.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colores.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncStatusSheet extends StatefulWidget {
  const _SyncStatusSheet({required this.lecheriaId});

  final String lecheriaId;

  @override
  State<_SyncStatusSheet> createState() => _SyncStatusSheetState();
}

class _SyncStatusSheetState extends State<_SyncStatusSheet> {
  late Future<Map<String, int>> _pendientesFuture;

  @override
  void initState() {
    super.initState();
    _pendientesFuture = syncService.pendientesPorTabla();
  }

  Future<void> _sincronizarAhora() async {
    await syncService.sincronizar();
    if (!mounted) return;
    setState(() {
      _pendientesFuture = syncService.pendientesPorTabla();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Sincronización',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<bool>(
              valueListenable: syncService.sincronizando,
              builder: (context, sincronizando, _) =>
                  Text(sincronizando ? 'Sincronizando…' : 'En reposo.'),
            ),
            const SizedBox(height: 8),
            FutureBuilder<Map<String, int>>(
              future: _pendientesFuture,
              builder: (context, snapshot) {
                final total = (snapshot.data ?? const {}).values.fold<int>(
                  0,
                  (a, b) => a + b,
                );
                return Text('Cambios pendientes por subir: $total');
              },
            ),
            const SizedBox(height: 8),
            Text(
              estadoConexion.hayConexion.value
                  ? 'Hay conexión a internet.'
                  : 'Sin conexión a internet.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _sincronizarAhora,
              icon: const Icon(Icons.sync),
              label: const Text('Sincronizar ahora'),
            ),
          ],
        ),
      ),
    );
  }
}
