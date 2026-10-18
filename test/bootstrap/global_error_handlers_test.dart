import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_base/bootstrap/global_error_handlers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FlutterExceptionHandler? previousFlutterHandler;
  late ErrorCallback? previousPlatformHandler;

  setUp(() {
    previousFlutterHandler = FlutterError.onError;
    previousPlatformHandler = PlatformDispatcher.instance.onError;
  });

  tearDown(() {
    FlutterError.onError = previousFlutterHandler;
    PlatformDispatcher.instance.onError = previousPlatformHandler;
  });

  test('framework errors are presented and reported as non-fatal', () {
    final reports = <(Object, bool)>[];
    installGlobalErrorHandlers(
      reporter: (error, stack, {required fatal}) => reports.add((error, fatal)),
    );
    final presented = <FlutterErrorDetails>[];
    final originalPresent = FlutterError.presentError;
    FlutterError.presentError = presented.add;
    addTearDown(() => FlutterError.presentError = originalPresent);

    final error = StateError('build failed');
    FlutterError.onError!(FlutterErrorDetails(exception: error));

    expect(presented, hasLength(1));
    expect(reports, [(error, false)]);
  });

  test('uncaught async errors are reported as fatal and marked handled', () {
    final reports = <(Object, StackTrace, bool)>[];
    installGlobalErrorHandlers(
      reporter: (error, stack, {required fatal}) =>
          reports.add((error, stack, fatal)),
    );

    final error = Exception('plugin callback');
    final stack = StackTrace.current;
    final handled = PlatformDispatcher.instance.onError!(error, stack);

    expect(handled, isTrue);
    expect(reports.single.$1, error);
    expect(reports.single.$2, stack);
    expect(reports.single.$3, isTrue);
  });

  test('a reporter that throws never propagates', () {
    installGlobalErrorHandlers(
      reporter: (error, stack, {required fatal}) =>
          throw StateError('reporter down'),
    );
    final originalPresent = FlutterError.presentError;
    FlutterError.presentError = (_) {};
    addTearDown(() => FlutterError.presentError = originalPresent);

    expect(
      () => FlutterError.onError!(FlutterErrorDetails(exception: 'x')),
      returnsNormally,
    );
    expect(PlatformDispatcher.instance.onError!('y', StackTrace.empty), isTrue);
    expect(
      () => reportZoneError(
        (e, s, {required fatal}) => throw StateError('down'),
        'z',
        StackTrace.empty,
      ),
      returnsNormally,
    );
  });

  test('installing without a reporter still handles errors safely', () {
    installGlobalErrorHandlers();
    expect(PlatformDispatcher.instance.onError!('e', StackTrace.empty), isTrue);
    expect(() => reportZoneError(null, 'e', StackTrace.empty), returnsNormally);
  });
}
