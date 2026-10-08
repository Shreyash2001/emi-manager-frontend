import 'package:mobile_emi_manager/core/errors/result.dart';
import 'package:mobile_emi_manager/features/auth/domain/repositories/auth_repository.dart';

/// Use case for logging out the current user.
class LogoutUseCase {
  final AuthRepository _repository;

  LogoutUseCase({required AuthRepository repository})
      : _repository = repository;

  Future<Result<void>> call() => _repository.logout();
}
