import 'package:flutter_base/src/core/network/error/failures.dart';
import 'package:flutter_base/src/core/network/exceptions/app_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppException -> Failure mapping', () {
    test('NetworkException -> NetworkFailure', () {
      expect(const NetworkException().toFailure(), isA<NetworkFailure>());
    });

    test('timeouts collapse into TimeoutFailure', () {
      expect(
        const ConnectionTimeoutException().toFailure(),
        isA<TimeoutFailure>(),
      );
      expect(
        const GatewayTimeoutException().toFailure(),
        isA<TimeoutFailure>(),
      );
    });

    test('UnauthorizedException -> UnauthorizedFailure', () {
      expect(
        const UnauthorizedException().toFailure(),
        isA<UnauthorizedFailure>(),
      );
    });

    test('server message is retained but never becomes user-facing copy', () {
      final failure = ConflictException('Already exists').toFailure();
      expect(failure, isA<ConflictFailure>());
      expect((failure as ConflictFailure).customMessage, 'Already exists');
      expect(failure.userMessage, isNot('Already exists'));
    });

    test(
      'no server message -> customMessage stays null (uses localized default)',
      () {
        final failure = PermissionException().toFailure();
        expect(failure, isA<PermissionFailure>());
        expect((failure as PermissionFailure).customMessage, isNull);
      },
    );

    test('validation errors are carried over', () {
      final failure = UnprocessableException(
        null,
        errors: const {
          'email': ['taken'],
        },
      ).toFailure();
      expect(failure, isA<ValidationFailure>());
      expect((failure as ValidationFailure).fields?['email'], ['taken']);
      expect(failure.userMessage, isNot('taken'));
    });

    test('CancelledRequest -> CancelledFailure', () {
      expect(const CancelledRequest().toFailure(), isA<CancelledFailure>());
    });
  });
}
