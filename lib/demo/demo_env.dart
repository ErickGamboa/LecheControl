/// Flag de compilación para builds demo/tour (`--dart-define=LECHE_DEMO=...`).
///
/// [bool.fromEnvironment] solo trata el literal `true` como habilitado; los
/// scripts de shell muchas veces pasan `LECHE_DEMO=1`, así que aceptamos las
/// variantes comunes.
const _seedDemoRaw = String.fromEnvironment('LECHE_DEMO', defaultValue: '');

const kSeedDemoEnabled =
    _seedDemoRaw == 'true' ||
    _seedDemoRaw == '1' ||
    _seedDemoRaw == 'yes' ||
    _seedDemoRaw == 'TRUE' ||
    _seedDemoRaw == 'YES';
