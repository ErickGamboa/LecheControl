import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../local/database.dart';
import 'sync_remote_gateway.dart';

/// Cómo subir las filas `pendiente=true` de una tabla: qué mandar y cómo
/// marcarlas subidas al terminar. `pendientes()` devuelve pares (id, datos)
/// para no acoplar el motor genérico al tipo de fila de cada tabla.
class PushSpec {
  const PushSpec({required this.pendientes, required this.marcarSubida});

  final Future<List<(String id, Map<String, dynamic> datos)>> Function()
  pendientes;
  final Future<void> Function(String id) marcarSubida;
}

/// Cómo aplicar una fila bajada del servidor, y (si la tabla tiene
/// `pendiente`) cómo saber si la fila local tiene cambios sin subir que no
/// hay que pisar. `tieneCambioLocalPendiente` es null para tablas sin guard
/// (sin columna `pendiente`, como `planes`).
///
/// `idDe` extrae el identificador de la fila remota para el guard y el
/// cursor compuesto — por defecto `r['id']`, salvo `planes` cuya llave
/// natural es `codigo` (no tiene columna `id`).
class PullSpec {
  const PullSpec({
    required this.aplicar,
    this.tieneCambioLocalPendiente,
    this.idDe = _idPorDefecto,
    this.idColumnaRemota = 'id',
  });

  final Future<void> Function(Map<String, dynamic> fila) aplicar;
  final Future<bool> Function(String id)? tieneCambioLocalPendiente;
  final String Function(Map<String, dynamic> fila) idDe;

  /// Nombre de la columna remota que identifica la fila, para el filtro y
  /// orden del cursor compuesto (ver [SyncRemoteGateway.consultar]). Debe
  /// coincidir con lo que [idDe] lee del mapa remoto.
  final String idColumnaRemota;

  static String _idPorDefecto(Map<String, dynamic> fila) =>
      fila['id'] as String;
}

/// Todo lo que el motor de sync necesita saber de una tabla. `subida` es
/// null para tablas de solo lectura (`planes`, `cuentas`, `usuarios`): el
/// motor genérico (`_subirTabla`/`_bajarTabla`) hace el resto igual para
/// todas.
class TableSyncSpec {
  const TableSyncSpec({required this.tabla, this.subida, required this.bajada});

  final String tabla;
  final PushSpec? subida;
  final PullSpec bajada;
}

DateTime? _fechaOpcional(dynamic v) =>
    v == null ? null : DateTime.parse(v as String);

/// Motor de sincronización entre la base local (Drift/SQLite) y Supabase.
///
/// Estrategia:
///  - SUBIR: envía al servidor las filas marcadas como `pendiente` (upsert) y
///    luego las marca como sincronizadas.
///  - BAJAR: trae del servidor las filas con `(updated_at, id)` mayor al
///    último marcador guardado ([SyncCursor]), y las guarda localmente.
///    Avanza el marcador.
///  - Conflictos: "gana el último que escribe" (el servidor fija `updated_at`).
///  - Borrados: viajan como `deleted_at` (borrado suave, "nada se borra").
///
/// Cada tabla es un [TableSyncSpec] en [_specs]; `_subirTabla`/`_bajarTabla`
/// son el único código de orquestación.
class SyncService {
  SyncService(this.db, {SyncRemoteGateway? remote})
    : _remote = remote ?? SupabaseSyncRemoteGateway();

  final AppDatabase db;
  final SyncRemoteGateway _remote;

  /// Para que la UI pueda mostrar un indicador de "sincronizando…".
  final ValueNotifier<bool> sincronizando = ValueNotifier(false);

  bool _enCurso = false;

  Future<void> sincronizar() async {
    if (!_remote.tieneUsuario) return; // sin sesión, nada que hacer
    if (_enCurso) return; // evitar solapamientos
    _enCurso = true;
    sincronizando.value = true;
    try {
      // Tiempo límite: si la red se cuelga (p. ej. se cae a mitad), no dejamos
      // el sync trabado para siempre; se cancela y se libera para reintentar.
      await _ejecutarSync().timeout(const Duration(seconds: 20));
    } catch (e) {
      // Si no hay internet o falla la red, reintentaremos en la próxima.
      debugPrint('Sync: no se pudo completar ($e)');
    } finally {
      _enCurso = false;
      sincronizando.value = false;
    }
  }

