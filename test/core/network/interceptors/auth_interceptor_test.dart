import 'dart:async';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_base/src/core/network/base/base_remote_source.dart';
import 'package:flutter_base/src/core/network/error/failures.dart';
import 'package:flutter_base/src/core/network/http_method.dart';
import 'package:flutter_base/src/core/network/interceptors/auth_interceptor.dart';
import 'package:flutter_base/src/core/network/auth/token_storage.dart';
import 'package:flutter_base/src/core/session/session_failure_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory [TokenStorageBackend] so a session can be seeded without a device
/// Keychain. [failWrites] simulates a durable secure-store outage.
final class _MemoryBackend implements TokenStorageBackend {
  final values = <String, String>{};
  bool failWrites = false;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    if (failWrites) throw StateError('simulated secure-storage failure');
    values[key] = value;
  }

  @override
  Future<void> deleteAll(Iterable<String> keys) async {
    for (final key in keys) {
      values.remove(key);
    }
  }
}

/// Always answers `401` — for the protected endpoint (auth challenge) and for
/// the refresh endpoint (so refresh fails unrecoverably). Counts refresh hits
/// to prove single-flight refresh.
class _UnauthorizedAdapter implements HttpClientAdapter {
  int refreshCalls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.contains('refresh')) refreshCalls += 1;
    return ResponseBody.fromString(
      '{"message":"unauthenticated"}',
      401,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _TestRemoteSource extends BaseRemoteSource {
  _TestRemoteSource(Dio dio) : super(dio: dio);

  Future<Either<Failure, Unit>> get(String endpoint) => request<Unit>(
    method: HttpMethod.get,
    endpoint: endpoint,
    fromJson: (_) => unit,
  );
}

Future<(TokenStorage, _UnauthorizedAdapter, Dio)> _wire({
  required Future<void> Function()? onAuthFailure,
  _MemoryBackend? backend,
  Duration authFailureTimeout = const Duration(seconds: 10),
}) async {
  final storage = TokenStorage.forTesting(backend ?? _MemoryBackend());
  await storage.save(access: 'access-token', refresh: 'refresh-token');

  final adapter = _UnauthorizedAdapter();
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://example.com/',
      // Mirror production: 4xx arrives as a Response, so the challenge is
      // handled in AuthInterceptor.onResponse.
      validateStatus: (status) => status != null && status < 500,
    ),
  );
  dio.httpClientAdapter = adapter;
  dio.interceptors.add(
    AuthInterceptor(
      dio,
      storage: storage,
      onAuthFailure: onAuthFailure,
      authFailureTimeout: authFailureTimeout,
    ),
  );
  return (storage, adapter, dio);
}

