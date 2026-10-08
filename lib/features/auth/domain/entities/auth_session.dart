import 'package:equatable/equatable.dart';
import 'package:mobile_emi_manager/features/auth/domain/entities/user.dart';

/// Domain entity representing an active authentication session.
class AuthSession extends Equatable {
  final String accessToken;
  final User user;

  const AuthSession({
    required this.accessToken,
    required this.user,
  });

  @override
  List<Object?> get props => [accessToken, user];
}
