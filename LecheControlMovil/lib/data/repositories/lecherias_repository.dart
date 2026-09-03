import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../local/database.dart';
import 'curva_repository.dart';

/// Estado de la licencia de una cuenta: qué plan tiene y cuántas lecherías
/// permite. Sirve para validar el límite al crear (spec: una lechería activa
/// por cuenta en v1).
class EstadoLicencia {
  const EstadoLicencia({
    required this.cuentaId,
    required this.planNombre,
    required this.limite,
    required this.usadas,
  });

  final String cuentaId;
  final String planNombre;
  final int limite;
  final int usadas;

  bool get alcanzoLimite => usadas >= limite;
}

/// Se lanza al intentar crear una lechería habiendo alcanzado el límite del
/// plan (v1: normalmente 1).
class LimiteLecheriasException implements Exception {
  const LimiteLecheriasException(this.limite, this.planNombre);
  final int limite;
  final String planNombre;
}

/// Se lanza si todavía no conocemos la cuenta del usuario (no se ha
/// sincronizado). Requiere conectarse a internet una vez.
class LicenciaNoDisponibleException implements Exception {
  const LicenciaNoDisponibleException();
}

/// Acceso a la(s) lechería(s). SIEMPRE lee y escribe en la base local
/// (instantáneo y offline). La sincronización con Supabase corre por
/// separado (SyncService).
class LecheriasRepository {
  LecheriasRepository(this.db, {CurvaRepository? curva})
    : _curva = curva ?? CurvaRepository(db);

  final AppDatabase db;
  final CurvaRepository _curva;
  final _uuid = const Uuid();

  /// Stream reactivo con la lechería del usuario (donde es miembro), no
  /// borrada. Por ahora una lechería activa por cuenta (spec Módulo 0).
  Stream<LecheriaRow?> observarLecheriaDeUsuario(String usuarioId) {
    final consulta =
        db.select(db.lecherias).join([
            innerJoin(
              db.lecheriaMiembros,
              db.lecheriaMiembros.lecheriaId.equalsExp(db.lecherias.id),
            ),
          ])
          ..where(
            db.lecheriaMiembros.usuarioId.equals(usuarioId) &
                db.lecheriaMiembros.deletedAt.isNull() &
                db.lecherias.deletedAt.isNull(),
          )
          ..orderBy([OrderingTerm.asc(db.lecherias.createdAt)])
          ..limit(1);

    return consulta.watchSingleOrNull().map(
      (fila) => fila?.readTable(db.lecherias),
    );
  }

  /// Lechería activa del usuario (una sola vez, no reactivo). null si todavía
  /// no tiene ninguna.
  Future<LecheriaRow?> obtenerActiva(String usuarioId) {
    return observarLecheriaDeUsuario(usuarioId).first;
  }

  /// Calcula el estado de licencia del usuario (plan y límite de lecherías).
  /// Devuelve null si todavía no se conoce la cuenta (sin sincronizar).
  Future<EstadoLicencia?> estadoLicencia(String usuarioId) async {
    final usuario = await (db.select(
      db.usuarios,
    )..where((u) => u.id.equals(usuarioId))).getSingleOrNull();
    final cuentaId = usuario?.cuentaId;
    if (cuentaId == null) return null;

    final cuenta = await (db.select(
      db.cuentas,
    )..where((c) => c.id.equals(cuentaId))).getSingleOrNull();
    if (cuenta == null) return null;

    final plan = await (db.select(
      db.planes,
    )..where((p) => p.codigo.equals(cuenta.plan))).getSingleOrNull();

    return EstadoLicencia(
      cuentaId: cuentaId,
      planNombre: plan?.nombre ?? cuenta.plan,
      limite: plan?.limiteLecherias ?? 1,
      usadas: await _contarLecheriasPropias(cuentaId),
    );
  }

  Future<int> _contarLecheriasPropias(String cuentaId) async {
    final conteo = db.lecherias.id.count();
    final q = db.selectOnly(db.lecherias)
      ..addColumns([conteo])
      ..where(
        db.lecherias.cuentaId.equals(cuentaId) &
            db.lecherias.deletedAt.isNull(),
      );
    final row = await q.getSingle();
    return row.read(conteo) ?? 0;
  }

  /// Crea una lechería y, en la misma transacción, agrega al creador como
  /// admin. Ambas filas quedan `pendiente`.
  Future<void> crearLecheria({
    required String nombre,
    required String creadaPor,
  }) async {
    final estado = await estadoLicencia(creadaPor);
    if (estado == null) {
      throw const LicenciaNoDisponibleException();
    }
    if (estado.alcanzoLimite) {
      throw LimiteLecheriasException(estado.limite, estado.planNombre);
    }

    final ahora = DateTime.now();
    final lecheriaId = _uuid.v4();

    await db.transaction(() async {
      await db
          .into(db.lecherias)
          .insert(
            LecheriasCompanion.insert(
              id: lecheriaId,
              nombre: nombre,
              creadaPor: creadaPor,
              cuentaId: Value(estado.cuentaId),
              createdAt: ahora,
              updatedAt: ahora,
              pendiente: const Value(true),
            ),
          );
      await db
          .into(db.lecheriaMiembros)
          .insert(
            LecheriaMiembrosCompanion.insert(
              id: _uuid.v4(),
              lecheriaId: lecheriaId,
              usuarioId: creadaPor,
              rol: 'admin',
              createdAt: ahora,
              updatedAt: ahora,
              pendiente: const Value(true),
            ),
          );
    });

    // Arranca con la curva de referencia, los umbrales del reporte y las
    // categorías de gasto ya cargados, para que la app sirva desde la primera
    // pesa sin obligar a configurar nada.
    await _curva.sembrarSiHaceFalta(lecheriaId);
  }

  /// Edita el nombre de la lechería.
  Future<void> editarNombre({
    required String lecheriaId,
    required String nombre,
  }) async {
    await (db.update(
      db.lecherias,
    )..where((t) => t.id.equals(lecheriaId))).write(
      LecheriasCompanion(
        nombre: Value(nombre),
        updatedAt: Value(DateTime.now()),
        pendiente: const Value(true),
      ),
    );
  }
}