  Future<void> _ejecutarSync() async {
    // Cada paso va aislado: si uno falla (p. ej. un registro con conflicto),
    // los demás igual se ejecutan. Subir primero (para no pisar cambios
    // locales al bajar). Bajar después, en el orden de _specs (planes/
    // cuentas/usuarios antes que lecherías, que las necesita).
    for (final spec in _specs) {
      if (spec.subida != null) {
        await _paso(() => _subirTabla(spec));
      }
    }
    for (final spec in _specs) {
      await _paso(() => _bajarTabla(spec));
    }
  }

  /// Ejecuta un paso del sync de forma aislada: si lanza una excepción, la
  /// registra y sigue con los demás pasos (no aborta toda la sincronización).
  Future<void> _paso(Future<void> Function() accion) async {
    try {
      await accion();
    } catch (e) {
      debugPrint('Sync: un paso falló y se omite ($e)');
    }
  }

  // ------------------------------------------------------------- MOTOR

  Future<void> _subirTabla(TableSyncSpec spec) async {
    final subida = spec.subida;
    if (subida == null) return;
    final pendientes = await subida.pendientes();
    // Resiliencia POR FILA: si una falla (conflicto, red, RLS, etc.) se
    // registra y se sigue con las demás — nunca bloquea ni descarta al
    // resto. Cada fila se marca subida solo si tuvo éxito; si falla, queda
    // `pendiente` y se reintenta en la próxima sincronización.
    for (final (id, datos) in pendientes) {
      try {
        await _remote.insertarOActualizar(spec.tabla, id, datos);
        await subida.marcarSubida(id);
      } catch (e) {
        debugPrint(
          'Sync: no se pudo subir ${spec.tabla} $id; queda pendiente '
          'para reintentar ($e)',
        );
      }
    }
  }

  Future<void> _bajarTabla(TableSyncSpec spec) async {
    var cursorNuevo = SyncCursor.vacio;
    var retuvoCambioLocal = false;
    try {
      final cursorActual = await _leerCursor(spec.tabla);
      cursorNuevo = cursorActual;
      final filas = await _consultar(
        spec.tabla,
        cursorActual,
        idColumna: spec.bajada.idColumnaRemota,
      );
      for (final r in filas) {
        final id = spec.bajada.idDe(r);
        final guard = spec.bajada.tieneCambioLocalPendiente;
        // Las descargas nunca deben pisar cambios locales sin subir: si una
        // subida falló y luego baja una versión vieja del servidor, se
        // perdería el cambio local.
        if (guard != null && await guard(id)) {
          retuvoCambioLocal = true;
          continue;
        }
        await spec.bajada.aplicar(r);
        cursorNuevo = SyncCursor(
          updatedAt: DateTime.parse(r['updated_at'] as String),
          id: id,
        );
      }
      if (!retuvoCambioLocal && !cursorNuevo.esVacio) {
        await _guardarCursor(spec.tabla, cursorNuevo);
      }
      await _registrarExito(spec.tabla);
    } catch (e) {
      await _registrarError(spec.tabla, e);
      rethrow; // _paso() lo registra y sigue con la próxima tabla.
    }
  }

  TableSyncSpec? _specPara(String tabla) {
    for (final spec in _specs) {
      if (spec.tabla == tabla) return spec;
    }
    return null;
  }

  /// Indica si una fila local todavía tiene cambios sin subir. Expuesto para
  /// tests; delega en el guard del spec de esa tabla (null = sin guard).
  @visibleForTesting
  Future<bool> tieneCambiosLocalesPendientes(String tabla, String id) async {
    final guard = _specPara(tabla)?.bajada.tieneCambioLocalPendiente;
    if (guard == null) return false;
    return guard(id);
  }

  /// Estado de sync por tabla: para una pantalla de "sincronizando…" con
  /// detalle, o para soporte/debug.
  Future<List<SyncEstadoRow>> estadoPorTabla() =>
      db.select(db.syncEstados).get();

  /// Cantidad de filas `pendiente=true` por tabla (solo las que suben algo).
  Future<Map<String, int>> pendientesPorTabla() async {
    final resultado = <String, int>{};
    for (final spec in _specs) {
      final subida = spec.subida;
      if (subida == null) continue;
      resultado[spec.tabla] = (await subida.pendientes()).length;
    }
    return resultado;
  }

