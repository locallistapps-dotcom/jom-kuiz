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
  /// PostgREST REST API base URL.
  /// Set via `--dart-define=API_BASE_URL=https://<ref>.supabase.co/rest/v1`.
  /// Defaults to `{supabaseUrl}/rest/v1` at runtime if not explicitly provided.
  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get apiBaseUrl =>
      _apiBaseUrlOverride.isNotEmpty ? _apiBaseUrlOverride : '$supabaseUrl/rest/v1';

  /// Supabase project root URL — `https://<project-ref>.supabase.co`.
  /// Set via `--dart-define=SUPABASE_URL=https://<ref>.supabase.co`.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  /// Supabase anonymous (publishable) key.
  /// Safe to embed in client apps. Set via `--dart-define=SUPABASE_ANON_KEY=eyJ...`.
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
