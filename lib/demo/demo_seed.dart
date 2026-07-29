import 'package:drift/drift.dart';

import '../data/domain/grupos.dart';
import '../data/local/database.dart';
import '../data/repositories/animales_repository.dart';
import '../data/repositories/gastos_repository.dart';
import '../data/repositories/lecherias_repository.dart';
import '../data/repositories/medicamentos_repository.dart';
import '../data/repositories/pesas_repository.dart';
import '../services.dart';
import 'demo_env.dart';

/// IDs y nombres fijos del set de datos de demostración (para poder
/// reconocerlos y no duplicarlos si se vuelve a sembrar).
abstract final class DemoSeedIds {
  static const userId = '00000000-0000-4000-9000-000000000001';
  static const cuentaId = '00000000-0000-4000-9000-000000000010';
  static const lecheriaNombre = 'Lechería Demo LecheControl';
}

/// Siembra una lechería demo completa (offline) para explorar la app sin
/// necesitar un proyecto de Supabase: hato con 5 animales en distintos
/// grupos, medicamentos, parámetros del mes y una sesión de pesa reciente.
class DemoSeed {
  DemoSeed({
    AppDatabase? database,
    LecheriasRepository? lecherias,
    AnimalesRepository? animales,
    PesasRepository? pesas,
    GastosRepository? gastos,
    MedicamentosRepository? medicamentos,
  }) : _db = database ?? db,
       _lecherias = lecherias ?? lecheriasRepo,
       _animales = animales ?? animalesRepo,
       _pesas = pesas ?? pesasRepo,
       _gastos = gastos ?? gastosRepo,
       _medicamentos = medicamentos ?? medicamentosRepo;

  final AppDatabase _db;
  final LecheriasRepository _lecherias;
  final AnimalesRepository _animales;
  final PesasRepository _pesas;
  final GastosRepository _gastos;
  final MedicamentosRepository _medicamentos;

  /// Idempotente: si la lechería demo ya existe para este usuario, no hace
  /// nada más que devolver su id.
  Future<String> seedIfAbsent({required String usuarioId}) async {
    final existente = await _lecherias
        .observarLecheriaDeUsuario(usuarioId)
        .first;
    if (existente != null) return existente.id;

    await _ensureCuenta(usuarioId);
    await _lecherias.crearLecheria(
      nombre: DemoSeedIds.lecheriaNombre,
      creadaPor: usuarioId,
    );
    final lecheria = await _lecherias
        .observarLecheriaDeUsuario(usuarioId)
        .first;
    final lecheriaId = lecheria!.id;

    await _sembrarMedicamentos(lecheriaId);
    await _sembrarAnimales(lecheriaId);
    await _sembrarParametros(lecheriaId);
    await _sembrarPesaReciente(lecheriaId);

    return lecheriaId;
  }

  Future<void> _sembrarMedicamentos(String lecheriaId) async {
    await _medicamentos.crearMedicamento(
      lecheriaId: lecheriaId,
      nombre: 'Oxitetraciclina',
      costoEnvase: 12000,
      tipoDosis: TipoDosisMedicamento.fija,
      mlEnvase: 100,
      dosisFijaMl: 10,
      diasRetiroLeche: 4,
    );
    await _medicamentos.crearMedicamento(
      lecheriaId: lecheriaId,
      nombre: 'Vitaminas AD3E',
      costoEnvase: 8000,
      tipoDosis: TipoDosisMedicamento.fija,
      mlEnvase: 100,
      dosisFijaMl: 5,
      diasRetiroLeche: 0,
    );
    await _medicamentos.crearMedicamento(
      lecheriaId: lecheriaId,
      nombre: 'Desparasitante spray',
      costoEnvase: 15000,
      tipoDosis: TipoDosisMedicamento.porAplicacion,
      aplicacionesEnvase: 20,
      diasRetiroLeche: 0,
    );
  }

  Future<void> _sembrarAnimales(String lecheriaId) async {
    final ahora = DateTime.now();

    // 3 vacas en ordeño (una con concentrado y retiro de leche vigente).
    await _animales.altaAnimal(
      lecheriaId: lecheriaId,
      identificador: '1001',
      sexo: Sexo.hembra,
      grupo: GrupoAnimal.enOrdeno,
      origen: OrigenAnimal.nacido,
    );
    await _fijarConcentrado(lecheriaId, '1001', 3.5);

    await _animales.altaAnimal(
      lecheriaId: lecheriaId,
      identificador: '1002',
      sexo: Sexo.hembra,
      grupo: GrupoAnimal.enOrdeno,
      origen: OrigenAnimal.comprado,
      precioCompra: 450000,
      fechaCompra: ahora.subtract(const Duration(days: 400)),
    );
    await _fijarConcentrado(lecheriaId, '1002', 4.0);

    await _animales.altaAnimal(
      lecheriaId: lecheriaId,
      identificador: '1003',
      sexo: Sexo.hembra,
      grupo: GrupoAnimal.enOrdeno,
      origen: OrigenAnimal.nacido,
    );
    await _fijarConcentrado(lecheriaId, '1003', 2.5);
    await _fijarRetiro(lecheriaId, '1003', ahora.add(const Duration(days: 2)));

    // 1 vaca seca, próxima a parir.
    await _animales.altaAnimal(
      lecheriaId: lecheriaId,
      identificador: '2001',
      sexo: Sexo.hembra,
      grupo: GrupoAnimal.secas,
      origen: OrigenAnimal.nacido,
    );
    await _fijarPreniez(
      lecheriaId,
      '2001',
      fechaProbableParto: ahora.add(const Duration(days: 10)),
    );

    // 1 novilla.
    await _animales.altaAnimal(
      lecheriaId: lecheriaId,
      identificador: '3001',
      sexo: Sexo.hembra,
      grupo: GrupoAnimal.novillas,
      origen: OrigenAnimal.nacido,
    );
  }

