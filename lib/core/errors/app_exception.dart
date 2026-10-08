/// Base class for all application exceptions.
/// These are caught by data sources and mapped to [AppFailure].
sealed class AppException implements Exception {
  final String message;
  final int? statusCode;
  final String? requestId;

  const AppException({
    required this.message,
    this.statusCode,
    this.requestId,
  });

  @override
  String toString() => 'AppException: $message (status: $statusCode)';
}

/// Thrown when the device has no internet or the server is unreachable.
class NetworkException extends AppException {
  const NetworkException({super.message = 'Network error', super.statusCode, super.requestId});
}

/// Thrown on 401 responses — token missing/expired.
class AuthenticationException extends AppException {
  const AuthenticationException({super.message = 'Authentication failed', super.statusCode = 401, super.requestId});
}

/// Thrown on 403 responses — authenticated but not authorized.
class AuthorizationException extends AppException {
  const AuthorizationException({super.message = 'Access denied', super.statusCode = 403, super.requestId});
}

/// Thrown on 404 responses.
class NotFoundException extends AppException {
  const NotFoundException({super.message = 'Resource not found', super.statusCode = 404, super.requestId});
}

/// Thrown on 409 responses — resource conflict.
class ConflictException extends AppException {
  const ConflictException({super.message = 'Conflict', super.statusCode = 409, super.requestId});
}

/// Thrown on 422 responses — validation failed on the server.
class ValidationException extends AppException {
  final List<String> details;

  const ValidationException({
    super.message = 'Validation failed',
    super.statusCode = 422,
    this.details = const [],
    super.requestId,
  });
}

/// Thrown on 5xx responses.
class ServerException extends AppException {
  const ServerException({super.message = 'Server error', super.statusCode, super.requestId});
}

/// Fallback for unexpected exceptions.
class UnknownException extends AppException {
  const UnknownException({super.message = 'An unknown error occurred', super.statusCode, super.requestId});
}
