/// Keys used for local storage (SharedPreferences).
/// All storage access must use these constants — never raw strings.
class StorageKeys {
  StorageKeys._();

  // ─── Auth ─────────────────────────────────────────────────────────────────
  /// Stored in SecureStorage, NOT SharedPreferences.
  static const String accessToken = 'access_token';

  // ─── Preferences ──────────────────────────────────────────────────────────
  static const String selectedLocale = 'selected_locale';
  static const String themeMode = 'theme_mode';
  static const String onboardingComplete = 'onboarding_complete';

  // ─── User ─────────────────────────────────────────────────────────────────
  /// Cached user data (non-sensitive; stored in SharedPreferences).
  static const String cachedUser = 'cached_user';
}
