import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../data/local/database.dart';
import '../gastos/gastos_screen.dart';
import '../inventario/inventario_screen.dart';
import '../pesa/pesa_screen.dart';
import '../rentabilidad/rentabilidad_screen.dart';
import '../sanidad/sanidad_screen.dart';
import '../services.dart';
import '../trabajo/trabajo_screen.dart';

/// Pantalla principal (Módulo 0): acceso a todos los módulos en forma de
/// grilla, estado de sincronización y aviso de modo sin conexión. Se entra
/// directo con la lechería activa del usuario (v1: una lechería por cuenta).
///
/// La hoja de vida no tiene tarjeta propia: se llega tocando el animal en
/// Inventario (y desde Trabajo o Rentabilidad), que es el mismo destino.
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
        onTap: () => _abrir(context, PesaScreen(lecheriaId: lecheria.id)),
      ),
      _Modulo(
        valueKey: 'home.gastos',
        icono: Icons.payments_outlined,
        titulo: 'Gastos',
        color: kAzulLeche,
        onTap: () => _abrir(context, GastosScreen(lecheriaId: lecheria.id)),
      ),
      _Modulo(
        valueKey: 'home.rentabilidad',
        icono: Icons.trending_up,
        titulo: 'Rentabilidad',
        color: kVerdeLeche,
        onTap: () =>
            _abrir(context, RentabilidadScreen(lecheriaId: lecheria.id)),
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
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1,
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
    return Card(
      key: ValueKey(modulo.valueKey),
      elevation: 1,
      child: InkWell(
        onTap: modulo.onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(modulo.icono, size: 44, color: modulo.color),
              const SizedBox(height: 12),
              Text(
                modulo.titulo,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
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
    return Container(
      width: double.infinity,
      color: Colors.amber.shade700,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: const Row(
        children: [
          Icon(Icons.cloud_off, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Trabajando sin conexión. Tus datos se guardan en el '
              'dispositivo y se sincronizan al recuperar internet.',
              style: TextStyle(color: Colors.white, fontSize: 13),
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
