import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/teclado/teclado_del_app.dart';
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

  if (kDemoPedidoPeroIgnorado) {
    // Que no quede la duda de si el define "funcionó": una build que no es de
    // depuración ignora el modo demo a propósito (ver `demo_env.dart`).
    debugPrint(
      'LECHE_DEMO se pidió pero esta build no es de depuración: se ignora. '
      'El modo demo le cierra la sesión al usuario en cada arranque, así que '
      'no puede salir en una build de release.',
    );
  }

  await sesionLocalRepo.cargar();
  await maybeSeedDemoOnStartup();
  if (!kSeedDemoEnabled) {
    // Si el teléfono viene de una build demo, la finca falsa quedó guardada.
    // Se limpia acá para que el ganadero no tenga que borrar la app.
    await limpiarRestosDeDemo();
    await sesionLocalRepo.cargar();
  }
  await estadoConexion.iniciar(alRecuperarConexion: syncService.sincronizar);

  if (!kSeedDemoEnabled && SupabaseConfig.estaConfigurado) {
    final usuarioInicial = supabase.auth.currentUser;
    if (usuarioInicial != null) {
      // Antes de mostrar nada: si lo que hay guardado es de otra cuenta, se
      // borra. Si no, la app abre con la lechería y los animales del otro.
      await prepararBaseParaUsuario(usuarioInicial.id);
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
  //
  // Se reintenta también cuando **nunca bajó nada**, y eso no es un detalle:
  // antes la condición era solo `hayPendientes()`, que mira lo que falta
  // *subir*. Una instalación nueva no tiene nada pendiente de subir, así que
  // si su primera bajada fallaba, esta red de seguridad no entraba nunca y la
  // app se quedaba esperando una cuenta que ya nadie iba a ir a buscar.
  Timer.periodic(kReintentoSyncCada, (_) async {
    if (await syncService.hayPendientes() || await faltaLaPrimeraBajada()) {
      await sincronizarSiSePuede();
    }
  });

  if (SupabaseConfig.estaConfigurado) {
    supabase.auth.onAuthStateChange.listen((estado) async {
      if (estado.event == AuthChangeEvent.signedIn) {
        final usuario = estado.session?.user ?? supabase.auth.currentUser;
        if (usuario != null) {
          // Acá es donde de verdad se cambia de cuenta: alguien escribió otro
          // correo y entró. Se limpia lo del anterior **antes** de sincronizar,
          // para no dejar las dos fincas mezcladas ni un instante.
          await prepararBaseParaUsuario(usuario.id);
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
      // LecheControl es SIEMPRE clara, tenga el teléfono el modo que tenga.
      // Se trabaja al sol y las pantallas están pensadas para eso. Antes decía
      // `ThemeMode.system` y con el teléfono en oscuro no se leía lo que se
      // digitaba en los campos (ver `LecheTheme`).
      themeMode: ThemeMode.light,
      // El teclado propio de la app, para cuando el lector de identificadores
      // está conectado y el sistema esconde el suyo. Envuelve todo, incluido
      // el login: el lector se empareja una vez y queda conectado, así que sin
      // esto no se podría ni escribir la contraseña. Ver `TecladoDelApp`.
      builder: (context, child) =>
          TecladoDelApp(child: child ?? const SizedBox.shrink()),
      home: const AuthGate(),
    );
  }
}

void runLecheControlApp() {
  runApp(const LecheControlApp());
}
