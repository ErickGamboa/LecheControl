/// Calidad de la leche que se entrega: lo que la planta mide cada semana y
/// cómo se lee ese número.
///
/// Son tres análisis y ninguno se calcula en la finca —los reporta la planta—:
/// **sólidos totales** (%), **células somáticas** (cél./mL) y **conteo
/// bacterial** (UFC/mL). La app los guarda por semana y los grafica; lo único
/// que agrega de su cosecha es decir en qué escalón cayó cada uno, para que el
/// ganadero no tenga que buscar la tabla en el papel.
///
/// De dónde salen los escalones:
/// - El **recuento bacterial** y los **precios por kilo de sólido** son la
///   tabla de la planta, tal como la trajo el cliente. Cuando la planta cambie
///   los rangos o los precios, se cambian acá y en ningún otro lado.
/// - Los de **células somáticas** y **sólidos totales** son referencia
///   general de manejo lechero, no una tabla de pago: sirven para saber si la
///   ubre viene bien y si la leche viene rica, no para calcular la plata.
library;

/// En qué escalón cayó un análisis. La app la usa solo para pintar y para
/// escribir la etiqueta; no hay plata atada a esto.
enum NivelCalidad {
  excelente,
  bueno,
  vigilar,
  malo;

  String get etiqueta => switch (this) {
    NivelCalidad.excelente => 'Excelente',
    NivelCalidad.bueno => 'Bueno',
    NivelCalidad.vigilar => 'Vigilar',
    NivelCalidad.malo => 'Malo',
  };
}

/// Un renglón de una tabla de referencia: de cuánto a cuánto, cómo se llama y
/// qué significa.
///
/// [hasta] nulo es el último renglón ("de ahí para arriba"). Un valor cae en
/// el primer renglón cuyo [hasta] todavía no pasó, así que los huecos de la
/// tabla de la planta (de 290.000 a 291.000, por ejemplo) no dejan a nadie sin
/// escalón: lo que caiga en el hueco baja al renglón siguiente, que es el más
/// exigente de los dos. Ante la duda, el grado que se muestra es el peor —no
/// el que conviene.
class RangoCalidad {
  const RangoCalidad({
    required this.desde,
    required this.hasta,
    required this.etiqueta,
    required this.nivel,
    required this.nota,
  });

  final double desde;
  final double? hasta;

  /// Cómo se llama el escalón en la tabla ("PREMIUM", "A", "Excelente"…).
  final String etiqueta;

  final NivelCalidad nivel;

  /// Qué implica, en una línea, para el que lo lee.
  final String nota;
}

/// El escalón en el que cae [valor] dentro de [tabla]. null si no hay valor.
RangoCalidad? escalonDe(double? valor, List<RangoCalidad> tabla) {
  if (valor == null) return null;
  for (final r in tabla) {
    if (r.hasta == null || valor <= r.hasta!) return r;
  }
  return tabla.last;
}

// ---------------------------------------------------------------- bacterial

/// Recuento bacterial (UFC/mL) según la tabla de la planta, con el grado y lo
/// que le hace al precio base.
///
/// El ajuste va en [RangoCalidad.nota] porque es lo que el ganadero quiere
/// leer: el grado por sí solo no dice cuánta plata cuesta.
const tablaRecuentoBacterial = <RangoCalidad>[
  RangoCalidad(
    desde: 0,
    hasta: 290000,
    etiqueta: 'PREMIUM',
    nivel: NivelCalidad.excelente,
    nota: 'Base +1,5 %',
  ),
  RangoCalidad(
    desde: 291000,
    hasta: 600000,
    etiqueta: 'EXCELENTE',
    nivel: NivelCalidad.bueno,
    nota: 'Base',
  ),
  RangoCalidad(
    desde: 601000,
    hasta: 1550000,
    etiqueta: 'A',
    nivel: NivelCalidad.vigilar,
    nota: 'Base −25 %',
  ),
  RangoCalidad(
    desde: 1551000,
    hasta: 2220000,
    etiqueta: 'B',
    nivel: NivelCalidad.malo,
    nota: 'Base −50 %',
  ),
  RangoCalidad(
    desde: 2221000,
    hasta: null,
    etiqueta: 'C',
    nivel: NivelCalidad.malo,
    nota: 'Base −100 %',
  ),
];

/// Grado bacterial de un conteo, o null si no se anotó.
RangoCalidad? gradoBacterial(double? ufcPorMl) =>
    escalonDe(ufcPorMl, tablaRecuentoBacterial);

