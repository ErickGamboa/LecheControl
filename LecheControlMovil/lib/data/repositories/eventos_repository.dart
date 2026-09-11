import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../domain/grupos.dart';
import '../local/database.dart';

/// Registra los eventos de la hoja de vida del animal (Módulo 1 y 6):
/// celo/monta/inseminación, palpación, secado, parto y consulta el
/// historial. `cambiarGrupo` y `registrarBaja` viven en [AnimalesRepository]
/// (ver Módulo 2), pero el resto de eventos reproductivos y sanitarios
/// puntuales viven aquí.
class EventosRepository {
  EventosRepository(this.db);

  final AppDatabase db;
  final _uuid = const Uuid();

  /// Historial completo (más reciente primero) para la Hoja de Vida.
  Stream<List<EventoAnimalRow>> listarHojaVida(String animalId) {
    return (db.select(db.eventosAnimal)
          ..where((t) => t.animalId.equals(animalId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.fecha)]))
        .watch();
  }

  Future<EventoAnimalRow?> ultimoEventoDeTipo(
    String animalId,
    String tipo,
  ) async {
    return (db.select(db.eventosAnimal)
          ..where(
            (t) =>
                t.animalId.equals(animalId) &
                t.tipo.equals(tipo) &
                t.deletedAt.isNull(),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.fecha)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Celo, monta o inseminación: guarda la fecha del servicio y, si aplica,
  /// el toro/pajilla usado.
  Future<void> registrarServicio({
    required String animalId,
    required String lecheriaId,
    required String tipo, // celo | monta | inseminacion
    String? toroPajilla,
    DateTime? fecha,
    String? registradoPor,
  }) async {
    final ahora = fecha ?? DateTime.now();
    await db
        .into(db.eventosAnimal)
        .insert(
          EventosAnimalCompanion.insert(
            id: _uuid.v4(),
            animalId: animalId,
            lecheriaId: lecheriaId,
            tipo: tipo,
            fecha: ahora,
            toroPajilla: Value(toroPajilla),
            registradoPor: Value(registradoPor),
            createdAt: ahora,
            updatedAt: ahora,
            pendiente: const Value(true),
          ),
        );
  }

  /// Nota libre sobre la vaca: lo que el ganadero quiera dejar apuntado.
  ///
  /// No cambia nada de la ficha del animal — es el único evento que no toca
  /// grupo, estado ni fechas. El texto va en `detalle` y queda en la hoja de
  /// vida junto a los demás eventos. Un texto en blanco no se guarda.
  Future<void> registrarObservacion({
    required String animalId,
    required String lecheriaId,
    required String texto,
    DateTime? fecha,
    String? registradoPor,
  }) async {
    final limpio = texto.trim();
    if (limpio.isEmpty) return;
    final ahora = fecha ?? DateTime.now();
    await db
        .into(db.eventosAnimal)
        .insert(
          EventosAnimalCompanion.insert(
            id: _uuid.v4(),
            animalId: animalId,
            lecheriaId: lecheriaId,
            tipo: TipoEventoAnimal.observacion,
            fecha: ahora,
            detalle: Value(limpio),
            registradoPor: Value(registradoPor),
            createdAt: ahora,
            updatedAt: ahora,
            pendiente: const Value(true),
          ),
        );
  }

  /// Palpación / diagnóstico: resultado preñada o vacía. Si está preñada,
  /// guarda la fecha probable de parto y actualiza el estado reproductivo.
  Future<void> registrarPalpacion({
    required String animalId,
    required String lecheriaId,
    required String resultado, // preñada | vacia
    DateTime? fechaProbableParto,
    DateTime? fecha,
    String? registradoPor,
  }) async {
    final ahora = fecha ?? DateTime.now();
    final preniada = resultado == ResultadoPalpacion.preniada;
    await db.transaction(() async {
      await db
          .into(db.eventosAnimal)
          .insert(
            EventosAnimalCompanion.insert(
              id: _uuid.v4(),
              animalId: animalId,
              lecheriaId: lecheriaId,
              tipo: TipoEventoAnimal.palpacion,
              fecha: ahora,
              resultado: Value(resultado),
              registradoPor: Value(registradoPor),
              createdAt: ahora,
              updatedAt: ahora,
              pendiente: const Value(true),
            ),
          );
      await (db.update(db.animales)..where((t) => t.id.equals(animalId))).write(
        AnimalesCompanion(
          estadoReproductivo: Value(
            preniada ? EstadoReproductivo.preniada : EstadoReproductivo.vacia,
          ),
          fechaProbableParto: Value(preniada ? fechaProbableParto : null),
          updatedAt: Value(ahora),
          pendiente: const Value(true),
        ),
      );
    });
  }

  /// Secado: la vaca deja de ordeñarse y pasa al grupo Secas.
  Future<void> registrarSecado({
    required String animalId,
    required String lecheriaId,
    DateTime? fecha,
    String? registradoPor,
  }) async {
    final animal = await (db.select(
      db.animales,
    )..where((t) => t.id.equals(animalId))).getSingle();
    final ahora = fecha ?? DateTime.now();
    await db.transaction(() async {
      await (db.update(db.animales)..where((t) => t.id.equals(animalId))).write(
        AnimalesCompanion(
          grupo: const Value(GrupoAnimal.secas),
          updatedAt: Value(ahora),
          pendiente: const Value(true),
        ),
      );
      await db
          .into(db.eventosAnimal)
          .insert(
            EventosAnimalCompanion.insert(
              id: _uuid.v4(),
              animalId: animalId,
              lecheriaId: lecheriaId,
              tipo: TipoEventoAnimal.secado,
              fecha: ahora,
              grupoAnterior: Value(animal.grupo),
              grupoNuevo: const Value(GrupoAnimal.secas),
              registradoPor: Value(registradoPor),
              createdAt: ahora,
              updatedAt: ahora,
              pendiente: const Value(true),
            ),
          );
    });
  }

  /// Parto: registra el evento en la madre, crea la cría como animal nuevo
  /// vinculado, y la madre vuelve al grupo En ordeño. Devuelve el id de la
  /// cría creada.
  Future<String> registrarParto({
    required String animalId, // madre
    required String lecheriaId,
    required String sexoCria,
    String? identificadorCria,
    DateTime? fecha,
    String? registradoPor,
  }) async {
    final madre = await (db.select(
      db.animales,
    )..where((t) => t.id.equals(animalId))).getSingle();
    final ahora = fecha ?? DateTime.now();
    final criaId = _uuid.v4();
    final identificador = identificadorCria?.trim().isNotEmpty == true
        ? identificadorCria!.trim()
        : 'CRIA-${ahora.millisecondsSinceEpoch}';

    await db.transaction(() async {
      await db
          .into(db.animales)
          .insert(
            AnimalesCompanion.insert(
              id: criaId,
              lecheriaId: lecheriaId,
              identificador: identificador,
              sexo: sexoCria,
              grupo: GrupoAnimal.terneros,
              origen: 'nacido',
              madreId: Value(animalId),
              createdAt: ahora,
              updatedAt: ahora,
              pendiente: const Value(true),
            ),
          );
      await (db.update(db.animales)..where((t) => t.id.equals(animalId))).write(
        AnimalesCompanion(
          grupo: const Value(GrupoAnimal.enOrdeno),
          estadoReproductivo: const Value(EstadoReproductivo.vacia),
          fechaProbableParto: const Value(null),
          // Arranca de nuevo la cuenta de días de lactancia (DLac), que es la
          // base del reporte de producción.
          fechaUltimoParto: Value(ahora),
          updatedAt: Value(ahora),
          pendiente: const Value(true),
        ),
      );
      await db
          .into(db.eventosAnimal)
          .insert(
            EventosAnimalCompanion.insert(
              id: _uuid.v4(),
              animalId: animalId,
              lecheriaId: lecheriaId,
              tipo: TipoEventoAnimal.parto,
              fecha: ahora,
              sexoCria: Value(sexoCria),
              grupoAnterior: Value(madre.grupo),
              grupoNuevo: const Value(GrupoAnimal.enOrdeno),
              criaAnimalId: Value(criaId),
              registradoPor: Value(registradoPor),
              createdAt: ahora,
              updatedAt: ahora,
              pendiente: const Value(true),
            ),
          );
    });
    return criaId;
  }

  /// Cría(s) de una vaca (genealogía en la Hoja de Vida).
  Stream<List<AnimalRow>> observarCrias(String madreId) {
    return (db.select(
      db.animales,
    )..where((t) => t.madreId.equals(madreId) & t.deletedAt.isNull())).watch();
  }

  /// Corrige la fecha y la nota de un evento ya registrado.
  ///
  /// Solo esos dos campos: lo demás (que una palpación diga preñada, que un
  /// parto haya dado una cría) cambia la ficha del animal y la de la cría, y
  /// enmendarlo a medias dejaría la hoja de vida diciendo una cosa y el animal
  /// otra. Para eso se elimina el evento —que sí deshace todo— y se vuelve a
  /// registrar.
  ///
  /// La fecha de un parto arrastra los días de lactancia, así que cuando el
  /// parto corregido es el último de la vaca, se le mueve también
  /// `fechaUltimoParto`.
  Future<void> editarEvento({
    required String eventoId,
    required DateTime fecha,
    String? detalle,
  }) async {
    final evento = await (db.select(
      db.eventosAnimal,
    )..where((t) => t.id.equals(eventoId))).getSingleOrNull();
    if (evento == null) return;
    final ahora = DateTime.now();
    final limpio = detalle?.trim();

    await db.transaction(() async {
      await (db.update(
        db.eventosAnimal,
      )..where((t) => t.id.equals(eventoId))).write(
        EventosAnimalCompanion(
          fecha: Value(fecha),
          detalle: Value(limpio == null || limpio.isEmpty ? null : limpio),
          updatedAt: Value(ahora),
          pendiente: const Value(true),
        ),
      );
      if (evento.tipo != TipoEventoAnimal.parto) return;

      final ultimoParto = await _ultimoPartoDe(evento.animalId);
      if (ultimoParto == null || ultimoParto.id != eventoId) return;
      await (db.update(
        db.animales,
      )..where((t) => t.id.equals(evento.animalId))).write(
        AnimalesCompanion(
          fechaUltimoParto: Value(fecha),
          updatedAt: Value(ahora),
          pendiente: const Value(true),
        ),
      );
    });
  }

  /// Borra un evento de la hoja de vida **y deshace lo que ese evento le hizo
  /// al animal**.
  ///
  /// Un evento no es solo una línea del historial: el secado movió la vaca a
  /// Secas, la baja la sacó del inventario, el parto le reinició los días de
  /// lactancia. Borrar la línea y dejar el efecto sería peor que no poder
  /// borrar: la hoja de vida no explicaría por qué la vaca está donde está.
  ///
  /// Lo que no se puede recuperar no se inventa. Al deshacer un parto o una
  /// palpación, la vaca queda **sin estado reproductivo** y sin fecha probable
  /// de parto: nadie guardó cómo venía antes, y suponerlo sería peor que
  /// decir que no se sabe.
  Future<void> eliminarEvento(String eventoId) async {
    final evento = await (db.select(
      db.eventosAnimal,
    )..where((t) => t.id.equals(eventoId))).getSingleOrNull();
    if (evento == null) return;
    final ahora = DateTime.now();

    await db.transaction(() async {
      await (db.update(
        db.eventosAnimal,
      )..where((t) => t.id.equals(eventoId))).write(
        EventosAnimalCompanion(
          deletedAt: Value(ahora),
          updatedAt: Value(ahora),
          pendiente: const Value(true),
        ),
      );

      switch (evento.tipo) {
        case TipoEventoAnimal.parto:
          await _deshacerParto(evento, ahora);
        case TipoEventoAnimal.palpacion:
          await _deshacerPalpacion(evento, ahora);
        case TipoEventoAnimal.secado:
        case TipoEventoAnimal.cambioGrupo:
          await _devolverAlGrupoAnterior(evento, ahora);
        case TipoEventoAnimal.baja:
          await (db.update(
            db.animales,
          )..where((t) => t.id.equals(evento.animalId))).write(
            AnimalesCompanion(
              estado: const Value(EstadoAnimal.activo),
              updatedAt: Value(ahora),
              pendiente: const Value(true),
            ),
          );
        default:
          // Sanidad, celo, monta, inseminación, concentrado y observación no
          // tocan la ficha del animal: basta con borrar la línea.
          break;
      }
    });
  }

  /// Lo que el parto había cambiado: el grupo de la madre, sus días de
  /// lactancia y la cría que creó.
  Future<void> _deshacerParto(EventoAnimalRow evento, DateTime ahora) async {
    final partoPrevio = await _ultimoPartoDe(evento.animalId);
    await (db.update(
      db.animales,
    )..where((t) => t.id.equals(evento.animalId))).write(
      AnimalesCompanion(
        grupo: evento.grupoAnterior == null
            ? const Value.absent()
            : Value(evento.grupoAnterior!),
        fechaUltimoParto: Value(partoPrevio?.fecha),
        estadoReproductivo: const Value(EstadoReproductivo.desconocido),
        fechaProbableParto: const Value(null),
        updatedAt: Value(ahora),
        pendiente: const Value(true),
      ),
    );

    final criaId = evento.criaAnimalId;
    if (criaId == null) return;
    // La cría se va con el parto que la trajo, salvo que ya tenga vida
    // propia: si le anotaron algo o ya se pesó, borrarla sería tirar datos de
    // verdad. En ese caso queda en el inventario, suelta de su madre.
    final tieneEventos =
        await (db.select(db.eventosAnimal)..where(
              (t) => t.animalId.equals(criaId) & t.deletedAt.isNull(),
            ))
            .get();
    final tienePesas =
        await (db.select(db.pesasLeche)..where(
              (t) => t.animalId.equals(criaId) & t.deletedAt.isNull(),
            ))
            .get();
    if (tieneEventos.isNotEmpty || tienePesas.isNotEmpty) {
      await (db.update(db.animales)..where((t) => t.id.equals(criaId))).write(
        AnimalesCompanion(
          madreId: const Value(null),
          updatedAt: Value(ahora),
          pendiente: const Value(true),
        ),
      );
      return;
    }
    await (db.update(db.animales)..where((t) => t.id.equals(criaId))).write(
      AnimalesCompanion(
        deletedAt: Value(ahora),
        updatedAt: Value(ahora),
        pendiente: const Value(true),
      ),
    );
  }

  /// Vuelve al diagnóstico anterior, si quedó alguno.
  Future<void> _deshacerPalpacion(
    EventoAnimalRow evento,
    DateTime ahora,
  ) async {
    final previa = await ultimoEventoDeTipo(
      evento.animalId,
      TipoEventoAnimal.palpacion,
    );
    final resultado = previa?.resultado;
    await (db.update(
      db.animales,
    )..where((t) => t.id.equals(evento.animalId))).write(
      AnimalesCompanion(
        estadoReproductivo: Value(
          resultado == ResultadoPalpacion.preniada
              ? EstadoReproductivo.preniada
              : resultado == ResultadoPalpacion.vacia
              ? EstadoReproductivo.vacia
              : EstadoReproductivo.desconocido,
        ),
        // La fecha probable de parto no se guarda en el evento, así que no hay
        // de dónde sacar la anterior: se limpia y se vuelve a palpar.
        fechaProbableParto: const Value(null),
        updatedAt: Value(ahora),
        pendiente: const Value(true),
      ),
    );
  }

  Future<void> _devolverAlGrupoAnterior(
    EventoAnimalRow evento,
    DateTime ahora,
  ) async {
    final anterior = evento.grupoAnterior;
    if (anterior == null) return;
    await (db.update(
      db.animales,
    )..where((t) => t.id.equals(evento.animalId))).write(
      AnimalesCompanion(
        grupo: Value(anterior),
        updatedAt: Value(ahora),
        pendiente: const Value(true),
      ),
    );
  }

  /// El último parto que le queda a la vaca (los borrados no cuentan).
  Future<EventoAnimalRow?> _ultimoPartoDe(String animalId) =>
      ultimoEventoDeTipo(animalId, TipoEventoAnimal.parto);
}
