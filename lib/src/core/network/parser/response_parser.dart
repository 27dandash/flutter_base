import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../config/app_config.dart';
import '../error/failures.dart';
import '../exceptions/app_exception.dart';
import '../php/php_envelope.dart';
import '../php/php_response_keys.dart';
import 'status_code_handler.dart';

/// Turns a raw Dio response (or DioException) into an
/// `Either<Failure, T>`. The data-source layer never has to spell out
/// status-code logic — it just calls this.
class ResponseParser {
  ResponseParser._();

  static Either<Failure, T> parse<T>(
    Response response,
    T Function(dynamic json) fromJson,
  ) {
    final status = response.statusCode ?? 0;
    final data = _safeDecode(response.data);

    if (_looksLikeHtml(data) || _looksLikeHtml(response.data)) {
      return Left(
        ParseFailure(
          technical:
              'HTML response on $status from ${response.requestOptions.uri}',
        ),
      );
    }

    // Custom PHP backend mode (opt-in, off by default). The backend signals the
    // outcome via a `key` in the body regardless of HTTP status, so when the
    // body is a recognizable envelope we map it here and return early. Any other
    // body (HTML, redirect, legacy/partial JSON) leaves `env == null` and falls
    // through to the unchanged status-code path below. When the flag is off this
    // whole block is a compile-time-false branch and is tree-shaken away.
    if (AppConfig.phpResponseMode) {
      final env = PhpEnvelope.tryFrom(data);
      if (env != null) return phpOutcome<T>(env, fromJson);
    }

    if (status >= 200 && status < 300) {
      // Business-level failure smuggled inside an HTTP 200 envelope, e.g.
      // `{"status":"fail","code":422,"message":"...","data":{...}}`.
      // Map it to the right Failure BEFORE handing the body to fromJson,
      // otherwise the parser would treat corrupt data as success.
      final businessFailure = _businessEnvelopeFailure(data, status);
      if (businessFailure != null) return Left(businessFailure);

      if (status == 204 || _isEmpty(data)) {
        try {
          return Right(fromJson(const <String, dynamic>{}));
        } catch (_) {
          return Right(fromJson(null));
        }
      }
      try {
        return Right(fromJson(data));
      } catch (e, st) {
        return Left(ParseFailure(technical: 'parse: $e\n$st'));
      }
    }

    return Left(
      StatusCodeHandler.handle(
        statusCode: status,
        responseData: data,
      ).toFailure(),
    );
  }

  /// Maps a recognized custom-PHP [PhpEnvelope] to an `Either<Failure, T>`.
  ///
  /// Pure and flag-free (the caller decides whether PHP mode is on), so it is
  /// directly unit-testable. On `success` the WHOLE envelope is handed to
  /// [fromJson] — identical to the normal 2xx contract — so existing parsers
  /// that read `json['data']` (and extras like `count_notifications`) keep
  /// working unchanged. The failure keys never reach [fromJson].
  static Either<Failure, T> phpOutcome<T>(
    PhpEnvelope env,
    T Function(dynamic json) fromJson,
  ) {
    switch (env.key) {
      case PhpResponseKeys.success:
        try {
          return Right(fromJson(env.raw));
        } catch (e, st) {
          return Left(ParseFailure(technical: 'php parse: $e\n$st'));
        }
      case PhpResponseKeys.fail:
        // Logical/business failure (invalid coupon, insufficient balance, ...).
        // `msg` is the server's already-localized text; ValidationFailure is
        // non-retryable and surfaces customMessage, which fits a business fail.
        return Left(ValidationFailure(customMessage: env.msg));
      case PhpResponseKeys.needActive:
        return Left(
          NeedActiveFailure(customMessage: env.msg, activationData: env.data),
        );
      case PhpResponseKeys.blocked:
        return Left(BlockedFailure(customMessage: env.msg));
      case PhpResponseKeys.unauthenticated:
        // The interceptor already attempted refresh/retry; by the time the body
        // reaches here the session is genuinely invalid. msg is kept as
        // technical only — userMessage stays the localized session-expired text.
        return Left(UnauthorizedFailure(technical: env.msg));
      case PhpResponseKeys.unauthorized:
        return Left(PermissionFailure(customMessage: env.msg));
      case PhpResponseKeys.exception:
        // `msg` is developer-facing here, so it is intentionally NOT surfaced;
        // {line, file} go into `technical` only (never shown to the user).
        return Left(ServerFailure(technical: _phpExceptionTech(env.data)));
      default:
        // tryFrom only accepts known keys, so this is unreachable — kept as a
        // defensive fallback if the known set ever grows without a case here.
        return Left(UnknownFailure(technical: 'unhandled php key: ${env.key}'));
    }
  }

