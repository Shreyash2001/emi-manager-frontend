import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mobile_emi_manager/app/localization/app_localizations.dart';
import 'package:mobile_emi_manager/app/localization/locale_cubit.dart';
import 'package:mobile_emi_manager/app/router/app_router.dart';
import 'package:mobile_emi_manager/app/theme/app_theme.dart';
import 'package:mobile_emi_manager/app/theme/theme_cubit.dart';
import 'package:mobile_emi_manager/core/di/injection_container.dart';
import 'package:mobile_emi_manager/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mobile_emi_manager/features/auth/presentation/bloc/auth_event.dart';

/// Root application widget.
///
/// Responsibilities:
///   - Provide global BLoCs (AuthBloc, ThemeCubit, LocaleCubit)
///   - Configure MaterialApp.router with go_router
///   - Set up localization delegates
///   - Apply theme
///
/// Does NOT contain business logic.
class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _appRouter = AppRouter(authBloc: sl<AuthBloc>());

    // Trigger initial auth check and preference loading.
    sl<AuthBloc>().add(const CheckAuthenticationStatus());
    sl<ThemeCubit>().loadTheme();
    sl<LocaleCubit>().loadLocale();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: sl<AuthBloc>()),
        BlocProvider.value(value: sl<ThemeCubit>()),
        BlocProvider.value(value: sl<LocaleCubit>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          return BlocBuilder<LocaleCubit, LocaleState>(
            builder: (context, localeState) {
              return MaterialApp.router(
                title: 'EMI Manager',
                debugShowCheckedModeBanner: false,

                // Theme
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: themeState.themeMode,

                // Routing
                routerConfig: _appRouter.router,

                // Localization
                locale: localeState.locale,
                supportedLocales: SupportedLocales.all,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
              );
            },
          );
        },
      ),
    );
  }
}
