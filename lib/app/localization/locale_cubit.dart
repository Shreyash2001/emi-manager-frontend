import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mobile_emi_manager/app/localization/app_localizations.dart';
import 'package:mobile_emi_manager/core/storage/local_storage_service.dart';
import 'package:mobile_emi_manager/core/constants/storage_keys.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class LocaleState extends Equatable {
  final Locale locale;

  const LocaleState({required this.locale});

  @override
  List<Object?> get props => [locale];
}

// ─── Cubit ────────────────────────────────────────────────────────────────────

/// Manages the app-wide locale (language) with persistence.
/// Cubit is appropriate because locale switching is simple UI-level state.
class LocaleCubit extends Cubit<LocaleState> {
  final LocalStorageService _storage;

  LocaleCubit({required LocalStorageService storage})
      : _storage = storage,
        super(const LocaleState(locale: SupportedLocales.english));

  /// Load the persisted locale from storage on app start.
  Future<void> loadLocale() async {
    final saved = _storage.getString(StorageKeys.selectedLocale);
    if (saved != null) {
      final locale = _findLocale(saved);
      emit(LocaleState(locale: locale));
    }
  }

  Future<void> setEnglish() => _setLocale(SupportedLocales.english);
  Future<void> setHindi() => _setLocale(SupportedLocales.hindi);
  Future<void> setMarathi() => _setLocale(SupportedLocales.marathi);

  Future<void> setLocale(Locale locale) => _setLocale(locale);

  Future<void> _setLocale(Locale locale) async {
    await _storage.setString(StorageKeys.selectedLocale, locale.languageCode);
    emit(LocaleState(locale: locale));
  }

  Locale _findLocale(String languageCode) {
    return SupportedLocales.all.firstWhere(
      (l) => l.languageCode == languageCode,
      orElse: () => SupportedLocales.english,
    );
  }
}
