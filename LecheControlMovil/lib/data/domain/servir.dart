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

/// Una vaca de la lista, lista para pintar.
class VacaPorServir {
  const VacaPorServir({
    required this.animalId,
    required this.identificador,
    required this.grupo,
    required this.estadoReproductivo,
    required this.diasLactancia,
    required this.servicios,
  });

  final String animalId;
  final String identificador;
  final String grupo;
  final String estadoReproductivo;

  /// Días desde el último parto. Es el mismo DLac del reporte de producción.
  final int diasLactancia;

  /// Cuántas montas o inseminaciones lleva **desde que parió**. Cero significa
  /// que nadie la ha intentado servir todavía.
  final int servicios;

  /// Cómo se lee la segunda línea de la tarjeta.
  String get resumen {
    final dias = '$diasLactancia días de lactancia';
    final s = switch (servicios) {
      0 => 'sin servicios',
      1 => '1 servicio',
      _ => '$servicios servicios',
    };
    return '$dias · $s';
  }
}

/// Si la vaca tiene que aparecer en la lista.
///
/// [estadoReproductivo] es el de la ficha: una preñada confirmada no se sirve.
bool hayQueServir({
  required String sexo,
  required DateTime? fechaUltimoParto,
  required String estadoReproductivo,
  DateTime? hoy,
}) {
  if (sexo != Sexo.hembra) return false;
  if (estadoReproductivo == EstadoReproductivo.preniada) return false;
  final parto = fechaUltimoParto;
  if (parto == null) return false; // nunca ha parido: no es de esta lista
  return diasDesde(parto, hoy: hoy) >= diasParaServir;
}

/// Ordena la lista como se lee: la más atrasada de primera.
///
/// El orden **es** la información. Arriba está la vaca que lleva más tiempo
/// abierta, que es por la que hay que empezar.
int compararPorServir(VacaPorServir a, VacaPorServir b) {
  final porDias = b.diasLactancia.compareTo(a.diasLactancia);
  if (porDias != 0) return porDias;
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
