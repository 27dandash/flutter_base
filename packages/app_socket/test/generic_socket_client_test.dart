import 'dart:async';
import 'dart:math';

import 'package:app_socket/app_socket.dart';
import 'package:flutter_test/flutter_test.dart';

final class _Transport implements SocketTransport {
  bool connectFails = false;
  bool connected = false;
  var connectCalls = 0;
  var disconnectCalls = 0;
  final events = <String, List<void Function(Object?)>>{};
  final emitted = <String>[];
  final disconnects = StreamController<void>.broadcast();
  final errorController = StreamController<Object>.broadcast();

  @override
  Stream<void> get disconnected => disconnects.stream;
  @override
  Stream<Object> get errors => errorController.stream;
  @override
  bool get isConnected => connected;
  @override
  Future<void> connect() async {
    connectCalls++;
    if (connectFails) throw StateError('failed');
    connected = true;
  }

  @override
  void disconnect() {
    disconnectCalls++;
    connected = false;
  }

  @override
  void dispose() {}
  @override
  void emit(String event, Object? data) => emitted.add(event);
  @override
  void off(String event, void Function(Object? data) handler) =>
      events[event]?.remove(handler);
  @override
  void on(String event, void Function(Object? data) handler) =>
      events.putIfAbsent(event, () => []).add(handler);
}

final class _Factory implements SocketTransportFactory {
  final created = <_Transport>[];
  bool failNext = false;
  @override
  SocketTransport create({
    required Uri endpoint,
    required Map<String, String> headers,
    required Map<String, dynamic> authentication,
  }) {
    final transport = _Transport()..connectFails = failNext;
    failNext = false;
    created.add(transport);
    return transport;
  }
}

GenericSocketClient _client(_Factory factory) => GenericSocketClient(
  config: AppSocketConfig(
    endpoint: Uri.parse('https://socket.example.com'),
    authentication: () async => {'token': 'not-logged'},
    initialReconnectDelay: Duration.zero,
    maxReconnectDelay: Duration.zero,
    connectionTimeout: const Duration(milliseconds: 20),
  ),
  transportFactory: factory,
  random: Random(1),
);

void main() {
  test('connect is idempotent and emit requires a connection', () async {
    final factory = _Factory();
    final client = _client(factory);
    expect(client.emit('message', const {}), isFalse);
    await Future.wait([client.connect(), client.connect()]);
    expect(factory.created, hasLength(1));
    expect(client.state, AppSocketState.connected);
    expect(client.emit('message', const {}), isTrue);
    await client.dispose();
  });

  test('prevents duplicate listeners and removes safely', () async {
    final factory = _Factory();
    final client = _client(factory);
    expect(client.addListener<String>('message', (v) => '$v', (_) {}), isTrue);
    expect(client.addListener<String>('message', (v) => '$v', (_) {}), isFalse);
    await client.connect();
    expect(factory.created.single.events['message'], hasLength(1));
    client.removeListener('message');
    expect(factory.created.single.events['message'], isEmpty);
    await client.dispose();
  });

  test('network loss pauses and restoration reconnects', () async {
    final factory = _Factory();
    final client = _client(factory);
    await client.connect();
    client.setNetworkAvailable(false);
    expect(client.state, AppSocketState.paused);
    client.setNetworkAvailable(true);
    await Future<void>.delayed(Duration.zero);
    expect(factory.created.length, 2);
    await client.dispose();
  });

  test('authentication change replaces the transport', () async {
    final factory = _Factory();
    final client = _client(factory);
    await client.connect();
    await client.authenticationChanged();
    expect(factory.created.length, 2);
    await client.dispose();
  });

  test('logout disconnects without reconnecting', () async {
    final factory = _Factory();
    final client = _client(factory);
    await client.connect();
    await client.disconnect(logout: true);
    factory.created.last.disconnects.add(null);
    await Future<void>.delayed(Duration.zero);
    expect(factory.created.length, 1);
    await client.dispose();
  });

  test('connection failure maps safely and reconnect is bounded', () async {
    final factory = _Factory()..failNext = true;
    final client = _client(factory);
    await client.connect();
    await Future<void>.delayed(const Duration(milliseconds: 5));
    expect(factory.created.length, greaterThanOrEqualTo(2));
    await client.dispose();
  });
}
