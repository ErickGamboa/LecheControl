// La app tiene que poder hablar con Supabase desde CUALQUIER teléfono que la
// descargue, no solo desde el que corre `flutter run`.
//
// Este test existe porque el fallo es invisible: Flutter crea el proyecto con
// el permiso de INTERNET solo en `src/debug/` y `src/profile/`, así que en
// desarrollo todo anda perfecto y recién al instalar el APK de release el
// login falla y la sincronización nunca sube nada — sin ningún error que
// apunte al permiso. Un test de configuración lo agarra antes de publicar.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:leche_control/config/supabase_config.dart';

void main() {
  test('el manifest de release pide permiso de INTERNET', () {
    // `src/main` es el único manifest que entra en el build de release; los
    // de debug/profile no cuentan.
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(
      manifest,
      contains('android.permission.INTERNET'),
      reason:
          'Sin INTERNET en src/main, la app instalada no puede hacer login '
          'ni sincronizar. Tenerlo solo en src/debug no sirve para release.',
    );
  });

  test('el manifest de release puede leer el estado de la red', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(
      manifest,
      contains('android.permission.ACCESS_NETWORK_STATE'),
      reason:
          'connectivity_plus lo necesita para avisar cuando volvió la señal, '
          'que es lo que dispara la sincronización automática.',
    );
  });

  test('Supabase se habla por HTTPS', () {
    // Con http pelado el ATS de iOS y el `cleartext` bloqueado de Android
    // cortarían las peticiones en los dispositivos, no en el emulador.
    expect(SupabaseConfig.url, startsWith('https://'));
    expect(SupabaseConfig.estaConfigurado, isTrue);
  });

  test('iOS no bloquea las conexiones seguras', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();

    // ATS permite HTTPS por defecto, así que lo normal es que no haya nada.
    // Lo que no puede pasar es que alguien meta una excepción que apague la
    // seguridad de transporte para todo.
    expect(
      plist.contains('NSAllowsArbitraryLoads'),
      isFalse,
      reason:
          'Supabase es HTTPS: no hace falta apagar App Transport Security, y '
          'hacerlo abre la app a conexiones sin cifrar.',
    );
  });
}
