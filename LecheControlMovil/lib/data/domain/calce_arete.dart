/// Cómo se busca un animal escribiendo solo un pedazo de su arete o de su
/// alias.
///
/// Sentado con la hoja de apuntes al lado, nadie digita `542117` completo
/// veinte veces. Escribe `117` —los últimos números, que es como se llaman las
/// vacas entre la gente— o `5421` si va por el principio, y espera que la
/// lista se le acorte sola.
///
/// Por eso no alcanza con "contiene": hay que **ordenar** los resultados, o el
/// que buscaba se pone a leer una lista larga y eso es más lento que digitar
/// el arete entero. El orden va de lo más seguro a lo más dudoso.
///
/// Y como el alias es justamente el nombre con el que se le dice al animal en
/// la finca, buscar por ahí tiene que funcionar igual de bien. Pero hay que
/// **decir cuál de los dos pegó**: si se escribe `99` y aparece la vaca
/// `1542`, sin explicación parece que el filtro está malo. Para eso está
/// [CoincidenciaAnimal.porAlias].
library;

/// De qué forma pega el texto, en orden: primero el que no deja dudas.
enum CalceArete {
  /// Se escribió el arete —o el alias— completo. No hay nada que escoger.
  exacto,

  /// Los últimos caracteres. Es la forma en que se nombra al animal en la
  /// finca —«la 117»— y por eso pesa más que el principio.
  terminaEn,

  /// Los primeros. En fincas donde el arete lleva prefijo de lote o de año,
  /// sirve para caer en el grupo de una vez.
  empiezaCon,

  /// Pegó en el medio. Es el más flojo: se muestra, pero de último.
  contiene,
}

/// Cómo pega [texto] con [valor], o null si no pega del todo.
///
/// No distingue mayúsculas: los aretes son casi siempre números, pero los hay
/// con letra —`A-204`— y los alias más todavía —`Pinta`—, y nadie va a
/// acordarse de cómo los escribió.
CalceArete? calceDeArete(String valor, String texto) {
  final v = valor.trim().toLowerCase();
  final buscado = texto.trim().toLowerCase();
  if (buscado.isEmpty || v.isEmpty) return null;
  if (v == buscado) return CalceArete.exacto;
  if (v.endsWith(buscado)) return CalceArete.terminaEn;
  if (v.startsWith(buscado)) return CalceArete.empiezaCon;
  if (v.contains(buscado)) return CalceArete.contiene;
  return null;
}

/// Por qué un animal salió en la lista: qué tan bien pegó y por cuál de los
/// dos campos.
typedef CoincidenciaAnimal = ({CalceArete calce, bool porAlias});

/// Si un animal pega con [texto], mirando primero el arete y después el alias.
///
/// **El arete manda cuando los dos pegan.** Si se escribe `99` y hay una vaca
/// de arete `99` y otra de alias `99`, la del arete va primero: es el dato
/// oficial y el que casi siempre se está buscando.
CoincidenciaAnimal? coincidenciaDe(
  String identificador,
  String? alias,
  String texto,
) {
  final porArete = calceDeArete(identificador, texto);
  final porAlias = alias == null ? null : calceDeArete(alias, texto);
  if (porArete == null && porAlias == null) return null;
  if (porArete == null) return (calce: porAlias!, porAlias: true);
  if (porAlias == null) return (calce: porArete, porAlias: false);
  // Pegan los dos: gana el calce más fuerte y, empatados, el arete.
  return porAlias.index < porArete.index
      ? (calce: porAlias, porAlias: true)
      : (calce: porArete, porAlias: false);
}

/// Ordena dos animales que ya pegaron: primero el calce más seguro, después
/// el que pegó por arete, y entre iguales el texto más corto.
///
/// Lo del largo no es capricho. Si se escribe `117`, tanto `117` como
/// `5421170` terminan pegando; el corto es casi siempre el que se buscaba,
/// porque el que escribió poco tenía poco que escribir.
int compararCoincidencia(
  (String texto, CoincidenciaAnimal c) a,
  (String texto, CoincidenciaAnimal c) b,
) {
  final porCalce = a.$2.calce.index.compareTo(b.$2.calce.index);
  if (porCalce != 0) return porCalce;
  // El que pegó por arete antes que el que pegó por alias.
  if (a.$2.porAlias != b.$2.porAlias) return a.$2.porAlias ? 1 : -1;
  final porLargo = a.$1.length.compareTo(b.$1.length);
  if (porLargo != 0) return porLargo;
  return a.$1.compareTo(b.$1);
}

/// Los aretes que pegan con [texto], del más probable al menos. Para probar la
/// regla sin arrastrar la base de datos.
List<String> aretesQuePegan(Iterable<String> aretes, String texto) {
  final conCalce = <(String, CoincidenciaAnimal)>[];
  for (final arete in aretes) {
    final c = coincidenciaDe(arete, null, texto);
    if (c != null) conCalce.add((arete, c));
  }
  conCalce.sort(compararCoincidencia);
  return [for (final (arete, _) in conCalce) arete];
}
