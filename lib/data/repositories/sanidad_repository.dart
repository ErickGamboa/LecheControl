import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../domain/grupos.dart';
import '../local/database.dart';
import 'medicamentos_repository.dart';

/// Aplica medicamentos del catálogo a un animal (Módulo 7): calcula el costo,
/// registra el evento en la hoja de vida y, si el medicamento tiene días de
/// retiro, deja al animal "en retiro de leche" hasta la fecha calculada.
class SanidadRepository {
  SanidadRepository(this.db, {MedicamentosRepository? medicamentosRepository})
    : _medicamentos = medicamentosRepository ?? MedicamentosRepository(db);

  final AppDatabase db;
  final MedicamentosRepository _medicamentos;
  final _uuid = const Uuid();

  Future<void> aplicarMedicamento({
    required String animalId,
    required String lecheriaId,
    required String medicamentoId,
    double? mlAplicados,
    DateTime? fecha,
    String? registradoPor,
  }) async {
    final medicamento = await _medicamentos.porId(medicamentoId);
    if (medicamento == null) {
      throw StateError('Medicamento no encontrado: $medicamentoId');
    }
    final calculo = _medicamentos.calcularCosto(
      medicamento,
      mlAplicados: mlAplicados,
    );
    final ahora = fecha ?? DateTime.now();
    final retiroHasta = medicamento.diasRetiroLeche > 0
        ? ahora.add(Duration(days: medicamento.diasRetiroLeche))
        : null;

    await db.transaction(() async {
      await db
          .into(db.eventosAnimal)
          .insert(
            EventosAnimalCompanion.insert(
              id: _uuid.v4(),
              animalId: animalId,
              lecheriaId: lecheriaId,
              tipo: TipoEventoAnimal.sanidad,
              fecha: ahora,
              detalle: Value(medicamento.nombre),
              medicamentoId: Value(medicamentoId),
              dosis: Value(calculo.etiquetaDosis),
              diasRetiro: Value(
                medicamento.diasRetiroLeche > 0
                    ? medicamento.diasRetiroLeche
                    : null,
              ),
              costo: Value(calculo.costo),
              registradoPor: Value(registradoPor),
              createdAt: ahora,
              updatedAt: ahora,
              pendiente: const Value(true),
            ),
          );
      if (retiroHasta != null) {
        await (db.update(
          db.animales,
        )..where((t) => t.id.equals(animalId))).write(
          AnimalesCompanion(
            retiroLecheHasta: Value(retiroHasta),
            updatedAt: Value(ahora),
            pendiente: const Value(true),
          ),
        );
      }
    });
  }

  /// True si el animal tiene retiro de leche vigente en [hoy] (o ahora).
  Future<bool> estaEnRetiro(String animalId, {DateTime? hoy}) async {
    final animal = await (db.select(
      db.animales,
    )..where((t) => t.id.equals(animalId))).getSingleOrNull();
    final retiro = animal?.retiroLecheHasta;
    if (retiro == null) return false;
    return retiro.isAfter(hoy ?? DateTime.now());
  }

  Stream<List<EventoAnimalRow>> observarHistorial(String animalId) {
    return (db.select(db.eventosAnimal)
          ..where(
            (t) =>
                t.animalId.equals(animalId) &
                t.tipo.equals(TipoEventoAnimal.sanidad) &
                t.deletedAt.isNull(),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.fecha)]))
        .watch();
  }
}
