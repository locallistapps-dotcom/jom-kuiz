/// App-wide, non-environment-specific constants.
abstract final class AppConstants {
  static const String appName = 'Jom Kuiz';

  static const Duration networkTimeout = Duration(seconds: 30);
  static const Duration snackBarDuration = Duration(seconds: 3);

  static const String defaultLocaleCode = 'en';
  static const List<String> supportedLocaleCodes = <String>['en', 'ms'];
}

/// Keys used for local persistence (secure storage / shared preferences).
///
/// Centralized so token/session code never hardcodes string keys inline.
abstract final class StorageKeys {
  static const String accessToken = 'auth_access_token';
  static const String refreshToken = 'auth_refresh_token';
  static const String tokenExpiresAt = 'auth_token_expires_at';
  static const String currentUserId = 'auth_current_user_id';
  static const String localeCode = 'settings_locale_code';
  static const String themeMode = 'settings_theme_mode';
}
