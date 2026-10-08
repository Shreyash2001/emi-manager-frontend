import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mobile_emi_manager/core/storage/local_storage_service.dart';
import 'package:mobile_emi_manager/core/constants/storage_keys.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class ThemeState extends Equatable {
  final ThemeMode themeMode;

  const ThemeState({required this.themeMode});

  @override
  List<Object?> get props => [themeMode];
}

// ─── Cubit ────────────────────────────────────────────────────────────────────

/// Manages the app-wide theme preference (light / dark / system).
/// This is a Cubit because theme switching is simple and event-free.
class ThemeCubit extends Cubit<ThemeState> {
  final LocalStorageService _storage;

  ThemeCubit({required LocalStorageService storage})
      : _storage = storage,
        super(const ThemeState(themeMode: ThemeMode.system));

  /// Load persisted theme preference on startup.
  Future<void> loadTheme() async {
    final saved = _storage.getString(StorageKeys.themeMode);
    final mode = _themeModeFromString(saved);
    emit(ThemeState(themeMode: mode));
  }

  Future<void> setLight() => _setTheme(ThemeMode.light);
  Future<void> setDark() => _setTheme(ThemeMode.dark);
  Future<void> setSystem() => _setTheme(ThemeMode.system);

  Future<void> _setTheme(ThemeMode mode) async {
    await _storage.setString(StorageKeys.themeMode, mode.name);
    emit(ThemeState(themeMode: mode));
  }

  ThemeMode _themeModeFromString(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
