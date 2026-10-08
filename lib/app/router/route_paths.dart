/// Route path constants — the actual URL segments used by go_router.
/// Keep these separate from [RouteNames] (semantic identifiers) and
/// from backend API paths defined in [ApiEndpoints].
class RoutePaths {
  RoutePaths._();

  static const splash = '/';
  static const login = '/login';
  static const dashboard = '/dashboard';

  // Customers
  static const customers = '/customers';
  static const addCustomer = '/customers/add';
  static const addDevice = '/customers/add-device';
  static const customerDetails = '/customers/:customerId';

  // EMI
  static const addEmi = '/emi/add';
  static const emiDetails = '/emi/:emiPlanId';

  // Payments
  static const payments = '/payments';
  static const recordPayment = '/payments/record';
  static const paymentDetails = '/payments/:paymentId';

  // Reports
  static const reports = '/reports';

  // Profile
  static const profile = '/profile';

  // Admin
  static const admin = '/admin';
  static const adminStores = '/admin/stores';
  static const adminStoreDetails = '/admin/stores/:storeId';
}
