import 'package:mobile_emi_manager/core/constants/api_constants.dart';
import 'package:mobile_emi_manager/core/network/api_client.dart';
import 'package:mobile_emi_manager/core/utils/logger.dart';
import 'package:mobile_emi_manager/features/auth/data/models/login_request_model.dart';
import 'package:mobile_emi_manager/features/auth/data/models/login_response_model.dart';
import 'package:mobile_emi_manager/features/auth/data/models/user_model.dart';

/// Remote data source for authentication API calls.
/// Knows about HTTP endpoints and response models — no business logic.
abstract class AuthRemoteDataSource {
  Future<LoginResponseModel> login(LoginRequestModel request);
  Future<UserModel> getCurrentUser();
  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<LoginResponseModel> login(LoginRequestModel request) async {
    AppLogger.info('Calling Auth API: POST ${ApiEndpoints.login}');
    final response = await _apiClient.post<LoginResponseModel>(
      ApiEndpoints.login,
      data: request.toJson(),
      fromJson: (json) =>
          LoginResponseModel.fromJson(json as Map<String, dynamic>),
    );
    AppLogger.info(
      'Auth API Response from ${ApiEndpoints.login} | success=${response.success} | message=${response.message}',
    );
    return response.data!;
  }

  @override
  Future<UserModel> getCurrentUser() async {
    AppLogger.info('Calling Auth API: GET ${ApiEndpoints.me}');
    final response = await _apiClient.get<UserModel>(
      ApiEndpoints.me,
      fromJson: (json) => UserModel.fromJson(json as Map<String, dynamic>),
    );
    AppLogger.info(
      'Auth API Response from ${ApiEndpoints.me} | success=${response.success} | user=${response.data?.name}',
    );
    return response.data!;
  }

  @override
  Future<void> logout() async {
    AppLogger.info('Calling Auth API: POST ${ApiEndpoints.logout}');
    final response = await _apiClient.post<void>(ApiEndpoints.logout);
    AppLogger.info(
      'Auth API Response from ${ApiEndpoints.logout} | success=${response.success} | message=${response.message}',
    );
  }
}
