import 'package:flutter_base/src/config/app_config.dart';
import 'package:flutter_base/src/core/network/error/failures.dart';
import 'package:flutter_base/src/core/network/parser/response_parser.dart';
import 'package:flutter_base/src/core/network/php/php_envelope.dart';
import 'package:flutter_base/src/core/network/php/php_response_keys.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

dynamic _identity(dynamic json) => json;

Response<dynamic> _res(dynamic data, int code) => Response<dynamic>(
  requestOptions: RequestOptions(path: '/x'),
  data: data,
  statusCode: code,
);

void main() {
  group('PhpEnvelope.tryFrom', () {
    test('recognizes every known key', () {
      for (final key in PhpResponseKeys.known) {
        final env = PhpEnvelope.tryFrom({'key': key, 'msg': 'm'});
        expect(env, isNotNull, reason: 'should recognize "$key"');
        expect(env!.key, key);
        expect(env.msg, 'm');
      }
    });

    test('returns null for anything that is not a known envelope', () {
      expect(PhpEnvelope.tryFrom(null), isNull);
      expect(PhpEnvelope.tryFrom('plain string'), isNull);
      expect(PhpEnvelope.tryFrom(<dynamic>[1, 2]), isNull);
      expect(PhpEnvelope.tryFrom({'a': 1}), isNull);
      expect(PhpEnvelope.tryFrom({'key': 'unknown'}), isNull);
      expect(PhpEnvelope.tryFrom({'key': 123}), isNull);
      expect(PhpEnvelope.tryFrom({'message': 'x'}), isNull);
    });

    test('exposes data, count_notifications and ad-hoc extras', () {
      final env = PhpEnvelope.tryFrom({
        'key': 'success',
        'msg': 'ok',
        'data': {'id': 1},
        'count_notifications': 5,
        'url': 'https://x',
      });
      expect(env!.data, {'id': 1});
      expect(env.countNotifications, 5);
      expect(env.extra('url'), 'https://x');
    });

    test('coerces a string count_notifications to int', () {
      final env = PhpEnvelope.tryFrom({
        'key': 'success',
        'count_notifications': '7',
      });
      expect(env!.countNotifications, 7);
    });

    test('decodes a String JSON body (interceptor/parser decode parity)', () {
      final env = PhpEnvelope.tryFrom('{"key":"unauthenticated","msg":"x"}');
      expect(env, isNotNull);
      expect(env!.key, 'unauthenticated');
      expect(env.msg, 'x');
    });

    test('returns null for empty / non-JSON String bodies', () {
      expect(PhpEnvelope.tryFrom(''), isNull);
      expect(PhpEnvelope.tryFrom('   '), isNull);
      expect(PhpEnvelope.tryFrom('not json'), isNull);
      expect(PhpEnvelope.tryFrom('<html></html>'), isNull);
    });
  });

  group('ResponseParser.phpOutcome — 7-key mapping', () {
    test('success -> Right and hands the WHOLE envelope to fromJson', () {
      dynamic received;
      final env = PhpEnvelope.tryFrom({
        'key': 'success',
        'msg': 'ok',
        'data': [1, 2],
        'count_notifications': 3,
      })!;
      final result = ResponseParser.phpOutcome<dynamic>(env, (json) {
        received = json;
        return json;
      });
      expect(result.isRight(), true);
      expect((received as Map)['data'], [1, 2]);
      expect((received as Map)['count_notifications'], 3);
    });

    test('fail -> ValidationFailure carrying msg, fromJson NOT called', () {
      var called = false;
      final env = PhpEnvelope.tryFrom({
        'key': 'fail',
        'msg': 'invalid coupon',
      })!;
      final result = ResponseParser.phpOutcome<dynamic>(env, (_) {
        called = true;
        return null;
      });
      expect(called, false);
      result.fold((f) {
        expect(f, isA<ValidationFailure>());
        expect((f as ValidationFailure).customMessage, 'invalid coupon');
        expect(f.retryable, false);
      }, (_) => fail('expected Left'));
    });

    test('needActive -> NeedActiveFailure carrying activationData', () {
      final env = PhpEnvelope.tryFrom({
        'key': 'needActive',
        'msg': 'activate',
        'data': {'phone': '05x'},
      })!;
      ResponseParser.phpOutcome<dynamic>(env, _identity).fold((f) {
        expect(f, isA<NeedActiveFailure>());
        final na = f as NeedActiveFailure;
        expect(na.customMessage, 'activate');
        expect(na.activationData, {'phone': '05x'});
      }, (_) => fail('expected Left'));
    });

    test('blocked -> BlockedFailure carrying msg', () {
      final env = PhpEnvelope.tryFrom({'key': 'blocked', 'msg': 'banned'})!;
      ResponseParser.phpOutcome<dynamic>(env, _identity).fold((f) {
        expect(f, isA<BlockedFailure>());
        expect((f as BlockedFailure).customMessage, 'banned');
      }, (_) => fail('expected Left'));
    });

    test('unauthenticated -> UnauthorizedFailure', () {
      final env = PhpEnvelope.tryFrom({'key': 'unauthenticated'})!;
      ResponseParser.phpOutcome<dynamic>(env, _identity).fold(
        (f) => expect(f, isA<UnauthorizedFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test('unauthorized -> PermissionFailure carrying msg', () {
      final env = PhpEnvelope.tryFrom({
        'key': 'unauthorized',
        'msg': 'no access',
      })!;
      ResponseParser.phpOutcome<dynamic>(env, _identity).fold((f) {
        expect(f, isA<PermissionFailure>());
        expect((f as PermissionFailure).customMessage, 'no access');
      }, (_) => fail('expected Left'));
    });

    test('exception -> ServerFailure with line/file in technical only', () {
      final env = PhpEnvelope.tryFrom({
        'key': 'exception',
        'msg': 'dev-only boom',
        'data': {'line': 42, 'file': 'x.php'},
      })!;
      ResponseParser.phpOutcome<dynamic>(env, _identity).fold((f) {
        expect(f, isA<ServerFailure>());
        final sf = f as ServerFailure;
        expect(sf.customMessage, isNull);
        expect(sf.technical, contains('42'));
        expect(sf.technical, contains('x.php'));
      }, (_) => fail('expected Left'));
    });
  });

  group(
    'parse() routes by key regardless of HTTP status (runs when flag is on)',
    () {
      test(
        '203 {key:needActive} -> NeedActiveFailure (NOT read as success)',
        () {
          final result = ResponseParser.parse<dynamic>(
            _res({
              'key': 'needActive',
              'msg': 'activate',
              'data': {'phone': '05'},
            }, 203),
            _identity,
          );
          result.fold(
            (f) => expect(f, isA<NeedActiveFailure>()),
            (_) => fail('expected Left — 203 must be keyed off `key`'),
          );
        },
      );

      test('200 {key:fail} -> ValidationFailure', () {
        final result = ResponseParser.parse<dynamic>(
          _res({'key': 'fail', 'msg': 'bad'}, 200),
          _identity,
        );
        result.fold(
          (f) => expect(f, isA<ValidationFailure>()),
          (_) => fail('expected Left'),
        );
      });

      test('non-envelope body still falls through to status-code handling', () {
        final result = ResponseParser.parse<dynamic>(
          _res({'message': 'nope'}, 404),
          _identity,
        );
        result.fold(
          (f) => expect(f, isA<NotFoundFailure>()),
          (_) => fail('expected Left'),
        );
      });
    },
    skip: AppConfig.phpResponseMode
        ? false
        : 'asserts flag-on routing; enable with PHP_RESPONSE_MODE=true',
  );

  group(
    'OFF-mode guarantee (runs only when the flag resolves to false)',
    () {
      test(
        'a body that WOULD be a PHP envelope goes through the normal path',
        () {
          final result = ResponseParser.parse<dynamic>(
            _res({
              'key': 'success',
              'msg': 'ok',
              'data': {'a': 1},
            }, 200),
            _identity,
          );
          expect(result.isRight(), true);
        },
      );

      test('a 200 {key: fail} is NOT mapped to a failure when mode is off', () {
        final result = ResponseParser.parse<dynamic>(
          _res({'key': 'fail', 'msg': 'x'}, 200),
          _identity,
        );
        expect(result.isRight(), true);
      });
    },
    skip: AppConfig.phpResponseMode
        ? 'asserts flag-off behavior; not valid with PHP_RESPONSE_MODE=true'
        : false,
  );
}
