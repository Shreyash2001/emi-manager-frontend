import 'package:mobile_emi_manager/core/constants/api_constants.dart';
import 'package:mobile_emi_manager/core/network/api_client.dart';
import 'package:mobile_emi_manager/features/emi/data/models/emi_plan_model.dart';

abstract class EmiRemoteDataSource {
  Future<EmiPlanModel> getEmiPlan(String id);
}

class EmiRemoteDataSourceImpl implements EmiRemoteDataSource {
  final ApiClient _apiClient;

  EmiRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<EmiPlanModel> getEmiPlan(String id) async {
    final response = await _apiClient.get<EmiPlanModel>(
      ApiEndpoints.emiPlan(id),
      fromJson: (json) => EmiPlanModel.fromJson(json as Map<String, dynamic>),
    );
    return response.data!;
  }
}
