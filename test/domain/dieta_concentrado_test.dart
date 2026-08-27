import 'package:flutter_test/flutter_test.dart';
import 'package:leche_control/data/domain/dieta_concentrado.dart';

void main() {
  group('racionConcentrado', () {
    test('con 3 kg de leche por kilo, una vaca de 18 L come 6 kg', () {
      expect(racionConcentrado(litrosLeche: 18, kgLechePorKg: 3), 6);
    });

    test('la proporción cambia la ración', () {
      // Con una regla más generosa (menos leche paga un kilo) come más.
      expect(racionConcentrado(litrosLeche: 18, kgLechePorKg: 2), 9);
      // Y con una más apretada, menos.
      expect(racionConcentrado(litrosLeche: 18, kgLechePorKg: 4), 4.5);
    });

    test('una vaca sin leche no come concentrado de producción', () {
      expect(racionConcentrado(litrosLeche: 0, kgLechePorKg: 3), 0);
    });

    test('una proporción de cero no da infinito, da null', () {
      // Dividir por cero se colaría hasta la pantalla como "Infinity kg".
      expect(racionConcentrado(litrosLeche: 18, kgLechePorKg: 0), isNull);
      expect(racionConcentrado(litrosLeche: 18, kgLechePorKg: -1), isNull);
    });
  });

  group('RacionVaca.diferenciaKg', () {
    RacionVaca racion({double? racionKg, double? actual}) => RacionVaca(
      identificador: '1',
      esManual: false,
      litrosLeche: 18,
      fechaPesa: DateTime(2026, 8, 17),
      concentradoActualKg: actual,
      racionKg: racionKg,
    );

    test('positiva cuando le falta concentrado', () {
      expect(racion(racionKg: 6, actual: 4).diferenciaKg, 2);
    });

    test('negativa cuando le sobra', () {
      expect(racion(racionKg: 6, actual: 7.5).diferenciaKg, -1.5);
    });

    test('null si no se anotó lo que come', () {
      expect(racion(racionKg: 6).diferenciaKg, isNull);
    });

    test('null si no hay ración que comparar', () {
      expect(racion(actual: 4).diferenciaKg, isNull);
    });
  });
}
