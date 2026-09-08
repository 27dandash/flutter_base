import 'dart:async';

import 'package:dio/dio.dart';

import '../../../config/app_config.dart';
import '../api_endpoints.dart';
import '../auth/token_storage.dart';
import '../options/request_extra.dart';
import '../php/php_envelope.dart';
import '../php/php_response_keys.dart';

enum _RefreshOutcome { refreshed, failed, staleSession }

enum _GuardedOutcome { completed, failed, timedOut }

/// Adds the Bearer token and performs a session-safe 401 refresh/retry cycle.
///
/// Refresh is single-flight per authenticated session. Every request captures
/// [TokenStorage.sessionGeneration]; a response, refresh, or retry that
/// completes after logout/account switching is rejected as cancellation. This
/// prevents an old account's work from writing tokens or data into a new one.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(
    this._dio, {
    TokenStorage? storage,
    this.onAuthFailure,
    this.authFailureTimeout = const Duration(seconds: 10),
  }) : _storage = storage ?? TokenStorage.instance;

  /// Shared client used to retry the original request through the complete
  /// interceptor chain. Refresh itself uses an isolated [Dio] to avoid
  /// re-entering this interceptor and deadlocking a challenged request.
  final Dio _dio;
  final TokenStorage _storage;
  final Future<void> Function()? onAuthFailure;

  /// Total upper bound on token cleanup plus [onAuthFailure] after an
  /// unrecoverable refresh failure. A slow or stuck store/callback can never
  /// hold the challenged request past this single shared ceiling.
  final Duration authFailureTimeout;

  static const _retriedFlag = RequestExtra.retried;
  static const _skipAuthFlag = RequestExtra.skipAuth;
  static const _sessionGenerationKey = RequestExtra.authSessionGeneration;
  static const _authFailureHandledFlag = RequestExtra.authFailureHandled;

  final Map<int, Future<_RefreshOutcome>> _refreshes = {};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.extra[_skipAuthFlag] == true) {
      handler.next(options);
      return;
    }

    final currentGeneration = _storage.sessionGeneration;
    final capturedGeneration = _requestGeneration(options);
    if (capturedGeneration != null && capturedGeneration != currentGeneration) {
      handler.reject(_staleSession(options));
      return;
    }

    options.extra[_sessionGenerationKey] = currentGeneration;
    if (_storage.hasAccessToken) {
      options.headers['Authorization'] = 'Bearer ${_storage.accessToken}';
    }
    handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    final request = response.requestOptions;
    if (_isStaleRequest(request)) {
      handler.reject(_staleSession(request));
      return;
    }

    final isAuthChallenge =
        response.statusCode == 401 || _isPhpUnauthenticated(response);
    if (!isAuthChallenge || !_shouldAttemptRefresh(request)) {
      handler.next(response);
      return;
    }

    final generation = _requestGeneration(request)!;
    final outcome = await _refresh(
      generation,
      acceptLanguage: request.headers['Accept-Language']?.toString(),
    );
    if (outcome == _RefreshOutcome.staleSession ||
        !_storage.isCurrentGeneration(generation)) {
      handler.reject(_staleSession(request));
      return;
    }
    if (outcome == _RefreshOutcome.failed) {
      final failedCurrentSession = await _failAuth(generation, request);
      if (!failedCurrentSession) {
        handler.reject(_staleSession(request));
        return;
      }
      handler.next(response);
      return;
    }

    try {
      final retried = await _retry(request, generation);
      handler.resolve(retried);
    } on DioException catch (error) {
      handler.reject(error);
    } catch (error, stackTrace) {
      handler.reject(
        DioException(
          requestOptions: request,
          error: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    if (_isStaleRequest(request)) {
      handler.reject(_staleSession(request));
      return;
    }

    if (err.response?.statusCode != 401 || !_shouldAttemptRefresh(request)) {
      handler.next(err);
      return;
    }

    final generation = _requestGeneration(request)!;
    final outcome = await _refresh(
      generation,
      acceptLanguage: request.headers['Accept-Language']?.toString(),
    );
    if (outcome == _RefreshOutcome.staleSession ||
        !_storage.isCurrentGeneration(generation)) {
      handler.reject(_staleSession(request));
      return;
    }
    if (outcome == _RefreshOutcome.failed) {
      final failedCurrentSession = await _failAuth(generation, request);
      if (!failedCurrentSession) {
        handler.reject(_staleSession(request));
        return;
      }
      handler.next(err);
      return;
    }

    try {
      final retried = await _retry(request, generation);
      handler.resolve(retried);
    } on DioException catch (retryError) {
      handler.reject(retryError);
    } catch (retryError, stackTrace) {
      handler.reject(
        DioException(
          requestOptions: request,
          error: retryError,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  bool _shouldAttemptRefresh(RequestOptions request) {
    if (request.extra[_retriedFlag] == true ||
        request.extra[_skipAuthFlag] == true) {
      return false;
    }
    final generation = _requestGeneration(request);
    if (generation == null || !_storage.isCurrentGeneration(generation)) {
      return false;
    }
    final refresh = _storage.refreshToken;
    return refresh != null && refresh.isNotEmpty;
  }

  bool _isPhpUnauthenticated(Response response) {
    if (!AppConfig.phpResponseMode) return false;
    return PhpEnvelope.tryFrom(response.data)?.key ==
        PhpResponseKeys.unauthenticated;
  }

  Future<_RefreshOutcome> _refresh(int generation, {String? acceptLanguage}) {
    final inFlight = _refreshes[generation];
    if (inFlight != null) return inFlight;

    final future = _doRefresh(generation, acceptLanguage: acceptLanguage);
    _refreshes[generation] = future;
    future.whenComplete(() {
      if (identical(_refreshes[generation], future)) {
        _refreshes.remove(generation);
      }
    });
    return future;
  }

  Future<_RefreshOutcome> _doRefresh(
    int generation, {
    String? acceptLanguage,
  }) async {
    if (!_storage.isCurrentGeneration(generation)) {
      return _RefreshOutcome.staleSession;
    }
    final refreshToken = _storage.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      return _RefreshOutcome.failed;
    }

    try {
      final tokenDio = Dio(BaseOptions(baseUrl: _dio.options.baseUrl))
        ..httpClientAdapter = _dio.httpClientAdapter;
      final headers = <String, dynamic>{};
      if (acceptLanguage != null && acceptLanguage.isNotEmpty) {
        headers['Accept-Language'] = acceptLanguage;
      }

      final response = await tokenDio.post(
        ApiEndpoints.refreshToken,
        data: {'refresh_token': refreshToken},
        options: Options(
          headers: headers.isEmpty ? null : headers,
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      if (!_storage.isCurrentGeneration(generation)) {
        return _RefreshOutcome.staleSession;
      }
      if (response.statusCode != 200 || response.data is! Map) {
        return _RefreshOutcome.failed;
      }

      final data = response.data as Map;
      final body =
          AppConfig.phpResponseMode &&
              data[PhpResponseKeys.key] == PhpResponseKeys.success &&
              data[PhpResponseKeys.data] is Map
          ? data[PhpResponseKeys.data] as Map
          : data;
      final access = body['access_token'] ?? body['token'];
      final refresh = body['refresh_token'];
      if (access is! String || access.isEmpty) {
        return _RefreshOutcome.failed;
      }

      final saved = await _storage.saveIfCurrent(
        expectedGeneration: generation,
        access: access,
        refresh: refresh is String ? refresh : null,
      );
      return saved ? _RefreshOutcome.refreshed : _RefreshOutcome.staleSession;
    } catch (_) {
      return _storage.isCurrentGeneration(generation)
          ? _RefreshOutcome.failed
          : _RefreshOutcome.staleSession;
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions request, int generation) {
    if (!_storage.isCurrentGeneration(generation)) {
      throw _staleSession(request);
    }
    request.extra[_retriedFlag] = true;
    request.extra[_sessionGenerationKey] = generation;
    request.headers['Authorization'] = 'Bearer ${_storage.accessToken}';

    final data = request.data;
    if (data is FormData) request.data = data.clone();
    return _dio.fetch(request);
  }

  /// Terminates the current session after an unrecoverable refresh failure.
  ///
  /// Runs once for the failed refresh: the first request bumps the session
  /// generation via [TokenStorage.clearIfCurrent], so any concurrent request
  /// sharing the same single-flight refresh is rejected as stale before it
  /// reaches here.
  ///
  /// Completion-safe by contract. Cleanup and the callback share one deadline,
  /// this method never throws, and the caller can always forward the 401.
  /// In-memory credentials are fail-closed synchronously regardless of the
  /// durable-write outcome. A callback that completes or is still running at
  /// the deadline keeps ownership of the Unauthorized transition; a callback
  /// that fails before the deadline leaves ownership to
  /// `SessionFailureCoordinator`. This prevents a timed-out callback from
  /// completing later and causing a second cleanup/navigation transition.
  Future<bool> _failAuth(int generation, RequestOptions request) async {
    if (!_storage.isCurrentGeneration(generation)) return false;
    final callback = onAuthFailure;
    final deadline = Stopwatch()..start();

    // Fail closed regardless of the durable store: a slow/failing tombstone
    // write must not hang the request. In-memory tokens are already gone.
    await _runGuarded(
      () => _storage.clearIfCurrent(generation),
      authFailureTimeout,
    );

    if (callback != null) {
      final remaining = authFailureTimeout - deadline.elapsed;
      if (remaining > Duration.zero) {
        final outcome = await _runGuarded(callback, remaining);
        if (outcome != _GuardedOutcome.failed) {
          request.extra[_authFailureHandledFlag] = true;
        }
      }
    }
    return true;
  }

  /// Converts [action] into a safe outcome without exposing raw error text.
  /// A timeout releases the challenged request but does not cancel the source
  /// future, so callers must keep ownership with an already-started callback.
  Future<_GuardedOutcome> _runGuarded(
    Future<void> Function() action,
    Duration timeout,
  ) async {
    try {
      await action().timeout(timeout);
      return _GuardedOutcome.completed;
    } on TimeoutException {
      return _GuardedOutcome.timedOut;
    } catch (_) {
      return _GuardedOutcome.failed;
    }
  }

  int? _requestGeneration(RequestOptions request) {
    final value = request.extra[_sessionGenerationKey];
    return value is int ? value : null;
  }

  bool _isStaleRequest(RequestOptions request) {
    if (request.extra[_skipAuthFlag] == true) return false;
    final generation = _requestGeneration(request);
    return generation != null && !_storage.isCurrentGeneration(generation);
  }

  DioException _staleSession(RequestOptions request) => DioException(
    requestOptions: request,
    type: DioExceptionType.cancel,
    error: 'stale_auth_session',
  );
}
