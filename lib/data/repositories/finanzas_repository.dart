import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../domain/grupos.dart';
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
  /// estimado, y es lo que se usa para repartir el ingreso entre las vacas.
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

/// Cuánto aportó cada vaca en la semana (Módulo 5, ahora semanal).
class FilaRentabilidadSemanal {
  const FilaRentabilidadSemanal({
    required this.animal,
    required this.litros,
    required this.concentradoKg,
    required this.ingreso,
    required this.costoAsignado,
    required this.enRetiro,
  });

  final AnimalRow animal;

  /// Litros de su última pesa dentro de la semana.
  final double litros;
  final double concentradoKg;

  /// `litros × precio real por litro`. Cero si la vaca está en retiro: su
  /// leche se descarta y no se vende.
  final double ingreso;

  /// Parte de los gastos de la semana que le toca (total ÷ vacas en ordeño).
  final double costoAsignado;

  final bool enRetiro;

  double get utilidad => ingreso - costoAsignado;
}

/// Finanzas de la semana (Módulo 4 y 5). Reemplaza el esquema mensual de
/// `GastosRepository` + `RentabilidadRepository`.
///
/// La diferencia de fondo con el modelo viejo: **los ingresos no se calculan,
/// se digitan**. Antes la app multiplicaba litros por un precio que había que
/// mantener a mano; ahora se anota la plata que entró y el precio por litro
/// sale de dividirla entre los litros pagados. Ese precio, que es el real,
/// es el que reparte el ingreso entre las vacas.
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

  // -------------------------------------------------- rentabilidad por vaca

  /// Cuánto aportó cada vaca en ordeño durante la semana.
  ///
  /// El ingreso sale del **precio real** de la semana (lo que pagó la planta ÷
  /// los litros que pagó). Si esta semana no se anotaron los litros junto al
  /// monto, no hay con qué repartir y devuelve lista vacía: es preferible no
  /// mostrar nada a mostrar una utilidad inventada.
  Future<List<FilaRentabilidadSemanal>> rentabilidadPorVaca({
    required String lecheriaId,
    required SemanaRow semana,
    DateTime? hoy,
  }) async {
    final resumen = await resumenDe(semana);
    final precio = resumen.precioRealPorLitro;
    if (precio == null) return const [];

    final vacas =
        await (db.select(db.animales)..where(
              (t) =>
                  t.lecheriaId.equals(lecheriaId) &
                  t.deletedAt.isNull() &
                  t.estado.equals(EstadoAnimal.activo) &
                  t.grupo.equals(GrupoAnimal.enOrdeno),
            ))
            .get();
    if (vacas.isEmpty) return const [];

    final costoPorVaca = resumen.totalGastos / vacas.length;
    final ahora = hoy ?? DateTime.now();
    final finSemana = semana.fechaFin.add(const Duration(days: 1));

    final filas = <FilaRentabilidadSemanal>[];
    for (final vaca in vacas) {
      final pesa = await _ultimaPesaEnRango(
        animalId: vaca.id,
        desde: semana.fechaInicio,
        hasta: finSemana,
      );
      final litros = pesa?.litros ?? 0;
      final enRetiro =
          vaca.retiroLecheHasta != null &&
          vaca.retiroLecheHasta!.isAfter(ahora);
      filas.add(
        FilaRentabilidadSemanal(
          animal: vaca,
          litros: litros,
          concentradoKg: pesa?.concentradoKg ?? 0,
          // En retiro la leche se descarta: no se vende, no es ingreso.
          ingreso: enRetiro ? 0 : litros * precio,
          costoAsignado: costoPorVaca,
          enRetiro: enRetiro,
        ),
      );
    }
    filas.sort((a, b) => b.utilidad.compareTo(a.utilidad));
    return filas;
  }

  Future<PesaLecheRow?> _ultimaPesaEnRango({
    required String animalId,
    required DateTime desde,
    required DateTime hasta,
  }) async {
    final consulta =
        db.select(db.pesasLeche).join([
            innerJoin(
              db.pesasSesiones,
              db.pesasSesiones.id.equalsExp(db.pesasLeche.sesionId),
            ),
          ])
          ..where(
            db.pesasLeche.animalId.equals(animalId) &
                db.pesasLeche.deletedAt.isNull() &
                db.pesasSesiones.fecha.isBiggerOrEqualValue(desde) &
                db.pesasSesiones.fecha.isSmallerThanValue(hasta),
          )
          ..orderBy([OrderingTerm.desc(db.pesasSesiones.fecha)])
          ..limit(1);
    final fila = await consulta.getSingleOrNull();
    return fila?.readTable(db.pesasLeche);
  }
}
