import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every explicitly declared root asset exists', () {
    final pubspec = File('pubspec.yaml').readAsLinesSync();
    final declaredAssets = <String>[];
    var inAssets = false;

    for (final line in pubspec) {
      if (line == '  assets:') {
        inAssets = true;
        continue;
      }
      if (inAssets && line.startsWith('  ') && !line.startsWith('    ')) {
        break;
      }
      if (inAssets) {
        final match = RegExp(r'^    - (assets/\S+)$').firstMatch(line);
        if (match != null) declaredAssets.add(match.group(1)!);
      }
    }

    expect(declaredAssets, isNotEmpty);
    expect(
      declaredAssets.where((path) => !File(path).existsSync()),
      isEmpty,
      reason: 'A generated or runtime asset path would fail in production.',
    );
    expect(
      declaredAssets.where((path) => Directory(path).existsSync()),
      isEmpty,
      reason: 'Declare individual files so unused assets cannot ship silently.',
    );
  });

  test('Arabic and English translation keys stay aligned', () {
    final arabicKeys = _translationPaths('assets/translations/ar.json');
    final englishKeys = _translationPaths('assets/translations/en.json');

    expect(arabicKeys.difference(englishKeys), isEmpty);
    expect(englishKeys.difference(arabicKeys), isEmpty);
  });
}

Set<String> _translationPaths(String path) {
  final value = jsonDecode(File(path).readAsStringSync());
  expect(value, isA<Map<String, dynamic>>());
  final paths = <String>{};

  void visit(Object? node, String prefix) {
    if (node is! Map<String, dynamic>) return;
    for (final entry in node.entries) {
      final key = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
      paths.add(key);
      visit(entry.value, key);
    }
  }

  visit(value, '');
  return paths;
}
