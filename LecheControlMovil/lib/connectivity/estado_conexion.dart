import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Si parece haber conexión a internet. Es una **pista para la pantalla**, no
/// un permiso para sincronizar.
///
/// La diferencia importa: `connectivity_plus` informa si hay una *interfaz* de
/// red levantada, no si internet responde. Puede decir que hay WiFi con el
/// módem sin servicio, y puede decir `none` por una carrera al arrancar
/// teniendo la red perfecta.
///
/// Por eso [hayConexion] alimenta el ícono del home y la ayuda del login, y
/// **nada más**. Quien decida si intentar una petición no debe consultarla:
/// ver `sincronizarSiSePuede` en `services.dart`, que se trababa justamente
/// por usarla de compuerta.
class EstadoConexion {
  /// Arranca en `true` a propósito: ante la duda, se asume que hay red y se
  /// deja intentar. Equivocarse hacia el optimismo cuesta una petición que
  /// falla; equivocarse hacia el pesimismo dejaba la app inservible.
  final ValueNotifier<bool> hayConexion = ValueNotifier(true);

  StreamSubscription<List<ConnectivityResult>>? _sub;
  Timer? _repaso;

  /// Cada cuánto se vuelve a preguntar por las dudas.
  ///
  /// Los eventos de cambio son la vía normal, pero si la primera lectura sale
  /// mal y la red no vuelve a cambiar —un WiFi de casa, por ejemplo— no llega
  /// ningún evento y el valor se queda equivocado para siempre. Este repaso
  /// es el que lo corrige.
  static const repasoCada = Duration(seconds: 30);

  Future<void> iniciar({Future<void> Function()? alRecuperarConexion}) async {
    await refrescar();
    _sub = Connectivity().onConnectivityChanged.listen((resultados) async {
      final antes = hayConexion.value;
      _actualizar(resultados);
      if (!antes && hayConexion.value) {
        await alRecuperarConexion?.call();
      }
    });
    _repaso = Timer.periodic(repasoCada, (_) async {
      final antes = hayConexion.value;
      await refrescar();
      if (!antes && hayConexion.value) {
        await alRecuperarConexion?.call();
      }
    });
  }

  /// Vuelve a preguntar al sistema. Se puede llamar cuando convenga (al
  /// volver del fondo, al reintentar a mano).
  Future<void> refrescar() async {
    try {
      _actualizar(await Connectivity().checkConnectivity());
    } catch (_) {
      // Si el plugin falla, se asume que hay red: que la detección no ande no
      // puede ser motivo para dejar de intentar.
      hayConexion.value = true;
    }
  }

  void _actualizar(List<ConnectivityResult> resultados) {
    hayConexion.value = resultados.any((r) => r != ConnectivityResult.none);
  }

  Future<void> dispose() async {
    _repaso?.cancel();
    await _sub?.cancel();
  }
}
