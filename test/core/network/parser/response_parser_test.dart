import 'package:flutter_base/src/core/network/error/failures.dart';
import 'package:flutter_base/src/core/network/parser/response_parser.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

Response<dynamic> _res(dynamic data, int code) => Response<dynamic>(
  requestOptions: RequestOptions(path: '/x'),
  data: data,
  statusCode: code,
);

dynamic _identity(dynamic json) => json;

void main() {
  group('ResponseParser.parse', () {
    test('HTTP 200 success envelope -> Right', () {
      final result = ResponseParser.parse<dynamic>(
        _res({
          'status': 'success',
          'data': {'a': 1},
        }, 200),
        _identity,
      );
      expect(result.isRight(), true);
    });

    test('plain 200 map (no status) -> Right', () {
      final result = ResponseParser.parse<dynamic>(
        _res({'a': 1}, 200),
        _identity,
      );
      expect(result.isRight(), true);
    });

    test('HTTP 200 with status:fail -> Left', () {
      final result = ResponseParser.parse<dynamic>(
        _res({'status': 'fail', 'code': 422, 'message': 'bad'}, 200),
        _identity,
      );
      expect(result.isLeft(), true);
    });

    test('HTTP 200 with status:error -> Left', () {
      final result = ResponseParser.parse<dynamic>(
        _res({'status': 'error', 'code': 500}, 200),
        _identity,
      );
      expect(result.isLeft(), true);
    });

    test('status:fail with code 422 maps to ValidationFailure', () {
      final result = ResponseParser.parse<dynamic>(
        _res({'status': 'fail', 'code': 422}, 200),
        _identity,
      );
      result.fold(
        (f) => expect(f, isA<ValidationFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test('does not call fromJson when envelope indicates failure', () {
      var called = false;
      ResponseParser.parse<dynamic>(
        _res({'status': 'fail', 'code': 400}, 200),
        (json) {
          called = true;
          return json;
        },
      );
      expect(called, false);
    });

    test('HTML body -> ParseFailure', () {
      final result = ResponseParser.parse<dynamic>(
        _res('<!doctype html><html><body>oops</body></html>', 200),
        _identity,
      );
      result.fold(
        (f) => expect(f, isA<ParseFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test('non-2xx maps to a Failure', () {
      final result = ResponseParser.parse<dynamic>(
        _res({'message': 'nope'}, 404),
        _identity,
      );
      result.fold(
        (f) => expect(f, isA<NotFoundFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test('204 / empty body still resolves Right', () {
      final result = ResponseParser.parse<dynamic>(_res(null, 204), _identity);
      expect(result.isRight(), true);
    });
  });
}
