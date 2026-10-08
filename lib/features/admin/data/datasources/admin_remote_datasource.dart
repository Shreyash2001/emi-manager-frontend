import 'package:mobile_emi_manager/core/constants/api_constants.dart';
import 'package:mobile_emi_manager/core/network/api_client.dart';
import 'package:mobile_emi_manager/features/admin/data/models/admin_models.dart';

abstract class AdminRemoteDataSource {
  Future<AdminDashboardModel> getAdminDashboard();
  Future<StoreListResponse> listStores({int page = 1, int limit = 20, String? search});
  Future<StoreModel> createStore(CreateStoreRequestModel request);
}

class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  final ApiClient _apiClient;

  AdminRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<AdminDashboardModel> getAdminDashboard() async {
    final response = await _apiClient.get<AdminDashboardModel>(
      ApiEndpoints.adminDashboard,
      fromJson: (json) =>
          AdminDashboardModel.fromJson(json as Map<String, dynamic>),
    );
    return response.data!;
  }

  @override
  Future<StoreListResponse> listStores({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
    };

    final response = await _apiClient.get<StoreListResponse>(
      ApiEndpoints.adminStores,
      queryParameters: queryParams,
      fromJson: (json) =>
          StoreListResponse.fromJson(json as Map<String, dynamic>),
    );
    return response.data!;
  }

  @override
  Future<StoreModel> createStore(CreateStoreRequestModel request) async {
    final response = await _apiClient.post<StoreModel>(
      ApiEndpoints.adminStores,
      data: request.toJson(),
      fromJson: (json) => StoreModel.fromJson(json as Map<String, dynamic>),
    );
    return response.data!;
  }
}
