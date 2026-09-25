import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../domain/grupos.dart';
import '../local/database.dart';
import 'medicamentos_repository.dart';

/// Aplica medicamentos del catálogo a un animal (Módulo 7): deja el evento en
/// la hoja de vida con el nombre del medicamento y su dosis.
///
/// Una misma aplicación puede llevar **varios medicamentos** —así se trabaja
/// en el corral: se agarra la vaca una vez y se le pone todo— y por eso queda
/// un evento por medicamento, con la misma fecha.
///
/// No pide ml aplicados ni calcula costos: la plata de los medicamentos se
/// anota como gasto de la semana, y el animal no cambia de grupo por estar
/// tratado.
class SanidadRepository {
  SanidadRepository(this.db, {MedicamentosRepository? medicamentosRepository})
    : _medicamentos = medicamentosRepository ?? MedicamentosRepository(db);

  final AppDatabase db;
  final MedicamentosRepository _medicamentos;
  final _uuid = const Uuid();

  /// Registra la aplicación de uno o varios medicamentos a un animal.
  Future<void> aplicarMedicamentos({
    required String animalId,
    required String lecheriaId,
    required List<String> medicamentoIds,
    DateTime? fecha,
    String? registradoPor,
  }) async {
    if (medicamentoIds.isEmpty) return;
    final medicamentos = <MedicamentoRow>[];
    for (final id in medicamentoIds) {
      final medicamento = await _medicamentos.porId(id);
      if (medicamento == null) {
        throw StateError('Medicamento no encontrado: $id');
      }
      medicamentos.add(medicamento);
    }
    final ahora = fecha ?? DateTime.now();
    // Cuándo PASÓ y cuándo se DIGITÓ no son lo mismo, y desde que se
    // pueden pasar apuntes de días atrás hay que distinguirlos: `ahora`
    // es el día del evento —el del papel— y `registrado` el momento en
    // que se guardó. `created_at` con la fecha del evento borraría el
    // único rastro de cuándo se digitó, y un `updated_at` viejo es
    // además un mal dato para el sync, que ordena por él.
    final registrado = DateTime.now();

    await db.transaction(() async {
      for (final medicamento in medicamentos) {
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
                medicamentoId: Value(medicamento.id),
                dosis: Value(medicamento.dosisAplicacion),
                registradoPor: Value(registradoPor),
                createdAt: registrado,
                updatedAt: registrado,
                pendiente: const Value(true),
              ),
            );
      }
    });
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
