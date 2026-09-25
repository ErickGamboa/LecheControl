/// Cómo se busca un animal escribiendo solo un pedazo del arete.
///
/// Sentado con la hoja de apuntes al lado, nadie digita `542117` completo
/// veinte veces. Escribe `117` —los últimos números, que es como se llaman
/// las vacas entre la gente— o `5421` si va por el principio, y espera que la
/// lista se le acorte sola.
///
/// Por eso no alcanza con "contiene": hay que **ordenar** los resultados, o el
/// que buscaba se pone a leer una lista larga y eso es más lento que digitar
/// el arete entero. El orden va de lo más seguro a lo más dudoso.
library;

/// De qué forma pega el arete con lo que se escribió, en orden: primero el
/// que no deja dudas.
enum CalceArete {
  /// Se escribió el arete completo. No hay nada que escoger.
  exacto,

  /// Los últimos números. Es la forma en que se nombra al animal en la finca
  /// —«la 117»— y por eso pesa más que el principio.
  terminaEn,

  /// Los primeros números. En fincas donde el arete lleva prefijo de lote o
  /// de año, sirve para caer en el grupo de una vez.
  empiezaCon,

  /// Pegó en el medio. Es el más flojo: se muestra, pero de último.
  contiene,
}

/// Cómo pega [identificador] con [texto], o null si no pega del todo.
///
/// No distingue mayúsculas: los aretes son casi siempre números, pero los hay
/// con letra —`A-204`— y nadie va a acordarse de cómo la escribió.
CalceArete? calceDeArete(String identificador, String texto) {
  final arete = identificador.trim().toLowerCase();
  final buscado = texto.trim().toLowerCase();
  if (buscado.isEmpty || arete.isEmpty) return null;
  if (arete == buscado) return CalceArete.exacto;
  if (arete.endsWith(buscado)) return CalceArete.terminaEn;
  if (arete.startsWith(buscado)) return CalceArete.empiezaCon;
  if (arete.contains(buscado)) return CalceArete.contiene;
  return null;
}

/// Ordena dos aretes que ya pegaron: primero el calce más seguro y, entre
/// iguales, el arete más corto.
///
/// Lo del largo no es capricho. Si se escribe `117`, tanto `117` como
/// `5421170` terminan pegando; el corto es casi siempre el que se buscaba,
/// porque el que escribió poco tenía poco que escribir.
int compararCalce(
  (String arete, CalceArete calce) a,
  (String arete, CalceArete calce) b,
) {
  final porCalce = a.$2.index.compareTo(b.$2.index);
  if (porCalce != 0) return porCalce;
  final porLargo = a.$1.length.compareTo(b.$1.length);
  if (porLargo != 0) return porLargo;
  return a.$1.compareTo(b.$1);
}

/// Los aretes que pegan con [texto], del más probable al menos.
List<String> aretesQuePegan(Iterable<String> aretes, String texto) {
  final conCalce = <(String, CalceArete)>[];
  for (final arete in aretes) {
    final calce = calceDeArete(arete, texto);
    if (calce != null) conCalce.add((arete, calce));
  }
  conCalce.sort(compararCalce);
  return [for (final (arete, _) in conCalce) arete];
}
