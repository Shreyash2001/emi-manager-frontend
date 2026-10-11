import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_emi_manager/app/config/app_config.dart';
import 'package:mobile_emi_manager/app/localization/locale_cubit.dart';
import 'package:mobile_emi_manager/app/theme/theme_cubit.dart';
import 'package:mobile_emi_manager/core/network/api_cache_manager.dart';
import 'package:mobile_emi_manager/core/network/api_client.dart';
import 'package:mobile_emi_manager/core/network/auth_interceptor.dart';
import 'package:mobile_emi_manager/core/network/logging_interceptor.dart';
import 'package:mobile_emi_manager/core/network/network_info.dart';
import 'package:mobile_emi_manager/core/storage/local_storage_service.dart';
import 'package:mobile_emi_manager/core/storage/secure_storage_service.dart';

// ─── Auth ─────────────────────────────────────────────────────────────────────
import 'package:mobile_emi_manager/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:mobile_emi_manager/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mobile_emi_manager/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile_emi_manager/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:mobile_emi_manager/features/auth/domain/usecases/login_usecase.dart';
import 'package:mobile_emi_manager/features/auth/domain/usecases/logout_usecase.dart';
import 'package:mobile_emi_manager/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mobile_emi_manager/features/auth/presentation/bloc/auth_event.dart';

// ─── Dashboard ────────────────────────────────────────────────────────────────
import 'package:mobile_emi_manager/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:mobile_emi_manager/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:mobile_emi_manager/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:mobile_emi_manager/features/dashboard/presentation/bloc/dashboard_bloc.dart';

// ─── Customers ────────────────────────────────────────────────────────────────
import 'package:mobile_emi_manager/features/customers/data/datasources/customer_remote_datasource.dart';
import 'package:mobile_emi_manager/features/customers/data/repositories/customer_repository_impl.dart';
import 'package:mobile_emi_manager/features/customers/domain/repositories/customer_repository.dart';
import 'package:mobile_emi_manager/features/customers/presentation/bloc/customer_bloc.dart';

// ─── EMI Plans ────────────────────────────────────────────────────────────────
import 'package:mobile_emi_manager/features/emi/data/datasources/emi_remote_datasource.dart';
import 'package:mobile_emi_manager/features/emi/data/repositories/emi_repository_impl.dart';
import 'package:mobile_emi_manager/features/emi/domain/repositories/emi_repository.dart';
import 'package:mobile_emi_manager/features/emi/presentation/bloc/emi_bloc.dart';

// ─── Payments ─────────────────────────────────────────────────────────────────
import 'package:mobile_emi_manager/features/payments/data/datasources/payment_remote_datasource.dart';
import 'package:mobile_emi_manager/features/payments/data/repositories/payment_repository_impl.dart';
import 'package:mobile_emi_manager/features/payments/domain/repositories/payment_repository.dart';
import 'package:mobile_emi_manager/features/payments/presentation/bloc/payment_bloc.dart';

// ─── Reports ──────────────────────────────────────────────────────────────────
import 'package:mobile_emi_manager/features/reports/data/datasources/reports_remote_datasource.dart';
import 'package:mobile_emi_manager/features/reports/data/repositories/reports_repository_impl.dart';
import 'package:mobile_emi_manager/features/reports/domain/repositories/reports_repository.dart';
import 'package:mobile_emi_manager/features/reports/presentation/bloc/reports_bloc.dart';

// ─── Admin ────────────────────────────────────────────────────────────────────
import 'package:mobile_emi_manager/features/admin/data/datasources/admin_remote_datasource.dart';
import 'package:mobile_emi_manager/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:mobile_emi_manager/features/admin/domain/repositories/admin_repository.dart';
import 'package:mobile_emi_manager/features/admin/presentation/bloc/admin_bloc.dart';

/// Global service locator instance.
final sl = GetIt.instance;

