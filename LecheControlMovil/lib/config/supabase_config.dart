/// Configuración de conexión a Supabase para LecheControl.
///
/// LecheControl usa SU PROPIO proyecto de Supabase (`yskvlaovqvjfodiroaqz`),
/// no el de HatoControl (`geocoundyilwxrnbhcqu`).
///
/// Los valores por defecto apuntan al proyecto real, igual que en HatoControl:
/// así la app queda conectada apenas se abre, sin depender de `--dart-define`.
/// Esto es necesario para builds instalados (un APK en el teléfono de un
/// finquero no recibe defines en tiempo de compilación).
///
/// La clave `anon` es PÚBLICA por diseño: está pensada para ir embebida en
/// apps cliente y es extraíble de cualquier APK. La seguridad real la dan las
/// políticas RLS de la base de datos, no esta clave. (Nunca pongas aquí la
/// "service_role key".)
///
/// Se pueden sobreescribir por `--dart-define` para apuntar a otro proyecto
/// (por ejemplo un staging), sin tocar este archivo:
///
/// ```bash
/// flutter run \
///   --dart-define=LECHE_SUPABASE_URL=https://OTRO-PROYECTO.supabase.co \
///   --dart-define=LECHE_SUPABASE_ANON_KEY=OTRA_ANON_KEY
/// ```
class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'LECHE_SUPABASE_URL',
    defaultValue: 'https://yskvlaovqvjfodiroaqz.supabase.co',
  );
  static const String anonKey = String.fromEnvironment(
    'LECHE_SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inlza3ZsYW92cXZqZm9kaXJvYXF6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODUzNDQ0MzcsImV4cCI6MjEwMDkyMDQzN30.UFrbCtXII6GGG91VJ95WeJXiVdSPHIuWQIuWA24E-wg',
  );

  /// True cuando hay configuración suficiente para inicializar Supabase.
  /// `app_bootstrap.dart` usa esto para saltarse `Supabase.initialize` y
  /// dejar la app funcionando en modo offline/demo. Con los valores por
  /// defecto de arriba esto es siempre true; sólo da false si alguien pasa
  /// un `--dart-define` vacío a propósito.
  static bool get estaConfigurado => url.isNotEmpty && anonKey.isNotEmpty;
}
