import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  // Dart imports are case-sensitive and the repository must build on Linux CI
  // as well as on case-insensitive developer machines. A directory that is
  // committed with capitals while imports use lowercase only works on macOS and
  // Windows.
  test('every directory under lib and test is lowercase', () {
    final offenders = <String>[];
    for (final root in ['lib', 'test']) {
      for (final entity in Directory(root).listSync(recursive: true)) {
        if (entity is! Directory) continue;
        final name = entity.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
        if (name != name.toLowerCase()) offenders.add(entity.path);
      }
    }
    expect(offenders, isEmpty);
  });
}
