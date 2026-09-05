// La pantalla de partos se lee en un teléfono angosto, parada en el corral.
// Estas pruebas montan la pantalla real contra una base en memoria y la miden
// a 400 puntos de ancho: cualquier fila que se salga revienta el test.

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leche_control/analisis/partos_screen.dart';
import 'package:leche_control/app/theme.dart';
import 'package:leche_control/data/domain/grupos.dart';
import 'package:leche_control/data/local/database.dart';
import 'package:leche_control/data/repositories/partos_repository.dart';

import '../support/local_db_seed.dart';

void main() {
  late AppDatabase db;
  late PartosRepository repo;
  const lecheriaId = 'lecheria-1';
  final hoy = DateTime.now();

  setUp(() async {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    repo = PartosRepository(db);
    await seedCuentaLocal(db, usuarioId: 'user-1');
    await seedLecheria(db, usuarioId: 'user-1', lecheriaId: lecheriaId);
  });

  tearDown(() async => db.close());

  Future<void> vaca(
    String id,
    String identificador, {
    required int diasParaParto,
    String grupo = GrupoAnimal.secas,
    bool conFechaAnotada = true,
    int? servicioHaceDias,
  }) async {
    await seedAnimal(
      db,
      lecheriaId: lecheriaId,
      id: id,
      identificador: identificador,
      grupo: grupo,
      estadoReproductivo: EstadoReproductivo.preniada,
      fechaProbableParto: conFechaAnotada
          ? DateTime(hoy.year, hoy.month, hoy.day + diasParaParto)
          : null,
    );
    if (servicioHaceDias != null) {
      await db
          .into(db.eventosAnimal)
          .insert(
            EventosAnimalCompanion.insert(
              id: 'evento-$id',
              animalId: id,
              lecheriaId: lecheriaId,
              tipo: TipoEventoAnimal.inseminacion,
              fecha: DateTime(hoy.year, hoy.month, hoy.day - servicioHaceDias),
              toroPajilla: const Value('Pajilla 44'),
              createdAt: hoy,
              updatedAt: hoy,
            ),
          );
    }
  }

  /// Monta la pantalla en un teléfono de 400 puntos de ancho, alto de sobra
  /// para que se construyan los doce meses de una: así una fila que se
  /// desborde aparece acá y no en la finca.
  Future<void> montar(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 8000);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: LecheTheme.light,
        home: PartosScreen(
          lecheriaId: lecheriaId,
          nombreLecheria: 'Lechería Erick',
          repositorio: repo,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// La tarjeta del mes que cae [dentroDe] meses del actual.
  Finder tarjetaMes(int dentroDe) {
    final mes = DateTime(hoy.year, hoy.month + dentroDe);
    return find.byKey(ValueKey('partos.mes.${mes.year}-${mes.month}'));
  }

  testWidgets('muestra los doce meses aunque vengan vacíos', (tester) async {
    await vaca('a1', '1001', diasParaParto: 40);
    await montar(tester);

    for (var i = 0; i < 12; i++) {
      expect(
        tarjetaMes(i),
        findsOneWidget,
        reason: 'falta el mes $i del calendario',
      );
    }
    expect(find.text('Ninguna vaca pare en este mes.'), findsWidgets);
  });

  testWidgets('la pasada de fecha sale en el mes en curso', (tester) async {
    await vaca('a1', '1001', diasParaParto: -6);
    await montar(tester);

    expect(
      find.descendant(
        of: tarjetaMes(0),
        matching: find.text('Pasada de fecha por 6 días'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('marca la fecha estimada y no la confirmada', (tester) async {
    await vaca('a1', '1001', diasParaParto: 40);
    await vaca(
      'a2',
      '1002',
      conFechaAnotada: false,
      diasParaParto: 0,
      servicioHaceDias: 200,
    );
    await montar(tester);

    expect(find.text('Estimada'), findsOneWidget);
    expect(find.text('Inseminación · Pajilla 44'), findsOneWidget);
  });

  testWidgets('un identificador largo no rompe la fila', (tester) async {
    // Hay fincas que llaman a la vaca por nombre, no por número.
    await vaca('a1', 'NOVILLA-BLANQUITA-DEL-2024', diasParaParto: 40);
    await montar(tester);

    // Sin desbordes: cualquiera habría hecho fallar el `pumpAndSettle`.
    expect(find.textContaining('NOVILLA'), findsOneWidget);
  });

  testWidgets('avisa de la preñada sin fecha de parto', (tester) async {
    await vaca('a1', '1001', conFechaAnotada: false, diasParaParto: 0);
    await montar(tester);

    expect(find.byKey(const ValueKey('partos.sinFecha')), findsOneWidget);
    expect(find.text('1001'), findsOneWidget);
  });

  testWidgets('sin preñadas explica que el calendario se llena solo', (
    tester,
  ) async {
    await montar(tester);

    expect(find.text('Todavía no hay partos que proyectar'), findsOneWidget);
    expect(find.byKey(const ValueKey('partos.resumen')), findsNothing);
  });
}
