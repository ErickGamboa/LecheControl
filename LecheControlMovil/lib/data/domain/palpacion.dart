/// Qué vacas hay que palpar (Módulo 6 — Análisis).
///
/// El veterinario viene a la finca cada tanto y hay que tener lista la hoja de
/// cuáles revisa. Son dos motivos distintos y ninguno se anota a mano: los dos
/// salen de lo que ya está en la hoja de vida del animal.
///
/// 1. **Recién paridas** — parieron hace [diasRevisionPosparto] días o menos.
///    Es la revisión de posparto. La vaca entra y sale sola de la lista.
/// 2. **Servidas sin confirmar** — se les registró celo, monta o inseminación
///    y todavía no están preñadas. Es el diagnóstico de gestación: se palpa
///    para saber si la vaca **aumentó** o hay que volver a servirla.
///
/// Nada de esto depende de la base de datos a propósito: es la regla de
/// negocio y se prueba sola.
library;

import 'grupos.dart';

/// Hasta cuántos días después del parto la vaca sale en la lista de posparto.
const diasRevisionPosparto = 15;

/// Por qué la vaca está en la lista.
enum MotivoPalpacion {
  /// Parió hace poco: toca la revisión de posparto.
  posparto,

  /// Ya se sirvió y no se ha confirmado la preñez.
  servidaSinConfirmar;

  String get etiqueta => switch (this) {
    MotivoPalpacion.posparto => 'Recién parida',
    MotivoPalpacion.servidaSinConfirmar => 'Servida sin confirmar',
  };

  /// Cómo se escribe en la tabla del PDF, donde la columna es angosta.
  String get etiquetaCorta => switch (this) {
    MotivoPalpacion.posparto => 'Recién parida',
    MotivoPalpacion.servidaSinConfirmar => 'Servida',
  };
}

/// Días completos entre [desde] y [hoy], ignorando la hora.
int diasDesde(DateTime desde, {DateTime? hoy}) {
  final referencia = hoy ?? DateTime.now();
  final a = DateTime(desde.year, desde.month, desde.day);
  final b = DateTime(referencia.year, referencia.month, referencia.day);
  return b.difference(a).inDays;
}

/// La razón por la que una vaca entra a la lista, con la fecha que la puso
/// ahí. null si no hay que palparla.
typedef RazonPalpacion = ({MotivoPalpacion motivo, DateTime fecha});

/// Decide si hay que palpar una vaca, mirando solo su historia reproductiva.
///
/// [fechaUltimoServicio] y [fechaUltimaPalpacion] son las del **último** evento
/// de cada tipo; [estadoReproductivo] es el de la ficha del animal.
///
/// Las reglas, en orden:
///
/// - **Posparto manda.** Si parió hace [diasRevisionPosparto] días o menos,
///   entra por eso aunque además tenga un servicio viejo colgando: lo que toca
///   ahora es la revisión de posparto.
/// - **Preñada confirmada no se palpa.** Ya se sabe la respuesta.
/// - **Un servicio anterior al último parto no cuenta.** Ese servicio ya
///   terminó en parto; volver a listarlo dejaría a la vaca clavada en la lista
///   para siempre.
/// - **Si ya se palpó después del servicio, el trabajo está hecho.** Aunque
///   haya salido vacía: para volver a palparla hace falta un servicio nuevo.
///   Sin esta regla la lista nunca se vaciaría.
RazonPalpacion? razonDePalpacion({
  required DateTime? fechaUltimoParto,
  required DateTime? fechaUltimoServicio,
  required DateTime? fechaUltimaPalpacion,
  required String estadoReproductivo,
  DateTime? hoy,
}) {
  if (fechaUltimoParto != null &&
      diasDesde(fechaUltimoParto, hoy: hoy) <= diasRevisionPosparto &&
      diasDesde(fechaUltimoParto, hoy: hoy) >= 0) {
    return (motivo: MotivoPalpacion.posparto, fecha: fechaUltimoParto);
  }

  if (estadoReproductivo == EstadoReproductivo.preniada) return null;

  final servicio = fechaUltimoServicio;
  if (servicio == null) return null;
  if (fechaUltimoParto != null && !servicio.isAfter(fechaUltimoParto)) {
    return null;
  }
  if (fechaUltimaPalpacion != null &&
      !fechaUltimaPalpacion.isBefore(servicio)) {
    return null;
  }

  return (motivo: MotivoPalpacion.servidaSinConfirmar, fecha: servicio);
}

/// Una vaca de la lista, ya lista para pintar en pantalla o en el PDF.
class VacaPorPalpar {
  const VacaPorPalpar({
    required this.animalId,
    required this.identificador,
    required this.grupo,
    required this.estadoReproductivo,
    required this.motivo,
    required this.fecha,
    required this.dias,
    this.tipoServicio,
    this.toroPajilla,
  });

  final String animalId;
  final String identificador;
  final String grupo;
  final String estadoReproductivo;
  final MotivoPalpacion motivo;

  /// La fecha que la puso en la lista: el parto o el servicio, según [motivo].
  final DateTime fecha;

  /// Cuántos días pasaron desde [fecha]. Entre más, más atrasada está.
  final int dias;

  /// Solo para [MotivoPalpacion.servidaSinConfirmar]: celo, monta o
  /// inseminación.
  final String? tipoServicio;

  /// Con qué toro o pajilla se sirvió, si se anotó.
  final String? toroPajilla;

  /// Cómo se lee el servicio en una línea, p. ej. "Inseminación · Pajilla 44".
  /// Vacío cuando la vaca entró por posparto.
  String get detalleServicio {
    final tipo = tipoServicio;
    if (tipo == null) return '';
    final toro = toroPajilla?.trim();
    final nombre = TipoEventoAnimal.etiqueta(tipo);
    return toro == null || toro.isEmpty ? nombre : '$nombre · $toro';
  }
}

/// Ordena la lista como la va a leer el veterinario: primero las recién
/// paridas —que tienen fecha de vencimiento— y después las servidas, las más
/// atrasadas arriba.
///
/// Dentro de cada motivo manda el número de días, de mayor a menor: la vaca
/// que lleva 60 días servida sin confirmar es más urgente que la de 30.
int compararPorPalpar(VacaPorPalpar a, VacaPorPalpar b) {
  if (a.motivo != b.motivo) return a.motivo.index.compareTo(b.motivo.index);
  return b.dias.compareTo(a.dias);
}
