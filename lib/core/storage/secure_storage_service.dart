import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile_emi_manager/core/utils/logger.dart';

/// Secure storage service wrapping [FlutterSecureStorage].
///
/// Use this for sensitive data ONLY:
///   - Access token
///   - Refresh token (when implemented)
///
/// Never use this for non-sensitive preferences (use [LocalStorageService]).
/// Never access [FlutterSecureStorage] directly from widgets or BLoCs.
class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      AppLogger.error('SecureStorage read error for key "$key": $e');
      return null;
    }
  }

  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      AppLogger.error('SecureStorage write error for key "$key": $e');
    }
  }

  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      AppLogger.error('SecureStorage delete error for key "$key": $e');
    }
  }

  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      AppLogger.error('SecureStorage deleteAll error: $e');
    }
  }

  Future<bool> containsKey(String key) async {
    try {
      return await _storage.containsKey(key: key);
    } catch (e) {
      AppLogger.error('SecureStorage containsKey error for key "$key": $e');
      return false;
    }
  }
}
