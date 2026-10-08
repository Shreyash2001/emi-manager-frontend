import 'package:equatable/equatable.dart';
import 'package:mobile_emi_manager/core/errors/app_failure.dart';
import 'package:mobile_emi_manager/features/auth/domain/entities/user.dart';

/// All states for [AuthBloc]. All states are immutable.
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state — before any auth check has been performed.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Auth check or login is in progress.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// User is authenticated and has a valid session.
class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

/// User is not authenticated (no valid session found).
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// An auth error occurred (login failed, etc.).
class AuthError extends AuthState {
  final AppFailure failure;

  const AuthError({required this.failure});

  @override
  List<Object?> get props => [failure];
}
