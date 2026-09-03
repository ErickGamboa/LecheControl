import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/theme.dart';
import 'auth/auth_gate.dart';
import 'config/supabase_config.dart';
import 'demo/demo_env.dart';
import 'demo/demo_seed.dart';
import 'services.dart';

export 'app/theme.dart' show kAzulLeche, kCremaLeche, kVerdeLeche;

/// Cada cuánto se reintenta solo la sincronización si quedó algo pendiente.
const kReintentoSyncCada = Duration(minutes: 2);

/// Inicializa Supabase (si hay configuración), la sesión local, la
/// conectividad y, si aplica, la siembra de datos demo.
///
/// Si `SupabaseConfig.url`/`anonKey` están vacíos (proyecto de Supabase
/// todavía no creado), se salta `Supabase.initialize` por completo: la app
/// sigue funcionando en modo offline/demo (ver `LECHE_DEMO=true`).
Future<void> bootstrapLecheControl() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (SupabaseConfig.estaConfigurado) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      // ignore: deprecated_member_use
      anonKey: SupabaseConfig.anonKey,
    );
  }

  await sesionLocalRepo.cargar();
  await maybeSeedDemoOnStartup();
  await estadoConexion.iniciar(alRecuperarConexion: syncService.sincronizar);

  if (!kSeedDemoEnabled && SupabaseConfig.estaConfigurado) {
    final usuarioInicial = supabase.auth.currentUser;
    if (usuarioInicial != null) {
      await sesionLocalRepo.guardarUsuarioVerificado(
        usuarioId: usuarioInicial.id,
        email: usuarioInicial.email,
        nombre: usuarioInicial.userMetadata?['nombre'] as String?,
      );
    }
  }

  sincronizarSiSePuede();

  // Red de seguridad: si algo quedó sin subir —la red se cayó a mitad, el
  // servidor no respondió— se reintenta solo. El ganadero no tiene que
  // acordarse de nada ni apretar ningún botón.
  Timer.periodic(kReintentoSyncCada, (_) async {
    if (await syncService.hayPendientes()) await sincronizarSiSePuede();
  });

  if (SupabaseConfig.estaConfigurado) {
    supabase.auth.onAuthStateChange.listen((estado) async {
      if (estado.event == AuthChangeEvent.signedIn) {
        final usuario = estado.session?.user ?? supabase.auth.currentUser;
        if (usuario != null) {
          await sesionLocalRepo.guardarUsuarioVerificado(
            usuarioId: usuario.id,
            email: usuario.email,
            nombre: usuario.userMetadata?['nombre'] as String?,
          );
        }
        sincronizarSiSePuede();
      }
    });
  }
}

class LecheControlApp extends StatelessWidget {
  const LecheControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LecheControl',
      debugShowCheckedModeBanner: false,
      theme: LecheTheme.light,
      darkTheme: LecheTheme.dark,
      themeMode: ThemeMode.system,
      home: const AuthGate(),
    );
  }
}

void runLecheControlApp() {
  runApp(const LecheControlApp());
}