  Future<void> _registrarExito(String tabla) async {
    await db
        .into(db.syncEstados)
        .insertOnConflictUpdate(
          SyncEstadosCompanion.insert(
            tabla: tabla,
            ultimaSincronizacionOk: Value(DateTime.now()),
            ultimoError: const Value(null),
            ultimoErrorEn: const Value(null),
          ),
        );
  }

  Future<void> _registrarError(String tabla, Object error) async {
    await db
        .into(db.syncEstados)
        .insertOnConflictUpdate(
          SyncEstadosCompanion.insert(
            tabla: tabla,
            ultimoError: Value(error.toString()),
            ultimoErrorEn: Value(DateTime.now()),
          ),
        );
  }

  // -------------------------------------------------------------- MARCADORES

  Future<SyncCursor> _leerCursor(String tabla) async {
    final row = await (db.select(
      db.syncCursores,
    )..where((t) => t.tabla.equals(tabla))).getSingleOrNull();
    if (row == null || row.ultimaBajada == null) return SyncCursor.vacio;
    return SyncCursor(updatedAt: row.ultimaBajada, id: row.ultimaBajadaId);
  }

  Future<void> _guardarCursor(String tabla, SyncCursor cursor) async {
    await db
        .into(db.syncCursores)
        .insertOnConflictUpdate(
          SyncCursorRow(
            tabla: tabla,
            ultimaBajada: cursor.updatedAt,
            ultimaBajadaId: cursor.id,
          ),
        );
  }

  Future<List<Map<String, dynamic>>> _consultar(
    String tabla,
    SyncCursor cursor, {
    String idColumna = 'id',
  }) {
    return _remote.consultar(tabla, cursor, idColumna: idColumna);
  }

  // --------------------------------------------------------------- SPECS
  //
  // Orden: primero las tablas de solo bajada que no dependen de nada
  // (planes, cuentas, usuarios), luego lecherías y todo lo que depende de
  // ella. El bucle de SUBIR filtra las que tienen `subida`.

  List<TableSyncSpec> get _specs => [
    _planesSpec,
    _cuentasSpec,
    _usuariosSpec,
    _lecheriasSpec,
    _lecheriaMiembrosSpec,
    _animalesSpec,
    _eventosAnimalSpec,
    _pesasSesionesSpec,
    _pesasLecheSpec,
    _parametrosPeriodoSpec,
    _costosFijosSpec,
    _medicamentosSpec,
    _configAlertasSpec,
  ];

  /// Catálogo de licencias (solo lectura). No usa borrado suave ni `pendiente`.
  TableSyncSpec get _planesSpec => TableSyncSpec(
    tabla: 'planes',
    bajada: PullSpec(
      idDe: (r) => r['codigo'] as String,
      idColumnaRemota: 'codigo',
      aplicar: (r) => db
          .into(db.planes)
          .insertOnConflictUpdate(
            PlanRow(
              codigo: r['codigo'] as String,
              nombre: r['nombre'] as String,
              limiteLecherias: r['limite_lecherias'] as int,
              updatedAt: DateTime.parse(r['updated_at'] as String),
            ),
          ),
    ),
  );

  TableSyncSpec get _cuentasSpec => TableSyncSpec(
    tabla: 'cuentas',
    bajada: PullSpec(
      tieneCambioLocalPendiente: (id) async {
        final fila = await (db.select(
          db.cuentas,
        )..where((t) => t.id.equals(id))).getSingleOrNull();
        return fila?.pendiente ?? false;
      },
      aplicar: (r) => db
          .into(db.cuentas)
          .insertOnConflictUpdate(
            CuentaRow(
              id: r['id'] as String,
              nombre: r['nombre'] as String,
              duenoId: r['dueno_id'] as String,
              plan: r['plan'] as String,
              estado: r['estado'] as String,
              pruebaTermina: _fechaOpcional(r['prueba_termina']),
              createdAt: DateTime.parse(r['created_at'] as String),
              updatedAt: DateTime.parse(r['updated_at'] as String),
              deletedAt: _fechaOpcional(r['deleted_at']),
              pendiente: false,
            ),
          ),
    ),
  );

