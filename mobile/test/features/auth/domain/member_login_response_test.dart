import 'package:flutter_test/flutter_test.dart';
import 'package:munserv_mobile/features/auth/domain/member_login_response.dart';

void main() {
  group('MemberLoginResponse', () {
    test('can be created with required fields', () {
      const response = MemberLoginResponse(
        memberId: '123',
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
        expiresIn: 900,
        mustChangePassword: true,
      );

      expect(response.memberId, '123');
      expect(response.accessToken, 'access-token');
      expect(response.refreshToken, 'refresh-token');
      expect(response.expiresIn, 900);
      expect(response.mustChangePassword, true);
    });

    test('should deserialize from JSON', () {
      final json = {
        'memberId': '123',
        'accessToken': 'access-token',
        'refreshToken': 'refresh-token',
        'expiresIn': 900,
        'mustChangePassword': true,
      };

      final response = MemberLoginResponse.fromJson(json);

      expect(response.memberId, '123');
      expect(response.accessToken, 'access-token');
      expect(response.refreshToken, 'refresh-token');
      expect(response.expiresIn, 900);
      expect(response.mustChangePassword, true);
    });

    test('should serialize to JSON', () {
      const response = MemberLoginResponse(
        memberId: '123',
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
        expiresIn: 900,
        mustChangePassword: false,
      );

      final json = response.toJson();

      expect(json['memberId'], '123');
      expect(json['accessToken'], 'access-token');
      expect(json['refreshToken'], 'refresh-token');
      expect(json['expiresIn'], 900);
      expect(json['mustChangePassword'], false);
    });

    test('equality works correctly', () {
      const response1 = MemberLoginResponse(
        memberId: '123',
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
        expiresIn: 900,
        mustChangePassword: true,
      );
      const response2 = MemberLoginResponse(
        memberId: '123',
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
        expiresIn: 900,
        mustChangePassword: true,
      );
      const response3 = MemberLoginResponse(
        memberId: '456',
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
        expiresIn: 900,
        mustChangePassword: true,
      );

      expect(response1, response2);
      expect(response1, isNot(response3));
    });

    test('mustChangePassword false case', () {
      final json = {
        'memberId': '123',
        'accessToken': 'access-token',
        'refreshToken': 'refresh-token',
        'expiresIn': 3600,
        'mustChangePassword': false,
      };

      final response = MemberLoginResponse.fromJson(json);

      expect(response.mustChangePassword, false);
      expect(response.expiresIn, 3600);
    });
  });
}
