import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../combinar_streams.dart';
import '../domain/curva_lactancia.dart';
import '../domain/dieta_concentrado.dart';
import '../domain/grupos.dart';
import '../domain/semana.dart';
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

/// Una fila de lo pesado en una sesión, con la ficha de la vaca si la tiene.
class PesaDeSesion {
  const PesaDeSesion({required this.pesa, required this.animal});

  final PesaLecheRow pesa;

  /// null cuando es una **vaca manual**: se le anota leche pero no está en el
  /// inventario, así que no tiene días de lactancia.
  final AnimalRow? animal;

  bool get esManual => animal == null;

  /// Cómo se muestra en la lista. Las manuales van con asterisco, igual que
  /// en el reporte que trajo el cliente.
  String get etiqueta =>
      animal?.identificador ?? '${pesa.identificadorManual ?? '?'} *';

  /// Días de lactancia de la vaca al momento de consultar. null para las
  /// manuales y para las que nunca tuvieron un parto registrado.
  int? diasLactanciaHoy({DateTime? hoy}) =>
      diasLactancia(animal?.fechaUltimoParto, hoy: hoy);
}

/// Ordena identificadores como los lee una persona: la vaca 2 va antes que la
/// 10. Comparar como texto pondría "10" antes que "2", que es justo lo que
/// hace ilegible una lista de 36 vacas numeradas.
///
/// Los identificadores que no son solo números (p. ej. "A-14") se comparan
/// como texto y quedan después de los numéricos.
int compararIdentificadores(String a, String b) {
  final na = int.tryParse(a.trim());
  final nb = int.tryParse(b.trim());
  if (na != null && nb != null) return na.compareTo(nb);
  if (na != null) return -1;
  if (nb != null) return 1;
  return a.toLowerCase().compareTo(b.toLowerCase());
}

/// Una pesa del historial con sus totales ya sumados.
class SesionConTotales {
  const SesionConTotales({
    required this.sesion,
    required this.vacas,
    required this.litros,
  });

  final PesaSesionRow sesion;
  final int vacas;
  final double litros;

  double get promedio => vacas == 0 ? 0 : litros / vacas;
}

/// Acceso a sesiones de pesa y litros por vaca (Módulo 3). Lee y escribe en
/// la base local; el sync corre por separado.
class PesasRepository {
  PesasRepository(this.db);

  final AppDatabase db;
  final _uuid = const Uuid();

