/// Partos por mes (Módulo 6 — Análisis): qué vacas van a parir y cuándo.
///
/// En la finca la pregunta se hace al revés de como la guarda la app. La app
/// sabe, vaca por vaca, cuándo se espera su parto; el ganadero lo que quiere
/// ver es el **calendario**: cuántas paren en octubre, cuántas en noviembre,
/// para saber en qué mes se le llena el ordeño y en cuál se le vacía.
///
/// El cálculo es el de siempre: una vaca queda preñada y pare unos nueve meses
/// después. Cuando la palpación dejó anotada la fecha probable, se usa esa —es
/// la del veterinario, que vio a la vaca—. Cuando no, se saca del último
/// servicio sumándole la gestación, y la fila queda marcada como **estimada**
/// para que nadie la confunda con una fecha confirmada.
///
/// Nada de esto toca la base de datos a propósito: es la regla y se prueba
/// sola.
library;

import 'grupos.dart';

/// Cuánto dura la preñez de una vaca lechera, en días.
///
/// Son los "nueve meses" de los que se habla en la finca, dichos con el número
/// que usa el veterinario: 283 días es el promedio de la Holstein y la Jersey.
const diasGestacion = 283;

/// Cuántos meses trae el calendario, contando el mes en curso.
const mesesDeProyeccion = 12;

/// El parto que se espera de un servicio hecho el día [servicio].
///
/// `DateTime` acomoda solo el desborde de días, así que sumarle 283 al día
/// cruza los meses y los años sin que haya que hacer cuentas aparte.
DateTime partoProbableDesdeServicio(DateTime servicio) =>
    DateTime(servicio.year, servicio.month, servicio.day + diasGestacion);

/// De dónde salió la fecha de parto de una vaca.
enum OrigenFechaParto {
  /// La anotó la palpación: la fecha del veterinario.
  confirmada,

  /// Se calculó del último servicio más la gestación.
  estimada;

  String get etiqueta => switch (this) {
    OrigenFechaParto.confirmada => 'Confirmada',
    OrigenFechaParto.estimada => 'Estimada',
  };
}

/// Los meses como se escriben en Costa Rica. En minúscula, que es como van
/// dentro de una frase; quien los ponga de título los capitaliza.
const nombresDeMes = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'setiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

String _capitalizar(String texto) =>
    texto.isEmpty ? texto : texto[0].toUpperCase() + texto.substring(1);

/// Una vaca preñada con la fecha en que se espera su parto.
class VacaPorParir {
  const VacaPorParir({
    required this.animalId,
    required this.identificador,
    required this.grupo,
    required this.fechaProbable,
    required this.origen,
    this.fechaServicio,
    this.tipoServicio,
    this.toroPajilla,
  });

  final String animalId;
  final String identificador;
  final String grupo;

  /// Cuándo se espera el parto.
  final DateTime fechaProbable;

  /// Si esa fecha la puso el veterinario o la sacó la app. Ver
  /// [OrigenFechaParto].
  final OrigenFechaParto origen;

  /// El servicio del que viene la preñez, cuando se sabe cuál fue.
  final DateTime? fechaServicio;
  final String? tipoServicio;
  final String? toroPajilla;

  /// Días que faltan para el parto. Negativo si la vaca ya se pasó de fecha.
  int dias({DateTime? hoy}) => diasParaParto(fechaProbable, hoy: hoy) ?? 0;

  /// Una vaca que se pasó de la fecha y todavía no tiene el parto registrado.
  /// Sigue en el calendario —todavía tiene que parir— y va de primera en el
  /// mes en curso.
  bool pasadaDeFecha({DateTime? hoy}) => dias(hoy: hoy) < 0;

  /// Cómo se lee el servicio en una línea, p. ej. "Inseminación · Pajilla 44".
  /// Vacío cuando no se sabe de dónde viene la preñez.
  String get detalleServicio {
    final tipo = tipoServicio;
    if (tipo == null) return '';
    final toro = toroPajilla?.trim();
    final nombre = TipoEventoAnimal.etiqueta(tipo);
    return toro == null || toro.isEmpty ? nombre : '$nombre · $toro';
  }
}

/// Un mes del calendario, con las vacas que paren en él. Puede venir vacío:
/// que un mes no traiga partos también es información.
class MesDePartos {
  const MesDePartos({
    required this.anio,
    required this.mes,
    required this.vacas,
  });

  final int anio;

  /// 1 = enero.
  final int mes;

  final List<VacaPorParir> vacas;

  int get cantidad => vacas.length;
  bool get vacio => vacas.isEmpty;

  /// "Octubre 2026".
  String get etiqueta => '${_capitalizar(nombresDeMes[mes - 1])} $anio';

