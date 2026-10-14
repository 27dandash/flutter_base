import 'dart:async';
import 'dart:math';

import 'socket_models.dart';
import 'socket_transport.dart';

final class GenericSocketClient {
  GenericSocketClient({
    required this.config,
    required this.transportFactory,
    Random? random,
  }) : _random = random ?? Random.secure() {
    config.validate();
  }

  final AppSocketConfig config;
  final SocketTransportFactory transportFactory;
  final Random _random;
  final StreamController<AppSocketState> _states =
      StreamController<AppSocketState>.broadcast();
  final StreamController<AppSocketFailure> _failures =
      StreamController<AppSocketFailure>.broadcast();
  final Map<String, void Function(Object? data)> _listeners = {};

  SocketTransport? _transport;
  StreamSubscription<void>? _disconnectSubscription;
  StreamSubscription<Object>? _errorSubscription;
  Future<void>? _connectionInFlight;
  Timer? _reconnectTimer;
  AppSocketState _state = AppSocketState.disconnected;
  bool _networkAvailable = true;
  bool _appActive = true;
  bool _allowReconnect = true;
  int _reconnectAttempts = 0;
  int _generation = 0;

  AppSocketState get state => _state;
  Stream<AppSocketState> get states => _states.stream;
  Stream<AppSocketFailure> get failures => _failures.stream;

  Future<void> connect() {
    if (_state == AppSocketState.disposed ||
        _state == AppSocketState.connected ||
        _state == AppSocketState.authenticationFailed ||
        !_networkAvailable ||
        !_appActive) {
      return Future<void>.value();
    }
    final inFlight = _connectionInFlight;
    if (inFlight != null) return inFlight;

    late final Future<void> connection;
    connection = _connect().whenComplete(() {
      if (identical(_connectionInFlight, connection)) {
        _connectionInFlight = null;
      }
    });
    _connectionInFlight = connection;
    return connection;
  }

  Future<void> _connect() async {
    final generation = _generation;
    _setState(
      _reconnectAttempts == 0
          ? AppSocketState.connecting
          : AppSocketState.reconnecting,
    );
    try {
      final authentication = await config.authentication().timeout(
        config.connectionTimeout,
      );
      if (generation != _generation) return;
      final transport = transportFactory.create(
        endpoint: config.endpoint,
        headers: config.headers,
        authentication: authentication,
      );
      _replaceTransport(transport);
      await transport.connect().timeout(config.connectionTimeout);
      if (generation != _generation) {
        transport.disconnect();
        return;
      }
      _reconnectAttempts = 0;
      _setState(AppSocketState.connected);
    } on TimeoutException {
      if (generation != _generation) return;
      _failures.add(const AppSocketFailure('connection_timeout'));
      _scheduleReconnect();
    } on SocketAuthenticationException catch (error) {
      if (generation != _generation) return;
      _failures.add(AppSocketFailure(error.code, retryable: false));
      _reconnectTimer?.cancel();
      _setState(AppSocketState.authenticationFailed);
    } catch (_) {
      if (generation != _generation) return;
      _failures.add(const AppSocketFailure('connection_failed'));
      _scheduleReconnect();
    }
  }

  /// Stops reacting to the transport's `disconnected` event.
  ///
  /// Socket.IO emits `disconnect` for a *local* `disconnect()` call too. An
  /// intentional disconnect (explicit, network loss, app paused) must not be
  /// mistaken for a dropped connection: it would overwrite the `paused` state
  /// and schedule a reconnect the caller asked not to have.
  void _detachDisconnectListener() {
    final subscription = _disconnectSubscription;
    _disconnectSubscription = null;
    if (subscription != null) unawaited(subscription.cancel());
  }

  void _replaceTransport(SocketTransport transport) {
    _disconnectSubscription?.cancel();
    _errorSubscription?.cancel();
    _transport?.dispose();
    _transport = transport;
    for (final entry in _listeners.entries) {
      transport.on(entry.key, entry.value);
    }
    _disconnectSubscription = transport.disconnected.listen((_) {
      if (_state != AppSocketState.disposed) {
        _setState(AppSocketState.disconnected);
        _scheduleReconnect();
      }
    });
    _errorSubscription = transport.errors.listen((_) {
      _failures.add(const AppSocketFailure('transport_error'));
    });
  }