  /// Perfiles de usuario (el propio + compañeros de lechería). Trae
  /// `cuenta_id`, necesario para saber la cuenta del usuario actual.
  TableSyncSpec get _usuariosSpec => TableSyncSpec(
    tabla: 'usuarios',
    bajada: PullSpec(
      tieneCambioLocalPendiente: (id) async {
        final fila = await (db.select(
          db.usuarios,
        )..where((t) => t.id.equals(id))).getSingleOrNull();
        return fila?.pendiente ?? false;
      },
      aplicar: (r) => db
          .into(db.usuarios)
          .insertOnConflictUpdate(
            UsuarioRow(
              id: r['id'] as String,
              nombre: r['nombre'] as String?,
              email: r['email'] as String?,
              cuentaId: r['cuenta_id'] as String?,
              createdAt: DateTime.parse(r['created_at'] as String),
              updatedAt: DateTime.parse(r['updated_at'] as String),
              pendiente: false,
            ),
          ),
    ),
  );

  TableSyncSpec get _lecheriasSpec => TableSyncSpec(
    tabla: 'lecherias',
    subida: PushSpec(
      pendientes: () async {
        final filas = await (db.select(
          db.lecherias,
        )..where((t) => t.pendiente.equals(true))).get();
        return [
          for (final f in filas)
            (
              f.id,
              {
                'id': f.id,
                'nombre': f.nombre,
                'creada_por': f.creadaPor,
                'cuenta_id': f.cuentaId,
                'created_at': f.createdAt.toIso8601String(),
                'deleted_at': f.deletedAt?.toIso8601String(),
              },
            ),
        ];
      },
      marcarSubida: (id) =>
          (db.update(db.lecherias)..where((t) => t.id.equals(id))).write(
            const LecheriasCompanion(pendiente: Value(false)),
          ),
    ),
    bajada: PullSpec(
      tieneCambioLocalPendiente: (id) async {
        final fila = await (db.select(
          db.lecherias,
        )..where((t) => t.id.equals(id))).getSingleOrNull();
        return fila?.pendiente ?? false;
      },
      aplicar: (r) => db
          .into(db.lecherias)
          .insertOnConflictUpdate(
            LecheriaRow(
              id: r['id'] as String,
              nombre: r['nombre'] as String,
              creadaPor: r['creada_por'] as String,
              cuentaId: r['cuenta_id'] as String?,
              createdAt: DateTime.parse(r['created_at'] as String),
              updatedAt: DateTime.parse(r['updated_at'] as String),
              deletedAt: _fechaOpcional(r['deleted_at']),
              pendiente: false,
            ),
          ),
    ),
  );

  TableSyncSpec get _lecheriaMiembrosSpec => TableSyncSpec(
    tabla: 'lecheria_miembros',
    subida: PushSpec(
      pendientes: () async {
        final filas = await (db.select(
          db.lecheriaMiembros,
        )..where((t) => t.pendiente.equals(true))).get();
        return [
          for (final m in filas)
            (
              m.id,
              {
                'id': m.id,
                'lecheria_id': m.lecheriaId,
                'usuario_id': m.usuarioId,
                'rol': m.rol,
                'created_at': m.createdAt.toIso8601String(),
                'deleted_at': m.deletedAt?.toIso8601String(),
              },
            ),
        ];
      },
      marcarSubida: (id) =>
          (db.update(db.lecheriaMiembros)..where((t) => t.id.equals(id))).write(
            const LecheriaMiembrosCompanion(pendiente: Value(false)),
          ),
    ),
    bajada: PullSpec(
      tieneCambioLocalPendiente: (id) async {
        final fila = await (db.select(
          db.lecheriaMiembros,
        )..where((t) => t.id.equals(id))).getSingleOrNull();
        return fila?.pendiente ?? false;
      },
      aplicar: (r) => db
          .into(db.lecheriaMiembros)
          .insertOnConflictUpdate(
            LecheriaMiembroRow(
              id: r['id'] as String,
              lecheriaId: r['lecheria_id'] as String,
              usuarioId: r['usuario_id'] as String,
              rol: r['rol'] as String,
              createdAt: DateTime.parse(r['created_at'] as String),
              updatedAt: DateTime.parse(r['updated_at'] as String),
              deletedAt: _fechaOpcional(r['deleted_at']),
              pendiente: false,
            ),
          ),
    ),
  );

