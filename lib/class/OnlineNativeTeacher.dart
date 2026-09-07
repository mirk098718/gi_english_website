/// 온라인 화상수업용 원어민 강사 (임시 더미 데이터).
/// 실제 강사 계정(admins)과 별도로, 수강생이 고르는 '메인 원어민' 프로필이다.
class OnlineNativeTeacher {
  final String id;
  final String name;
  final String nationality;
  final String intro;
  final String imageAsset;

  const OnlineNativeTeacher({
    required this.id,
    required this.name,
    required this.nationality,
    required this.intro,
    required this.imageAsset,
  });

  static const List<OnlineNativeTeacher> all = [
    OnlineNativeTeacher(
      id: 'native_temp_emma',
      name: 'Emma',
      nationality: 'USA',
      intro: '밝은 톤으로 기초·중급 회화를 이끌어 주는 선생님입니다.',
      imageAsset: 'assets/nativeTeacher01.png',
    ),
    OnlineNativeTeacher(
      id: 'native_temp_james',
      name: 'James',
      nationality: 'Canada',
      intro: '문법 설명과 실전 대화를 균형 있게 진행합니다.',
      imageAsset: 'assets/nativeTeacher02.png',
    ),
    OnlineNativeTeacher(
      id: 'native_temp_sophie',
      name: 'Sophie',
      nationality: 'UK',
      intro: '비즈니스·격식 표현을 차분하게 코칭합니다.',
      imageAsset: 'assets/nativeTeacher03.png',
    ),
    OnlineNativeTeacher(
      id: 'native_temp_daniel',
      name: 'Daniel',
      nationality: 'USA',
      intro: '시사·토론 주제로 자연스러운 고급 회화를 연습합니다.',
      imageAsset: 'assets/nativeTeacher04.png',
    ),
  ];

  static OnlineNativeTeacher? findById(String id) {
    for (final t in all) {
      if (t.id == id) return t;
    }
    return null;
  }
}
