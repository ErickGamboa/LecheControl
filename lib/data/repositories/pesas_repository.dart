import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../local/database.dart';

/// Resumen de una sesión de pesa terminada (Módulo 3).
class ResumenSesion {
  const ResumenSesion({
    required this.totalVacas,
    required this.totalLitros,
    required this.promedio,
    required this.maximo,
    required this.minimo,
    required this.variacionRespectoAnterior,
  });

  final int totalVacas;
  final double totalLitros;
  final double promedio;
  final double maximo;
  final double minimo;

  /// Diferencia en litros contra el total de la sesión anterior. null si no
  /// hay sesión anterior para comparar.
  final double? variacionRespectoAnterior;
}

/// Un punto del historial de pesas de un animal, con su tendencia.
class PesaHistorial {
  const PesaHistorial({required this.fecha, required this.litros});
  final DateTime fecha;
  final double litros;
}

enum Tendencia { subiendo, estable, bajando }

/// Acceso a sesiones de pesa y litros por vaca (Módulo 3). Lee y escribe en
/// la base local; el sync corre por separado.
class PesasRepository {
  PesasRepository(this.db);

  final AppDatabase db;
  final _uuid = const Uuid();

  /// Abre (o reutiliza si ya existe una abierta hoy) una sesión de pesa.
  Future<PesaSesionRow> abrirSesion({
    required String lecheriaId,
    DateTime? fecha,
  }) async {
    final ahora = fecha ?? DateTime.now();
    final inicioDia = DateTime(ahora.year, ahora.month, ahora.day);
    final finDia = inicioDia.add(const Duration(days: 1));
    final existente =
        await (db.select(db.pesasSesiones)..where(
              (t) =>
                  t.lecheriaId.equals(lecheriaId) &
                  t.deletedAt.isNull() &
                  t.cerrada.equals(false) &
                  t.fecha.isBiggerOrEqualValue(inicioDia) &
                  t.fecha.isSmallerThanValue(finDia),
            ))
            .getSingleOrNull();
    if (existente != null) return existente;

    final id = _uuid.v4();
    await db
        .into(db.pesasSesiones)
        .insert(
          PesasSesionesCompanion.insert(
            id: id,
            lecheriaId: lecheriaId,
            fecha: ahora,
            createdAt: ahora,
            updatedAt: ahora,
            pendiente: const Value(true),
          ),
        );
    return (db.select(
      db.pesasSesiones,
    )..where((t) => t.id.equals(id))).getSingle();
  }

  Stream<PesaSesionRow?> observarSesion(String sesionId) {
    return (db.select(
      db.pesasSesiones,
    )..where((t) => t.id.equals(sesionId))).watchSingleOrNull();
  }

  /// Sesión abierta (no cerrada) más reciente de la lechería, si hay.
  Future<PesaSesionRow?> sesionAbierta(String lecheriaId) {
    return (db.select(db.pesasSesiones)
          ..where(
            (t) =>
                t.lecheriaId.equals(lecheriaId) &
                t.deletedAt.isNull() &
                t.cerrada.equals(false),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.fecha)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Registra los litros de un animal en la sesión. Si el animal YA se pesó
  /// en esta sesión y [corregir] es false, devuelve la fila existente para
  /// que la UI pregunte si se corrige (no se duplica). Si [corregir] es
  /// true, actualiza esa fila. Devuelve null cuando se guardó (fila nueva o
  /// corrección aplicada).
  Future<PesaLecheRow?> registrarPesa({
    required String sesionId,
    required String animalId,
    required double litros,
    bool corregir = false,
  }) async {
    final existente =
        await (db.select(db.pesasLeche)..where(
              (t) =>
                  t.sesionId.equals(sesionId) &
                  t.animalId.equals(animalId) &
                  t.deletedAt.isNull(),
            ))
            .getSingleOrNull();
    final ahora = DateTime.now();

    if (existente != null && !corregir) {
      return existente;
    }
    if (existente != null && corregir) {
      await (db.update(
        db.pesasLeche,
      )..where((t) => t.id.equals(existente.id))).write(
        PesasLecheCompanion(
          litros: Value(litros),
          updatedAt: Value(ahora),
          pendiente: const Value(true),
        ),
      );
      return null;
    }
    await db
        .into(db.pesasLeche)
        .insert(
          PesasLecheCompanion.insert(
            id: _uuid.v4(),
            sesionId: sesionId,
            animalId: animalId,
            litros: litros,
            createdAt: ahora,
            updatedAt: ahora,
            pendiente: const Value(true),
          ),
        );
    return null;
  }

  Future<void> cerrarSesion(String sesionId) async {
    await (db.update(
      db.pesasSesiones,
    )..where((t) => t.id.equals(sesionId))).write(
      PesasSesionesCompanion(
        cerrada: const Value(true),
        updatedAt: Value(DateTime.now()),
        pendiente: const Value(true),
      ),
    );
  }

  /// Litros registrados en la sesión (para el contador visible: pesadas y
  /// faltantes).
  Stream<List<PesaLecheRow>> observarPesasDeSesion(String sesionId) {
    return (db.select(db.pesasLeche)
          ..where((t) => t.sesionId.equals(sesionId) & t.deletedAt.isNull()))
        .watch();
  }

  Future<ResumenSesion> resumenSesion(String sesionId) async {
    final pesas = await (db.select(
      db.pesasLeche,
    )..where((t) => t.sesionId.equals(sesionId) & t.deletedAt.isNull())).get();
    if (pesas.isEmpty) {
      return const ResumenSesion(
        totalVacas: 0,
        totalLitros: 0,
        promedio: 0,
        maximo: 0,
        minimo: 0,
        variacionRespectoAnterior: null,
      );
    }
    final litros = pesas.map((p) => p.litros).toList();
    final total = litros.fold<double>(0, (a, b) => a + b);
    final promedio = total / litros.length;
    final maximo = litros.reduce((a, b) => a > b ? a : b);
    final minimo = litros.reduce((a, b) => a < b ? a : b);

    final sesion = await (db.select(
      db.pesasSesiones,
    )..where((t) => t.id.equals(sesionId))).getSingle();
    final anterior =
        await (db.select(db.pesasSesiones)
              ..where(
                (t) =>
                    t.lecheriaId.equals(sesion.lecheriaId) &
                    t.deletedAt.isNull() &
                    t.id.equals(sesionId).not() &
                    t.fecha.isSmallerOrEqualValue(sesion.fecha),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.fecha)])
              ..limit(1))
            .getSingleOrNull();

    double? variacion;
    if (anterior != null) {
      final pesasAnteriores =
          await (db.select(db.pesasLeche)..where(
                (t) => t.sesionId.equals(anterior.id) & t.deletedAt.isNull(),
              ))
              .get();
      if (pesasAnteriores.isNotEmpty) {
        final totalAnterior = pesasAnteriores.fold<double>(
          0,
          (a, p) => a + p.litros,
        );
        variacion = total - totalAnterior;
      }
    }

    return ResumenSesion(
      totalVacas: litros.length,
      totalLitros: total,
      promedio: promedio,
      maximo: maximo,
      minimo: minimo,
      variacionRespectoAnterior: variacion,
    );
  }

