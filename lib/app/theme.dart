import 'package:flutter/material.dart';

/// Colores de marca de LecheControl: blanco leche/crema + verde/teal profundo
/// (nada de morado — se aleja a propósito de la paleta de HatoControl).
const Color kVerdeLeche = Color(0xFF0E6B5C); // teal profundo, color primario
const Color kAzulLeche = Color(0xFF2E5F6B); // azul grisáceo, color secundario
const Color kCremaLeche = Color(0xFFFFF8ED); // blanco leche/crema de fondo

/// Espaciados estándar de la app (múltiplos de 4).
abstract final class LecheSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
}

/// Tema visual de LecheControl: mismo esquema de color en claro y oscuro,
/// generado a partir de los colores de marca (crema + verde lechero).
abstract final class LecheTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: kVerdeLeche,
      primary: kVerdeLeche,
      secondary: kAzulLeche,
      tertiary: kAzulLeche,
      brightness: brightness,
      surface: brightness == Brightness.light ? kCremaLeche : null,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: brightness == Brightness.light
          ? kCremaLeche
          : null,
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: kVerdeLeche,
        foregroundColor: Colors.white,
      ),
      cardTheme: const CardThemeData(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.all(LecheSpacing.xs),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}