  Future<void> _fijarConcentrado(
    String lecheriaId,
    String identificador,
    double kgDia,
  ) async {
    final animal = await _animales.buscarPorIdentificador(
      lecheriaId,
      identificador,
    );
    if (animal == null) return;
    await _animales.actualizarConcentrado(animalId: animal.id, kgDia: kgDia);
  }

  Future<void> _fijarRetiro(
    String lecheriaId,
    String identificador,
    DateTime retiroHasta,
  ) async {
    final animal = await _animales.buscarPorIdentificador(
      lecheriaId,
      identificador,
    );
    if (animal == null) return;
    await (_db.update(
      _db.animales,
    )..where((t) => t.id.equals(animal.id))).write(
      AnimalesCompanion(
        retiroLecheHasta: Value(retiroHasta),
        updatedAt: Value(DateTime.now()),
        pendiente: const Value(true),
      ),
    );
  }

  Future<void> _fijarPreniez(
    String lecheriaId,
    String identificador, {
    required DateTime fechaProbableParto,
  }) async {
    final animal = await _animales.buscarPorIdentificador(
      lecheriaId,
      identificador,
    );
    if (animal == null) return;
    await (_db.update(
      _db.animales,
    )..where((t) => t.id.equals(animal.id))).write(
      AnimalesCompanion(
        estadoReproductivo: const Value(EstadoReproductivo.preniada),
        fechaProbableParto: Value(fechaProbableParto),
        updatedAt: Value(DateTime.now()),
        pendiente: const Value(true),
      ),
    );
  }

  Future<void> _sembrarParametros(String lecheriaId) async {
    final ahora = DateTime.now();
    await _gastos.upsertParametrosPeriodo(
      lecheriaId: lecheriaId,
      anio: ahora.year,
      mes: ahora.month,
      precioLitro: 380,
      precioConcentradoKg: 320,
      umbralSecadoLitros: 8,
    );
    final periodo = await _gastos.obtenerPeriodo(
      lecheriaId,
      ahora.year,
      ahora.month,
    );
    if (periodo == null) return;
    await _gastos.addCostoFijo(
      lecheriaId: lecheriaId,
      periodoId: periodo.id,
      categoria: 'Luz',
      monto: 45000,
    );
    await _gastos.addCostoFijo(
      lecheriaId: lecheriaId,
      periodoId: periodo.id,
      categoria: 'Salario del peón',
      monto: 320000,
    );
    await _gastos.addCostoFijo(
      lecheriaId: lecheriaId,
      periodoId: periodo.id,
      categoria: 'Agua',
      monto: 15000,
    );
  }

  Future<void> _sembrarPesaReciente(String lecheriaId) async {
    final sesion = await _pesas.abrirSesion(lecheriaId: lecheriaId);
    final litrosPorIdentificador = {'1001': 18.5, '1002': 21.0, '1003': 14.2};
    for (final entry in litrosPorIdentificador.entries) {
      final animal = await _animales.buscarPorIdentificador(
        lecheriaId,
        entry.key,
      );
      if (animal == null) continue;
      await _pesas.registrarPesa(
        sesionId: sesion.id,
        animalId: animal.id,
        litros: entry.value,
      );
    }
    await _pesas.cerrarSesion(sesion.id);
  }

  Future<void> _ensureCuenta(String usuarioId) async {
    final existe = await (_db.select(
      _db.usuarios,
    )..where((t) => t.id.equals(usuarioId))).getSingleOrNull();
    if (existe != null) return;

    final ts = DateTime(2026, 1, 1);
    await _db
        .into(_db.planes)
        .insertOnConflictUpdate(
          PlanesCompanion.insert(
            codigo: 'pro',
            nombre: 'Pro',
            limiteLecherias: 5,
            updatedAt: ts,
          ),
        );
    await _db
        .into(_db.cuentas)
        .insert(
          CuentasCompanion.insert(
            id: DemoSeedIds.cuentaId,
            nombre: 'Cuenta Demo LecheControl',
            duenoId: usuarioId,
            plan: 'pro',
            estado: 'activa',
            createdAt: ts,
            updatedAt: ts,
          ),
        );
    await _db
        .into(_db.usuarios)
        .insert(
          UsuariosCompanion.insert(
            id: usuarioId,
            nombre: const Value('Ganadero Demo'),
            email: const Value('demo@lechecontrol.cr'),
            cuentaId: const Value(DemoSeedIds.cuentaId),
            createdAt: ts,
            updatedAt: ts,
          ),
        );
  }
}

/// Activa la sesión local offline (llamar después de [DemoSeed.seedIfAbsent]).
Future<void> activateDemoOfflineSession({String? usuarioId}) async {
  final uid = usuarioId ?? DemoSeedIds.userId;
  await sesionLocalRepo.guardarUsuarioVerificado(
    usuarioId: uid,
    email: 'demo@lechecontrol.cr',
    nombre: 'Ganadero Demo',
  );
  await sesionLocalRepo.activarOffline();
}

/// Siembra los datos demo + sesión offline cuando `LECHE_DEMO` está activo.
Future<void> maybeSeedDemoOnStartup() async {
  if (!kSeedDemoEnabled) return;

  const uid = String.fromEnvironment(
    'DEMO_USER_ID',
    defaultValue: DemoSeedIds.userId,
  );
  await DemoSeed().seedIfAbsent(usuarioId: uid);
  try {
    await supabase.auth.signOut();
  } catch (_) {
    // Demo: no requiere sesión real de Supabase.
  }
  await activateDemoOfflineSession(usuarioId: uid);
}
