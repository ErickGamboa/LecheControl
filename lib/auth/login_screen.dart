import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../data/local/database.dart';
import '../services.dart';
import 'mensajes_auth.dart';

/// Pantalla de inicio de sesión. Sin auto-registro (spec Módulo 0): las
/// cuentas las crea el administrador y se las entrega al ganadero. El primer
/// login requiere internet una sola vez; después la sesión queda guardada y
/// se puede entrar sin conexión.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _cargando = false;
  bool _verPass = false;
  bool _falloRedReciente = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) return;
    final client = supabaseClientOrNull;
    if (client == null) {
      _mostrarMensaje(
        'Esta app todavía no tiene un proyecto de Supabase configurado. '
        'Pedile a soporte tus credenciales o entrá sin conexión si ya '
        'usaste esta cuenta en este dispositivo.',
        error: true,
      );
      return;
    }
    setState(() => _cargando = true);
    try {
      final auth = client.auth;
      await auth.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      final usuario = auth.currentUser;
      if (usuario != null) {
        await sesionLocalRepo.guardarUsuarioVerificado(
          usuarioId: usuario.id,
          email: usuario.email,
          nombre: usuario.userMetadata?['nombre'] as String?,
        );
      }
      _falloRedReciente = false;
      // El AuthGate detecta la sesión y cambia de pantalla solo.
    } catch (e) {
      _falloRedReciente = esErrorRedAuth(e);
      if (_falloRedReciente) {
        final entroOffline = await sesionLocalRepo.activarOfflineParaEmail(
          _emailCtrl.text,
        );
        if (entroOffline) return;
      }
      if (mounted) _mostrarMensaje(traducirErrorAuth(e), error: true);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _entrarSinConexion() async {
    await sesionLocalRepo.activarOffline();
  }

  void _mostrarMensaje(String texto, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _MarcaLecheControl(),
                    const SizedBox(height: 8),
                    Text(
                      'Iniciá sesión',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 32),

                    TextFormField(
                      key: const ValueKey('login.email'),
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Correo',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final t = v?.trim() ?? '';
                        if (t.isEmpty) return 'Ingresá tu correo';
                        if (!t.contains('@') || !t.contains('.')) {
                          return 'Correo no válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      key: const ValueKey('login.password'),
                      controller: _passCtrl,
                      obscureText: !_verPass,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _verPass ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () => setState(() => _verPass = !_verPass),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Ingresá tu contraseña'
                          : null,
                    ),
                    const SizedBox(height: 24),

                    FilledButton(
                      key: const ValueKey('login.submit'),
                      onPressed: _cargando ? null : _entrar,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _cargando
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Entrar'),
                    ),

                    ValueListenableBuilder<SesionLocalRow?>(
                      valueListenable: sesionLocalRepo.sesion,
                      builder: (context, sesionLocal, _) {
                        return ValueListenableBuilder<bool>(
                          valueListenable: estadoConexion.hayConexion,
                          builder: (context, hayConexion, _) {
                            return OfflineLoginAction(
                              sesionLocal: sesionLocal,
                              hayConexion: hayConexion,
                              falloRedReciente: _falloRedReciente,
                              cargando: _cargando,
                              onEntrarSinConexion: _entrarSinConexion,
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 24),
                    Text(
                      'Las cuentas las crea el administrador. Si no tenés '
                      'usuario, contactá a soporte.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// El logo del login. Grande y sin recuadro: el PNG es transparente.
class _LogoLogin extends StatelessWidget {
  const _LogoLogin();

  static const double _lado = 180;

  @override
  Widget build(BuildContext context) {
    final logo = Image.asset(
      'assets/logo_lechecontrol.png',
      width: _lado,
      height: _lado,
      fit: BoxFit.contain,
    );

    if (Theme.of(context).brightness == Brightness.light) return logo;

    // En oscuro el azul marino del logo se pierde contra el fondo, así que
    // se le pone un disco claro detrás. Disco y no cuadro: el borde recto
    // era justo lo que se veía como una caja pegada encima.
    return Container(
      width: _lado + 24,
      height: _lado + 24,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: logo,
    );
  }
}

class _MarcaLecheControl extends StatelessWidget {
  const _MarcaLecheControl();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        // Sin recuadro: el PNG tiene fondo transparente y se apoya directo en
        // el fondo de la pantalla. En oscuro sí lleva un disco claro detrás,
        // porque el logo es azul marino y verde y contra el fondo negro no se
        // lee; un círculo no deja el borde cuadrado que sí se notaba antes.
        const _LogoLogin(),
        const SizedBox(height: LecheSpacing.lg),
        Text(
          'LecheControl',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

class OfflineLoginAction extends StatelessWidget {
  const OfflineLoginAction({
    super.key,
    required this.sesionLocal,
    required this.hayConexion,
    required this.falloRedReciente,
    required this.cargando,
    required this.onEntrarSinConexion,
  });

  final SesionLocalRow? sesionLocal;
  final bool hayConexion;
  final bool falloRedReciente;
  final bool cargando;
  final VoidCallback onEntrarSinConexion;

  @override
  Widget build(BuildContext context) {
    final sesion = sesionLocal;
    if (sesion == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final usuario = sesion.email ?? sesion.nombre;
    final necesitaAyudaOffline = !hayConexion || falloRedReciente;
    final textoAyuda = necesitaAyudaOffline
        ? 'Usarás los datos guardados en este dispositivo. '
              'La sincronización se retomará cuando vuelva internet.'
        : 'Disponible para trabajar con datos guardados si no tenés internet.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const ValueKey('login.offline'),
          onPressed: cargando ? null : onEntrarSinConexion,
          icon: const Icon(Icons.cloud_off_outlined),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          label: Text(
            usuario == null
                ? 'Entrar sin conexión'
                : 'Entrar sin conexión como $usuario',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          textoAyuda,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}
