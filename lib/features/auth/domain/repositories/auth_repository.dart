import 'package:mobile_emi_manager/core/errors/result.dart';
import 'package:mobile_emi_manager/features/auth/domain/entities/auth_session.dart';
import 'package:mobile_emi_manager/features/auth/domain/entities/user.dart';

/// Abstract repository interface for authentication operations.
/// The domain layer only depends on this interface, never on the implementation.
abstract class AuthRepository {
  /// Login with mobile number and password.
  Future<Result<AuthSession>> login({
    required String mobileNumber,
    required String password,
  });

  /// Get the currently authenticated user from the API.
  Future<Result<User>> getCurrentUser();

  /// Logout — clears session from secure storage.
  Future<Result<void>> logout();

  /// Check if a valid session exists in secure storage.
  Future<Result<AuthSession?>> getStoredSession();
}
