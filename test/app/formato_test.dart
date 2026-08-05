import 'package:flutter_test/flutter_test.dart';
import 'package:leche_control/app/formato.dart';

void main() {
  test('formatea montos en colones con separador de miles', () {
    expect(colones(0), '₡0');
    expect(colones(10000), '₡10.000');
    expect(colones(1234567), '₡1.234.567');
  });

  test('redondea a colones enteros', () {
    expect(colones(1500.4), '₡1.500');
    expect(colones(1500.6), '₡1.501');
  });
}
