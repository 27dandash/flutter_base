import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../shared/extensions/string_extension.dart';
import '../../session/session_failure_coordinator.dart';
import '../cancel/request_cancellation_manager.dart';
import '../dio_client.dart';
import '../error/failures.dart';
import '../http_method.dart';
import '../options/request_extra.dart';
import '../parser/response_parser.dart';

/// Base for every concrete remote data source.
///
/// Each call goes through one of:
///   - [request] — the **everyday** entry point. One method, named
///     params, dispatches to the right verb, supports body, query,
///     custom headers, skipAuth, multipart.
///   - [safeApiCall] — the lower-level building block used when you need
///     full control over how `dio.*` is invoked (file upload with
///     progress, custom timeout per request, etc.).
///
/// Both return `Either<Failure, T>` so callers can `fold` without
/// try/catch and without knowing about Dio.
abstract class BaseRemoteSource {
  BaseRemoteSource({Dio? dio, RequestCancellationManager? cancelManager})
    : _dio = dio ?? DioClient().dio,
      _cancelManager = cancelManager ?? RequestCancellationManager();

  final Dio _dio;
  final RequestCancellationManager _cancelManager;

  Dio get dio => _dio;

  // ════════════════════════════════════════════════════════════════
  // High-level: one method to rule them all
  // ════════════════════════════════════════════════════════════════

  /// Unified HTTP call. Pick a verb, pass body/query/headers, get back
  /// `Either<Failure, T>`.
  ///
  /// Examples
  ///   ```dart
  ///   // GET list
  ///   request<List<Product>>(
  ///     method: HttpMethod.get,
  ///     endpoint: ApiEndpoints.products,
  ///     queryParameters: {'page': 1, 'search': 'shoe'},
  ///     fromJson: (j) => ...,
  ///   );
  ///
  ///   // POST create (with body)
  ///   request<Product>(
  ///     method: HttpMethod.post,
  ///     endpoint: ApiEndpoints.products,
  ///     body: {'name': 'Sneaker', 'price': 199.0},
  ///     fromJson: (j) => Product.fromJson(j),
  ///   );
  ///
  ///   // POST public (skip Bearer token — for login/register)
  ///   request<AuthToken>(
  ///     method: HttpMethod.post,
  ///     endpoint: ApiEndpoints.login,
  ///     body: {'email': email, 'password': pwd},
  ///     skipAuth: true,
  ///     fromJson: (j) => AuthToken.fromJson(j),
  ///   );
  ///
  ///   // PUT update
  ///   request<Product>(
  ///     method: HttpMethod.put,
  ///     endpoint: ApiEndpoints.productById(id),
  ///     body: {'name': newName},
  ///     fromJson: (j) => Product.fromJson(j),
  ///   );
  ///
  ///   // DELETE (no payload back)
  ///   request<Unit>(
  ///     method: HttpMethod.delete,
  ///     endpoint: ApiEndpoints.productById(id),
  ///     fromJson: (_) => unit, // dartz's void-equivalent
  ///   );
  ///
  ///   // Multipart upload (FormData)
  ///   request<UploadResult>(
  ///     method: HttpMethod.post,
  ///     endpoint: ApiEndpoints.upload,
  ///     body: {'file': await MultipartFile.fromFile(path), 'note': 'avatar'},
  ///     asFormData: true,
  ///     fromJson: (j) => UploadResult.fromJson(j),
  ///   );
  ///   ```
  ///
  /// Parameters
  ///   - [method]: GET / POST / PUT / PATCH / DELETE
  ///   - [endpoint]: relative or absolute URL — Dio prepends `baseUrl`.
  ///   - [queryParameters]: `?key=value&…`
  ///   - [body]: request body. Can be `Map<String, dynamic>`, `List`, raw
  ///     `String`, or a pre-built `FormData`. Combined with [asFormData]
  ///     for multipart.
  ///   - [headers]: extra request headers merged on top of the global ones.
  ///   - [skipAuth]: skip the [AuthInterceptor] Bearer-token attachment.
  ///     Use for login/register/public endpoints.
  ///   - [asFormData]: if true and `body` is a `Map`, wrap it in
  ///     `FormData.fromMap(...)`. Lets you write multipart calls without
  ///     constructing the FormData yourself.
  ///   - [normalizeArabicDigits]: if true (default), walks `body` and
  ///     `queryParameters` and converts any Arabic-Indic digits
  ///     (٠١٢٣٤٥٦٧٨٩) to ASCII digits before serialization — so a phone
  ///     number typed by the user always reaches the backend as
  ///     `0501234567` regardless of keyboard layout. Set to `false` for
  ///     endpoints that actually expect Arabic digits.
  ///   - [cancelKey]: lookup key in [RequestCancellationManager]. Defaults
  ///     to `"$METHOD:$endpoint"` so two calls with the same method+url
  ///     auto-cancel the first one. Override for finer control
  ///     (e.g. `"search:products"`).
  ///   - [cancelPrevious]: if true, cancels any in-flight request with the
  ///     same [cancelKey] before issuing this one. Defaults to `true` for GET
  ///     (a newer read supersedes an older one) and `false` for every other
  ///     verb: a write must never be cancelled client-side by a repeated tap,
  ///     because the server may already have processed it.
  ///   - [responseType]: override the response parsing (rarely needed).
  Future<Either<Failure, T>> request<T>({
    required HttpMethod method,
    required String endpoint,
    required T Function(dynamic json) fromJson,
    Map<String, dynamic>? queryParameters,
    Object? body,
    Map<String, dynamic>? headers,
    bool skipAuth = false,
    bool asFormData = false,
    bool normalizeArabicDigits = true,
    String? cancelKey,
    bool? cancelPrevious,
    ResponseType? responseType,
  }) {
    final key = cancelKey ?? '${method.value}:$endpoint';
    final supersede = cancelPrevious ?? method == HttpMethod.get;

    Object? requestData = body;
    Map<String, dynamic>? requestQuery = queryParameters;

    // Convert ٠١٢٣ → 0123 inside any string field of body & query.
    if (normalizeArabicDigits) {
      requestData = _normalizeArabicDigits(requestData);
      if (requestQuery != null) {
        requestQuery =
            _normalizeArabicDigits(requestQuery) as Map<String, dynamic>;
      }
    }

    // Optional multipart wrapping — only when the caller explicitly opts in
    // and the body is a Map (FormData built by the caller is kept as-is).
    if (asFormData && requestData is Map<String, dynamic>) {
      requestData = FormData.fromMap(requestData);
    }

    final extra = <String, dynamic>{};
    if (skipAuth) extra[RequestExtra.skipAuth] = true;

    return safeApiCall<T>(
      cancelKey: key,
      cancelPrevious: supersede,
      fromJson: fromJson,
      call: (token) => _dio.request(
        endpoint,
        data: requestData,
        queryParameters: requestQuery,
        cancelToken: token,
        options: Options(
          method: method.value,
          headers: headers,
          extra: extra.isEmpty ? null : extra,
          responseType: responseType,
        ),
      ),
    );
  }

