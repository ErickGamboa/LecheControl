/// Constantes de dominio de LecheControl: grupos del hato, sexos, orígenes,
/// motivos de baja y estados reproductivos. Los valores (códigos) son los que
/// se guardan en la base local y en Supabase; las etiquetas son para la UI.
library;

/// Grupos/estados del hato (Módulo 1 y 2). Sin grupos libres ni de toros.
abstract final class GrupoAnimal {
  static const enOrdeno = 'en_ordeno';
  static const secas = 'secas';
  static const novillas = 'novillas';
  static const terneros = 'terneros';
  static const enTratamiento = 'en_tratamiento';

  static const todos = [enOrdeno, secas, novillas, terneros, enTratamiento];

  /// Grupos donde se puede dar de alta un animal nuevo (no incluye
  /// "en tratamiento", que se llega solo por evento sanitario).
  static const altaDisponibles = [enOrdeno, secas, novillas, terneros];

  static String etiqueta(String codigo) => switch (codigo) {
    enOrdeno => 'En ordeño',
    secas => 'Secas',
    novillas => 'Novillas',
    terneros => 'Terneros',
    enTratamiento => 'En tratamiento',
    _ => codigo,
  };
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

/// Tipo de dosis de un medicamento (Módulo 7).
abstract final class TipoDosisMedicamento {
  static const fija = 'fija';
  static const porAplicacion = 'por_aplicacion';

  static const todos = [fija, porAplicacion];

  static String etiqueta(String codigo) => switch (codigo) {
    fija => 'Dosis fija (ml)',
    porAplicacion => 'Por aplicación',
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
