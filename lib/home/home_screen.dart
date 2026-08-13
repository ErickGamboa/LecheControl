import 'package:flutter/material.dart';

import '../ajustes/curva_screen.dart';
import '../analisis/analisis_screen.dart';
import '../app/theme.dart';
import '../data/domain/grupos.dart';
import '../data/local/database.dart';
import '../finanzas/finanzas_screen.dart';
import '../inventario/inventario_screen.dart';
import '../pesa/pesa_screen.dart';
import '../sanidad/sanidad_screen.dart';
import '../services.dart';
import '../trabajo/trabajo_screen.dart';

/// Pantalla principal (Módulo 0): el conteo del hato, acceso a todos los
/// módulos en forma de grilla y el estado de sincronización. Se entra directo
/// con la lechería activa del usuario (v1: una lechería por cuenta).
///
/// Ya no lleva el aviso de "trabajando sin conexión": la app es offline-first
/// y estar sin señal es lo normal, no una anomalía que valga un cartel fijo
/// robándole espacio a la pantalla. El ícono de nube de la barra sigue
/// contando cómo va el sync para quien lo quiera ver.
///
/// La hoja de vida no tiene tarjeta propia: se llega tocando el animal en
/// Inventario (o desde Trabajo), que es el mismo destino.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.lecheria,
    required this.usuarioId,
  });

  final LecheriaRow lecheria;
  final String usuarioId;

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
            _ResumenHato(lecheriaId: lecheria.id),
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
                        // Un poco más anchas que altas: adentro solo va el
                        // ícono y el nombre. Cuadradas quedaban medio vacías
                        // y, al llenar la pantalla, el centrado vertical no
                        // se notaba.
                        childAspectRatio: 1.15,
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

/// Cuántos animales hay en cada grupo, arriba de los módulos.
///
/// Es lo primero que se pregunta el ganadero al abrir la app, y hasta ahora
/// había que entrar a Inventario para saberlo.
class _ResumenHato extends StatelessWidget {
  const _ResumenHato({required this.lecheriaId});

  final String lecheriaId;

  /// Los cuatro grupos del hato, cada uno con su color.
  ///
  /// "En tratamiento" queda afuera a propósito: no es un grupo del hato sino
  /// una situación pasajera, y su lugar es Sanidad.
  static const _grupos = [
    (GrupoAnimal.enOrdeno, 'En ordeño', kVerdeLeche),
    (GrupoAnimal.secas, 'Secas', kAzulLeche),
    (GrupoAnimal.novillas, 'Novillas', kVerdeLeche),
    (GrupoAnimal.terneros, 'Terneros', kAmbarLeche),
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, int>>(
      stream: animalesRepo.observarConteoPorGrupo(lecheriaId),
      builder: (context, snap) {
        final conteo = snap.data;
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            LecheSpacing.lg,
            LecheSpacing.md,
            LecheSpacing.lg,
            0,
          ),
          // `IntrinsicHeight` para que los cuatro cuadritos queden del mismo
          // alto: sin esto, `stretch` no tiene contra qué estirarse (la fila
          // no tiene altura acotada) y revienta el layout.
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (codigo, etiqueta, color) in _grupos)
                  Expanded(
                    child: _ContadorGrupo(
                      valueKey: 'home.hato.$codigo',
                      etiqueta: etiqueta,
                      color: color,
                      // Mientras carga se deja el hueco en vez de escribir un
                      // cero que después salta a otro número.
                      cantidad: conteo?[codigo],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Un cuadrito por grupo: la cantidad y el nombre.
class _ContadorGrupo extends StatelessWidget {
  const _ContadorGrupo({
    required this.valueKey,
    required this.etiqueta,
    required this.color,
    required this.cantidad,
  });

  final String valueKey;
  final String etiqueta;
  final Color color;
  final int? cantidad;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Card(
      key: ValueKey(valueKey),
      margin: const EdgeInsets.symmetric(horizontal: LecheSpacing.xs),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: LecheSpacing.sm,
          vertical: LecheSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              cantidad == null ? '—' : '$cantidad',
              style: textos.headlineSmall?.copyWith(color: color),
            ),
            const SizedBox(height: 2),
            // Los nombres largos ("En ordeño") no caben en cuatro columnas a
            // tamaño normal, así que se encogen en vez de cortarse con "…":
            // un número sin saber de qué grupo es no sirve de nada.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                etiqueta,
                textAlign: TextAlign.center,
                style: textos.bodySmall,
                maxLines: 1,
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
          padding: const EdgeInsets.all(LecheSpacing.md),
          child: Column(
            // Todo al centro, horizontal y vertical: son seis tarjetas
            // iguales y alineadas al centro se leen como una grilla pareja.
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(LecheSpacing.md),
                decoration: BoxDecoration(
                  color: tinte,
                  borderRadius: BorderRadius.circular(LecheRadius.md),
                ),
                child: Icon(modulo.icono, size: 32, color: modulo.color),
              ),
              const SizedBox(height: LecheSpacing.sm),
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
