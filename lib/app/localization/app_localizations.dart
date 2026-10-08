import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_emi_manager/core/utils/logger.dart';

/// Loads translations from JSON asset files.
/// Implements [LocalizationsDelegate] so Flutter's localization system
/// can use it automatically.
class AppLocalizations {
  final Locale locale;
  late Map<String, String> _translations;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  Future<void> load() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/translations/${locale.languageCode}.json',
      );
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      _translations = jsonMap.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      AppLogger.warning('Failed to load translations for ${locale.languageCode}: $e');
      _translations = {};
    }
  }

  /// Look up a translation by key. Falls back to the key itself if not found.
  String translate(String key) {
    return _translations[key] ?? key;
  }

  // ─── Convenience Getters ─────────────────────────────────────────────────
  String get appName => translate('appName');
  String get login => translate('login');
  String get logout => translate('logout');
  String get mobileNumber => translate('mobileNumber');
  String get password => translate('password');
  String get enterMobileNumber => translate('enterMobileNumber');
  String get enterPassword => translate('enterPassword');
  String get invalidCredentials => translate('invalidCredentials');
  String get loginFailed => translate('loginFailed');
  String get dashboard => translate('dashboard');
  String get customers => translate('customers');
  String get payments => translate('payments');
  String get reports => translate('reports');
  String get profile => translate('profile');
  String get emiPlans => translate('emiPlans');
  String get admin => translate('admin');
  String get stores => translate('stores');
  String get loading => translate('loading');
  String get retry => translate('retry');
  String get noData => translate('noData');
  String get noCustomers => translate('noCustomers');
  String get noPayments => translate('noPayments');
  String get noEmiPlans => translate('noEmiPlans');
  String get noReports => translate('noReports');
  String get errorOccurred => translate('errorOccurred');
  String get networkError => translate('networkError');
  String get serverError => translate('serverError');
  String get authenticationError => translate('authenticationError');
  String get authorizationError => translate('authorizationError');
  String get validationError => translate('validationError');
  String get unknownError => translate('unknownError');
  String get requiredField => translate('requiredField');
  String get invalidMobileNumber => translate('invalidMobileNumber');
  String get invalidPassword => translate('invalidPassword');
  String get invalidEmail => translate('invalidEmail');
  String get invalidAmount => translate('invalidAmount');
  String get search => translate('search');
  String get filter => translate('filter');
  String get refresh => translate('refresh');
  String get save => translate('save');
  String get cancel => translate('cancel');
  String get confirm => translate('confirm');
  String get delete => translate('delete');
  String get edit => translate('edit');
  String get add => translate('add');
  String get view => translate('view');
  String get back => translate('back');
  String get next => translate('next');
  String get done => translate('done');
  String get close => translate('close');
  String get yes => translate('yes');
  String get no => translate('no');
  String get ok => translate('ok');
  String get settings => translate('settings');
  String get language => translate('language');
  String get theme => translate('theme');
  String get lightMode => translate('lightMode');
  String get darkMode => translate('darkMode');
  String get systemDefault => translate('systemDefault');
  String get english => translate('english');
  String get hindi => translate('hindi');
  String get marathi => translate('marathi');
  String get totalCustomers => translate('totalCustomers');
  String get totalPayments => translate('totalPayments');
  String get totalCollection => translate('totalCollection');
  String get pendingPayments => translate('pendingPayments');
  String get overduePayments => translate('overduePayments');
  String get welcomeBack => translate('welcomeBack');
  String get sessionExpired => translate('sessionExpired');
  String get noInternetConnection => translate('noInternetConnection');
  String get checkConnection => translate('checkConnection');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      SupportedLocales.all.any((l) => l.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// All locales supported by the application.
class SupportedLocales {
  SupportedLocales._();

  static const Locale english = Locale('en');
  static const Locale hindi = Locale('hi');
  static const Locale marathi = Locale('mr');

  static const List<Locale> all = [english, hindi, marathi];
}
