/// Qué vacas hay que servir (Módulo 6 — Análisis).
///
/// Una vaca que parió y no vuelve a quedar preñada es plata que se va sin que
/// nadie grite: sigue comiendo, sigue ordeñándose cada vez menos, y el día que
/// debería estar pariendo otra vez no hay nada. El intervalo entre partos es
/// el número que más manda en la rentabilidad de una lechería, y depende de
/// una sola cosa: cuánto tarda la vaca en volver a preñarse después de parir.
///
/// Por eso la lista es simple y dura: **parió hace [diasParaServir] días o más
/// y todavía no está preñada**. No importa si está en ordeño o seca, ni si ya
/// se le intentó una monta: mientras no aumente, sigue en la lista.
///
/// Igual que la lista de palpación, esto no toca la base: es la regla y se
/// prueba sola.
library;

import 'grupos.dart';
import 'palpacion.dart' show diasDesde;

/// A partir de cuántos días del parto la vaca entra a la lista.
///
/// Cincuenta días es el arranque del período voluntario de espera: antes de
/// eso la vaca todavía se está recuperando del parto y servirla no es buena
/// idea. De ahí en adelante, cada día que pasa sin preñarse alarga el
/// intervalo entre partos.
const diasParaServir = 50;

/// A qué edad, en meses, una novilla que nunca ha parido entra a la lista.
///
/// Servir antes es meterse con un animal que todavía está creciendo; servir
/// mucho después es tenerla comiendo sin producir. Quince meses es el punto en
/// que ya se puede, y de ahí en adelante cada mes que pasa es plata.
const mesesParaPrimerServicio = 15;

/// Por qué el animal está en la lista.
enum MotivoServir {
  /// Parió y lleva [diasParaServir] días o más sin volver a preñarse.
  vacaAbierta,

  /// Nunca ha parido y ya tiene edad de servirse.
  novillaPrimeriza;

  String get etiqueta => switch (this) {
    MotivoServir.vacaAbierta => 'Vaca abierta',
    MotivoServir.novillaPrimeriza => 'Novilla primeriza',
  };
}

/// Meses completos entre [desde] y [hoy].
///
/// Se cuentan por calendario y no dividiendo días entre 30: a una novilla
/// nacida el 12 de marzo se le cumplen los 15 meses el 12 de junio del año
/// siguiente, no "más o menos por ahí".
int mesesDesde(DateTime desde, {DateTime? hoy}) {
  final referencia = hoy ?? DateTime.now();
  var meses =
      (referencia.year - desde.year) * 12 + (referencia.month - desde.month);
  if (referencia.day < desde.day) meses--;
  return meses;
}

/// La edad escrita como la diría el ganadero: en meses mientras el animal sea
/// joven, en años cuando ya no lo es.
///
/// Hace falta desde que la fecha de nacimiento también se le pone al toro y a
/// la vaca adulta: "56 meses de edad" obliga a dividir de cabeza, y lo que se
/// quiere leer es "4 años y 8 meses".
String edadEnPalabras(int meses) {
  if (meses < 24) return '$meses ${meses == 1 ? 'mes' : 'meses'}';
  final anios = meses ~/ 12;
  final resto = meses % 12;
  if (resto == 0) return '$anios años';
  return '$anios años y $resto ${resto == 1 ? 'mes' : 'meses'}';
}

/// El día en que la novilla cumple la edad de servirse.
DateTime fechaPrimerServicio(DateTime nacimiento) => DateTime(
  nacimiento.year,
  nacimiento.month + mesesParaPrimerServicio,
  nacimiento.day,
);

/// Un animal de la lista, listo para pintar.
class VacaPorServir {
  const VacaPorServir({
    required this.animalId,
    required this.identificador,
    required this.grupo,
    required this.estadoReproductivo,
    required this.motivo,
    required this.servicios,
    required this.diasDeAtraso,
    this.diasLactancia,
    this.mesesEdad,
  });

  final String animalId;
  final String identificador;
  final String grupo;
  final String estadoReproductivo;
  final MotivoServir motivo;

  /// Cuántas montas o inseminaciones lleva sin agarrar: desde el parto en una
  /// vaca, y en toda su vida en una novilla que nunca ha parido. Cero
  /// significa que nadie la ha intentado servir todavía.
  final int servicios;

