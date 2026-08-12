import 'package:drift/drift.dart';

import '../domain/curva_lactancia.dart';
import '../domain/grupos.dart';
import '../local/database.dart';
import 'curva_repository.dart';

/// En qué rango de producción cae una vaca (bloque "distribución por rango").
enum RangoProduccion {
  alta,
  media,
  baja,
  muyBaja;

  String get etiqueta => switch (this) {
    RangoProduccion.alta => 'Alta (> 18 L)',
    RangoProduccion.media => 'Media (12 - 18 L)',
    RangoProduccion.baja => 'Baja (8 - 12 L)',
    RangoProduccion.muyBaja => 'Muy baja (< 8 L)',
  };

  static RangoProduccion de(double litros) {
    if (litros > 18) return RangoProduccion.alta;
    if (litros >= 12) return RangoProduccion.media;
    if (litros >= 8) return RangoProduccion.baja;
    return RangoProduccion.muyBaja;
  }
}

/// Una vaca en el reporte de producción.
class FilaReporte {
  const FilaReporte({
    required this.identificador,
    required this.esManual,
    required this.diasLactancia,
    required this.litrosManana,
    required this.litrosTarde,
    required this.total,
    required this.concentradoKg,
    required this.anterior,
    required this.esperado,
    required this.evaluacion,
  });

  final String identificador;
  final bool esManual;

  /// null para las manuales y para las que no tienen parto registrado.
  final int? diasLactancia;

  /// null cuando la pesa se anotó sin separar los ordeños (datos viejos).
  final double? litrosManana;
  final double? litrosTarde;

  final double total;
  final double? concentradoKg;

  /// Total de esa misma vaca en la pesa anterior. null si es su primera.
  final double? anterior;

  /// Litros que la curva esperaba para sus días de lactancia. null si la vaca
  /// no tiene DLac o si la lechería no tiene curva cargada.
  final double? esperado;

  final EvaluacionVaca? evaluacion;

  bool get tieneDesglose => litrosManana != null || litrosTarde != null;

  double? get porcentajeDelEsperado {
    final e = esperado;
    if (e == null || e <= 0) return null;
    return total / e * 100;
  }

  double? get diferenciaAnterior {
    final a = anterior;
    return a == null ? null : total - a;
  }

  RangoProduccion get rango => RangoProduccion.de(total);
}

/// Un punto del gráfico "curva ideal vs promedio del hato".
class PuntoCurvaHato {
  const PuntoCurvaHato({
    required this.tramo,
    required this.promedioHato,
    required this.vacas,
  });

  final TramoCurva tramo;

  /// Promedio real de las vacas del hato en ese tramo. **null si no hay
  /// ninguna vaca ahí** — el reporte del cliente mostraba un valor para un
  /// tramo vacío, que no salía de sus datos.
  final double? promedioHato;

  final int vacas;
}

/// Cuántas vacas hay de cada tipo en la lechería.
class ResumenHato {
  const ResumenHato({
    required this.enProduccion,
    required this.secas,
    required this.prontasAlParto,
    required this.manuales,
  });

  /// Vacas activas del grupo En ordeño (no incluye las manuales).
  final int enProduccion;

  /// Del grupo Secas, las que no están cerca de parir.
  final int secas;

  /// Del grupo Secas, las que paren dentro de los próximos 30 días.
  final int prontasAlParto;

  /// Vacas pesadas que no están en el inventario.
  final int manuales;

  int get totalRegistradas => enProduccion + secas + prontasAlParto + manuales;
}

/// El reporte de producción de una sesión de pesa (Módulo 3).
///
/// Las definiciones están fijadas acá a propósito, porque el reporte de
/// ejemplo que trajo el cliente se contradecía en varios puntos:
///
/// - **Los promedios no mezclan.** `promedioPorVacaPesada` divide la leche
///   entre las vacas que efectivamente se pesaron (manuales incluidas, porque
///   su leche está en el total). El ejemplo dividía leche de 38 vacas entre 36.
/// - **La distribución por rango** se calcula sobre las mismas vacas pesadas,
///   así los porcentajes suman 100 %.
/// - **Una sola curva** alimenta el gráfico y los rankings. El ejemplo usaba
///   una referencia para el gráfico y otra distinta para las tablas.
/// - **Los tramos sin vacas quedan vacíos**, no se les inventa un promedio.
class ReporteProduccion {
  const ReporteProduccion({
    required this.fecha,
    required this.filas,
    required this.hato,
    required this.curvaHato,
    required this.curvaVacia,
  });

