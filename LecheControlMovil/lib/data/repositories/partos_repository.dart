import 'package:drift/drift.dart';

import '../domain/grupos.dart';
import '../domain/partos_proyectados.dart';
import '../local/database.dart';

/// Arma el calendario de partos de los próximos doce meses (Módulo 6 —
/// Análisis).
///
/// La regla —de dónde sale la fecha de cada vaca y cómo se reparte en los
/// meses— vive en `domain/partos_proyectados.dart` y no toca la base: acá solo
/// se buscan las preñadas y el último servicio de cada una, y se le pasan.
///
/// Igual que en la lista de palpación, son **dos consultas** que se cruzan en
/// memoria: preguntando vaca por vaca, un hato de 60 serían decenas de viajes
/// a la base para una pantalla que se abre de un toque.
class PartosRepository {
  PartosRepository(this.db);

  final AppDatabase db;

  /// Los eventos que cuentan como "la vaca fue servida", igual que en la lista
  /// de palpación: en la finca el celo se anota como parte del mismo momento
  /// que la monta o la inseminación.
  static const _tiposServicio = [
    TipoEventoAnimal.celo,
    TipoEventoAnimal.monta,
    TipoEventoAnimal.inseminacion,
  ];

  /// El calendario de partos de la lechería.
  ///
  /// Entran las hembras activas marcadas como **preñadas**: una vaca vacía no
  /// tiene parto que proyectar, y una que ya parió vuelve a vacía sola.
  ///
  /// La fecha de cada una sale, en este orden:
  ///
  /// 1. La **fecha probable de parto** de su ficha, que es la que anotó la
  ///    palpación. Es la del veterinario y manda sobre cualquier cuenta.
  /// 2. El **último servicio** más la gestación, cuando no hay fecha anotada.
  ///    Solo sirve si ese servicio es posterior al último parto: uno anterior
  ///    ya terminó en parto y proyectaría una preñez que no existe.
  ///
  /// La que no cae en ninguno de los dos casos se aparta en
  /// [ProyeccionPartos.sinFecha]: está marcada como preñada pero no hay de
  /// dónde sacarle el parto, y eso hay que arreglarlo en su hoja de vida.
  Future<ProyeccionPartos> proyeccion(
    String lecheriaId, {
    DateTime? hoy,
    int meses = mesesDeProyeccion,
  }) async {
    final animales =
        await (db.select(db.animales)..where(
              (t) =>
                  t.lecheriaId.equals(lecheriaId) &
                  t.deletedAt.isNull() &
                  t.estado.equals(EstadoAnimal.activo) &
                  t.sexo.equals(Sexo.hembra) &
                  t.estadoReproductivo.equals(EstadoReproductivo.preniada),
            ))
            .get();
    if (animales.isEmpty) {
      return proyectarPartos(vacas: const [], hoy: hoy, meses: meses);
    }

    final eventos =
        await (db.select(db.eventosAnimal)
              ..where(
                (t) =>
                    t.lecheriaId.equals(lecheriaId) &
                    t.deletedAt.isNull() &
                    t.tipo.isIn(_tiposServicio),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.fecha)]))
            .get();

    // De la más vieja a la más nueva: el último que se guarda de cada animal
    // es el más reciente. Una sola pasada.
    final ultimoServicio = <String, EventoAnimalRow>{};
    for (final e in eventos) {
      ultimoServicio[e.animalId] = e;
    }

    final vacas = <VacaPorParir>[];
    final sinFecha = <String>[];

    for (final a in animales) {
      final servicio = ultimoServicio[a.id];
      // Un servicio anterior al último parto ya cumplió: no proyecta nada.
      final servicioVigente =
          servicio != null &&
          (a.fechaUltimoParto == null ||
              servicio.fecha.isAfter(a.fechaUltimoParto!))
          ? servicio
          : null;

      final confirmada = a.fechaProbableParto;
      final DateTime? fechaProbable = confirmada ??
          (servicioVigente == null
              ? null
              : partoProbableDesdeServicio(servicioVigente.fecha));

      if (fechaProbable == null) {
        sinFecha.add(a.identificador);
        continue;
      }

      vacas.add(
        VacaPorParir(
          animalId: a.id,
          identificador: a.identificador,
          grupo: a.grupo,
          fechaProbable: fechaProbable,
          origen: confirmada != null
              ? OrigenFechaParto.confirmada
              : OrigenFechaParto.estimada,
          fechaServicio: servicioVigente?.fecha,
          tipoServicio: servicioVigente?.tipo,
          toroPajilla: servicioVigente?.toroPajilla,
        ),
      );
    }

    sinFecha.sort();

    return proyectarPartos(
      vacas: vacas,
      preniadasSinFecha: sinFecha,
      hoy: hoy,
      meses: meses,
    );
  }
}
