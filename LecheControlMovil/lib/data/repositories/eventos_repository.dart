import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../domain/grupos.dart';
import '../local/database.dart';

/// Registra los eventos de la hoja de vida del animal (Módulo 1 y 6):
/// celo/monta/inseminación, palpación, secado, parto y consulta el
/// historial. `cambiarGrupo` y `registrarBaja` viven en [AnimalesRepository]
/// (ver Módulo 2), pero el resto de eventos reproductivos y sanitarios
/// puntuales viven aquí.
class EventosRepository {
  EventosRepository(this.db);

  final AppDatabase db;
  final _uuid = const Uuid();

  /// Historial completo (más reciente primero) para la Hoja de Vida.
  Stream<List<EventoAnimalRow>> listarHojaVida(String animalId) {
    return (db.select(db.eventosAnimal)
          ..where((t) => t.animalId.equals(animalId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.fecha)]))
        .watch();
  }

  Future<EventoAnimalRow?> ultimoEventoDeTipo(
    String animalId,
    String tipo,
  ) async {
    return (db.select(db.eventosAnimal)
          ..where(
            (t) =>
                t.animalId.equals(animalId) &
                t.tipo.equals(tipo) &
                t.deletedAt.isNull(),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.fecha)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Celo, monta o inseminación: guarda la fecha del servicio y, si aplica,
  /// el toro/pajilla usado.
  Future<void> registrarServicio({
    required String animalId,
    required String lecheriaId,
    required String tipo, // celo | monta | inseminacion
    String? toroPajilla,
    DateTime? fecha,
    String? registradoPor,
  }) async {
    final ahora = fecha ?? DateTime.now();
    await db
        .into(db.eventosAnimal)
        .insert(
          EventosAnimalCompanion.insert(
            id: _uuid.v4(),
            animalId: animalId,
            lecheriaId: lecheriaId,
            tipo: tipo,
            fecha: ahora,
            toroPajilla: Value(toroPajilla),
            registradoPor: Value(registradoPor),
            createdAt: ahora,
            updatedAt: ahora,
            pendiente: const Value(true),
          ),
        );
  }

  /// Nota libre sobre la vaca: lo que el ganadero quiera dejar apuntado.
  ///
  /// No cambia nada de la ficha del animal — es el único evento que no toca
  /// grupo, estado ni fechas. El texto va en `detalle` y queda en la hoja de
  /// vida junto a los demás eventos. Un texto en blanco no se guarda.
  Future<void> registrarObservacion({
    required String animalId,
    required String lecheriaId,
    required String texto,
    DateTime? fecha,
    String? registradoPor,
  }) async {
    final limpio = texto.trim();
    if (limpio.isEmpty) return;
    final ahora = fecha ?? DateTime.now();
    await db
        .into(db.eventosAnimal)
        .insert(
          EventosAnimalCompanion.insert(
            id: _uuid.v4(),
            animalId: animalId,
            lecheriaId: lecheriaId,
            tipo: TipoEventoAnimal.observacion,
            fecha: ahora,
            detalle: Value(limpio),
            registradoPor: Value(registradoPor),
            createdAt: ahora,
            updatedAt: ahora,
            pendiente: const Value(true),
          ),
        );
  }

  /// Palpación / diagnóstico: resultado preñada o vacía. Si está preñada,
  /// guarda la fecha probable de parto y actualiza el estado reproductivo.
  Future<void> registrarPalpacion({
    required String animalId,
    required String lecheriaId,
    required String resultado, // preñada | vacia
    DateTime? fechaProbableParto,
    DateTime? fecha,
    String? registradoPor,
  }) async {
    final ahora = fecha ?? DateTime.now();
    final preniada = resultado == ResultadoPalpacion.preniada;
    await db.transaction(() async {
      await db
          .into(db.eventosAnimal)
          .insert(
            EventosAnimalCompanion.insert(
              id: _uuid.v4(),
              animalId: animalId,
              lecheriaId: lecheriaId,
              tipo: TipoEventoAnimal.palpacion,
              fecha: ahora,
              resultado: Value(resultado),
              registradoPor: Value(registradoPor),
              createdAt: ahora,
              updatedAt: ahora,
              pendiente: const Value(true),
            ),
          );
      await (db.update(db.animales)..where((t) => t.id.equals(animalId))).write(
        AnimalesCompanion(
          estadoReproductivo: Value(
            preniada ? EstadoReproductivo.preniada : EstadoReproductivo.vacia,
          ),
          fechaProbableParto: Value(preniada ? fechaProbableParto : null),
          updatedAt: Value(ahora),
          pendiente: const Value(true),
        ),
      );
    });
  }

  /// Secado: la vaca deja de ordeñarse y pasa al grupo Secas.
  Future<void> registrarSecado({
    required String animalId,
    required String lecheriaId,
    DateTime? fecha,
    String? registradoPor,
  }) async {
    final animal = await (db.select(
      db.animales,
    )..where((t) => t.id.equals(animalId))).getSingle();
    final ahora = fecha ?? DateTime.now();
    await db.transaction(() async {
      await (db.update(db.animales)..where((t) => t.id.equals(animalId))).write(
        AnimalesCompanion(
          grupo: const Value(GrupoAnimal.secas),
          updatedAt: Value(ahora),
          pendiente: const Value(true),
        ),
      );
      await db
          .into(db.eventosAnimal)
          .insert(
            EventosAnimalCompanion.insert(
              id: _uuid.v4(),
              animalId: animalId,
              lecheriaId: lecheriaId,
              tipo: TipoEventoAnimal.secado,
              fecha: ahora,
              grupoAnterior: Value(animal.grupo),
              grupoNuevo: const Value(GrupoAnimal.secas),
              registradoPor: Value(registradoPor),
              createdAt: ahora,
              updatedAt: ahora,
              pendiente: const Value(true),
            ),
          );
    });
  }

  /// Parto: registra el evento en la madre, crea la cría como animal nuevo
  /// vinculado, y la madre vuelve al grupo En ordeño. Devuelve el id de la
  /// cría creada.
  Future<String> registrarParto({
    required String animalId, // madre
    required String lecheriaId,
    required String sexoCria,
    String? identificadorCria,
    DateTime? fecha,
    String? registradoPor,
  }) async {
    final madre = await (db.select(
      db.animales,
    )..where((t) => t.id.equals(animalId))).getSingle();
    final ahora = fecha ?? DateTime.now();
    final criaId = _uuid.v4();
    final identificador = identificadorCria?.trim().isNotEmpty == true
        ? identificadorCria!.trim()
        : 'CRIA-${ahora.millisecondsSinceEpoch}';

    await db.transaction(() async {
      await db
          .into(db.animales)
          .insert(
            AnimalesCompanion.insert(
              id: criaId,
              lecheriaId: lecheriaId,
              identificador: identificador,
              sexo: sexoCria,
              grupo: GrupoAnimal.terneros,
              origen: 'nacido',
              madreId: Value(animalId),
              createdAt: ahora,
              updatedAt: ahora,
              pendiente: const Value(true),
            ),
          );
      await (db.update(db.animales)..where((t) => t.id.equals(animalId))).write(
        AnimalesCompanion(
          grupo: const Value(GrupoAnimal.enOrdeno),
          estadoReproductivo: const Value(EstadoReproductivo.vacia),
          fechaProbableParto: const Value(null),
          // Arranca de nuevo la cuenta de días de lactancia (DLac), que es la
          // base del reporte de producción.
          fechaUltimoParto: Value(ahora),
          updatedAt: Value(ahora),
          pendiente: const Value(true),
        ),
      );
      await db
          .into(db.eventosAnimal)
          .insert(
            EventosAnimalCompanion.insert(
              id: _uuid.v4(),
              animalId: animalId,
              lecheriaId: lecheriaId,
              tipo: TipoEventoAnimal.parto,
              fecha: ahora,
              sexoCria: Value(sexoCria),
              grupoAnterior: Value(madre.grupo),
              grupoNuevo: const Value(GrupoAnimal.enOrdeno),
              criaAnimalId: Value(criaId),
              registradoPor: Value(registradoPor),
              createdAt: ahora,
              updatedAt: ahora,
              pendiente: const Value(true),
            ),
          );
    });
    return criaId;
  }

  /// Cría(s) de una vaca (genealogía en la Hoja de Vida).
  Stream<List<AnimalRow>> observarCrias(String madreId) {
    return (db.select(
      db.animales,
    )..where((t) => t.madreId.equals(madreId) & t.deletedAt.isNull())).watch();
  }

  Future<void> eliminarEvento(String eventoId) async {
    await (db.update(
      db.eventosAnimal,
    )..where((t) => t.id.equals(eventoId))).write(
      EventosAnimalCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        pendiente: const Value(true),
      ),
    );
  }
}