  /// Recursively walks a JSON-like structure converting Arabic-Indic
  /// digits to ASCII. Non-string leaves are returned as-is so `int`s and
  /// `double`s pass through untouched.
  static Object? _normalizeArabicDigits(Object? value) {
    if (value is String) return value.toEnglishNumbers();
    if (value is Map) {
      // Keep the result a Map<String, dynamic> (and stringify keys) so the
      // `as Map<String, dynamic>` cast on queryParameters and the
      // `requestData is Map<String, dynamic>` asFormData guard both still hold
      // after normalization. A plain `.map(...)` yields Map<dynamic, Object?>,
      // which throws on the query cast and silently skips the FormData wrap.
      return value.map<String, dynamic>(
        (k, v) => MapEntry(k.toString(), _normalizeArabicDigits(v)),
      );
    }
    if (value is List) {
      return value.map(_normalizeArabicDigits).toList();
    }
    return value;
  }

  // ════════════════════════════════════════════════════════════════
  // Low-level: build the Dio call yourself when you need full control
  // ════════════════════════════════════════════════════════════════

  /// Use [request] for normal CRUD. Reach for this only when you need to
  /// drive Dio directly — e.g. upload progress callbacks, download
  /// streaming, custom Dio per-request options, etc.
  Future<Either<Failure, T>> safeApiCall<T>({
    required String cancelKey,
    required Future<Response> Function(CancelToken token) call,
    required T Function(dynamic json) fromJson,
    bool cancelPrevious = true,
  }) async {
    final token = _cancelManager.getToken(
      cancelKey,
      cancelPrevious: cancelPrevious,
    );
    try {
      final response = await call(token);
      _cancelManager.release(cancelKey, token);
      final result = ResponseParser.parse<T>(response, fromJson);
      await result.fold(
        (failure) => _handleSessionFailure(failure, response.requestOptions),
        (_) async => false,
      );
      return result;
    } on DioException catch (e) {
      _cancelManager.release(cancelKey, token);
      if (CancelToken.isCancel(e)) {
        return const Left(CancelledFailure());
      }
      final failure = ResponseParser.parseDioError(e);
      await _handleSessionFailure(failure, e.requestOptions);
      return Left(failure);
    } catch (e) {
      _cancelManager.release(cancelKey, token);
      final failure = ResponseParser.parseUnknownError(e);
      await _handleSessionFailure(failure, null);
      return Left(failure);
    }
  }

  /// Routes a session-changing failure to [SessionFailureCoordinator] unless
  /// [AuthInterceptor] already owns the transition for this request.
  ///
  /// After a failed token refresh the interceptor drives its own
  /// `onAuthFailure` callback and passes the original 401 onward. Without this
  /// guard the coordinator would terminate/clean/navigate a second time for the
  /// very same failure. The [RequestExtra.authFailureHandled] marker is honored
  /// **only** for an [UnauthorizedFailure], so an accidentally retained marker
  /// can never suppress a blocked or needs-activation transition.
  Future<void> _handleSessionFailure(
    Failure failure,
    RequestOptions? options,
  ) async {
    if (failure is UnauthorizedFailure &&
        options?.extra[RequestExtra.authFailureHandled] == true) {
      return;
    }
    await SessionFailureCoordinator.instance.handle(failure);
  }
}
