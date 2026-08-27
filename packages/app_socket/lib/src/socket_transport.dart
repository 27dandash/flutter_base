abstract interface class SocketTransport {
  bool get isConnected;
  Stream<void> get disconnected;
  Stream<Object> get errors;

  Future<void> connect();
  void disconnect();
  void dispose();
  void emit(String event, Object? data);
  void on(String event, void Function(Object? data) handler);
  void off(String event, void Function(Object? data) handler);
}

abstract interface class SocketTransportFactory {
  SocketTransport create({
    required Uri endpoint,
    required Map<String, String> headers,
    required Map<String, dynamic> authentication,
  });
}
