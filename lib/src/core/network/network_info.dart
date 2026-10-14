import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkInfo {
  NetworkInfo._() {
    _sub = _connectivity.onConnectivityChanged.listen(_emit);
  }
  static final NetworkInfo _instance = NetworkInfo._();
  factory NetworkInfo() => _instance;

  final Connectivity _connectivity = Connectivity();
  late final StreamSubscription<List<ConnectivityResult>> _sub;

  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  Stream<bool> get onStatusChange => _controller.stream;

  bool _lastKnown = true;
  bool get isOnline => _lastKnown;

  Future<bool> check() async {
    final results = await _connectivity.checkConnectivity();
    _emit(results);
    return _lastKnown;
  }

  /// Connectivity-plus reports "online" the moment Wi-Fi/cellular is attached,
  /// even behind a captive portal or a router with no upstream. This performs
  /// an actual reachability probe (a TCP connection with a timeout) so callers
  /// such as [OfflineQueueManager] only sync when the internet is truly
  /// reachable.
  ///
  /// [host] defaults to Cloudflare's `1.1.1.1` on port 443.
  Future<bool> isReallyOnline({
    String host = '1.1.1.1',
    int port = 443,
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final results = await _connectivity.checkConnectivity();
    if (!results.any((r) => r != ConnectivityResult.none)) return false;
    return probeReachability(host: host, port: port, timeout: timeout);
  }

  /// Opens (and immediately closes) a TCP connection to [host]:[port].
  ///
  /// A name lookup is not a probe: resolving an IP literal such as `1.1.1.1`
  /// never leaves the device, so it succeeds behind a captive portal or with
  /// no upstream. Only a completed connection proves the route.
  static Future<bool> probeReachability({
    required String host,
    required int port,
    Duration timeout = const Duration(seconds: 3),
  }) async {
    try {
      final socket = await Socket.connect(host, port, timeout: timeout);
      socket.destroy();
      return true;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    }
  }

  void _emit(List<ConnectivityResult> results) {
    final online = results.any((r) => r != ConnectivityResult.none);
    if (online != _lastKnown) {
      _lastKnown = online;
      _controller.add(online);
    } else {
      _lastKnown = online;
    }
  }

  void dispose() {
    _sub.cancel();
    _controller.close();
  }
}
