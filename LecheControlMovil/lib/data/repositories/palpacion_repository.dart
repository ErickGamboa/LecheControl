import 'package:drift/drift.dart';

import '../domain/grupos.dart';
import '../domain/palpacion.dart';
import '../domain/secar.dart';
import '../domain/servir.dart';
import '../local/database.dart';
import 'curva_repository.dart';

/// Arma la lista de vacas por palpar (Módulo 6 — Análisis).
///
/// La regla de quién entra vive en `domain/palpacion.dart` y no toca la base:
/// acá solo se buscan los datos que esa regla necesita —el último parto, el
/// último servicio y la última palpación de cada hembra— y se los pasa.
class PalpacionRepository {
  PalpacionRepository(this.db, {CurvaRepository? curva})
    : _curva = curva ?? CurvaRepository(db);

  final AppDatabase db;

  /// De acá sale a cuántos días del parto secar, que lo decide cada finca.
  final CurvaRepository _curva;

  /// Tipos de evento que cuentan como "la vaca fue servida".
  ///
  /// **El celo no está, y es a propósito.** Antes entraba junto a la monta y
  /// la inseminación porque en la finca se anotan en el mismo momento, pero
  /// son cosas distintas: el celo es que la vaca está en calor, un dato para
  /// decidir cuándo servirla. Contarlo como servicio metía en la lista de
  /// palpación vacas a las que nadie había echado toro ni pajilla, y no hay
  /// preñez que confirmar donde no hubo servicio.
  static const tiposServicio = [
    TipoEventoAnimal.monta,
    TipoEventoAnimal.inseminacion,
  ];

