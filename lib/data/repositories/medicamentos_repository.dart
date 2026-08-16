import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../local/database.dart';

/// Catálogo de medicamentos de la lechería (Módulo 7). El usuario los registra
/// una vez —nombre, dosis y ml del envase— y luego los aplica rápido desde la
/// Pantalla de Trabajo.
///
/// La dosis es texto libre ("10 ml cada 50 kilos") porque así viene en la
/// etiqueta del frasco. La app no pide ml aplicados ni calcula costo por
/// aplicación: la plata de los medicamentos se anota como gasto de la semana.
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
    String? dosisAplicacion,
    double? mlEnvase,
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
            dosisAplicacion: Value(_limpio(dosisAplicacion)),
            mlEnvase: Value(mlEnvase),
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
    String? dosisAplicacion,
    double? mlEnvase,
  }) async {
    await (db.update(
      db.medicamentos,
    )..where((t) => t.id.equals(medicamentoId))).write(
      MedicamentosCompanion(
        nombre: Value(nombre.trim()),
        dosisAplicacion: Value(_limpio(dosisAplicacion)),
        mlEnvase: Value(mlEnvase),
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

  String? _limpio(String? texto) {
    final limpio = texto?.trim();
    return limpio == null || limpio.isEmpty ? null : limpio;
  }
}
