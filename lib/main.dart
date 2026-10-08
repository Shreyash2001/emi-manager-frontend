import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_emi_manager/app/app.dart';
import 'package:mobile_emi_manager/app/config/app_config.dart';
import 'package:mobile_emi_manager/core/di/injection_container.dart';
import 'package:mobile_emi_manager/core/utils/logger.dart';

/// Application entry point.
///
/// Order of initialization:
///   1. Flutter binding
///   2. Read environment configuration
///   3. Configure logger
///   4. Initialize dependency injection
///   5. Run the app
///
/// No business logic belongs here.
Future<void> main() async {
  // 1. Ensure Flutter is initialized before calling platform APIs.
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Lock orientation to portrait (mobile-first).
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 3. Load environment-specific configuration from --dart-define.
  final config = AppConfig.fromEnvironment();

  // 4. Configure centralized logger.
  AppLogger.configure(enableLogging: config.enableLogging);
  AppLogger.info('Starting EMI Manager — ${config.environment}');
  AppLogger.info('API Base URL: ${config.apiBaseUrl}');

  // 5. Initialize all dependencies via DI container.
  await initializeDependencies(config);

  // 6. Set up global Flutter error handler.
  FlutterError.onError = (details) {
    AppLogger.error(
      'Unhandled Flutter error',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  // 7. Run the app.
  runApp(const App());
}