  TableSyncSpec get _animalesSpec => TableSyncSpec(
    tabla: 'animales',
    subida: PushSpec(
      pendientes: () async {
        final filas = await (db.select(
          db.animales,
        )..where((t) => t.pendiente.equals(true))).get();
        return [
          for (final a in filas)
            (
              a.id,
              {
                'id': a.id,
                'lecheria_id': a.lecheriaId,
                'identificador': a.identificador,
                'sexo': a.sexo,
                'grupo': a.grupo,
                'estado': a.estado,
                'estado_reproductivo': a.estadoReproductivo,
                'origen': a.origen,
                'precio_compra': a.precioCompra,
                'fecha_compra': a.fechaCompra?.toIso8601String(),
                'madre_id': a.madreId,
                'concentrado_kg_dia': a.concentradoKgDia,
                'fecha_probable_parto': a.fechaProbableParto?.toIso8601String(),
                'retiro_leche_hasta': a.retiroLecheHasta?.toIso8601String(),
                'created_at': a.createdAt.toIso8601String(),
                'deleted_at': a.deletedAt?.toIso8601String(),
              },
            ),
        ];
      },
      marcarSubida: (id) =>
          (db.update(db.animales)..where((t) => t.id.equals(id))).write(
            const AnimalesCompanion(pendiente: Value(false)),
          ),
    ),
    bajada: PullSpec(
      tieneCambioLocalPendiente: (id) async {
        final fila = await (db.select(
          db.animales,
        )..where((t) => t.id.equals(id))).getSingleOrNull();
        return fila?.pendiente ?? false;
      },
      aplicar: (r) => db
          .into(db.animales)
          .insertOnConflictUpdate(
            AnimalRow(
              id: r['id'] as String,
              lecheriaId: r['lecheria_id'] as String,
              identificador: r['identificador'] as String,
              sexo: r['sexo'] as String,
              grupo: r['grupo'] as String,
              estado: r['estado'] as String? ?? 'activo',
              estadoReproductivo:
                  r['estado_reproductivo'] as String? ?? 'desconocido',
              origen: r['origen'] as String,
              precioCompra: (r['precio_compra'] as num?)?.toDouble(),
              fechaCompra: _fechaOpcional(r['fecha_compra']),
              madreId: r['madre_id'] as String?,
              concentradoKgDia:
                  (r['concentrado_kg_dia'] as num?)?.toDouble() ?? 0,
              fechaProbableParto: _fechaOpcional(r['fecha_probable_parto']),
              retiroLecheHasta: _fechaOpcional(r['retiro_leche_hasta']),
              createdAt: DateTime.parse(r['created_at'] as String),
              updatedAt: DateTime.parse(r['updated_at'] as String),
              deletedAt: _fechaOpcional(r['deleted_at']),
              pendiente: false,
            ),
          ),
    ),
  );

  TableSyncSpec get _eventosAnimalSpec => TableSyncSpec(
    tabla: 'eventos_animal',
    subida: PushSpec(
      pendientes: () async {
        final filas = await (db.select(
          db.eventosAnimal,
        )..where((t) => t.pendiente.equals(true))).get();
        return [
          for (final e in filas)
            (
              e.id,
              {
                'id': e.id,
                'animal_id': e.animalId,
                'lecheria_id': e.lecheriaId,
                'tipo': e.tipo,
                'fecha': e.fecha.toIso8601String(),
                'detalle': e.detalle,
                'medicamento_id': e.medicamentoId,
                'dosis': e.dosis,
                'dias_retiro': e.diasRetiro,
                'costo': e.costo,
                'resultado': e.resultado,
                'toro_pajilla': e.toroPajilla,
                'sexo_cria': e.sexoCria,
                'grupo_anterior': e.grupoAnterior,
                'grupo_nuevo': e.grupoNuevo,
                'motivo_baja': e.motivoBaja,
                'precio_venta': e.precioVenta,
                'cria_animal_id': e.criaAnimalId,
                'registrado_por': e.registradoPor,
                'created_at': e.createdAt.toIso8601String(),
                'deleted_at': e.deletedAt?.toIso8601String(),
              },
            ),
        ];
      },
      marcarSubida: (id) =>
          (db.update(db.eventosAnimal)..where((t) => t.id.equals(id))).write(
            const EventosAnimalCompanion(pendiente: Value(false)),
          ),
    ),
    bajada: PullSpec(
      tieneCambioLocalPendiente: (id) async {
        final fila = await (db.select(
          db.eventosAnimal,
        )..where((t) => t.id.equals(id))).getSingleOrNull();
        return fila?.pendiente ?? false;
      },
      aplicar: (r) => db
          .into(db.eventosAnimal)
          .insertOnConflictUpdate(
            EventoAnimalRow(
              id: r['id'] as String,
              animalId: r['animal_id'] as String,
              lecheriaId: r['lecheria_id'] as String,
              tipo: r['tipo'] as String,
              fecha: DateTime.parse(r['fecha'] as String),
              detalle: r['detalle'] as String?,
              medicamentoId: r['medicamento_id'] as String?,
              dosis: r['dosis'] as String?,
              diasRetiro: r['dias_retiro'] as int?,
              costo: (r['costo'] as num?)?.toDouble(),
              resultado: r['resultado'] as String?,
              toroPajilla: r['toro_pajilla'] as String?,
              sexoCria: r['sexo_cria'] as String?,
              grupoAnterior: r['grupo_anterior'] as String?,
              grupoNuevo: r['grupo_nuevo'] as String?,
              motivoBaja: r['motivo_baja'] as String?,
              precioVenta: (r['precio_venta'] as num?)?.toDouble(),
              criaAnimalId: r['cria_animal_id'] as String?,
              registradoPor: r['registrado_por'] as String?,
              createdAt: DateTime.parse(r['created_at'] as String),
              updatedAt: DateTime.parse(r['updated_at'] as String),
              deletedAt: _fechaOpcional(r['deleted_at']),
              pendiente: false,
            ),
          ),
    ),
  );

