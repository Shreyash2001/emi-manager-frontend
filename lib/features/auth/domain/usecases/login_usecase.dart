import 'package:mobile_emi_manager/core/errors/result.dart';
import 'package:mobile_emi_manager/features/auth/domain/entities/auth_session.dart';
import 'package:mobile_emi_manager/features/auth/domain/repositories/auth_repository.dart';

/// Use case for logging in a user.
class LoginUseCase {
  final AuthRepository _repository;

  LoginUseCase({required AuthRepository repository})
      : _repository = repository;

  Future<Result<AuthSession>> call({
    required String mobileNumber,
    required String password,
  }) {
    return _repository.login(
      mobileNumber: mobileNumber,
      password: password,
    );
  }
}
