class TalkSafetyHit {
  final String kind;
  final String userMessage;

  const TalkSafetyHit({
    required this.kind,
    required this.userMessage,
  });
}

/// Let's Talk 텍스트 안전 필터. 화상 음성은 Jitsi 탭에 있어서 들을 수 없고,
/// 사이트 안 메시지·신고는 여기서 막거나 운영자에게 넘긴다.
class TalkSafety {
  static const warningMessage =
      '이 내용에는 Cafe에서 쓸 수 없는 욕설이나 성적 표현이 있어요. '
      '전송을 막았고, 운영자에게 알려 두었습니다.';

  static const List<String> abuseTerms = [
    '시발',
    '씨발',
    'ㅅㅂ',
    '병신',
    '지랄',
    '꺼져',
    'fuck',
    'fucking',
    'bitch',
    'asshole',
    'shit',
  ];

  static const List<String> sexualTerms = [
    '섹스',
    '야동',
    '포르노',
    '성관계',
    '자지',
    '보지',
    'porn',
    'pussy',
    'dick',
    'nude',
    'nudes',
    'horny',
    'blowjob',
    'onlyfans',
  ];

  static String normalize(String raw) {
    return raw.toLowerCase().replaceAll(RegExp(r'[\s\-_*.,!?"\x27]+'), '');
  }

  static TalkSafetyHit? scan(String raw) {
    final compact = normalize(raw);
    if (compact.isEmpty) return null;
    for (final term in sexualTerms) {
      if (compact.contains(normalize(term))) {
        return const TalkSafetyHit(
          kind: 'sexual',
          userMessage: warningMessage,
        );
      }
    }
    for (final term in abuseTerms) {
      if (compact.contains(normalize(term))) {
        return const TalkSafetyHit(
          kind: 'abuse',
          userMessage: warningMessage,
        );
      }
    }
    return null;
  }
}
