import 'package:flutter_test/flutter_test.dart';
import 'package:leche_control/data/domain/curva_lactancia.dart';

void main() {
  final curva = CurvaLactancia(CurvaLactancia.tramosPorDefecto);

  group('diaCentro', () {
    test('es el punto medio del tramo', () {
      const tramo = TramoCurva(diaDesde: 31, diaHasta: 70, litrosEsperados: 26);
      expect(tramo.diaCentro, 50.5);
    });

    test('el tramo abierto (sin tope) cae 25 días adentro', () {
      const tramo = TramoCurva(
        diaDesde: 306,
        diaHasta: null,
        litrosEsperados: 10,
      );
      expect(tramo.diaCentro, 331);
    });
  });

  group('esperadoPara', () {
    test('interpola entre los centros de dos tramos', () {
      // Centro del tramo 0-30 = día 15 (18.8 L); centro del 31-70 = día 50.5
      // (26 L). A los 44 días: 18.8 + (44-15)/(50.5-15) * 7.2.
      final esperado = curva.esperadoPara(44)!;
      expect(esperado, closeTo(24.68, 0.01));
    });

    test('no da saltos al cruzar el borde entre tramos', () {
      final dia30 = curva.esperadoPara(30)!;
      final dia31 = curva.esperadoPara(31)!;
      expect(
        (dia31 - dia30).abs(),
        lessThan(0.5),
        reason:
            'cruzar de un tramo al siguiente no puede mover litros de golpe',
      );
    });

    test('crece de forma monótona hasta el pico y luego baja', () {
      final pico = curva.esperadoPara(50)!;
      expect(curva.esperadoPara(15)!, lessThan(pico));
      expect(curva.esperadoPara(120)!, lessThan(pico));
      expect(curva.esperadoPara(300)!, lessThan(curva.esperadoPara(120)!));
    });

    test('se mantiene plano antes del primer centro', () {
      // Extrapolar hacia atrás daría valores sin sentido (hasta negativos).
      expect(curva.esperadoPara(0), 18.8);
      expect(curva.esperadoPara(15), 18.8);
    });

    test('se mantiene plano después del último centro', () {
      expect(curva.esperadoPara(331), 10);
      expect(curva.esperadoPara(500), 10);
    });

    test('devuelve null si la curva no tiene tramos', () {
      expect(CurvaLactancia(const []).esperadoPara(50), isNull);
    });
  });

  group('porcentajeDelEsperado', () {
    test('compara la vaca contra su propia etapa, no contra el hato', () {
      // Una vaca de 250 días que da 12 L está mejor para su etapa que una de
      // 50 días que da 20 L, aunque produzca menos leche.
      final vieja = curva.porcentajeDelEsperado(250, 12)!;
      final fresca = curva.porcentajeDelEsperado(50, 20)!;
      expect(vieja, greaterThan(fresca));
    });

    test('devuelve null si el esperado es cero', () {
      final plana = CurvaLactancia(const [
        TramoCurva(diaDesde: 0, diaHasta: 30, litrosEsperados: 0),
      ]);
      expect(plana.porcentajeDelEsperado(10, 5), isNull);
    });
  });

  group('tramoDe', () {
    test('ubica la vaca en su tramo', () {
      expect(curva.tramoDe(44)!.diaDesde, 31);
      expect(curva.tramoDe(0)!.diaDesde, 0);
      expect(curva.tramoDe(305)!.diaDesde, 241);
    });

    test('el tramo abierto atrapa cualquier día alto', () {
      expect(curva.tramoDe(9999)!.diaDesde, 306);
    });
  });

  group('UmbralesEvaluacion', () {
    const umbrales = UmbralesEvaluacion();

    test('califica según el porcentaje del esperado', () {
      expect(umbrales.evaluar(124), EvaluacionVaca.excelente);
      expect(umbrales.evaluar(100), EvaluacionVaca.excelente);
      expect(umbrales.evaluar(90), EvaluacionVaca.bueno);
      expect(umbrales.evaluar(75), EvaluacionVaca.vigilar);
      expect(umbrales.evaluar(62), EvaluacionVaca.bajo);
      expect(umbrales.evaluar(29), EvaluacionVaca.muyBajo);
    });

    test('cada calificación lleva a una recomendación', () {
      expect(
        EvaluacionVaca.excelente.recomendacion,
        RecomendacionVaca.mantener,
      );
      expect(EvaluacionVaca.vigilar.recomendacion, RecomendacionVaca.vigilar);
      expect(EvaluacionVaca.muyBajo.recomendacion, RecomendacionVaca.revisar);
    });
  });

  group('diasLactancia', () {
    test('cuenta los días desde el parto ignorando la hora', () {
      expect(
        diasLactancia(DateTime(2026, 3, 1, 23), hoy: DateTime(2026, 3, 10, 1)),
        9,
      );
    });

    test('el día del parto es 0', () {
      expect(
        diasLactancia(DateTime(2026, 3, 10), hoy: DateTime(2026, 3, 10)),
        0,
      );
    });

    test('null si nunca se registró un parto', () {
      expect(diasLactancia(null), isNull);
    });

    test('null si el parto quedó en el futuro (dato mal cargado)', () {
      expect(
        diasLactancia(DateTime(2026, 3, 20), hoy: DateTime(2026, 3, 10)),
        isNull,
      );
    });
  });
}
