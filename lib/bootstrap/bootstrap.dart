import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../src/app.dart';
import '../src/config/app_config.dart';
import '../src/config/language/languages.dart';
import '../src/config/res/config_imports.dart';
import '../src/core/navigation/constants/imports_constants.dart';
import '../src/core/navigation/transition/implementation/fade/option/fade_animation_option.dart';
import '../src/core/navigation/page_router/implementation/imports_page_router.dart';
import '../src/core/navigation/page_router/imports_page_router_builder.dart';
import '../src/core/network/cache/cache_config.dart';
import '../src/core/network/dio_client.dart';
import '../src/core/network/api_endpoints.dart';
import '../src/core/network/offline/offline_queue_manager.dart';
import '../src/core/session/image_cache_cleanup.dart';
import '../src/core/session/session_cleanup.dart';
import '../src/core/session/session_failure_coordinator.dart';
import '../src/core/shared/cubits/user_cubit/user_cubit.dart';
import '../src/core/shared/helpers/helpers.dart';
import '../src/core/shared/observer/bloc_observer.dart';
import '../src/core/shared/service_locators/setup_service_locators.dart';
import '../src/core/startup/startup_coordinator.dart';
import '../src/core/widgets/exception_view.dart';
import 'app_environment.dart';
import 'global_error_handlers.dart';

/// Starts the application.
///
/// [onError] receives every uncaught error (see [AppErrorReporter]); pass a
/// crash reporter from the product's `main_*.dart`. The binding is
/// initialized inside the guarded zone so `runApp` runs in the same zone as
/// `ensureInitialized` (Flutter warns about a zone mismatch otherwise).
void bootstrap(AppEnvironment environment, {AppErrorReporter? onError}) {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();
    installGlobalErrorHandlers(reporter: onError);
    return _start(environment);
  }, (error, stackTrace) => reportZoneError(onError, error, stackTrace));
}

Future<void> _start(AppEnvironment environment) async {
  final coordinator = StartupCoordinator([
    StartupTask(
      id: 'localization',
      kind: StartupTaskKind.critical,
      timeout: const Duration(seconds: 8),
      action: EasyLocalization.ensureInitialized,
    ),
    StartupTask(
      id: 'screen_metrics',
      kind: StartupTaskKind.critical,
      timeout: const Duration(seconds: 5),
      action: ScreenUtil.ensureScreenSize,
    ),
    StartupTask(
      id: 'composition_root',
      kind: StartupTaskKind.critical,
      action: () => _configureCompositionRoot(environment),
    ),
    StartupTask(
      id: 'local_persistence',
      kind: StartupTaskKind.optional,
      timeout: const Duration(seconds: 12),
      action: () async {
        await Hive.initFlutter();
        await CacheConfig.init();
        await OfflineQueueManager().init();
      },
    ),
    StartupTask(
      id: 'session_restore',
      kind: StartupTaskKind.nonBlocking,
      timeout: const Duration(seconds: 8),
      action: () => injector<UserCubit>().init(),
    ),
    StartupTask(
      id: 'preferred_orientations',
      kind: StartupTaskKind.deferred,
      timeout: const Duration(seconds: 4),
      action: () => SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]),
    ),
  ], onBackgroundResult: _reportBackgroundResult);

  final report = await coordinator.runCritical();
  if (!report.succeeded) {
    for (final failure in report.failures) {
      _reportBootstrapError(
        failure.error ?? StateError('Startup task ${failure.id} failed.'),
        failure.stackTrace ?? StackTrace.current,
      );
    }
    runApp(_BootstrapFailureApp(onRetry: () => _start(environment)));
    return;
  }

  _runApplication();
  coordinator.startBackground();
  unawaited(coordinator.runDeferred());
}

void _configureCompositionRoot(AppEnvironment environment) {
  if (kDebugMode) Bloc.observer = AppBlocObserver();
  final apiUri = Uri.parse(ApiEndpoints.baseUrl);
  environment.validate(apiBaseUri: apiUri, tlsPins: AppConfig.tlsPins);
  setUpServiceLocator();
  final userCubit = injector<UserCubit>();
  DioClient().onAuthFailure = userCubit.sessionRevoked;
  if (AppConfig.tlsPins.isNotEmpty) {
    DioClient().enableCertificatePinning(
      AppConfig.tlsPins,
      allowedHosts: {apiUri.host},
    );
  }
  // Cached images may be private to the signed-in account (avatars, chat
  // attachments); do not leave them readable by the next account on the device.
  SessionCleanupRegistry.instance.register(
    SessionCleanupHook(id: 'image_cache', action: clearImageCaches),
  );
  final sessionFailures = SessionFailureCoordinator.instance;
  sessionFailures.onUnauthorized = userCubit.sessionRevoked;
  sessionFailures.onBlocked = (message) =>
      userCubit.markBlocked(message: message);
  sessionFailures.onNeedsActivation = (message, activationData) => userCubit
      .markNeedsActivation(message: message, activationData: activationData);

  PageRouterBuilder().initAppRouter(
    config: PlatformConfig(
      android: CustomPageRouterCreator(
        parentTransition: TransitionType.fade,
        parentOptions: const FadeAnimationOptions(
          duration: Duration(milliseconds: 300),
        ),
      ),
    ),
  );

  Animate.restartOnHotReload = true;
  if (kReleaseMode) ErrorWidget.builder = (_) => const ExceptionView();
  Helpers.changeStatusbarColor(statusBarColor: Colors.transparent);
}

void _runApplication() {
  runApp(
    EasyLocalization(
      supportedLocales: Languages.supportLocales,
      path: 'assets/translations',
      fallbackLocale: const Locale('ar'),
      saveLocale: true,
      child: const App(),
    ),
  );
}

void _reportBackgroundResult(StartupTaskResult result) {
  if (result.succeeded) return;
  _reportBootstrapError(
    result.error ?? StateError('Background startup task ${result.id} failed.'),
    result.stackTrace ?? StackTrace.current,
  );
}

void _reportBootstrapError(Object error, StackTrace stackTrace) {
  FlutterError.reportError(
    FlutterErrorDetails(
      exception: error,
      stack: stackTrace,
      library: 'application bootstrap',
    ),
  );
}

final class _BootstrapFailureApp extends StatefulWidget {
  const _BootstrapFailureApp({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  State<_BootstrapFailureApp> createState() => _BootstrapFailureAppState();
}

final class _BootstrapFailureAppState extends State<_BootstrapFailureApp> {
  bool _retrying = false;

  Future<void> _retry() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    try {
      await widget.onRetry();
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'The application could not start.\n'
                    'تعذر تشغيل التطبيق بأمان.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _retrying ? null : _retry,
                    child: _retrying
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Retry / إعادة المحاولة'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
