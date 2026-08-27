import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const optionalPackages = {
    'app_notifications',
    'app_remote_config',
    'app_webview',
    'app_maps',
    'app_socket',
  };

  test('feature domain code has no framework or infrastructure imports', () {
    final domainFiles = Directory('lib/src/features')
        .listSync(recursive: true)
        .whereType<File>()
        .where(
          (file) =>
              file.path.endsWith('.dart') && file.path.contains('/domain/'),
        );
    const forbidden = [
      'package:flutter/',
      'package:dio/',
      'package:hive_ce/',
      'package:flutter_bloc/',
      '/presentation/',
      '/data/',
    ];

    for (final file in domainFiles) {
      final source = file.readAsStringSync();
      for (final import in forbidden) {
        expect(
          source,
          isNot(contains(import)),
          reason: '${file.path} crosses the domain boundary via $import',
        );
      }
    }
  });

  test('root source and pubspec do not opt into optional integrations', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final rootSources = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final package in optionalPackages) {
      expect(
        pubspec,
        isNot(contains(RegExp('^  $package:', multiLine: true))),
        reason: '$package must remain opt-in.',
      );
      for (final file in rootSources) {
        expect(
          file.readAsStringSync(),
          isNot(contains('package:$package/')),
          reason: '${file.path} imports optional package $package.',
        );
      }
    }
  });

  test('navigation imports use one canonical lowercase URI identity', () {
    final dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    const nonCanonicalSegments = [
      '/navigation/Transition/',
      '/navigation/Constants/',
      '/navigation/Helper/',
      '/page_router/Implementation/',
    ];

    for (final file in dartFiles) {
      final source = file.readAsStringSync();
      for (final segment in nonCanonicalSegments) {
        expect(
          source,
          isNot(contains(segment)),
          reason:
              '${file.path} imports $segment with a second URI identity. '
              'This can create runtime-incompatible duplicate Dart types on '
              'case-insensitive file systems.',
        );
      }
    }
  });
}
