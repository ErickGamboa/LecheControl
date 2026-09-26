import 'dart:async';

import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../data/local/database.dart';
import '../data/repositories/lecherias_repository.dart';
import '../home/home_screen.dart';
import '../services.dart';

/// Cómo construir el home una vez que ya hay cuenta activa y lechería.
///
/// El teléfono (y la web de celular) no pasan nada y se quedan con
/// `HomeScreen`. La versión de escritorio pasa su marco —barra lateral y
/// barra superior— para envolver esas mismas pantallas, sin repetir el camino
/// de sesión, cuenta y lechería que ya resuelven estos gates: esa lógica es
/// idéntica en los tres clientes y vive una sola vez, acá.
typedef ConstructorHome =
    Widget Function({required LecheriaRow lecheria, required String usuarioId});

/// Decide, una vez con sesión iniciada, qué pantalla mostrar:
///   - sin lechería todavía (primera vez) → formulario mínimo para crearla.
///   - en cualquier otro caso → HomeScreen con la lechería activa (spec:
///     "una lechería activa", se entra directo, sin lista de fincas).
///
/// **Acá no se le cierra la puerta a nadie.** Antes este gate podía dejar al
/// ganadero afuera de sus propios datos —cuenta suspendida, prueba vencida— y
/// mandarlo a una pantalla a contactar soporte. Eso ya no existe: el que
/// inicia sesión entra a su lechería, punto.
///
/// Lo único que todavía espera es la **primera** sincronización de la cuenta,
/// y no para autorizar nada: la lechería se crea colgada de una cuenta, así
/// que hay que saber cuál es antes de ofrecer el formulario.
class CuentaGate extends StatefulWidget {
  const CuentaGate({
    super.key,
    required this.usuarioId,
    required this.sinConexion,
    this.construirHome,
  });

  final String usuarioId;
  final bool sinConexion;

  /// Ver [ConstructorHome]. En `null` se usa `HomeScreen`.
  final ConstructorHome? construirHome;

  @override
  State<CuentaGate> createState() => _CuentaGateState();
}

class _CuentaGateState extends State<CuentaGate> {
  @override
  void initState() {
    super.initState();
    // Asegurar que bajamos el estado actual de la cuenta.
    sincronizarSiSePuede();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CuentaRow?>(
      stream: cuentasRepo.observarMiCuenta(widget.usuarioId),
      builder: (context, snapshot) {
        final cuenta = snapshot.data;
        // Con conexión pero sin la cuenta bajada todavía: se espera el sync
        // en vez de ofrecer crear la lechería, porque sin cuenta la creación
        // no tiene de dónde colgarla (ver `CuentaNoSincronizadaException`).
        //
        // Sin conexión se sigue de largo: la app es offline-first y no se le
        // va a pedir internet al que está parado en el corral.
        if (cuenta == null && !widget.sinConexion) {
          return const _EsperandoCuenta();
        }
        return _LecheriaGate(
          usuarioId: widget.usuarioId,
          sinConexion: widget.sinConexion,
          construirHome: widget.construirHome,
        );
      },
    );
  }
}

/// La espera de la primera sincronización, con salida.
///
/// **Por qué tiene tanto cuidado.** Esta pantalla sale cuando el usuario ya
/// inició sesión pero todavía no llegó su fila de cuenta. Si esa fila no
/// llega nunca —le crearon el usuario en Supabase Auth pero nadie le insertó
/// la cuenta, o la red está mal—, el que la mira se queda con un girito para
/// siempre: no había reintento, no había explicación y **no había forma de
/// cerrar sesión**. Había que borrar los datos de la app para salir.
///
/// El reintento de fondo de `app_bootstrap` tampoco lo salvaba: solo corre
/// `si hayPendientes()`, y un usuario nuevo no tiene nada pendiente que
/// subir, así que nunca se disparaba.
///
/// Ahora insiste sola unas cuantas veces y, si a los [_paciencia] no llegó,
/// deja de fingir que está trabajando y ofrece las dos salidas: reintentar o
/// cerrar sesión.
class _EsperandoCuenta extends StatefulWidget {
  const _EsperandoCuenta();

