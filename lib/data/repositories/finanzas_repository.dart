import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../domain/semana.dart';
import '../local/database.dart';

/// Lo que entró, lo que salió y lo que quedó en una semana.
class ResumenSemana {
  const ResumenSemana({
    required this.semana,
    required this.ingresos,
    required this.gastos,
  });

  final SemanaRow semana;
  final List<IngresoSemanaRow> ingresos;
  final List<GastoSemanaRow> gastos;

  double get totalIngresos => ingresos.fold(0, (a, i) => a + i.monto);
  double get totalGastos => gastos.fold(0, (a, g) => a + g.monto);

  /// Lo que quedó. Puede ser negativa.
  double get utilidad => totalIngresos - totalGastos;

  double totalIngresosDe(String tipo) =>
      ingresos.where((i) => i.tipo == tipo).fold(0, (a, i) => a + i.monto);

  double get montoLeche => totalIngresosDe(TipoIngreso.leche);

  /// Litros de leche que la planta pagó esta semana.
  double get litrosLeche => ingresos
      .where((i) => i.tipo == TipoIngreso.leche)
      .fold(0, (a, i) => a + (i.litros ?? 0));

  /// **El precio real por litro de la semana**: lo que pagaron dividido entre
  /// los litros que pagaron. Es plata que entró de verdad, no un precio
  /// estimado ni digitado a mano.
  ///
  /// null si no se anotaron los litros junto al monto.
  double? get precioRealPorLitro {
    final litros = litrosLeche;
    return litros <= 0 ? null : montoLeche / litros;
  }

  /// Gastos sumados por categoría, de mayor a menor.
  List<({String categoria, double monto})> get gastosPorCategoria {
    final mapa = <String, double>{};
    for (final g in gastos) {
      mapa[g.categoria] = (mapa[g.categoria] ?? 0) + g.monto;
    }
    final lista = [
      for (final e in mapa.entries) (categoria: e.key, monto: e.value),
    ]..sort((a, b) => b.monto.compareTo(a.monto));
    return lista;
  }
}

/// Finanzas de la semana (Módulo 4 y 5). Reemplaza el esquema mensual de
/// `GastosRepository` + `RentabilidadRepository`.
///
/// La diferencia de fondo con el modelo viejo: **los ingresos no se calculan,
/// se digitan**. Antes la app multiplicaba litros por un precio que había que
/// mantener a mano; ahora se anota la plata que entró y el precio por litro
/// sale de dividirla entre los litros pagados.
class FinanzasRepository {
  FinanzasRepository(this.db);

  final AppDatabase db;
  final _uuid = const Uuid();

  /// Abre (o reutiliza) la semana en la que cae [fecha].
  Future<SemanaRow> abrirSemana({
    required String lecheriaId,
    DateTime? fecha,
  }) async {
    final inicio = lunesDe(fecha ?? DateTime.now());
    final fin = inicio.add(const Duration(days: 6));

    final existente =
        await (db.select(db.semanas)..where(
              (t) =>
                  t.lecheriaId.equals(lecheriaId) &
                  t.deletedAt.isNull() &
                  t.fechaInicio.equals(inicio),
            ))
            .getSingleOrNull();
    if (existente != null) return existente;

    final ahora = DateTime.now();
    final id = _uuid.v4();
    await db
        .into(db.semanas)
        .insert(
          SemanasCompanion.insert(
            id: id,
            lecheriaId: lecheriaId,
            fechaInicio: inicio,
            fechaFin: fin,
            createdAt: ahora,
            updatedAt: ahora,
            pendiente: const Value(true),
          ),
        );
    return (db.select(db.semanas)..where((t) => t.id.equals(id))).getSingle();
  }

