import 'package:flutter/material.dart';

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
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Sincronizando tu cuenta…'),
                ],
              ),
            ),
          );
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

/// Sub-gate: espera a que exista la lechería activa del usuario (creándola
/// si es la primera vez) y luego muestra el home.
class _LecheriaGate extends StatelessWidget {
  const _LecheriaGate({
    required this.usuarioId,
    required this.sinConexion,
    this.construirHome,
  });

  final String usuarioId;
  final bool sinConexion;
  final ConstructorHome? construirHome;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<LecheriaRow?>(
      stream: lecheriasRepo.observarLecheriaDeUsuario(usuarioId),
      builder: (context, snapshot) {
        final lecheria = snapshot.data;
        if (lecheria == null) {
          return _CrearLecheriaScreen(
            usuarioId: usuarioId,
            sinConexion: sinConexion,
          );
        }
        final construir = construirHome;
        if (construir != null) {
          return construir(lecheria: lecheria, usuarioId: usuarioId);
        }
        return HomeScreen(lecheria: lecheria, usuarioId: usuarioId);
      },
    );
  }
}

/// Formulario mínimo para crear la lechería la primera vez que se entra.
class _CrearLecheriaScreen extends StatefulWidget {
  const _CrearLecheriaScreen({
    required this.usuarioId,
    required this.sinConexion,
  });

  final String usuarioId;
  final bool sinConexion;

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.mensaje)),
        );
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
        title: const Text('LecheControl'),
        actions: [
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
                    '¡Bienvenido a LecheControl!',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ponele nombre a tu lechería para empezar.',
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
