import 'package:flutter_base/src/core/network/exceptions/app_exception.dart';
import 'package:flutter_base/src/core/network/parser/status_code_handler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StatusCodeHandler.handle', () {
    test('maps known status codes to the right exception types', () {
      expect(
        StatusCodeHandler.handle(statusCode: 401),
        isA<UnauthorizedException>(),
      );
      expect(
        StatusCodeHandler.handle(statusCode: 404),
        isA<NotFoundException>(),
      );
      expect(
        StatusCodeHandler.handle(statusCode: 500),
        isA<InternalServerException>(),
      );
      expect(
        StatusCodeHandler.handle(statusCode: 503),
        isA<MaintenanceException>(),
      );
    });

    test('422 reads validation fields from data.items', () {
      final ex = StatusCodeHandler.handle(
        statusCode: 422,
        responseData: const {
          'data': {
            'items': {
              'email': ['taken'],
              'name': 'required',
            },
          },
        },
      );
      expect(ex, isA<UnprocessableException>());
      final fields = (ex as UnprocessableException).errors;
      expect(fields?['email'], ['taken']);
      expect(fields?['name'], ['required']);
    });

    test('422 falls back to legacy errors shape', () {
      final ex = StatusCodeHandler.handle(
        statusCode: 422,
        responseData: const {
          'errors': {
            'phone': ['invalid'],
          },
        },
      );
      final fields = (ex as UnprocessableException).errors;
      expect(fields?['phone'], ['invalid']);
    });

    test('400 maps to ValidationException with fields', () {
      final ex = StatusCodeHandler.handle(
        statusCode: 400,
        responseData: const {
          'validation': {
            'city': ['required'],
          },
        },
      );
      expect(ex, isA<ValidationException>());
      expect((ex as ValidationException).fields?['city'], ['required']);
    });

    test('forwards server message into serverMessage', () {
      final ex = StatusCodeHandler.handle(
        statusCode: 409,
        responseData: const {'message': 'Email already in use'},
      );
      expect(ex, isA<ConflictException>());
      expect((ex as ConflictException).serverMessage, 'Email already in use');
    });

    test('unknown status -> ServerException', () {
      final ex = StatusCodeHandler.handle(statusCode: 418);
      expect(ex, isA<ServerException>());
    });
  });
}
