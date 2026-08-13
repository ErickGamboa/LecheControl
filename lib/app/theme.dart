import 'package:flutter/material.dart';

/// Colores de marca de LecheControl, tomados del logo (la vaca y el
/// tarro sobre la "LC"): el azul marino de la "L" manda y el verde de la
/// "C" acompaña. Están muestreados del archivo del ícono, no elegidos a
/// ojo, para que la app y su ícono se vean de la misma familia.
const Color kAzulLeche = Color(0xFF00234B); // azul marino de la "L"
const Color kVerdeLeche = Color(0xFF217030); // verde de la "C" y la hoja
const Color kAmbarLeche = Color(0xFFC98A00); // ámbar de apoyo, para avisos
const Color kCremaLeche = Color(0xFFF5F7FA); // fondo claro, azulado
const Color kCarbonLeche = Color(0xFF0B1220); // fondo oscuro, azulado

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

/// Tema visual de LecheControl, en claro y oscuro.
abstract final class LecheTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final claro = brightness == Brightness.light;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: kAzulLeche,
          brightness: brightness,
        ).copyWith(
          // En oscuro el marino y el verde del logo se hunden contra el
          // fondo, así que se usan versiones aclaradas de los mismos tonos.
          primary: claro ? kAzulLeche : const Color(0xFF8FB4E8),
          secondary: claro ? kVerdeLeche : const Color(0xFF6FCB7E),
          tertiary: claro ? kVerdeLeche : const Color(0xFF6FCB7E),
          error: claro ? kPeligro : const Color(0xFFFF8A8A),
          surface: claro ? kCremaLeche : kCarbonLeche,
        );

    final base = ThemeData(colorScheme: scheme, useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,

      // La barra va del color de la marca y con el título alineado a la
      // izquierda: en Android es lo que la gente espera.
      appBarTheme: AppBarTheme(
        backgroundColor: claro ? kAzulLeche : scheme.surfaceContainerHigh,
        foregroundColor: claro ? Colors.white : scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: false,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          color: claro ? Colors.white : scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Tarjetas planas con borde suave en vez de sombra: se ven más limpias
      // y no se ensucian unas con otras cuando van en lista.
      cardTheme: CardThemeData(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        color: claro ? Colors.white : scheme.surfaceContainerHigh,
        margin: const EdgeInsets.symmetric(vertical: LecheSpacing.xs),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LecheRadius.md),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),

      // Campos rellenos y sin borde duro: menos ruido visual en pantallas que
      // son casi puros formularios.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: claro ? Colors.white : scheme.surfaceContainerHighest,
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
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
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
        backgroundColor: claro ? kAzulLeche : scheme.primaryContainer,
        foregroundColor: claro ? Colors.white : scheme.onPrimaryContainer,
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
      textTheme: base.textTheme.copyWith(
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
