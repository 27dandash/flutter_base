import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Debug-only network log: the REQUEST is printed in red and the RESPONSE in
/// green (same convention as the Productive Families app).
///
/// What is printed: method, path, status, elapsed time, and the pretty JSON of
/// the request (query + body) and of the response body.
/// What is never printed: the host, headers (so no `Authorization`), and any
/// value whose key looks like a credential — those become `<redacted>`.
class LoggingInterceptor {
  LoggingInterceptor._();

  static Interceptor build() => _ColoredHttpLoggingInterceptor();
}

class _ColoredHttpLoggingInterceptor extends Interceptor {
  static const _startedAtKey = '_log_started_at';
  static const _red = '\u001b[31m';
  static const _green = '\u001b[32m';
  static const _reset = '\u001b[0m';
  static const _pretty = JsonEncoder.withIndent('  ');
  static final _sensitiveKey = RegExp(
    r'(token|password|secret|authorization|otp|api[_-]?key|refresh|fcm|credential|(^|_)pin($|_))',
    caseSensitive: false,
  );

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startedAtKey] = DateTime.now();
    if (kDebugMode) {
      _print(_red, 'HTTP request ${options.method} ${options.uri.path}');
      if (options.queryParameters.isNotEmpty) {
        _printBlock(_red, 'query', options.queryParameters);
      }
      final body = options.data;
      if (body != null && body is! FormData) {
        _printBlock(_red, 'body', body);
      } else if (body is FormData) {
        _printBlock(_red, 'form', <String, dynamic>{
          for (final field in body.fields) field.key: field.value,
          for (final file in body.files) file.key: '<file>',
        });
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      final request = response.requestOptions;
      _print(
        _green,
        'HTTP response ${request.method} ${request.uri.path} '
        '${response.statusCode ?? 'unknown'} (${_elapsed(request)} ms)',
      );
      _printBlock(_green, null, response.data);
    }
    handler.next(response);
  }

  @override
  void onError(DioException error, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      final request = error.requestOptions;
      _print(
        _green,
        'HTTP failure ${request.method} ${request.uri.path} '
        '${error.type.name} ${error.response?.statusCode ?? 'no-status'} '
        '(${_elapsed(request)} ms)',
      );
      if (error.response?.data != null) {
        _printBlock(_green, null, error.response?.data);
      }
    }
    handler.next(error);
  }

  void _printBlock(String color, String? title, dynamic value) {
    if (title != null) _print(color, '$title:');
    for (final line in _encode(_redact(value)).split('\n')) {
      _print(color, line);
    }
  }

  void _print(String color, String text) {
    debugPrint('$color$text$_reset', wrapWidth: 4096);
  }

  String _encode(dynamic value) {
    try {
      return _pretty.convert(value);
    } catch (_) {
      return '<unprintable>';
    }
  }

  dynamic _redact(dynamic value) {
    if (value is Map) {
      return <String, dynamic>{
        for (final entry in value.entries)
          entry.key.toString(): _sensitiveKey.hasMatch(entry.key.toString())
              ? '<redacted>'
              : _redact(entry.value),
      };
    }
    if (value is List) return [for (final item in value) _redact(item)];
    if (value is String || value is num || value is bool || value == null) {
      return value;
    }
    return value.toString();
  }

  int _elapsed(RequestOptions options) {
    final startedAt = options.extra.remove(_startedAtKey);
    return startedAt is DateTime
        ? DateTime.now().difference(startedAt).inMilliseconds
        : 0;
  }
}
