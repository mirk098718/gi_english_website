import 'package:flutter_test/flutter_test.dart';
import 'package:gi_english_website/util/AuthService.dart';

void main() {
  test('role 이 없는 admins 문서는 메인 관리자가 아니다', () {
    final student = {
      'bookingOffer': 'coteach',
      'nativeProfileId': 'native_owner_gi',
    };
    expect(AuthService.docIsOwner(student), isFalse);
    expect(AuthService.roleFromDoc(student), AdminRole.none);
    expect(
      AuthService.roleFromDoc(student, email: 'road-english@naver.com'),
      AdminRole.none,
    );
  });

  test('명시적인 owner 와 강사, 메인 관리자 이메일만 권한이 있다', () {
    expect(
      AuthService.roleFromDoc({'role': 'owner', 'isActive': true}),
      AdminRole.owner,
    );
    expect(
      AuthService.roleFromDoc({'role': 'teacher', 'isActive': true}),
      AdminRole.teacher,
    );
    expect(
      AuthService.roleFromDoc(
        {'role': 'teacher', 'isActive': true},
        email: AuthService.ownerEmail,
      ),
      AdminRole.owner,
    );
    expect(
      AuthService.roleFromDoc({'role': 'teacher', 'isActive': false}),
      AdminRole.none,
    );
    expect(AuthService.docIsOwner({'role': 'owner'}), isTrue);
    expect(AuthService.docIsOwner({'role': 'teacher'}), isFalse);
  });
}
