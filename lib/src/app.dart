import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'config/res/config_imports.dart';
import 'config/themes/app_theme.dart';
import 'core/navigation/named_routes.dart';
import 'core/navigation/navigator.dart';
import 'core/navigation/route_generator.dart';
import 'core/network/cubits/connectivity_cubit.dart';
import 'core/network/cubits/offline_queue_cubit.dart';
import 'core/session/session_navigation_coordinator.dart';
import 'core/shared/cubits/user_cubit/user_cubit.dart';

final SessionNavigationCoordinator _sessionNavigation =
    SessionNavigationCoordinator(navigatorKey: Go.navigatorKey);

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (_, child) => MultiBlocProvider(
        providers: [
          BlocProvider<UserCubit>.value(value: injector<UserCubit>()),
          BlocProvider<ConnectivityCubit>.value(
            value: injector<ConnectivityCubit>(),
          ),
          BlocProvider<OfflineQueueCubit>.value(
            value: injector<OfflineQueueCubit>(),
          ),
        ],
        child: BlocListener<UserCubit, UserState>(
          listenWhen: (previous, current) =>
              previous.userStatus != current.userStatus,
          listener: (_, state) => _sessionNavigation.handle(state),
          child: MaterialApp(
            title: ConstantManager.appName,
            debugShowCheckedModeBanner: false,
            navigatorKey: Go.navigatorKey,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: ThemeMode.system,
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            onGenerateRoute: RouterGenerator.getRoute,
            initialRoute: NamedRoutes.root.routeName,
          ),
        ),
      ),
    );
  }
}
