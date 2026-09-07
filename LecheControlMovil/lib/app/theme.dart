import 'package:flutter/material.dart';

/// Colores de marca de LecheControl, tomados del logo (la vaca y el
/// tarro sobre la "LC"): el azul marino de la "L" manda y el verde de la
/// "C" acompaña. Están muestreados del archivo del ícono, no elegidos a
/// ojo, para que la app y su ícono se vean de la misma familia.
const Color kAzulLeche = Color(0xFF082850); // azul marino de la "L"
const Color kVerdeLeche = Color(0xFF287038); // verde de la "C" y la hoja
const Color kAmbarLeche = Color(0xFFC98A00); // ámbar de apoyo, para avisos
const Color kCremaLeche = Color(0xFFF5F7FA); // fondo claro, azulado

/// El color de la letra que se escribe en los campos y de los títulos.
///
/// Va puesto a mano y no heredado del esquema: es lo único que garantiza que
/// lo que el ganadero digita se **vea**, tenga el teléfono el modo que tenga.
const Color kTintaLeche = Color(0xFF11161D);

/// Colores de estado, para no repetir `Colors.red.shade700` por toda la app.
const Color kExito = kVerdeLeche;
const Color kAviso = Color(0xFF9A6700);
const Color kPeligro = Color(0xFFC5303B);

/// Espaciados estándar de la app (múltiplos de 4).
abstract final class LecheSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
}

/// Radios de esquina. Generosos a propósito: es lo que separa una app que se
/// ve actual de una que se ve de 2015.
abstract final class LecheRadius {
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 22;
}

/// Tema visual de LecheControl. **Siempre claro.**
///
/// No hay tema oscuro y no es un olvido: la app se usa a pleno sol, en el
/// corral y en la lechería, y los fondos, los tintes de las tarjetas y los
/// colores de los gráficos están pensados para eso.
///
/// Antes seguía el modo del teléfono, y con el teléfono en oscuro pasaba lo
/// peor que puede pasar en una app de captura: las pantallas que pintan su
/// fondo blanco a mano —el login, las tarjetas— quedaban con letra clara
/// sobre blanco, y **lo que el ganadero digitaba no se veía**. Un dato que no
/// se lee mientras se escribe es un dato que se anota mal.
abstract final class LecheTheme {
  static ThemeData get light => _build();

  static ThemeData _build() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: kAzulLeche,
          brightness: Brightness.light,
        ).copyWith(
          primary: kAzulLeche,
          secondary: kVerdeLeche,
          tertiary: kVerdeLeche,
          error: kPeligro,
          surface: kCremaLeche,
          onSurface: kTintaLeche,
        );

    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      // El brillo del tema manda sobre el del sistema en todo lo que Flutter
      // no resuelve por el esquema de color: el cursor, las manijas de
      // selección, el fondo de los menús emergentes.
      brightness: Brightness.light,
    );

    // Cada estilo de texto sale con su color escrito, no heredado.
    //
    // Es la red que ataja el problema de raíz: un `Text` o un `TextField` sin
    // color propio lo toma del tema de más cerca, y basta un widget que herede
    // de otro lado para que la letra salga clara sobre blanco. Con el color
    // puesto en todos los estilos, eso no puede pasar en ninguna pantalla.
    final textos = base.textTheme.apply(
      bodyColor: kTintaLeche,
      displayColor: kTintaLeche,
    );

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,

      // La barra va del color de la marca y con el título alineado a la
      // izquierda: en Android es lo que la gente espera.
      appBarTheme: AppBarTheme(
        backgroundColor: kAzulLeche,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: false,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Tarjetas planas con borde suave en vez de sombra: se ven más limpias
      // y no se ensucian unas con otras cuando van en lista.
      cardTheme: CardThemeData(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        color: Colors.white,
        margin: const EdgeInsets.symmetric(vertical: LecheSpacing.xs),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LecheRadius.md),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),

      // Lo que se digita: fondo blanco y letra oscura, dichos los dos a mano.
      //
      // El relleno blanco ya estaba; lo que faltaba era el color de la letra.
      // Sin él, el campo se pintaba blanco y el texto salía del tema, así que
      // con el teléfono en oscuro quedaba gris clarito sobre blanco y **no se
      // leía lo que se estaba escribiendo**. En una app donde todo el trabajo
      // es digitar en el corral, eso es un dato mal anotado.
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: kAzulLeche,
        selectionHandleColor: kAzulLeche,
      ),

      // Campos rellenos y sin borde duro: menos ruido visual en pantallas que
      // son casi puros formularios.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        // El rótulo y la pista van más tenues que la letra que se digita, pero
        // los dos oscuros: nunca al revés.
        labelStyle: TextStyle(color: kTintaLeche.withValues(alpha: 0.70)),
        floatingLabelStyle: const TextStyle(color: kAzulLeche),
        hintStyle: TextStyle(color: kTintaLeche.withValues(alpha: 0.45)),
        prefixStyle: const TextStyle(color: kTintaLeche),
        suffixStyle: const TextStyle(color: kTintaLeche),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: LecheSpacing.lg,
          vertical: LecheSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LecheRadius.sm),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LecheRadius.sm),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LecheRadius.sm),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),

      // Botones altos: se usan con las manos ocupadas y a veces con guantes.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LecheRadius.sm),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LecheRadius.sm),
          ),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: kAzulLeche,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LecheRadius.md),
        ),
      ),

      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LecheRadius.lg),
        ),
        side: BorderSide(color: scheme.outlineVariant),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(LecheRadius.lg),
          ),
        ),
      ),

      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LecheRadius.md),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LecheRadius.sm),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.6),
        space: 1,
        thickness: 1,
      ),

      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LecheRadius.sm),
        ),
      ),

      // Números un poco más apretados y con más peso: la app muestra muchas
      // cifras y así se leen de un vistazo.
      textTheme: textos.copyWith(
        titleLarge: textos.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        titleMedium: textos.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        headlineSmall: textos.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
