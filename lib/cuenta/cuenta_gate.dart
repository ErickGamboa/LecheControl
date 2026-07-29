import 'package:flutter/material.dart';

import '../data/local/database.dart';
import '../data/repositories/lecherias_repository.dart';
import '../home/home_screen.dart';
import '../services.dart';
import 'suscripcion_screen.dart';
import 'suspendida_screen.dart';

/// Decide, una vez con sesión iniciada, qué pantalla mostrar:
///   - cuenta suspendida por el admin (`estado != 'activa'`) → SuspendidaScreen.
///   - prueba gratis vencida y todavía sin licencia pagada → SuscripcionScreen.
///   - sin lechería todavía (primera vez) → formulario mínimo para crearla.
///   - en cualquier otro caso → HomeScreen con la lechería activa (spec:
///     "una lechería activa", se entra directo, sin lista de fincas).
/// Es reactivo: cuando el admin la reactiva o le asigna un plan (y se
/// sincroniza), la pantalla cambia sola.
class CuentaGate extends StatefulWidget {
  const CuentaGate({
    super.key,
    required this.usuarioId,
    required this.sinConexion,
  });

  final String usuarioId;
  final bool sinConexion;

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
        // Mientras no conocemos la cuenta (aún sin sincronizar), dejamos
        // entrar; el home dispara el sync y, si corresponde, se bloqueará
        // al recibir el dato.
        if (cuenta != null) {
          if (cuenta.estado != 'activa') {
            return const SuspendidaScreen();
          }
          final fin = cuenta.pruebaTermina;
          if (cuenta.plan != 'invitado' &&
              fin != null &&
              fin.isBefore(DateTime.now())) {
            return const SuscripcionScreen();
          }
        } else if (!widget.sinConexion) {
          // Online pero todavía no bajó la cuenta: esperamos el sync en
          // vez de ofrecer crear lechería (eso falla con LicenciaNoDisponible).
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
        );
      },
    );
  }
}

/// Sub-gate: espera a que exista la lechería activa del usuario (creándola
/// si es la primera vez) y luego muestra el home.
class _LecheriaGate extends StatelessWidget {
  const _LecheriaGate({required this.usuarioId, required this.sinConexion});

  final String usuarioId;
  final bool sinConexion;

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
        return HomeScreen(
          lecheria: lecheria,
          usuarioId: usuarioId,
          sinConexion: sinConexion,
        );
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
    } on LicenciaNoDisponibleException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Conectate a internet una vez para activar tu cuenta.',
            ),
          ),
        );
      }
    } on LimiteLecheriasException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tu plan ${e.planNombre} permite ${e.limite} lechería(s).',
            ),
          ),
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
