import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobile_emi_manager/core/errors/app_failure.dart';
import 'package:mobile_emi_manager/core/errors/result.dart';
import 'package:mobile_emi_manager/features/auth/domain/entities/auth_session.dart';
import 'package:mobile_emi_manager/features/auth/domain/entities/user.dart';
import 'package:mobile_emi_manager/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:mobile_emi_manager/features/auth/domain/usecases/login_usecase.dart';
import 'package:mobile_emi_manager/features/auth/domain/usecases/logout_usecase.dart';
import 'package:mobile_emi_manager/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mobile_emi_manager/features/auth/presentation/bloc/auth_event.dart';
import 'package:mobile_emi_manager/features/auth/presentation/bloc/auth_state.dart';
import 'package:mobile_emi_manager/shared/enums/user_role.dart';

// ─── Mocks ────────────────────────────────────────────────────────────────────

class MockLoginUseCase extends Mock implements LoginUseCase {}
class MockLogoutUseCase extends Mock implements LogoutUseCase {}
class MockGetCurrentUserUseCase extends Mock implements GetCurrentUserUseCase {}

// ─── Test Data ────────────────────────────────────────────────────────────────

const _testUser = User(
  id: 'user-1',
  name: 'Test Store Owner',
  mobileNumber: '9876543210',
  role: UserRole.storeOwner,
  storeName: 'Test Store',
);

const _testSession = AuthSession(
  accessToken: 'test-token-12345',
  user: _testUser,
);

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  late MockLoginUseCase mockLoginUseCase;
  late MockLogoutUseCase mockLogoutUseCase;
  late MockGetCurrentUserUseCase mockGetCurrentUserUseCase;

  setUp(() {
    mockLoginUseCase = MockLoginUseCase();
    mockLogoutUseCase = MockLogoutUseCase();
    mockGetCurrentUserUseCase = MockGetCurrentUserUseCase();
  });

  AuthBloc buildBloc() => AuthBloc(
        loginUseCase: mockLoginUseCase,
        logoutUseCase: mockLogoutUseCase,
        getCurrentUserUseCase: mockGetCurrentUserUseCase,
      );

  group('AuthBloc', () {
    test('initial state is AuthInitial', () {
      expect(buildBloc().state, isA<AuthInitial>());
    });

    group('CheckAuthenticationStatus', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthAuthenticated] when session exists',
        build: buildBloc,
        setUp: () {
          when(() => mockGetCurrentUserUseCase())
              .thenAnswer((_) async => const Success(_testSession));
        },
        act: (bloc) => bloc.add(const CheckAuthenticationStatus()),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthAuthenticated>(),
        ],
        verify: (_) {
          verify(() => mockGetCurrentUserUseCase()).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthUnauthenticated] when no session exists',
        build: buildBloc,
        setUp: () {
          when(() => mockGetCurrentUserUseCase())
              .thenAnswer((_) async => const Success(null));
        },
        act: (bloc) => bloc.add(const CheckAuthenticationStatus()),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthUnauthenticated>(),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthUnauthenticated] on failure',
        build: buildBloc,
        setUp: () {
          when(() => mockGetCurrentUserUseCase())
              .thenAnswer((_) async => const Failure(NetworkFailure()));
        },
        act: (bloc) => bloc.add(const CheckAuthenticationStatus()),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthUnauthenticated>(),
        ],
      );
    });

    group('LoginRequested', () {
      const loginEvent = LoginRequested(
        mobileNumber: '9876543210',
        password: 'password123',
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthAuthenticated] on successful login',
        build: buildBloc,
        setUp: () {
          when(() => mockLoginUseCase(
                mobileNumber: any(named: 'mobileNumber'),
                password: any(named: 'password'),
              )).thenAnswer((_) async => const Success(_testSession));
        },
        act: (bloc) => bloc.add(loginEvent),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthAuthenticated>(),
        ],
        verify: (bloc) {
          final authenticated = bloc.state as AuthAuthenticated;
          expect(authenticated.user.id, equals(_testUser.id));
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] on failed login',
        build: buildBloc,
        setUp: () {
          when(() => mockLoginUseCase(
                mobileNumber: any(named: 'mobileNumber'),
                password: any(named: 'password'),
              )).thenAnswer((_) async =>
              const Failure(AuthenticationFailure(message: 'Invalid credentials')));
        },
        act: (bloc) => bloc.add(loginEvent),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthError>(),
        ],
        verify: (bloc) {
          final error = bloc.state as AuthError;
          expect(error.failure, isA<AuthenticationFailure>());
        },
      );
    });

    group('LogoutRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthUnauthenticated] after logout',
        build: buildBloc,
        seed: () => const AuthAuthenticated(user: _testUser),
        setUp: () {
          when(() => mockLogoutUseCase())
              .thenAnswer((_) async => const Success(null));
        },
        act: (bloc) => bloc.add(const LogoutRequested()),
        expect: () => [isA<AuthUnauthenticated>()],
        verify: (_) {
          verify(() => mockLogoutUseCase()).called(1);
        },
      );
    });

    group('SessionExpired', () {
      blocTest<AuthBloc, AuthState>(
        'clears session and emits AuthUnauthenticated',
        build: buildBloc,
        seed: () => const AuthAuthenticated(user: _testUser),
        setUp: () {
          when(() => mockLogoutUseCase())
              .thenAnswer((_) async => const Success(null));
        },
        act: (bloc) => bloc.add(const SessionExpired()),
        expect: () => [isA<AuthUnauthenticated>()],
      );
    });
  });
}
