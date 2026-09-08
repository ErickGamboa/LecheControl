// Lo que la pantalla le muestra al ganadero cuando el sync no pudo.
//
// Existe porque los errores del sync van a `debugPrint`, que en una app
// instalada **no se ve**. Diagnosticar el teléfono de alguien así es adivinar
// —se perdieron varias vueltas por eso—. Este texto es el que se manda por
// WhatsApp a soporte, así que tiene que decir algo útil en todos los casos.

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leche_control/data/local/database.dart';
import 'package:leche_control/services.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forExecutor(NativeDatabase.memory()));
  tearDown(() async => db.close());

  test('sin nada anotado dice que el sync no corrió', () async {
    // Es el caso más informativo de todos: si no hay ni éxitos ni errores, el
    // problema no está en el servidor, es que no se intentó.
    expect(
      await diagnosticoDeSync(base: db),
      'La sincronización no llegó a correr.',
    );
  });

  test('con un error muestra la tabla y el mensaje', () async {
    await db.into(db.syncEstados).insert(
      SyncEstadosCompanion.insert(
        tabla: 'cuentas',
        ultimoError: const Value('SocketException: Failed host lookup'),
        ultimoErrorEn: Value(DateTime(2026, 9, 8, 10)),
      ),
    );

    final texto = await diagnosticoDeSync(base: db);
    expect(texto, contains('cuentas'));
    expect(texto, contains('Failed host lookup'));
  });

  test('con varios errores muestra el más reciente', () async {
    await db.into(db.syncEstados).insert(
      SyncEstadosCompanion.insert(
        tabla: 'animales',
        ultimoError: const Value('error viejo'),
        ultimoErrorEn: Value(DateTime(2026, 9, 8, 9)),
      ),
    );
    await db.into(db.syncEstados).insert(
      SyncEstadosCompanion.insert(
        tabla: 'cuentas',
        ultimoError: const Value('error nuevo'),
        ultimoErrorEn: Value(DateTime(2026, 9, 8, 11)),
      ),
    );

    expect(await diagnosticoDeSync(base: db), contains('error nuevo'));
  });

  test('si todo bajó bien lo dice, en vez de dejar el recuadro vacío', () async {
    // Que no haya errores y aun así la app no entre es un dato en sí: apunta
    // a que lo que falta no es red sino la fila de la cuenta.
    await db.into(db.syncEstados).insert(
      SyncEstadosCompanion.insert(
        tabla: 'cuentas',
        ultimaSincronizacionOk: Value(DateTime(2026, 9, 8, 10)),
      ),
    );

    final texto = await diagnosticoDeSync(base: db);
    expect(texto, contains('sin errores'));
    expect(texto, isNotEmpty);
  });

  test('nunca lanza, pase lo que pase con la base', () async {
    // Un diagnóstico que revienta tapa el problema con otro problema. Sobre
    // una base cerrada tiene que devolver texto, no una excepción.
    final cerrada = AppDatabase.forExecutor(NativeDatabase.memory());
    await cerrada.close();

    late String texto;
    await expectLater(
      Future(() async => texto = await diagnosticoDeSync(base: cerrada)),
      completes,
    );
    expect(texto, isNotEmpty);
  });
}
