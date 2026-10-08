import 'package:dio/dio.dart';
import 'package:mobile_emi_manager/core/errors/app_exception.dart';
import 'package:mobile_emi_manager/core/errors/app_failure.dart';
import 'package:mobile_emi_manager/core/utils/logger.dart';

/// Maps raw Dio errors and AppExceptions into [AppFailure] instances.
/// This is the single place where error translation occurs.
class ErrorMapper {
  ErrorMapper._();

  /// Convert a [DioException] into an [AppException].
  static AppException fromDioException(DioException e) {
    final requestId = e.response?.headers.value('x-request-id');

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException(
          message: 'Request timed out. Please try again.',
          requestId: requestId,
        );

      case DioExceptionType.connectionError:
        return const NetworkException(
          message: 'Unable to connect. Please check your internet connection.',
        );

      case DioExceptionType.badResponse:
        return _fromStatusCode(e);

      case DioExceptionType.cancel:
        return const NetworkException(message: 'Request was cancelled.');

      default:
        return UnknownException(
          message: e.message ?? 'An unknown error occurred.',
          requestId: requestId,
        );
    }
  }

  static AppException _fromStatusCode(DioException e) {
    final statusCode = e.response?.statusCode;
    final requestId = e.response?.headers.value('x-request-id');
    final serverMessage = _extractMessage(e.response?.data);
    final details = _extractDetails(e.response?.data);

    AppLogger.error(
      'API Error [$statusCode]: $serverMessage (requestId: $requestId)',
    );

    switch (statusCode) {
      case 401:
        return AuthenticationException(
          message: serverMessage ?? 'Authentication failed',
          requestId: requestId,
        );
      case 403:
        return AuthorizationException(
          message: serverMessage ?? 'Access denied',
          requestId: requestId,
        );
      case 404:
        return NotFoundException(
          message: serverMessage ?? 'Resource not found',
          requestId: requestId,
        );
      case 409:
        return ConflictException(
          message: serverMessage ?? 'Conflict',
          requestId: requestId,
        );
      case 422:
        return ValidationException(
          message: serverMessage ?? 'Validation failed',
          details: details,
          requestId: requestId,
        );
      case 500:
      case 502:
      case 503:
        return ServerException(
          message: serverMessage ?? 'Server error. Please try again later.',
          statusCode: statusCode,
          requestId: requestId,
        );
      default:
        return UnknownException(
          message: serverMessage ?? 'An error occurred.',
          statusCode: statusCode,
          requestId: requestId,
        );
    }
  }

  /// Convert any exception (AppException or generic) to [AppFailure].
  static AppFailure toFailure(Object error) {
    if (error is AppException) {
      return fromAppException(error);
    }
    if (error is DioException) {
      return fromAppException(fromDioException(error));
    }
    AppLogger.error('Unexpected error: $error');
    return const UnknownFailure();
  }

  /// Convert an [AppException] directly to its [AppFailure] counterpart.
  static AppFailure fromAppException(AppException exception) {
    return switch (exception) {
      NetworkException e => NetworkFailure(message: e.message, requestId: e.requestId),
      AuthenticationException e => AuthenticationFailure(message: e.message, requestId: e.requestId),
      AuthorizationException e => AuthorizationFailure(message: e.message, requestId: e.requestId),
      NotFoundException e => NotFoundFailure(message: e.message, requestId: e.requestId),
      ConflictException e => ConflictFailure(message: e.message, requestId: e.requestId),
      ValidationException e => ValidationFailure(message: e.message, details: e.details, requestId: e.requestId),
      ServerException e => ServerFailure(message: e.message, requestId: e.requestId),
      UnknownException e => UnknownFailure(message: e.message, requestId: e.requestId),
    };
  }

  static String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['message'] as String?;
    }
    return null;
  }

  static List<String> _extractDetails(dynamic data) {
    if (data is Map<String, dynamic>) {
      final error = data['error'];
      if (error is Map<String, dynamic>) {
        final details = error['details'];
        if (details is List) {
          return details.map((e) => e.toString()).toList();
        }
      }
    }
    return [];
  }
}
