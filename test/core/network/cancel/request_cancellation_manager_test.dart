import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_base/src/core/network/base/base_remote_source.dart';
import 'package:flutter_base/src/core/network/cancel/request_cancellation_manager.dart';
import 'package:flutter_base/src/core/network/error/failures.dart';
import 'package:flutter_base/src/core/network/http_method.dart';
import 'package:flutter_test/flutter_test.dart';

/// Holds every request open until the test completes it or the request is
/// cancelled through its CancelToken.
final class _HoldingAdapter implements HttpClientAdapter {
  final pending = <Completer<ResponseBody>>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    final completer = Completer<ResponseBody>();
    pending.add(completer);
    cancelFuture?.then((_) {
      if (!completer.isCompleted) {
        completer.completeError(
          DioException.requestCancelled(
            requestOptions: options,
            reason: 'cancelled',
          ),
        );
      }
    });
    return completer.future;
  }

  @override
  void close({bool force = false}) {}
}

final class _Source extends BaseRemoteSource {
  _Source(Dio dio, RequestCancellationManager manager)
    : super(dio: dio, cancelManager: manager);

  Future<Object?> call(
    HttpMethod method, {
    String endpoint = 'items',
    String? key,
    bool? cancelPrevious,
  }) => request<Object?>(
    method: method,
    endpoint: endpoint,
    fromJson: (json) => json,
    cancelKey: key,
    cancelPrevious: cancelPrevious,
  ).then((either) => either.fold((f) => f, (v) => v));
}

ResponseBody _ok() => ResponseBody.fromString(
  '{"ok":true}',
  200,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);

/// Dio runs the interceptor chain asynchronously, so a request reaches the
/// adapter a few turns after the call.
Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 10));

void main() {
  group('RequestCancellationManager', () {
    test('a newer token supersedes the older one for the same key', () {
      final manager = RequestCancellationManager();
      final first = manager.getToken('k-supersede');
      final second = manager.getToken('k-supersede');

      expect(first.isCancelled, isTrue);
      expect(second.isCancelled, isFalse);
      manager.cancel('k-supersede');
    });

    test('releasing a superseded token does not drop the newer one', () {
      final manager = RequestCancellationManager();
      final older = manager.getToken('k-stale');
      final newer = manager.getToken('k-stale');

      manager.release('k-stale', older);

      expect(manager.isActive('k-stale'), isTrue);
      manager.cancelAll('test');
      expect(newer.isCancelled, isTrue);
    });

    test('a shared token is released only by its last user', () {
      final manager = RequestCancellationManager();
      final a = manager.getToken('k-shared', cancelPrevious: false);
      final b = manager.getToken('k-shared', cancelPrevious: false);
      expect(identical(a, b), isTrue);

      manager.release('k-shared', a);
      expect(manager.isActive('k-shared'), isTrue);
      manager.release('k-shared', b);
      expect(manager.isActive('k-shared'), isFalse);
    });

    test('release without a token clears the key', () {
      final manager = RequestCancellationManager();
      manager.getToken('k-legacy');
      manager.release('k-legacy');
      expect(manager.isActive('k-legacy'), isFalse);
    });
  });

  group('BaseRemoteSource cancellation', () {
    late _HoldingAdapter adapter;
    late RequestCancellationManager manager;
    late _Source source;

    setUp(() {
      adapter = _HoldingAdapter();
      manager = RequestCancellationManager();
      source = _Source(
        Dio(BaseOptions(baseUrl: 'https://example.test/'))
          ..httpClientAdapter = adapter,
        manager,
      );
    });

    tearDown(() => manager.cancelAll('test teardown'));

    test(
      'a superseded GET leaves the newer GET cancellable by cancelAll',
      () async {
        final first = source.call(HttpMethod.get, key: 'list-A');
        await _settle();
        final second = source.call(HttpMethod.get, key: 'list-A');

        expect(await first, isA<CancelledFailure>());
        // The older request has finished unwinding; the newer one must still be
        // tracked so logout can cancel it.
        expect(manager.isActive('list-A'), isTrue);

        manager.cancelAll('session_terminated');
        expect(await second, isA<CancelledFailure>());
      },
    );

    test(
      'a third GET still supersedes the second after the first unwound',
      () async {
        final first = source.call(HttpMethod.get, key: 'list-B');
        await _settle();
        final second = source.call(HttpMethod.get, key: 'list-B');
        expect(await first, isA<CancelledFailure>());

        final third = source.call(HttpMethod.get, key: 'list-B');
        expect(await second, isA<CancelledFailure>());
        await _settle();

        adapter.pending.last.complete(_ok());
        expect(await third, isNot(isA<Failure>()));
      },
    );

    test('a repeated POST is not cancelled by default', () async {
      final first = source.call(HttpMethod.post, endpoint: 'orders');
      await _settle();
      final second = source.call(HttpMethod.post, endpoint: 'orders');
      await _settle();

      for (final pending in adapter.pending) {
        pending.complete(_ok());
      }

      expect(await first, isNot(isA<Failure>()));
      expect(await second, isNot(isA<Failure>()));
    });

    test('a write can still opt in to superseding', () async {
      final first = source.call(
        HttpMethod.put,
        endpoint: 'draft',
        cancelPrevious: true,
      );
      await _settle();
      final second = source.call(
        HttpMethod.put,
        endpoint: 'draft',
        cancelPrevious: true,
      );

      expect(await first, isA<CancelledFailure>());
      await _settle();
      adapter.pending.last.complete(_ok());
      expect(await second, isNot(isA<Failure>()));
    });
  });
}
