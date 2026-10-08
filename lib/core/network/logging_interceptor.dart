import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:mobile_emi_manager/core/utils/logger.dart';

/// Centralized Dio interceptor for logging all outgoing API requests,
/// request headers, request bodies, incoming API responses with status codes,
/// response bodies, and API errors.
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final fullUrl = '${options.baseUrl}${options.path}';
    final queryStr = options.queryParameters.isNotEmpty
        ? '\n  Query Params: ${options.queryParameters}'
        : '';
    final headersStr = options.headers.isNotEmpty
        ? '\n  Headers: ${_safeHeaders(options.headers)}'
        : '';
    final bodyStr = options.data != null
        ? '\n  Request Body: ${_safeBody(options.data)}'
        : '';

    AppLogger.network(
      '🌐 [API REQUEST] ${options.method} $fullUrl$headersStr$queryStr$bodyStr',
    );
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final statusCode = response.statusCode;
    final statusMessage = response.statusMessage ?? '';
    final path = response.requestOptions.path;
    final method = response.requestOptions.method;
    final responseBody = _formatData(response.data);

    AppLogger.network(
      '✅ [API RESPONSE] [$statusCode $statusMessage] $method $path\n'
      '  Response Body: $responseBody',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final statusCode = err.response?.statusCode ?? 'NO_STATUS';
    final path = err.requestOptions.path;
    final method = err.requestOptions.method;
    final errorBody = _formatData(err.response?.data);

    AppLogger.error(
      '❌ [API ERROR] [$statusCode] $method $path\n'
      '  Message: ${err.message}\n'
      '  Response Body: $errorBody',
    );
    handler.next(err);
  }

  String _formatData(dynamic data) {
    if (data == null) return 'null';
    if (data is Map || data is List) {
      try {
        return jsonEncode(data);
      } catch (_) {
        return data.toString();
      }
    }
    return data.toString();
  }

  Map<String, dynamic> _safeHeaders(Map<String, dynamic> headers) {
    final copy = Map<String, dynamic>.from(headers);
    if (copy.containsKey('Authorization')) {
      final auth = copy['Authorization'].toString();
      if (auth.length > 20) {
        copy['Authorization'] = '${auth.substring(0, 15)}...';
      }
    }
    return copy;
  }

  dynamic _safeBody(dynamic data) {
    if (data is Map<String, dynamic>) {
      final masked = Map<String, dynamic>.from(data);
      // We log request bodies clearly for debugging while avoiding raw passwords in plain logs
      if (masked.containsKey('password')) {
        masked['password'] = '***';
      }
      return masked;
    }
    if (data is String) {
      try {
        final parsed = jsonDecode(data);
        if (parsed is Map<String, dynamic>) {
          return _safeBody(parsed);
        }
      } catch (_) {}
    }
    return data;
  }
}