  /// Cada cuánto se vuelve a pedir el sync mientras se espera.
  static const _cada = Duration(seconds: 5);

  /// Cuánto se espera antes de admitir que algo no anda.
  static const _paciencia = Duration(seconds: 20);

  /// Cada cuánto se sigue intentando **después** de avisar que falló.
  ///
  /// Se sigue intentando a propósito, más despacio: el ganadero puede estar en
  /// un punto con señal intermitente, y si la señal vuelve la pantalla se
  /// arregla sola sin que tenga que tocar nada. El aviso y los botones quedan
  /// igual, para el que no quiera esperar.
  static const _cadaDespues = Duration(seconds: 15);

  @override
  State<_EsperandoCuenta> createState() => _EsperandoCuentaState();
}

class _EsperandoCuentaState extends State<_EsperandoCuenta> {
  Timer? _reintento;
  Timer? _rendicion;
  bool _seTardo = false;

  /// Lo último que dijo el sync. Se muestra en pantalla porque en una app
  /// instalada los `debugPrint` no se ven, y sin esto ni el ganadero ni
  /// soporte tienen con qué saber qué pasó.
  String? _diagnostico;

  @override
  void initState() {
    super.initState();
    _empezarAEsperar();
  }

  void _empezarAEsperar() {
    sincronizarSiSePuede();
    _reintento?.cancel();
    _rendicion?.cancel();
    _reintento = Timer.periodic(
      _EsperandoCuenta._cada,
      (_) => sincronizarSiSePuede(),
    );
    _rendicion = Timer(_EsperandoCuenta._paciencia, () {
      if (!mounted) return;
      // Se deja de girar y se avisa: el girito eterno no informa nada. Pero
      // se sigue intentando de fondo, más despacio, para que vuelva sola
      // cuando vuelva la señal.
      _reintento?.cancel();
      _reintento = Timer.periodic(
        _EsperandoCuenta._cadaDespues,
        (_) => sincronizarSiSePuede(),
      );
      setState(() => _seTardo = true);
      // El diagnóstico se busca aparte y **sin esperarlo**: el aviso y los
      // botones tienen que estar ahí de una. Si leerlo tarda o no se puede,
      // el recuadro no sale y la pantalla sigue sirviendo igual.
      _cargarDiagnostico();
    });
  }

  Future<void> _cargarDiagnostico() async {
    final texto = await diagnosticoDeSync();
    if (mounted) setState(() => _diagnostico = texto);
  }

  void _reintentarAMano() {
    setState(() => _seTardo = false);
    _empezarAEsperar();
  }

