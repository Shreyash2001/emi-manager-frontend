import 'package:mobile_emi_manager/core/errors/result.dart';
import 'package:mobile_emi_manager/features/auth/domain/entities/auth_session.dart';
import 'package:mobile_emi_manager/features/auth/domain/repositories/auth_repository.dart';

/// Use case for checking the stored authentication session on app startup.
class GetCurrentUserUseCase {
  final AuthRepository _repository;

  GetCurrentUserUseCase({required AuthRepository repository})
      : _repository = repository;

  /// Returns [AuthSession] if a valid stored session exists, null otherwise.
  Future<Result<AuthSession?>> call() => _repository.getStoredSession();
}