  /// Semanas con movimientos, de la más reciente a la más vieja.
  Stream<List<SemanaRow>> observarSemanas(String lecheriaId) {
    return (db.select(db.semanas)
          ..where((t) => t.lecheriaId.equals(lecheriaId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.fechaInicio)]))
        .watch();
  }

  Stream<ResumenSemana> observarResumen(SemanaRow semana) {
    final ingresos =
        (db.select(db.ingresosSemana)
              ..where(
                (t) => t.semanaId.equals(semana.id) & t.deletedAt.isNull(),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
            .watch();
    final gastos =
        (db.select(db.gastosSemana)
              ..where(
                (t) => t.semanaId.equals(semana.id) & t.deletedAt.isNull(),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
            .watch();

    // Un cambio en cualquiera de las dos listas rehace el resumen.
    return ingresos.asyncExpand(
      (i) => gastos.map(
        (g) => ResumenSemana(semana: semana, ingresos: i, gastos: g),
      ),
    );
  }

  Future<ResumenSemana> resumenDe(SemanaRow semana) async {
    final ingresos = await (db.select(
      db.ingresosSemana,
    )..where((t) => t.semanaId.equals(semana.id) & t.deletedAt.isNull())).get();
    final gastos = await (db.select(
      db.gastosSemana,
    )..where((t) => t.semanaId.equals(semana.id) & t.deletedAt.isNull())).get();
    return ResumenSemana(semana: semana, ingresos: ingresos, gastos: gastos);
  }

  // ------------------------------------------------------------- ingresos

  /// Anota plata que entró. Para [TipoIngreso.leche] conviene pasar también
  /// los [litros] que pagaron: de ahí sale el precio real por litro.
  Future<void> agregarIngreso({
    required String lecheriaId,
    required String semanaId,
    required String tipo,
    required double monto,
    double? litros,
    String? animalId,
    String? detalle,
  }) async {
    final ahora = DateTime.now();
    await db
        .into(db.ingresosSemana)
        .insert(
          IngresosSemanaCompanion.insert(
            id: _uuid.v4(),
            lecheriaId: lecheriaId,
            semanaId: semanaId,
            tipo: tipo,
            monto: monto,
            litros: Value(tipo == TipoIngreso.leche ? litros : null),
            animalId: Value(tipo == TipoIngreso.ventaGanado ? animalId : null),
            detalle: Value(detalle?.trim().isEmpty == true ? null : detalle),
            createdAt: ahora,
            updatedAt: ahora,
            pendiente: const Value(true),
          ),
        );
  }

  Future<void> eliminarIngreso(String id) async {
    final ahora = DateTime.now();
    await (db.update(db.ingresosSemana)..where((t) => t.id.equals(id))).write(
      IngresosSemanaCompanion(
        deletedAt: Value(ahora),
        updatedAt: Value(ahora),
        pendiente: const Value(true),
      ),
    );
  }

  // --------------------------------------------------------------- gastos

  Future<void> agregarGasto({
    required String lecheriaId,
    required String semanaId,
    required String categoria,
    required double monto,
    String? detalle,
  }) async {
    final ahora = DateTime.now();
    await db
        .into(db.gastosSemana)
        .insert(
          GastosSemanaCompanion.insert(
            id: _uuid.v4(),
            lecheriaId: lecheriaId,
            semanaId: semanaId,
            categoria: categoria.trim(),
            monto: monto,
            detalle: Value(detalle?.trim().isEmpty == true ? null : detalle),
            createdAt: ahora,
            updatedAt: ahora,
            pendiente: const Value(true),
          ),
        );
  }

  Future<void> eliminarGasto(String id) async {
    final ahora = DateTime.now();
    await (db.update(db.gastosSemana)..where((t) => t.id.equals(id))).write(
      GastosSemanaCompanion(
        deletedAt: Value(ahora),
        updatedAt: Value(ahora),
        pendiente: const Value(true),
      ),
    );
  }

  Stream<List<CategoriaGastoRow>> observarCategorias(String lecheriaId) {
    return (db.select(db.categoriasGasto)
          ..where((t) => t.lecheriaId.equals(lecheriaId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.orden)]))
        .watch();
  }

  /// Agrega una categoría que el ganadero escribió y todavía no existía, para
  /// que la próxima vez le salga como botón.
  Future<void> recordarCategoria({
    required String lecheriaId,
    required String nombre,
  }) async {
    final limpio = nombre.trim();
    if (limpio.isEmpty) return;
    final existente =
        await (db.select(db.categoriasGasto)..where(
              (t) =>
                  t.lecheriaId.equals(lecheriaId) &
                  t.nombre.equals(limpio) &
                  t.deletedAt.isNull(),
            ))
            .getSingleOrNull();
    if (existente != null) return;

    final ahora = DateTime.now();
    await db
        .into(db.categoriasGasto)
        .insert(
          CategoriasGastoCompanion.insert(
            id: _uuid.v4(),
            lecheriaId: lecheriaId,
            nombre: limpio,
            orden: const Value(99),
            createdAt: ahora,
            updatedAt: ahora,
            pendiente: const Value(true),
          ),
        );
  }
}