/// Initialize all dependencies.
///
/// Call this once from [main()] before [runApp()].
/// Order matters: lower-level dependencies must be registered first.
Future<void> initializeDependencies(AppConfig config) async {
  // ─── External Dependencies ─────────────────────────────────────────────────
  final sharedPrefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(sharedPrefs);
  sl.registerSingleton<Connectivity>(Connectivity());

  // ─── Config ───────────────────────────────────────────────────────────────
  sl.registerSingleton<AppConfig>(config);

  // ─── Storage ──────────────────────────────────────────────────────────────
  sl.registerSingleton<SecureStorageService>(
    SecureStorageService(storage: const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    )),
  );

  sl.registerSingleton<LocalStorageService>(
    LocalStorageService(prefs: sl<SharedPreferences>()),
  );

  // ─── Network ──────────────────────────────────────────────────────────────
  sl.registerSingleton<NetworkInfo>(
    NetworkInfoImpl(connectivity: sl<Connectivity>()),
  );

  // Cache manager with 15-minute TTL
  final cacheManager = ApiCacheManager(defaultTtl: config.cacheTtl);
  sl.registerSingleton<ApiCacheManager>(cacheManager);

  // Auth interceptor (needs SecureStorage for token reading and cacheManager for clearing cache on 401)
  final authInterceptor = AuthInterceptor(
    secureStorage: sl<SecureStorageService>(),
    cacheManager: cacheManager,
  );
  sl.registerSingleton<AuthInterceptor>(authInterceptor);

  // Configure Dio
  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: config.connectTimeout,
      receiveTimeout: config.requestTimeout,
      sendTimeout: config.requestTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Add interceptors (logging first, then auth)
  if (config.enableLogging) {
    dio.interceptors.add(LoggingInterceptor());
  }
  dio.interceptors.add(authInterceptor);

  sl.registerSingleton<ApiClient>(
    ApiClient(
      config: config,
      dio: dio,
      cacheManager: sl<ApiCacheManager>(),
    ),
  );

  // ─── Data Sources ─────────────────────────────────────────────────────────
  // Auth: Always use real datasource (mock is only a fallback in the datasource itself)
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(apiClient: sl<ApiClient>()),
  );

  sl.registerLazySingleton<DashboardRemoteDataSource>(
    () => DashboardRemoteDataSourceImpl(apiClient: sl<ApiClient>()),
  );

  sl.registerLazySingleton<CustomerRemoteDataSource>(
    () => CustomerRemoteDataSourceImpl(apiClient: sl<ApiClient>()),
  );

  sl.registerLazySingleton<EmiRemoteDataSource>(
    () => EmiRemoteDataSourceImpl(apiClient: sl<ApiClient>()),
  );

  sl.registerLazySingleton<PaymentRemoteDataSource>(
    () => PaymentRemoteDataSourceImpl(apiClient: sl<ApiClient>()),
  );

  sl.registerLazySingleton<ReportsRemoteDataSource>(
    () => ReportsRemoteDataSourceImpl(apiClient: sl<ApiClient>()),
  );

  sl.registerLazySingleton<AdminRemoteDataSource>(
    () => AdminRemoteDataSourceImpl(apiClient: sl<ApiClient>()),
  );

  // ─── Repositories ─────────────────────────────────────────────────────────
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl<AuthRemoteDataSource>(),
      secureStorage: sl<SecureStorageService>(),
      localStorage: sl<LocalStorageService>(),
    ),
  );

  sl.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(
      remoteDataSource: sl<DashboardRemoteDataSource>(),
    ),
  );

  sl.registerLazySingleton<CustomerRepository>(
    () => CustomerRepositoryImpl(
      remoteDataSource: sl<CustomerRemoteDataSource>(),
    ),
  );

  sl.registerLazySingleton<EmiRepository>(
    () => EmiRepositoryImpl(
      remoteDataSource: sl<EmiRemoteDataSource>(),
    ),
  );

  sl.registerLazySingleton<PaymentRepository>(
    () => PaymentRepositoryImpl(
      remoteDataSource: sl<PaymentRemoteDataSource>(),
    ),
  );

  sl.registerLazySingleton<ReportsRepository>(
    () => ReportsRepositoryImpl(
      remoteDataSource: sl<ReportsRemoteDataSource>(),
    ),
  );

  sl.registerLazySingleton<AdminRepository>(
    () => AdminRepositoryImpl(
      remoteDataSource: sl<AdminRemoteDataSource>(),
    ),
  );

  // ─── Use Cases ────────────────────────────────────────────────────────────
  sl.registerLazySingleton(() => LoginUseCase(repository: sl<AuthRepository>()));
  sl.registerLazySingleton(() => LogoutUseCase(repository: sl<AuthRepository>()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(repository: sl<AuthRepository>()));

  // ─── Global BLoCs / Cubits ────────────────────────────────────────────────
  sl.registerSingleton<AuthBloc>(
    AuthBloc(
      loginUseCase: sl<LoginUseCase>(),
      logoutUseCase: sl<LogoutUseCase>(),
      getCurrentUserUseCase: sl<GetCurrentUserUseCase>(),
    ),
  );

  sl.registerSingleton<ThemeCubit>(
    ThemeCubit(storage: sl<LocalStorageService>()),
  );

  sl.registerSingleton<LocaleCubit>(
    LocaleCubit(storage: sl<LocalStorageService>()),
  );

  // ─── Feature BLoCs (registered as factories so each screen gets a fresh instance) ──
  sl.registerLazySingleton<DashboardBloc>(
    () => DashboardBloc(dashboardRepository: sl<DashboardRepository>()),
  );

  sl.registerFactory<CustomerBloc>(
    () => CustomerBloc(customerRepository: sl<CustomerRepository>()),
  );

  sl.registerFactory<EMIBloc>(
    () => EMIBloc(emiRepository: sl<EmiRepository>()),
  );

  sl.registerFactory<PaymentBloc>(
    () => PaymentBloc(paymentRepository: sl<PaymentRepository>()),
  );

  sl.registerFactory<ReportsBloc>(
    () => ReportsBloc(
      reportsRepository: sl<ReportsRepository>(),
      paymentRepository: sl<PaymentRepository>(),
    ),
  );

  sl.registerFactory<AdminBloc>(
    () => AdminBloc(adminRepository: sl<AdminRepository>()),
  );

  // Wire up AuthInterceptor → AuthBloc for 401 handling
  authInterceptor.onUnauthorized = () {
    sl<AuthBloc>().add(const SessionExpired());
  };
}
