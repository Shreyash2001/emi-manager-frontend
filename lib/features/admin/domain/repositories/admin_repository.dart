import 'package:mobile_emi_manager/features/admin/data/models/admin_models.dart';

abstract class AdminRepository {
  Future<AdminDashboardModel> getAdminDashboard();
  Future<StoreListResponse> listStores({int page = 1, int limit = 20, String? search});
  Future<StoreModel> createStore(CreateStoreRequestModel request);
}
