/// Curva de referencia de lactancia: cuántos litros se esperan de una vaca
/// según cuántos días lleva desde su último parto (Módulo 3 — reporte de
/// producción).
///
/// La referencia se guarda como **siete tramos** editables por el ganadero
/// (tabla `curva_referencia`). Para una vaca concreta el esperado NO es el
/// escalón del tramo: si lo fuera, una vaca de 30 días esperaría 18.8 L y al
/// día siguiente 26 L, y pasaría de "Excelente" a "Muy Bajo" sin haber
/// cambiado nada. Por eso cada tramo aporta **un punto en su día central** y
/// entre puntos se traza una recta.
///
/// Nada de esto depende de la base de datos a propósito: es la regla de
/// negocio y se prueba sola.
library;

/// Un tramo de la curva: de [diaDesde] a [diaHasta] se esperan
/// [litrosEsperados]. El último tramo tiene [diaHasta] nulo ("de 306 días en
/// adelante").
class TramoCurva {
  const TramoCurva({
    required this.diaDesde,
    required this.diaHasta,
    required this.litrosEsperados,
  });

  final int diaDesde;
  final int? diaHasta;
  final double litrosEsperados;

  /// Día que representa al tramo dentro de la curva. Para el tramo abierto
  /// (sin tope) se usa un punto 25 días adentro, que es lo que dura en
  /// promedio antes de que la vaca se seque.
  double get diaCentro {
    final hasta = diaHasta;
    return hasta == null ? diaDesde + 25 : (diaDesde + hasta) / 2;
  }
}

/// Cómo se califica una vaca comparando lo que dio contra lo que se esperaba.
enum EvaluacionVaca {
  excelente,
  bueno,
  vigilar,
  bajo,
  muyBajo;

  String get etiqueta => switch (this) {
    EvaluacionVaca.excelente => 'Excelente',
    EvaluacionVaca.bueno => 'Bueno',
    EvaluacionVaca.vigilar => 'Vigilar',
    EvaluacionVaca.bajo => 'Bajo',
    EvaluacionVaca.muyBajo => 'Muy bajo',
  };

  /// Qué hacer con la vaca, para el bloque de recomendaciones del reporte.
  RecomendacionVaca get recomendacion => switch (this) {
    EvaluacionVaca.excelente ||
    EvaluacionVaca.bueno => RecomendacionVaca.mantener,
    EvaluacionVaca.vigilar => RecomendacionVaca.vigilar,
    EvaluacionVaca.bajo || EvaluacionVaca.muyBajo => RecomendacionVaca.revisar,
  };
}

enum RecomendacionVaca {
  mantener,
  vigilar,
  revisar;

  String get titulo => switch (this) {
    RecomendacionVaca.mantener => 'Mantener',
    RecomendacionVaca.vigilar => 'Vigilar',
    RecomendacionVaca.revisar => 'Revisar / decisión',
  };

  String get descripcion => switch (this) {
    RecomendacionVaca.mantener =>
      'Vacas con producción acorde o superior a lo esperado según sus días '
          'en leche. Continuar con el manejo actual.',
    RecomendacionVaca.vigilar =>
      'Vacas con producción moderada o ligeramente baja. Revisar '
          'alimentación, condición corporal y reproducción.',
    RecomendacionVaca.revisar =>
      'Vacas con producción muy baja para su etapa de lactancia. Revisar '
          'salud, reproducción y evaluar descarte.',
  };
}

/// Umbrales de `producción ÷ esperado` (en porcentaje) para calificar. Los
/// edita el ganadero; estos son los valores por defecto.
class UmbralesEvaluacion {
  const UmbralesEvaluacion({
    this.excelente = 100,
    this.bueno = 85,
    this.vigilar = 70,
    this.bajo = 60,
  });

  final double excelente;
  final double bueno;
  final double vigilar;
  final double bajo;

  EvaluacionVaca evaluar(double porcentaje) {
    if (porcentaje >= excelente) return EvaluacionVaca.excelente;
    if (porcentaje >= bueno) return EvaluacionVaca.bueno;
    if (porcentaje >= vigilar) return EvaluacionVaca.vigilar;
    if (porcentaje >= bajo) return EvaluacionVaca.bajo;
    return EvaluacionVaca.muyBajo;
  }
}

