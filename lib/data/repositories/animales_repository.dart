import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../domain/grupos.dart';
import '../local/database.dart';

/// Se lanza al intentar registrar un animal con un identificador que ya
/// existe activo dentro de la misma lechería.
class AnimalDuplicadoException implements Exception {
  const AnimalDuplicadoException(this.identificador);
  final String identificador;
}

/// Acceso a animales (inventario). Lee y escribe en la base local; la
/// sincronización con Supabase corre por separado (SyncService).
class AnimalesRepository {
  AnimalesRepository(this.db);

  final AppDatabase db;
  final _uuid = const Uuid();

  /// Busca un animal (no borrado, cualquier estado) por su identificador
  /// dentro de una lechería. Es el mismo dato que llega por RFID o manual.
  Future<AnimalRow?> buscarPorIdentificador(
    String lecheriaId,
    String identificador,
  ) {
    return (db.select(db.animales)..where(
          (t) =>
              t.lecheriaId.equals(lecheriaId) &
              t.identificador.equals(identificador) &
              t.deletedAt.isNull(),
        ))
        .getSingleOrNull();
  }

  /// Stream reactivo con un animal por id (para la tarjeta de la Pantalla de
  /// Trabajo y la Hoja de Vida).
  Stream<AnimalRow?> observarAnimal(String animalId) {
    return (db.select(
      db.animales,
    )..where((t) => t.id.equals(animalId))).watchSingleOrNull();
  }

  /// Stream reactivo con el inventario activo de la lechería, opcionalmente
  /// filtrado por grupo (Módulo 2).
  Stream<List<AnimalRow>> observarInventario(
    String lecheriaId, {
    String? grupo,
    String? busqueda,
  }) {
    final consulta = db.select(db.animales)
      ..where(
        (t) =>
            t.lecheriaId.equals(lecheriaId) &
            t.deletedAt.isNull() &
            t.estado.equals(EstadoAnimal.activo),
      )
      ..orderBy([(t) => OrderingTerm.asc(t.identificador)]);
    if (grupo != null) {
      consulta.where((t) => t.grupo.equals(grupo));
    }
    return consulta.watch().map((animales) {
      if (busqueda == null || busqueda.trim().isEmpty) return animales;
      final termino = busqueda.trim().toLowerCase();
      return animales
          .where((a) => a.identificador.toLowerCase().contains(termino))
          .toList();
    });
  }

  /// Stream con animales dados de baja (historial, Módulo 2).
  Stream<List<AnimalRow>> observarHistorialBajas(String lecheriaId) {
    return (db.select(db.animales)
          ..where(
            (t) =>
                t.lecheriaId.equals(lecheriaId) &
                t.deletedAt.isNull() &
                t.estado.equals(EstadoAnimal.activo).not(),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  /// Cuenta los animales activos de un grupo (para el contador de faltantes
  /// de la Pesa de leche).
  Future<int> contarPorGrupo(String lecheriaId, String grupo) async {
    final conteo = db.animales.id.count();
    final q = db.selectOnly(db.animales)
      ..addColumns([conteo])
      ..where(
        db.animales.lecheriaId.equals(lecheriaId) &
            db.animales.deletedAt.isNull() &
            db.animales.estado.equals(EstadoAnimal.activo) &
            db.animales.grupo.equals(grupo),
      );
    final row = await q.getSingle();
    return row.read(conteo) ?? 0;
  }

  /// Alta de un animal nuevo (Módulo 1 y 2). Pide lo mínimo: identificador,
  /// sexo, grupo y origen (comprado o nacido en la finca).
  Future<String> altaAnimal({
    required String lecheriaId,
    required String identificador,
    required String sexo,
    required String grupo,
    required String origen,
    double? precioCompra,
    DateTime? fechaCompra,
    String? madreId,
  }) async {
    final existente = await buscarPorIdentificador(lecheriaId, identificador);
    if (existente != null) {
      throw AnimalDuplicadoException(identificador);
    }
    final ahora = DateTime.now();
    final id = _uuid.v4();
    await db
        .into(db.animales)
        .insert(
          AnimalesCompanion.insert(
            id: id,
            lecheriaId: lecheriaId,
            identificador: identificador,
            sexo: sexo,
            grupo: grupo,
            origen: origen,
            precioCompra: Value(
              origen == OrigenAnimal.comprado ? precioCompra : null,
            ),
            fechaCompra: Value(
              origen == OrigenAnimal.comprado ? fechaCompra : null,
            ),
            madreId: Value(madreId),
            createdAt: ahora,
            updatedAt: ahora,
            pendiente: const Value(true),
          ),
        );
    return id;
  }

  /// Mueve un animal a otro grupo/estado y deja la fecha en la hoja de vida.
  Future<void> cambiarGrupo({
    required String animalId,
    required String lecheriaId,
    required String nuevoGrupo,
    DateTime? fecha,
    String? registradoPor,
  }) async {
    final animal = await (db.select(
      db.animales,
    )..where((t) => t.id.equals(animalId))).getSingle();
    if (animal.grupo == nuevoGrupo) return;

    final ahora = fecha ?? DateTime.now();
    await db.transaction(() async {
      await (db.update(db.animales)..where((t) => t.id.equals(animalId))).write(
        AnimalesCompanion(
          grupo: Value(nuevoGrupo),
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
              tipo: TipoEventoAnimal.cambioGrupo,
              fecha: ahora,
              grupoAnterior: Value(animal.grupo),
              grupoNuevo: Value(nuevoGrupo),
              registradoPor: Value(registradoPor),
              createdAt: ahora,
              updatedAt: ahora,
              pendiente: const Value(true),
            ),
          );
    });
  }

  /// Da de baja un animal: venta, muerte o descarte. No se borra — deja de
  /// aparecer en inventario/pesas pero queda en el historial (D-08 no negociable).
  Future<void> registrarBaja({
    required String animalId,
    required String lecheriaId,
    required String motivo,
    double? precioVenta,
    DateTime? fecha,
    String? registradoPor,
  }) async {
    final estadoNuevo = switch (motivo) {
      MotivoBaja.venta => EstadoAnimal.vendido,
      MotivoBaja.muerte => EstadoAnimal.muerto,
      MotivoBaja.descarte => EstadoAnimal.descartado,
      _ => EstadoAnimal.descartado,
    };
    final ahora = fecha ?? DateTime.now();
    await db.transaction(() async {
      await (db.update(db.animales)..where((t) => t.id.equals(animalId))).write(
        AnimalesCompanion(
          estado: Value(estadoNuevo),
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
              tipo: TipoEventoAnimal.baja,
              fecha: ahora,
              motivoBaja: Value(motivo),
              precioVenta: Value(
                motivo == MotivoBaja.venta ? precioVenta : null,
              ),
              registradoPor: Value(registradoPor),
              createdAt: ahora,
              updatedAt: ahora,
              pendiente: const Value(true),
            ),
          );
    });
  }

  /// Edita el consumo diario de concentrado (kg/día) de un animal. Editable en
  /// cualquier momento (Módulo 4).
  Future<void> actualizarConcentrado({
    required String animalId,
    required double kgDia,
  }) async {
    await (db.update(db.animales)..where((t) => t.id.equals(animalId))).write(
      AnimalesCompanion(
        concentradoKgDia: Value(kgDia),
        updatedAt: Value(DateTime.now()),
        pendiente: const Value(true),
      ),
    );
  }
}
