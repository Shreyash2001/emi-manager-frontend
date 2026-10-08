import 'package:equatable/equatable.dart';

/// Represents a failure that propagates to the BLoC/UI layer.
/// BLoCs receive [AppFailure] subclasses, never raw exceptions.
sealed class AppFailure extends Equatable {
  final String message;
  final String? requestId;

  const AppFailure({required this.message, this.requestId});

  @override
  List<Object?> get props => [message, requestId];

  @override
  String toString() => '$runtimeType: $message';
}

class NetworkFailure extends AppFailure {
  const NetworkFailure({super.message = 'Network error. Please check your connection.', super.requestId});
}

class AuthenticationFailure extends AppFailure {
  const AuthenticationFailure({super.message = 'Authentication failed. Please login again.', super.requestId});
}

class AuthorizationFailure extends AppFailure {
  const AuthorizationFailure({super.message = 'You are not authorized to perform this action.', super.requestId});
}

class NotFoundFailure extends AppFailure {
  const NotFoundFailure({super.message = 'The requested resource was not found.', super.requestId});
}

class ConflictFailure extends AppFailure {
  const ConflictFailure({super.message = 'A conflict occurred.', super.requestId});
}

class ValidationFailure extends AppFailure {
  final List<String> details;

  const ValidationFailure({
    super.message = 'Please check your input and try again.',
    this.details = const [],
    super.requestId,
  });

  @override
  List<Object?> get props => [message, details, requestId];
}

class ServerFailure extends AppFailure {
  const ServerFailure({super.message = 'Server error. Please try again later.', super.requestId});
}

class UnknownFailure extends AppFailure {
  const UnknownFailure({super.message = 'An unknown error occurred.', super.requestId});
}
