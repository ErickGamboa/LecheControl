import 'package:flutter/foundation.dart';

/// Flag de compilación para builds demo/tour (`--dart-define=LECHE_DEMO=...`).
///
/// [bool.fromEnvironment] solo trata el literal `true` como habilitado; los
/// scripts de shell muchas veces pasan `LECHE_DEMO=1`, así que aceptamos las
/// variantes comunes.
const _seedDemoRaw = String.fromEnvironment('LECHE_DEMO', defaultValue: '');

const _pidieronDemo =
    _seedDemoRaw == 'true' ||
    _seedDemoRaw == '1' ||
    _seedDemoRaw == 'yes' ||
    _seedDemoRaw == 'TRUE' ||
    _seedDemoRaw == 'YES';

/// Si la app tiene que sembrar y usar los datos de demostración.
///
/// **Pide el define Y que la build sea de depuración.** Las dos condiciones,
/// y la segunda no es paranoia: el modo demo, en cada arranque, siembra una
/// finca falsa, **le cierra la sesión al usuario** y activa una sesión demo
/// (ver `maybeSeedDemoOnStartup`). Eso en manos de un ganadero —o del revisor
/// de la tienda— es una app rota:
///
/// - Abre la app y aparece «Lechería Demo LecheControl» con animales que no
///   son suyos, en vez de su finca.
/// - Su sesión se cierra sola en cada arranque, así que nunca queda dentro.
/// - Y como no hay sesión, el sync no corre: la app se queda en
///   «Preparando tu cuenta…».
///
/// Pasó: una build de TestFlight salió con `LECHE_DEMO` puesto y costó varios
/// días entender por qué las cuentas «no funcionaban». Con `kDebugMode` de
/// por medio, una build de release o de perfil **ignora el define** y eso no
/// puede repetirse por un flag olvidado en un comando.
///
/// Para hacer una build demo de verdad hay que compilarla en modo debug, que
/// es donde el tour tiene sentido.
const kSeedDemoEnabled = _pidieronDemo && kDebugMode;

/// Si alguien pidió demo pero la build no lo permite. Sirve para avisarlo en
/// consola en vez de dejar la impresión de que el define funcionó.
const kDemoPedidoPeroIgnorado = _pidieronDemo && !kDebugMode;