  /// Cuánto lleva pasada del momento en que se podía servir: días desde los
  /// [diasParaServir] del parto, o desde que cumplió los
  /// [mesesParaPrimerServicio] meses.
  ///
  /// Es lo que **ordena la lista y reparte el color**, y existe para poder
  /// comparar dos cosas que se miden distinto. Entre vacas el orden es el
  /// mismo que daría el DLac —se diferencian en los mismos 50 días—, así que
  /// mezclarlas con las novillas no desordena lo que ya se leía.
  final int diasDeAtraso;

  /// Días desde el último parto (el DLac del reporte). Solo en una vaca.
  final int? diasLactancia;

  /// Meses de edad. Solo en una novilla que nunca ha parido.
  final int? mesesEdad;

  /// El número grande de la tarjeta, con su unidad.
  String get cifra => switch (motivo) {
    MotivoServir.vacaAbierta => '$diasLactancia',
    MotivoServir.novillaPrimeriza => '${mesesEdad}m',
  };

  /// Cómo se lee la segunda línea de la tarjeta.
  String get resumen {
    final cuanto = switch (motivo) {
      MotivoServir.vacaAbierta => '$diasLactancia días de lactancia',
      MotivoServir.novillaPrimeriza => '$mesesEdad meses de edad',
    };
    final s = switch (servicios) {
      0 => 'sin servicios',
      1 => '1 servicio',
      _ => '$servicios servicios',
    };
    return '$cuanto · $s';
  }
}

/// Por qué el animal entra a la lista, con cuánto lleva de atraso. null si no
/// hay que servirlo.
typedef RazonServir = ({MotivoServir motivo, int diasDeAtraso});

/// Si el animal tiene que aparecer en la lista, y por qué.
///
/// [estadoReproductivo] es el de la ficha: una preñada confirmada no se sirve.
///
/// Las dos puertas de entrada son excluyentes por naturaleza: o ya parió —y
/// entonces se mide desde el parto— o nunca ha parido —y entonces se mide
/// desde que nació—. Una novilla sin fecha de nacimiento no entra: no hay
/// forma de saber si ya tiene edad, y meterla a ciegas sería mandar a servir
/// a una ternera.
RazonServir? razonDeServir({
  required String sexo,
  required DateTime? fechaUltimoParto,
  required DateTime? fechaNacimiento,
  required String estadoReproductivo,
  DateTime? hoy,
}) {
  if (sexo != Sexo.hembra) return null;
  if (estadoReproductivo == EstadoReproductivo.preniada) return null;

  final parto = fechaUltimoParto;
  if (parto != null) {
    final atraso = diasDesde(parto, hoy: hoy) - diasParaServir;
    if (atraso < 0) return null;
    return (motivo: MotivoServir.vacaAbierta, diasDeAtraso: atraso);
  }

  final nacimiento = fechaNacimiento;
  if (nacimiento == null) return null;
  final atraso = diasDesde(fechaPrimerServicio(nacimiento), hoy: hoy);
  if (atraso < 0) return null;
  return (motivo: MotivoServir.novillaPrimeriza, diasDeAtraso: atraso);
}

/// Ordena la lista como se lee: la más atrasada de primera.
///
/// El orden **es** la información. Arriba está el animal que lleva más tiempo
/// pudiendo servirse sin que nadie lo haya servido, sea vaca o novilla: las
/// dos cuestan lo mismo cada día que pasan abiertas.
int compararPorServir(VacaPorServir a, VacaPorServir b) {
  final porAtraso = b.diasDeAtraso.compareTo(a.diasDeAtraso);
  if (porAtraso != 0) return porAtraso;
  return a.identificador.compareTo(b.identificador);
}

/// Qué tan urgente es la vaca, de 0 a 1, para el color de la tarjeta.
///
/// 0 es la que menos días lleva de la lista y 1 la que más. Se reparte entre
/// los extremos de **esta** lista y no contra un número fijo: en una finca al
/// día la peor vaca puede llevar 60 días y en una atrasada 300, y en las dos
/// el ganadero necesita ver de un vistazo cuál es la que aprieta.
///
/// Si todas llevan los mismos días no hay a quién señalar y todas van en 1:
/// pintarlas pálidas diría que no urgen, y no es cierto.
double urgencia(int dias, {required int menos, required int mas}) {
  if (mas <= menos) return 1;
  final t = (dias - menos) / (mas - menos);
  return t.clamp(0.0, 1.0);
}
