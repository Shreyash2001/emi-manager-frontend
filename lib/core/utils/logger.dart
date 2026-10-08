import 'package:flutter/foundation.dart';

/// Centralized logger for the application.
///
/// Rules:
///   - Development: all levels enabled
///   - Production: no debug/info/network logs; only errors are optionally captured
///   - NEVER log: passwords, tokens, sensitive customer/payment data
///
/// Usage:
///   AppLogger.debug('User tapped login button');
///   AppLogger.error('API failed', error: e, stackTrace: st);
class AppLogger {
  AppLogger._();

  static bool _enabled = kDebugMode;

  static void configure({required bool enableLogging}) {
    _enabled = enableLogging;
  }

  static void debug(String message) {
    if (_enabled) {
      debugPrint('[DEBUG] $message');
    }
  }

  static void info(String message) {
    if (_enabled) {
      debugPrint('[INFO]  $message');
    }
  }

  static void warning(String message) {
    if (_enabled) {
      debugPrint('[WARN]  $message');
    }
  }

  static void network(String message) {
    if (_enabled) {
      debugPrint('[NET]   $message');
    }
  }

  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    // Errors are always logged (even in production via crash reporting).
    debugPrint('[ERROR] $message${error != null ? '\n  $error' : ''}');
    if (stackTrace != null && _enabled) {
      debugPrint('[STACK] $stackTrace');
    }
  }

  static void bloc(String blocName, String event) {
    if (_enabled) {
      debugPrint('[BLOC]  $blocName → $event');
    }
  }
}
