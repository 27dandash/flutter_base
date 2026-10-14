import 'dart:io';

import 'package:flutter_base/src/core/network/network_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('probe succeeds only when a TCP connection completes', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);

    expect(
      await NetworkInfo.probeReachability(
        host: '127.0.0.1',
        port: server.port,
        timeout: const Duration(seconds: 2),
      ),
      isTrue,
    );
  });

  test('probe fails when nothing listens, unlike a name lookup', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final closedPort = server.port;
    await server.close();

    // An IP literal "resolves" locally without any network, which is why the
    // previous lookup-based probe could never detect a dead route.
    expect(await InternetAddress.lookup('127.0.0.1'), isNotEmpty);
    expect(
      await NetworkInfo.probeReachability(
        host: '127.0.0.1',
        port: closedPort,
        timeout: const Duration(seconds: 2),
      ),
      isFalse,
    );
  });

  test('probe reports an unresolvable host as unreachable', () async {
    expect(
      await NetworkInfo.probeReachability(
        host: 'host.invalid',
        port: 443,
        timeout: const Duration(seconds: 2),
      ),
      isFalse,
    );
  });
}
