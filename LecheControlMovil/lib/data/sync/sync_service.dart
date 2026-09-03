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
/// motor genérico (`_subirFilasPendientes`/`_bajarTabla`) hace el resto igual
/// para todas.
class TableSyncSpec {
  const TableSyncSpec({required this.tabla, this.subida, required this.bajada});

  final String tabla;
  final PushSpec? subida;
  final PullSpec bajada;
}

DateTime? _fechaOpcional(dynamic v) =>
    v == null ? null : DateTime.parse(v as String);

/// `YYYY-MM-DD` para las columnas `date` de Postgres (`semanas`), que no
/// llevan hora.
String _soloFecha(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Cuánto va subido de la sincronización en curso, para que la app pueda
/// decir "subiendo 12 de 210" en vez de un giro sin fin.
class SyncProgreso {
  const SyncProgreso({required this.hechas, required this.total});

  static const inactivo = SyncProgreso(hechas: 0, total: 0);

  final int hechas;
  final int total;

  bool get activo => total > 0;
}

/// Cuánto se movió una vuelta de subida: filas que lograron subir y filas que
/// quedaron pendientes.
///
/// Es lo que decide si vale la pena insistir: si algo subió, la red está viva
/// y se sigue de una; si no subió nada, hay que esperar antes de reintentar.
class ResultadoSubida {
  const ResultadoSubida({required this.subidas, required this.pendientes});

  static const nada = ResultadoSubida(subidas: 0, pendientes: 0);

  final int subidas;
  final int pendientes;
}

/// Motor de sincronización entre la base local (Drift/SQLite) y Supabase.
///
/// Estrategia:
///  - SUBIR: envía al servidor las filas marcadas como `pendiente` (upsert) y
///    luego las marca como sincronizadas. Insiste hasta que no quede ninguna.
///  - BAJAR: trae del servidor las filas con `(updated_at, id)` mayor al
///    último marcador guardado ([SyncCursor]), y las guarda localmente.
///    Avanza el marcador.
///  - Conflictos: "gana el último que escribe" (el servidor fija `updated_at`).
///  - Borrados: viajan como `deleted_at` (borrado suave, "nada se borra").
///
/// **El usuario nunca aprieta nada**: se sincroniza al arrancar, al guardar,
/// al recuperar la conexión y cada tanto si quedó algo pendiente (ver
/// `app_bootstrap.dart`).
///
/// Cada tabla es un [TableSyncSpec] en [_specs]; `_subirFilasPendientes` y
/// `_bajarTabla` son el único código de orquestación.
class SyncService {
  SyncService(
    this.db, {
    SyncRemoteGateway? remote,
    List<Duration>? esperasReintento,
  }) : _remote = remote ?? SupabaseSyncRemoteGateway(),
       _esperasReintento = esperasReintento ?? esperasReintentoPorDefecto;

  final AppDatabase db;
  final SyncRemoteGateway _remote;

  /// Cuánto esperar antes de cada reintento, cuando una vuelta de subida no
  /// logró subir ni una fila. Se agotan y el resto queda pendiente para el
  /// próximo intento: si la red está caída de verdad, insistir para siempre
  /// solo gasta batería. Los tests las ponen en `[]` para no dormir.
  static const esperasReintentoPorDefecto = [
    Duration(seconds: 2),
    Duration(seconds: 5),
    Duration(seconds: 15),
  ];

  final List<Duration> _esperasReintento;

  /// Para que la UI pueda mostrar un indicador de "sincronizando…".
  final ValueNotifier<bool> sincronizando = ValueNotifier(false);

  /// Avance de la subida en curso (ver [SyncProgreso]).
  final ValueNotifier<SyncProgreso> progreso = ValueNotifier(
    SyncProgreso.inactivo,
  );

  bool _enCurso = false;

  /// Llegó otro pedido mientras se sincronizaba: al terminar se da otra
  /// vuelta en vez de perderlo.
  bool _pedidoDeNuevo = false;

  /// Sincroniza **todo**, de una, sin que el usuario apriete nada.
  ///
  /// No hay tiempo límite global a propósito. Antes había uno de 20 s para
  /// toda la sincronización y con muchos registros —un día entero de campo—
  /// se cortaba a la mitad: subía un pedazo, dejaba el resto pendiente y
  /// había que insistir. El límite ahora es **por petición**, dentro del
  /// gateway: una conexión colgada se corta sola, pero una lenta pero viva
  /// termina el trabajo.
  Future<void> sincronizar() async {
    if (!_remote.tieneUsuario) return; // sin sesión, nada que hacer
    if (_enCurso) {
      // El pedido no se descarta: al terminar la vuelta actual se da otra,
      // así lo que se guardó **mientras** se subía también sale. Antes esto
      // era un `return` seco y esos cambios se quedaban esperando el próximo
      // disparo.
      _pedidoDeNuevo = true;
      return;
    }
    _enCurso = true;
    sincronizando.value = true;
    try {
      do {
        _pedidoDeNuevo = false;
        await _ejecutarSync();
      } while (_pedidoDeNuevo);
    } catch (e) {
      // Si no hay internet o falla la red, reintentaremos en la próxima.
      debugPrint('Sync: no se pudo completar ($e)');
    } finally {
      _enCurso = false;
      sincronizando.value = false;
      progreso.value = SyncProgreso.inactivo;
    }
  }

  /// Una sincronización completa: SUBIR todo lo pendiente —insistiendo hasta
  /// que no quede nada— y después BAJAR los cambios del servidor.
  Future<void> _ejecutarSync() async {
    var vueltasSinProgreso = 0;
    while (true) {
      final resultado = await _subirFilasPendientes();
      if (resultado.pendientes == 0) break; // subió todo
      if (resultado.subidas > 0) {
        // Hubo avance, la red responde: seguimos de una, sin esperar.
        vueltasSinProgreso = 0;
        continue;
      }
      // Ni una fila pasó: probablemente la red se cayó otra vez. Se espera y
      // se reintenta; si no hay caso, queda pendiente para la próxima (no se
      // pierde nada, las filas siguen marcadas `pendiente`).
      if (vueltasSinProgreso >= _esperasReintento.length) break;
      await Future.delayed(_esperasReintento[vueltasSinProgreso]);
      vueltasSinProgreso++;
    }

    // Bajar al final, en el orden de _specs (planes/cuentas/usuarios antes
    // que lecherías, que las necesita). Cada paso va aislado: si uno falla,
    // los demás igual se ejecutan.
    for (final spec in _specs) {
      await _paso(() => _bajarTabla(spec));
    }
  }

  /// Una vuelta de subida: manda **todas** las filas pendientes de todas las
  /// tablas y dice cuántas pasaron y cuántas quedaron.
  ///
  /// Se juntan primero para poder decir "subiendo 12 de 210" mientras avanza:
  /// sin el total, el usuario no tiene forma de saber si falta mucho.
  Future<ResultadoSubida> _subirFilasPendientes() async {
    final porTabla = <String, List<(String, Map<String, dynamic>)>>{};
    for (final spec in _specs) {
      final subida = spec.subida;
      if (subida == null) continue;
      await _paso(() async {
        porTabla[spec.tabla] = await subida.pendientes();
      });
    }
    final total = porTabla.values.fold<int>(0, (n, filas) => n + filas.length);
    if (total == 0) {
      progreso.value = SyncProgreso.inactivo;
      return ResultadoSubida.nada;
    }

    var subidas = 0;
    var pendientes = 0;
    var hechas = 0;
    progreso.value = SyncProgreso(hechas: 0, total: total);

    for (final spec in _specs) {
      final filas = porTabla[spec.tabla];
      final subida = spec.subida;
      if (subida == null || filas == null || filas.isEmpty) continue;
      // Resiliencia POR FILA: si una falla (conflicto, red, RLS, etc.) se
      // registra y se sigue con las demás — nunca bloquea ni descarta al
      // resto. Cada fila se marca subida solo si tuvo éxito; si falla, queda
      // `pendiente` y se reintenta en la vuelta siguiente.
      for (final (id, datos) in filas) {
        try {
          await _remote.insertarOActualizar(spec.tabla, id, datos);
          await subida.marcarSubida(id);
          subidas++;
        } catch (e) {
          pendientes++;
          debugPrint(
            'Sync: no se pudo subir ${spec.tabla} $id; queda pendiente '
            'para reintentar ($e)',
          );
        }
        hechas++;
        progreso.value = SyncProgreso(hechas: hechas, total: total);
      }
    }
    return ResultadoSubida(subidas: subidas, pendientes: pendientes);
  }

  /// Si quedó algo sin subir. Lo usa el reintento automático para no
  /// despertar la red cuando no hay nada que mandar.
  Future<bool> hayPendientes() async {
    for (final spec in _specs) {
      final subida = spec.subida;
      if (subida == null) continue;
      if ((await subida.pendientes()).isNotEmpty) return true;
    }
    return false;
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
    _curvaReferenciaSpec,
    _configReporteSpec,
    _semanasSpec,
    _ingresosSemanaSpec,
    _gastosSemanaSpec,
    _calidadLecheSpec,
    _categoriasGastoSpec,
    _medicamentosSpec,
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
                'fecha_probable_parto': a.fechaProbableParto?.toIso8601String(),
                'retiro_leche_hasta': a.retiroLecheHasta?.toIso8601String(),
                'fecha_ultimo_parto': a.fechaUltimoParto?.toIso8601String(),
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
              fechaProbableParto: _fechaOpcional(r['fecha_probable_parto']),
              retiroLecheHasta: _fechaOpcional(r['retiro_leche_hasta']),
              fechaUltimoParto: _fechaOpcional(r['fecha_ultimo_parto']),
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
                'identificador_manual': p.identificadorManual,
                'litros': p.litros,
                'litros_manana': p.litrosManana,
                'litros_tarde': p.litrosTarde,
                'concentrado_kg': p.concentradoKg,
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
              animalId: r['animal_id'] as String?,
              identificadorManual: r['identificador_manual'] as String?,
              litros: (r['litros'] as num).toDouble(),
              litrosManana: (r['litros_manana'] as num?)?.toDouble(),
              litrosTarde: (r['litros_tarde'] as num?)?.toDouble(),
              concentradoKg: (r['concentrado_kg'] as num?)?.toDouble(),
              createdAt: DateTime.parse(r['created_at'] as String),
              updatedAt: DateTime.parse(r['updated_at'] as String),
              deletedAt: _fechaOpcional(r['deleted_at']),
              pendiente: false,
            ),
          ),
    ),
  );

  TableSyncSpec get _curvaReferenciaSpec => TableSyncSpec(
    tabla: 'curva_referencia',
    subida: PushSpec(
      pendientes: () async {
        final filas = await (db.select(
          db.curvaReferencia,
        )..where((t) => t.pendiente.equals(true))).get();
        return [
          for (final c in filas)
            (
              c.id,
              {
                'id': c.id,
                'lecheria_id': c.lecheriaId,
                'orden': c.orden,
                'dia_desde': c.diaDesde,
                'dia_hasta': c.diaHasta,
                'litros_esperados': c.litrosEsperados,
                'created_at': c.createdAt.toIso8601String(),
                'deleted_at': c.deletedAt?.toIso8601String(),
              },
            ),
        ];
      },
      marcarSubida: (id) =>
          (db.update(db.curvaReferencia)..where((t) => t.id.equals(id))).write(
            const CurvaReferenciaCompanion(pendiente: Value(false)),
          ),
    ),
    bajada: PullSpec(
      tieneCambioLocalPendiente: (id) async {
        final fila = await (db.select(
          db.curvaReferencia,
        )..where((t) => t.id.equals(id))).getSingleOrNull();
        return fila?.pendiente ?? false;
      },
      aplicar: (r) => db
          .into(db.curvaReferencia)
          .insertOnConflictUpdate(
            CurvaReferenciaRow(
              id: r['id'] as String,
              lecheriaId: r['lecheria_id'] as String,
              orden: r['orden'] as int,
              diaDesde: r['dia_desde'] as int,
              diaHasta: r['dia_hasta'] as int?,
              litrosEsperados: (r['litros_esperados'] as num).toDouble(),
              createdAt: DateTime.parse(r['created_at'] as String),
              updatedAt: DateTime.parse(r['updated_at'] as String),
              deletedAt: _fechaOpcional(r['deleted_at']),
              pendiente: false,
            ),
          ),
    ),
  );

  TableSyncSpec get _configReporteSpec => TableSyncSpec(
    tabla: 'config_reporte',
    subida: PushSpec(
      pendientes: () async {
        final filas = await (db.select(
          db.configReporte,
        )..where((t) => t.pendiente.equals(true))).get();
        return [
          for (final c in filas)
            (
              c.id,
              {
                'id': c.id,
                'lecheria_id': c.lecheriaId,
                'pct_excelente': c.pctExcelente,
                'pct_bueno': c.pctBueno,
                'pct_vigilar': c.pctVigilar,
                'pct_bajo': c.pctBajo,
                'umbral_secado_litros': c.umbralSecadoLitros,
                'tope_kg_leche': c.topeKgLeche,
                'kg_leche_por_kg_concentrado': c.kgLechePorKgConcentrado,
                'created_at': c.createdAt.toIso8601String(),
                'deleted_at': c.deletedAt?.toIso8601String(),
              },
            ),
        ];
      },
      marcarSubida: (id) =>
          (db.update(db.configReporte)..where((t) => t.id.equals(id))).write(
            const ConfigReporteCompanion(pendiente: Value(false)),
          ),
    ),
    bajada: PullSpec(
      tieneCambioLocalPendiente: (id) async {
        final fila = await (db.select(
          db.configReporte,
        )..where((t) => t.id.equals(id))).getSingleOrNull();
        return fila?.pendiente ?? false;
      },
      aplicar: (r) => db
          .into(db.configReporte)
          .insertOnConflictUpdate(
            ConfigReporteRow(
              id: r['id'] as String,
              lecheriaId: r['lecheria_id'] as String,
              pctExcelente: (r['pct_excelente'] as num?)?.toDouble() ?? 100,
              pctBueno: (r['pct_bueno'] as num?)?.toDouble() ?? 85,
              pctVigilar: (r['pct_vigilar'] as num?)?.toDouble() ?? 70,
              pctBajo: (r['pct_bajo'] as num?)?.toDouble() ?? 60,
              umbralSecadoLitros:
                  (r['umbral_secado_litros'] as num?)?.toDouble() ?? 8,
              topeKgLeche: (r['tope_kg_leche'] as num?)?.toDouble(),
              kgLechePorKgConcentrado:
                  (r['kg_leche_por_kg_concentrado'] as num?)?.toDouble() ?? 3,
              createdAt: DateTime.parse(r['created_at'] as String),
              updatedAt: DateTime.parse(r['updated_at'] as String),
              deletedAt: _fechaOpcional(r['deleted_at']),
              pendiente: false,
            ),
          ),
    ),
  );

  TableSyncSpec get _semanasSpec => TableSyncSpec(
    tabla: 'semanas',
    subida: PushSpec(
      pendientes: () async {
        final filas = await (db.select(
          db.semanas,
        )..where((t) => t.pendiente.equals(true))).get();
        return [
          for (final s in filas)
            (
              s.id,
              {
                'id': s.id,
                'lecheria_id': s.lecheriaId,
                // Columnas `date` en Postgres: mandamos solo el día.
                'fecha_inicio': _soloFecha(s.fechaInicio),
                'fecha_fin': _soloFecha(s.fechaFin),
                'cerrada': s.cerrada,
                'created_at': s.createdAt.toIso8601String(),
                'deleted_at': s.deletedAt?.toIso8601String(),
              },
            ),
        ];
      },
      marcarSubida: (id) =>
          (db.update(db.semanas)..where((t) => t.id.equals(id))).write(
            const SemanasCompanion(pendiente: Value(false)),
          ),
    ),
    bajada: PullSpec(
      tieneCambioLocalPendiente: (id) async {
        final fila = await (db.select(
          db.semanas,
        )..where((t) => t.id.equals(id))).getSingleOrNull();
        return fila?.pendiente ?? false;
      },
      aplicar: (r) => db
          .into(db.semanas)
          .insertOnConflictUpdate(
            SemanaRow(
              id: r['id'] as String,
              lecheriaId: r['lecheria_id'] as String,
              fechaInicio: DateTime.parse(r['fecha_inicio'] as String),
              fechaFin: DateTime.parse(r['fecha_fin'] as String),
              cerrada: r['cerrada'] as bool? ?? false,
              createdAt: DateTime.parse(r['created_at'] as String),
              updatedAt: DateTime.parse(r['updated_at'] as String),
              deletedAt: _fechaOpcional(r['deleted_at']),
              pendiente: false,
            ),
          ),
    ),
  );

  TableSyncSpec get _ingresosSemanaSpec => TableSyncSpec(
    tabla: 'ingresos_semana',
    subida: PushSpec(
      pendientes: () async {
        final filas = await (db.select(
          db.ingresosSemana,
        )..where((t) => t.pendiente.equals(true))).get();
        return [
          for (final i in filas)
            (
              i.id,
              {
                'id': i.id,
                'lecheria_id': i.lecheriaId,
                'semana_id': i.semanaId,
                'tipo': i.tipo,
                'monto': i.monto,
                'litros': i.litros,
                'animal_id': i.animalId,
                'detalle': i.detalle,
                'created_at': i.createdAt.toIso8601String(),
                'deleted_at': i.deletedAt?.toIso8601String(),
              },
            ),
        ];
      },
      marcarSubida: (id) =>
          (db.update(db.ingresosSemana)..where((t) => t.id.equals(id))).write(
            const IngresosSemanaCompanion(pendiente: Value(false)),
          ),
    ),
    bajada: PullSpec(
      tieneCambioLocalPendiente: (id) async {
        final fila = await (db.select(
          db.ingresosSemana,
        )..where((t) => t.id.equals(id))).getSingleOrNull();
        return fila?.pendiente ?? false;
      },
      aplicar: (r) => db
          .into(db.ingresosSemana)
          .insertOnConflictUpdate(
            IngresoSemanaRow(
              id: r['id'] as String,
              lecheriaId: r['lecheria_id'] as String,
              semanaId: r['semana_id'] as String,
              tipo: r['tipo'] as String,
              monto: (r['monto'] as num).toDouble(),
              litros: (r['litros'] as num?)?.toDouble(),
              animalId: r['animal_id'] as String?,
              detalle: r['detalle'] as String?,
              createdAt: DateTime.parse(r['created_at'] as String),
              updatedAt: DateTime.parse(r['updated_at'] as String),
              deletedAt: _fechaOpcional(r['deleted_at']),
              pendiente: false,
            ),
          ),
    ),
  );

  TableSyncSpec get _gastosSemanaSpec => TableSyncSpec(
    tabla: 'gastos_semana',
    subida: PushSpec(
      pendientes: () async {
        final filas = await (db.select(
          db.gastosSemana,
        )..where((t) => t.pendiente.equals(true))).get();
        return [
          for (final g in filas)
            (
              g.id,
              {
                'id': g.id,
                'lecheria_id': g.lecheriaId,
                'semana_id': g.semanaId,
                'categoria': g.categoria,
                'monto': g.monto,
                'detalle': g.detalle,
                'created_at': g.createdAt.toIso8601String(),
                'deleted_at': g.deletedAt?.toIso8601String(),
              },
            ),
        ];
      },
      marcarSubida: (id) =>
          (db.update(db.gastosSemana)..where((t) => t.id.equals(id))).write(
            const GastosSemanaCompanion(pendiente: Value(false)),
          ),
    ),
    bajada: PullSpec(
      tieneCambioLocalPendiente: (id) async {
        final fila = await (db.select(
          db.gastosSemana,
        )..where((t) => t.id.equals(id))).getSingleOrNull();
        return fila?.pendiente ?? false;
      },
      aplicar: (r) => db
          .into(db.gastosSemana)
          .insertOnConflictUpdate(
            GastoSemanaRow(
              id: r['id'] as String,
              lecheriaId: r['lecheria_id'] as String,
              semanaId: r['semana_id'] as String,
              categoria: r['categoria'] as String,
              monto: (r['monto'] as num).toDouble(),
              detalle: r['detalle'] as String?,
              createdAt: DateTime.parse(r['created_at'] as String),
              updatedAt: DateTime.parse(r['updated_at'] as String),
              deletedAt: _fechaOpcional(r['deleted_at']),
              pendiente: false,
            ),
          ),
    ),
  );

  TableSyncSpec get _calidadLecheSpec => TableSyncSpec(
    tabla: 'calidad_leche',
    subida: PushSpec(
      pendientes: () async {
        final filas = await (db.select(
          db.calidadLeche,
        )..where((t) => t.pendiente.equals(true))).get();
        return [
          for (final c in filas)
            (
              c.id,
              {
                'id': c.id,
                'lecheria_id': c.lecheriaId,
                'semana_id': c.semanaId,
                'solidos_totales_pct': c.solidosTotalesPct,
                'celulas_somaticas': c.celulasSomaticas,
                'conteo_bacterial': c.conteoBacterial,
                'created_at': c.createdAt.toIso8601String(),
                'deleted_at': c.deletedAt?.toIso8601String(),
              },
            ),
        ];
      },
      marcarSubida: (id) =>
          (db.update(db.calidadLeche)..where((t) => t.id.equals(id))).write(
            const CalidadLecheCompanion(pendiente: Value(false)),
          ),
    ),
    bajada: PullSpec(
      tieneCambioLocalPendiente: (id) async {
        final fila = await (db.select(
          db.calidadLeche,
        )..where((t) => t.id.equals(id))).getSingleOrNull();
        return fila?.pendiente ?? false;
      },
      aplicar: (r) => db
          .into(db.calidadLeche)
          .insertOnConflictUpdate(
            CalidadLecheRow(
              id: r['id'] as String,
              lecheriaId: r['lecheria_id'] as String,
              semanaId: r['semana_id'] as String,
              solidosTotalesPct: (r['solidos_totales_pct'] as num?)?.toDouble(),
              celulasSomaticas: (r['celulas_somaticas'] as num?)?.toDouble(),
              conteoBacterial: (r['conteo_bacterial'] as num?)?.toDouble(),
              createdAt: DateTime.parse(r['created_at'] as String),
              updatedAt: DateTime.parse(r['updated_at'] as String),
              deletedAt: _fechaOpcional(r['deleted_at']),
              pendiente: false,
            ),
          ),
    ),
  );

  TableSyncSpec get _categoriasGastoSpec => TableSyncSpec(
    tabla: 'categorias_gasto',
    subida: PushSpec(
      pendientes: () async {
        final filas = await (db.select(
          db.categoriasGasto,
        )..where((t) => t.pendiente.equals(true))).get();
        return [
          for (final c in filas)
            (
              c.id,
              {
                'id': c.id,
                'lecheria_id': c.lecheriaId,
                'nombre': c.nombre,
                'orden': c.orden,
                'created_at': c.createdAt.toIso8601String(),
                'deleted_at': c.deletedAt?.toIso8601String(),
              },
            ),
        ];
      },
      marcarSubida: (id) =>
          (db.update(db.categoriasGasto)..where((t) => t.id.equals(id))).write(
            const CategoriasGastoCompanion(pendiente: Value(false)),
          ),
    ),
    bajada: PullSpec(
      tieneCambioLocalPendiente: (id) async {
        final fila = await (db.select(
          db.categoriasGasto,
        )..where((t) => t.id.equals(id))).getSingleOrNull();
        return fila?.pendiente ?? false;
      },
      aplicar: (r) => db
          .into(db.categoriasGasto)
          .insertOnConflictUpdate(
            CategoriaGastoRow(
              id: r['id'] as String,
              lecheriaId: r['lecheria_id'] as String,
              nombre: r['nombre'] as String,
              orden: r['orden'] as int? ?? 0,
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
                'dosis_aplicacion': m.dosisAplicacion,
                'ml_envase': m.mlEnvase,
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
              dosisAplicacion: r['dosis_aplicacion'] as String?,
              mlEnvase: (r['ml_envase'] as num?)?.toDouble(),
              createdAt: DateTime.parse(r['created_at'] as String),
              updatedAt: DateTime.parse(r['updated_at'] as String),
              deletedAt: _fechaOpcional(r['deleted_at']),
              pendiente: false,
            ),
          ),
    ),
  );
}
