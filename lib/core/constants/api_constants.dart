/// API endpoint path constants.
///
/// IMPORTANT: These are backend API paths — completely separate from Flutter
/// navigation route paths defined in [RoutePaths].
///
/// The [AppConfig.apiBaseUrl] is prepended automatically by [ApiClient].
/// Example: ApiEndpoints.login → POST /auth/login
class ApiEndpoints {
  ApiEndpoints._();

  // ─── Auth ─────────────────────────────────────────────────────────────────
  static const String login = '/auth/login';
  static const String me = '/auth/me';
  static const String logout = '/auth/logout';

  // ─── Dashboard ────────────────────────────────────────────────────────────
  static const String dashboard = '/dashboard';

  // ─── Customers ────────────────────────────────────────────────────────────
  static const String customers = '/customers';
  static String customerDetails(String id) => '/customers/$id';

  // ─── EMI Plans ────────────────────────────────────────────────────────────
  static String emiPlan(String id) => '/emi-plans/$id';

  // ─── Payments ─────────────────────────────────────────────────────────────
  static const String payments = '/payments';
  static String paymentDetails(String id) => '/payments/$id';

  // ─── Reports ──────────────────────────────────────────────────────────────
  static const String reportsSummary = '/reports/summary';
  static const String monthlyTrend = '/reports/monthly-trend';
  static const String weeklyCollection = '/reports/weekly-collection';
  static const String smartphoneBreakdown = '/reports/smartphones';

  // ─── Admin ────────────────────────────────────────────────────────────────
  static const String adminDashboard = '/admin/dashboard';
  static const String adminStores = '/admin/stores';
  static String adminStoreDetails(String id) => '/admin/stores/$id';
  static String adminStoreStatus(String id) => '/admin/stores/$id/status';
  static String adminStorePassword(String id) => '/admin/stores/$id/password';
  static String adminStoreTheme(String id) => '/admin/stores/$id/theme';
}