  /// Historial cronológico de pesas de un animal (más antiguo primero), para
  /// la Hoja de Vida y el cálculo de tendencia.
  Stream<List<PesaHistorial>> historialAnimal(String animalId) {
    final consulta =
        db.select(db.pesasLeche).join([
            innerJoin(
              db.pesasSesiones,
              db.pesasSesiones.id.equalsExp(db.pesasLeche.sesionId),
            ),
          ])
          ..where(
            db.pesasLeche.animalId.equals(animalId) &
                db.pesasLeche.deletedAt.isNull(),
          )
          ..orderBy([OrderingTerm.asc(db.pesasSesiones.fecha)]);

    return consulta.watch().map(
      (filas) => filas
          .map(
            (f) => PesaHistorial(
              fecha: f.readTable(db.pesasSesiones).fecha,
              litros: f.readTable(db.pesasLeche).litros,
            ),
          )
          .toList(),
    );
  }

  /// Última producción registrada del animal (para la tarjeta de la Pantalla
  /// de Trabajo y la tabla de rentabilidad). null si nunca se ha pesado.
  Future<double?> ultimaProduccion(String animalId) async {
    final consulta =
        db.select(db.pesasLeche).join([
            innerJoin(
              db.pesasSesiones,
              db.pesasSesiones.id.equalsExp(db.pesasLeche.sesionId),
            ),
          ])
          ..where(
            db.pesasLeche.animalId.equals(animalId) &
                db.pesasLeche.deletedAt.isNull(),
          )
          ..orderBy([OrderingTerm.desc(db.pesasSesiones.fecha)])
          ..limit(1);
    final fila = await consulta.getSingleOrNull();
    return fila?.readTable(db.pesasLeche).litros;
  }

  /// Promedio, tendencia y diferencia contra la pesa anterior de un animal.
  Future<({double promedio, Tendencia tendencia, double? diferencia})>
  estadisticasAnimal(String animalId) async {
    final historial = await historialAnimal(animalId).first;
    if (historial.isEmpty) {
      return (promedio: 0.0, tendencia: Tendencia.estable, diferencia: null);
    }
    final promedio =
        historial.fold<double>(0, (a, p) => a + p.litros) / historial.length;
    if (historial.length == 1) {
      return (
        promedio: promedio,
        tendencia: Tendencia.estable,
        diferencia: null,
      );
    }
    final ultimo = historial.last.litros;
    final anterior = historial[historial.length - 2].litros;
    final diferencia = ultimo - anterior;
    final tendencia = diferencia.abs() < 0.5
        ? Tendencia.estable
        : (diferencia > 0 ? Tendencia.subiendo : Tendencia.bajando);
    return (promedio: promedio, tendencia: tendencia, diferencia: diferencia);
  }
}
