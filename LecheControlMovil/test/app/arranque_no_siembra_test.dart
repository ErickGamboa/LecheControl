// El arranque de la app NO inventa datos y NO cierra la sesión de nadie.
//
// Esto no es una regla de estilo: una build salió a TestFlight con el modo
// demo activo y en cada arranque sembraba una finca falsa y le cerraba la
// sesión al usuario. El ganadero abría la app, veía una lechería que no era la
// suya, quedaba sin sesión y lo que había digitado no subía nunca. Se
// perdieron datos reales.
//
// Estos tests leen el código fuente del arranque. Es tosco a propósito: la
// idea es que si alguien vuelve a meter una siembra o un cierre de sesión ahí,
// el build se caiga antes de llegar a un teléfono.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// El código del archivo, sin comentarios.
///
/// Hace falta porque los comentarios del arranque **nombran** justamente lo
/// que no debe pasar (para que se entienda por qué), y si no se quitaran, este
/// test se caería por la explicación en vez de por el código.
String codigoSinComentarios(File archivo) {
  return archivo
      .readAsLinesSync()
      .map((linea) {
        final corte = linea.indexOf('//');
        return corte == -1 ? linea : linea.substring(0, corte);
      })
      .join('\n');
}

void main() {
  final bootstrap = File('lib/app_bootstrap.dart');
  final main = File('lib/main.dart');

  test('el archivo del arranque existe donde se lo espera', () {
    expect(
      bootstrap.existsSync(),
      isTrue,
      reason:
          'si se movió, hay que apuntar estos tests al lugar nuevo, no '
          'borrarlos',
    );
    expect(main.existsSync(), isTrue);
  });

  test('el arranque no cierra la sesión del usuario', () {
    final fuente = codigoSinComentarios(bootstrap) + codigoSinComentarios(main);
    expect(
      fuente.contains('signOut'),
      isFalse,
      reason:
          'cerrar sesión en el arranque es exactamente lo que dejó al '
          'ganadero fuera de su cuenta una y otra vez. Si de verdad hace '
          'falta, tiene que ser una decisión del usuario, no del arranque',
    );
  });

  test('el arranque no siembra datos', () {
    final fuente = codigoSinComentarios(bootstrap) + codigoSinComentarios(main);
    for (final siembra in const [
      'seed',
      'Seed',
      'sembrar',
      'Sembrar',
      'insert',
      'Insert',
    ]) {
      expect(
        fuente.contains(siembra),
        isFalse,
        reason:
            'el arranque no escribe filas de dominio: encontré "$siembra". '
            'Los datos entran por sincronización o porque el ganadero los '
            'digita',
      );
    }
  });

  test('no volvió el modo demo', () {
    expect(
      Directory('lib/demo').existsSync(),
      isFalse,
      reason:
          'el modo demo se quitó por completo; ver "No hay modo demo" en el '
          'README',
    );

    const extensiones = [
      '.dart',
      '.kt',
      '.swift',
      '.gradle',
      '.plist',
      '.xcconfig',
    ];
    final conBandera = <String>[];
    for (final dir in [
      Directory('lib'),
      Directory('android'),
      Directory('ios'),
    ]) {
      if (!dir.existsSync()) continue;
      for (final f in dir.listSync(recursive: true).whereType<File>()) {
        if (!extensiones.any(f.path.endsWith)) continue;
        if (f.readAsStringSync().contains('LECHE_DEMO')) conBandera.add(f.path);
      }
    }
    expect(
      conBandera,
      isEmpty,
      reason: 'quedó la bandera del modo demo en: ${conBandera.join(", ")}',
    );
  });
}
