/// Dieta de concentrado: cuánto concentrado le corresponde a una vaca según lo que
/// está dando de leche (Módulo 6 — Análisis).
///
/// La regla de la finca es una proporción: **cada tantos kilos de leche pagan
/// un kilo de concentrado**. Con 3, una vaca de 18 L come 6 kg. El número lo
/// edita el ganadero en Ajuste de métricas, porque depende del precio de la
/// leche, del concentrado y de cómo esté la finca.
///
/// Nada de esto depende de la base de datos a propósito: es la regla de
/// negocio y se prueba sola.
library;

/// Con cuántos kilos de leche arranca una lechería nueva por cada kilo de
/// concentrado.
const kgLechePorKgConcentradoPorDefecto = 3.0;

/// Kilos de concentrado que le corresponden a una vaca que dio [litrosLeche].
///
/// [kgLechePorKg] es la proporción de la finca. Devuelve null si la
/// proporción no sirve para dividir (cero o negativa), en vez de un infinito
/// que se colaría hasta la pantalla.
double? racionConcentrado({
  required double litrosLeche,
  required double kgLechePorKg,
}) {
  if (kgLechePorKg <= 0) return null;
  if (litrosLeche <= 0) return 0;
  return litrosLeche / kgLechePorKg;
}

/// Lo que le corresponde a una vaca contra lo que está recibiendo.
class RacionVaca {
  const RacionVaca({
    required this.identificador,
    required this.esManual,
    required this.litrosLeche,
    required this.fechaPesa,
    required this.concentradoActualKg,
    required this.racionKg,
  });

  final String identificador;

  /// Vaca pesada que no está en el inventario: se muestra con asterisco, igual
  /// que en el reporte de producción.
  final bool esManual;

  /// Litros de su pesa más reciente — de ahí sale la ración.
  final double litrosLeche;

  /// Cuándo fue esa pesa. Se muestra porque cada vaca puede venir de una pesa
  /// distinta: la que no se pesó esta semana arrastra la de la anterior.
  final DateTime fechaPesa;

  /// Concentrado que se le anotó en esa misma pesa. null cuando no se anotó.
  final double? concentradoActualKg;

  /// Lo que debería comer según la regla de la finca.
  final double? racionKg;

  /// Cuánto le falta (positivo) o le sobra (negativo) contra la ración.
  /// null si no hay ración calculable o si no se anotó lo que come.
  double? get diferenciaKg {
    final racion = racionKg;
    final actual = concentradoActualKg;
    if (racion == null || actual == null) return null;
    return racion - actual;
  }
}
