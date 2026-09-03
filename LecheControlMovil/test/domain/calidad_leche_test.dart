// Los escalones de calidad son la tabla de la planta: si uno se corre, la app
// muestra un grado que no es el que se paga.

import 'package:flutter_test/flutter_test.dart';
import 'package:leche_control/data/domain/calidad_leche.dart';

void main() {
  group('recuento bacterial', () {
    test('cada rango de la tabla de la planta da su grado', () {
      expect(gradoBacterial(0)?.etiqueta, 'PREMIUM');
      expect(gradoBacterial(290000)?.etiqueta, 'PREMIUM');
      expect(gradoBacterial(291000)?.etiqueta, 'EXCELENTE');
      expect(gradoBacterial(600000)?.etiqueta, 'EXCELENTE');
      expect(gradoBacterial(601000)?.etiqueta, 'A');
      expect(gradoBacterial(1550000)?.etiqueta, 'A');
      expect(gradoBacterial(1551000)?.etiqueta, 'B');
      expect(gradoBacterial(2220000)?.etiqueta, 'B');
      expect(gradoBacterial(2221000)?.etiqueta, 'C');
      expect(gradoBacterial(9000000)?.etiqueta, 'C');
    });

    test('un valor en el hueco entre dos rangos cae en el más exigente', () {
      // La tabla salta de 290.000 a 291.000. Un 290.500 no puede quedarse sin
      // grado: cae al renglón siguiente, que es el peor de los dos. Ante la
      // duda, el grado que se muestra nunca es el que conviene.
      expect(gradoBacterial(290500)?.etiqueta, 'EXCELENTE');
      expect(gradoBacterial(600500)?.etiqueta, 'A');
    });

    test('el ajuste al valor acompaña al grado', () {
      expect(gradoBacterial(100000)?.nota, 'Base +1,5 %');
      expect(gradoBacterial(3000000)?.nota, 'Base −100 %');
    });

    test('sin conteo anotado no hay grado', () {
      expect(gradoBacterial(null), isNull);
    });
  });

  group('células somáticas', () {
    test('sube de escalón conforme sube el conteo', () {
      expect(nivelCelulasSomaticas(150000)?.etiqueta, 'Excelente');
      expect(nivelCelulasSomaticas(200000)?.etiqueta, 'Bueno');
      expect(nivelCelulasSomaticas(400000)?.etiqueta, 'Vigilar');
      expect(nivelCelulasSomaticas(750000)?.etiqueta, 'Alto');
    });

    test('más células es peor', () {
      expect(nivelCelulasSomaticas(150000)?.nivel, NivelCalidad.excelente);
      expect(nivelCelulasSomaticas(900000)?.nivel, NivelCalidad.malo);
    });
  });

  group('sólidos totales', () {
    test('acá el número alto es el bueno', () {
      expect(nivelSolidosTotales(9)?.nivel, NivelCalidad.malo);
      expect(nivelSolidosTotales(11)?.nivel, NivelCalidad.vigilar);
      expect(nivelSolidosTotales(12)?.nivel, NivelCalidad.bueno);
      expect(nivelSolidosTotales(13)?.nivel, NivelCalidad.excelente);
    });

    test('los bordes de la tabla caen donde dice la tabla', () {
      expect(nivelSolidosTotales(10.49)?.etiqueta, 'Bajo');
      expect(nivelSolidosTotales(10.5)?.etiqueta, 'Vigilar');
      expect(nivelSolidosTotales(11.5)?.etiqueta, 'Bueno');
      expect(nivelSolidosTotales(12.5)?.etiqueta, 'Excelente');
    });
  });

  test('los precios por kilo de sólido son los de la tabla de la planta', () {
    final grasa = tablaPreciosSolidos.first;
    expect(grasa.suscrita, 3140.90);
    expect(grasa.noSuscrita, 2355.67);
    expect(grasa.noSuscritaSobre20, 1570.45);

    final lactosa = tablaPreciosSolidos.last;
    expect(lactosa.suscrita, 2556.87);
    expect(lactosa.noSuscrita, 1917.65);
    expect(lactosa.noSuscritaSobre20, 1278.44);
  });
}
