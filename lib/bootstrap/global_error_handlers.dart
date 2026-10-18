import 'package:flutter/foundation.dart';

/// Receives every error that reaches the global handlers. Wire a crash
/// reporter (Crashlytics, Sentry, …) here from the product's entry point.
///
/// [fatal] is `true` only for errors that escaped every guard (`runZonedGuarded`
/// and `PlatformDispatcher`); framework errors that Flutter already recovered
/// from (a widget build failure) are reported with `fatal: false`.
///
/// The reporter must never include request data, tokens or personal
/// information in what it sends; the base itself never passes any.
typedef AppErrorReporter = void Function(
  Object error,
  StackTrace stackTrace, {
  required bool fatal,
});

/// Installs the process-wide error handlers once at startup.
///
/// * `FlutterError.onError`: framework errors (build/layout/paint, gestures).
///   Still printed by `FlutterError.presentError`, then forwarded.
/// * `PlatformDispatcher.onError`: uncaught asynchronous errors that never
///   reach a zone (plugin callbacks, engine callbacks). Returning `true` marks
///   them handled so the process is not torn down by the default handler.
///
/// A throwing [reporter] is contained: error reporting must never be the
/// reason an app crashes.
void installGlobalErrorHandlers({AppErrorReporter? reporter}) {
  void report(Object error, StackTrace stackTrace, {required bool fatal}) {
    try {
      reporter?.call(error, stackTrace, fatal: fatal);
    } catch (_) {
      // Never let the reporter take the app down.
    }
  }

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    report(details.exception, details.stack ?? StackTrace.empty, fatal: false);
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stackTrace) {
    report(error, stackTrace, fatal: true);
    if (kDebugMode) {
      debugPrint('Uncaught asynchronous error: ${error.runtimeType}');
    }
    return true;
  };
}

/// Reports an error caught by the root `runZonedGuarded`.
void reportZoneError(
  AppErrorReporter? reporter,
  Object error,
  StackTrace stackTrace,
) {
  try {
    reporter?.call(error, stackTrace, fatal: true);
  } catch (_) {
    // See installGlobalErrorHandlers.
  }
  if (kDebugMode) debugPrint('Uncaught zone error: ${error.runtimeType}');
}
