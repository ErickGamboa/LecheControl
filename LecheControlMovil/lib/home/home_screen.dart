import 'package:flutter/material.dart';

import '../ajustes/ajustes_screen.dart';
import '../analisis/analisis_screen.dart';
import '../app/theme.dart';
import '../data/local/database.dart';
import '../data/sync/sync_service.dart';
import '../finanzas/finanzas_screen.dart';
import '../inventario/inventario_screen.dart';
import '../pesa/registro_leche_screen.dart';
import '../sanidad/sanidad_screen.dart';
import '../services.dart';
import '../trabajo/trabajo_screen.dart';
import 'widgets/produccion_semanal.dart';
import 'widgets/resumen_hato.dart';

/// Pantalla principal (Módulo 0): el conteo del hato, cómo viene la
/// producción, acceso a todos los módulos en forma de grilla y el estado de
/// sincronización. Se entra directo con la lechería activa del usuario (v1:
/// una lechería por cuenta).
///
/// El orden es a propósito: primero cuántos animales hay (estado), después
/// para dónde va la leche (tendencia) y al final qué se puede hacer
/// (acciones).
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
      // Sin esto la hoja se desborda en cuanto el diagnóstico trae un error
      // largo —un fallo de red lo hace— y sale la franja amarilla y negra.
      isScrollControlled: true,
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
        valueKey: 'home.registroLeche',
        icono: Icons.water_drop_outlined,
        titulo: 'Registro de leche',
        color: kVerdeLeche,
        onTap: () => _abrir(
          context,
          RegistroLecheScreen(
            lecheriaId: lecheria.id,
            nombreLecheria: lecheria.nombre,
          ),
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
            key: const ValueKey('home.ajustes'),
            tooltip: 'Ajuste de métricas',
            icon: const Icon(Icons.tune),
            onPressed: () =>
                _abrir(context, AjustesScreen(lecheriaId: lecheria.id)),
          ),
          IconButton(
            key: const ValueKey('home.cerrarSesion'),
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: cerrarSesion,
          ),
        ],
      ),
      body: SafeArea(
        // Todo el aire vertical lo reparte el `spaceEvenly`: queda el mismo
        // hueco encima del conteo, entre el conteo y la grilla, y debajo de
        // la grilla. Así el conteo queda centrado entre la barra y los
        // módulos, y los módulos centrados en lo que sobra —en vez de que el
        // conteo quede pegado arriba con todo el aire abajo.
        //
        // Va dentro de un scroll porque en una pantalla chica (o con la letra
        // del sistema en grande) las seis tarjetas no caben, y es mejor que se
        // pueda bajar a que se recorten. Ahí no sobra alto, los huecos se
        // cierran solos y el `minHeight` deja de mandar.
        child: LayoutBuilder(
          builder: (context, restricciones) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: restricciones.maxHeight),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ResumenHato(lecheriaId: lecheria.id),
                  ProduccionSemanal(
                    lecheriaId: lecheria.id,
                    nombreLecheria: lecheria.nombre,
                  ),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    // Solo a los lados: el alto lo pone el reparto de arriba,
                    // si además llevara relleno vertical los huecos dejarían
                    // de verse iguales.
                    padding: const EdgeInsets.symmetric(
                      horizontal: LecheSpacing.lg,
                    ),
                    crossAxisCount: 2,
                    mainAxisSpacing: LecheSpacing.md,
                    crossAxisSpacing: LecheSpacing.md,
                    // Bastante más anchas que altas: adentro solo va el ícono
                    // y el nombre, y lo que se les recorta de alto es lo que
                    // gana el gráfico, que sí tiene qué mostrar ahí.
                    childAspectRatio: 1.3,
                    children: [for (final m in modulos) _ModuloCard(modulo: m)],
                  ),
                ],
              ),
            ),
          ),
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
    // El color del módulo tiñe apenas el fondo: distingue las tarjetas de un
    // vistazo sin convertir la pantalla en un semáforo.
    final tinte = modulo.color.withValues(alpha: 0.10);

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
                padding: const EdgeInsets.all(LecheSpacing.sm),
                decoration: BoxDecoration(
                  color: tinte,
                  borderRadius: BorderRadius.circular(LecheRadius.md),
                ),
                child: Icon(modulo.icono, size: 32, color: modulo.color),
              ),
              const SizedBox(height: LecheSpacing.sm),
              // En una sola línea, encogiéndose si hace falta. Partir
              // "Registro de leche" en dos renglones le pedía a la tarjeta un
              // alto que ya no tiene: ese espacio se lo llevó el gráfico.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  modulo.titulo,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lo que la hoja de la nube necesita saber para decir la verdad completa:
