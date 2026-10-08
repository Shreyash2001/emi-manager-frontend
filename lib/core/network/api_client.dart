import 'package:dio/dio.dart';
import 'package:mobile_emi_manager/app/config/app_config.dart';
import 'package:mobile_emi_manager/core/network/api_response.dart';
import 'package:mobile_emi_manager/core/errors/app_exception.dart';
import 'package:mobile_emi_manager/core/errors/error_mapper.dart';

/// The single, centralized Dio HTTP client.
///
/// All API communication goes through this class.
/// No feature may create its own Dio instance.
///
/// Interceptors are added externally via [ApiClient.addInterceptor].
class ApiClient {
  final Dio _dio;
  final AppConfig _config;

  ApiClient({required AppConfig config, required Dio dio})
      : _config = config,
        _dio = dio;

  void addInterceptor(Interceptor interceptor) {
    _dio.interceptors.add(interceptor);
  }

  // ─── HTTP Methods ─────────────────────────────────────────────────────────

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
      );
      return _parseResponse<T>(response, fromJson);
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
      );
      return _parseResponse<T>(response, fromJson);
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
      );
      return _parseResponse<T>(response, fromJson);
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  Future<ApiResponse<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
      );
      return _parseResponse<T>(response, fromJson);
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
      );
      return _parseResponse<T>(response, fromJson);
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  // ─── Response Parsing ─────────────────────────────────────────────────────

  ApiResponse<T> _parseResponse<T>(
    Response response,
    T Function(dynamic)? fromJson,
  ) {
    final body = response.data;

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