  final DateTime fecha;
  final List<FilaReporte> filas;
  final ResumenHato hato;
  final List<PuntoCurvaHato> curvaHato;

  /// true si la lechería todavía no tiene curva de referencia cargada: sin
  /// ella no hay comparación contra lo esperado y el reporte lo dice, en vez
  /// de mostrar una referencia que el ganadero nunca vio.
  final bool curvaVacia;

  double get produccionTotal => filas.fold(0, (a, f) => a + f.total);

  int get vacasPesadas => filas.length;

  /// Leche total ÷ vacas del hato (en producción + secas + prontas +
  /// manuales).
  double get promedioGeneral {
    final n = hato.totalRegistradas;
    return n == 0 ? 0 : produccionTotal / n;
  }

  /// Leche total ÷ vacas que se pesaron. Numerador y denominador cuentan a
  /// las mismas vacas.
  double get promedioPorVacaPesada {
    return filas.isEmpty ? 0 : produccionTotal / filas.length;
  }

  double get concentradoTotalKg =>
      filas.fold(0, (a, f) => a + (f.concentradoKg ?? 0));

  /// Vacas comparables contra la curva (tienen DLac y hay referencia).
  List<FilaReporte> get _comparables =>
      filas.where((f) => f.porcentajeDelEsperado != null).toList();

  /// Las que mejor cumplen para su etapa de lactancia.
  List<FilaReporte> mejoresSegunCurva({int cuantas = 5}) {
    final lista = [..._comparables]
      ..sort(
        (a, b) => b.porcentajeDelEsperado!.compareTo(a.porcentajeDelEsperado!),
      );
    return lista.take(cuantas).toList();
  }

  /// Las que están por debajo de lo esperado para su etapa.
  List<FilaReporte> debajoDeLoEsperado({int cuantas = 5}) {
    final lista =
        _comparables.where((f) => f.porcentajeDelEsperado! < 100).toList()
          ..sort(
            (a, b) =>
                a.porcentajeDelEsperado!.compareTo(b.porcentajeDelEsperado!),
          );
    return lista.take(cuantas).toList();
  }

  List<FilaReporte> topMayorProduccion({int cuantas = 5}) {
    final lista = [...filas]..sort((a, b) => b.total.compareTo(a.total));
    return lista.take(cuantas).toList();
  }

  List<FilaReporte> topMenorProduccion({int cuantas = 5}) {
    final lista = [...filas]..sort((a, b) => a.total.compareTo(b.total));
    return lista.take(cuantas).toList();
  }

  /// Cuántas vacas hay en cada rango de litros, sobre las pesadas.
  Map<RangoProduccion, int> get distribucionPorRango {
    final mapa = {for (final r in RangoProduccion.values) r: 0};
    for (final f in filas) {
      mapa[f.rango] = mapa[f.rango]! + 1;
    }
    return mapa;
  }

  /// Cuántas vacas caen en cada recomendación (Mantener / Vigilar / Revisar).
  Map<RecomendacionVaca, int> get recomendaciones {
    final mapa = {for (final r in RecomendacionVaca.values) r: 0};
    for (final f in filas) {
      final e = f.evaluacion;
      if (e == null) continue;
      final r = e.recomendacion;
      mapa[r] = mapa[r]! + 1;
    }
    return mapa;
  }
}

/// Arma el reporte de producción a partir de una sesión de pesa.
class ReporteRepository {
  ReporteRepository(this.db, {CurvaRepository? curva})
    : _curva = curva ?? CurvaRepository(db);

  final AppDatabase db;
  final CurvaRepository _curva;

  /// Cuántos días antes del parto se considera que una vaca seca está
  /// "pronta al parto".
  static const diasProntaAlParto = 30;

