import 'package:flutter/foundation.dart';

import '../logger/app_logger.dart';

/// Installs process-wide handlers for uncaught Flutter framework errors and
/// uncaught async errors outside the Flutter framework (platform channels,
/// isolates, etc.).
///
/// Call [install] once, before `runApp`. Does not implement crash reporting
/// (Sentry/Crashlytics) yet -- wire that in here when a provider is chosen.
abstract final class GlobalErrorHandler {
  static void install({required AppLogger logger}) {
    FlutterError.onError = (FlutterErrorDetails details) {
      logger.error(
        'Uncaught Flutter error',
        error: details.exception,
        stackTrace: details.stack,
      );
      FlutterError.presentError(details);
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      logger.error('Uncaught platform error', error: error, stackTrace: stack);
      return true;
    };
  }
}
