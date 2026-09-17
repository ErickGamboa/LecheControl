/// Qué vacas hay que palpar (Módulo 6 — Análisis).
///
/// El veterinario viene a la finca cada tanto y hay que tener lista la hoja de
/// cuáles revisa. Son dos motivos distintos y ninguno se anota a mano: los dos
/// salen de lo que ya está en la hoja de vida del animal.
///
/// 1. **Servidas sin confirmar** — se les registró monta o inseminación y
///    todavía no están preñadas. Es el diagnóstico de gestación: se palpa para
///    saber si la vaca **aumentó** o hay que volver a servirla. El celo no
///    entra: es una observación de que la vaca está en calor, no un servicio,
///    y no hay nada que confirmar después de él.
/// 2. **Paridas sin diagnóstico** — parieron hace más de
///    [diasSinDiagnostico] días y nadie les ha registrado preñez ni vacío.
///    Estas **no salen solas**: salen cuando se les registra el diagnóstico.
///
/// Nada de esto depende de la base de datos a propósito: es la regla de
/// negocio y se prueba sola.
library;

import 'grupos.dart';

/// A partir de cuántos días del parto una vaca sin diagnóstico entra a la
/// lista.
///
/// **Cambió de sentido.** Antes marcaba una ventana —la vaca entraba los
/// primeros 15 días y salía sola al día 16, hubiera pasado el veterinario o
/// no—. Ahora es un piso: se le da ese margen a la vaca recién parida y, si
/// pasado eso **nadie le ha dicho si quedó preñada o vacía**, entra a la lista
/// y no sale hasta que se le registre. Una vaca sin diagnosticar no deja de
/// necesitar palpación porque pase el tiempo; al revés.
const diasSinDiagnostico = 15;

/// Por qué la vaca está en la lista.
enum MotivoPalpacion {
  /// Ya se sirvió y no se ha confirmado la preñez.
  servidaSinConfirmar,

  /// Parió hace rato y nadie le ha registrado preñez ni vacío.
  paridaSinDiagnostico;

  String get etiqueta => switch (this) {
    MotivoPalpacion.servidaSinConfirmar => 'Servida sin confirmar',
    MotivoPalpacion.paridaSinDiagnostico => 'Parida sin diagnóstico',
  };

  /// Cómo se escribe en la tabla del PDF, donde la columna es angosta.
  String get etiquetaCorta => switch (this) {
    MotivoPalpacion.servidaSinConfirmar => 'Servida',
    MotivoPalpacion.paridaSinDiagnostico => 'Sin diagnóstico',
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
/// [fechaUltimoServicio] es la del último servicio **de verdad** —monta o
/// inseminación—; el celo no cuenta, es solo una observación de que la vaca
/// está en calor y no hay nada que confirmar después de él.
/// [fechaUltimaPalpacion] es la del último diagnóstico y [estadoReproductivo]
/// el de la ficha.
///
/// Las reglas, en orden:
///
/// - **Preñada confirmada no se palpa.** Ya se sabe la respuesta.
/// - **Servida y sin confirmar manda.** Es el dato más útil para el
///   veterinario: sabe con qué se sirvió y hace cuánto. Un servicio anterior
///   al último parto no cuenta —ese ya terminó en parto— y si ya se palpó
///   después del servicio el trabajo está hecho, aunque haya salido vacía:
///   para volver a listarla hace falta un servicio nuevo.
/// - **Parida y sin diagnóstico.** Pasados [diasSinDiagnostico] días del
///   parto, si nadie le registró preñez ni vacío, entra. Y **no sale sola**:
///   sale cuando se le registra el diagnóstico.
RazonPalpacion? razonDePalpacion({
  required DateTime? fechaUltimoParto,
  required DateTime? fechaUltimoServicio,
  required DateTime? fechaUltimaPalpacion,
  required String estadoReproductivo,
  DateTime? hoy,
}) {
  if (estadoReproductivo == EstadoReproductivo.preniada) return null;

  final servicio = fechaUltimoServicio;
  final servicioVigente =
      servicio != null &&
      (fechaUltimoParto == null || servicio.isAfter(fechaUltimoParto)) &&
      (fechaUltimaPalpacion == null || fechaUltimaPalpacion.isBefore(servicio));
  if (servicioVigente) {
    return (motivo: MotivoPalpacion.servidaSinConfirmar, fecha: servicio);
  }

  final parto = fechaUltimoParto;
  if (parto != null &&
      diasDesde(parto, hoy: hoy) > diasSinDiagnostico &&
      (fechaUltimaPalpacion == null || !fechaUltimaPalpacion.isAfter(parto))) {
    return (motivo: MotivoPalpacion.paridaSinDiagnostico, fecha: parto);
  }

  return null;
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
  /// Vacío cuando la vaca entró por no tener diagnóstico.
  String get detalleServicio {
    final tipo = tipoServicio;
    if (tipo == null) return '';
    final toro = toroPajilla?.trim();
    final nombre = TipoEventoAnimal.etiqueta(tipo);
    return toro == null || toro.isEmpty ? nombre : '$nombre · $toro';
  }
}

/// Ordena la lista como la va a leer el veterinario: primero las servidas sin
/// confirmar —que es lo que vino a hacer— y después las paridas sin
/// diagnóstico, las más atrasadas arriba.
///
/// Dentro de cada motivo manda el número de días, de mayor a menor: la vaca
/// que lleva 60 días servida sin confirmar es más urgente que la de 30.
int compararPorPalpar(VacaPorPalpar a, VacaPorPalpar b) {
  if (a.motivo != b.motivo) return a.motivo.index.compareTo(b.motivo.index);
  return b.dias.compareTo(a.dias);
}
