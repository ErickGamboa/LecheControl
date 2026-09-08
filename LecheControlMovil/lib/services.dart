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
import 'data/repositories/partos_repository.dart';
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
final PartosRepository partosRepo = PartosRepository(db);
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

/// Intenta sincronizar. Lo único que la detiene es no tener sesión.
///
/// **No se pregunta si hay internet, y es a propósito.** Antes esto arrancaba
/// con `if (!estadoConexion.hayConexion.value) return;` y ahí se trababa la
/// app entera:
///
/// `connectivity_plus` dice si hay una **interfaz** de red, no si internet
/// funciona, y su primera lectura al arrancar puede contestar `none` por una
/// carrera con el sistema. `EstadoConexion` guarda ese `false` y solo lo
/// corrige cuando llega un evento de **cambio** de red; con un WiFi estable
/// ese evento no llega nunca. Resultado: la app quedaba convencida de estar
/// sin internet para siempre y no sincronizaba ni una vez, aunque la red
/// estuviera perfecta. El que entraba por primera vez se quedaba en
/// «Preparando tu cuenta…» hasta reinstalar, y reinstalar solo cambiaba la
/// suerte de esa primera lectura.
///
/// Una detección de red es una **pista**, no un permiso. Intentar sin red
/// cuesta una petición que falla rápido y que el sync ya sabe manejar —la
/// registra y reintenta—; no intentar cuando la pista se equivoca deja la app
/// inservible. El costo está todo de un lado.
///
/// `estadoConexion.hayConexion` sigue existiendo para lo que sí es: avisarle
/// al ganadero en pantalla (el ícono del home, la ayuda del login).
Future<void> sincronizarSiSePuede() async {
  final client = supabaseClientOrNull;
  if (client == null || client.auth.currentSession == null) {
    return;
  }
  await syncService.sincronizar();
}

/// Si la primera bajada del servidor todavía no llegó.
///
/// La cuenta es lo primero que baja el sync después de los planes, y sin ella
/// la app no puede mostrar nada: si no está, es que nunca se completó una
/// bajada. Sirve para que la red de seguridad reintente en ese caso, que es
/// el único en el que no hay nada pendiente de subir y aun así falta trabajo.
Future<bool> faltaLaPrimeraBajada() async {
  final cuantas = await db.select(db.cuentas).get();
  return cuantas.isEmpty;
}

/// Qué dijo el sync la última vez, en una línea, para mostrarlo en pantalla.
///
/// **Por qué existe.** Los errores del sync van a `debugPrint`, que en una app
/// instalada de TestFlight o de la tienda **no se ve**. Cuando algo falla en
/// el teléfono del ganadero, ni él ni soporte tienen con qué: solo una
/// pantalla que espera. Diagnosticar así es adivinar.
///
/// `SyncEstados` ya guardaba el último error de cada tabla; lo único que
/// faltaba era sacarlo a la luz.
/// Nunca lanza: es una ayuda para entender una falla, así que reventar acá
/// sería tapar el problema con otro. Si no se puede leer, lo dice y ya.
Future<String> diagnosticoDeSync({AppDatabase? base}) async {
  try {
    return await _diagnosticoDeSync(base: base);
  } catch (e) {
    return 'No se pudo leer el estado de la sincronización ($e).';
  }
}

Future<String> _diagnosticoDeSync({AppDatabase? base}) async {
  final d = base ?? db;
  final filas = await d.select(d.syncEstados).get();
  if (filas.isEmpty) {
    // Ni éxito ni error en ninguna tabla: la sincronización no llegó a
    // correr. Eso ya dice mucho —no es el servidor, es que no se intentó—.
    return 'La sincronización no llegó a correr.';
  }

  final conError = filas.where((f) => f.ultimoError != null).toList()
    ..sort(
      (a, b) => (b.ultimoErrorEn ?? DateTime(0)).compareTo(
        a.ultimoErrorEn ?? DateTime(0),
      ),
    );

  if (conError.isEmpty) {
    final ok = filas.where((f) => f.ultimaSincronizacionOk != null).length;
    return 'Bajó $ok de ${filas.length} tablas sin errores.';
  }

  final peor = conError.first;
  return '${peor.tabla}: ${peor.ultimoError}';
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
