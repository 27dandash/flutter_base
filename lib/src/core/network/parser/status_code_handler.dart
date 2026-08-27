import '../exceptions/app_exception.dart';

class StatusCodeHandler {
  StatusCodeHandler._();

  static AppException handle({required int statusCode, dynamic responseData}) {
    final serverMsg = _extractMessage(responseData);

    return switch (statusCode) {
      400 => ValidationException(
        serverMsg,
        fields: _extractValidationFields(responseData),
      ),
      401 => const UnauthorizedException(),
      403 => PermissionException(serverMsg),
      404 => const NotFoundException(),
      409 => ConflictException(serverMsg),
      413 => const PayloadTooLargeException(),
      422 => UnprocessableException(
        serverMsg,
        errors: _extractValidationFields(responseData),
      ),
      429 => RateLimitException(retryAfter: _extractRetryAfter(responseData)),
      500 => const InternalServerException(),
      502 => const BadGatewayException(),
      503 => MaintenanceException(retryAfter: _extractRetryAfter(responseData)),
      504 => const GatewayTimeoutException(),
      _ => ServerException(
        serverMsg,
        statusCode: statusCode,
        tech: 'Unhandled status: $statusCode',
      ),
    };
  }

  static String? _extractMessage(dynamic data) {
    if (data is! Map) return null;
    const keys = [
      'message',
      'error',
      'detail',
      'msg',
      'description',
      'error_message',
      'error_description',
    ];
    for (final k in keys) {
      final v = data[k];
      if (v is String && v.trim().isNotEmpty) return v;
      if (v is Map) {
        // sometimes APIs nest a {message: "..."} object
        final nested = v['message'] ?? v['detail'];
        if (nested is String && nested.trim().isNotEmpty) return nested;
      }
    }
    return null;
  }

  static Map<String, List<String>>? _extractValidationFields(dynamic data) {
    if (data is! Map) return null;
    // Project API contract: 422 errors live under `data.items.{field}`.
    // Fall back to the common Laravel-style shapes for other backends.
    final inner = data['data'] is Map ? (data['data'] as Map)['items'] : null;
    final raw = inner ?? data['errors'] ?? data['validation'] ?? data['fields'];
    if (raw is! Map) return null;
    final out = <String, List<String>>{};
    raw.forEach((key, value) {
      if (key is! String) return;
      if (value is List) {
        out[key] = value.map((e) => e.toString()).toList();
      } else if (value is String) {
        out[key] = [value];
      }
    });
    return out.isEmpty ? null : out;
  }

  static Duration? _extractRetryAfter(dynamic data) {
    if (data is Map) {
      final raw = data['retry_after'] ?? data['retryAfter'];
      if (raw is int) return Duration(seconds: raw);
      if (raw is String) {
        final n = int.tryParse(raw);
        if (n != null) return Duration(seconds: n);
      }
    }
    return null;
  }
}
