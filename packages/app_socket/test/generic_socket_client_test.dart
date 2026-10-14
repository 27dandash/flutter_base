import 'dart:async';
import 'dart:math';

import 'package:app_socket/app_socket.dart';
import 'package:flutter_test/flutter_test.dart';

final class _Transport implements SocketTransport {
  _Transport({this.connectGate});

  final Completer<void>? connectGate;
  bool connectFails = false;
  bool connected = false;

  /// Real Socket.IO fires `disconnect` for a local `disconnect()` as well.
  bool emitsOnLocalDisconnect = false;
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
    await connectGate?.future;
    connected = true;
  }

  @override
  void disconnect() {
    disconnectCalls++;
    connected = false;
    if (emitsOnLocalDisconnect) disconnects.add(null);
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
  bool emitsOnLocalDisconnect = false;
  Completer<void>? nextConnectGate;
  @override
  SocketTransport create({
    required Uri endpoint,
    required Map<String, String> headers,
    required Map<String, dynamic> authentication,
  }) {
    final transport = _Transport(connectGate: nextConnectGate)
      ..connectFails = failNext
      ..emitsOnLocalDisconnect = emitsOnLocalDisconnect;
    failNext = false;
    nextConnectGate = null;
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

Future<void> _pumpUntil(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 2));
  while (!condition() && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(Duration.zero);
  }
  expect(condition(), isTrue, reason: 'condition did not become true');
}

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

  test('authentication change supersedes an in-flight connection', () async {
    final firstGate = Completer<void>();
    final factory = _Factory()..nextConnectGate = firstGate;
    final client = _client(factory);

    final staleConnection = client.connect();
    await _pumpUntil(() => factory.created.length == 1);
    await client.authenticationChanged();

    expect(factory.created, hasLength(2));
    expect(client.state, AppSocketState.connected);

    firstGate.complete();
    await staleConnection;
    expect(factory.created.first.connected, isFalse);
    expect(client.state, AppSocketState.connected);
    await client.dispose();
  });

  test('pause and resume supersede an in-flight connection', () async {
    final firstGate = Completer<void>();
    final factory = _Factory()..nextConnectGate = firstGate;
    final client = _client(factory);

    final staleConnection = client.connect();
    await _pumpUntil(() => factory.created.length == 1);
    client.setNetworkAvailable(false);
    expect(client.state, AppSocketState.paused);
    client.setNetworkAvailable(true);
    await _pumpUntil(() => factory.created.length == 2);
    expect(client.state, AppSocketState.connected);

    firstGate.complete();
    await staleConnection;
    expect(factory.created.first.connected, isFalse);
    expect(client.state, AppSocketState.connected);
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

  test('authentication provider failure emits authenticationFailed', () async {
    final factory = _Factory();
    final failures = <AppSocketFailure>[];
    final states = <AppSocketState>[];
    final client = GenericSocketClient(
      config: AppSocketConfig(
        endpoint: Uri.parse('https://socket.example.com'),
        authentication: () async => throw const SocketAuthenticationException(
          'credentials_unavailable',
        ),
        initialReconnectDelay: Duration.zero,
        maxReconnectDelay: Duration.zero,
        connectionTimeout: const Duration(milliseconds: 20),
      ),
      transportFactory: factory,
      random: Random(1),
    );
    client.failures.listen(failures.add);
    client.states.listen(states.add);

    await client.connect();
    await Future<void>.delayed(Duration.zero);

    expect(client.state, AppSocketState.authenticationFailed);
    expect(factory.created, isEmpty);
    expect(failures.single.code, 'credentials_unavailable');
    expect(failures.single.retryable, isFalse);
    expect(states, contains(AppSocketState.authenticationFailed));
    await client.dispose();
  });

  test('authenticationChanged recovers after authenticationFailed', () async {
    var authenticated = false;
    final factory = _Factory();
    final client = GenericSocketClient(
      config: AppSocketConfig(
        endpoint: Uri.parse('https://socket.example.com'),
        authentication: () async {
          if (!authenticated) {
            throw const SocketAuthenticationException(
              'credentials_unavailable',
            );
          }
          return {'token': 'fresh'};
        },
        initialReconnectDelay: Duration.zero,
        maxReconnectDelay: Duration.zero,
        connectionTimeout: const Duration(milliseconds: 20),
      ),
      transportFactory: factory,
      random: Random(1),
    );

    await client.connect();
    expect(client.state, AppSocketState.authenticationFailed);

    authenticated = true;
    await client.authenticationChanged();
    expect(client.state, AppSocketState.connected);
    expect(factory.created, hasLength(1));
    await client.dispose();
  });

  group('with a transport that reports local disconnects (Socket.IO)', () {
    test('an explicit disconnect stays disconnected', () async {
      final factory = _Factory()..emitsOnLocalDisconnect = true;
      final client = _client(factory);
      await client.connect();
      expect(client.state, AppSocketState.connected);

      await client.disconnect();
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(client.state, AppSocketState.disconnected);
      expect(factory.created, hasLength(1), reason: 'no automatic reconnect');
      await client.dispose();
    });

    test('network loss ends in paused, not disconnected', () async {
      final factory = _Factory()..emitsOnLocalDisconnect = true;
      final client = _client(factory);
      await client.connect();

      client.setNetworkAvailable(false);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(client.state, AppSocketState.paused);

      client.setNetworkAvailable(true);
      await _pumpUntil(() => client.state == AppSocketState.connected);
      expect(factory.created, hasLength(2));
      await client.dispose();
    });

    test(
      'backgrounding the app ends in paused and resumes on return',
      () async {
        final factory = _Factory()..emitsOnLocalDisconnect = true;
        final client = _client(factory);
        await client.connect();

        client.setAppActive(false);
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(client.state, AppSocketState.paused);
        expect(factory.created, hasLength(1));

        client.setAppActive(true);
        await _pumpUntil(() => client.state == AppSocketState.connected);
        await client.dispose();
      },
    );

    test('a genuine server-side drop still reconnects', () async {
      final factory = _Factory()..emitsOnLocalDisconnect = true;
      final client = _client(factory);
      await client.connect();

      factory.created.single.connected = false;
      factory.created.single.disconnects.add(null);

      await _pumpUntil(() => factory.created.length == 2);
      await _pumpUntil(() => client.state == AppSocketState.connected);
      await client.dispose();
    });
  });
}
