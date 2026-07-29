import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../domain/grupos.dart';
import '../local/database.dart';

/// Tipos de alerta reproductiva y de manejo (Módulo 9).
enum TipoAlerta {
  celoEsperado,
  confirmarPreniez,
  vaciaHaceMucho,
  proximaSecar,
  proximaParir,
  finRetiro,
}

/// Una alerta calculada para un animal, con su mensaje y fecha de referencia
/// (para ordenar: la más urgente primero).
class Alerta {
  const Alerta({
    required this.tipo,
    required this.animal,
    required this.mensaje,
    required this.fecha,
  });

  final TipoAlerta tipo;
  final AnimalRow animal;
  final String mensaje;
  final DateTime fecha;

  String get titulo => switch (tipo) {
    TipoAlerta.celoEsperado => 'Celo esperado',
    TipoAlerta.confirmarPreniez => 'Confirmar preñez',
    TipoAlerta.vaciaHaceMucho => 'Vacía hace mucho',
    TipoAlerta.proximaSecar => 'Próxima a secar',
    TipoAlerta.proximaParir => 'Próxima a parir',
    TipoAlerta.finRetiro => 'Fin de retiro de leche',
  };
}

/// Genera alertas a partir de los eventos ya registrados y de la
/// configuración de umbrales de la lechería (Módulo 9). Días de secado
/// biológico estándar: 60 días antes del parto probable.
const _diasSecadoAntesParto = 60;

class AlertasRepository {
  AlertasRepository(this.db);

  final AppDatabase db;
  final _uuid = const Uuid();

  Future<ConfigAlertaRow> obtenerConfig(String lecheriaId) async {
    final existente =
        await (db.select(db.configAlertas)..where(
              (t) => t.lecheriaId.equals(lecheriaId) & t.deletedAt.isNull(),
            ))
            .getSingleOrNull();
    if (existente != null) return existente;

    // Valores por defecto sensatos, sin persistir hasta que el usuario los edite.
    final ahora = DateTime.now();
    return ConfigAlertaRow(
      id: '',
      lecheriaId: lecheriaId,
      diasCeloEsperado: 21,
      diasConfirmarPreniez: 45,
      diasVaciosAltos: 150,
      diasAntesSecar: 60,
      diasAntesParto: 14,
      diasAvisoFinRetiro: 1,
      createdAt: ahora,
      updatedAt: ahora,
      pendiente: false,
    );
  }

  Stream<ConfigAlertaRow> observarConfig(String lecheriaId) async* {
    yield await obtenerConfig(lecheriaId);
    yield* (db.select(
          db.configAlertas,
        )..where((t) => t.lecheriaId.equals(lecheriaId) & t.deletedAt.isNull()))
        .watchSingleOrNull()
        .asyncMap((fila) async => fila ?? await obtenerConfig(lecheriaId));
  }

  Future<void> upsertConfig({
    required String lecheriaId,
    required int diasCeloEsperado,
    required int diasConfirmarPreniez,
    required int diasVaciosAltos,
    required int diasAntesSecar,
    required int diasAntesParto,
    required int diasAvisoFinRetiro,
  }) async {
    final existente =
        await (db.select(db.configAlertas)..where(
              (t) => t.lecheriaId.equals(lecheriaId) & t.deletedAt.isNull(),
            ))
            .getSingleOrNull();
    final ahora = DateTime.now();
    if (existente != null) {
      await (db.update(
        db.configAlertas,
      )..where((t) => t.id.equals(existente.id))).write(
        ConfigAlertasCompanion(
          diasCeloEsperado: Value(diasCeloEsperado),
          diasConfirmarPreniez: Value(diasConfirmarPreniez),
          diasVaciosAltos: Value(diasVaciosAltos),
          diasAntesSecar: Value(diasAntesSecar),
          diasAntesParto: Value(diasAntesParto),
          diasAvisoFinRetiro: Value(diasAvisoFinRetiro),
          updatedAt: Value(ahora),
          pendiente: const Value(true),
        ),
      );
      return;
    }
    await db
        .into(db.configAlertas)
        .insert(
          ConfigAlertasCompanion.insert(
            id: _uuid.v4(),
            lecheriaId: lecheriaId,
            diasCeloEsperado: Value(diasCeloEsperado),
            diasConfirmarPreniez: Value(diasConfirmarPreniez),
            diasVaciosAltos: Value(diasVaciosAltos),
            diasAntesSecar: Value(diasAntesSecar),
            diasAntesParto: Value(diasAntesParto),
            diasAvisoFinRetiro: Value(diasAvisoFinRetiro),
            createdAt: ahora,
            updatedAt: ahora,
            pendiente: const Value(true),
          ),
        );
  }

  /// Calcula todas las alertas vigentes de la lechería, más urgente primero.
  Future<List<Alerta>> generarAlertas(
    String lecheriaId, {
    DateTime? hoy,
  }) async {
    final ahora = hoy ?? DateTime.now();
    final config = await obtenerConfig(lecheriaId);
    final animales =
        await (db.select(db.animales)..where(
              (t) =>
                  t.lecheriaId.equals(lecheriaId) &
                  t.deletedAt.isNull() &
                  t.estado.equals(EstadoAnimal.activo),
            ))
            .get();

    final alertas = <Alerta>[];
    for (final animal in animales) {
      _alertaFinRetiro(alertas, animal, config, ahora);
      await _alertasReproductivas(alertas, animal, config, ahora);
    }
    alertas.sort((a, b) => a.fecha.compareTo(b.fecha));
    return alertas;
  }

