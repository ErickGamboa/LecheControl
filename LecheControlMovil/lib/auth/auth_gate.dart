import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../cuenta/cuenta_gate.dart';
import '../data/local/database.dart';
import '../services.dart';
import 'login_screen.dart';

/// Decide qué pantalla mostrar según el estado de la sesión:
/// - Sesión Supabase activa   -> CuentaGate (online)
/// - Sesión local offline     -> CuentaGate (sin conexión)
/// - Ninguna                  -> LoginScreen
///
/// Escucha los cambios de autenticación en tiempo real, así que al iniciar o
/// cerrar sesión la app cambia de pantalla automáticamente. Si no hay cliente
/// de Supabase disponible (`supabaseClientOrNull == null`: sin configuración,
/// o `Supabase.initialize` todavía no corrió), solo se admite la sesión local
/// (modo offline/demo).
class AuthGate extends StatelessWidget {
  const AuthGate({super.key, this.construirHome});

  /// Con qué reemplazar el home una vez que hay cuenta y lechería.
  ///
  /// Existe para que la versión de escritorio (LecheControlWeb) monte su
  /// propio marco —barra lateral y barra superior— sin volver a escribir el
  /// camino de sesión, cuenta y lechería que lleva hasta acá: esa lógica es
  /// la misma en los tres clientes y vive una sola vez, en este paquete.
  ///
  /// En `null` (el teléfono y la web de celular) se usa `HomeScreen`, o sea
  /// exactamente el mismo árbol de siempre.
  final ConstructorHome? construirHome;

  @override
  Widget build(BuildContext context) {
    final client = supabaseClientOrNull;
    if (client == null) {
      return ValueListenableBuilder<SesionLocalRow?>(
        valueListenable: sesionLocalRepo.sesion,
        builder: (context, sesionLocal, _) {
          if (sesionLocal?.offlineActiva == true) {
            return CuentaGate(
              usuarioId: sesionLocal!.usuarioId,
              sinConexion: true,
              construirHome: construirHome,
            );
          }
          return const LoginScreen();
        },
      );
    }

    return StreamBuilder<AuthState>(
      stream: client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        return ValueListenableBuilder<SesionLocalRow?>(
          valueListenable: sesionLocalRepo.sesion,
          builder: (context, sesionLocal, _) {
            final session = client.auth.currentSession;
            if (session != null) {
              return CuentaGate(
                usuarioId: session.user.id,
                sinConexion: false,
                construirHome: construirHome,
              );
            }
            if (sesionLocal?.offlineActiva == true) {
              return CuentaGate(
                usuarioId: sesionLocal!.usuarioId,
                sinConexion: true,
                construirHome: construirHome,
              );
            }
            return const LoginScreen();
          },
        );
      },
    );
  }
}