  /// "Oct" — para debajo de una barra del gráfico, donde no cabe más. En una
  /// ventana de doce meses ningún mes se repite, así que no hace falta el año.
  String get etiquetaCorta =>
      _capitalizar(nombresDeMes[mes - 1].substring(0, 3));
}

/// El calendario completo: los doce meses, más lo que quedó por fuera.
class ProyeccionPartos {
  const ProyeccionPartos({
    required this.meses,
    required this.sinFecha,
    required this.fueraDeRango,
  });

  final List<MesDePartos> meses;

  /// Preñadas a las que no se les puede calcular el parto: no tienen fecha
  /// probable anotada ni un servicio posterior al último parto del cual
  /// sacarla. Se listan por identificador para poder ir a arreglarlas.
  final List<String> sinFecha;

  /// Preñadas cuya fecha cae más allá del último mes del calendario. Casi
  /// siempre es una fecha mal digitada, y taparla sería peor que mostrarla.
  final List<VacaPorParir> fueraDeRango;

  /// Cuántas vacas trae el calendario.
  int get totalEnCalendario => meses.fold(0, (suma, m) => suma + m.cantidad);

  /// Todas las preñadas de la finca, salgan o no en el calendario.
  int get totalPreniadas =>
      totalEnCalendario + sinFecha.length + fueraDeRango.length;

  /// El primer mes que trae partos, para el resumen de arriba. null si el
  /// calendario viene vacío.
  MesDePartos? get proximoMesConPartos {
    for (final m in meses) {
      if (!m.vacio) return m;
    }
    return null;
  }

  /// El mes más cargado: el que hay que ver venir. null si no hay ninguno.
  MesDePartos? get mesConMasPartos {
    MesDePartos? mayor;
    for (final m in meses) {
      if (m.vacio) continue;
      if (mayor == null || m.cantidad > mayor.cantidad) mayor = m;
    }
    return mayor;
  }
}

/// Dentro de un mes mandan los días: la que pare el 3 va antes que la del 20.
/// A igual día, por identificador, para que la lista no baile entre aperturas.
int compararPorParir(VacaPorParir a, VacaPorParir b) {
  final porFecha = a.fechaProbable.compareTo(b.fechaProbable);
  if (porFecha != 0) return porFecha;
  return a.identificador.compareTo(b.identificador);
}

/// Reparte las vacas preñadas en los [meses] meses que arrancan en el mes en
/// curso.
///
/// Dos decisiones que no son obvias:
///
/// - **La vaca pasada de fecha entra en el mes en curso.** Su parto quedó
///   atrás en el calendario pero no ocurrió —si hubiera ocurrido, el evento de
///   parto la habría dejado vacía—, así que sigue pendiente, y el mes de hoy
///   es donde alguien la va a ver.
/// - **La que cae más allá del último mes no se reparte**, se aparta en
///   [ProyeccionPartos.fueraDeRango]. Con 283 días de gestación ninguna preñez
///   real llega tan lejos: es una fecha mal digitada y conviene que se vea.
ProyeccionPartos proyectarPartos({
  required List<VacaPorParir> vacas,
  List<String> preniadasSinFecha = const [],
  DateTime? hoy,
  int meses = mesesDeProyeccion,
}) {
  final referencia = hoy ?? DateTime.now();
  final inicio = DateTime(referencia.year, referencia.month);
  // Primer mes que ya no cabe. `DateTime` acomoda el desborde, así que
  // sumarle 12 a un mes de setiembre da setiembre del año siguiente.
  final limite = DateTime(referencia.year, referencia.month + meses);

  final baldes = List.generate(meses, (_) => <VacaPorParir>[]);
  final fuera = <VacaPorParir>[];

  for (final v in vacas) {
    final mesDeLaVaca = DateTime(v.fechaProbable.year, v.fechaProbable.month);
    if (!mesDeLaVaca.isBefore(limite)) {
      fuera.add(v);
      continue;
    }
    final indice = mesDeLaVaca.isBefore(inicio)
        ? 0
        : (mesDeLaVaca.year - inicio.year) * 12 +
              (mesDeLaVaca.month - inicio.month);
    baldes[indice].add(v);
  }

  for (final balde in baldes) {
    balde.sort(compararPorParir);
  }
  fuera.sort(compararPorParir);

  final calendario = <MesDePartos>[];
  for (var i = 0; i < meses; i++) {
    final mes = DateTime(inicio.year, inicio.month + i);
    calendario.add(
      MesDePartos(
        anio: mes.year,
        mes: mes.month,
        vacas: List.unmodifiable(baldes[i]),
      ),
    );
  }

  return ProyeccionPartos(
    meses: List.unmodifiable(calendario),
    sinFecha: List.unmodifiable(preniadasSinFecha),
    fueraDeRango: List.unmodifiable(fuera),
  );
}
