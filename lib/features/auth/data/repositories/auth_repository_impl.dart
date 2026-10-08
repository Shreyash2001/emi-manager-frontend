import 'dart:convert';
import 'package:mobile_emi_manager/core/errors/error_mapper.dart';
import 'package:mobile_emi_manager/core/errors/result.dart';
import 'package:mobile_emi_manager/core/storage/secure_storage_service.dart';
import 'package:mobile_emi_manager/core/storage/local_storage_service.dart';
import 'package:mobile_emi_manager/core/constants/storage_keys.dart';
import 'package:mobile_emi_manager/core/utils/logger.dart';
import 'package:mobile_emi_manager/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:mobile_emi_manager/features/auth/data/models/login_request_model.dart';
import 'package:mobile_emi_manager/features/auth/data/models/user_model.dart';
import 'package:mobile_emi_manager/features/auth/domain/entities/auth_session.dart';
import 'package:mobile_emi_manager/features/auth/domain/entities/user.dart';
import 'package:mobile_emi_manager/features/auth/domain/repositories/auth_repository.dart';

/// Concrete implementation of [AuthRepository].
/// Coordinates between remote data source and secure/local storage.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final SecureStorageService _secureStorage;
  final LocalStorageService _localStorage;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required SecureStorageService secureStorage,
    required LocalStorageService localStorage,
  })  : _remoteDataSource = remoteDataSource,
        _secureStorage = secureStorage,
        _localStorage = localStorage;

  @override
  Future<Result<AuthSession>> login({
    required String mobileNumber,
    required String password,
  }) async {
    try {
      final response = await _remoteDataSource.login(
        LoginRequestModel(mobileNumber: mobileNumber, password: password),
      );

      // Persist token securely.
      await _secureStorage.write(StorageKeys.accessToken, response.accessToken);

      // Cache non-sensitive user data locally for quick access.
      await _localStorage.setString(
        StorageKeys.cachedUser,
        json.encode(response.user.toJson()),
      );

      final session = AuthSession(
        accessToken: response.accessToken,
        user: response.user.toDomain(),
      );
      AppLogger.info('AuthRepository: login successful for ${mobileNumber.substring(0, 6)}***');
      return Success(session);
    } catch (e) {
      AppLogger.error('AuthRepository: login failed', error: e);
      return Failure(ErrorMapper.toFailure(e));
    }
  }

  @override
  Future<Result<User>> getCurrentUser() async {
    try {
      final userModel = await _remoteDataSource.getCurrentUser();
      // Update cached user.
      await _localStorage.setString(
        StorageKeys.cachedUser,
        json.encode(userModel.toJson()),
      );
      return Success(userModel.toDomain());
    } catch (e) {
      AppLogger.error('AuthRepository: getCurrentUser failed', error: e);
      return Failure(ErrorMapper.toFailure(e));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      final token = await _secureStorage.read(StorageKeys.accessToken);

      // 1. Immediately delete local & secure session to prevent infinite recursion
      await _secureStorage.delete(StorageKeys.accessToken);
      await _localStorage.remove(StorageKeys.cachedUser);

      // 2. Only attempt remote logout if token was actually present
      if (token != null && token.isNotEmpty) {
        try {
          await _remoteDataSource.logout();
        } catch (_) {
          // Non-critical server logout error
        }
      }

      AppLogger.info('AuthRepository: logout complete');
      return const Success(null);
    } catch (e) {
      AppLogger.error('AuthRepository: logout error', error: e);
      return Failure(ErrorMapper.toFailure(e));
    }
  }

  @override
  Future<Result<AuthSession?>> getStoredSession() async {
    try {
      final token = await _secureStorage.read(StorageKeys.accessToken);
      if (token == null || token.isEmpty) {
        return const Success(null);
      }

      // Load cached user data.
      final cachedUserJson = _localStorage.getString(StorageKeys.cachedUser);
      if (cachedUserJson != null) {
        final userMap = json.decode(cachedUserJson) as Map<String, dynamic>;
        final userModel = UserModel.fromJson(userMap);
        return Success(
          AuthSession(accessToken: token, user: userModel.toDomain()),
        );
      }

      return const Success(null);
    } catch (e) {
      AppLogger.error('AuthRepository: getStoredSession error', error: e);
      return Failure(ErrorMapper.toFailure(e));
    }
  }
}
