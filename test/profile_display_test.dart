import 'package:flutter_test/flutter_test.dart';
import 'package:gi_english_website/util/AuthService.dart';

void main() {
  group('profileDisplayName', () {
    test('uses nickname before legal name', () {
      expect(
        AuthService.profileDisplayName({
          'nickname': 'Sunny',
          'name': '김수연',
          'email': 'a@b.com',
        }),
        'Sunny',
      );
    });

    test('falls back to name then email', () {
      expect(
        AuthService.profileDisplayName({'name': '김수연', 'email': 'a@b.com'}),
        '김수연',
      );
      expect(
        AuthService.profileDisplayName({'email': 'a@b.com'}),
        'a@b.com',
      );
      expect(AuthService.profileDisplayName({}, fallback: '수강생'), '수강생');
    });
  });

  group('validateNickname', () {
    test('allows empty unless required', () {
      expect(AuthService.validateNickname(''), isNull);
      expect(AuthService.validateNickname('', required: true), isNotNull);
    });

    test('rejects email-like or too short/long values', () {
      expect(AuthService.validateNickname('a'), isNotNull);
      expect(AuthService.validateNickname('me@school.com'), isNotNull);
      expect(AuthService.validateNickname('abcdefghijklmnopq'), isNotNull);
      expect(AuthService.validateNickname('Sunny'), isNull);
      expect(AuthService.validateNickname('수연'), isNull);
    });
  });
}