  void _alertaFinRetiro(
    List<Alerta> alertas,
    AnimalRow animal,
    ConfigAlertaRow config,
    DateTime ahora,
  ) {
    final retiro = animal.retiroLecheHasta;
    if (retiro == null) return;
    final diasParaFin = retiro.difference(ahora).inDays;
    if (diasParaFin > config.diasAvisoFinRetiro) return;
    alertas.add(
      Alerta(
        tipo: TipoAlerta.finRetiro,
        animal: animal,
        fecha: retiro,
        mensaje: diasParaFin <= 0
            ? 'El retiro de leche ya venció'
            : 'El retiro de leche termina en $diasParaFin día(s)',
      ),
    );
  }

  Future<void> _alertasReproductivas(
    List<Alerta> alertas,
    AnimalRow animal,
    ConfigAlertaRow config,
    DateTime ahora,
  ) async {
    // Próxima a parir / próxima a secar (vacas preñadas).
    final fechaParto = animal.fechaProbableParto;
    if (animal.estadoReproductivo == EstadoReproductivo.preniada &&
        fechaParto != null) {
      final diasParaParto = fechaParto.difference(ahora).inDays;
      if (diasParaParto >= 0 && diasParaParto <= config.diasAntesParto) {
        alertas.add(
          Alerta(
            tipo: TipoAlerta.proximaParir,
            animal: animal,
            fecha: fechaParto,
            mensaje: 'Parto probable en $diasParaParto día(s)',
          ),
        );
      }
      final fechaSecado = fechaParto.subtract(
        const Duration(days: _diasSecadoAntesParto),
      );
      final diasParaSecado = fechaSecado.difference(ahora).inDays;
      if (animal.grupo != GrupoAnimal.secas &&
          diasParaSecado >= 0 &&
          diasParaSecado <= config.diasAntesSecar) {
        alertas.add(
          Alerta(
            tipo: TipoAlerta.proximaSecar,
            animal: animal,
            fecha: fechaSecado,
            mensaje: 'Debería secarse pronto (parto en $diasParaParto día(s))',
          ),
        );
      }
    }

    if (animal.estadoReproductivo == EstadoReproductivo.preniada) return;

    // Eventos del animal, más reciente primero.
    final eventos =
        await (db.select(db.eventosAnimal)
              ..where(
                (t) => t.animalId.equals(animal.id) & t.deletedAt.isNull(),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.fecha)]))
            .get();

    EventoAnimalRow? ultimoServicio;
    EventoAnimalRow? ultimaPalpacion;
    EventoAnimalRow? ultimoParto;
    for (final e in eventos) {
      if (ultimoServicio == null &&
          (e.tipo == TipoEventoAnimal.monta ||
              e.tipo == TipoEventoAnimal.inseminacion ||
              e.tipo == TipoEventoAnimal.celo)) {
        ultimoServicio = e;
      }
      if (ultimaPalpacion == null && e.tipo == TipoEventoAnimal.palpacion) {
        ultimaPalpacion = e;
      }
      if (ultimoParto == null && e.tipo == TipoEventoAnimal.parto) {
        ultimoParto = e;
      }
    }

    if (ultimoServicio != null) {
      final huboPalpacionDespues =
          ultimaPalpacion != null &&
          ultimaPalpacion.fecha.isAfter(ultimoServicio.fecha);
      final diasDesdeServicio = ahora.difference(ultimoServicio.fecha).inDays;
      if (!huboPalpacionDespues) {
        if (diasDesdeServicio >= config.diasConfirmarPreniez) {
          alertas.add(
            Alerta(
              tipo: TipoAlerta.confirmarPreniez,
              animal: animal,
              fecha: ultimoServicio.fecha,
              mensaje:
                  'Ya se puede palpar para confirmar preñez '
                  '($diasDesdeServicio días desde el servicio)',
            ),
          );
        } else if (diasDesdeServicio >= config.diasCeloEsperado) {
          alertas.add(
            Alerta(
              tipo: TipoAlerta.celoEsperado,
              animal: animal,
              fecha: ultimoServicio.fecha,
              mensaje: 'Celo esperado (revisar en el hato)',
            ),
          );
        }
      }
    }

    // Vacía hace mucho: días abiertos desde el último parto (o desde el alta
    // si nunca ha parido), solo para vacas en ordeño.
    if (animal.estadoReproductivo == EstadoReproductivo.vacia &&
        animal.grupo == GrupoAnimal.enOrdeno) {
      final referencia = ultimoParto?.fecha ?? animal.createdAt;
      final diasAbiertos = ahora.difference(referencia).inDays;
      if (diasAbiertos >= config.diasVaciosAltos) {
        alertas.add(
          Alerta(
            tipo: TipoAlerta.vaciaHaceMucho,
            animal: animal,
            fecha: referencia,
            mensaje: 'Vacía hace $diasAbiertos días',
          ),
        );
      }
    }
  }
}
