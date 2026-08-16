/// La semana de la finca: de lunes a domingo. Es el período con el que se
/// manejan las finanzas (Módulo 4 y 5) — ingresos, gastos y utilidad.
library;

/// Lunes de la semana en la que cae [fecha], a las 00:00.
DateTime lunesDe(DateTime fecha) {
  final dia = DateTime(fecha.year, fecha.month, fecha.day);
  // DateTime.weekday: lunes = 1 … domingo = 7.
  return dia.subtract(Duration(days: dia.weekday - DateTime.monday));
}

/// Domingo de la semana en la que cae [fecha], a las 00:00.
DateTime domingoDe(DateTime fecha) =>
    lunesDe(fecha).add(const Duration(days: 6));

/// Cómo se nombra una semana en pantalla, p. ej. "10 - 16 de agosto" o
/// "29 de setiembre - 5 de octubre" cuando cruza de mes.
String etiquetaSemana(DateTime inicio, DateTime fin) {
  if (inicio.month == fin.month) {
    return '${inicio.day} - ${fin.day} de ${_meses[fin.month - 1]}';
  }
  return '${inicio.day} de ${_meses[inicio.month - 1]} - '
      '${fin.day} de ${_meses[fin.month - 1]}';
}

const _meses = [
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

/// Tipos de ingreso que entran a la finca.
abstract final class TipoIngreso {
  static const leche = 'leche';
  static const ventaGanado = 'venta_ganado';
  static const otro = 'otro';

  static const todos = [leche, ventaGanado, otro];

  static String etiqueta(String tipo) => switch (tipo) {
    leche => 'Leche',
    ventaGanado => 'Venta de ganado',
    _ => 'Otro',
  };
}

/// En qué se va la plata de la semana.
///
/// [todos] son los botones que ve el ganadero: se toca uno y listo, sin
/// escribir. Si el gasto no es ninguno de esos, todavía puede escribirlo a
/// mano.
///
/// [compraGanado] no está entre los botones a propósito: no se anota a mano.
/// Lo mete la app sola cuando se registra un animal comprado con su precio
/// (ver `AnimalesRepository.altaAnimal`).
abstract final class CategoriaGasto {
  static const salarios = 'Salarios';
  static const luz = 'Luz';
  static const concentrado = 'Concentrado';
  static const medicamentos = 'Medicamentos';
  static const combustible = 'Combustible';

  static const todos = [salarios, luz, concentrado, medicamentos, combustible];

  static const compraGanado = 'Compra de ganado';
}
