/// Constantes de dominio de LecheControl: grupos del hato, sexos, orígenes,
/// motivos de baja y estados reproductivos. Los valores (códigos) son los que
/// se guardan en la base local y en Supabase; las etiquetas son para la UI.
library;

/// Grupos/estados del hato (Módulo 1 y 2). Sin grupos libres ni de toros.
///
/// "En tratamiento" ya no existe: aplicar un medicamento no saca a la vaca de
/// su grupo, solo le deja el evento en la hoja de vida.
abstract final class GrupoAnimal {
  static const enOrdeno = 'en_ordeno';
  static const secas = 'secas';
  static const novillas = 'novillas';
  static const terneros = 'terneros';

  static const todos = [enOrdeno, secas, novillas, terneros];

  /// Grupos donde se puede dar de alta un animal nuevo.
  static const altaDisponibles = todos;

  static String etiqueta(String codigo) => switch (codigo) {
    enOrdeno => 'En ordeño',
    secas => 'Secas',
    novillas => 'Novillas',
    terneros => 'Terneros',
    _ => codigo,
  };
}

/// Cuántos días antes del parto una vaca se considera **pronta**.
const diasParaPronta = 21;

/// Días que faltan para el parto probable. Negativo si ya se pasó de la
/// fecha. null si no hay fecha probable (vaca vacía o sin palpar).
int? diasParaParto(DateTime? fechaProbableParto, {DateTime? hoy}) {
  if (fechaProbableParto == null) return null;
  final referencia = hoy ?? DateTime.now();
  final dia = DateTime(referencia.year, referencia.month, referencia.day);
  final parto = DateTime(
    fechaProbableParto.year,
    fechaProbableParto.month,
    fechaProbableParto.day,
  );
  return parto.difference(dia).inDays;
}

/// **Pronta**: le falta poco para parir.
///
/// No es un grupo del hato sino un estado que se deduce de la fecha probable
/// de parto, justamente para que la vaca **no salga de Secas** cuando entra en
/// él. Una vaca que ya se pasó de la fecha sigue pronta: todavía no parió.
bool esPronta(DateTime? fechaProbableParto, {DateTime? hoy}) {
  final dias = diasParaParto(fechaProbableParto, hoy: hoy);
  return dias != null && dias <= diasParaPronta;
}

/// Cómo se lee el estado de pronta en pantalla, p. ej. "Pronta · faltan 9
/// días" o "Pronta · pasada de fecha".
String etiquetaPronta(DateTime? fechaProbableParto, {DateTime? hoy}) {
  final dias = diasParaParto(fechaProbableParto, hoy: hoy);
  if (dias == null) return 'Pronta';
  if (dias < 0) return 'Pronta · pasada de fecha';
  if (dias == 0) return 'Pronta · pare hoy';
  if (dias == 1) return 'Pronta · falta 1 día';
  return 'Pronta · faltan $dias días';
}

/// Sexo del animal.
abstract final class Sexo {
  static const hembra = 'hembra';
  static const macho = 'macho';

  static const todos = [hembra, macho];

  static String etiqueta(String codigo) => switch (codigo) {
    hembra => 'Hembra',
    macho => 'Macho',
    _ => codigo,
  };
}

/// Estado del animal en su ciclo de vida (activo o dado de baja).
abstract final class EstadoAnimal {
  static const activo = 'activo';
  static const vendido = 'vendido';
  static const muerto = 'muerto';
  static const descartado = 'descartado';

  static const todos = [activo, vendido, muerto, descartado];

  static String etiqueta(String codigo) => switch (codigo) {
    activo => 'Activo',
    vendido => 'Vendido',
    muerto => 'Muerto',
    descartado => 'Descartado',
    _ => codigo,
  };
}

/// Origen del animal: comprado o nacido en la finca.
abstract final class OrigenAnimal {
  static const comprado = 'comprado';
  static const nacido = 'nacido';

  static const todos = [comprado, nacido];

  static String etiqueta(String codigo) => switch (codigo) {
    comprado => 'Comprado',
    nacido => 'Nacido en la finca',
    _ => codigo,
  };
}

/// Motivo de baja del animal (Módulo 2).
abstract final class MotivoBaja {
  static const venta = 'venta';
  static const muerte = 'muerte';
  static const descarte = 'descarte';

  static const todos = [venta, muerte, descarte];

  static String etiqueta(String codigo) => switch (codigo) {
    venta => 'Venta',
    muerte => 'Muerte',
    descarte => 'Descarte',
    _ => codigo,
  };
}

/// Estado reproductivo del animal (hembras).
abstract final class EstadoReproductivo {
  static const vacia = 'vacia';
  static const preniada = 'preñada';
  static const desconocido = 'desconocido';

  static const todos = [vacia, preniada, desconocido];

  static String etiqueta(String codigo) => switch (codigo) {
    vacia => 'Vacía',
    preniada => 'Preñada',
    desconocido => 'Desconocido',
    _ => codigo,
  };
}

/// Tipos de evento de la hoja de vida (Módulo 1 y 6).
abstract final class TipoEventoAnimal {
  static const sanidad = 'sanidad';
  static const celo = 'celo';
  static const monta = 'monta';
  static const inseminacion = 'inseminacion';
  static const palpacion = 'palpacion';
  static const secado = 'secado';
  static const parto = 'parto';
  static const cambioGrupo = 'cambio_grupo';
  static const baja = 'baja';
  static const concentrado = 'concentrado';

  /// Nota libre que el ganadero escribe sobre la vaca. No cambia nada del
  /// animal: es solo texto que queda en su hoja de vida.
  static const observacion = 'observacion';

  static const todos = [
    sanidad,
    celo,
    monta,
    inseminacion,
    palpacion,
    secado,
    parto,
    cambioGrupo,
    baja,
    concentrado,
    observacion,
  ];

  static String etiqueta(String codigo) => switch (codigo) {
    sanidad => 'Sanidad',
    celo => 'Celo',
    monta => 'Monta',
    inseminacion => 'Inseminación',
    palpacion => 'Palpación',
    secado => 'Secado',
    parto => 'Parto',
    cambioGrupo => 'Cambio de grupo',
    baja => 'Baja',
    concentrado => 'Cambio de concentrado',
    observacion => 'Observación',
    _ => codigo,
  };
}

/// Resultado de una palpación / diagnóstico.
abstract final class ResultadoPalpacion {
  static const preniada = 'preñada';
  static const vacia = 'vacia';

  static const todos = [preniada, vacia];

  static String etiqueta(String codigo) => switch (codigo) {
    preniada => 'Preñada',
    vacia => 'Vacía',
    _ => codigo,
  };
}

/// Planes de licencia de la cuenta.
abstract final class PlanCuenta {
  static const invitado = 'invitado';
  static const light = 'light';
  static const medium = 'medium';
  static const pro = 'pro';

  static const todos = [invitado, light, medium, pro];
}

/// Estado de la cuenta.
abstract final class EstadoCuenta {
  static const activa = 'activa';
  static const suspendida = 'suspendida';
}

/// Rol de un miembro dentro de una lechería.
abstract final class RolMiembro {
  static const admin = 'admin';
  static const operario = 'operario';

  static const todos = [admin, operario];

  static String etiqueta(String codigo) => switch (codigo) {
    admin => 'Administrador',
    operario => 'Operario',
    _ => codigo,
  };
}
