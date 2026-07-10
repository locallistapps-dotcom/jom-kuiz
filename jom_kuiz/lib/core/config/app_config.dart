/// Build-time / environment configuration.
///
/// Values are sourced from `--dart-define` flags so the same source can be
/// compiled against different backends (local, staging, production) without
/// code changes.
///
/// Example:
/// ```sh
/// flutter run --dart-define=API_BASE_URL=https://api.staging.jomkuiz.my
/// ```
abstract final class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.jomkuiz.my',
  );

  static const String environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static bool get isProduction => environment == 'production';
  static bool get isDevelopment => environment == 'development';
}