  Future<ReporteProduccion> generar({
    required String lecheriaId,
    required String sesionId,
    DateTime? hoy,
  }) async {
    final sesion = await (db.select(
      db.pesasSesiones,
    )..where((t) => t.id.equals(sesionId))).getSingle();
    final ahora = hoy ?? sesion.fecha;

    final curva = await _curva.curvaDe(lecheriaId);
    final umbrales = await _curva.umbralesDe(lecheriaId);

    final pesas = await (db.select(
      db.pesasLeche,
    )..where((t) => t.sesionId.equals(sesionId) & t.deletedAt.isNull())).get();

    final animales =
        await (db.select(db.animales)..where(
              (t) =>
                  t.lecheriaId.equals(lecheriaId) &
                  t.deletedAt.isNull() &
                  t.estado.equals(EstadoAnimal.activo),
            ))
            .get();
    final porId = {for (final a in animales) a.id: a};

    final anteriores = await _totalesDeLaPesaAnterior(
      lecheriaId: lecheriaId,
      sesion: sesion,
    );

    final filas = <FilaReporte>[];
    for (final p in pesas) {
      final animal = p.animalId == null ? null : porId[p.animalId];
      final esManual = p.animalId == null;
      final dlac = diasLactancia(animal?.fechaUltimoParto, hoy: ahora);
      final esperado = dlac == null ? null : curva.esperadoPara(dlac);
      final porcentaje = (esperado == null || esperado <= 0)
          ? null
          : p.litros / esperado * 100;

      filas.add(
        FilaReporte(
          identificador:
              animal?.identificador ?? p.identificadorManual ?? 'sin id',
          esManual: esManual,
          diasLactancia: dlac,
          litrosManana: p.litrosManana,
          litrosTarde: p.litrosTarde,
          total: p.litros,
          concentradoKg: p.concentradoKg,
          anterior: anteriores[_claveVaca(p)],
          esperado: esperado,
          evaluacion: porcentaje == null ? null : umbrales.evaluar(porcentaje),
        ),
      );
    }
    filas.sort((a, b) => a.identificador.compareTo(b.identificador));

    return ReporteProduccion(
      fecha: sesion.fecha,
      filas: filas,
      hato: _resumirHato(
        animales: animales,
        manuales: pesas.where((p) => p.animalId == null).length,
        ahora: ahora,
      ),
      curvaHato: _curvaDelHato(curva: curva, filas: filas),
      curvaVacia: curva.estaVacia,
    );
  }

  /// Clave con la que se empareja una vaca entre dos sesiones: su id de
  /// animal, o su identificador suelto si es manual.
  String _claveVaca(PesaLecheRow p) =>
      p.animalId ?? 'manual:${p.identificadorManual}';

  /// Totales por vaca de la sesión inmediatamente anterior, para la columna
  /// "Anterior (L)". Vacío si es la primera pesa.
  Future<Map<String, double>> _totalesDeLaPesaAnterior({
    required String lecheriaId,
    required PesaSesionRow sesion,
  }) async {
    final anterior =
        await (db.select(db.pesasSesiones)
              ..where(
                (t) =>
                    t.lecheriaId.equals(lecheriaId) &
                    t.deletedAt.isNull() &
                    t.id.equals(sesion.id).not() &
                    t.fecha.isSmallerOrEqualValue(sesion.fecha),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.fecha)])
              ..limit(1))
            .getSingleOrNull();
    if (anterior == null) return const {};

    final pesas =
        await (db.select(db.pesasLeche)..where(
              (t) => t.sesionId.equals(anterior.id) & t.deletedAt.isNull(),
            ))
            .get();
    return {for (final p in pesas) _claveVaca(p): p.litros};
  }

  ResumenHato _resumirHato({
    required List<AnimalRow> animales,
    required int manuales,
    required DateTime ahora,
  }) {
    var enProduccion = 0;
    var secas = 0;
    var prontas = 0;
    final limiteProntas = ahora.add(const Duration(days: diasProntaAlParto));

    for (final a in animales) {
      if (a.grupo == GrupoAnimal.enOrdeno) {
        enProduccion++;
      } else if (a.grupo == GrupoAnimal.secas) {
        final parto = a.fechaProbableParto;
        if (parto != null && parto.isBefore(limiteProntas)) {
          prontas++;
        } else {
          secas++;
        }
      }
      // Novillas y terneros no son vacas del ordeño: no entran al conteo.
    }

    return ResumenHato(
      enProduccion: enProduccion,
      secas: secas,
      prontasAlParto: prontas,
      manuales: manuales,
    );
  }

  List<PuntoCurvaHato> _curvaDelHato({
    required CurvaLactancia curva,
    required List<FilaReporte> filas,
  }) {
    return [
      for (final tramo in curva.tramos)
        () {
          final delTramo = filas
              .where(
                (f) =>
                    f.diasLactancia != null &&
                    f.diasLactancia! >= tramo.diaDesde &&
                    (tramo.diaHasta == null ||
                        f.diasLactancia! <= tramo.diaHasta!),
              )
              .toList();
          return PuntoCurvaHato(
            tramo: tramo,
            promedioHato: delTramo.isEmpty
                ? null
                : delTramo.fold<double>(0, (a, f) => a + f.total) /
                      delTramo.length,
            vacas: delTramo.length,
          );
        }(),
    ];
  }
}