void main() {
  final coordinator = SessionFailureCoordinator.instance;

  tearDown(() {
    coordinator.onUnauthorized = null;
    coordinator.onBlocked = null;
    coordinator.onNeedsActivation = null;
  });

  test('failed refresh terminates the session exactly once through '
      'BaseRemoteSource', () async {
    var interceptorCallbacks = 0;
    var coordinatorCallbacks = 0;
    coordinator.onUnauthorized = () async => coordinatorCallbacks++;

    final (_, adapter, dio) = await _wire(
      onAuthFailure: () async => interceptorCallbacks++,
    );
    final source = _TestRemoteSource(dio);

    final result = await source.get('/protected');

    // Repository caller still receives the typed unauthorized failure.
    expect(result.isLeft(), isTrue);
    result.fold(
      (failure) => expect(failure, isA<UnauthorizedFailure>()),
      (_) => fail('expected a failure'),
    );

    // The interceptor owns the transition; the coordinator does not fire a
    // second one for the same 401.
    expect(interceptorCallbacks, 1);
    expect(coordinatorCallbacks, 0);
    expect(adapter.refreshCalls, 1);
  });

  test('concurrent failed requests share one refresh and one session '
      'termination', () async {
    var interceptorCallbacks = 0;
    var coordinatorCallbacks = 0;
    coordinator.onUnauthorized = () async => coordinatorCallbacks++;

    final (_, adapter, dio) = await _wire(
      onAuthFailure: () async => interceptorCallbacks++,
    );
    final source = _TestRemoteSource(dio);

    final results = await Future.wait([
      source.get('/protected-a'),
      source.get('/protected-b'),
    ]);

    // Both callers get a typed failure (never a success). The preserved
    // session-generation guard makes exactly one own the 401 while the other
    // is cancelled as stale.
    final unauthorized = results
        .where((r) => r.fold((f) => f is UnauthorizedFailure, (_) => false))
        .length;
    final cancelled = results
        .where((r) => r.fold((f) => f is CancelledFailure, (_) => false))
        .length;
    expect(unauthorized, 1);
    expect(cancelled, 1);

    // Single-flight refresh + single-flight termination across both requests,
    // with no duplicate transition through the coordinator.
    expect(adapter.refreshCalls, 1);
    expect(interceptorCallbacks, 1);
    expect(coordinatorCallbacks, 0);
  });

  test(
    'without an interceptor callback the coordinator owns the transition',
    () async {
      var coordinatorCallbacks = 0;
      coordinator.onUnauthorized = () async => coordinatorCallbacks++;

      final (_, _, dio) = await _wire(onAuthFailure: null);
      final source = _TestRemoteSource(dio);

      final result = await source.get('/protected');

      result.fold(
        (failure) => expect(failure, isA<UnauthorizedFailure>()),
        (_) => fail('expected a failure'),
      );
      // No interceptor callback ⇒ the coordinator remains the single owner.
      expect(coordinatorCallbacks, 1);
    },
  );

  test(
    'a throwing auth callback does not falsely own the transition',
    () async {
      var coordinatorCallbacks = 0;
      coordinator.onUnauthorized = () async => coordinatorCallbacks++;

      final (_, _, dio) = await _wire(
        onAuthFailure: () async => throw StateError('callback boom'),
      );
      final source = _TestRemoteSource(dio);

      final result = await source.get('/protected');

      // Request still resolves with the typed failure — no hang, no rethrow.
      result.fold(
        (failure) => expect(failure, isA<UnauthorizedFailure>()),
        (_) => fail('expected a failure'),
      );
      // The failed callback did NOT mark the transition handled, so the
      // coordinator remains the safe fallback owner.
      expect(coordinatorCallbacks, 1);
    },
  );

  test(
    'a timed-out callback retains ownership and cannot complete twice',
    () async {
      var coordinatorCallbacks = 0;
      var interceptorCompletions = 0;
      coordinator.onUnauthorized = () async => coordinatorCallbacks++;

      final releaseCallback = Completer<void>();
      addTearDown(() {
        if (!releaseCallback.isCompleted) releaseCallback.complete();
      });

      final (_, _, dio) = await _wire(
        onAuthFailure: () async {
          await releaseCallback.future;
          interceptorCompletions++;
        },
        authFailureTimeout: const Duration(milliseconds: 50),
      );
      final source = _TestRemoteSource(dio);

      final result = await source.get('/protected');

      result.fold(
        (failure) => expect(failure, isA<UnauthorizedFailure>()),
        (_) => fail('expected a failure'),
      );
      // The callback was already invoked when the deadline elapsed, so it
      // remains the sole owner instead of transferring ownership and later
      // causing a duplicate transition.
      expect(coordinatorCallbacks, 0);
      expect(interceptorCompletions, 0);

      releaseCallback.complete();
      await Future<void>.delayed(Duration.zero);
      expect(interceptorCompletions, 1);
      expect(coordinatorCallbacks, 0);
    },
    // Guards against a regression that would hang the challenged request.
    timeout: const Timeout(Duration(seconds: 5)),
  );

  test(
    'a durable clear failure stays fail-closed and terminates once',
    () async {
      var interceptorCallbacks = 0;
      var coordinatorCallbacks = 0;
      coordinator.onUnauthorized = () async => coordinatorCallbacks++;

      final backend = _MemoryBackend();
      final (storage, _, dio) = await _wire(
        onAuthFailure: () async => interceptorCallbacks++,
        backend: backend,
      );
      // Fail every write from now on, so the tombstone (durable clear) fails.
      backend.failWrites = true;
      final source = _TestRemoteSource(dio);

      final result = await source.get('/protected');

      result.fold(
        (failure) => expect(failure, isA<UnauthorizedFailure>()),
        (_) => fail('expected a failure'),
      );
      // In-memory credentials are dropped despite the durable-write failure.
      expect(storage.hasAccessToken, isFalse);
      // The completed callback still owns the single transition.
      expect(interceptorCallbacks, 1);
      expect(coordinatorCallbacks, 0);
    },
  );
}
