import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import 'socket_transport.dart';

final class SocketIoTransportFactory implements SocketTransportFactory {
  const SocketIoTransportFactory();

  @override
  SocketTransport create({
    required Uri endpoint,
    required Map<String, String> headers,
    required Map<String, dynamic> authentication,
  }) {
    final socket = io.io(
      endpoint.toString(),
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setExtraHeaders(headers)
          .setAuth(authentication)
          .disableAutoConnect()
          .disableReconnection()
          .build(),
    );
    return _SocketIoTransport(socket);
  }
}

final class _SocketIoTransport implements SocketTransport {
  _SocketIoTransport(this._socket) {
    _socket.onDisconnect((_) => _disconnected.add(null));
    _socket.onError((error) => _errors.add(error ?? 'socket_error'));
    _socket.onConnectError((error) => _errors.add(error ?? 'connection_error'));
  }

  final io.Socket _socket;
  final StreamController<void> _disconnected =
      StreamController<void>.broadcast();
  final StreamController<Object> _errors = StreamController<Object>.broadcast();
  Future<void>? _connecting;

  @override
  Stream<void> get disconnected => _disconnected.stream;

  @override
  Stream<Object> get errors => _errors.stream;

  @override
  bool get isConnected => _socket.connected;

  @override
  Future<void> connect() {
    if (_socket.connected) return Future<void>.value();
    return _connecting ??= _connect().whenComplete(() => _connecting = null);
  }

  Future<void> _connect() {
    final completer = Completer<void>();
    void onConnect(Object? _) {
      if (!completer.isCompleted) completer.complete();
    }

    void onError(Object? error) {
      if (!completer.isCompleted) {
        completer.completeError(
          error ?? StateError('Socket connection failed'),
        );
      }
    }

    _socket
      ..once('connect', onConnect)
      ..once('connect_error', onError)
      ..connect();
    return completer.future.whenComplete(() {
      _socket
        ..off('connect', onConnect)
        ..off('connect_error', onError);
    });
  }

  @override
  void disconnect() => _socket.disconnect();

  @override
  void dispose() {
    _socket.dispose();
    _disconnected.close();
    _errors.close();
  }

  @override
  void emit(String event, Object? data) => _socket.emit(event, data);

  @override
  void on(String event, void Function(Object? data) handler) =>
      _socket.on(event, handler);

  @override
  void off(String event, void Function(Object? data) handler) =>
      _socket.off(event, handler);
}
