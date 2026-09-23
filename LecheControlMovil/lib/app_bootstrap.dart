import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/teclado/teclado_del_app.dart';
import 'app/theme.dart';
import 'auth/auth_gate.dart';
import 'config/supabase_config.dart';
import 'services.dart';

export 'app/theme.dart' show kAzulLeche, kCremaLeche, kVerdeLeche;

/// Cada cuánto se reintenta solo la sincronización.
const kReintentoSyncCada = Duration(minutes: 2);

/// Sincroniza cada vez que la app vuelve del segundo plano.
///
/// **Por qué hace falta.** En un teléfono la app casi nunca arranca en frío:
/// se retoma. El arranque y el `signedIn` sí sincronizaban, pero volver a
/// abrir la app desde el multitarea no disparaba nada, así que el ganadero se
/// encontraba el hato como lo había dejado ayer. Era la razón de fondo por la
/// que cerrar sesión "refrescaba": es lo único que forzaba una bajada.
class _SyncAlVolver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    if (estado == AppLifecycleState.resumed) sincronizarSiSePuede();
  }
}

/// Inicializa Supabase (si hay configuración), la sesión local y la
/// conectividad, y deja la base lista para el usuario que tenga sesión.
///
/// Si `SupabaseConfig.url`/`anonKey` están vacíos (proyecto de Supabase
/// todavía no creado), se salta `Supabase.initialize` por completo y la app
/// queda en modo sin conexión con lo que haya guardado.
///
/// **Acá no se inventan datos ni se toca la sesión de nadie.** Hubo un modo
/// demo que en cada arranque sembraba una finca falsa y llamaba a
/// `signOut()`, y eso dejaba al ganadero fuera de su cuenta una y otra vez.
/// Se quitó por completo: no queda ni la bandera ni el código que sembraba.
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
  await estadoConexion.iniciar(alRecuperarConexion: syncService.sincronizar);

  if (SupabaseConfig.estaConfigurado) {
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

  WidgetsBinding.instance.addObserver(_SyncAlVolver());

  // Red de seguridad: si algo quedó sin subir —la red se cayó a mitad, el
  // servidor no respondió— se reintenta solo. El ganadero no tiene que
  // acordarse de nada ni apretar ningún botón.
  //
  // Se reintenta también cuando **nunca bajó nada**, y eso no es un detalle:
  // antes la condición era solo `hayPendientes()`, que mira lo que falta
  // *subir*. Una instalación nueva no tiene nada pendiente de subir, así que
  // si su primera bajada fallaba, esta red de seguridad no entraba nunca y la
  // app se quedaba esperando una cuenta que ya nadie iba a ir a buscar.
  //
  // **Ya no se condiciona a que haya algo pendiente.** Antes era
  // `if (hayPendientes() || faltaLaPrimeraBajada())`, y las dos cosas miran lo
  // que falta *subir*: un teléfono que solo consulta —el del dueño mirando
  // cómo va la finca— no tenía nada pendiente, así que **no volvía a bajar
  // nunca**. Se quedaba con el hato del día que lo abrió hasta que cerraba
  // sesión, que era el único refresco que existía.
  Timer.periodic(kReintentoSyncCada, (_) => sincronizarSiSePuede());

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
      // La app es en español y punto. Sin esto, lo que pone Material por su
      // cuenta salía en inglés: el calendario para escoger fechas se abría con
      // «Select date», «Cancel», los meses y los días de la semana.
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
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
