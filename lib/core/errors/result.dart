/// Result type for use in domain layers and repositories.
///
/// Follows a simple Success/Failure pattern that avoids throwing exceptions
/// across layer boundaries. BLoCs pattern-match on the result:
///
/// ```dart
/// final result = await loginUseCase(params);
/// switch (result) {
///   case Success(:final value):
///     emit(AuthAuthenticated(user: value));
///   case Failure(:final failure):
///     emit(AuthError(failure: failure));
/// }
/// ```
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);

  @override
  String toString() => 'Success($value)';
}

class Failure<T> extends Result<T> {
  final dynamic failure;
  const Failure(this.failure);

  @override
  String toString() => 'Failure($failure)';
}

extension ResultExtension<T> on Result<T> {
  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get valueOrNull => switch (this) {
        Success(:final value) => value,
        Failure() => null,
      };

  dynamic get failureOrNull => switch (this) {
        Success() => null,
        Failure(:final failure) => failure,
      };
}
