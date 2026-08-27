import 'dart:async';

import 'package:dio/dio.dart';

import '../../../config/app_config.dart';
import '../api_endpoints.dart';
import '../auth/token_storage.dart';
import '../options/request_extra.dart';
import '../php/php_envelope.dart';
import '../php/php_response_keys.dart';

/// Adds the Bearer token to every request and performs a single-flight
/// 401 → refresh → retry cycle. If the refresh fails the original error is
/// propagated and the stored tokens are cleared (callers can react by routing
/// to the login screen on UnauthorizedFailure).
///
/// This is a PLAIN [Interceptor], NOT a [QueuedInterceptor]. A
/// `QueuedInterceptor` serialises every `onResponse` through one shared queue;
/// because `DioClient` uses `validateStatus < 500`, a 401 is delivered to
/// `onResponse`, and awaiting a refresh whose own 200 response must pass back
/// through that same (still-busy) queue deadlocks the request forever. A plain
/// interceptor has no such queue, and single-flight is provided instead by
/// [_refreshCompleter]: concurrent 401s all await the same in-flight refresh,
/// so the refresh endpoint is hit at most once.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._dio, {TokenStorage? storage, this.onAuthFailure})
    : _storage = storage ?? TokenStorage.instance;

  /// Shared client used to retry the original request (full interceptor chain,
  /// no leak). The refresh call itself runs on a throwaway [Dio] — see
  /// [_doRefresh] — so its response never re-enters this interceptor.
  final Dio _dio;
  final TokenStorage _storage;
  final Future<void> Function()? onAuthFailure;

  // Shared with BaseRemoteSource via RequestExtra so callers can opt out
  // of auth attachment per-request (e.g. login/register endpoints).
  static const _retriedFlag = RequestExtra.retried;
  static const _skipAuthFlag = RequestExtra.skipAuth;

  /// In-flight refresh, shared by all callers that hit a 401 at once.
  Completer<bool>? _refreshCompleter;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final skip = options.extra[_skipAuthFlag] == true;
    if (!skip && _storage.hasAccessToken) {
      options.headers['Authorization'] = 'Bearer ${_storage.accessToken}';
    }
    handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    // Since DioClient uses validateStatus < 500, a 401 lands here as a
    // normal response. In PHP-response mode the backend instead signals an
    // expired/invalid token with HTTP 200 + {"key":"unauthenticated"}, so treat
    // that as the same auth challenge. Off by default -> only a 401 qualifies,
    // exactly as before.
    final isAuthChallenge =
        response.statusCode == 401 || _isPhpUnauthenticated(response);
    if (!isAuthChallenge) return handler.next(response);

    final req = response.requestOptions;
    if (!_shouldAttemptRefresh(req)) return handler.next(response);

    try {
      final refreshed = await _refresh();
      if (!refreshed) {
        await _failAuth();
        return handler.next(response);
      }
      final retried = await _retry(req);
      return handler.resolve(retried);
    } catch (_) {
      await _failAuth();
      return handler.next(response);
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Defensive: only reached if validateStatus is ever tightened so a 401
    // arrives as an error instead of a response.
    final isUnauthorized = err.response?.statusCode == 401;
    if (!isUnauthorized || !_shouldAttemptRefresh(err.requestOptions)) {
      return handler.next(err);
    }

    try {
      final refreshed = await _refresh();
      if (!refreshed) {
        await _failAuth();
        return handler.next(err);
      }
      final retried = await _retry(err.requestOptions);
      return handler.resolve(retried);
    } catch (_) {
      await _failAuth();
      return handler.next(err);
    }
  }

  bool _shouldAttemptRefresh(RequestOptions req) {
    if (req.extra[_retriedFlag] == true) return false;
    if (req.extra[_skipAuthFlag] == true) return false;
    final refresh = _storage.refreshToken;
    return refresh != null && refresh.isNotEmpty;
  }

  /// PHP-mode only: a 200 body whose logical key is `unauthenticated` is the
  /// custom backend's equivalent of an HTTP 401. Returns false cheaply when the
  /// mode is off, keeping the 401-only path byte-identical by default.
  bool _isPhpUnauthenticated(Response response) {
    if (!AppConfig.phpResponseMode) return false;
    return PhpEnvelope.tryFrom(response.data)?.key ==
        PhpResponseKeys.unauthenticated;
  }

  /// Single-flight refresh: the first caller performs the actual refresh,
  /// every concurrent caller awaits the same [Completer].
  Future<bool> _refresh() {
    final inFlight = _refreshCompleter;
    if (inFlight != null) return inFlight.future;

    final completer = _refreshCompleter = Completer<bool>();
    _doRefresh()
        .then((ok) {
          completer.complete(ok);
        })
        .catchError((Object e, StackTrace st) {
          completer.completeError(e, st);
        })
        .whenComplete(() {
          _refreshCompleter = null;
        });
    return completer.future;
  }

  Future<bool> _doRefresh() async {
    final refreshToken = _storage.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return false;

    // Throwaway client for the refresh call so its 200 response does NOT pass
    // back through THIS interceptor. Routing it through `_dio` would re-enter
    // onResponse while we are still awaiting here — the original deadlock.
    final tokenDio = Dio(BaseOptions(baseUrl: _dio.options.baseUrl))
      ..httpClientAdapter = _dio.httpClientAdapter;

    final res = await tokenDio.post(
      ApiEndpoints.refreshToken,
      data: {'refresh_token': refreshToken},
      options: Options(validateStatus: (s) => s != null && s < 500),
    );
    if (res.statusCode != 200 || res.data is! Map) return false;
    final data = res.data as Map;
    // In PHP-response mode the refresh endpoint wraps the tokens in the standard
    // envelope ({"key":"success","data":{...}}); unwrap so they are read from
    // the right place. Off by default -> reads `data` exactly as before.
    final body =
        AppConfig.phpResponseMode &&
            data[PhpResponseKeys.key] == PhpResponseKeys.success &&
            data[PhpResponseKeys.data] is Map
        ? data[PhpResponseKeys.data] as Map
        : data;
    final access = body['access_token'] ?? body['token'];
    final refresh = body['refresh_token'];
    if (access is! String || access.isEmpty) return false;
    await _storage.save(
      access: access,
      refresh: refresh is String ? refresh : null,
    );
    return true;
  }

  Future<Response<dynamic>> _retry(RequestOptions req) {
    // Mark so a second 401 on the replayed request doesn't recurse, then
    // re-issue through the shared client (full interceptor chain, no leak).
    req.extra[_retriedFlag] = true;
    req.headers['Authorization'] = 'Bearer ${_storage.accessToken}';
    // FormData is single-use: once finalised on the first send it cannot be
    // re-read. Clone it so the retried multipart body is rebuilt instead of
    // throwing a StateError (which would silently log the user out).
    final data = req.data;
    if (data is FormData) {
      req.data = data.clone();
    }
    return _dio.fetch(req);
  }

  Future<void> _failAuth() async {
    await _storage.clear();
    final cb = onAuthFailure;
    if (cb != null) await cb();
  }
}
