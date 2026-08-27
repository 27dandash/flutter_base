import 'dart:async';

enum StartupTaskKind { critical, nonBlocking, optional, deferred }

enum StartupTaskStatus { succeeded, failed, timedOut }

typedef StartupAction = FutureOr<void> Function();

final class StartupTask {
  const StartupTask({
    required this.id,
    required this.kind,
    required this.action,
    this.timeout = const Duration(seconds: 8),
  });

  final String id;
  final StartupTaskKind kind;
  final StartupAction action;
  final Duration timeout;
}

final class StartupTaskResult {
  const StartupTaskResult({
    required this.id,
    required this.kind,
    required this.status,
    required this.elapsed,
    this.error,
    this.stackTrace,
  });

  final String id;
  final StartupTaskKind kind;
  final StartupTaskStatus status;
  final Duration elapsed;
  final Object? error;
  final StackTrace? stackTrace;

  bool get succeeded => status == StartupTaskStatus.succeeded;
}

final class StartupReport {
  const StartupReport(this.results);

  final List<StartupTaskResult> results;

  bool get succeeded => results.every((result) => result.succeeded);

  Iterable<StartupTaskResult> get failures =>
      results.where((result) => !result.succeeded);
}

/// Executes startup work once, with bounded waits and explicit ownership.
///
/// Critical work is the only work callers should await before [runApp].
/// Non-blocking and optional work is deliberately started afterwards and its
/// failure is reported without keeping the native splash screen alive.
final class StartupCoordinator {
  StartupCoordinator(Iterable<StartupTask> tasks, {this.onBackgroundResult})
    : _tasks = List<StartupTask>.unmodifiable(tasks) {
    final ids = _tasks.map((task) => task.id).toSet();
    if (ids.length != _tasks.length) {
      throw ArgumentError('Startup task ids must be unique.');
    }
  }

  final List<StartupTask> _tasks;
  final void Function(StartupTaskResult result)? onBackgroundResult;
  final Map<String, Future<StartupTaskResult>> _runs = {};

  Future<StartupReport> runCritical() =>
      _runKinds(const {StartupTaskKind.critical});

  void startBackground() {
    for (final task in _tasks.where(
      (task) =>
          task.kind == StartupTaskKind.nonBlocking ||
          task.kind == StartupTaskKind.optional,
    )) {
      unawaited(
        _runTask(task).then((result) => onBackgroundResult?.call(result)),
      );
    }
  }

  Future<StartupReport> runDeferred() =>
      _runKinds(const {StartupTaskKind.deferred});

  Future<StartupReport> _runKinds(Set<StartupTaskKind> kinds) async {
    final results = <StartupTaskResult>[];
    for (final task in _tasks.where((task) => kinds.contains(task.kind))) {
      results.add(await _runTask(task));
    }
    return StartupReport(List<StartupTaskResult>.unmodifiable(results));
  }

  Future<StartupTaskResult> _runTask(StartupTask task) {
    return _runs.putIfAbsent(task.id, () async {
      final stopwatch = Stopwatch()..start();
      try {
        await Future<void>.sync(task.action).timeout(task.timeout);
        return StartupTaskResult(
          id: task.id,
          kind: task.kind,
          status: StartupTaskStatus.succeeded,
          elapsed: stopwatch.elapsed,
        );
      } on TimeoutException catch (error, stackTrace) {
        return StartupTaskResult(
          id: task.id,
          kind: task.kind,
          status: StartupTaskStatus.timedOut,
          elapsed: stopwatch.elapsed,
          error: error,
          stackTrace: stackTrace,
        );
      } catch (error, stackTrace) {
        return StartupTaskResult(
          id: task.id,
          kind: task.kind,
          status: StartupTaskStatus.failed,
          elapsed: stopwatch.elapsed,
          error: error,
          stackTrace: stackTrace,
        );
      } finally {
        stopwatch.stop();
      }
    });
  }
}
