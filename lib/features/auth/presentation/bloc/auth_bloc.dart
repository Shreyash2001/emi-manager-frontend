import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_emi_manager/core/errors/result.dart';
import 'package:mobile_emi_manager/core/utils/logger.dart';
import 'package:mobile_emi_manager/features/auth/domain/usecases/login_usecase.dart';
import 'package:mobile_emi_manager/features/auth/domain/usecases/logout_usecase.dart';
import 'package:mobile_emi_manager/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// The primary authentication BLoC.
///
/// Handles:
///   - Session checking on startup
///   - Login
///   - Logout
///   - Session expiration (from 401 interceptor)
///
/// Does NOT know about Dio, HTTP, SharedPreferences, or SecureStorage.
/// Communicates only with use cases.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;

  AuthBloc({
    required LoginUseCase loginUseCase,
    required LogoutUseCase logoutUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
  })  : _loginUseCase = loginUseCase,
        _logoutUseCase = logoutUseCase,
        _getCurrentUserUseCase = getCurrentUserUseCase,
        super(const AuthInitial()) {
    on<CheckAuthenticationStatus>(_onCheckAuthenticationStatus);
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<SessionExpired>(_onSessionExpired);
  }

  Future<void> _onCheckAuthenticationStatus(
    CheckAuthenticationStatus event,
    Emitter<AuthState> emit,
  ) async {
    AppLogger.bloc('AuthBloc', 'CheckAuthenticationStatus');
    emit(const AuthLoading());

    final result = await _getCurrentUserUseCase();
    switch (result) {
      case Success(:final value):
        if (value != null) {
          emit(AuthAuthenticated(user: value.user));
        } else {
          emit(const AuthUnauthenticated());
        }
      case Failure():
        emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    AppLogger.bloc('AuthBloc', 'LoginRequested');
    emit(const AuthLoading());

    final result = await _loginUseCase(
      mobileNumber: event.mobileNumber,
      password: event.password,
    );

    switch (result) {
      case Success(:final value):
        emit(AuthAuthenticated(user: value.user));
      case Failure(:final failure):
        emit(AuthError(failure: failure));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state is AuthUnauthenticated) return;
    AppLogger.bloc('AuthBloc', 'LogoutRequested');
    await _logoutUseCase();
    emit(const AuthUnauthenticated());
  }

  Future<void> _onSessionExpired(
    SessionExpired event,
    Emitter<AuthState> emit,
  ) async {
    if (state is AuthUnauthenticated) return;
    AppLogger.bloc('AuthBloc', 'SessionExpired');
    await _logoutUseCase();
    emit(const AuthUnauthenticated());
  }
}
