/// App-wide constant values.
class AppConstants {
  AppConstants._();

  // ─── Pagination ───────────────────────────────────────────────────────────
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  static const int firstPage = 1;

  // ─── Timeouts ─────────────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // ─── Search ───────────────────────────────────────────────────────────────
  static const Duration searchDebounce = Duration(milliseconds: 500);
  static const int minSearchLength = 2;

  // ─── Validation ───────────────────────────────────────────────────────────
  static const int mobileNumberLength = 10;
  static const int minPasswordLength = 6;
  static const double minAmount = 0.01;

  // ─── Currency ─────────────────────────────────────────────────────────────
  static const String currencySymbol = '₹';
  static const String currencyCode = 'INR';

  // ─── Date Formats ─────────────────────────────────────────────────────────
  static const String displayDateFormat = 'dd MMM yyyy';
  static const String apiDateFormat = 'yyyy-MM-dd';
  static const String displayMonthFormat = 'MMM yyyy';
  static const String displayDateTimeFormat = 'dd MMM yyyy, hh:mm a';

  // ─── App ──────────────────────────────────────────────────────────────────
  static const String defaultAvatarPath = 'assets/images/default_avatar.png';
  static const String appVersion = '1.0.0';
}
