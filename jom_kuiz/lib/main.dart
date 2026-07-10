import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/error/global_error_handler.dart';
import 'core/logger/app_logger.dart';
import 'jom_kuiz_app.dart';

/// Application entry point.
///
/// This file intentionally contains no feature logic. It only wires up:
/// - Global error handling (uncaught Flutter + platform errors)
/// - The Riverpod [ProviderScope] root
/// - The root [JomKuizApp] widget
///
/// Feature modules (auth, parent, child, quiz, etc.) are intentionally
/// NOT implemented here. They will be added in future prompts.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  GlobalErrorHandler.install(logger: AppLogger.instance);

  runApp(
    const ProviderScope(
      child: JomKuizApp(),
    ),
  );
}
