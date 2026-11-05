/// 홈에 하루에 하나씩 보여주는 단어와 그 단어를 쓴 표현.
class DailyWord {
  final String word;
  final String meaning;
  final String expression;
  final String expressionMeaning;

  const DailyWord({
    required this.word,
    required this.meaning,
    required this.expression,
    required this.expressionMeaning,
  });

  /// 같은 날짜에는 같은 단어, 다음 날에는 다음 단어.
  static DailyWord forDate(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final diff = day.difference(DateTime(2026, 1, 1)).inDays;
    final length = words.length;
    final index = ((diff % length) + length) % length;
    return words[index];
  }

  static const List<DailyWord> words = [
    DailyWord(
      word: 'ready',
      meaning: '준비된',
      expression: "I'm ready for class.",
      expressionMeaning: '수업 준비됐어요.',
    ),
    DailyWord(
      word: 'practice',
      meaning: '연습하다',
      expression: 'I practice English every day.',
      expressionMeaning: '저는 매일 영어를 연습해요.',
    ),
    DailyWord(
      word: 'together',
      meaning: '함께',
      expression: "Let's study together.",
      expressionMeaning: '같이 공부해요.',
    ),
    DailyWord(
      word: 'please',
      meaning: '부탁해요',
      expression: 'Could you help me, please?',
      expressionMeaning: '도와주시겠어요?',
    ),
    DailyWord(
      word: 'today',
      meaning: '오늘',
      expression: 'Today is a good day to speak English.',
      expressionMeaning: '오늘은 영어 말하기에 좋은 날이에요.',
    ),
    DailyWord(
      word: 'try',
      meaning: '시도하다',
      expression: "I'll try one more time.",
      expressionMeaning: '한 번 더 해볼게요.',
    ),
    DailyWord(
      word: 'share',
      meaning: '나누다',
      expression: 'Can I share my idea?',
      expressionMeaning: '제 생각을 말해도 될까요?',
    ),
    DailyWord(
      word: 'listen',
      meaning: '듣다',
      expression: 'Please listen carefully.',
      expressionMeaning: '잘 들어 주세요.',
    ),
    DailyWord(
      word: 'ask',
      meaning: '묻다',
      expression: "Don't be afraid to ask.",
      expressionMeaning: '묻는 걸 두려워하지 마세요.',
    ),
    DailyWord(
      word: 'smile',
      meaning: '미소',
      expression: 'A smile opens the conversation.',
      expressionMeaning: '미소가 대화를 열어요.',
    ),
    DailyWord(
      word: 'brave',
      meaning: '용감한',
      expression: 'Be brave and say it out loud.',
      expressionMeaning: '용기 내서 소리 내어 말해 보세요.',
    ),
    DailyWord(
      word: 'kind',
      meaning: '다정한',
      expression: 'Kind words make people feel safe.',
      expressionMeaning: '다정한 말은 사람을 편하게 해요.',
    ),
    DailyWord(
      word: 'wait',
      meaning: '기다리다',
      expression: 'Please wait a moment.',
      expressionMeaning: '잠시만 기다려 주세요.',
    ),
    DailyWord(
      word: 'start',
      meaning: '시작하다',
      expression: "Let's start with a greeting.",
      expressionMeaning: '인사부터 시작해요.',
    ),
    DailyWord(
      word: 'finish',
      meaning: '끝내다',
      expression: 'I finished my homework.',
      expressionMeaning: '숙제를 끝냈어요.',
    ),
    DailyWord(
      word: 'help',
      meaning: '돕다',
      expression: 'Can you help me with this word?',
      expressionMeaning: '이 단어 좀 도와주실래요?',
    ),
    DailyWord(
      word: 'choose',
      meaning: '고르다',
      expression: 'I choose the blue one.',
      expressionMeaning: '파란색으로 고를게요.',
    ),
    DailyWord(
      word: 'remember',
      meaning: '기억하다',
      expression: 'I remember your name.',
      expressionMeaning: '이름을 기억해요.',
    ),
    DailyWord(
      word: 'forget',
      meaning: '잊다',
      expression: 'I sometimes forget new words.',
      expressionMeaning: '새 단어를 가끔 잊어요.',
    ),
    DailyWord(
      word: 'repeat',
      meaning: '다시 말하다',
      expression: 'Could you repeat that, please?',
      expressionMeaning: '다시 한 번 말해 주실래요?',
    ),
    DailyWord(
      word: 'slowly',
      meaning: '천천히',
      expression: 'Please speak slowly.',
      expressionMeaning: '천천히 말해 주세요.',
    ),
    DailyWord(
      word: 'clearly',
      meaning: '또렷하게',
      expression: 'Say it clearly.',
      expressionMeaning: '또렷하게 말해 보세요.',
    ),
    DailyWord(
      word: 'early',
      meaning: '일찍',
      expression: 'I arrived early today.',
      expressionMeaning: '오늘은 일찍 도착했어요.',
    ),
    DailyWord(
      word: 'late',
      meaning: '늦은',
      expression: "Sorry, I'm a little late.",
      expressionMeaning: '죄송해요, 조금 늦었어요.',
    ),
    DailyWord(
      word: 'hungry',
      meaning: '배고픈',
      expression: "I'm hungry after class.",
      expressionMeaning: '수업 끝나고 배고파요.',
    ),
    DailyWord(
      word: 'tired',
      meaning: '피곤한',
      expression: "I'm tired, but I'll finish this.",
      expressionMeaning: '피곤하지만 이건 끝낼게요.',
    ),
    DailyWord(
      word: 'happy',
      meaning: '기쁜',
      expression: "I'm happy to see you.",
      expressionMeaning: '만나서 기뻐요.',
    ),
    DailyWord(
      word: 'nervous',
      meaning: '긴장한',
      expression: 'I feel nervous before speaking.',
      expressionMeaning: '말하기 전에 긴장돼요.',
    ),
    DailyWord(
      word: 'proud',
      meaning: '뿌듯한',
      expression: "I'm proud of my progress.",
      expressionMeaning: '제 발전이 뿌듯해요.',
    ),
    DailyWord(
      word: 'curious',
      meaning: '궁금한',
      expression: "I'm curious about this word.",
      expressionMeaning: '이 단어가 궁금해요.',
    ),
    DailyWord(
      word: 'quiet',
      meaning: '조용한',
      expression: 'The room is quiet.',
      expressionMeaning: '방이 조용해요.',
    ),
    DailyWord(
      word: 'careful',
      meaning: '조심하는',
      expression: 'Be careful with the spelling.',
      expressionMeaning: '철자를 조심하세요.',
    ),
    DailyWord(
      word: 'favorite',
      meaning: '가장 좋아하는',
      expression: 'This is my favorite phrase.',
      expressionMeaning: '이 표현을 가장 좋아해요.',
    ),
    DailyWord(
      word: 'weekend',
      meaning: '주말',
      expression: 'I review a little on the weekend.',
      expressionMeaning: '주말에 조금 복습해요.',
    ),
    DailyWord(
      word: 'morning',
      meaning: '아침',
      expression: 'Good morning, everyone.',
      expressionMeaning: '모두 좋은 아침이에요.',
    ),
    DailyWord(
      word: 'tomorrow',
      meaning: '내일',
      expression: "I'll review this tomorrow.",
      expressionMeaning: '내일 이걸 복습할게요.',
    ),
    DailyWord(
      word: 'yesterday',
      meaning: '어제',
      expression: 'Yesterday I learned a new phrase.',
      expressionMeaning: '어제 새 표현을 배웠어요.',
    ),
    DailyWord(
      word: 'friend',
      meaning: '친구',
      expression: 'She is my study friend.',
      expressionMeaning: '그 친구는 같이 공부하는 친구예요.',
    ),
    DailyWord(
      word: 'welcome',
      meaning: '환영하는',
      expression: 'Welcome to class.',
      expressionMeaning: '수업에 온 걸 환영해요.',
    ),
    DailyWord(
      word: 'enough',
      meaning: '충분한',
      expression: "That's enough for today.",
      expressionMeaning: '오늘은 이만큼이면 충분해요.',
    ),
  ];
}