  @override
  void dispose() {
    _reintento?.cancel();
    _rendicion?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _seTardo ? _loQueNoAnda(theme) : _esperando(theme),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _esperando(ThemeData theme) => [
    const CircularProgressIndicator(),
    const SizedBox(height: 16),
    Text('Preparando tu cuenta…', style: theme.textTheme.bodyLarge),
  ];

  List<Widget> _loQueNoAnda(ThemeData theme) => [
    Icon(Icons.cloud_off_outlined, size: 64, color: theme.colorScheme.outline),
    const SizedBox(height: 20),
    Text(
      'No pudimos preparar tu cuenta',
      textAlign: TextAlign.center,
      style: theme.textTheme.titleMedium,
    ),
    const SizedBox(height: 10),
    Text(
      'Seguimos intentando por si vuelve la señal. Si querés, probá de una '
      'vez o volvé a entrar más tarde; si sigue igual, escribinos a soporte '
      'con lo que dice el recuadro de abajo.',
      textAlign: TextAlign.center,
      style: theme.textTheme.bodyMedium,
    ),
    if (_diagnostico case final texto?) ...[
      const SizedBox(height: 16),
      // Se puede seleccionar y copiar a propósito: es lo que hay que
      // mandarle a soporte, y de un teléfono no se saca de otra forma.
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(LecheSpacing.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(LecheRadius.sm),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: SelectableText(
          texto,
          key: const ValueKey('cuenta.diagnostico'),
          style: theme.textTheme.bodySmall,
        ),
      ),
    ],
    const SizedBox(height: 24),
    FilledButton.icon(
      key: const ValueKey('cuenta.reintentar'),
      onPressed: _reintentarAMano,
      icon: const Icon(Icons.refresh),
      label: const Text('Reintentar'),
    ),
    const SizedBox(height: 8),
    // La salida que faltaba: sin esto, el que caía acá no podía ni cambiar
    // de usuario.
    TextButton.icon(
      key: const ValueKey('cuenta.cerrarSesion'),
      onPressed: cerrarSesion,
      icon: const Icon(Icons.logout),
      label: const Text('Cerrar sesión'),
    ),
  ];
}

/// Sub-gate: decide en cuál finca se entra.
///
/// Son tres casos y uno solo de ellos es nuevo:
///
/// - **Ninguna finca** (primera vez): el formulario para crearla.
/// - **Una sola finca**: se entra directo, como siempre. La inmensa mayoría de
///   las cuentas está acá, y hacerlas tocar una lista de un solo renglón en
///   cada arranque sería cobrarles un toque por una función que no usan.
/// - **Varias fincas**: la lista, para escoger. Y desde adentro se puede
///   volver a ella tocando el nombre en la barra del Inicio.
class _LecheriaGate extends StatefulWidget {
  const _LecheriaGate({
    required this.usuarioId,
    required this.sinConexion,
    this.construirHome,
  });

  final String usuarioId;
  final bool sinConexion;
  final ConstructorHome? construirHome;

  @override
  State<_LecheriaGate> createState() => _LecheriaGateState();
}

class _LecheriaGateState extends State<_LecheriaGate> {
  /// Cuál finca se escogió en esta sesión de la app. null es «todavía no
  /// escogió», que con una sola finca no obliga a nada.
  String? _elegida;

  /// Si se pidió ver la lista a propósito, tocando el nombre en la barra.
  ///
  /// Es distinto de «todavía no escogió»: con una sola finca se entra directo
  /// y el usuario igual puede querer ver la lista, sea para agregar otra o
  /// solo para mirar.
  bool _viendoLista = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<LecheriaRow>>(
      stream: lecheriasRepo.observarLecheriasDeUsuario(widget.usuarioId),
      builder: (context, snapshot) {
        final lecherias = snapshot.data;
        if (lecherias == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (lecherias.isEmpty) {
          return _CrearLecheriaScreen(
            usuarioId: widget.usuarioId,
            sinConexion: widget.sinConexion,
          );
        }

        // La elegida puede haber desaparecido —se borró en otro teléfono y
        // bajó el borrado—, así que se busca en vez de confiar en el id.
        final elegida = _elegida == null
            ? null
            : lecherias.where((l) => l.id == _elegida).firstOrNull;

        if (_viendoLista || (elegida == null && lecherias.length > 1)) {
          return _FincasScreen(
            usuarioId: widget.usuarioId,
            sinConexion: widget.sinConexion,
            lecherias: lecherias,
            onElegir: (l) => setState(() {
              _elegida = l.id;
              _viendoLista = false;
            }),
            // Solo hay a dónde volver si ya se estaba trabajando en una.
            onVolver: _viendoLista
                ? () => setState(() => _viendoLista = false)
                : null,
          );
        }

        final activa = elegida ?? lecherias.first;
        // El nombre de la barra siempre lleva a la lista. Aunque haya una
        // sola finca y no quepa otra, de ahí se la borra y se le cambia el
        // nombre, así que el camino tiene que estar.
        void volverALista() => setState(() => _viendoLista = true);

        final construir = widget.construirHome;
        if (construir != null) {
          return construir(lecheria: activa, usuarioId: widget.usuarioId);
        }
        return HomeScreen(
          lecheria: activa,
          usuarioId: widget.usuarioId,
          onCambiarFinca: volverALista,
        );
      },
    );
  }
}

/// La lista de fincas de la cuenta, para escoger en cuál se trabaja.
///
/// **Acá no se habla de cupos.** Ni cuántas fincas tiene, ni cuántas podría
/// tener, ni por qué. Lo único que cambia entre una cuenta y otra es si
/// aparece el botón de agregar: si aparece, se puede; si no, no. El ganadero
/// no tiene que entender nada más que eso.
class _FincasScreen extends StatefulWidget {
  const _FincasScreen({
    required this.usuarioId,
    required this.sinConexion,
    required this.lecherias,
    required this.onElegir,
    this.onVolver,
  });

