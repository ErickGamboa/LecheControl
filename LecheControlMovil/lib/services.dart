import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'connectivity/estado_conexion.dart';
import 'data/local/database.dart';
import 'data/repositories/animales_repository.dart';
import 'data/repositories/calidad_repository.dart';
import 'data/repositories/cuentas_repository.dart';
import 'data/repositories/curva_repository.dart';
import 'data/repositories/eventos_repository.dart';
import 'data/repositories/finanzas_repository.dart';
import 'data/repositories/lecherias_repository.dart';
import 'data/repositories/medicamentos_repository.dart';
import 'data/repositories/palpacion_repository.dart';
import 'data/repositories/pesas_repository.dart';
import 'data/repositories/reporte_repository.dart';
import 'data/repositories/sanidad_repository.dart';
import 'data/repositories/sesion_local_repository.dart';
import 'data/sync/sync_service.dart';

/// Instancias compartidas de la app (se crean una sola vez, de forma
/// perezosa). Más adelante, si conviene, las podemos mover a Riverpod.
final AppDatabase db = AppDatabase();
final CurvaRepository curvaRepo = CurvaRepository(db);
final LecheriasRepository lecheriasRepo = LecheriasRepository(db);
final CuentasRepository cuentasRepo = CuentasRepository(db);
final FinanzasRepository finanzasRepo = FinanzasRepository(db);
final AnimalesRepository animalesRepo = AnimalesRepository(
  db,
  finanzasRepository: finanzasRepo,
);
final CalidadRepository calidadRepo = CalidadRepository(
  db,
  finanzasRepository: finanzasRepo,
);
final EventosRepository eventosRepo = EventosRepository(db);
final PesasRepository pesasRepo = PesasRepository(db);
final PalpacionRepository palpacionRepo = PalpacionRepository(db);
final ReporteRepository reporteRepo = ReporteRepository(db, curva: curvaRepo);
final MedicamentosRepository medicamentosRepo = MedicamentosRepository(db);
final SanidadRepository sanidadRepo = SanidadRepository(
  db,
  medicamentosRepository: medicamentosRepo,
);
final SesionLocalRepository sesionLocalRepo = SesionLocalRepository(db);
final SyncService syncService = SyncService(db);
final EstadoConexion estadoConexion = EstadoConexion();

SupabaseClient get supabase => Supabase.instance.client;

/// Cliente de Supabase, o `null` si no hay configuración o si
/// `Supabase.initialize` todavía no corrió (por ejemplo en tests de widget,
/// que montan pantallas sin pasar por `bootstrapLecheControl`).
SupabaseClient? get supabaseClientOrNull {
  if (!SupabaseConfig.estaConfigurado) return null;
  try {
    return Supabase.instance.client;
  } on AssertionError {
    return null;
  }
}

Future<void> sincronizarSiSePuede() async {
  if (!estadoConexion.hayConexion.value) {
    return;
  }
  final client = supabaseClientOrNull;
  if (client == null || client.auth.currentSession == null) {
    return;
  }
  await syncService.sincronizar();
}

Future<void> cerrarSesion() async {
  await sesionLocalRepo.borrar();
  final client = supabaseClientOrNull;
  if (client == null) return;
  try {
    await client.auth.signOut();
  } catch (_) {
    // Sin conexión puede fallar el signOut remoto; la sesión local ya quedó
    // cerrada para este dispositivo.
  }
}
