/// Route name constants for use throughout the application.
/// These are semantic identifiers, not URL paths.
/// See [RoutePaths] for the actual URL path strings.
class RouteNames {
  RouteNames._();

  static const splash = 'splash';
  static const login = 'login';
  static const dashboard = 'dashboard';

  // Customers
  static const customers = 'customers';
  static const addCustomer = 'addCustomer';
  static const addDevice = 'addDevice';
  static const customerDetails = 'customerDetails';

  // EMI
  static const addEmi = 'addEmi';
  static const emiDetails = 'emiDetails';

  // Payments
  static const payments = 'payments';
  static const recordPayment = 'recordPayment';
  static const paymentDetails = 'paymentDetails';

  // Reports
  static const reports = 'reports';

  // Profile
  static const profile = 'profile';

  // Admin
  static const admin = 'admin';
  static const adminStores = 'adminStores';
  static const adminStoreDetails = 'adminStoreDetails';
}
