/// Qué vacas hay que secar (Módulo 6 — Análisis).
///
/// La vaca preñada necesita dos meses largos sin ordeñar antes de parir: es
/// cuando repone cuerpo y arma la ubre para la lactancia que viene. Secarla
/// tarde —o no secarla— le cuesta leche a la lactancia siguiente y le cuesta
/// la cría a la vaca.
///
/// El problema es que **nadie se acuerda solo**. La vaca está produciendo, va
/// al ordeño todos los días y no hay nada que avise; para cuando alguien mira
/// la fecha probable de parto, ya se pasó. Esta lista es ese aviso: sale sola
/// a los [diasParaSecar] días del parto y **no se va hasta que se seque**.
library;

import 'palpacion.dart' show diasDesde;

/// A cuántos días del parto hay que secar la vaca.
///
/// Setenta días. Es el período seco que se maneja en la finca; por debajo de
/// los sesenta la vaca llega sin reservas a la próxima lactancia.
const diasParaSecar = 70;

/// Días de hoy a la fecha probable de parto. Negativo si ya se pasó.
int diasParaParir(DateTime fechaProbableParto, {DateTime? hoy}) =>
    -diasDesde(fechaProbableParto, hoy: hoy);

/// Si a esta vaca le corresponde secarse, y cuántos días le faltan para parir.
///
/// Entra la que está **preñada, con fecha probable de parto, a
/// [diasParaSecar] días o menos, y que todavía no está en Secas**.
///
/// Las tres condiciones importan:
///
/// - **Preñada con fecha.** Sin fecha probable no hay de dónde contar. Una
///   vaca sin palpar no se seca a ciegas: lo que le corresponde es aparecer en
///   Vacas por palpar.
/// - **Que no esté seca.** Es lo único que la saca de la lista, y es lo que
///   hace que la lista sirva: mientras la vaca siga en ordeño el aviso sigue
///   ahí, y se va sola el día que se registre el secado.
/// - **Sin piso por abajo.** Una vaca que se pasó de la fecha y sigue en
///   ordeño no desaparece del aviso: al revés, es la más urgente de todas.
///
/// Devuelve null si no le corresponde. El número puede ser negativo, y eso es
/// exactamente lo que hay que ver.
int? diasQueFaltanParaSecar({
  required String grupo,
  required String estadoReproductivo,
  required DateTime? fechaProbableParto,
  DateTime? hoy,
}) {
  if (grupo == _secas) return null;
  if (estadoReproductivo != _preniada) return null;
  final parto = fechaProbableParto;
  if (parto == null) return null;
  final faltan = diasParaParir(parto, hoy: hoy);
  return faltan <= diasParaSecar ? faltan : null;
}

const _secas = 'secas';
const _preniada = 'preñada';

/// Una vaca de la lista, lista para pintar.
class VacaPorSecar {
  const VacaPorSecar({
    required this.animalId,
    required this.identificador,
    this.alias,
    required this.grupo,
    required this.diasParaParir,
    required this.diasLactancia,
    required this.ultimaProduccion,
  });

  final String animalId;
  final String identificador;
  final String? alias;
  final String grupo;

  /// Cuántos días le faltan para parir. Negativo si ya se pasó de la fecha.
  final int diasParaParir;

  /// Cuántos días lleva de parida, si se sabe.
  final int? diasLactancia;

  /// Cuántos litros dio en la última pesa, si la hay. Es lo que decide si
  /// secarla duele: una vaca en 6 litros se seca sin pensarlo.
  final double? ultimaProduccion;

  /// Se pasó de la fecha probable y sigue sin secarse.
  bool get pasadaDeFecha => diasParaParir < 0;

  /// El número grande de la tarjeta.
  String get cifra => pasadaDeFecha ? '+${-diasParaParir}' : '$diasParaParir';

  /// La línea de abajo, en palabras.
  String get resumen {
    final cuando = switch (diasParaParir) {
      < 0 => 'se pasó ${-diasParaParir} días de la fecha de parto',
      0 => 'pare hoy',
      1 => 'pare mañana',
      final d => 'le faltan $d días para parir',
    };
    final leche = ultimaProduccion == null
        ? null
        : '${ultimaProduccion!.toStringAsFixed(1)} L en la última pesa';
    return [cuando, ?leche].join(' · ');
  }
}

/// La más urgente primero: la que menos le falta para parir. La que ya se pasó
/// de la fecha queda de primera de todas, que es donde tiene que estar.
int compararPorSecar(VacaPorSecar a, VacaPorSecar b) {
  final porDias = a.diasParaParir.compareTo(b.diasParaParir);
  if (porDias != 0) return porDias;
  return a.identificador.compareTo(b.identificador);
}
