import 'package:flutter/material.dart';

import '../alertas/alertas_screen.dart';
import '../app/theme.dart';
import '../app/widgets/scan_field.dart';
import '../data/local/database.dart';
import '../gastos/gastos_screen.dart';
import '../hoja_vida/hoja_vida_screen.dart';
import '../inventario/inventario_screen.dart';
import '../pesa/pesa_screen.dart';
import '../rentabilidad/rentabilidad_screen.dart';
import '../sanidad/sanidad_screen.dart';
import '../services.dart';
import '../trabajo/trabajo_screen.dart';

/// Pantalla principal (Módulo 0): acceso a todos los módulos en forma de
/// grilla, estado de sincronización, aviso de modo sin conexión y contador
/// de alertas pendientes. Se entra directo con la lechería activa del
/// usuario (v1: una lechería por cuenta).
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.lecheria,
    required this.usuarioId,
    required this.sinConexion,
  });

  final LecheriaRow lecheria;
  final String usuarioId;
  final bool sinConexion;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<int> _alertasFuture;

  @override
  void initState() {
    super.initState();
    _cargarAlertas();
  }

  void _cargarAlertas() {
    _alertasFuture = alertasRepo
        .generarAlertas(widget.lecheria.id)
        .then((a) => a.length);
  }

  Future<void> _abrir(Widget pantalla) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => pantalla));
    if (mounted) setState(_cargarAlertas);
  }

  Future<void> _abrirHojaVidaBuscando() async {
    final ctrl = TextEditingController();
    final focus = FocusNode();
    final identificador = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Buscar animal'),
        content: ScanField(
          controller: ctrl,
          focusNode: focus,
          labelText: 'Identificador',
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.done,
          onSubmitted: (v) => Navigator.pop(dialogContext, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, ctrl.text),
            child: const Text('Buscar'),
          ),
        ],
      ),
    );
    focus.dispose();
    if (identificador == null || identificador.trim().isEmpty) return;
    final animal = await animalesRepo.buscarPorIdentificador(
      widget.lecheria.id,
      identificador.trim(),
    );
    if (!mounted) return;
    if (animal == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Animal no encontrado')));
      return;
    }
    await _abrir(HojaVidaScreen(animalId: animal.id));
  }

  void _mostrarEstadoSync() {
    showModalBottomSheet(
      context: context,
      builder: (_) => _SyncStatusSheet(lecheriaId: widget.lecheria.id),
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
          TrabajoScreen(
            lecheriaId: widget.lecheria.id,
            usuarioId: widget.usuarioId,
          ),
        ),
      ),
      _Modulo(
        valueKey: 'home.inventario',
        icono: Icons.list_alt,
        titulo: 'Inventario',
        color: kAzulLeche,
        onTap: () => _abrir(
          InventarioScreen(
            lecheriaId: widget.lecheria.id,
            usuarioId: widget.usuarioId,
          ),
        ),
      ),
      _Modulo(
        valueKey: 'home.pesa',
        icono: Icons.water_drop_outlined,
        titulo: 'Pesa de leche',
        color: kVerdeLeche,
        onTap: () => _abrir(PesaScreen(lecheriaId: widget.lecheria.id)),
      ),
      _Modulo(
        valueKey: 'home.gastos',
        icono: Icons.payments_outlined,
        titulo: 'Gastos',
        color: kAzulLeche,
        onTap: () => _abrir(GastosScreen(lecheriaId: widget.lecheria.id)),
      ),
      _Modulo(
        valueKey: 'home.rentabilidad',
        icono: Icons.trending_up,
        titulo: 'Rentabilidad',
        color: kVerdeLeche,
        onTap: () => _abrir(RentabilidadScreen(lecheriaId: widget.lecheria.id)),
      ),
      _Modulo(
        valueKey: 'home.hojaVida',
        icono: Icons.timeline,
        titulo: 'Hoja de vida',
        color: kAzulLeche,
        onTap: _abrirHojaVidaBuscando,
      ),
      _Modulo(
        valueKey: 'home.sanidad',
        icono: Icons.medical_services_outlined,
        titulo: 'Sanidad',
        color: kVerdeLeche,
        onTap: () => _abrir(
          SanidadScreen(
            lecheriaId: widget.lecheria.id,
            usuarioId: widget.usuarioId,
          ),
        ),
      ),
      _Modulo(
        valueKey: 'home.alertas',
        icono: Icons.notifications_outlined,
        titulo: 'Alertas',
        color: kAzulLeche,
        onTap: () => _abrir(AlertasScreen(lecheriaId: widget.lecheria.id)),
        contadorFuture: _alertasFuture,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lecheria.nombre),
        actions: [
          IconButton(
            key: const ValueKey('home.syncStatus'),
            tooltip: 'Sincronización',
            onPressed: _mostrarEstadoSync,
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
            if (widget.sinConexion || !estadoConexion.hayConexion.value)
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
    this.contadorFuture,
  });

  final String valueKey;
  final IconData icono;
  final String titulo;
  final Color color;
  final VoidCallback onTap;
  final Future<int>? contadorFuture;
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
          child: Stack(
            children: [
              Column(
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
              if (modulo.contadorFuture != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: FutureBuilder<int>(
                    future: modulo.contadorFuture,
                    builder: (context, snapshot) {
                      final n = snapshot.data ?? 0;
                      if (n <= 0) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$n',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
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
