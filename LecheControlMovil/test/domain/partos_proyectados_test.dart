// El calendario de partos decide qué espera el ganadero de los próximos doce
// meses: cuánta leche va a entrar y cuándo. Un mes corrido es una previsión
// equivocada de aquí a un año.

import 'package:flutter_test/flutter_test.dart';
import 'package:leche_control/data/domain/partos_proyectados.dart';

void main() {
  // Un jueves cualquiera de setiembre, para tener meses con y sin partos.
  final hoy = DateTime(2026, 9, 5);

  VacaPorParir vaca(
    String id,
    DateTime fechaProbable, {
    OrigenFechaParto origen = OrigenFechaParto.confirmada,
  }) => VacaPorParir(
    animalId: 'id-$id',
    identificador: id,
    grupo: 'secas',
    fechaProbable: fechaProbable,
    origen: origen,
  );

  group('gestación', () {
    test('el parto sale a los 283 días del servicio', () {
      // 5 de setiembre de 2026 + 283 días = 15 de junio de 2027.
      expect(
        partoProbableDesdeServicio(DateTime(2026, 9, 5)),
        DateTime(2027, 6, 15),
      );
    });

    test('cruza el fin de año sin ayuda', () {
      expect(
        partoProbableDesdeServicio(DateTime(2026, 12, 20)),
        DateTime(2027, 9, 29),
      );
    });
  });

  group('los doce meses', () {
    test('arrancan en el mes en curso', () {
      final p = proyectarPartos(vacas: const [], hoy: hoy);
      expect(p.meses.length, 12);
      expect(p.meses.first.mes, 9);
      expect(p.meses.first.anio, 2026);
    });

    test('el último es once meses después, ya del año siguiente', () {
      final p = proyectarPartos(vacas: const [], hoy: hoy);
      expect(p.meses.last.mes, 8);
      expect(p.meses.last.anio, 2027);
    });

    test('los meses sin partos siguen apareciendo', () {
      final p = proyectarPartos(vacas: const [], hoy: hoy);
      expect(p.meses.every((m) => m.vacio), isTrue);
      expect(p.totalEnCalendario, 0);
    });
  });

  group('reparto', () {
    test('cada vaca cae en el mes de su fecha probable', () {
      final p = proyectarPartos(
        vacas: [
          vaca('44', DateTime(2026, 10, 12)),
          vaca('77', DateTime(2027, 3, 2)),
        ],
        hoy: hoy,
      );
      expect(p.meses[1].vacas.map((v) => v.identificador), ['44']);
      expect(p.meses[6].vacas.map((v) => v.identificador), ['77']);
      expect(p.totalEnCalendario, 2);
    });

    test('dentro del mes van por día', () {
      final p = proyectarPartos(
        vacas: [
          vaca('tarde', DateTime(2026, 10, 28)),
          vaca('temprano', DateTime(2026, 10, 3)),
        ],
        hoy: hoy,
      );
      expect(p.meses[1].vacas.map((v) => v.identificador), [
        'temprano',
        'tarde',
      ]);
    });

    test('la pasada de fecha entra en el mes en curso', () {
      // Le tocaba parir en julio y no hay parto registrado: sigue pendiente.
      final p = proyectarPartos(
        vacas: [vaca('atrasada', DateTime(2026, 7, 20))],
        hoy: hoy,
      );
      expect(p.meses.first.vacas.map((v) => v.identificador), ['atrasada']);
      expect(p.meses.first.vacas.single.pasadaDeFecha(hoy: hoy), isTrue);
      expect(p.meses.first.vacas.single.dias(hoy: hoy), lessThan(0));
    });

    test('la de más allá del último mes se aparta', () {
      final p = proyectarPartos(
        vacas: [vaca('rara', DateTime(2027, 10, 1))],
        hoy: hoy,
      );
      expect(p.totalEnCalendario, 0);
      expect(p.fueraDeRango.map((v) => v.identificador), ['rara']);
      // Sigue contando como preñada de la finca aunque no salga en un mes.
      expect(p.totalPreniadas, 1);
    });

    test('el último día del último mes todavía entra', () {
      final p = proyectarPartos(
        vacas: [vaca('justa', DateTime(2027, 8, 31))],
        hoy: hoy,
      );
      expect(p.meses.last.cantidad, 1);
      expect(p.fueraDeRango, isEmpty);
    });
  });

  group('resumen', () {
    test('el próximo mes con partos se salta los vacíos', () {
      final p = proyectarPartos(
        vacas: [vaca('44', DateTime(2026, 12, 4))],
        hoy: hoy,
      );
      expect(p.proximoMesConPartos?.mes, 12);
      expect(p.proximoMesConPartos?.etiqueta, 'Diciembre 2026');
    });

    test('el mes más cargado es el que trae más vacas', () {
      final p = proyectarPartos(
        vacas: [
          vaca('a', DateTime(2026, 10, 4)),
          vaca('b', DateTime(2026, 11, 4)),
          vaca('c', DateTime(2026, 11, 18)),
        ],
        hoy: hoy,
      );
      expect(p.mesConMasPartos?.mes, 11);
      expect(p.mesConMasPartos?.cantidad, 2);
    });

    test('sin partos no hay próximo ni pico', () {
      final p = proyectarPartos(vacas: const [], hoy: hoy);
      expect(p.proximoMesConPartos, isNull);
      expect(p.mesConMasPartos, isNull);
    });

    test('las preñadas sin fecha cuentan en el total pero no en los meses', () {
      final p = proyectarPartos(
        vacas: [vaca('44', DateTime(2026, 10, 4))],
        preniadasSinFecha: const ['77', '91'],
        hoy: hoy,
      );
      expect(p.totalEnCalendario, 1);
      expect(p.totalPreniadas, 3);
      expect(p.sinFecha, ['77', '91']);
    });
  });

  group('cómo se lee', () {
    test('el mes se escribe con el nombre de Costa Rica', () {
      final p = proyectarPartos(vacas: const [], hoy: hoy);
      expect(p.meses.first.etiqueta, 'Setiembre 2026');
      expect(p.meses.first.etiquetaCorta, 'Set');
    });

    test('la fecha estimada se distingue de la confirmada', () {
      final v = vaca(
        '44',
        DateTime(2026, 10, 4),
        origen: OrigenFechaParto.estimada,
      );
      expect(v.origen.etiqueta, 'Estimada');
    });
  });
}