/// qué falta subir, qué está trabado, y **cuándo fue la última vez que bajó
/// algo** —que es lo que faltaba—.
class _EstadoSync {
  const _EstadoSync({
    required this.pendientes,
    required this.trabadas,
    required this.ultimaBajada,
    required this.diagnostico,
  });

  final int pendientes;
  final int trabadas;
  final DateTime? ultimaBajada;
  final String diagnostico;
}

/// Una línea de la explicación: el nombre del botón en negrita y qué hace.
class _QueHace extends StatelessWidget {
  const _QueHace(this.boton, this.queHace);

  final String boton;
  final String queHace;

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$boton: ',
            style: estilo?.copyWith(fontWeight: FontWeight.w600),
          ),
          TextSpan(text: queHace),
        ],
      ),
      style: estilo,
    );
  }
}

String _haceCuanto(DateTime cuando) {
  final d = DateTime.now().difference(cuando);
  if (d.inMinutes < 1) return 'hace un momento';
  if (d.inMinutes < 60) return 'hace ${d.inMinutes} min';
  if (d.inHours < 24) {
    return d.inHours == 1 ? 'hace 1 hora' : 'hace ${d.inHours} horas';
  }
  return d.inDays == 1 ? 'hace 1 día' : 'hace ${d.inDays} días';
}

class _SyncStatusSheet extends StatefulWidget {
  const _SyncStatusSheet({required this.lecheriaId});

  final String lecheriaId;

  @override
  State<_SyncStatusSheet> createState() => _SyncStatusSheetState();
}

class _SyncStatusSheetState extends State<_SyncStatusSheet> {
  late Future<_EstadoSync> _estadoFuture;
  bool _rebajando = false;

  @override
  void initState() {
    super.initState();
    // Abrir esta hoja **sincroniza**. Antes solo mostraba números: tocar la
    // nube no disparaba nada, así que el único gesto que el ganadero asocia
    // con "actualizame esto" no actualizaba nada.
    //
    // Pero se muestra primero y se sincroniza después, **en ese orden**. Al
    // revés, sin señal la hoja se quedaba en «Revisando…» casi un minuto —los
    // reintentos y el tiempo límite de cada petición—, y justo ahí es cuando
    // uno la abre para entender qué pasa. Lo que ya se sabe se enseña de una;
    // cuando la sincronización termina, se refresca.
    _estadoFuture = _leer();
    _sincronizarYRefrescar();
  }

  Future<void> _sincronizarYRefrescar() async {
    await sincronizarSiSePuede();
    if (mounted) setState(() => _estadoFuture = _leer());
  }

  Future<_EstadoSync> _leer() async {
    return _EstadoSync(
      pendientes: (await syncService.pendientesPorTabla()).values.fold<int>(
        0,
        (a, b) => a + b,
      ),
      trabadas: (await syncService.fallos()).length,
      ultimaBajada: (await syncService.estadoPorTabla())
          .map((e) => e.ultimaSincronizacionOk)
          .whereType<DateTime>()
          .fold<DateTime?>(
            null,
            (mayor, f) => mayor == null || f.isAfter(mayor) ? f : mayor,
          ),
      diagnostico: await diagnosticoDeSync(),
    );
  }

