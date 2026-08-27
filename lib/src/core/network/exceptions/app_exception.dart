import '../../../config/language/locale_keys.g.dart';

/// Low-level transport error raised inside `ResponseParser` / interceptors.
///
/// Localization
///   [userMessage] is an **abstract getter** — each subtype maps itself to a
///   key from [LocaleKeys], resolved against the active locale at read time.
///   Switching language updates rendered messages instantly. A server value is
///   kept in [serverMessage] as diagnostic metadata and is never rendered
///   directly.
sealed class AppException implements Exception {
  /// Untrusted server-provided metadata. It must not override [userMessage].
  final String? serverMessage;
  final String? technicalInfo;
  final int? statusCode;
  final bool retryable;

  const AppException({
    this.serverMessage,
    this.technicalInfo,
    this.statusCode,
    this.retryable = false,
  });

  /// Localized, user-facing message resolved at read time.
  String get userMessage;

  @override
  String toString() =>
      '$runtimeType(status: $statusCode, retryable: $retryable, msg: $userMessage'
      '${technicalInfo != null ? ", tech: $technicalInfo" : ""})';
}

final class NetworkException extends AppException {
  const NetworkException([String? tech])
    : super(technicalInfo: tech, retryable: true);

  @override
  String get userMessage => LocaleKeys.failureNoInternet;
}

final class ConnectionTimeoutException extends AppException {
  const ConnectionTimeoutException([String? tech])
    : super(technicalInfo: tech, retryable: true);

  @override
  String get userMessage => LocaleKeys.failureTimeout;
}

final class SendTimeoutException extends AppException {
  const SendTimeoutException([String? tech])
    : super(technicalInfo: tech, retryable: true);

  @override
  String get userMessage => LocaleKeys.failureTimeout;
}

final class ReceiveTimeoutException extends AppException {
  const ReceiveTimeoutException([String? tech])
    : super(technicalInfo: tech, retryable: true);

  @override
  String get userMessage => LocaleKeys.failureTimeout;
}

final class BadCertificateException extends AppException {
  const BadCertificateException([String? tech]) : super(technicalInfo: tech);

  @override
  String get userMessage => LocaleKeys.failureBadCertificate;
}

final class UnauthorizedException extends AppException {
  const UnauthorizedException([String? tech])
    : super(technicalInfo: tech, statusCode: 401);

  @override
  String get userMessage => LocaleKeys.failureUnauthorized;
}

final class PermissionException extends AppException {
  PermissionException([String? msg, String? tech])
    : super(serverMessage: msg, technicalInfo: tech, statusCode: 403);

  @override
  String get userMessage => LocaleKeys.failurePermissionDenied;
}

final class ValidationException extends AppException {
  final Map<String, List<String>>? fields;
  ValidationException(String? msg, {this.fields, String? tech})
    : super(serverMessage: msg, technicalInfo: tech, statusCode: 400);

  @override
  String get userMessage => LocaleKeys.failureValidation;
}

final class UnprocessableException extends AppException {
  final Map<String, List<String>>? errors;
  UnprocessableException(String? msg, {this.errors, String? tech})
    : super(serverMessage: msg, technicalInfo: tech, statusCode: 422);

  @override
  String get userMessage => LocaleKeys.failureValidation;
}

final class NotFoundException extends AppException {
  const NotFoundException([String? tech])
    : super(technicalInfo: tech, statusCode: 404);

  @override
  String get userMessage => LocaleKeys.failureNotFound;
}

final class ConflictException extends AppException {
  ConflictException([String? msg, String? tech])
    : super(serverMessage: msg, technicalInfo: tech, statusCode: 409);

  @override
  String get userMessage => LocaleKeys.failureConflict;
}

final class RateLimitException extends AppException {
  final Duration? retryAfter;
  RateLimitException({this.retryAfter, String? tech})
    : super(technicalInfo: tech, statusCode: 429, retryable: true);

  @override
  String get userMessage => LocaleKeys.failureRateLimit;
}

final class PayloadTooLargeException extends AppException {
  const PayloadTooLargeException([String? tech])
    : super(technicalInfo: tech, statusCode: 413);

  @override
  String get userMessage => LocaleKeys.failurePayloadTooLarge;
}

final class InternalServerException extends AppException {
  const InternalServerException([String? tech])
    : super(technicalInfo: tech, statusCode: 500, retryable: true);

  @override
  String get userMessage => LocaleKeys.failureServer;
}

final class BadGatewayException extends AppException {
  const BadGatewayException([String? tech])
    : super(technicalInfo: tech, statusCode: 502, retryable: true);

  @override
  String get userMessage => LocaleKeys.failureServer;
}

final class MaintenanceException extends AppException {
  final Duration? retryAfter;
  MaintenanceException({this.retryAfter, String? tech})
    : super(technicalInfo: tech, statusCode: 503, retryable: true);

  @override
  String get userMessage => LocaleKeys.failureMaintenance;
}

final class GatewayTimeoutException extends AppException {
  const GatewayTimeoutException([String? tech])
    : super(technicalInfo: tech, statusCode: 504, retryable: true);

  @override
  String get userMessage => LocaleKeys.failureTimeout;
}

final class ServerException extends AppException {
  ServerException(String? msg, {super.statusCode, String? tech})
    : super(serverMessage: msg, technicalInfo: tech);

  @override
  String get userMessage => LocaleKeys.failureServer;
}

final class HtmlResponseException extends AppException {
  const HtmlResponseException([String? tech]) : super(technicalInfo: tech);

  @override
  String get userMessage => LocaleKeys.failureUnknown;
}

final class ParseException extends AppException {
  const ParseException([String? tech]) : super(technicalInfo: tech);

  @override
  String get userMessage => LocaleKeys.failureParse;
}

final class CancelledRequest extends AppException {
  const CancelledRequest();

  // Intentionally empty — a cancelled request must be a UI no-op.
  @override
  String get userMessage => '';
}

final class UnknownException extends AppException {
  const UnknownException([String? tech]) : super(technicalInfo: tech);

  @override
  String get userMessage => LocaleKeys.failureUnknown;
}
