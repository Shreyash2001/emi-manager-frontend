import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_emi_manager/core/utils/logger.dart';

/// Local storage service wrapping [SharedPreferences].
///
/// Use this for non-sensitive data only:
///   - Selected locale
///   - Theme preference
///   - Onboarding flags
///
/// For sensitive data (tokens), use [SecureStorageService].
/// Never access [SharedPreferences] directly from widgets or BLoCs.
class LocalStorageService {
  final SharedPreferences _prefs;

  LocalStorageService({required SharedPreferences prefs}) : _prefs = prefs;

  // ─── String ───────────────────────────────────────────────────────────────

  String? getString(String key) {
    try {
      return _prefs.getString(key);
    } catch (e) {
      AppLogger.error('LocalStorage getString error for "$key": $e');
      return null;
    }
  }

  Future<bool> setString(String key, String value) async {
    try {
      return await _prefs.setString(key, value);
    } catch (e) {
      AppLogger.error('LocalStorage setString error for "$key": $e');
      return false;
    }
  }

  // ─── Bool ─────────────────────────────────────────────────────────────────

  bool? getBool(String key) {
    try {
      return _prefs.getBool(key);
    } catch (e) {
      AppLogger.error('LocalStorage getBool error for "$key": $e');
      return null;
    }
  }

  Future<bool> setBool(String key, {required bool value}) async {
    try {
      return await _prefs.setBool(key, value);
    } catch (e) {
      AppLogger.error('LocalStorage setBool error for "$key": $e');
      return false;
    }
  }

  // ─── Int ──────────────────────────────────────────────────────────────────

  int? getInt(String key) {
    try {
      return _prefs.getInt(key);
    } catch (e) {
      AppLogger.error('LocalStorage getInt error for "$key": $e');
      return null;
    }
  }

  Future<bool> setInt(String key, int value) async {
    try {
      return await _prefs.setInt(key, value);
    } catch (e) {
      AppLogger.error('LocalStorage setInt error for "$key": $e');
      return false;
    }
  }

  // ─── Remove / Clear ───────────────────────────────────────────────────────

  Future<bool> remove(String key) async {
    try {
      return await _prefs.remove(key);
    } catch (e) {
      AppLogger.error('LocalStorage remove error for "$key": $e');
      return false;
    }
  }

  Future<bool> clear() async {
    try {
      return await _prefs.clear();
    } catch (e) {
      AppLogger.error('LocalStorage clear error: $e');
      return false;
    }
  }

  bool containsKey(String key) => _prefs.containsKey(key);
}