  final String usuarioId;
  final bool sinConexion;
  final List<LecheriaRow> lecherias;
  final ValueChanged<LecheriaRow> onElegir;

  /// Volver a la finca en la que se estaba, si se llegó acá tocando el nombre
  /// en la barra. Al entrar a la app no hay nada atrás y va nulo.
  final VoidCallback? onVolver;

  @override
  State<_FincasScreen> createState() => _FincasScreenState();
}

class _FincasScreenState extends State<_FincasScreen> {
  /// Se resuelve una vez al abrir y se vuelve a resolver al agregar una.
  late Future<bool> _puedeAgregar = lecheriasRepo.puedeAgregarLecheria(
    widget.usuarioId,
  );

  /// Borrar una finca, con el nombre escrito a mano de por medio.
  ///
  /// Escribir el nombre no es un trámite: es lo único que separa un toque mal
  /// dado de perder la finca entera. Un «¿Está seguro?» con un botón rojo se
  /// contesta que sí sin leerlo; el nombre hay que copiarlo, y para copiarlo
  /// hay que mirarlo.
  Future<void> _eliminar(LecheriaRow lecheria) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmarBorrado(nombre: lecheria.nombre),
    );
    if (confirmado != true) return;

    await lecheriasRepo.eliminarLecheria(lecheria.id);
    sincronizarSiSePuede();
    if (!mounted) return;
    // Borrar libera lugar, así que el botón de agregar puede volver.
    setState(() {
      _puedeAgregar = lecheriasRepo.puedeAgregarLecheria(widget.usuarioId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${lecheria.nombre} se eliminó.')),
    );
  }

  Future<void> _agregar() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => _CrearLecheriaScreen(
          usuarioId: widget.usuarioId,
          sinConexion: widget.sinConexion,
          esLaPrimera: false,
        ),
      ),
    );
    if (mounted) {
      setState(() {
        _puedeAgregar = lecheriasRepo.puedeAgregarLecheria(widget.usuarioId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis fincas'),
        leading: widget.onVolver == null
            ? null
            : IconButton(
                key: const ValueKey('fincas.volver'),
                tooltip: 'Volver',
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onVolver,
              ),
        actions: [
          // Salirse desde acá solo tiene sentido cuando esta es la primera
          // pantalla; si se vino del tablero, el camino de vuelta es atrás.
          if (widget.onVolver == null)
            IconButton(
              tooltip: 'Cerrar sesión',
              icon: const Icon(Icons.logout),
              onPressed: cerrarSesion,
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('¿En cuál finca vas a trabajar?', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            for (final l in widget.lecherias)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  key: ValueKey('fincas.finca.${l.id}'),
                  leading: const Icon(Icons.holiday_village_outlined),
                  title: Text(
                    l.nombre,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: PopupMenuButton<String>(
                    key: ValueKey('fincas.menu.${l.id}'),
                    tooltip: 'Acciones',
                    onSelected: (_) => _eliminar(l),
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'eliminar',
                        child: Text('Eliminar finca'),
                      ),
                    ],
                  ),
                  onTap: () => widget.onElegir(l),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FutureBuilder<bool>(
        future: _puedeAgregar,
        builder: (context, snap) {
          // Mientras no se sepa, no hay botón: aparecer y desaparecer se ve
          // peor que aparecer un instante después.
          if (snap.data != true) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            key: const ValueKey('fincas.agregar'),
            onPressed: _agregar,
            icon: const Icon(Icons.add),
            label: const Text('Agregar finca'),
          );
        },
      ),
    );
  }
}

/// Pide escribir el nombre de la finca antes de borrarla.
///
/// El botón de borrar arranca apagado y solo se enciende cuando lo escrito
/// coincide con el nombre. Se comparan sin mayúsculas y sin espacios de
/// sobra: la idea es asegurarse de que la persona sabe cuál finca está
/// borrando, no ponerle una prueba de mecanografía.
class _ConfirmarBorrado extends StatefulWidget {
  const _ConfirmarBorrado({required this.nombre});

  final String nombre;

  @override
  State<_ConfirmarBorrado> createState() => _ConfirmarBorradoState();
}

class _ConfirmarBorradoState extends State<_ConfirmarBorrado> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _coincide =>
      _ctrl.text.trim().toLowerCase() == widget.nombre.trim().toLowerCase();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text('Eliminar ${widget.nombre}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Se va a borrar esta finca con todo lo que tiene adentro: sus '
            'animales, sus eventos, sus pesas y sus finanzas.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Text(
            'Esto no se puede deshacer, y también desaparece de los demás '
            'teléfonos de la cuenta.',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Para confirmar, escribí «${widget.nombre}».',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('fincas.eliminar.nombre'),
            controller: _ctrl,
            autofocus: true,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Nombre de la finca',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const ValueKey('fincas.eliminar.confirmar'),
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
          ),
          onPressed: _coincide ? () => Navigator.pop(context, true) : null,
          child: const Text('Eliminar'),
        ),
      ],
    );
  }
}

