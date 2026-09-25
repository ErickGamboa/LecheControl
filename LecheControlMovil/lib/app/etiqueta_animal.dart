/// Cómo se nombra un animal en pantalla cuando tiene alias.
///
/// **El arete manda y el alias acompaña**, siempre en ese orden y en todas las
/// pantallas. El arete es el dato oficial —el que está en la oreja y el que
/// viaja al servidor—; el alias es el nombre con el que se le dice en la
/// finca. Mostrar solo uno de los dos obliga a adivinar de cuál animal se está
/// hablando, y mostrarlos en distinto orden según la pantalla es peor todavía.
///
/// Se escribe la palabra «alias» a propósito, en vez de un paréntesis o un
/// guion. Un `1542 (99)` no dice qué es el 99: podría ser el grupo, los litros
/// o el número de partos. Con la palabra no hay nada que deducir, y es lo que
/// hace que buscar «99» y ver aparecer la 1542 se entienda solo.
library;

/// El animal en una línea: `1542` si no tiene alias, `1542 · alias 99` si lo
/// tiene.
String etiquetaAnimal(String identificador, String? alias) {
  final a = alias?.trim() ?? '';
  return a.isEmpty ? identificador : '$identificador · alias $a';
}

/// Solo la parte del alias, para las pantallas que ya muestran el arete
/// grande y necesitan el alias en su propio renglón: `alias 99`, o null si no
/// tiene.
String? soloAlias(String? alias) {
  final a = alias?.trim() ?? '';
  return a.isEmpty ? null : 'alias $a';
}
