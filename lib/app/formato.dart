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
