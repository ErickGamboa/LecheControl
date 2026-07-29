import 'package:drift/drift.dart' show Value;
import 'package:leche_control/data/domain/grupos.dart';
import 'package:leche_control/data/local/database.dart';

/// Seeds a plan, cuenta and usuario for offline repository/integration
/// tests. Mirrors what `SyncService` would have downloaded after the first
/// online login.
Future<void> seedCuentaLocal(
  AppDatabase db, {
  required String usuarioId,
  DateTime? now,
  String cuentaId = 'cuenta-offline-1',
  String email = 'offline@example.com',
  String nombre = 'Usuario Offline',
  String plan = 'pro',
  int limiteLecherias = 5,
}) async {
  final ts = now ?? DateTime(2026, 1, 1);
  await db
      .into(db.planes)
      .insert(
        PlanesCompanion.insert(
          codigo: plan,
          nombre: 'Plan $plan',
          limiteLecherias: limiteLecherias,
          updatedAt: ts,
        ),
      );
  await db
      .into(db.cuentas)
      .insert(
        CuentasCompanion.insert(
          id: cuentaId,
          nombre: 'Cuenta offline',
          duenoId: usuarioId,
          plan: plan,
          estado: 'activa',
          createdAt: ts,
          updatedAt: ts,
        ),
      );
  await db
      .into(db.usuarios)
      .insert(
        UsuariosCompanion.insert(
          id: usuarioId,
          nombre: Value(nombre),
          email: Value(email),
          cuentaId: Value(cuentaId),
          createdAt: ts,
          updatedAt: ts,
        ),
      );
}

/// Seeds a lechería (and its admin membership for [usuarioId]) directly,
/// bypassing `LecheriasRepository` for tests that just need an existing
/// lechería to hang other rows off of. Returns the lechería id.
Future<String> seedLecheria(
  AppDatabase db, {
  required String usuarioId,
  String lecheriaId = 'lecheria-offline-1',
  String nombre = 'Lechería Test',
  String? cuentaId,
  DateTime? now,
}) async {
  final ts = now ?? DateTime(2026, 1, 1);
  await db
      .into(db.lecherias)
      .insert(
        LecheriasCompanion.insert(
          id: lecheriaId,
          nombre: nombre,
          creadaPor: usuarioId,
          cuentaId: Value(cuentaId),
          createdAt: ts,
          updatedAt: ts,
        ),
      );
  await db
      .into(db.lecheriaMiembros)
      .insert(
        LecheriaMiembrosCompanion.insert(
          id: '$lecheriaId-miembro-$usuarioId',
          lecheriaId: lecheriaId,
          usuarioId: usuarioId,
          rol: 'admin',
          createdAt: ts,
          updatedAt: ts,
        ),
      );
  return lecheriaId;
}

/// Seeds an animal directly (bypassing `AnimalesRepository`) for tests that
/// need a pre-existing animal without exercising the alta flow itself.
Future<String> seedAnimal(
  AppDatabase db, {
  required String lecheriaId,
  String id = 'animal-offline-1',
  String identificador = 'A-001',
  String sexo = Sexo.hembra,
  String grupo = GrupoAnimal.enOrdeno,
  String origen = OrigenAnimal.nacido,
  double concentradoKgDia = 0,
  DateTime? retiroLecheHasta,
  DateTime? now,
}) async {
  final ts = now ?? DateTime(2026, 1, 1);
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
          concentradoKgDia: Value(concentradoKgDia),
          retiroLecheHasta: Value(retiroLecheHasta),
          createdAt: ts,
          updatedAt: ts,
        ),
      );
  return id;
}