  /// Captures the developer-only `{line, file}` from an `exception` envelope's
  /// data into a technical string (never surfaced to the user).
  static String? _phpExceptionTech(dynamic data) {
    if (data is Map) {
      final line = data['line'];
      final file = data['file'];
      if (line != null || file != null) return 'line=$line, file=$file';
    }
    return null;
  }

  /// Maps a low-level [DioException] (timeout, no internet, cert error,
  /// or a 4xx/5xx with `validateStatus` having rejected it) to a [Failure].
  static Failure parseDioError(DioException e) {
    final res = e.response;
    final exception = switch (e.type) {
      DioExceptionType.connectionTimeout => ConnectionTimeoutException(
        e.message,
      ),
      DioExceptionType.sendTimeout => SendTimeoutException(e.message),
      DioExceptionType.receiveTimeout => ReceiveTimeoutException(e.message),
      DioExceptionType.transformTimeout => ReceiveTimeoutException(e.message),
      DioExceptionType.badCertificate => BadCertificateException(e.message),
      DioExceptionType.cancel => const CancelledRequest(),
      DioExceptionType.connectionError => _classifyConnectionError(e),
      DioExceptionType.unknown => _classifyUnknown(e),
      DioExceptionType.badResponse => () {
        if (res == null) return const UnknownException('badResponse no res');
        final data = _safeDecode(res.data);
        if (_looksLikeHtml(data) || _looksLikeHtml(res.data)) {
          return const HtmlResponseException();
        }
        return StatusCodeHandler.handle(
          statusCode: res.statusCode ?? 0,
          responseData: data,
        );
      }(),
    };
    return exception.toFailure();
  }

  /// Catch-all for unexpected errors raised inside the data source
  /// (e.g. a `SocketException` that didn't come from Dio).
  static Failure parseUnknownError(Object e) {
    if (e is SocketException) return NetworkFailure(technical: e.message);
    return UnknownFailure(technical: e.toString());
  }

  // ── helpers ──────────────────────────────────────────────────────

  /// Detects a success-HTTP-status response whose JSON envelope still
  /// signals a business failure (`status: "fail" | "error"`). Returns the
  /// mapped [Failure], or `null` when the envelope is a genuine success.
  static Failure? _businessEnvelopeFailure(dynamic data, int httpStatus) {
    if (data is! Map) return null;
    final status = data['status']?.toString().toLowerCase();
    if (status != 'fail' && status != 'error') return null;

    final businessCode = (data['code'] as num?)?.toInt() ?? httpStatus;
    return StatusCodeHandler.handle(
      statusCode: businessCode,
      responseData: data,
    ).toFailure();
  }

  static AppException _classifyConnectionError(DioException e) {
    final inner = e.error;
    if (inner is SocketException) return NetworkException(inner.message);
    return NetworkException(e.message);
  }

  /// `DioExceptionType.unknown` covers errors raised while Dio processes the
  /// response — most importantly a [FormatException] from `jsonDecode` when the
  /// server returns a non-JSON body (an HTML WAF/login page, a truncated
  /// payload) under a JSON `Content-Type`. That decode throws upstream of the
  /// [_safeDecode]/[_looksLikeHtml] guards in [parse], so it must be caught
  /// here and surfaced as a parse failure — NOT a misleading "no internet".
  /// A genuine transport problem ([SocketException]) still maps to a network
  /// failure.
  static AppException _classifyUnknown(DioException e) {
    final inner = e.error;
    if (inner is SocketException) return NetworkException(inner.message);
    if (inner is FormatException) return const HtmlResponseException();
    if (_looksLikeHtml(e.response?.data)) return const HtmlResponseException();
    return NetworkException(e.message);
  }

  static dynamic _safeDecode(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map || raw is List) return raw;
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return null;
      try {
        return jsonDecode(trimmed);
      } catch (_) {
        return {'message': trimmed};
      }
    }
    return raw;
  }

  static bool _looksLikeHtml(dynamic data) {
    if (data is! String) return false;
    final lower = data.toLowerCase().trimLeft();
    return lower.startsWith('<!doctype html') ||
        lower.startsWith('<html') ||
        lower.contains('<head>') ||
        lower.contains('<body');
  }

  static bool _isEmpty(dynamic data) {
    if (data == null) return true;
    if (data is String) return data.trim().isEmpty;
    if (data is Map) return data.isEmpty;
    if (data is List) return data.isEmpty;
    return false;
  }
}
