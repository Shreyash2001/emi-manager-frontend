import 'package:equatable/equatable.dart';

/// All events for [AuthBloc].
sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Check stored session on app startup.
class CheckAuthenticationStatus extends AuthEvent {
  const CheckAuthenticationStatus();
}

/// User submitted login form.
class LoginRequested extends AuthEvent {
  final String mobileNumber;
  final String password;

  const LoginRequested({
    required this.mobileNumber,
    required this.password,
  });

  @override
  List<Object?> get props => [mobileNumber];
  // Note: password intentionally excluded from props for security.
}

/// User tapped logout.
class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

/// Session was cleared externally (e.g. 401 from AuthInterceptor).
class SessionExpired extends AuthEvent {
  const SessionExpired();
}
