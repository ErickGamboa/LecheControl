import 'package:intl/intl.dart';

/// Formato de moneda de la app: colones costarricenses.
///
/// Costa Rica usa el punto como separador de miles, así que `1234567` sale
/// como `₡1.234.567`. Sin decimales: los montos de la lechería (precio del
/// litro, costo de un envase, gastos del mes) se manejan en colones enteros.
///
/// Se arma el símbolo a mano en vez de usar `NumberFormat.currency`: el
/// locale `es_CR` de intl lo pone como sufijo (`1.500 ₡`), pero acá se
/// escribe antes del monto.
final NumberFormat _numeroCR = NumberFormat('#,##0', 'es_CR');

/// Devuelve el monto formateado en colones, p. ej. `₡10.000`.
String colones(num monto) => '₡${_numeroCR.format(monto)}';

/// Un número con decimales al modo de Costa Rica: **coma** decimal y punto de
/// miles, p. ej. `12,40` o `1.234,5`.
///
/// El `toStringAsFixed` de Dart escribe `12.40`, que en la misma pantalla que
/// un `₡3.140,90` se lee como si el punto separara miles. Todo número con
/// decimales que se muestre pasa por acá.
final _decimalesCR = <int, NumberFormat>{};

String decimales(num valor, {int cifras = 2}) =>
    (_decimalesCR[cifras] ??= NumberFormat(
      '#,##0.${'0' * cifras}',
      'es_CR',
    )).format(valor);

/// Colones **con céntimos**, p. ej. `₡3.140,90`.
///
/// Solo para precios que vienen así de la planta —lo que paga por kilo de
/// grasa o de proteína—, donde redondear a colón entero borraría el dato tal
/// como está en la tabla. La plata de la finca sigue en colones enteros.
String colonesConCentimos(num monto) => '₡${decimales(monto)}';

/// Un conteo grande con separador de miles, p. ej. `290.000`.
///
/// Los análisis de calidad de la leche se leen en cientos de miles (células
/// somáticas, UFC): sin separador, `1550000` y `155000` se confunden de un
/// vistazo, que es justo lo que no puede pasar cuando de eso depende el grado.
String miles(num cantidad) => _numeroCR.format(cantidad);
