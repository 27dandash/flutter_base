import 'dart:async';

enum AppSocketState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  paused,
  authenticationFailed,
  failed,
  disposed,
}

final class AppSocketFailure {
  const AppSocketFailure(this.code, {this.retryable = true});

  final String code;
  final bool retryable;
}

final class SocketAuthenticationException implements Exception {
  const SocketAuthenticationException([this.code = 'authentication_failed']);

  final String code;

  @override
  String toString() => 'SocketAuthenticationException($code)';
}

typedef SocketAuthProvider = Future<Map<String, dynamic>> Function();

final class AppSocketConfig {
  const AppSocketConfig({
    required this.endpoint,
    required this.authentication,
    this.headers = const {},
    this.connectionTimeout = const Duration(seconds: 10),
    this.maxReconnectAttempts = 5,
    this.initialReconnectDelay = const Duration(seconds: 1),
    this.maxReconnectDelay = const Duration(seconds: 20),
  });

  final Uri endpoint;
  final SocketAuthProvider authentication;
  final Map<String, String> headers;
  final Duration connectionTimeout;
  final int maxReconnectAttempts;
  final Duration initialReconnectDelay;
  final Duration maxReconnectDelay;

  void validate() {
    if (!endpoint.hasScheme || endpoint.host.isEmpty) {
      throw ArgumentError.value(endpoint, 'endpoint', 'must be absolute');
    }
    if (endpoint.scheme != 'https' && endpoint.scheme != 'wss') {
      throw ArgumentError.value(
        endpoint,
        'endpoint',
        'production socket endpoints must use HTTPS/WSS',
      );
    }
    if (maxReconnectAttempts < 0) {
      throw ArgumentError.value(maxReconnectAttempts, 'maxReconnectAttempts');
    }
  }
}
