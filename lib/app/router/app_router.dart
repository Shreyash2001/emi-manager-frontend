import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_emi_manager/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mobile_emi_manager/features/auth/presentation/bloc/auth_state.dart';
import 'package:mobile_emi_manager/features/auth/presentation/pages/login_page.dart';
import 'package:mobile_emi_manager/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:mobile_emi_manager/features/customers/presentation/pages/customers_page.dart';
import 'package:mobile_emi_manager/features/customers/presentation/pages/add_customer_page.dart';
import 'package:mobile_emi_manager/features/customers/presentation/pages/add_device_page.dart';
import 'package:mobile_emi_manager/features/customers/presentation/pages/customer_details_page.dart';
import 'package:mobile_emi_manager/features/payments/presentation/pages/payments_page.dart';
import 'package:mobile_emi_manager/features/payments/presentation/pages/record_payment_page.dart';
import 'package:mobile_emi_manager/features/reports/presentation/pages/reports_page.dart';
import 'package:mobile_emi_manager/features/profile/presentation/pages/profile_page.dart';
import 'package:mobile_emi_manager/features/admin/presentation/pages/admin_page.dart';
import 'package:mobile_emi_manager/features/emi/presentation/pages/emi_details_page.dart';
import 'package:mobile_emi_manager/features/emi/presentation/pages/add_emi_page.dart';
import 'package:mobile_emi_manager/app/router/route_names.dart';
import 'package:mobile_emi_manager/app/router/route_paths.dart';
import 'package:mobile_emi_manager/core/di/injection_container.dart';
import 'package:mobile_emi_manager/core/widgets/app_loader.dart';
import 'package:mobile_emi_manager/features/dashboard/presentation/bloc/dashboard_bloc.dart';

/// Central router configuration for the app.
/// All navigation must go through this router — no raw Navigator.push() calls.
class AppRouter {
  final AuthBloc authBloc;

  AppRouter({required this.authBloc});

  late final GoRouter router = GoRouter(
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: true,
    redirect: _handleRedirect,
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        builder: (context, state) => const _SplashPage(),
      ),
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => _AppShell(child: child),
        routes: [
          GoRoute(
            path: RoutePaths.dashboard,
            name: RouteNames.dashboard,
            builder: (context, state) {
              sl<DashboardBloc>().add(const LoadDashboard());
              return DashboardPage(key: state.pageKey);
            },
          ),
          GoRoute(
            path: RoutePaths.customers,
            name: RouteNames.customers,
            builder: (context, state) => const CustomersPage(),
          ),
          GoRoute(
            path: RoutePaths.addCustomer,
            name: RouteNames.addCustomer,
            builder: (context, state) => const AddCustomerPage(),
          ),
          GoRoute(
            path: RoutePaths.addDevice,
            name: RouteNames.addDevice,
            builder: (context, state) {
              final extra = state.extra;
              String? custId;
              if (extra is Map) {
                custId = extra['customerId']?.toString();
              } else if (extra is String) {
                custId = extra;
              }
              custId ??= state.uri.queryParameters['customerId'];
              return AddDevicePage(initialCustomerId: custId);
            },
          ),
          GoRoute(
            path: RoutePaths.customerDetails,
            name: RouteNames.customerDetails,
            builder: (context, state) {
              final customerId = state.pathParameters['customerId']!;
              return CustomerDetailsPage(customerId: customerId);
            },
          ),
          GoRoute(
            path: RoutePaths.addEmi,
            name: RouteNames.addEmi,
            builder: (context, state) => const AddEmiPage(),
          ),
          GoRoute(
            path: RoutePaths.emiDetails,
            name: RouteNames.emiDetails,
            builder: (context, state) {
              final emiPlanId = state.pathParameters['emiPlanId']!;
              return EmiDetailsPage(emiPlanId: emiPlanId);
            },
          ),
          GoRoute(
            path: RoutePaths.payments,
            name: RouteNames.payments,
            builder: (context, state) => const PaymentsPage(),
          ),
          GoRoute(
            path: RoutePaths.recordPayment,
            name: RouteNames.recordPayment,
            builder: (context, state) {
              final extra = state.extra;
              String? custId;
              String? planId;
              if (extra is Map) {
                custId = extra['customerId']?.toString();
                planId = extra['emiPlanId']?.toString();
              } else if (extra is String) {
                custId = extra;
              }
              custId ??= state.uri.queryParameters['customerId'];
              planId ??= state.uri.queryParameters['emiPlanId'];
              return RecordPaymentPage(
                initialCustomerId: custId,
                initialEmiPlanId: planId,
              );
            },
          ),
          GoRoute(
            path: RoutePaths.reports,
            name: RouteNames.reports,
            builder: (context, state) => const ReportsPage(),
          ),
          GoRoute(
            path: RoutePaths.profile,
            name: RouteNames.profile,
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),
      // Admin routes (SUPER_ADMIN only)
      GoRoute(
        path: RoutePaths.admin,
        name: RouteNames.admin,
        builder: (context, state) => const AdminPage(),
        routes: [
          GoRoute(
            path: 'stores',
            name: RouteNames.adminStores,
            builder: (context, state) => const AdminPage(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => _ErrorPage(error: state.error),
  );

  String? _handleRedirect(BuildContext context, GoRouterState state) {
    final authState = authBloc.state;
    final location = state.matchedLocation;

    final isOnSplash = location == RoutePaths.splash;
    final isOnLogin = location == RoutePaths.login;

    // While checking auth, stay on splash
    if (authState is AuthInitial || authState is AuthLoading) {
      return isOnSplash ? null : RoutePaths.splash;
    }

    // Authenticated
    if (authState is AuthAuthenticated) {
      if (isOnLogin || isOnSplash) {
        return RoutePaths.dashboard;
      }
      return null;
    }

    // Unauthenticated
    if (authState is AuthUnauthenticated) {
      if (isOnLogin) return null;
      return RoutePaths.login;
    }

    // AuthError — go to login
    if (authState is AuthError) {
      if (isOnLogin) return null;
      return RoutePaths.login;
    }

    return null;
  }
}

/// Simple splash/loading page shown during auth check.
class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: AppLoader()));
  }
}

/// App shell that wraps authenticated pages with bottom navigation.
class _AppShell extends StatelessWidget {
  final Widget child;

  const _AppShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: _BottomNav(),
    );
  }
}

class _BottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    int currentIndex = 0;
    if (location.startsWith('/customers')) {
      currentIndex = 1;
    } else if (location.startsWith('/reports')) {
      currentIndex = 2;
    }

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        switch (index) {
          case 0:
            sl<DashboardBloc>().add(const LoadDashboard());
            context.go(RoutePaths.dashboard);
          case 1:
            context.go(RoutePaths.customers);
          case 2:
            context.go(RoutePaths.reports);
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.storefront_rounded),
          activeIcon: Icon(Icons.storefront_rounded),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline_rounded),
          activeIcon: Icon(Icons.people_rounded),
          label: 'Customers',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart_rounded),
          activeIcon: Icon(Icons.bar_chart_rounded),
          label: 'Reports',
        ),
      ],
    );
  }
}

class _ErrorPage extends StatelessWidget {
  final Exception? error;

  const _ErrorPage({this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Page not found', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => context.go(RoutePaths.dashboard),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}

/// A [ChangeNotifier] that listens to a [Stream] and notifies listeners
/// whenever a new event is emitted. Used to trigger go_router refreshes.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    (_subscription as dynamic).cancel();
    super.dispose();
  }
}