  TableSyncSpec get _pesasSesionesSpec => TableSyncSpec(
    tabla: 'pesas_sesiones',
    subida: PushSpec(
      pendientes: () async {
        final filas = await (db.select(
          db.pesasSesiones,
        )..where((t) => t.pendiente.equals(true))).get();
        return [
          for (final s in filas)
            (
              s.id,
              {
                'id': s.id,
                'lecheria_id': s.lecheriaId,
                'fecha': s.fecha.toIso8601String(),
                'cerrada': s.cerrada,
                'created_at': s.createdAt.toIso8601String(),
                'deleted_at': s.deletedAt?.toIso8601String(),
              },
            ),
        ];
      },
      marcarSubida: (id) =>
          (db.update(db.pesasSesiones)..where((t) => t.id.equals(id))).write(
            const PesasSesionesCompanion(pendiente: Value(false)),
          ),
    ),
    bajada: PullSpec(
      tieneCambioLocalPendiente: (id) async {
        final fila = await (db.select(
          db.pesasSesiones,
        )..where((t) => t.id.equals(id))).getSingleOrNull();
        return fila?.pendiente ?? false;
      },
      aplicar: (r) => db
          .into(db.pesasSesiones)
          .insertOnConflictUpdate(
            PesaSesionRow(
              id: r['id'] as String,
              lecheriaId: r['lecheria_id'] as String,
              fecha: DateTime.parse(r['fecha'] as String),
              cerrada: r['cerrada'] as bool? ?? false,
              createdAt: DateTime.parse(r['created_at'] as String),
              updatedAt: DateTime.parse(r['updated_at'] as String),
              deletedAt: _fechaOpcional(r['deleted_at']),
              pendiente: false,
            ),
          ),
    ),
  );

  TableSyncSpec get _pesasLecheSpec => TableSyncSpec(
    tabla: 'pesas_leche',
    subida: PushSpec(
      pendientes: () async {
        final filas = await (db.select(
          db.pesasLeche,
        )..where((t) => t.pendiente.equals(true))).get();
        return [
          for (final p in filas)
            (
              p.id,
              {
                'id': p.id,
                'sesion_id': p.sesionId,
                'animal_id': p.animalId,
                'litros': p.litros,
                'created_at': p.createdAt.toIso8601String(),
                'deleted_at': p.deletedAt?.toIso8601String(),
              },
            ),
        ];
      },
      marcarSubida: (id) =>
          (db.update(db.pesasLeche)..where((t) => t.id.equals(id))).write(
            const PesasLecheCompanion(pendiente: Value(false)),
          ),
    ),
    bajada: PullSpec(
      tieneCambioLocalPendiente: (id) async {
        final fila = await (db.select(
          db.pesasLeche,
        )..where((t) => t.id.equals(id))).getSingleOrNull();
        return fila?.pendiente ?? false;
      },
      aplicar: (r) => db
          .into(db.pesasLeche)
          .insertOnConflictUpdate(
            PesaLecheRow(
              id: r['id'] as String,
              sesionId: r['sesion_id'] as String,
              animalId: r['animal_id'] as String,
              litros: (r['litros'] as num).toDouble(),
              createdAt: DateTime.parse(r['created_at'] as String),
              updatedAt: DateTime.parse(r['updated_at'] as String),
              deletedAt: _fechaOpcional(r['deleted_at']),
              pendiente: false,
            ),
          ),
    ),
  );