  /// Abre (o reutiliza si ya hay una abierta esta semana) una sesión de pesa.
  ///
  /// La ventana es **la semana, no el día**, porque se pesa un día por semana.
  /// Cuando buscaba por día, entrar a la pantalla un miércoles después de
  /// haber pesado el lunes abría una sesión nueva y vacía: la pesa del lunes
  /// seguía guardada, pero la pantalla arrancaba en blanco y parecía que se
  /// habían perdido los datos.
  ///
  /// Si de verdad se quiere una segunda pesa en la misma semana, se cierra la
  /// abierta y la siguiente llamada crea otra.
  Future<PesaSesionRow> abrirSesion({
    required String lecheriaId,
    DateTime? fecha,
  }) async {
    final ahora = fecha ?? DateTime.now();
    final inicioSemana = lunesDe(ahora);
    final finSemana = inicioSemana.add(const Duration(days: 7));
    // Puede haber MÁS de una sesión abierta: si dos dispositivos pesan sin
    // señal y luego sincronizan, cada uno creó la suya. Se reutiliza la
    // primera que se abrió, para seguir sumando donde ya se venía
    // trabajando. Sin el `limit(1)` esto reventaba la pantalla.
    final existente =
        await (db.select(db.pesasSesiones)
              ..where(
                (t) =>
                    t.lecheriaId.equals(lecheriaId) &
                    t.deletedAt.isNull() &
                    t.cerrada.equals(false) &
                    t.fecha.isBiggerOrEqualValue(inicioSemana) &
                    t.fecha.isSmallerThanValue(finSemana),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
              ..limit(1))
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

  /// Las últimas [cuantas] pesas, de la más reciente a la más vieja, con sus
  /// totales sumados **en la base**.
  ///
  /// La versión completa ([observarSesiones]) se trae todas las pesas de la
  /// finca a memoria para sumarlas; en Análisis está bien, pero el home se
  /// abre veinte veces al día y solo necesita cuatro puntos. Acá el `SUM` lo
  /// hace SQLite y vuelven cuatro filas.
  Stream<List<SesionConTotales>> observarUltimasSesiones(
    String lecheriaId, {
    int cuantas = 4,
  }) {
    final litros = db.pesasLeche.litros.sum();
    final vacas = db.pesasLeche.id.count();

    final consulta =
        db.select(db.pesasSesiones).join([
            leftOuterJoin(
              db.pesasLeche,
              db.pesasLeche.sesionId.equalsExp(db.pesasSesiones.id) &
                  db.pesasLeche.deletedAt.isNull(),
            ),
          ])
          ..addColumns([litros, vacas])
          ..where(
            db.pesasSesiones.lecheriaId.equals(lecheriaId) &
                db.pesasSesiones.deletedAt.isNull(),
          )
          ..groupBy([db.pesasSesiones.id])
          ..orderBy([OrderingTerm.desc(db.pesasSesiones.fecha)])
          ..limit(cuantas);

    return consulta.watch().map(
      (filas) => [
        for (final f in filas)
          SesionConTotales(
            sesion: f.readTable(db.pesasSesiones),
            vacas: f.read(vacas) ?? 0,
            litros: f.read(litros) ?? 0,
          ),
      ],
    );
  }

  /// Todas las pesas de la lechería, de la más reciente a la más vieja, con
  /// cuántas vacas y cuántos litros llevó cada una.
  ///
  /// Existe porque se pesa **una vez por semana**: sin esto, la pantalla de
  /// pesa solo alcanza la sesión de hoy y el trabajo de la semana pasada
  /// queda guardado pero invisible.
  Stream<List<SesionConTotales>> observarSesiones(String lecheriaId) {
    final sesiones =
        (db.select(db.pesasSesiones)
              ..where(
                (t) => t.lecheriaId.equals(lecheriaId) & t.deletedAt.isNull(),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.fecha)]))
            .watch();

    // Se recalculan los totales ante cualquier cambio en las pesas: agregar
    // una vaca a la sesión de hoy tiene que moverle el contador a la fila.
    final pesas = (db.select(
      db.pesasLeche,
    )..where((t) => t.deletedAt.isNull())).watch();

    return combinarUltimos(sesiones, pesas, (lista, todas) {
      return [
        for (final s in lista)
          () {
            final suyas = todas.where((p) => p.sesionId == s.id);
            return SesionConTotales(
              sesion: s,
              vacas: suyas.length,
              litros: suyas.fold<double>(0, (a, p) => a + p.litros),
            );
          }(),
      ];
    });
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

  /// Registra lo pesado de una vaca en la sesión: leche de la mañana, de la
  /// tarde y kilos de concentrado. El total del día se calcula acá.
  ///
  /// Se identifica la vaca por [animalId] (está en el inventario) o por
  /// [identificadorManual] (vaca manual, sin ficha ni días de lactancia).
  /// Hay que pasar exactamente uno de los dos.
  ///
  /// Si esa vaca YA se pesó en esta sesión y [corregir] es false, devuelve la
  /// fila existente para que la UI pregunte si se corrige (no se duplica). Si
  /// [corregir] es true, actualiza esa fila. Devuelve null cuando se guardó
  /// (fila nueva o corrección aplicada).
  Future<PesaLecheRow?> registrarPesa({
    required String sesionId,
    String? animalId,
    String? identificadorManual,
    double? litrosManana,
    double? litrosTarde,
    double? litrosTotal,
    double? concentradoKg,
    bool corregir = false,
  }) async {
    assert(
      (animalId == null) != (identificadorManual == null),
      'Pasá animalId (vaca del inventario) o identificadorManual (vaca '
      'manual), pero no los dos ni ninguno.',
    );
    // [litrosTotal] es para cuando se anota el día completo sin separar los
    // dos ordeños; el reporte muestra esas filas como "sin desglose".
    final litros = litrosTotal ?? ((litrosManana ?? 0) + (litrosTarde ?? 0));
    final existente =
        await (db.select(db.pesasLeche)..where((t) {
              final base = t.sesionId.equals(sesionId) & t.deletedAt.isNull();
              return animalId != null
                  ? base & t.animalId.equals(animalId)
                  : base & t.identificadorManual.equals(identificadorManual!);
            }))
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
          litrosManana: Value(litrosManana),
          litrosTarde: Value(litrosTarde),
          concentradoKg: Value(concentradoKg),
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
            animalId: Value(animalId),
            identificadorManual: Value(identificadorManual),
            litros: litros,
            litrosManana: Value(litrosManana),
            litrosTarde: Value(litrosTarde),
            concentradoKg: Value(concentradoKg),
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

  /// Lo pesado en la sesión junto con la ficha de cada vaca. Las vacas
  /// manuales vienen con `animal` en null: no tienen ficha ni días de
  /// lactancia, y en la lista se marcan con asterisco.
  Stream<List<PesaDeSesion>> observarDetalleSesion(String sesionId) {
    final consulta =
        db.select(db.pesasLeche).join([
            leftOuterJoin(
              db.animales,
              db.animales.id.equalsExp(db.pesasLeche.animalId),
            ),
          ])
          ..where(
            db.pesasLeche.sesionId.equals(sesionId) &
                db.pesasLeche.deletedAt.isNull(),
          )
          ..orderBy([OrderingTerm.desc(db.pesasLeche.createdAt)]);

    return consulta.watch().map(
      (filas) => [
        for (final f in filas)
          PesaDeSesion(
            pesa: f.readTable(db.pesasLeche),
            animal: f.readTableOrNull(db.animales),
          ),
      ],
    );
  }

  /// Vacas del grupo En ordeño que todavía no se pesaron en esta sesión.
  Future<List<AnimalRow>> faltantesDeSesion({
    required String lecheriaId,
    required String sesionId,
  }) async {
    final enOrdeno =
        await (db.select(db.animales)..where(
              (t) =>
                  t.lecheriaId.equals(lecheriaId) &
                  t.deletedAt.isNull() &
                  t.estado.equals(EstadoAnimal.activo) &
                  t.grupo.equals(GrupoAnimal.enOrdeno),
            ))
            .get();
    final pesadas = await (db.select(
      db.pesasLeche,
    )..where((t) => t.sesionId.equals(sesionId) & t.deletedAt.isNull())).get();
    final yaPesadas = {
      for (final p in pesadas)
        if (p.animalId != null) p.animalId!,
    };
    return [
      for (final a in enOrdeno)
        if (!yaPesadas.contains(a.id)) a,
    ]..sort(
      (a, b) => compararIdentificadores(a.identificador, b.identificador),
    );
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

  /// Dieta de concentrado del hato: cuánto le corresponde a cada vaca según **su**
  /// pesa más reciente, y cuánto se le está dando.
  ///
  /// Cada vaca sale con su último pesaje, no con el de la última sesión de la
  /// finca: así la que no se pesó esta semana entra con la de la anterior en
  /// vez de quedarse sin ración. Por eso cada fila lleva su fecha.
  ///
  /// Se traen todas las pesas de la lechería y se reduce en memoria. Con una
  /// consulta por vaca serían tantos viajes a la base como animales; el hato
  /// entero de una finca cabe de sobra en memoria.
  Future<List<RacionVaca>> dietaConcentrado(
    String lecheriaId, {
    required double kgLechePorKg,
  }) async {
    final filas =
        await (db.select(db.pesasLeche).join([
              innerJoin(
                db.pesasSesiones,
                db.pesasSesiones.id.equalsExp(db.pesasLeche.sesionId),
              ),
              leftOuterJoin(
                db.animales,
                db.animales.id.equalsExp(db.pesasLeche.animalId),
              ),
            ])..where(
              db.pesasSesiones.lecheriaId.equals(lecheriaId) &
                  db.pesasSesiones.deletedAt.isNull() &
                  db.pesasLeche.deletedAt.isNull(),
            ))
            .get();

    // Una sola fila por vaca: la de la pesa con fecha más nueva.
    final ultimaPorVaca = <String, TypedResult>{};
    for (final fila in filas) {
      final pesa = fila.readTable(db.pesasLeche);
      final clave = pesa.animalId ?? 'manual:${pesa.identificadorManual}';
      final guardada = ultimaPorVaca[clave];
      if (guardada == null ||
          fila
              .readTable(db.pesasSesiones)
              .fecha
              .isAfter(guardada.readTable(db.pesasSesiones).fecha)) {
        ultimaPorVaca[clave] = fila;
      }
    }

    final raciones = <RacionVaca>[];
    for (final fila in ultimaPorVaca.values) {
      final pesa = fila.readTable(db.pesasLeche);
      final animal = fila.readTableOrNull(db.animales);

      // Una vaca seca, vendida o borrada ya no come concentrado de
      // producción. Las manuales entran siempre: no tienen ficha que
      // consultar, pero su leche es real.
      if (animal != null &&
          (animal.deletedAt != null ||
              animal.estado != EstadoAnimal.activo ||
              animal.grupo != GrupoAnimal.enOrdeno)) {
        continue;
      }

      raciones.add(
        RacionVaca(
          identificador:
              animal?.identificador ?? pesa.identificadorManual ?? 'sin id',
          esManual: animal == null,
          litrosLeche: pesa.litros,
          fechaPesa: fila.readTable(db.pesasSesiones).fecha,
          concentradoActualKg: pesa.concentradoKg,
          racionKg: racionConcentrado(
            litrosLeche: pesa.litros,
            kgLechePorKg: kgLechePorKg,
          ),
        ),
      );
    }

    raciones.sort(
      (a, b) => compararIdentificadores(a.identificador, b.identificador),
    );
    return raciones;
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
