import 'package:flutter/material.dart';

import '../ajustes/curva_screen.dart';
import '../analisis/analisis_screen.dart';
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
        color: kAmbarLeche,
        onTap: () => _abrir(context, FinanzasScreen(lecheriaId: lecheria.id)),
      ),
      _Modulo(
        valueKey: 'home.sanidad',
        icono: Icons.medical_services_outlined,
        titulo: 'Sanidad',
        color: kAzulLeche,
        onTap: () => _abrir(
          context,
          SanidadScreen(lecheriaId: lecheria.id, usuarioId: usuarioId),
        ),
      ),
      _Modulo(
        valueKey: 'home.analisis',
        icono: Icons.insights_outlined,
        titulo: 'Análisis',
        color: kVerdeLeche,
        onTap: () => _abrir(
          context,
          AnalisisScreen(
            lecheriaId: lecheria.id,
            nombreLecheria: lecheria.nombre,
          ),
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
              // Centrada en vertical, pero dentro de un scroll: en una
              // pantalla chica (o con la letra del sistema en grande) las seis
              // tarjetas no caben, y es mejor que se pueda bajar a que se
              // recorten.
              child: LayoutBuilder(
                builder: (context, restricciones) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: restricciones.maxHeight,
                    ),
                    child: Center(
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(LecheSpacing.lg),
                        crossAxisCount: 2,
                        mainAxisSpacing: LecheSpacing.md,
                        crossAxisSpacing: LecheSpacing.md,
                        // Cuadradas: adentro solo va el ícono y el nombre,
                        // centrados.
                        childAspectRatio: 1.0,
                        children: [
                          for (final m in modulos) _ModuloCard(modulo: m),
                        ],
                      ),
                    ),
                  ),
                ),
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
    required this.color,
    required this.onTap,
  });

  final String valueKey;
  final IconData icono;
  final String titulo;
  final Color color;
  final VoidCallback onTap;
}

class _ModuloCard extends StatelessWidget {
  const _ModuloCard({required this.modulo});

  final _Modulo modulo;

  @override
  Widget build(BuildContext context) {
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
            // Todo al centro, horizontal y vertical: son seis tarjetas
            // iguales y alineadas al centro se leen como una grilla pareja.
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(LecheSpacing.lg),
                decoration: BoxDecoration(
                  color: tinte,
                  borderRadius: BorderRadius.circular(LecheRadius.md),
                ),
                child: Icon(modulo.icono, size: 34, color: modulo.color),
              ),
              const SizedBox(height: LecheSpacing.md),
              Text(
                modulo.titulo,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
