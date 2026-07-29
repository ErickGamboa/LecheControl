import 'package:drift/drift.dart';

import '../domain/grupos.dart';
import '../local/database.dart';
import 'gastos_repository.dart';
import 'pesas_repository.dart';

/// Una fila de la tabla de rentabilidad (Módulo 5), por vaca en ordeño.
class FilaRentabilidad {
  const FilaRentabilidad({
    required this.animal,
    required this.litrosDia,
    required this.kgConcentradoDia,
    required this.costoConcentradoDia,
    required this.costoFijoVaca,
    required this.costoTotalDia,
    required this.ingresoDia,
    required this.utilidadDia,
    required this.enRetiro,
  });

  final AnimalRow animal;
  final double litrosDia;
  final double kgConcentradoDia;
  final double costoConcentradoDia;
  final double costoFijoVaca;
  final double costoTotalDia;
  final double ingresoDia;
  final double utilidadDia;
  final bool enRetiro;
}

/// Calcula la rentabilidad por vaca a partir de la última pesa, los
/// parámetros del período y los costos fijos (Módulo 5). Toma solo las vacas
/// activas del grupo En ordeño.
class RentabilidadRepository {
  RentabilidadRepository(
    this.db, {
    GastosRepository? gastos,
    PesasRepository? pesas,
  }) : _gastos = gastos ?? GastosRepository(db),
       _pesas = pesas ?? PesasRepository(db);

  final AppDatabase db;
  final GastosRepository _gastos;
  final PesasRepository _pesas;

  /// Tabla de rentabilidad del mes calendario actual (o el que se indique).
  /// Devuelve una lista vacía si todavía no hay parámetros de precio
  /// cargados para el período, o si no hay vacas en ordeño.
  Future<List<FilaRentabilidad>> calcularTabla(
    String lecheriaId, {
    DateTime? hoy,
  }) async {
    final ahora = hoy ?? DateTime.now();
    final periodo = await _gastos.obtenerPeriodo(
      lecheriaId,
      ahora.year,
      ahora.month,
    );
    if (periodo == null) return const [];

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

    final totalCostosFijos = await _gastos.totalCostosFijos(periodo.id);
    final diasDelMes = DateTime(ahora.year, ahora.month + 1, 0).day;
    final costoFijoDia = totalCostosFijos / diasDelMes;
    final costoFijoPorVaca = costoFijoDia / vacas.length;

    final filas = <FilaRentabilidad>[];
    for (final vaca in vacas) {
      final ultimaProduccion = await _pesas.ultimaProduccion(vaca.id);
      final litrosDia = ultimaProduccion ?? 0.0;
      final enRetiro =
          vaca.retiroLecheHasta != null &&
          vaca.retiroLecheHasta!.isAfter(ahora);
      // D-05 del spec: en retiro, la leche se descarta y no cuenta ingreso.
      final ingresoDia = enRetiro ? 0.0 : litrosDia * periodo.precioLitro;
      final costoConcentradoDia =
          vaca.concentradoKgDia * periodo.precioConcentradoKg;
      final costoTotalDia = costoConcentradoDia + costoFijoPorVaca;
      final utilidadDia = ingresoDia - costoTotalDia;
      filas.add(
        FilaRentabilidad(
          animal: vaca,
          litrosDia: litrosDia,
          kgConcentradoDia: vaca.concentradoKgDia,
          costoConcentradoDia: costoConcentradoDia,
          costoFijoVaca: costoFijoPorVaca,
          costoTotalDia: costoTotalDia,
          ingresoDia: ingresoDia,
          utilidadDia: utilidadDia,
          enRetiro: enRetiro,
        ),
      );
    }
    return filas;
  }

  List<FilaRentabilidad> top5MayorUtilidad(List<FilaRentabilidad> filas) {
    final ordenadas = [...filas]
      ..sort((a, b) => b.utilidadDia.compareTo(a.utilidadDia));
    return ordenadas.take(5).toList();
  }

  List<FilaRentabilidad> top5MenorUtilidad(List<FilaRentabilidad> filas) {
    final ordenadas = [...filas]
      ..sort((a, b) => a.utilidadDia.compareTo(b.utilidadDia));
    return ordenadas.take(5).toList();
  }

  /// Sugiere candidatas a secar: por debajo del umbral configurado o con
  /// utilidad negativa. La decisión final la toma el ganadero.
  List<FilaRentabilidad> candidatasASecar(
    List<FilaRentabilidad> filas,
    double umbralLitros,
  ) {
    return filas
        .where((f) => f.litrosDia < umbralLitros || f.utilidadDia < 0)
        .toList();
  }

  double utilidadTotalPeriodo(List<FilaRentabilidad> filas) {
    return filas.fold<double>(0, (a, f) => a + f.utilidadDia);
  }
}
