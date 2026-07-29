import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../local/database.dart';

/// Gastos y parámetros de precio por período (mes calendario), Módulo 4.
class GastosRepository {
  GastosRepository(this.db);

  final AppDatabase db;
  final _uuid = const Uuid();

  Future<ParametrosPeriodoRow?> obtenerPeriodo(
    String lecheriaId,
    int anio,
    int mes,
  ) {
    return (db.select(db.parametrosPeriodo)..where(
          (t) =>
              t.lecheriaId.equals(lecheriaId) &
              t.anio.equals(anio) &
              t.mes.equals(mes) &
              t.deletedAt.isNull(),
        ))
        .getSingleOrNull();
  }

  /// Stream reactivo con los parámetros del mes calendario actual.
  Stream<ParametrosPeriodoRow?> observarPeriodoActual(String lecheriaId) {
    final ahora = DateTime.now();
    return (db.select(db.parametrosPeriodo)..where(
          (t) =>
              t.lecheriaId.equals(lecheriaId) &
              t.anio.equals(ahora.year) &
              t.mes.equals(ahora.month) &
              t.deletedAt.isNull(),
        ))
        .watchSingleOrNull();
  }

  /// Crea o actualiza los parámetros de un período (precio del litro, precio
  /// del concentrado y umbral de secado). Devuelve el id del período.
  Future<String> upsertParametrosPeriodo({
    required String lecheriaId,
    required int anio,
    required int mes,
    required double precioLitro,
    required double precioConcentradoKg,
    double umbralSecadoLitros = 8,
  }) async {
    final existente = await obtenerPeriodo(lecheriaId, anio, mes);
    final ahora = DateTime.now();
    if (existente != null) {
      await (db.update(
        db.parametrosPeriodo,
      )..where((t) => t.id.equals(existente.id))).write(
        ParametrosPeriodoCompanion(
          precioLitro: Value(precioLitro),
          precioConcentradoKg: Value(precioConcentradoKg),
          umbralSecadoLitros: Value(umbralSecadoLitros),
          updatedAt: Value(ahora),
          pendiente: const Value(true),
        ),
      );
      return existente.id;
    }
    final id = _uuid.v4();
    await db
        .into(db.parametrosPeriodo)
        .insert(
          ParametrosPeriodoCompanion.insert(
            id: id,
            lecheriaId: lecheriaId,
            anio: anio,
            mes: mes,
            precioLitro: precioLitro,
            precioConcentradoKg: precioConcentradoKg,
            umbralSecadoLitros: Value(umbralSecadoLitros),
            createdAt: ahora,
            updatedAt: ahora,
            pendiente: const Value(true),
          ),
        );
    return id;
  }

  Stream<List<CostoFijoRow>> observarCostosFijos(String periodoId) {
    return (db.select(db.costosFijos)
          ..where((t) => t.periodoId.equals(periodoId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.categoria)]))
        .watch();
  }

  Future<void> addCostoFijo({
    required String lecheriaId,
    required String periodoId,
    required String categoria,
    required double monto,
  }) async {
    final ahora = DateTime.now();
    await db
        .into(db.costosFijos)
        .insert(
          CostosFijosCompanion.insert(
            id: _uuid.v4(),
            lecheriaId: lecheriaId,
            periodoId: periodoId,
            categoria: categoria.trim(),
            monto: monto,
            createdAt: ahora,
            updatedAt: ahora,
            pendiente: const Value(true),
          ),
        );
  }

  Future<void> eliminarCostoFijo(String costoId) async {
    await (db.update(db.costosFijos)..where((t) => t.id.equals(costoId))).write(
      CostosFijosCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        pendiente: const Value(true),
      ),
    );
  }

  /// Suma de costos fijos del período (para el reparto diario entre las
  /// vacas en ordeño, Módulo 4 y 5).
  Future<double> totalCostosFijos(String periodoId) async {
    final costos =
        await (db.select(db.costosFijos)..where(
              (t) => t.periodoId.equals(periodoId) & t.deletedAt.isNull(),
            ))
            .get();
    return costos.fold<double>(0, (a, c) => a + c.monto);
  }
}
