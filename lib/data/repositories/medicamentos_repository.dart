import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../domain/grupos.dart';
import '../local/database.dart';

/// Resultado de calcular el costo/etiqueta de una aplicación de medicamento.
class CalculoDosis {
  const CalculoDosis({required this.costo, required this.etiquetaDosis});
  final double costo;
  final String etiquetaDosis;
}

/// Catálogo de medicamentos de la lechería (Módulo 7). El usuario los registra
/// una vez y luego los aplica rápido desde la Pantalla de Trabajo.
class MedicamentosRepository {
  MedicamentosRepository(this.db);

  final AppDatabase db;
  final _uuid = const Uuid();

  Stream<List<MedicamentoRow>> observarMedicamentos(String lecheriaId) {
    return (db.select(db.medicamentos)
          ..where((t) => t.lecheriaId.equals(lecheriaId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.nombre)]))
        .watch();
  }

  Future<List<MedicamentoRow>> listarMedicamentos(String lecheriaId) {
    return (db.select(db.medicamentos)
          ..where((t) => t.lecheriaId.equals(lecheriaId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.nombre)]))
        .get();
  }

  Future<MedicamentoRow?> porId(String id) {
    return (db.select(
      db.medicamentos,
    )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).getSingleOrNull();
  }

  Future<String> crearMedicamento({
    required String lecheriaId,
    required String nombre,
    required double costoEnvase,
    required String tipoDosis,
    double? mlEnvase,
    double? aplicacionesEnvase,
    double? dosisFijaMl,
    int diasRetiroLeche = 0,
  }) async {
    final ahora = DateTime.now();
    final id = _uuid.v4();
    await db
        .into(db.medicamentos)
        .insert(
          MedicamentosCompanion.insert(
            id: id,
            lecheriaId: lecheriaId,
            nombre: nombre.trim(),
            costoEnvase: costoEnvase,
            tipoDosis: tipoDosis,
            mlEnvase: Value(mlEnvase),
            aplicacionesEnvase: Value(aplicacionesEnvase),
            dosisFijaMl: Value(dosisFijaMl),
            diasRetiroLeche: Value(diasRetiroLeche),
            createdAt: ahora,
            updatedAt: ahora,
            pendiente: const Value(true),
          ),
        );
    return id;
  }

  Future<void> editarMedicamento({
    required String medicamentoId,
    required String nombre,
    required double costoEnvase,
    required String tipoDosis,
    double? mlEnvase,
    double? aplicacionesEnvase,
    double? dosisFijaMl,
    int diasRetiroLeche = 0,
  }) async {
    await (db.update(
      db.medicamentos,
    )..where((t) => t.id.equals(medicamentoId))).write(
      MedicamentosCompanion(
        nombre: Value(nombre.trim()),
        costoEnvase: Value(costoEnvase),
        tipoDosis: Value(tipoDosis),
        mlEnvase: Value(mlEnvase),
        aplicacionesEnvase: Value(aplicacionesEnvase),
        dosisFijaMl: Value(dosisFijaMl),
        diasRetiroLeche: Value(diasRetiroLeche),
        updatedAt: Value(DateTime.now()),
        pendiente: const Value(true),
      ),
    );
  }

  Future<void> eliminarMedicamento(String medicamentoId) async {
    await (db.update(
      db.medicamentos,
    )..where((t) => t.id.equals(medicamentoId))).write(
      MedicamentosCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        pendiente: const Value(true),
      ),
    );
  }

  /// Costo por uso (Módulo 7):
  /// - Líquidos (dosis fija): costo del envase ÷ ml del envase × ml aplicados.
  /// - Por aplicación: costo del envase ÷ aplicaciones que rinde.
  CalculoDosis calcularCosto(MedicamentoRow m, {double? mlAplicados}) {
    if (m.tipoDosis == TipoDosisMedicamento.porAplicacion) {
      final aplicaciones = m.aplicacionesEnvase ?? 1;
      final costo = aplicaciones > 0
          ? m.costoEnvase / aplicaciones
          : m.costoEnvase;
      return CalculoDosis(costo: costo, etiquetaDosis: '1 aplicación');
    }
    final ml = mlAplicados ?? m.dosisFijaMl ?? 0;
    final mlEnvase = m.mlEnvase ?? 0;
    final costo = mlEnvase > 0
        ? (m.costoEnvase / mlEnvase) * ml
        : m.costoEnvase;
    return CalculoDosis(
      costo: costo,
      etiquetaDosis: '${ml.toStringAsFixed(1)} ml',
    );
  }
}