/// Formulario mínimo para crear la lechería la primera vez que se entra.
class _CrearLecheriaScreen extends StatefulWidget {
  const _CrearLecheriaScreen({
    required this.usuarioId,
    required this.sinConexion,
    this.esLaPrimera = true,
  });

  final String usuarioId;
  final bool sinConexion;

  /// Si es la finca con la que el ganadero empieza a usar la app o una que
  /// agrega después. Solo cambia lo que dice la pantalla: la bienvenida no
  /// tiene sentido la segunda vez.
  final bool esLaPrimera;

  @override
  State<_CrearLecheriaScreen> createState() => _CrearLecheriaScreenState();
}

class _CrearLecheriaScreenState extends State<_CrearLecheriaScreen> {
  final _ctrl = TextEditingController();
  bool _creando = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _crear() async {
    final nombre = _ctrl.text.trim();
    if (nombre.isEmpty) return;
    setState(() => _creando = true);
    try {
      await lecheriasRepo.crearLecheria(
        nombre: nombre,
        creadaPor: widget.usuarioId,
      );
      sincronizarSiSePuede();
      // La primera se abre sola porque el gate la ve aparecer; las demás
      // vuelven a la lista, que es de donde se entró.
      if (!widget.esLaPrimera && mounted) Navigator.of(context).pop();
    } on CuentaNoSincronizadaException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Conectate a internet una vez para sincronizar tu cuenta.',
            ),
          ),
        );
      }
    } on LimiteLecheriasException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.mensaje)));
      }
    } finally {
      if (mounted) setState(() => _creando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.esLaPrimera ? 'LecheControl' : 'Agregar finca'),
        actions: [
          if (widget.esLaPrimera)
            IconButton(
              tooltip: 'Cerrar sesión',
              icon: const Icon(Icons.logout),
              onPressed: cerrarSesion,
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.holiday_village_outlined,
                    size: 72,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.esLaPrimera
                        ? '¡Bienvenido a LecheControl!'
                        : 'Una finca más',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.esLaPrimera
                        ? 'Ponele nombre a tu lechería para empezar.'
                        : 'Ponele el nombre con el que la conocés.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    key: const ValueKey('lecheria.nombre'),
                    controller: _ctrl,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la lechería',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _crear(),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const ValueKey('lecheria.crear'),
                    onPressed: _creando ? null : _crear,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _creando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Empezar'),
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
