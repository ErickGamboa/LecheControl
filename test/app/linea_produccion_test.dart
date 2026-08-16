// El gráfico del home es lo primero que se mira al abrir la app. Lo que no
// puede pasar es que dibuje una caída que no ocurrió: ni por una pesa a
// medias, ni por una semana que nadie anotó.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leche_control/app/theme.dart';
import 'package:leche_control/data/local/database.dart';
import 'package:leche_control/data/repositories/pesas_repository.dart';
import 'package:leche_control/home/widgets/linea_produccion.dart';

void main() {
  // Miércoles 12 de agosto de 2026; su lunes es el 10.
  final hoy = DateTime(2026, 8, 12);
  final esteLunes = DateTime(2026, 8, 10);

  SesionConTotales sesion({
    required DateTime fecha,
    required double litros,
    int vacas = 30,
    bool cerrada = true,
  }) {
    return SesionConTotales(
      sesion: PesaSesionRow(
        id: 'sesion-${fecha.toIso8601String()}',
        lecheriaId: 'lecheria-1',
        fecha: fecha,
        cerrada: cerrada,
        createdAt: fecha,
        updatedAt: fecha,
        pendiente: false,
      ),
      vacas: vacas,
      litros: litros,
    );
  }

  group('armarSemanas', () {
    test('devuelve siempre cuatro semanas, terminando en la actual', () {
      final puntos = armarSemanas(const [], hoy: hoy);

      expect(puntos, hasLength(4));
      expect(puntos.last.lunes, esteLunes);
      expect(puntos.first.lunes, DateTime(2026, 7, 20));
      expect(puntos.every((p) => p.litros == null), isTrue);
    });

    test('pone cada pesa en la semana que le toca', () {
      final puntos = armarSemanas([
        sesion(fecha: DateTime(2026, 8, 10, 6), litros: 312),
        sesion(fecha: DateTime(2026, 8, 3, 6), litros: 304),
      ], hoy: hoy);

      expect(puntos.map((p) => p.litros), [null, null, 304, 312]);
    });

    test('una semana sin pesa queda en hueco, no en cero', () {
      // Si el hueco valiera cero, la línea se desplomaría hasta el piso y
      // volvería a subir: parecería que la finca dejó de producir.
      final puntos = armarSemanas([
        sesion(fecha: DateTime(2026, 8, 10, 6), litros: 312),
        sesion(fecha: DateTime(2026, 7, 27, 6), litros: 300),
      ], hoy: hoy);

      // Ventana: 20/7, 27/7, 3/8 y 10/8. La del 3/8 es la que faltó.
      expect(puntos.map((p) => p.litros), [null, 300, null, 312]);
    });

    test('la pesa abierta sin vacas todavía no cuenta como semana', () {
      // Es la que la app abre sola al entrar a la pantalla de pesa.
      final puntos = armarSemanas([
        sesion(
          fecha: DateTime(2026, 8, 10, 6),
          litros: 0,
          vacas: 0,
          cerrada: false,
        ),
        sesion(fecha: DateTime(2026, 8, 3, 6), litros: 304),
      ], hoy: hoy);

      expect(puntos.last.litros, isNull, reason: 'la semana en curso va vacía');
      expect(puntos[2].litros, 304);
    });

    test('la pesa abierta con vacas se marca en curso', () {
      final puntos = armarSemanas([
        sesion(
          fecha: DateTime(2026, 8, 10, 6),
          litros: 120,
          vacas: 12,
          cerrada: false,
        ),
      ], hoy: hoy);

      expect(puntos.last.litros, 120);
      expect(puntos.last.enCurso, isTrue);
    });

    test('ignora las pesas más viejas que la ventana', () {
      final puntos = armarSemanas([
        sesion(fecha: DateTime(2026, 6, 1, 6), litros: 999),
      ], hoy: hoy);

      expect(puntos.every((p) => p.litros == null), isTrue);
    });
  });

  group('ticksDeEje', () {
    test('marca números redondos que envuelven al rango', () {
      final marcas = ticksDeEje(290, 312);

      expect(marcas, [280, 300, 320]);
    });

    test('siempre deja los datos adentro del eje', () {
      for (final (minimo, maximo) in [
        (0.0, 7.0),
        (293.0, 317.0),
        (1180.0, 1240.0),
        (12.5, 13.5),
      ]) {
        final marcas = ticksDeEje(minimo, maximo);
        expect(marcas.first, lessThanOrEqualTo(minimo), reason: '$marcas');
        expect(marcas.last, greaterThanOrEqualTo(maximo), reason: '$marcas');
        expect(marcas.length, greaterThanOrEqualTo(2), reason: '$marcas');
      }
    });

    test('con una sola semana no inventa un rango', () {
      expect(ticksDeEje(618, 618), [618]);
    });
  });

  group('LineaProduccion', () {
    Future<void> montar(WidgetTester tester, List<PuntoProduccion> puntos) {
      return tester.pumpWidget(
        MaterialApp(
          theme: LecheTheme.light,
          home: Scaffold(body: LineaProduccion(puntos: puntos)),
        ),
      );
    }

    testWidgets('con una sola pesa muestra el punto y su número, sin '
        'variación', (tester) async {
      await montar(
        tester,
        armarSemanas([
          sesion(fecha: DateTime(2026, 8, 10, 6), litros: 312),
        ], hoy: hoy),
      );

      expect(find.text('312 L'), findsOneWidget);
      expect(find.textContaining('+'), findsNothing);
      // Las cuatro semanas se rotulan igual, con datos o sin ellos.
      expect(find.text('10/8'), findsOneWidget);
      expect(find.text('20/7'), findsOneWidget);
    });

    testWidgets('compara contra la última semana con pesa', (tester) async {
      await montar(
        tester,
        armarSemanas([
          sesion(fecha: DateTime(2026, 8, 10, 6), litros: 312),
          sesion(fecha: DateTime(2026, 8, 3, 6), litros: 290),
        ], hoy: hoy),
      );

      expect(find.text('312 L'), findsOneWidget);
      expect(find.text('+22 L'), findsOneWidget);
    });

    testWidgets('unos litros arriba o abajo son ruido, no tendencia', (
      tester,
    ) async {
      await montar(
        tester,
        armarSemanas([
          sesion(fecha: DateTime(2026, 8, 10, 6), litros: 312),
          sesion(fecha: DateTime(2026, 8, 3, 6), litros: 310),
        ], hoy: hoy),
      );

      expect(find.text('estable'), findsOneWidget);
    });

    testWidgets('una caída se muestra con el signo', (tester) async {
      await montar(
        tester,
        armarSemanas([
          sesion(fecha: DateTime(2026, 8, 10, 6), litros: 280),
          sesion(fecha: DateTime(2026, 8, 3, 6), litros: 312),
        ], hoy: hoy),
      );

      expect(find.text('-32 L'), findsOneWidget);
    });

    testWidgets('con la pesa a medias no compara contra la semana llena', (
      tester,
    ) async {
      // 120 L de 12 vacas contra 312 L de la semana pasada daría "-192 L",
      // que es puro artefacto de estar pesando todavía.
      await montar(
        tester,
        armarSemanas([
          sesion(
            fecha: DateTime(2026, 8, 10, 6),
            litros: 120,
            vacas: 12,
            cerrada: false,
          ),
          sesion(fecha: DateTime(2026, 8, 3, 6), litros: 312),
        ], hoy: hoy),
      );

      expect(find.textContaining('-'), findsNothing);
      expect(find.text('pesando'), findsOneWidget);
      expect(find.text('120 L'), findsOneWidget);
    });

    testWidgets('sin ninguna pesa el marco sigue dibujado', (tester) async {
      await montar(tester, armarSemanas(const [], hoy: hoy));

      expect(find.text('PRODUCCIÓN SEMANAL'), findsOneWidget);
      expect(find.text('10/8'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
