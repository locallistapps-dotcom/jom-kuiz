/// Build-time / environment configuration via `--dart-define` flags.
///
/// Compile against different backends without code changes:
/// ```sh
/// flutter run \
///   --dart-define=API_BASE_URL=https://xxx.supabase.co/rest/v1 \
///   --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=eyJh...
/// ```
abstract final class AppConfig {
  /// PostgREST REST API base URL (e.g. `/questions`, `/admin_content`).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.jomkuiz.my',
  );

  /// Supabase project root URL — used for Storage and non-REST endpoints.
  /// Typically `https://<project-ref>.supabase.co`.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://api.jomkuiz.my',
  );

  /// Supabase anonymous/public API key — used as `apikey` header for
  /// Storage calls. Safe to embed in client apps (not a secret).
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static const String environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static bool get isProduction => environment == 'production';
  static bool get isDevelopment => environment == 'development';
}