  TableSyncSpec get _parametrosPeriodoSpec => TableSyncSpec(
    tabla: 'parametros_periodo',
    subida: PushSpec(
      pendientes: () async {
        final filas = await (db.select(
          db.parametrosPeriodo,
        )..where((t) => t.pendiente.equals(true))).get();
        return [
          for (final p in filas)
            (
              p.id,
              {
                'id': p.id,
                'lecheria_id': p.lecheriaId,
                'anio': p.anio,
                'mes': p.mes,
                'precio_litro': p.precioLitro,
                'precio_concentrado_kg': p.precioConcentradoKg,
                'umbral_secado_litros': p.umbralSecadoLitros,
                'created_at': p.createdAt.toIso8601String(),
                'deleted_at': p.deletedAt?.toIso8601String(),
              },
            ),
        ];
      },
      marcarSubida: (id) =>
          (db.update(db.parametrosPeriodo)..where((t) => t.id.equals(id)))
              .write(const ParametrosPeriodoCompanion(pendiente: Value(false))),
    ),
    bajada: PullSpec(
      tieneCambioLocalPendiente: (id) async {
        final fila = await (db.select(
          db.parametrosPeriodo,
        )..where((t) => t.id.equals(id))).getSingleOrNull();
        return fila?.pendiente ?? false;
      },
      aplicar: (r) => db
          .into(db.parametrosPeriodo)
          .insertOnConflictUpdate(
            ParametrosPeriodoRow(
              id: r['id'] as String,
              lecheriaId: r['lecheria_id'] as String,
              anio: r['anio'] as int,
              mes: r['mes'] as int,
              precioLitro: (r['precio_litro'] as num).toDouble(),
              precioConcentradoKg: (r['precio_concentrado_kg'] as num)
                  .toDouble(),
              umbralSecadoLitros:
                  (r['umbral_secado_litros'] as num?)?.toDouble() ?? 8,
              createdAt: DateTime.parse(r['created_at'] as String),
              updatedAt: DateTime.parse(r['updated_at'] as String),
              deletedAt: _fechaOpcional(r['deleted_at']),
              pendiente: false,
            ),
          ),
    ),
  );

  TableSyncSpec get _costosFijosSpec => TableSyncSpec(
    tabla: 'costos_fijos',
    subida: PushSpec(
      pendientes: () async {
        final filas = await (db.select(
          db.costosFijos,
        )..where((t) => t.pendiente.equals(true))).get();
        return [
          for (final c in filas)
            (
              c.id,
              {
                'id': c.id,
                'lecheria_id': c.lecheriaId,
                'periodo_id': c.periodoId,
                'categoria': c.categoria,
                'monto': c.monto,
                'created_at': c.createdAt.toIso8601String(),
                'deleted_at': c.deletedAt?.toIso8601String(),
              },
            ),
        ];
      },
      marcarSubida: (id) =>
          (db.update(db.costosFijos)..where((t) => t.id.equals(id))).write(
            const CostosFijosCompanion(pendiente: Value(false)),
          ),
    ),
    bajada: PullSpec(
      tieneCambioLocalPendiente: (id) async {
        final fila = await (db.select(
          db.costosFijos,
        )..where((t) => t.id.equals(id))).getSingleOrNull();
        return fila?.pendiente ?? false;
      },
      aplicar: (r) => db
          .into(db.costosFijos)
          .insertOnConflictUpdate(
            CostoFijoRow(
              id: r['id'] as String,
              lecheriaId: r['lecheria_id'] as String,
              periodoId: r['periodo_id'] as String,
              categoria: r['categoria'] as String,
              monto: (r['monto'] as num).toDouble(),
              createdAt: DateTime.parse(r['created_at'] as String),
              updatedAt: DateTime.parse(r['updated_at'] as String),
              deletedAt: _fechaOpcional(r['deleted_at']),
              pendiente: false,
            ),
          ),
    ),
  );

