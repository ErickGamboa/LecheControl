/// Configuración de conexión a Supabase para LecheControl.
///
/// LecheControl usa SU PROPIO proyecto de Supabase (no el de HatoControl).
/// Por defecto estos valores están vacíos: la app se puede compilar y correr
/// sin conexión (modo offline/demo, ver `lib/demo/demo_env.dart`) mientras el
/// proyecto de Supabase todavía no se crea.
///
/// Para conectar a un proyecto real, pasá los valores por `--dart-define` (no
/// los hardcodees en este archivo si el repo es público):
///
/// ```bash
/// flutter run \
///   --dart-define=LECHE_SUPABASE_URL=https://TU-PROYECTO.supabase.co \
///   --dart-define=LECHE_SUPABASE_ANON_KEY=TU_ANON_KEY
/// ```
///
/// La clave `anon` es PÚBLICA por diseño: está pensada para ir embebida en
/// apps cliente. La seguridad real la dan las políticas RLS de la base de
/// datos, no esta clave. (Nunca pongas aquí la "service_role key".)
class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'LECHE_SUPABASE_URL',
    defaultValue: '',
  );
  static const String anonKey = String.fromEnvironment(
    'LECHE_SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// True cuando hay configuración suficiente para inicializar Supabase.
  /// `app_bootstrap.dart` usa esto para saltarse `Supabase.initialize` y
  /// dejar la app funcionando en modo offline/demo sin proyecto todavía.
  static bool get estaConfigurado => url.isNotEmpty && anonKey.isNotEmpty;
}