/// La curva armada a partir de sus tramos.
class CurvaLactancia {
  CurvaLactancia(List<TramoCurva> tramos)
    : _tramos = [...tramos]..sort((a, b) => a.diaDesde.compareTo(b.diaDesde));

  final List<TramoCurva> _tramos;

  List<TramoCurva> get tramos => List.unmodifiable(_tramos);

  bool get estaVacia => _tramos.isEmpty;

  /// Tramos con los que arranca una lechería nueva. Vienen del reporte que
  /// trajo el cliente; son un punto de partida, no una verdad, y se editan
  /// desde la app.
  static const tramosPorDefecto = <TramoCurva>[
    TramoCurva(diaDesde: 0, diaHasta: 30, litrosEsperados: 18.8),
    TramoCurva(diaDesde: 31, diaHasta: 70, litrosEsperados: 26),
    TramoCurva(diaDesde: 71, diaHasta: 120, litrosEsperados: 24),
    TramoCurva(diaDesde: 121, diaHasta: 180, litrosEsperados: 21),
    TramoCurva(diaDesde: 181, diaHasta: 240, litrosEsperados: 18),
    TramoCurva(diaDesde: 241, diaHasta: 305, litrosEsperados: 14),
    TramoCurva(diaDesde: 306, diaHasta: null, litrosEsperados: 10),
  ];

  /// Litros esperados de una vaca con [diasLactancia] días desde su parto.
  ///
  /// Interpola linealmente entre los días centrales de los tramos. Antes del
  /// primer centro y después del último se mantiene plano: extrapolar daría
  /// valores sin sentido (negativos en los extremos).
  ///
  /// Devuelve null si la curva no tiene tramos cargados.
  double? esperadoPara(int diasLactancia) {
    if (_tramos.isEmpty) return null;
    if (_tramos.length == 1) return _tramos.single.litrosEsperados;

    final d = diasLactancia.toDouble();
    if (d <= _tramos.first.diaCentro) return _tramos.first.litrosEsperados;
    if (d >= _tramos.last.diaCentro) return _tramos.last.litrosEsperados;

    for (var i = 0; i < _tramos.length - 1; i++) {
      final izq = _tramos[i];
      final der = _tramos[i + 1];
      if (d >= izq.diaCentro && d <= der.diaCentro) {
        final ancho = der.diaCentro - izq.diaCentro;
        if (ancho == 0) return izq.litrosEsperados;
        final avance = (d - izq.diaCentro) / ancho;
        return izq.litrosEsperados +
            avance * (der.litrosEsperados - izq.litrosEsperados);
      }
    }
    return _tramos.last.litrosEsperados;
  }

  /// Qué porcentaje de lo esperado dio la vaca. null si no hay referencia o
  /// si el esperado es 0 (no se puede dividir).
  double? porcentajeDelEsperado(int diasLactancia, double litrosProducidos) {
    final esperado = esperadoPara(diasLactancia);
    if (esperado == null || esperado <= 0) return null;
    return litrosProducidos / esperado * 100;
  }

  /// A qué tramo pertenece una vaca, para agrupar el hato en el gráfico
  /// "ideal vs promedio del hato". null si no cae en ninguno.
  TramoCurva? tramoDe(int diasLactancia) {
    for (final t in _tramos) {
      final hasta = t.diaHasta;
      if (diasLactancia >= t.diaDesde &&
          (hasta == null || diasLactancia <= hasta)) {
        return t;
      }
    }
    return null;
  }
}

/// Días de lactancia (DLac): cuántos días lleva la vaca desde su último
/// parto. null si nunca se le registró uno — en el reporte esas vacas salen
/// sin DLac y no se comparan contra la curva.
int? diasLactancia(DateTime? fechaUltimoParto, {DateTime? hoy}) {
  if (fechaUltimoParto == null) return null;
  final ahora = hoy ?? DateTime.now();
  final desde = DateTime(
    fechaUltimoParto.year,
    fechaUltimoParto.month,
    fechaUltimoParto.day,
  );
  final hasta = DateTime(ahora.year, ahora.month, ahora.day);
  final dias = hasta.difference(desde).inDays;
  return dias < 0 ? null : dias;
}
