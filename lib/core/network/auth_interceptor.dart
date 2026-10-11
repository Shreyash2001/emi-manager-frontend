import 'package:dio/dio.dart';
import 'package:mobile_emi_manager/core/storage/secure_storage_service.dart';
import 'package:mobile_emi_manager/core/constants/storage_keys.dart';
import 'package:mobile_emi_manager/core/utils/logger.dart';

import 'package:mobile_emi_manager/core/network/api_cache_manager.dart';

/// Dio interceptor that automatically attaches the Bearer token to all
/// protected requests and handles 401 Unauthorized responses.
///
/// On 401: clears the session and triggers re-authentication.
/// The [onUnauthorized] callback is set by the app shell to clear AuthBloc state.
class AuthInterceptor extends Interceptor {
  final SecureStorageService _secureStorage;
  final ApiCacheManager? _cacheManager;

  /// Called when a 401 is received — use this to trigger AuthBloc logout.
  void Function()? onUnauthorized;

  AuthInterceptor({
    required SecureStorageService secureStorage,
    ApiCacheManager? cacheManager,
  })  : _secureStorage = secureStorage,
        _cacheManager = cacheManager;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _secureStorage.read(StorageKeys.accessToken);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      final path = err.requestOptions.path;
      final isLogoutEndpoint = path.contains('/auth/logout');

      _clearSession();

      if (!isLogoutEndpoint) {
        AppLogger.warning(
          'AuthInterceptor: 401 received for $path — clearing session.',
        );
        onUnauthorized?.call();
      }
    }
    handler.next(err);
  }

  Future<void> _clearSession() async {
    await _secureStorage.delete(StorageKeys.accessToken);
    _cacheManager?.clear();
  }
}
