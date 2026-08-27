import 'package:drift/drift.dart';

import '../domain/grupos.dart';
import '../domain/palpacion.dart';
import '../local/database.dart';

/// Arma la lista de vacas por palpar (Módulo 6 — Análisis).
///
/// La regla de quién entra vive en `domain/palpacion.dart` y no toca la base:
/// acá solo se buscan los datos que esa regla necesita —el último parto, el
/// último servicio y la última palpación de cada hembra— y se los pasa.
class PalpacionRepository {
  PalpacionRepository(this.db);

  final AppDatabase db;

  /// Tipos de evento que cuentan como "la vaca fue servida".
  ///
  /// El celo entra junto a la monta y la inseminación porque en la finca se
  /// anota como parte del mismo momento; lo que importa para la regla es la
  /// **fecha del último**, sea cual sea de los tres.
  static const _tiposServicio = [
    TipoEventoAnimal.celo,
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

    final tiposDeInteres = [..._tiposServicio, TipoEventoAnimal.palpacion];
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
          grupo: a.grupo,
          estadoReproductivo: a.estadoReproductivo,
          motivo: razon.motivo,
          fecha: razon.fecha,
          dias: diasDesde(razon.fecha, hoy: hoy),
          // El servicio solo se muestra cuando es la razón de estar en la
          // lista: en una recién parida sería el de la preñez que ya terminó.
          tipoServicio: esPorServicio ? servicio?.tipo : null,
          toroPajilla: esPorServicio ? servicio?.toroPajilla : null,
        ),
      );
    }

    lista.sort(compararPorPalpar);
    return lista;
  }
}
