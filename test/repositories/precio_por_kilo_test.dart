// El precio por kilo es el único número de la finca que nadie digita: sale de
// dividir lo que pagó la planta entre los kilos que recibió. Si el promedio se
// calcula mal, el ganadero cree que le pagan distinto de lo que le pagan.

import 'package:flutter_test/flutter_test.dart';
import 'package:leche_control/data/domain/semana.dart';
import 'package:leche_control/data/local/database.dart';
import 'package:leche_control/data/repositories/finanzas_repository.dart';

void main() {
  final ts = DateTime(2026, 1, 1);

  SemanaRow semanaDe(DateTime lunes) => SemanaRow(
    id: 'semana-${lunes.toIso8601String()}',
    lecheriaId: 'lecheria-1',
    fechaInicio: lunes,
    fechaFin: lunes.add(const Duration(days: 6)),
    cerrada: false,
    createdAt: ts,
    updatedAt: ts,
    pendiente: false,
  );

  /// Una semana con una entrega de leche. [kg] nulo = se anotó la plata pero
  /// no los kilos, que es el caso en el que no hay precio.
  ResumenSemana semanaConLeche(
    DateTime lunes, {
    required double monto,
    double? kg,
  }) {
    final semana = semanaDe(lunes);
    return ResumenSemana(
      semana: semana,
      ingresos: [
        IngresoSemanaRow(
          id: 'ingreso-${semana.id}',
          lecheriaId: 'lecheria-1',
          semanaId: semana.id,
          tipo: TipoIngreso.leche,
          monto: monto,
          litros: kg,
          createdAt: ts,
          updatedAt: ts,
          pendiente: false,
        ),
      ],
      gastos: const [],
    );
  }

  test('sin semanas con kilos anotados no hay precio que mostrar', () {
    final precio = PrecioPorKilo.desde([
      semanaConLeche(DateTime(2026, 8, 10), monto: 400000),
    ]);
    expect(precio.hayDatos, isFalse);
  });

  test('deja afuera las semanas sin kilos y usa las que sí los tienen', () {
    final precio = PrecioPorKilo.desde([
      semanaConLeche(DateTime(2026, 8, 10), monto: 400000, kg: 1000),
      semanaConLeche(DateTime(2026, 8, 17), monto: 300000),
    ]);
    expect(precio.semanas, hasLength(1));
    expect(precio.ultima.precio, 400);
  });

  test('el promedio se pondera por kilos, no por semanas', () {
    // 1.500 kg a ₡400 y 200 kg a ₡300. Promediar los dos precios daría ₡350,
    // pero lo que la planta pagó de verdad fueron ₡660.000 por 1.700 kg.
    final precio = PrecioPorKilo.desde([
      semanaConLeche(DateTime(2026, 8, 10), monto: 600000, kg: 1500),
      semanaConLeche(DateTime(2026, 8, 17), monto: 60000, kg: 200),
    ]);
    expect(precio.kgTotales, 1700);
    expect(precio.promedio, closeTo(660000 / 1700, 0.001));
    expect(
      precio.promedio,
      greaterThan(350),
      reason: 'no es el promedio simple',
    );
  });

  test('ordena de la semana más nueva a la más vieja', () {
    final precio = PrecioPorKilo.desde([
      semanaConLeche(DateTime(2026, 8, 3), monto: 100000, kg: 250),
      semanaConLeche(DateTime(2026, 8, 17), monto: 100000, kg: 200),
      semanaConLeche(DateTime(2026, 8, 10), monto: 100000, kg: 400),
    ]);
    expect(precio.semanas.map((s) => s.semana.fechaInicio), [
      DateTime(2026, 8, 17),
      DateTime(2026, 8, 10),
      DateTime(2026, 8, 3),
    ]);
    expect(precio.ultima.precio, 500);
  });

  test('la mejor y la peor semana son las del precio, no las del monto', () {
    final precio = PrecioPorKilo.desde([
      // Mucha plata pero muchos kilos: el precio es el más bajo.
      semanaConLeche(DateTime(2026, 8, 10), monto: 900000, kg: 3000),
      semanaConLeche(DateTime(2026, 8, 17), monto: 200000, kg: 400),
    ]);
    expect(precio.mejor, 500);
    expect(precio.peor, 300);
  });

  test('el cambio compara contra la anterior que también tenga precio', () {
    final precio = PrecioPorKilo.desde([
      semanaConLeche(DateTime(2026, 8, 3), monto: 100000, kg: 250), // ₡400
      // Sin kilos: no entra, y por eso no puede ser la base de comparación.
      semanaConLeche(DateTime(2026, 8, 10), monto: 500000),
      semanaConLeche(DateTime(2026, 8, 17), monto: 100000, kg: 200), // ₡500
    ]);
    expect(precio.cambio, 100);
  });

  test('con una sola semana no hay cambio que mostrar', () {
    final precio = PrecioPorKilo.desde([
      semanaConLeche(DateTime(2026, 8, 17), monto: 100000, kg: 200),
    ]);
    expect(precio.cambio, isNull);
  });
}
