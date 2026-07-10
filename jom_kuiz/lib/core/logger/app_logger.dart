import 'package:logger/logger.dart' as pkg;

/// Thin wrapper around the `logger` package so the rest of the app depends
/// on this app-owned API instead of the third-party package directly.
///
/// Usage:
/// ```dart
/// AppLogger.instance.debug('Fetched profile');
/// AppLogger.instance.error('Login failed', error: e, stackTrace: st);
/// ```
class AppLogger {
  AppLogger._(this._logger);

  static final AppLogger instance = AppLogger._(
    pkg.Logger(
      printer: pkg.PrettyPrinter(
        methodCount: 1,
        errorMethodCount: 8,
        lineLength: 100,
        colors: true,
        printEmojis: false,
      ),
    ),
  );

  final pkg.Logger _logger;

  void debug(String message) => _logger.d(message);

  void info(String message) => _logger.i(message);

  void warning(String message) => _logger.w(message);

  void error(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
}
