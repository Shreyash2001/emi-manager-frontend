import 'package:mobile_emi_manager/core/constants/api_constants.dart';
import 'package:mobile_emi_manager/core/network/api_client.dart';
import 'package:mobile_emi_manager/core/utils/logger.dart';
import 'package:mobile_emi_manager/features/dashboard/data/models/dashboard_model.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardModel> getDashboard();
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final ApiClient _apiClient;

  DashboardRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<DashboardModel> getDashboard() async {
    AppLogger.info('Calling API: GET ${ApiEndpoints.dashboard}');
    final response = await _apiClient.get<DashboardModel>(
      ApiEndpoints.dashboard,
      queryParameters: {'_t': DateTime.now().millisecondsSinceEpoch},
      fromJson: (json) => DashboardModel.fromJson(json as Map<String, dynamic>),
    );
    AppLogger.info(
      'API Response from ${ApiEndpoints.dashboard} | success=${response.success} | message=${response.message}',
    );
    return response.data!;
  }
}
