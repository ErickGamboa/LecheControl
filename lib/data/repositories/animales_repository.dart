import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../domain/grupos.dart';
import '../domain/semana.dart';
import '../local/database.dart';
import 'finanzas_repository.dart';

/// Se lanza al intentar registrar un animal con un identificador que ya
/// existe activo dentro de la misma lechería.
class AnimalDuplicadoException implements Exception {
  const AnimalDuplicadoException(this.identificador);
  final String identificador;
}

/// Acceso a animales (inventario). Lee y escribe en la base local; la
/// sincronización con Supabase corre por separado (SyncService).
class AnimalesRepository {
  AnimalesRepository(this.db, {FinanzasRepository? finanzasRepository})
    : _finanzas = finanzasRepository ?? FinanzasRepository(db);

  final AppDatabase db;

  /// Para anotar sola la compra de un animal como gasto de la semana.
  final FinanzasRepository _finanzas;
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
  ///
  /// [soloProntas] deja solo las vacas a las que les falta poco para parir.
  /// No es un grupo —la vaca sigue en Secas— sino un filtro sobre la fecha
  /// probable de parto, así que se aplica en memoria y se puede combinar con
  /// [grupo].
  Stream<List<AnimalRow>> observarInventario(
    String lecheriaId, {
    String? grupo,
    String? busqueda,
    bool soloProntas = false,
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
      var lista = animales;
      if (soloProntas) {
        lista = lista.where((a) => esPronta(a.fechaProbableParto)).toList();
      }
      if (busqueda == null || busqueda.trim().isEmpty) return lista;
      final termino = busqueda.trim().toLowerCase();
      return lista
          .where((a) => a.identificador.toLowerCase().contains(termino))
          .toList();
    });
  }

  /// Cuántas vacas activas están prontas (les falta poco para parir).
  Stream<int> observarConteoProntas(String lecheriaId) {
    return (db.select(db.animales)..where(
          (t) =>
              t.lecheriaId.equals(lecheriaId) &
              t.deletedAt.isNull() &
              t.estado.equals(EstadoAnimal.activo) &
              t.fechaProbableParto.isNotNull(),
        ))
        .watch()
        .map((as) => as.where((a) => esPronta(a.fechaProbableParto)).length);
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

  /// Cuántos animales activos hay en cada grupo, en un solo stream.
  ///
  /// El mapa siempre trae **todos** los grupos, con cero los que no tienen
  /// animales: así el resumen del home no cambia de forma —ni baila— cuando
  /// la finca se queda sin terneros.
  Stream<Map<String, int>> observarConteoPorGrupo(String lecheriaId) {
    final grupo = db.animales.grupo;
    final conteo = db.animales.id.count();
    final q = db.selectOnly(db.animales)
      ..addColumns([grupo, conteo])
      ..where(
        db.animales.lecheriaId.equals(lecheriaId) &
            db.animales.deletedAt.isNull() &
            db.animales.estado.equals(EstadoAnimal.activo),
      )
      ..groupBy([grupo]);

    return q.watch().map((filas) {
      final mapa = {for (final g in GrupoAnimal.todos) g: 0};
      for (final f in filas) {
        final codigo = f.read(grupo);
        if (codigo == null) continue;
        mapa[codigo] = f.read(conteo) ?? 0;
      }
      return mapa;
    });
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
  ///
  /// [fechaUltimoParto] es opcional pero importante para las vacas que entran
  /// al grupo En ordeño: sin ella no hay días de lactancia y la vaca queda
  /// fuera de la comparación contra la curva en el reporte de producción. De
  /// ahí en adelante la mantiene sola el evento de parto.
  ///
  /// Si el animal es **comprado** y trae precio, la app anota sola el gasto de
  /// la semana de la compra (categoría "Compra de ganado", con el
  /// identificador del animal en el detalle). El ganadero no tiene que ir a
  /// Finanzas a repetir la plata que ya digitó acá.
  Future<String> altaAnimal({
    required String lecheriaId,
    required String identificador,
    required String sexo,
    required String grupo,
    required String origen,
    double? precioCompra,
    DateTime? fechaCompra,
    String? madreId,
    DateTime? fechaUltimoParto,
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
            fechaUltimoParto: Value(fechaUltimoParto),
            createdAt: ahora,
            updatedAt: ahora,
            pendiente: const Value(true),
          ),
        );

    if (origen == OrigenAnimal.comprado &&
        precioCompra != null &&
        precioCompra > 0) {
      await _anotarGastoDeCompra(
        lecheriaId: lecheriaId,
        identificador: identificador,
        precioCompra: precioCompra,
        fechaCompra: fechaCompra ?? ahora,
      );
    }
    return id;
  }

  /// Mete la compra del animal como un gasto más de la semana en la que se
  /// compró. Va aparte del alta (fuera de su transacción) a propósito: si algo
  /// falla anotando la plata, el animal igual queda registrado, que es lo que
  /// el ganadero está viendo en pantalla.
  Future<void> _anotarGastoDeCompra({
    required String lecheriaId,
    required String identificador,
    required double precioCompra,
    required DateTime fechaCompra,
  }) async {
    final semana = await _finanzas.abrirSemana(
      lecheriaId: lecheriaId,
      fecha: fechaCompra,
    );
    await _finanzas.agregarGasto(
      lecheriaId: lecheriaId,
      semanaId: semana.id,
      categoria: CategoriaGasto.compraGanado,
      monto: precioCompra,
      detalle: identificador,
    );
  }

  /// Corrige a mano la fecha del último parto. Sirve para cargar de una vez
  /// las vacas que ya estaban en la finca antes de usar la app, y para
  /// arreglar una fecha mal digitada.
  Future<void> editarFechaUltimoParto({
    required String animalId,
    required DateTime? fecha,
  }) async {
    final ahora = DateTime.now();
    await (db.update(db.animales)..where((t) => t.id.equals(animalId))).write(
      AnimalesCompanion(
        fechaUltimoParto: Value(fecha),
        updatedAt: Value(ahora),
        pendiente: const Value(true),
      ),
    );
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
}
