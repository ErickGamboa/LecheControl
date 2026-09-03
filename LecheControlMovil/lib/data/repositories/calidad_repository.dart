import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../local/database.dart';
import 'finanzas_repository.dart';

/// La calidad de una semana con la semana a la que pertenece, que es lo que
/// hace falta para graficarla (el registro solo guarda el `semana_id`).
class CalidadDeSemana {
  const CalidadDeSemana({required this.semana, required this.calidad});

  final SemanaRow semana;
  final CalidadLecheRow calidad;
}

/// Calidad de la leche entregada, semana a semana (Módulo 3 — Registro de
/// leche).
///
/// Son datos que **manda la planta**, no que la finca mide: acá solo se
/// anotan, se guardan por semana y después se comparan en Análisis. Los tres
/// análisis son independientes —se puede anotar uno hoy y el otro cuando
/// llegue—, así que ninguno es obligatorio.
///
/// La semana es la misma de las finanzas (`semanas`, lunes a domingo): por eso
/// el repositorio se apoya en [FinanzasRepository.abrirSemana] en vez de
/// llevar su propio calendario.
class CalidadRepository {
  CalidadRepository(this.db, {required FinanzasRepository finanzasRepository})
    : _finanzas = finanzasRepository;

  final AppDatabase db;
  final FinanzasRepository _finanzas;
  final _uuid = const Uuid();

  /// Abre (o reutiliza) la semana en la que cae [fecha]. Es la misma semana de
  /// Finanzas: anotar la calidad de una semana que todavía no existía la crea.
  Future<SemanaRow> abrirSemana({
    required String lecheriaId,
    DateTime? fecha,
  }) => _finanzas.abrirSemana(lecheriaId: lecheriaId, fecha: fecha);

  /// Lo anotado para una semana, o null si todavía no hay nada.
  Future<CalidadLecheRow?> deSemana(String semanaId) {
    return (db.select(db.calidadLeche)
          ..where((t) => t.semanaId.equals(semanaId) & t.deletedAt.isNull()))
        .getSingleOrNull();
  }

  Stream<CalidadLecheRow?> observarDeSemana(String semanaId) {
    return (db.select(db.calidadLeche)
          ..where((t) => t.semanaId.equals(semanaId) & t.deletedAt.isNull()))
        .watchSingleOrNull();
  }

  /// Guarda (o corrige) la calidad de una semana.
  ///
  /// Es un solo registro por semana: si ya había uno se corrige, no se
  /// duplica. Y si los tres análisis quedan vacíos —el ganadero borró lo que
  /// había— la fila se borra suave: una lectura sin ningún valor no es una
  /// semana medida, y dejarla haría un hueco en los gráficos.
  Future<void> guardar({
    required String lecheriaId,
    required String semanaId,
    double? solidosTotalesPct,
    double? celulasSomaticas,
    double? conteoBacterial,
  }) async {
    final ahora = DateTime.now();
    final existente = await deSemana(semanaId);
    final vacia =
        solidosTotalesPct == null &&
        celulasSomaticas == null &&
        conteoBacterial == null;

    if (existente != null) {
      await (db.update(
        db.calidadLeche,
      )..where((t) => t.id.equals(existente.id))).write(
        CalidadLecheCompanion(
          solidosTotalesPct: Value(solidosTotalesPct),
          celulasSomaticas: Value(celulasSomaticas),
          conteoBacterial: Value(conteoBacterial),
          updatedAt: Value(ahora),
          deletedAt: Value(vacia ? ahora : null),
          pendiente: const Value(true),
        ),
      );
      return;
    }

    if (vacia) return;

    await db
        .into(db.calidadLeche)
        .insert(
          CalidadLecheCompanion.insert(
            id: _uuid.v4(),
            lecheriaId: lecheriaId,
            semanaId: semanaId,
            solidosTotalesPct: Value(solidosTotalesPct),
            celulasSomaticas: Value(celulasSomaticas),
            conteoBacterial: Value(conteoBacterial),
            createdAt: ahora,
            updatedAt: ahora,
            pendiente: const Value(true),
          ),
        );
  }

  /// Todas las semanas con calidad anotada, de la más reciente a la más vieja.
  ///
  /// Se traen las dos tablas de corrido y se cruzan en memoria, igual que
  /// `FinanzasRepository.resumenesDe`: con una consulta por semana, un año de
  /// historia serían más de cincuenta viajes a la base.
  Future<List<CalidadDeSemana>> historial(String lecheriaId) async {
    final filas =
        await (db.select(db.calidadLeche)..where(
              (t) => t.lecheriaId.equals(lecheriaId) & t.deletedAt.isNull(),
            ))
            .get();
    if (filas.isEmpty) return const [];

    final semanas =
        await (db.select(db.semanas)..where(
              (t) => t.lecheriaId.equals(lecheriaId) & t.deletedAt.isNull(),
            ))
            .get();
    final porId = {for (final s in semanas) s.id: s};

    final lista = <CalidadDeSemana>[
      for (final f in filas)
        if (porId[f.semanaId] case final semana?)
          CalidadDeSemana(semana: semana, calidad: f),
    ];
    lista.sort((a, b) => b.semana.fechaInicio.compareTo(a.semana.fechaInicio));
    return lista;
  }
}