  TableSyncSpec get _medicamentosSpec => TableSyncSpec(
    tabla: 'medicamentos',
    subida: PushSpec(
      pendientes: () async {
        final filas = await (db.select(
          db.medicamentos,
        )..where((t) => t.pendiente.equals(true))).get();
        return [
          for (final m in filas)
            (
              m.id,
              {
                'id': m.id,
                'lecheria_id': m.lecheriaId,
                'nombre': m.nombre,
                'costo_envase': m.costoEnvase,
                'tipo_dosis': m.tipoDosis,
                'ml_envase': m.mlEnvase,
                'aplicaciones_envase': m.aplicacionesEnvase,
                'dosis_fija_ml': m.dosisFijaMl,
                'dias_retiro_leche': m.diasRetiroLeche,
                'created_at': m.createdAt.toIso8601String(),
                'deleted_at': m.deletedAt?.toIso8601String(),
              },
            ),
        ];
      },
      marcarSubida: (id) =>
          (db.update(db.medicamentos)..where((t) => t.id.equals(id))).write(
            const MedicamentosCompanion(pendiente: Value(false)),
          ),
    ),
    bajada: PullSpec(
      tieneCambioLocalPendiente: (id) async {
        final fila = await (db.select(
          db.medicamentos,
        )..where((t) => t.id.equals(id))).getSingleOrNull();
        return fila?.pendiente ?? false;
      },
      aplicar: (r) => db
          .into(db.medicamentos)
          .insertOnConflictUpdate(
            MedicamentoRow(
              id: r['id'] as String,
              lecheriaId: r['lecheria_id'] as String,
              nombre: r['nombre'] as String,
              costoEnvase: (r['costo_envase'] as num).toDouble(),
              tipoDosis: r['tipo_dosis'] as String,
              mlEnvase: (r['ml_envase'] as num?)?.toDouble(),
              aplicacionesEnvase: (r['aplicaciones_envase'] as num?)
                  ?.toDouble(),
              dosisFijaMl: (r['dosis_fija_ml'] as num?)?.toDouble(),
              diasRetiroLeche: r['dias_retiro_leche'] as int? ?? 0,
              createdAt: DateTime.parse(r['created_at'] as String),
              updatedAt: DateTime.parse(r['updated_at'] as String),
              deletedAt: _fechaOpcional(r['deleted_at']),
              pendiente: false,
            ),
          ),
    ),
  );

  TableSyncSpec get _configAlertasSpec => TableSyncSpec(
    tabla: 'config_alertas',
    subida: PushSpec(
      pendientes: () async {
        final filas = await (db.select(
          db.configAlertas,
        )..where((t) => t.pendiente.equals(true))).get();
        return [
          for (final c in filas)
            (
              c.id,
              {
                'id': c.id,
                'lecheria_id': c.lecheriaId,
                'dias_celo_esperado': c.diasCeloEsperado,
                'dias_confirmar_preniez': c.diasConfirmarPreniez,
                'dias_vacios_altos': c.diasVaciosAltos,
                'dias_antes_secar': c.diasAntesSecar,
                'dias_antes_parto': c.diasAntesParto,
                'dias_aviso_fin_retiro': c.diasAvisoFinRetiro,
                'created_at': c.createdAt.toIso8601String(),
                'deleted_at': c.deletedAt?.toIso8601String(),
              },
            ),
        ];
      },
      marcarSubida: (id) =>
          (db.update(db.configAlertas)..where((t) => t.id.equals(id))).write(
            const ConfigAlertasCompanion(pendiente: Value(false)),
          ),
    ),
    bajada: PullSpec(
      tieneCambioLocalPendiente: (id) async {
        final fila = await (db.select(
          db.configAlertas,
        )..where((t) => t.id.equals(id))).getSingleOrNull();
        return fila?.pendiente ?? false;
      },
      aplicar: (r) => db
          .into(db.configAlertas)
          .insertOnConflictUpdate(
            ConfigAlertaRow(
              id: r['id'] as String,
              lecheriaId: r['lecheria_id'] as String,
              diasCeloEsperado: r['dias_celo_esperado'] as int? ?? 21,
              diasConfirmarPreniez: r['dias_confirmar_preniez'] as int? ?? 45,
              diasVaciosAltos: r['dias_vacios_altos'] as int? ?? 150,
              diasAntesSecar: r['dias_antes_secar'] as int? ?? 60,
              diasAntesParto: r['dias_antes_parto'] as int? ?? 14,
              diasAvisoFinRetiro: r['dias_aviso_fin_retiro'] as int? ?? 1,
              createdAt: DateTime.parse(r['created_at'] as String),
              updatedAt: DateTime.parse(r['updated_at'] as String),
              deletedAt: _fechaOpcional(r['deleted_at']),
              pendiente: false,
            ),
          ),
    ),
  );
}
