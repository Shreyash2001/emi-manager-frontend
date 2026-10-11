import 'package:dio/dio.dart';
import 'package:mobile_emi_manager/app/config/app_config.dart';
import 'package:mobile_emi_manager/core/network/api_cache_manager.dart';
import 'package:mobile_emi_manager/core/network/api_response.dart';
import 'package:mobile_emi_manager/core/errors/app_exception.dart';
import 'package:mobile_emi_manager/core/errors/error_mapper.dart';

/// The single, centralized Dio HTTP client with integrated 15-minute response caching.
///
/// All API communication goes through this class.
/// No feature may create its own Dio instance.
///
/// Features:
/// - In-memory caching for GET requests with a 15-minute TTL.
/// - Prevents repeated API calls when switching features inside the app.
/// - Automatic cache invalidation when any write transaction (POST, PUT, PATCH, DELETE) occurs.
/// - Support for forceRefresh when fresh network data is explicitly requested.
class ApiClient {
  final Dio _dio;
  final AppConfig _config;
  final ApiCacheManager _cacheManager;
  final Map<String, Future<dynamic>> _inFlightRequests = <String, Future<dynamic>>{};

  ApiClient({
    required AppConfig config,
    required Dio dio,
    ApiCacheManager? cacheManager,
  })  : _config = config,
        _dio = dio,
        _cacheManager =
            cacheManager ?? ApiCacheManager(defaultTtl: config.cacheTtl);

  void addInterceptor(Interceptor interceptor) {
    _dio.interceptors.add(interceptor);
  }

  /// Access to the underlying cache manager.
  ApiCacheManager get cacheManager => _cacheManager;

  /// Invalidate cache for a specific path or the entire cache.
  void invalidateCache([String? path]) {
    if (path != null) {
      _cacheManager.invalidate(path);
    } else {
      _cacheManager.clear();
    }
  }

  // ─── HTTP Methods ─────────────────────────────────────────────────────────

  /// GET request with automatic 15-minute caching and in-flight request deduplication.
  ///
  /// - Returns cached data if available and unexpired (< 15 mins).
  /// - Joins existing pending in-flight requests if multiple calls occur simultaneously.
  /// - Fetches from network on cache miss or if [forceRefresh] is true.
  /// - Subsequent calls within the TTL will reuse the cache.
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    CancelToken? cancelToken,
    bool forceRefresh = false,
    Duration? cacheTtl,
  }) async {
    final cacheKey = _cacheManager.generateKey(path, queryParameters);

    // 1. Check cache first if not explicitly force refreshing
    if (!forceRefresh) {
      final cachedBody = _cacheManager.get(cacheKey);
      if (cachedBody != null) {
        return _parseBody<T>(cachedBody, fromJson);
      }
    }

    // 2. In-flight request deduplication: join existing pending request
    if (!forceRefresh && _inFlightRequests.containsKey(cacheKey)) {
      try {
        final sharedData = await _inFlightRequests[cacheKey]!;
        return _parseBody<T>(sharedData, fromJson);
      } on DioException catch (e) {
        throw ErrorMapper.fromDioException(e);
      }
    }

    // 3. Fetch fresh data from the network and register in-flight future
    final requestFuture = () async {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
      );
      if (response.data is Map<String, dynamic>) {
        _cacheManager.put(cacheKey, response.data, ttl: cacheTtl);
      }
      return response.data;
    }();

    _inFlightRequests[cacheKey] = requestFuture;

    try {
      final rawData = await requestFuture;
      return _parseBody<T>(rawData, fromJson);
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    } finally {
      _inFlightRequests.remove(cacheKey);
    }
  }

  /// POST request (write transaction).
  ///
  /// Automatically invalidates the GET cache on success to ensure no stale data remains.
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    CancelToken? cancelToken,
    bool invalidateCache = true,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
      );
      final parsed = _parseResponse<T>(response, fromJson);

      // Invalidate cache on successful write transaction
      if (invalidateCache && parsed.success) {
        _cacheManager.invalidateOnWriteTransaction(
          operation: 'POST',
          path: path,
        );
      }

      return parsed;
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  /// PUT request (write transaction).
  ///
  /// Automatically invalidates the GET cache on success to ensure no stale data remains.
  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    CancelToken? cancelToken,
    bool invalidateCache = true,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
      );
      final parsed = _parseResponse<T>(response, fromJson);

      // Invalidate cache on successful write transaction
      if (invalidateCache && parsed.success) {
        _cacheManager.invalidateOnWriteTransaction(
          operation: 'PUT',
          path: path,
        );
      }

      return parsed;
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  /// PATCH request (write transaction).
  ///
  /// Automatically invalidates the GET cache on success to ensure no stale data remains.
  Future<ApiResponse<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    CancelToken? cancelToken,
    bool invalidateCache = true,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
      );
      final parsed = _parseResponse<T>(response, fromJson);

      // Invalidate cache on successful write transaction
      if (invalidateCache && parsed.success) {
        _cacheManager.invalidateOnWriteTransaction(
          operation: 'PATCH',
          path: path,
        );
      }

      return parsed;
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  /// DELETE request (write transaction).
  ///
  /// Automatically invalidates the GET cache on success to ensure no stale data remains.
  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    CancelToken? cancelToken,
    bool invalidateCache = true,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
      );
      final parsed = _parseResponse<T>(response, fromJson);

      // Invalidate cache on successful write transaction
      if (invalidateCache && parsed.success) {
        _cacheManager.invalidateOnWriteTransaction(
          operation: 'DELETE',
          path: path,
        );
      }

      return parsed;
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  // ─── Response Parsing ─────────────────────────────────────────────────────

  ApiResponse<T> _parseResponse<T>(
    Response response,
    T Function(dynamic)? fromJson,
  ) {
    return _parseBody<T>(response.data, fromJson);
  }

  ApiResponse<T> _parseBody<T>(
    dynamic body,
    T Function(dynamic)? fromJson,
  ) {
    if (body is! Map<String, dynamic>) {
      throw const UnknownException(message: 'Unexpected response format.');
    }

    final success = body['success'] as bool? ?? false;
    final message = body['message'] as String?;
    final data = body['data'];

    if (!success) {
      final errorObj = body['error'] as Map<String, dynamic>?;
      final errorMessage = message ?? 'Request failed';
      final details = (errorObj?['details'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      throw ValidationException(message: errorMessage, details: details);
    }

    T? parsedData;
    if (fromJson != null && data != null) {
      parsedData = fromJson(data);
    }

    return ApiResponse<T>(
      success: success,
      message: message,
      data: parsedData,
    );
  }

  AppConfig get config => _config;
}