// ----------------------------------------------------------------- somáticas

/// Células somáticas (cél./mL). Referencia de manejo, no tabla de pago: dice
/// cómo viene la ubre del hato.
const tablaCelulasSomaticas = <RangoCalidad>[
  RangoCalidad(
    desde: 0,
    hasta: 199999,
    etiqueta: 'Excelente',
    nivel: NivelCalidad.excelente,
    nota: 'Ubre sana',
  ),
  RangoCalidad(
    desde: 200000,
    hasta: 399999,
    etiqueta: 'Bueno',
    nivel: NivelCalidad.bueno,
    nota: 'Algo de mastitis subclínica',
  ),
  RangoCalidad(
    desde: 400000,
    hasta: 749999,
    etiqueta: 'Vigilar',
    nivel: NivelCalidad.vigilar,
    nota: 'Se está perdiendo leche; revisar la rutina de ordeño',
  ),
  RangoCalidad(
    desde: 750000,
    hasta: null,
    etiqueta: 'Alto',
    nivel: NivelCalidad.malo,
    nota: 'Mastitis subclínica extendida; buscar las vacas con problema',
  ),
];

/// En qué escalón caen las células somáticas de la semana.
RangoCalidad? nivelCelulasSomaticas(double? celulasPorMl) =>
    escalonDe(celulasPorMl, tablaCelulasSomaticas);

// ------------------------------------------------------------------ sólidos

/// Sólidos totales (%): grasa + proteína + lactosa y minerales. Entre más
/// altos, más kilos de sólido lleva cada kilo de leche —y los sólidos son lo
/// que la planta paga (ver [tablaPreciosSolidos]).
///
/// La tabla va de menor a mayor como todas, así que el "malo" queda de
/// primero: acá el número bueno es el alto, al revés de las bacterias.
const tablaSolidosTotales = <RangoCalidad>[
  RangoCalidad(
    desde: 0,
    hasta: 10.49,
    etiqueta: 'Bajo',
    nivel: NivelCalidad.malo,
    nota: 'Leche aguada; revisar dieta y energía',
  ),
  RangoCalidad(
    desde: 10.5,
    hasta: 11.49,
    etiqueta: 'Vigilar',
    nivel: NivelCalidad.vigilar,
    nota: 'Por debajo de lo normal para el hato',
  ),
  RangoCalidad(
    desde: 11.5,
    hasta: 12.49,
    etiqueta: 'Bueno',
    nivel: NivelCalidad.bueno,
    nota: 'Dentro de lo normal',
  ),
  RangoCalidad(
    desde: 12.5,
    hasta: null,
    etiqueta: 'Excelente',
    nivel: NivelCalidad.excelente,
    nota: 'Leche rica en sólidos: más kilos de sólido por kilo entregado',
  ),
];

/// En qué escalón caen los sólidos totales de la semana.
RangoCalidad? nivelSolidosTotales(double? porcentaje) =>
    escalonDe(porcentaje, tablaSolidosTotales);

// ------------------------------------------------------------------ precios

/// Lo que la planta paga por kilo de cada sólido, según la tabla del cliente.
///
/// Es informativo: la app no calcula el pago —eso se digita en Finanzas, que
/// es la plata que de verdad entró—. Está acá para que el ganadero vea por qué
/// los sólidos importan y cuánto cambia estar suscrito.
class PrecioSolido {
  const PrecioSolido({
    required this.componente,
    required this.suscrita,
    required this.noSuscrita,
    required this.noSuscritaSobre20,
  });

  final String componente;

  /// Cuota suscrita.
  final double suscrita;

  /// Cuota no suscrita.
  final double noSuscrita;

  /// No suscrita cuando pasa del 20 % de la cuota.
  final double noSuscritaSobre20;
}

const tablaPreciosSolidos = <PrecioSolido>[
  PrecioSolido(
    componente: 'Kg. grasa',
    suscrita: 3140.90,
    noSuscrita: 2355.67,
    noSuscritaSobre20: 1570.45,
  ),
  PrecioSolido(
    componente: 'Kg. proteína',
    suscrita: 3140.90,
    noSuscrita: 2355.67,
    noSuscritaSobre20: 1570.45,
  ),
  PrecioSolido(
    componente: 'Kg. lactosa y min.',
    suscrita: 2556.87,
    noSuscrita: 1917.65,
    noSuscritaSobre20: 1278.44,
  ),
];