  Future<void> _volverABajarTodo() async {
    setState(() => _rebajando = true);
    try {
      await volverABajarTodo();
    } finally {
      if (mounted) {
        setState(() {
          _rebajando = false;
          _estadoFuture = _leer();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      // Scroll y tope de alto: el diagnóstico puede traer el mensaje entero de
      // un error de red, y nada de esta hoja puede quedar fuera de la pantalla
      // —menos que nada los botones, que son lo único accionable—.
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SingleChildScrollView(
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
                // Con el total, "sincronizando" deja de ser un giro sin fin y
                // pasa a decir cuánto falta.
                ValueListenableBuilder<SyncProgreso>(
                  valueListenable: syncService.progreso,
                  builder: (context, avance, _) => ValueListenableBuilder<bool>(
                    valueListenable: syncService.sincronizando,
                    builder: (context, sincronizando, _) => Text(switch ((
                      sincronizando,
                      avance.activo,
                    )) {
                      (true, true) =>
                        'Subiendo ${avance.hechas} de ${avance.total}…',
                      (true, false) => 'Sincronizando…',
                      // Antes decía "Todo al día", y podía decirlo llevando
                      // días de atraso: solo miraba las subidas. Lo que está
                      // al día y lo que no se detalla abajo.
                      _ => 'No hay nada subiendo en este momento.',
                    }),
                  ),
                ),
                const SizedBox(height: 8),
                FutureBuilder<_EstadoSync>(
                  future: _estadoFuture,
                  builder: (context, snapshot) {
                    final e = snapshot.data;
                    if (e == null) return const Text('Revisando…');
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Cambios pendientes por subir: ${e.pendientes}'),
                        const SizedBox(height: 4),
                        // Lo de abajo es lo que faltaba: "Todo al día" solo miraba
                        // las SUBIDAS, así que podía decirlo llevando días de
                        // atraso en lo que tenía que bajar.
                        Text(
                          e.ultimaBajada == null
                              ? 'Todavía no ha bajado nada del servidor.'
                              : 'Última bajada: ${_haceCuanto(e.ultimaBajada!)}',
                        ),
                        if (e.trabadas > 0) ...[
                          const SizedBox(height: 8),
                          Text(
                            e.trabadas == 1
                                ? 'Hay 1 cambio que no logra subir.'
                                : 'Hay ${e.trabadas} cambios que no logran subir.',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          e.diagnostico,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  estadoConexion.hayConexion.value
                      ? 'Hay conexión a internet.'
                      : 'Sin conexión a internet.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: LecheSpacing.lg),
                // El botón vuelve. Se había quitado con el argumento de que "la
                // app sincroniza sola", y para las bajadas eso no era cierto.
                FilledButton.icon(
                  key: const ValueKey('sync.ahora'),
                  onPressed: _rebajando ? null : _sincronizarYRefrescar,
                  icon: const Icon(Icons.sync),
                  label: const Text('Sincronizar ahora'),
                ),
                const SizedBox(height: 4),
                // La salida que antes solo daba desinstalar la app.
                TextButton.icon(
                  key: const ValueKey('sync.volverABajarTodo'),
                  onPressed: _rebajando ? null : _volverABajarTodo,
                  icon: _rebajando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_download_outlined),
                  label: Text(
                    _rebajando ? 'Bajando todo…' : 'Volver a bajar todo',
                  ),
                ),
                const SizedBox(height: LecheSpacing.md),
                // Los dos botones juntos y la explicación debajo: los nombres se
                // parecen y hacen cosas distintas, así que la diferencia tiene que
                // poder leerse de corrido, no salteando entre botones.
                const _QueHace(
                  'Sincronizar ahora',
                  'envía los cambios de este '
                      'teléfono y trae los de los demás. Es lo que la app hace sola '
                      'cada tanto.',
                ),
                const SizedBox(height: 6),
                const _QueHace(
                  'Volver a bajar todo',
                  'pide la información '
                      'completa al servidor, aunque este teléfono ya la tenga. Úselo '
                      'si un dato sigue viéndose mal después de sincronizar: tarda '
                      'más y no descarta nada pendiente.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