  /// Las vacas que hay que palpar hoy, ordenadas como las lee el veterinario
  /// (ver [compararPorPalpar]).
  ///
  /// Se traen los animales y sus eventos en **dos consultas** y se cruzan en
  /// memoria: preguntando por animal, un hato de 60 vacas serían más de cien
  /// viajes a la base para una pantalla que se abre de un toque.
  Future<List<VacaPorPalpar>> porPalpar(
    String lecheriaId, {
    DateTime? hoy,
  }) async {
    final animales =
        await (db.select(db.animales)..where(
              (t) =>
                  t.lecheriaId.equals(lecheriaId) &
                  t.deletedAt.isNull() &
                  t.estado.equals(EstadoAnimal.activo) &
                  t.sexo.equals(Sexo.hembra),
            ))
            .get();
    if (animales.isEmpty) return const [];

    final tiposDeInteres = [...tiposServicio, TipoEventoAnimal.palpacion];
    final eventos =
        await (db.select(db.eventosAnimal)
              ..where(
                (t) =>
                    t.lecheriaId.equals(lecheriaId) &
                    t.deletedAt.isNull() &
                    t.tipo.isIn(tiposDeInteres),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.fecha)]))
            .get();

    // Recorriendo de la más vieja a la más nueva, el último que se guarda de
    // cada animal es el más reciente. Así se resuelve con una pasada.
    final ultimoServicio = <String, EventoAnimalRow>{};
    final ultimaPalpacion = <String, DateTime>{};
    for (final e in eventos) {
      final animalId = e.animalId;
      if (e.tipo == TipoEventoAnimal.palpacion) {
        ultimaPalpacion[animalId] = e.fecha;
      } else {
        ultimoServicio[animalId] = e;
      }
    }

    final lista = <VacaPorPalpar>[];
    for (final a in animales) {
      final servicio = ultimoServicio[a.id];
      final razon = razonDePalpacion(
        fechaUltimoParto: a.fechaUltimoParto,
        fechaUltimoServicio: servicio?.fecha,
        fechaUltimaPalpacion: ultimaPalpacion[a.id],
        estadoReproductivo: a.estadoReproductivo,
        hoy: hoy,
      );
      if (razon == null) continue;

      final esPorServicio = razon.motivo == MotivoPalpacion.servidaSinConfirmar;
      lista.add(
        VacaPorPalpar(
          animalId: a.id,
          identificador: a.identificador,
          alias: a.alias,
          grupo: a.grupo,
          estadoReproductivo: a.estadoReproductivo,
          motivo: razon.motivo,
          fecha: razon.fecha,
          dias: diasDesde(razon.fecha, hoy: hoy),
          // El servicio solo se muestra cuando es la razón de estar en la
          // lista: en una parida sin diagnóstico sería el de la preñez que ya
          // terminó en ese parto.
          tipoServicio: esPorServicio ? servicio?.tipo : null,
          toroPajilla: esPorServicio ? servicio?.toroPajilla : null,
        ),
      );
    }

    lista.sort(compararPorPalpar);
    return lista;
  }

  /// Las vacas que hay que servir: parieron hace [diasParaServir] días o más y
  /// siguen sin preñarse (ver `domain/servir.dart`).
  ///
  /// Mismo patrón que [porPalpar]: dos consultas y el cruce en memoria. Acá
  /// además hay que **contar** los servicios posteriores al parto, no solo
  /// quedarse con el último, porque el número de intentos es justo lo que dice
  /// si la vaca no se está sirviendo o si se sirve y no agarra —dos problemas
  /// distintos, con soluciones distintas—.
  Future<List<VacaPorServir>> porServir(
    String lecheriaId, {
    DateTime? hoy,
  }) async {
    final animales =
        await (db.select(db.animales)..where(
              (t) =>
                  t.lecheriaId.equals(lecheriaId) &
                  t.deletedAt.isNull() &
                  t.estado.equals(EstadoAnimal.activo) &
                  t.sexo.equals(Sexo.hembra),
            ))
            .get();
    if (animales.isEmpty) return const [];

    final candidatas = <(AnimalRow, RazonServir)>[];
    for (final a in animales) {
      final razon = razonDeServir(
        sexo: a.sexo,
        fechaUltimoParto: a.fechaUltimoParto,
        fechaNacimiento: a.fechaNacimiento,
        estadoReproductivo: a.estadoReproductivo,
        hoy: hoy,
      );
      if (razon != null) candidatas.add((a, razon));
    }
    if (candidatas.isEmpty) return const [];

    final servicios =
        await (db.select(db.eventosAnimal)..where(
              (t) =>
                  t.lecheriaId.equals(lecheriaId) &
                  t.deletedAt.isNull() &
                  t.tipo.isIn(tiposServicio),
            ))
            .get();

    final porAnimal = <String, List<DateTime>>{};
    for (final e in servicios) {
      (porAnimal[e.animalId] ??= []).add(e.fecha);
    }

    final lista = [
      for (final (a, razon) in candidatas)
        VacaPorServir(
          animalId: a.id,
          identificador: a.identificador,
          alias: a.alias,
          grupo: a.grupo,
          estadoReproductivo: a.estadoReproductivo,
          motivo: razon.motivo,
          diasDeAtraso: razon.diasDeAtraso,
          diasLactancia: a.fechaUltimoParto == null
              ? null
              : diasDesde(a.fechaUltimoParto!, hoy: hoy),
          mesesEdad: a.fechaNacimiento == null
              ? null
              : mesesDesde(a.fechaNacimiento!, hoy: hoy),
          // En una vaca cuentan los intentos desde el parto; en una novilla,
          // todos: el que la intentó servir a los 15 meses y no agarró es
          // exactamente el dato que hace falta.
          servicios: (porAnimal[a.id] ?? const [])
              .where(
                (f) =>
                    a.fechaUltimoParto == null ||
                    f.isAfter(a.fechaUltimoParto!),
              )
              .length,
        ),
    ]..sort(compararPorServir);
    return lista;
  }

  /// Las vacas a las que les corresponde secarse (ver `domain/secar.dart`).
  ///
  /// Entra la preñada con fecha probable de parto a la que le faltan los días
  /// que diga la finca o menos y **que no está en Secas**. No se va sola:
  /// la saca el secado, que es lo que la pasa al grupo Secas.
  ///
  /// Trae además los litros de la última pesa, porque es lo que decide si
  /// secarla duele: una vaca en 6 litros se seca sin pensarlo, una en 20 es
  /// una conversación.
  Future<List<VacaPorSecar>> porSecar(
    String lecheriaId, {
    DateTime? hoy,
  }) async {
    final dias = await _curva.diasParaSecarDe(lecheriaId);
    final animales =
        await (db.select(db.animales)..where(
              (t) =>
                  t.lecheriaId.equals(lecheriaId) &
                  t.deletedAt.isNull() &
                  t.estado.equals(EstadoAnimal.activo) &
                  t.sexo.equals(Sexo.hembra) &
                  t.fechaProbableParto.isNotNull(),
            ))
            .get();

    final lista = <VacaPorSecar>[];
    for (final a in animales) {
      final faltan = diasQueFaltanParaSecar(
        grupo: a.grupo,
        estadoReproductivo: a.estadoReproductivo,
        fechaProbableParto: a.fechaProbableParto,
        diasParaSecar: dias,
        hoy: hoy,
      );
      if (faltan == null) continue;
      lista.add(
        VacaPorSecar(
          animalId: a.id,
          identificador: a.identificador,
          alias: a.alias,
          grupo: a.grupo,
          diasParaParir: faltan,
          diasLactancia: a.fechaUltimoParto == null
              ? null
              : diasDesde(a.fechaUltimoParto!, hoy: hoy),
          ultimaProduccion: await _ultimaProduccion(a.id),
        ),
      );
    }
    return lista..sort(compararPorSecar);
  }

  /// Los litros de la última pesa del animal, si tiene alguna.
  Future<double?> _ultimaProduccion(String animalId) async {
    final fila =
        await (db.select(db.pesasLeche)
              ..where((t) => t.animalId.equals(animalId) & t.deletedAt.isNull())
              ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
              ..limit(1))
            .getSingleOrNull();
    return fila?.litros;
  }
}
