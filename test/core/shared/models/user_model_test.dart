import 'package:flutter_base/src/core/shared/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserModel.fromJson', () {
    test('empty map does not throw and yields safe defaults', () {
      final user = UserModel.fromJson(const {});
      expect(user.id, '');
      expect(user.fullName, '');
      expect(user.phoneNumber, '');
      expect(user.email, '');
      expect(user.city, '');
      expect(user.userType, 0);
      expect(user.allowNotify, false);
      expect(user.token, isNull);
    });

    test('parses snake_case keys', () {
      final user = UserModel.fromJson(const {
        'id': 'u1',
        'full_name': 'Sara',
        'phone_number': '0500000000',
        'user_type': 2,
        'allow_notify': true,
        'access_token': 'tok',
      });
      expect(user.fullName, 'Sara');
      expect(user.phoneNumber, '0500000000');
      expect(user.userType, 2);
      expect(user.allowNotify, true);
      expect(user.token, 'tok');
    });

    test('parses camelCase keys', () {
      final user = UserModel.fromJson(const {
        'fullName': 'Omar',
        'phoneNumber': '12345',
        'userType': 3,
      });
      expect(user.fullName, 'Omar');
      expect(user.phoneNumber, '12345');
      expect(user.userType, 3);
    });

    test('coerces id int -> String', () {
      final user = UserModel.fromJson(const {'id': 123});
      expect(user.id, '123');
    });

    test('coerces allowNotify from string and int', () {
      expect(
        UserModel.fromJson(const {'allow_notify': 'true'}).allowNotify,
        true,
      );
      expect(UserModel.fromJson(const {'allow_notify': 1}).allowNotify, true);
      expect(UserModel.fromJson(const {'allow_notify': 0}).allowNotify, false);
    });

    test('coerces userType from numeric string', () {
      expect(UserModel.fromJson(const {'user_type': '5'}).userType, 5);
      expect(UserModel.fromJson(const {'user_type': 'x'}).userType, 0);
    });
  });

  group('UserModel.toJson', () {
    test('writes snake_case and excludes token', () {
      final user = UserModel.fromJson(const {
        'id': 'u1',
        'full_name': 'Sara',
        'access_token': 'tok',
      });
      final json = user.toJson();
      expect(json.containsKey('full_name'), true);
      expect(json.containsKey('token'), false);
      expect(json['full_name'], 'Sara');
    });

    test('round-trips through fromJson', () {
      final original = UserModel.fromJson(const {
        'id': 'u1',
        'full_name': 'Sara',
        'phone_number': '050',
        'user_type': 2,
        'allow_notify': true,
      });
      final restored = UserModel.fromJson(original.toJson());
      expect(restored.fullName, original.fullName);
      expect(restored.userType, original.userType);
      expect(restored.allowNotify, original.allowNotify);
    });
  });

  test('initial() returns safe defaults', () {
    final u = UserModel.initial();
    expect(u.id, '');
    expect(u.userType, 0);
    expect(u.allowNotify, false);
  });
}
