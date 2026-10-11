import 'package:flutter/foundation.dart';

/// Environment enum defining supported deployment environments.
enum Environment { development, staging, production }

/// AppConfig holds all environment-specific configuration.
///
/// Usage:
///   flutter run --dart-define=ENV=development
///   flutter run --dart-define=API_URL=http://192.168.1.100:5000/api/v1
class AppConfig {
  final Environment environment;
  final String apiBaseUrl;
  final String appName;
  final bool enableLogging;
  final Duration requestTimeout;
  final Duration connectTimeout;
  final Duration cacheTtl;

  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.appName,
    required this.enableLogging,
    required this.requestTimeout,
    required this.connectTimeout,
    this.cacheTtl = const Duration(minutes: 15),
  });

  /// Factory constructor that reads `--dart-define=ENV=value`
  factory AppConfig.fromEnvironment() {
    const env = String.fromEnvironment('ENV', defaultValue: 'development');
    switch (env) {
      case 'production':
        return AppConfig._production();
      case 'staging':
        return AppConfig._staging();
      default:
        return AppConfig._development();
    }
  }

  static String get _devApiBaseUrl {
    const customUrl = String.fromEnvironment('API_URL');
    if (customUrl.isNotEmpty) return customUrl;

    // Android Emulators map host's localhost to 10.0.2.2
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      // return 'http://10.0.2.2:5000/api/v1';
      return 'https://emi-manager-backend-ten.vercel.app/api/v1';
    }
    // return 'http://127.0.0.1:5000/api/v1';
    return 'https://emi-manager-backend-ten.vercel.app/api/v1';
  }

  factory AppConfig._development() => AppConfig(
    environment: Environment.development,
    apiBaseUrl: _devApiBaseUrl,
    appName: 'EMI Manager (Dev)',
    enableLogging: true,
    requestTimeout: const Duration(seconds: 30),
    connectTimeout: const Duration(seconds: 15),
    cacheTtl: const Duration(minutes: 15),
  );

  factory AppConfig._staging() => const AppConfig(
    environment: Environment.staging,
    apiBaseUrl: 'https://staging-api.example.com/api/v1',
    appName: 'EMI Manager (Staging)',
    enableLogging: true,
    requestTimeout: Duration(seconds: 30),
    connectTimeout: Duration(seconds: 15),
    cacheTtl: Duration(minutes: 15),
  );

  factory AppConfig._production() => const AppConfig(
    environment: Environment.production,
    apiBaseUrl: 'https://api.example.com/api/v1',
    appName: 'EMI Manager',
    enableLogging: false,
    requestTimeout: Duration(seconds: 30),
    connectTimeout: Duration(seconds: 15),
    cacheTtl: Duration(minutes: 15),
  );

  bool get isDevelopment => environment == Environment.development;
  bool get isStaging => environment == Environment.staging;
  bool get isProduction => environment == Environment.production;

  @override
  String toString() =>
      'AppConfig(env: $environment, apiBaseUrl: $apiBaseUrl, logging: $enableLogging)';
}
