# Mobile Shop EMI Manager — Flutter Base Architecture

A production-ready Flutter application for managing mobile shop EMI plans, built with a clean, scalable feature-first architecture.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Folder Structure](#folder-structure)
3. [Environment Configuration](#environment-configuration)
4. [BLoC State Management](#bloc-state-management)
5. [Feature Structure](#feature-structure)
6. [Dependency Injection](#dependency-injection)
7. [API Layer](#api-layer)
8. [Authentication Flow](#authentication-flow)
9. [Routing](#routing)
10. [Localization](#localization)
11. [Theme](#theme)
12. [Secure Storage](#secure-storage)
13. [Error Handling](#error-handling)
14. [Testing](#testing)
15. [Code Generation](#code-generation)
16. [How To: Add a New Feature](#how-to-add-a-new-feature)
17. [How To: Add a New API Endpoint](#how-to-add-a-new-api-endpoint)
18. [How To: Add a New Language](#how-to-add-a-new-language)
19. [How To: Add a New Route](#how-to-add-a-new-route)

---

## Architecture Overview

```
Flutter App
    │
    ├── app/              # App-level config: router, theme, localization
    ├── core/             # Shared infrastructure: network, storage, DI, utils, widgets
    ├── features/         # Feature-first modules
    │     ├── auth/
    │     ├── dashboard/
    │     ├── customers/
    │     ├── emi/
    │     ├── payments/
    │     ├── reports/
    │     ├── admin/
    │     └── profile/
    └── shared/           # Cross-feature enums, models, widgets
```

### Data Flow

```
UI (Page/Widget)
      ↓
 BLoC / Cubit
      ↓
  Use Case         ← (optional for simple flows; required for complex ones)
      ↓
 Repository        ← Abstract interface defined in domain/
      ↓
RemoteDataSource   ← Knows only about HTTP endpoints and response models
      ↓
  ApiClient        ← Single configured Dio instance
      ↓
Backend REST API
```

### Layer Rules

| Layer | Allowed Dependencies | Forbidden |
|-------|---------------------|-----------|
| **Presentation** (BLoC, Widgets) | UseCases, Repositories | Dio, Storage, raw JSON |
| **Domain** (Entities, Repos, UseCases) | Nothing (pure Dart) | Flutter, Dio, JSON |
| **Data** (Models, DataSources, RepoImpl) | ApiClient, Storage | Flutter UI, BLoC |

---

## Folder Structure

```
lib/
├── main.dart                         # Entry point
├── app/
│   ├── app.dart                      # Root MaterialApp.router
│   ├── config/
│   │   └── app_config.dart           # Environment configuration
│   ├── router/
│   │   ├── app_router.dart           # go_router configuration + auth guards
│   │   ├── route_names.dart          # Semantic route name constants
│   │   └── route_paths.dart          # URL path constants
│   ├── theme/
│   │   ├── app_theme.dart            # Light/dark ThemeData
│   │   ├── app_colors.dart           # Color palette
│   │   ├── app_text_styles.dart      # Typography
│   │   ├── app_dimensions.dart       # Spacing/sizing
│   │   └── theme_cubit.dart          # Theme state management
│   └── localization/
│       ├── app_localizations.dart    # JSON-based localization delegate
│       └── locale_cubit.dart         # Locale state management
├── core/
│   ├── constants/
│   │   ├── api_constants.dart        # API endpoint paths
│   │   ├── app_constants.dart        # App-wide constants
│   │   └── storage_keys.dart         # Storage key constants
│   ├── di/
│   │   └── injection_container.dart  # get_it DI setup
│   ├── errors/
│   │   ├── app_exception.dart        # Exception hierarchy
│   │   ├── app_failure.dart          # Failure hierarchy (for BLoCs)
│   │   ├── error_mapper.dart         # DioException → AppFailure translation
│   │   └── result.dart               # Result<T> type
│   ├── extensions/
│   │   ├── context_extensions.dart
│   │   ├── string_extensions.dart
│   │   └── num_extensions.dart
│   ├── models/
│   │   └── pagination.dart           # PaginationParams + PaginatedResponse
│   ├── network/
│   │   ├── api_client.dart           # Centralized Dio client
│   │   ├── api_response.dart         # Generic response wrapper
│   │   ├── auth_interceptor.dart     # Bearer token + 401 handling
│   │   ├── logging_interceptor.dart  # Dev-only request/response logging
│   │   └── network_info.dart         # Connectivity check
│   ├── storage/
│   │   ├── secure_storage_service.dart  # flutter_secure_storage wrapper
│   │   └── local_storage_service.dart  # SharedPreferences wrapper
│   ├── utils/
│   │   ├── logger.dart
│   │   ├── date_utils.dart
│   │   ├── currency_utils.dart
│   │   └── validation_utils.dart
│   └── widgets/
│       ├── app_button.dart
│       ├── app_text_field.dart
│       ├── app_loader.dart
│       ├── app_error_view.dart
│       ├── app_empty_view.dart
│       ├── app_network_image.dart
│       └── app_dialog.dart
├── features/
│   └── auth/
│       ├── data/
│       │   ├── datasources/auth_remote_datasource.dart
│       │   ├── models/
│       │   │   ├── login_request_model.dart
│       │   │   ├── login_response_model.dart
│       │   │   └── user_model.dart
│       │   └── repositories/auth_repository_impl.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   ├── user.dart
│       │   │   └── auth_session.dart
│       │   ├── repositories/auth_repository.dart   ← abstract interface
│       │   └── usecases/
│       │       ├── login_usecase.dart
│       │       ├── logout_usecase.dart
│       │       └── get_current_user_usecase.dart
│       └── presentation/
│           ├── bloc/
│           │   ├── auth_bloc.dart
│           │   ├── auth_event.dart
│           │   └── auth_state.dart
│           └── pages/login_page.dart
└── shared/
    └── enums/user_role.dart
```

---

## Environment Configuration

Switch environments using `--dart-define`:

```bash
# Development (default)
flutter run --dart-define=ENV=development

# Staging
flutter run --dart-define=ENV=staging

# Production
flutter run --dart-define=ENV=production
```

Configured in [`app_config.dart`](lib/app/config/app_config.dart):

| Environment | API Base URL | Logging |
|-------------|-------------|---------|
| development | `http://localhost:5000/api/v1` | ✅ |
| staging | `https://staging-api.example.com/api/v1` | ✅ |
| production | `https://api.example.com/api/v1` | ❌ |

---

## BLoC State Management

### When to use Bloc vs Cubit

| Use Case | Choice |
|---------|--------|
| Complex event-driven flows (auth, customers, payments) | `Bloc` |
| Simple UI state (theme, locale, filters) | `Cubit` |

### State Pattern

All BLoC states are:
- **Immutable** — never mutate state objects
- **Equatable** — for efficient comparison

```dart
// Example AuthState sealed class
sealed class AuthState extends Equatable { ... }
class AuthInitial extends AuthState { ... }
class AuthLoading extends AuthState { ... }
class AuthAuthenticated extends AuthState { final User user; ... }
class AuthUnauthenticated extends AuthState { ... }
class AuthError extends AuthState { final AppFailure failure; ... }
```

### Event Pattern

```dart
sealed class AuthEvent extends Equatable { ... }
class CheckAuthenticationStatus extends AuthEvent { ... }
class LoginRequested extends AuthEvent { ... }
class LogoutRequested extends AuthEvent { ... }
class SessionExpired extends AuthEvent { ... }
```

### BLoC in UI

```dart
// BlocBuilder — rebuilds on state change
BlocBuilder<AuthBloc, AuthState>(
  builder: (context, state) {
    if (state is AuthLoading) return const AppLoader();
    if (state is AuthAuthenticated) return const DashboardPage();
    // ...
  },
)

// BlocListener — side effects only
BlocListener<AuthBloc, AuthState>(
  listener: (context, state) {
    if (state is AuthError) {
      context.showSnackBar(state.failure.message, isError: true);
    }
  },
)
```

---

## Feature Structure

Every feature follows this structure:

```
features/my_feature/
├── data/
│   ├── datasources/
│   │   └── my_feature_remote_datasource.dart   # HTTP calls only
│   ├── models/
│   │   ├── my_feature_request_model.dart
│   │   └── my_feature_response_model.dart
│   └── repositories/
│       └── my_feature_repository_impl.dart     # Implements domain interface
├── domain/
│   ├── entities/
│   │   └── my_feature.dart                     # Pure Dart, no Flutter/Dio
│   ├── repositories/
│   │   └── my_feature_repository.dart          # Abstract interface
│   └── usecases/
│       └── my_feature_usecase.dart
└── presentation/
    ├── bloc/
    │   ├── my_feature_bloc.dart
    │   ├── my_feature_event.dart
    │   └── my_feature_state.dart
    └── pages/
        └── my_feature_page.dart
```

---

## Dependency Injection

Uses `get_it`. All registrations are in [`injection_container.dart`](lib/core/di/injection_container.dart).

```dart
// Access a registered dependency
final apiClient = sl<ApiClient>();
final authBloc = sl<AuthBloc>();
```

Registration order:
1. External dependencies (SharedPreferences, Connectivity)
2. Config
3. Storage services
4. Network layer (Dio, interceptors, ApiClient)
5. Data sources
6. Repositories
7. Use cases
8. Global BLoCs/Cubits

**Only these BLoCs are global:**
- `AuthBloc`
- `ThemeCubit`
- `LocaleCubit`

Feature-specific BLoCs are created at page scope using `BlocProvider(create: (_) => MyBloc())`.

---

## API Layer

### Adding a new API call

**Step 1**: Add endpoint to [`api_constants.dart`](lib/core/constants/api_constants.dart):
```dart
static const String customers = '/customers';
static String customerDetails(String id) => '/customers/$id';
```

**Step 2**: Create request/response models in `data/models/`:
```dart
class CustomerModel {
  factory CustomerModel.fromJson(Map<String, dynamic> json) { ... }
  Customer toDomain() { ... }
}
```

**Step 3**: Create or update the remote data source:
```dart
class CustomerRemoteDataSource {
  Future<List<CustomerModel>> getCustomers(PaginationParams params) async {
    final response = await _apiClient.get<List<CustomerModel>>(
      ApiEndpoints.customers,
      queryParameters: params.toQueryParameters(),
      fromJson: (json) => (json as List)
          .map((e) => CustomerModel.fromJson(e))
          .toList(),
    );
    return response.data!;
  }
}
```

**Step 4**: Implement the repository:
```dart
class CustomerRepositoryImpl implements CustomerRepository {
  Future<Result<List<Customer>>> getCustomers(PaginationParams params) async {
    try {
      final models = await _remoteDataSource.getCustomers(params);
      return Success(models.map((m) => m.toDomain()).toList());
    } catch (e) {
      return Failure(ErrorMapper.toFailure(e));
    }
  }
}
```

**Step 5**: Create a use case (if needed):
```dart
class GetCustomersUseCase {
  Future<Result<List<Customer>>> call(PaginationParams params) =>
      _repository.getCustomers(params);
}
```

**Step 6**: Call from BLoC:
```dart
on<LoadCustomers>((event, emit) async {
  emit(const CustomerLoading());
  final result = await _getCustomersUseCase(params);
  switch (result) {
    case Success(:final value):
      emit(CustomerLoaded(customers: value, hasMore: false, currentPage: 1));
    case Failure(:final failure):
      emit(CustomerError(failure: failure));
  }
});
```

---

## Authentication Flow

### Startup

```
App starts
  → main() initializes DI
  → App widget provides global BLoCs
  → AuthBloc receives CheckAuthenticationStatus
  → GetCurrentUserUseCase → AuthRepository → SecureStorage
  → Token found: AuthAuthenticated → router → /dashboard
  → Token missing: AuthUnauthenticated → router → /login
```

### Login

```
LoginPage form submit
  → AuthBloc.add(LoginRequested)
  → LoginUseCase.call()
  → AuthRepository.login()
  → AuthRemoteDataSource → POST /auth/login
  → Save token to SecureStorage
  → AuthAuthenticated emitted
  → Router redirects to /dashboard
```

### Logout

```
User taps logout (ProfilePage)
  → AuthBloc.add(LogoutRequested)
  → LogoutUseCase.call()
  → AuthRepository.logout()
  → Delete token from SecureStorage
  → AuthUnauthenticated emitted
  → Router redirects to /login
```

### 401 Handling

```
AuthInterceptor detects 401 response
  → Deletes token from SecureStorage
  → Calls onUnauthorized callback
  → AuthBloc receives SessionExpired
  → AuthUnauthenticated emitted
  → Router redirects to /login
```

---

## Routing

All routes are defined in [`app_router.dart`](lib/app/router/app_router.dart).

**Never use** `Navigator.push()` directly. Always use:
```dart
context.go(RoutePaths.dashboard);
context.goNamed(RouteNames.customerDetails, pathParameters: {'customerId': id});
```

Route paths are in [`route_paths.dart`](lib/app/router/route_paths.dart).  
Route names are in [`route_names.dart`](lib/app/router/route_names.dart).

> **Important**: Flutter route paths (`/customers/:customerId`) are completely separate from backend API paths (`/customers/:id`). Never confuse the two.

### Adding a new route

1. Add path constant to `RoutePaths`:
   ```dart
   static const String emiList = '/emi';
   ```

2. Add name constant to `RouteNames`:
   ```dart
   static const String emiList = 'emiList';
   ```

3. Add `GoRoute` to `AppRouter._routes`:
   ```dart
   GoRoute(
     path: RoutePaths.emiList,
     name: RouteNames.emiList,
     builder: (context, state) => const EmiListPage(),
   ),
   ```

4. Navigate:
   ```dart
   context.goNamed(RouteNames.emiList);
   ```

---

## Localization

Translation files are in [`assets/translations/`](assets/translations/):
- `en.json` — English
- `hi.json` — Hindi
- `mr.json` — Marathi

Access translations in widgets:
```dart
// Via context extension (preferred)
Text(context.l10n.login)
Text(context.l10n.customers)

// Via AppLocalizations directly
Text(AppLocalizations.of(context).dashboard)
```

### Adding a new language

1. Create `assets/translations/XX.json` (where XX is the language code).
2. Add all required keys (copy from `en.json` and translate).
3. Add locale to `SupportedLocales.all` in `app_localizations.dart`:
   ```dart
   static const Locale tamil = Locale('ta');
   static const List<Locale> all = [english, hindi, marathi, tamil];
   ```
4. Re-run `flutter pub get` — no widget changes required.

---

## Theme

Theme is defined in [`app_theme.dart`](lib/app/theme/app_theme.dart).

```dart
AppTheme.light  // Light ThemeData
AppTheme.dark   // Dark ThemeData
```

Switch theme via `ThemeCubit`:
```dart
context.read<ThemeCubit>().setDark();
context.read<ThemeCubit>().setLight();
context.read<ThemeCubit>().setSystem();
```

### Store-specific themes

The backend may return custom colors:
```json
{ "primaryColor": "#6C5CE7", "secondaryColor": "#111827" }
```

Parse safely using:
```dart
final color = AppTheme.safeParseColor('#6C5CE7', fallback: AppColors.primary);
```

Apply store theme:
```dart
final storeTheme = AppTheme.storeTheme(
  base: AppTheme.light,
  primaryColorHex: user.storeTheme?.primaryColor,
);
```

---

## Secure Storage

| Data | Storage |
|------|---------|
| Access token | `SecureStorageService` (encrypted) |
| Refresh token | `SecureStorageService` (when supported) |
| Language preference | `LocalStorageService` (SharedPreferences) |
| Theme preference | `LocalStorageService` (SharedPreferences) |
| Cached user data | `LocalStorageService` (non-sensitive) |

Access via services (never SharedPreferences or FlutterSecureStorage directly):
```dart
// Read token
final token = await sl<SecureStorageService>().read(StorageKeys.accessToken);

// Save preference
await sl<LocalStorageService>().setString(StorageKeys.selectedLocale, 'hi');
```

---

## Error Handling

### Failure types

| Failure | Cause |
|---------|-------|
| `NetworkFailure` | No internet, timeout, connection error |
| `AuthenticationFailure` | 401 — token expired/missing |
| `AuthorizationFailure` | 403 — insufficient permissions |
| `NotFoundFailure` | 404 |
| `ConflictFailure` | 409 |
| `ValidationFailure` | 422 — server-side validation |
| `ServerFailure` | 5xx |
| `UnknownFailure` | Unexpected errors |

### In BLoC

```dart
switch (result) {
  case Success(:final value):
    emit(CustomerLoaded(customers: value));
  case Failure(:final failure):
    emit(CustomerError(failure: failure));
}
```

### In UI

```dart
AppErrorView(
  message: state.failure.message,
  onRetry: () => bloc.add(const LoadCustomers()),
)
```

---

## Testing

### Run all tests

```bash
flutter test
```

### Test structure

```
test/
├── core/
│   └── utils/
│       ├── validation_utils_test.dart
│       └── currency_utils_test.dart
└── features/
    └── auth/
        └── auth_bloc_test.dart
```

### BLoC test pattern

```dart
blocTest<AuthBloc, AuthState>(
  'emits [AuthLoading, AuthAuthenticated] on successful login',
  build: () => AuthBloc(loginUseCase: mockLogin, ...),
  setUp: () {
    when(() => mockLogin(...)).thenAnswer((_) async => Success(session));
  },
  act: (bloc) => bloc.add(LoginRequested(...)),
  expect: () => [isA<AuthLoading>(), isA<AuthAuthenticated>()],
);
```

---

## Code Generation

If using `json_serializable` for models:

```bash
dart run build_runner build --delete-conflicting-outputs
```

For continuous generation during development:
```bash
dart run build_runner watch --delete-conflicting-outputs
```

Generated files (`*.g.dart`) are excluded from version control and analyzer.

---

## How To: Add a New Feature

Example: Adding a `notifications` feature.

```bash
# 1. Create folder structure
mkdir -p lib/features/notifications/{data/{datasources,models,repositories},domain/{entities,repositories,usecases},presentation/{bloc,pages,widgets}}
```

```
# 2. Follow this checklist:
```

- [ ] Create domain entity: `lib/features/notifications/domain/entities/notification.dart`
- [ ] Create repository interface: `lib/features/notifications/domain/repositories/notifications_repository.dart`
- [ ] Create use case: `lib/features/notifications/domain/usecases/get_notifications_usecase.dart`
- [ ] Create request/response models in `data/models/`
- [ ] Create remote data source in `data/datasources/`
- [ ] Create repository implementation in `data/repositories/`
- [ ] Create BLoC (event/state/bloc) in `presentation/bloc/`
- [ ] Create page in `presentation/pages/`
- [ ] Add API endpoint to `core/constants/api_constants.dart`
- [ ] Register in `core/di/injection_container.dart`
- [ ] Add route to `app/router/` (route_names, route_paths, app_router)
- [ ] Add translation keys to all `assets/translations/*.json` files
- [ ] Write tests

---

## Packages

| Package | Purpose |
|---------|---------|
| `flutter_bloc` | State management |
| `equatable` | Value equality for states/events |
| `dio` | HTTP client |
| `go_router` | Navigation |
| `get_it` | Dependency injection |
| `flutter_secure_storage` | Encrypted token storage |
| `shared_preferences` | Non-sensitive local preferences |
| `connectivity_plus` | Network connectivity detection |
| `cached_network_image` | Remote image loading |
| `intl` | Date/number formatting |
| `json_annotation` + `json_serializable` | Type-safe JSON serialization |
| `bloc_test` | BLoC unit testing utilities |
| `mocktail` | Mocking for tests |
