import 'package:gi_english_website/util/AppLanguage.dart';

/// 온라인 상품 구성.
///
/// - [lecture]: 단계별 영문법 인강 + 퀴즈. 화상수업 없음.
/// - [bundle]: 인강 + 퀴즈 + 원어민 화상. 지금 판매 중인 구성.
/// - [speaking]: 원어민 화상 1:1 회화만. 인강·퀴즈 없음.
///
/// 예전에 결제한 수강은 plan 필드가 없다. 그때는 [bundle]로 본다.
class OnlinePlan {
  static const lecture = 'lecture';
  static const bundle = 'bundle';
  static const speaking = 'speaking';

  /// 원어민 화상만 들을 때 1회 금액. 안내 금액.
  static const speakingSessionPrice = 15000;

  /// 화상만 상품에서 고를 수 있는 횟수. 8회는 기존 묶음과 같다.
  static const speakingSessionChoices = [4, 8, 12];

  /// 레벨마다 약속하는 인강 편수.
  static const lessonsPerLevel = 25;

  /// 인강만 상품의 수강 기한. 25편을 주 1편보다 조금 여유 있게 듣는 기간.
  static const lectureAccessWeeks = 24;

  static const speakingCourseId = 'native_speaking';

  /// 상품 카드와 프로그램 이름 앞에 쓰는 제목.
  static String label(String plan) {
    if (plan == lecture) return '단계별 영문법 인강';
    if (plan == speaking) return '원어민 화상 1:1 회화';
    return '영문법 인강 + 원어민 화상 회화';
  }

  static String normalize(String? raw) {
    if (raw == lecture || raw == speaking) return raw!;
    return bundle;
  }

  /// 저장된 값이 비어 있고 과정이 화상 전용이면 화상만으로 본다.
  static String resolve({String? stored, String? courseId}) {
    if (courseId == speakingCourseId) return speaking;
    return normalize(stored);
  }

  static bool includesLessons(String? raw) => normalize(raw) != speaking;

  static bool includesSpeaking(String? raw) => normalize(raw) != lecture;

  static String grouped(int amount) {
    final s = amount.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  static String won(int amount) => '${grouped(amount)}원';

  /// 화면 언어에 맞춘 금액. 한국어는 15,000원, 영어는 ₩15,000.
  static String money(int amount) =>
      AppLanguage.instance.fill('{p0}원', {'p0': grouped(amount)});
}
