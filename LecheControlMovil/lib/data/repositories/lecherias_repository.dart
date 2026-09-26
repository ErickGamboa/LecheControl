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

  /// Cómo se lo dice al ganadero.
  ///
  /// **No dice cuántas tiene ni cuántas puede tener**, a propósito y en serio:
  /// ese número no es asunto suyo y nombrarlo convierte una decisión interna
  /// en algo que parece comprable. En la práctica este mensaje casi no se ve
  /// —el botón de agregar no aparece cuando no cabe—, y existe solo como red
  /// para el caso raro de dos teléfonos creando al mismo tiempo.
  String get mensaje => 'No se pudo agregar la finca.';
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
    return observarLecheriasDeUsuario(
      usuarioId,
    ).map((lista) => lista.isEmpty ? null : lista.first);
  }

  /// Todas las lecherías del usuario, de la más vieja a la más nueva.
  ///
  /// El orden por fecha de creación no es un detalle: la primera de la lista
  /// es la que el ganadero creó cuando empezó a usar la app, y es la que se
  /// abre sola cuando solo tiene una. Ordenarlas por nombre le movería la
  /// finca de siempre el día que creara otra que empiece con «A».
  Stream<List<LecheriaRow>> observarLecheriasDeUsuario(String usuarioId) {
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
          ..orderBy([OrderingTerm.asc(db.lecherias.createdAt)]);

    return consulta.watch().map(
      (filas) => [for (final f in filas) f.readTable(db.lecherias)],
    );
  }

  /// Si a la cuenta del usuario todavía le caben más lecherías.
  ///
  /// Es lo único que la app necesita saber del cupo, y por eso devuelve un
  /// `bool` y no el número: **en pantalla no se dice cuántas tiene ni cuántas
  /// puede**. O aparece el botón de agregar, o no aparece.
  ///
  /// Ante la duda, `false`. Si la cuenta todavía no sincronizó no hay de dónde
  /// sacar el tope, y es mejor no ofrecer un botón que después falle que
  /// ofrecerlo y que no funcione.
  Future<bool> puedeAgregarLecheria(String usuarioId) async {
    final cupo = await cupoDeLecherias(usuarioId);
    return cupo != null && !cupo.alcanzoLimite;
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

  /// Borra la finca de todos los teléfonos de la cuenta.
  ///
  /// **Para el ganadero esto no se deshace.** La finca desaparece de la lista
  /// acá y en cualquier otro teléfono en cuanto sincronice, y con ella se va
  /// el camino a sus animales, sus eventos, sus pesas y sus finanzas: la app
  /// no tiene por dónde volver a entrar. Por eso la pantalla le hace escribir
  /// el nombre antes de dejarlo hacerlo.
  ///
  /// Lo que se marca es la finca y el vínculo de sus miembros. Las filas de
  /// animales y demás no se tocan una por una, y es a propósito: son miles y
  /// marcarlas todas sería una subida enorme que, si se corta a la mitad,
  /// deja la finca medio borrada. Quedan colgando de una finca que ya no
  /// existe, que para la app es lo mismo que no estar.
  Future<void> eliminarLecheria(String lecheriaId) async {
    final ahora = DateTime.now();
    await db.transaction(() async {
      await (db.update(
        db.lecherias,
      )..where((t) => t.id.equals(lecheriaId))).write(
        LecheriasCompanion(
          deletedAt: Value(ahora),
          updatedAt: Value(ahora),
          pendiente: const Value(true),
        ),
      );
      await (db.update(db.lecheriaMiembros)..where(
            (t) => t.lecheriaId.equals(lecheriaId) & t.deletedAt.isNull(),
          ))
          .write(
            LecheriaMiembrosCompanion(
              deletedAt: Value(ahora),
              updatedAt: Value(ahora),
              pendiente: const Value(true),
            ),
          );
    });
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
