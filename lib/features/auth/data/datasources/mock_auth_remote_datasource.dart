import 'package:mobile_emi_manager/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:mobile_emi_manager/features/auth/data/models/login_request_model.dart';
import 'package:mobile_emi_manager/features/auth/data/models/login_response_model.dart';
import 'package:mobile_emi_manager/features/auth/data/models/user_model.dart';
import 'package:mobile_emi_manager/core/errors/app_exception.dart';
import 'package:mobile_emi_manager/core/utils/logger.dart';

/// Mock data source used in development when the real backend is not yet available.
///
/// IMPORTANT: This must NEVER be registered in staging or production.
/// It is only swapped in via [initializeDependencies] when ENV=development.
///
/// Dummy credentials:
///   Mobile : 1234567890
///   Password: 12345
class MockAuthRemoteDataSource implements AuthRemoteDataSource {
  static const _dummyMobile = '1234567890';
  static const _dummyPassword = '12345';
  static const _dummyToken = 'mock-jwt-token-dev-only-12345';

  @override
  Future<LoginResponseModel> login(LoginRequestModel request) async {
    AppLogger.debug('MockAuthRemoteDataSource: login attempt for ${request.mobileNumber}');

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    if (request.mobileNumber == _dummyMobile &&
        request.password == _dummyPassword) {
      AppLogger.debug('MockAuthRemoteDataSource: login SUCCESS');
      return const LoginResponseModel(
        accessToken: _dummyToken,
        user: UserModel(
          id: 'mock-user-001',
          name: 'Demo Store Owner',
          mobileNumber: _dummyMobile,
          role: 'STORE_OWNER',
          storeId: 'mock-store-001',
          storeName: 'Demo Mobile Shop',
          profileImageUrl: null,
          theme: StoreThemeModel(
            primaryColor: '#6C5CE7',
            secondaryColor: '#111827',
            accentColor: '#F59E0B',
          ),
        ),
      );
    }

    // Wrong credentials → simulate 401
    AppLogger.debug('MockAuthRemoteDataSource: login FAILED — wrong credentials');
    throw const AuthenticationException(
      message: 'Invalid mobile number or password',
    );
  }

  @override
  Future<UserModel> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const UserModel(
      id: 'mock-user-001',
      name: 'Demo Store Owner',
      mobileNumber: _dummyMobile,
      role: 'STORE_OWNER',
      storeId: 'mock-store-001',
      storeName: 'Demo Mobile Shop',
      profileImageUrl: null,
    );
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 200));
    AppLogger.debug('MockAuthRemoteDataSource: logout called');
  }
}