  bool addListener<T>(
    String event,
    T Function(Object? data) parser,
    void Function(T value) listener,
  ) {
    if (event.trim().isEmpty || _listeners.containsKey(event)) return false;
    void handler(Object? data) {
      try {
        listener(parser(data));
      } catch (_) {
        _failures.add(const AppSocketFailure('event_parse_error'));
      }
    }

    _listeners[event] = handler;
    _transport?.on(event, handler);
    return true;
  }

  void removeListener(String event) {
    final handler = _listeners.remove(event);
    if (handler != null) _transport?.off(event, handler);
  }

  bool emit(String event, Object? data) {
    final transport = _transport;
    if (event.trim().isEmpty || transport == null || !transport.isConnected) {
      return false;
    }
    transport.emit(event, data);
    return true;
  }

  void setNetworkAvailable(bool available) {
    if (_networkAvailable == available) return;
    _networkAvailable = available;
    if (!available) {
      _invalidateConnection();
      _reconnectTimer?.cancel();
      _detachDisconnectListener();
      _transport?.disconnect();
      _setState(AppSocketState.paused);
    } else if (_appActive && _allowReconnect) {
      unawaited(connect());
    }
  }

  void setAppActive(bool active) {
    if (_appActive == active) return;
    _appActive = active;
    if (!active) {
      _invalidateConnection();
      _reconnectTimer?.cancel();
      _detachDisconnectListener();
      _transport?.disconnect();
      _setState(AppSocketState.paused);
    } else if (_networkAvailable && _allowReconnect) {
      unawaited(connect());
    }
  }

  Future<void> authenticationChanged() async {
    if (_state == AppSocketState.disposed) return;
    _allowReconnect = true;
    _invalidateConnection();
    _reconnectTimer?.cancel();
    await _disconnectSubscription?.cancel();
    _disconnectSubscription = null;
    _transport?.disconnect();
    _setState(AppSocketState.disconnected);
    _reconnectAttempts = 0;
    if (_networkAvailable && _appActive) await connect();
  }

  void _scheduleReconnect() {
    if (!_allowReconnect ||
        !_networkAvailable ||
        !_appActive ||
        _state == AppSocketState.disposed ||
        _state == AppSocketState.authenticationFailed ||
        _reconnectAttempts >= config.maxReconnectAttempts ||
        _reconnectTimer?.isActive == true) {
      if (_reconnectAttempts >= config.maxReconnectAttempts) {
        _setState(AppSocketState.failed);
      }
      return;
    }
    final exponent = _reconnectAttempts.clamp(0, 20);
    final baseMs =
        config.initialReconnectDelay.inMilliseconds * (1 << exponent);
    final cappedMs = min(baseMs, config.maxReconnectDelay.inMilliseconds);
    final jitterMs = cappedMs == 0 ? 0 : _random.nextInt(max(1, cappedMs ~/ 4));
    _reconnectAttempts++;
    _reconnectTimer = Timer(
      Duration(milliseconds: cappedMs + jitterMs),
      () => unawaited(connect()),
    );
  }

  Future<void> disconnect({bool logout = false}) async {
    if (logout) _allowReconnect = false;
    _invalidateConnection();
    _reconnectTimer?.cancel();
    _detachDisconnectListener();
    _transport?.disconnect();
    _setState(AppSocketState.disconnected);
  }

  void _setState(AppSocketState value) {
    if (_state == value || _state == AppSocketState.disposed) return;
    _state = value;
    _states.add(value);
  }

  void _invalidateConnection() {
    _generation++;
    // Dart Futures are not cancellable. Detach the stale attempt so a new
    // lifecycle/auth generation can connect immediately; generation checks in
    // [_connect] prevent the old attempt from publishing state or reconnects.
    _connectionInFlight = null;
  }

  Future<void> dispose() async {
    if (_state == AppSocketState.disposed) return;
    _allowReconnect = false;
    _invalidateConnection();
    _reconnectTimer?.cancel();
    await _disconnectSubscription?.cancel();
    await _errorSubscription?.cancel();
    _transport?.dispose();
    _transport = null;
    _state = AppSocketState.disposed;
    _states.add(_state);
    await _states.close();
    await _failures.close();
  }
}
