import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../local/database.dart';
import 'curva_repository.dart';

/// Cuántas lecherías admite una cuenta y cuántas tiene hechas.
///
/// Es un límite **estructural**, no comercial: LecheControl trabaja con una
/// lechería activa por cuenta (spec Módulo 0), y toda la app —el home, la
/// pesa, las finanzas— está armada sobre ese supuesto. No hay nada que
/// comprar para levantarlo.
class CupoDeLecherias {
  const CupoDeLecherias({
    required this.cuentaId,
    required this.limite,
    required this.usadas,
  });

  final String cuentaId;
  final int limite;
  final int usadas;

  bool get alcanzoLimite => usadas >= limite;
}

/// Se lanza al intentar crear una lechería teniendo el cupo lleno.
///
/// En la práctica casi no se alcanza: el formulario de crear solo aparece
/// cuando el usuario todavía no tiene ninguna.
class LimiteLecheriasException implements Exception {
  const LimiteLecheriasException(this.limite);

  final int limite;

  /// Cómo se lo dice al ganadero. Sin nombrar planes ni pedirle nada: es un
  /// hecho de cómo trabaja la app.
  String get mensaje => limite == 1
      ? 'Ya tenés tu lechería creada.'
      : 'Ya tenés $limite lecherías creadas.';
}

/// Se lanza si todavía no bajó la cuenta del usuario. La lechería se cuelga
/// de una cuenta, así que hay que saber cuál es antes de crearla: pide
/// conectarse a internet **una vez**, no autoriza nada.
class CuentaNoSincronizadaException implements Exception {
  const CuentaNoSincronizadaException();
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

  /// Cuántas lecherías admite la cuenta del usuario y cuántas tiene hechas.
  /// Devuelve null si todavía no se conoce la cuenta (sin sincronizar).
  Future<CupoDeLecherias?> cupoDeLecherias(String usuarioId) async {
    final usuario = await (db.select(
      db.usuarios,
    )..where((u) => u.id.equals(usuarioId))).getSingleOrNull();
    final cuentaId = usuario?.cuentaId;
    if (cuentaId == null) return null;

    final cuenta = await (db.select(
      db.cuentas,
    )..where((c) => c.id.equals(cuentaId))).getSingleOrNull();
    if (cuenta == null) return null;

    // El número sale de la configuración que baja el sync. Es un tope
    // estructural —una lechería por cuenta— y no algo que se compre.
    final config = await (db.select(
      db.planes,
    )..where((p) => p.codigo.equals(cuenta.plan))).getSingleOrNull();

    return CupoDeLecherias(
      cuentaId: cuentaId,
      limite: config?.limiteLecherias ?? 1,
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
    final cupo = await cupoDeLecherias(creadaPor);
    if (cupo == null) {
      throw const CuentaNoSincronizadaException();
    }
    if (cupo.alcanzoLimite) {
      throw LimiteLecheriasException(cupo.limite);
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
              cuentaId: Value(cupo.cuentaId),
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
