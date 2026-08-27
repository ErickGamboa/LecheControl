import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../domain/curva_lactancia.dart';
import '../domain/dieta_concentrado.dart';
import '../local/database.dart';

/// La curva de referencia de lactancia y los umbrales del reporte de
/// producción (Módulo 3), guardados por lechería y editables por el ganadero.
///
/// **Sobre la siembra inicial:** los siete tramos se crean al dar de alta una
/// lechería nueva ([sembrarSiHaceFalta], que llama `LecheriasRepository`). Las
/// lecherías que ya existían recibieron sus tramos del lado del servidor, en
/// la migración `20260810120000_v2_pesa_semanal_y_finanzas.sql`, y llegan al
/// dispositivo por sync. A propósito NO se siembra a ciegas cada vez que se
/// abre el módulo: las filas locales tendrían ids distintos a los del
/// servidor y chocarían contra el índice único `(lecheria_id, dia_desde)` al
/// bajar.
class CurvaRepository {
  CurvaRepository(this.db);

  final AppDatabase db;
  final _uuid = const Uuid();

  /// Tramos de la lechería, ordenados. Vacío si todavía no se sembraron ni
  /// bajaron del servidor.
  Future<List<CurvaReferenciaRow>> tramosDe(String lecheriaId) {
    return (db.select(db.curvaReferencia)
          ..where((t) => t.lecheriaId.equals(lecheriaId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.diaDesde)]))
        .get();
  }

  Stream<List<CurvaReferenciaRow>> observarTramos(String lecheriaId) {
    return (db.select(db.curvaReferencia)
          ..where((t) => t.lecheriaId.equals(lecheriaId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.diaDesde)]))
        .watch();
  }

  /// La curva lista para consultar litros esperados. Si la lechería no tiene
  /// tramos, devuelve una curva vacía (`estaVacia`), no los valores por
  /// defecto: mostrar una referencia que el ganadero nunca vio ni aceptó
  /// sería peor que decirle que falta configurarla.
  Future<CurvaLactancia> curvaDe(String lecheriaId) async {
    final filas = await tramosDe(lecheriaId);
    return CurvaLactancia([
      for (final f in filas)
        TramoCurva(
          diaDesde: f.diaDesde,
          diaHasta: f.diaHasta,
          litrosEsperados: f.litrosEsperados,
        ),
    ]);
  }

  /// Cambia los litros esperados de un tramo.
  Future<void> editarTramo({
    required String tramoId,
    required double litrosEsperados,
  }) async {
    final ahora = DateTime.now();
    await (db.update(
      db.curvaReferencia,
    )..where((t) => t.id.equals(tramoId))).write(
      CurvaReferenciaCompanion(
        litrosEsperados: Value(litrosEsperados),
        updatedAt: Value(ahora),
        pendiente: const Value(true),
      ),
    );
  }

  /// Umbrales de calificación de la lechería. Si nunca se guardó una fila,
  /// devuelve los valores por defecto (a diferencia de la curva, acá sí hay
  /// un default sensato y universal).
  Future<UmbralesEvaluacion> umbralesDe(String lecheriaId) async {
    final config = await configDe(lecheriaId);
    if (config == null) return const UmbralesEvaluacion();
    return UmbralesEvaluacion(
      excelente: config.pctExcelente,
      bueno: config.pctBueno,
      vigilar: config.pctVigilar,
      bajo: config.pctBajo,
    );
  }

  Future<ConfigReporteRow?> configDe(String lecheriaId) {
    return (db.select(
          db.configReporte,
        )..where((t) => t.lecheriaId.equals(lecheriaId) & t.deletedAt.isNull()))
        .getSingleOrNull();
  }

  /// Umbral de litros bajo el cual la app sugiere secar la vaca.
  Future<double> umbralSecadoDe(String lecheriaId) async {
    final config = await configDe(lecheriaId);
    return config?.umbralSecadoLitros ?? 8;
  }

  /// Tope de kilos de leche que la finca espera entregar en una semana.
  /// `null` cuando no se ha configurado: sin tope no hay alerta que dar.
  Future<double?> topeKgLecheDe(String lecheriaId) async {
    final config = await configDe(lecheriaId);
    return config?.topeKgLeche;
  }

  Stream<double?> observarTopeKgLeche(String lecheriaId) {
    return (db.select(
          db.configReporte,
        )..where((t) => t.lecheriaId.equals(lecheriaId) & t.deletedAt.isNull()))
        .watch()
        .map((filas) => filas.isEmpty ? null : filas.first.topeKgLeche);
  }

  /// Fija el tope de kilos, o lo quita con [tope] en null.
  ///
  /// Va aparte de [editarConfig] justamente porque acepta null como valor
  /// válido: ahí null significa "no cambiés este campo", y acá significa
  /// "quitá el tope".
  Future<void> editarTopeKgLeche({
    required String lecheriaId,
    required double? tope,
  }) async {
    final config = await configDe(lecheriaId);
    if (config == null) return;
    final ahora = DateTime.now();
    await (db.update(
      db.configReporte,
    )..where((t) => t.id.equals(config.id))).write(
      ConfigReporteCompanion(
        topeKgLeche: Value(tope),
        updatedAt: Value(ahora),
        pendiente: const Value(true),
      ),
    );
  }

  /// Cuántos kilos de leche pagan un kilo de concentrado. Si la lechería no
  /// tiene fila de config todavía, el valor por defecto (a diferencia del
  /// tope, acá siempre hay una regla con la que calcular).
  Future<double> kgLechePorKgConcentradoDe(String lecheriaId) async {
    final config = await configDe(lecheriaId);
    return config?.kgLechePorKgConcentrado ?? kgLechePorKgConcentradoPorDefecto;
  }

  Future<void> editarKgLechePorKgConcentrado({
    required String lecheriaId,
    required double kgLechePorKg,
  }) async {
    // Cero o negativo no es una proporción: no habría ración que calcular.
    if (kgLechePorKg <= 0) return;
    final config = await configDe(lecheriaId);
    if (config == null) return;
    final ahora = DateTime.now();
    await (db.update(
      db.configReporte,
    )..where((t) => t.id.equals(config.id))).write(
      ConfigReporteCompanion(
        kgLechePorKgConcentrado: Value(kgLechePorKg),
        updatedAt: Value(ahora),
        pendiente: const Value(true),
      ),
    );
  }

  /// Cambia los umbrales de calificación y el umbral de secado.
  Future<void> editarConfig({
    required String lecheriaId,
    double? pctExcelente,
    double? pctBueno,
    double? pctVigilar,
    double? pctBajo,
    double? umbralSecadoLitros,
  }) async {
    final config = await configDe(lecheriaId);
    if (config == null) return;
    final ahora = DateTime.now();
    await (db.update(
      db.configReporte,
    )..where((t) => t.id.equals(config.id))).write(
      ConfigReporteCompanion(
        pctExcelente: Value(pctExcelente ?? config.pctExcelente),
        pctBueno: Value(pctBueno ?? config.pctBueno),
        pctVigilar: Value(pctVigilar ?? config.pctVigilar),
        pctBajo: Value(pctBajo ?? config.pctBajo),
        umbralSecadoLitros: Value(
          umbralSecadoLitros ?? config.umbralSecadoLitros,
        ),
        updatedAt: Value(ahora),
        pendiente: const Value(true),
      ),
    );
  }

  /// Lo que de verdad produce el hato en cada tramo, juntando **todas** las
  /// pesas registradas.
  ///
  /// Es la base de la recalibración: a los pocos meses el ganadero puede ver
  /// su curva real al lado de la que tiene cargada y adoptarla tramo por
  /// tramo. Cada pesa aporta una observación, ubicada según los días de
  /// lactancia que la vaca tenía **ese día**, no los de hoy.
  ///
  /// [minimoObservaciones] es cuántas se piden para considerar un tramo
  /// confiable: con 2 o 3 vacas el promedio lo mueve cualquier cosa.
  Future<List<PromedioRealTramo>> promediosRealesDelHato(
    String lecheriaId, {
    int minimoObservaciones = 10,
  }) async {
    final tramos = await tramosDe(lecheriaId);
    if (tramos.isEmpty) return const [];

    final consulta =
        db.select(db.pesasLeche).join([
          innerJoin(
            db.pesasSesiones,
            db.pesasSesiones.id.equalsExp(db.pesasLeche.sesionId),
          ),
          innerJoin(
            db.animales,
            db.animales.id.equalsExp(db.pesasLeche.animalId),
          ),
        ])..where(
          db.pesasSesiones.lecheriaId.equals(lecheriaId) &
              db.pesasLeche.deletedAt.isNull() &
              db.pesasSesiones.deletedAt.isNull() &
              db.animales.fechaUltimoParto.isNotNull(),
        );

    final filas = await consulta.get();
    final acumulado = <int, ({double litros, int n})>{};

    for (final f in filas) {
      final pesa = f.readTable(db.pesasLeche);
      final sesion = f.readTable(db.pesasSesiones);
      final animal = f.readTable(db.animales);
      // Los días que la vaca tenía el día de esa pesa.
      final dlac = diasLactancia(animal.fechaUltimoParto, hoy: sesion.fecha);
      if (dlac == null) continue;

      for (final t in tramos) {
        if (dlac >= t.diaDesde && (t.diaHasta == null || dlac <= t.diaHasta!)) {
          final actual = acumulado[t.diaDesde] ?? (litros: 0.0, n: 0);
          acumulado[t.diaDesde] = (
            litros: actual.litros + pesa.litros,
            n: actual.n + 1,
          );
          break;
        }
      }
    }

    return [
      for (final t in tramos)
        () {
          final a = acumulado[t.diaDesde];
          return PromedioRealTramo(
            tramo: t,
            promedio: a == null || a.n == 0 ? null : a.litros / a.n,
            observaciones: a?.n ?? 0,
            confiable: (a?.n ?? 0) >= minimoObservaciones,
          );
        }(),
    ];
  }

  /// Crea los siete tramos y la configuración del reporte de una lechería
  /// **nueva**. No hace nada si ya tiene tramos.
  Future<void> sembrarSiHaceFalta(String lecheriaId) async {
    final ahora = DateTime.now();
    final existentes = await tramosDe(lecheriaId);
    if (existentes.isEmpty) {
      var orden = 1;
      for (final tramo in CurvaLactancia.tramosPorDefecto) {
        await db
            .into(db.curvaReferencia)
            .insert(
              CurvaReferenciaCompanion.insert(
                id: _uuid.v4(),
                lecheriaId: lecheriaId,
                orden: orden++,
                diaDesde: tramo.diaDesde,
                diaHasta: Value(tramo.diaHasta),
                litrosEsperados: tramo.litrosEsperados,
                createdAt: ahora,
                updatedAt: ahora,
                pendiente: const Value(true),
              ),
            );
      }
    }

    if (await configDe(lecheriaId) == null) {
      await db
          .into(db.configReporte)
          .insert(
            ConfigReporteCompanion.insert(
              id: _uuid.v4(),
              lecheriaId: lecheriaId,
              createdAt: ahora,
              updatedAt: ahora,
              pendiente: const Value(true),
            ),
          );
    }
  }
}

/// Lo que el hato produjo de verdad en un tramo, para poder recalibrar la
/// curva con datos propios en vez de valores prestados.
class PromedioRealTramo {
  const PromedioRealTramo({
    required this.tramo,
    required this.promedio,
    required this.observaciones,
    required this.confiable,
  });

  final CurvaReferenciaRow tramo;

  /// Promedio real del tramo. null si todavía no pasó ninguna vaca por ahí.
  final double? promedio;

  /// Cuántas pesas alimentaron ese promedio.
  final int observaciones;

  /// true cuando hay suficientes pesas como para tomárselo en serio.
  final bool confiable;
}
