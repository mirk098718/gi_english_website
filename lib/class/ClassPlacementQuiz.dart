import 'package:gi_english_website/class/OnlineCourse.dart';

/// 온라인 프로그램 클래스 배정 설문·실력 진단 문항.
class PlacementChoice {
  final int number;
  final String text;

  const PlacementChoice({required this.number, required this.text});

  String get circledLabel {
    const marks = ['①', '②', '③', '④', '⑤'];
    if (number >= 1 && number <= marks.length) return marks[number - 1];
    return '$number';
  }
}

class Part1Question {
  final String prompt;
  final List<PlacementChoice> choices;

  const Part1Question({required this.prompt, required this.choices});
}

class Part2Question {
  final String category;
  final String prompt;
  final List<PlacementChoice> choices;
  final int correctChoice;

  const Part2Question({
    required this.category,
    required this.prompt,
    required this.choices,
    required this.correctChoice,
  });
}

class PlacementResult {
  final OnlineCourse course;
  final bool skippedLevelTest;
  final int part1Choice1Count;
  final int? correctCount;
  final int? totalQuestions;

  const PlacementResult({
    required this.course,
    required this.skippedLevelTest,
    required this.part1Choice1Count,
    this.correctCount,
    this.totalQuestions,
  });

  String get explanation {
    if (skippedLevelTest) {
      return '설문에서 1번 항목(알파벳/파닉스 단계)을 $part1Choice1Count문항 선택하셔서, '
          '별도의 실력 테스트 없이 ${course.order}번 클래스로 배정되었습니다.';
    }
    return '실력 진단 테스트 ${totalQuestions ?? 0}문항 중 ${correctCount ?? 0}문항을 맞히셨습니다.';
  }
}

class ClassPlacementQuiz {
  ClassPlacementQuiz._();

  static const String part1Intro =
      '수강생의 현재 학습 목적과 주된 사용 영역을 구분하여 최적의 반을 선별하기 위한 문항입니다.';

  static const String skipNotice =
      '설문에서 1번 항목(알파벳/파닉스 단계)을 선택하신 수강생은 별도의 실력 테스트 없이 '
      '[1번: 성인 왕초보 영어] 클래스로 바로 배정됩니다.';

  static const List<Part1Question> part1Questions = [
    Part1Question(
      prompt: '영어를 배우려는 주요 목적은 무엇인가요?',
      choices: [
        PlacementChoice(
          number: 1,
          text: '알파벳 읽기, 발음 기초부터 차근차근 배우고 싶다.',
        ),
        PlacementChoice(
          number: 2,
          text: '일상생활이나 해외여행 시 간단한 소통을 원한다.',
        ),
        PlacementChoice(
          number: 3,
          text: '문법을 체계적으로 정리하여 다채로운 회화를 구사하고 싶다.',
        ),
        PlacementChoice(
          number: 4,
          text: '업무(이메일, 회의, 프레젠테이션 등)에서 직무 영어가 필요하다.',
        ),
        PlacementChoice(
          number: 5,
          text: '시사/토론 등 깊이 있는 주제로 유창하고 세련된 영어를 하고 싶다.',
        ),
      ],
    ),
    Part1Question(
      prompt: '현재 본인의 영어 실력에 대해 어떻게 느끼시나요?',
      choices: [
        PlacementChoice(
          number: 1,
          text: '알파벳이나 파닉스 기초 발음부터 자신이 없다.',
        ),
        PlacementChoice(
          number: 2,
          text: '아는 단어는 몇 개 있지만 문장으로 말하기가 어렵다.',
        ),
        PlacementChoice(
          number: 3,
          text: '기본적인 문장은 만들 수 있지만, 긴 문장이나 자연스러운 표현은 부족하다.',
        ),
        PlacementChoice(
          number: 4,
          text: '일반 회화는 가능하나 비즈니스 격식에 맞는 표현이 필요하다.',
        ),
        PlacementChoice(
          number: 5,
          text: '웬만한 대화는 가능하지만 뉘앙스 차이와 세련된 어휘 표현을 보완하고 싶다.',
        ),
      ],
    ),
    Part1Question(
      prompt: '영어로 말을 할 때 가장 크게 느끼는 어려움은 무엇인가요?',
      choices: [
        PlacementChoice(
          number: 1,
          text: '단어를 보고 어떻게 읽어야 할지 잘 모른다.',
        ),
        PlacementChoice(
          number: 2,
          text: '영문법 기초가 없어 단어를 어떤 순서로 배치해야 할지 모른다.',
        ),
        PlacementChoice(
          number: 3,
          text: '쓰거나 읽을 수는 있지만, 막상 입 밖으로 잘 나오지 않는다.',
        ),
        PlacementChoice(
          number: 4,
          text: '업무 관련 전문 표현이나 비즈니스 매너 표현을 모른다.',
        ),
        PlacementChoice(
          number: 5,
          text: '단순 의사전달은 되지만, 논리적이고 깊이 있는 표현이 안 된다.',
        ),
      ],
    ),
    Part1Question(
      prompt: '원어민과의 대화 경험 및 선호하는 수업 방식은 무엇인가요?',
      choices: [
        PlacementChoice(
          number: 1,
          text: '원어민 대화는 부담스러워 기초부터 편하게 시작하고 싶다.',
        ),
        PlacementChoice(
          number: 2,
          text: '아주 간단한 대화부터 차근차근 시도해보고 싶다.',
        ),
        PlacementChoice(
          number: 3,
          text: '기본적인 문법 수업과 함께 원어민 회화 실전 연습을 원한다.',
        ),
        PlacementChoice(
          number: 4,
          text: '실무와 연관된 상황별 회화 롤플레잉 위주의 수업을 원한다.',
        ),
        PlacementChoice(
          number: 5,
          text: '시사, 문화, 토론 등 심화 주제로 긴 대화를 나누는 수업을 원한다.',
        ),
      ],
    ),
    Part1Question(
      prompt: '가장 집중적으로 향상시키고 싶은 영역은 무엇인가요?',
      choices: [
        PlacementChoice(number: 1, text: '발음, 파닉스, 기초 단어'),
        PlacementChoice(number: 2, text: '기초 영문법, 일상 회화 표현'),
        PlacementChoice(number: 3, text: '중급 영문법, 풍부한 어휘 및 자연스러운 대화'),
        PlacementChoice(number: 4, text: '회의, 프레젠테이션, 비즈니스 이메일 작성'),
        PlacementChoice(number: 5, text: '논리적 토론, 고급 어휘, 섬세한 뉘앙스 차이'),
      ],
    ),
  ];

  static const List<Part2Question> part2Questions = [
    Part2Question(
      category: '기초 영문법',
      prompt: 'She ________ to the gym every morning.',
      choices: [
        PlacementChoice(number: 1, text: 'go'),
        PlacementChoice(number: 2, text: 'goes'),
        PlacementChoice(number: 3, text: 'going'),
        PlacementChoice(number: 4, text: 'gone'),
      ],
      correctChoice: 2,
    ),
    Part2Question(
      category: '기초 회화',
      prompt: '"오늘 저녁에 뭐 할 예정인가요?"',
      choices: [
        PlacementChoice(number: 1, text: 'What do you do tonight?'),
        PlacementChoice(number: 2, text: 'What are you doing tonight?'),
        PlacementChoice(number: 3, text: 'What did you do tonight?'),
        PlacementChoice(number: 4, text: 'What are you do tonight?'),
      ],
      correctChoice: 2,
    ),
    Part2Question(
      category: '기초 영문법',
      prompt: 'I have a meeting ________ 2 PM ________ Monday.',
      choices: [
        PlacementChoice(number: 1, text: 'at / on'),
        PlacementChoice(number: 2, text: 'in / at'),
        PlacementChoice(number: 3, text: 'on / in'),
        PlacementChoice(number: 4, text: 'at / in'),
      ],
      correctChoice: 1,
    ),
    Part2Question(
      category: '중급 영문법',
      prompt: 'I ________ in Seoul for five years before I moved to Paju.',
      choices: [
        PlacementChoice(number: 1, text: 'live'),
        PlacementChoice(number: 2, text: 'am living'),
        PlacementChoice(number: 3, text: 'had lived'),
        PlacementChoice(number: 4, text: 'have lived'),
      ],
      correctChoice: 3,
    ),
    Part2Question(
      category: '중급 회화',
      prompt: 'Take an umbrella ________ it rains.',
      choices: [
        PlacementChoice(number: 1, text: 'in case'),
        PlacementChoice(number: 2, text: 'although'),
        PlacementChoice(number: 3, text: 'unless'),
        PlacementChoice(number: 4, text: 'despite'),
      ],
      correctChoice: 1,
    ),
    Part2Question(
      category: '중급 영문법',
      prompt: 'The manager ________ is in charge of this project is away today.',
      choices: [
        PlacementChoice(number: 1, text: 'which'),
        PlacementChoice(number: 2, text: 'who'),
        PlacementChoice(number: 3, text: 'whom'),
        PlacementChoice(number: 4, text: 'whose'),
      ],
      correctChoice: 2,
    ),
    Part2Question(
      category: '비즈니스',
      prompt: '예의 바르게 동의하지 않을 때',
      choices: [
        PlacementChoice(number: 1, text: 'You are wrong about this.'),
        PlacementChoice(
          number: 2,
          text: 'I see your point, but I have a slightly different view.',
        ),
        PlacementChoice(number: 3, text: "I don't care about that idea."),
        PlacementChoice(number: 4, text: 'Shut up and listen to me.'),
      ],
      correctChoice: 2,
    ),
    Part2Question(
      category: '비즈니스',
      prompt: '첨부 파일 보고서',
      choices: [
        PlacementChoice(number: 1, text: 'Look at the attached report.'),
        PlacementChoice(number: 2, text: 'You can see the report I attached.'),
        PlacementChoice(
          number: 3,
          text: 'Please find the attached report for your review.',
        ),
        PlacementChoice(number: 4, text: 'Attachment is there for report.'),
      ],
      correctChoice: 3,
    ),
    Part2Question(
      category: '비즈니스',
      prompt: 'We need to ________ the deadline for this project.',
      choices: [
        PlacementChoice(number: 1, text: 'postpone'),
        PlacementChoice(number: 2, text: 'cancel'),
        PlacementChoice(number: 3, text: 'finish'),
        PlacementChoice(number: 4, text: 'accelerate'),
      ],
      correctChoice: 1,
    ),
    Part2Question(
      category: '비즈니스 회화',
      prompt: 'I will review the proposal and ________ to you soon.',
      choices: [
        PlacementChoice(number: 1, text: 'get back'),
        PlacementChoice(number: 2, text: 'call out'),
        PlacementChoice(number: 3, text: 'turn off'),
        PlacementChoice(number: 4, text: 'look down'),
      ],
      correctChoice: 1,
    ),
    Part2Question(
      category: '고급 회화',
      prompt: '그의 행동은 말보다 더 큰 설득력',
      choices: [
        PlacementChoice(number: 1, text: 'Words are better than actions.'),
        PlacementChoice(number: 2, text: 'Actions speak louder than words.'),
        PlacementChoice(number: 3, text: 'Talking is doing.'),
        PlacementChoice(number: 4, text: 'Big mouth makes big things.'),
      ],
      correctChoice: 2,
    ),
    Part2Question(
      category: '고급 뉘앙스',
      prompt: 'The negotiation requires a very ________ approach.',
      choices: [
        PlacementChoice(number: 1, text: 'delicate'),
        PlacementChoice(number: 2, text: 'easy'),
        PlacementChoice(number: 3, text: 'simple'),
        PlacementChoice(number: 4, text: 'rough'),
      ],
      correctChoice: 1,
    ),
    Part2Question(
      category: '고급/시사',
      prompt: '"유연하고 적응력이 뛰어난"',
      choices: [
        PlacementChoice(number: 1, text: 'rigid'),
        PlacementChoice(number: 2, text: 'versatile'),
        PlacementChoice(number: 3, text: 'stubborn'),
        PlacementChoice(number: 4, text: 'obsolete'),
      ],
      correctChoice: 2,
    ),
    Part2Question(
      category: '고급 가정법',
      prompt: 'If I ________ about the risks, I would have made a different decision.',
      choices: [
        PlacementChoice(number: 1, text: 'know'),
        PlacementChoice(number: 2, text: 'knew'),
        PlacementChoice(number: 3, text: 'have known'),
        PlacementChoice(number: 4, text: 'had known'),
      ],
      correctChoice: 4,
    ),
    Part2Question(
      category: '고급 표현',
      prompt: 'Due to ________ circumstances, we need to reschedule the meeting.',
      choices: [
        PlacementChoice(number: 1, text: 'unforeseen'),
        PlacementChoice(number: 2, text: 'familiar'),
        PlacementChoice(number: 3, text: 'intended'),
        PlacementChoice(number: 4, text: 'intentional'),
      ],
      correctChoice: 1,
    ),
  ];

  /// Part 1에서 ①을 3문항 이상 고르면 실력 진단을 생략한다.
  static bool shouldSkipPart2(List<int> part1Answers) {
    final ones = part1Answers.where((answer) => answer == 1).length;
    return ones >= 3;
  }

  static int scorePart2(List<int> answers) {
    var correct = 0;
    final limit = answers.length < part2Questions.length
        ? answers.length
        : part2Questions.length;
    for (var i = 0; i < limit; i++) {
      if (answers[i] == part2Questions[i].correctChoice) {
        correct++;
      }
    }
    return correct;
  }

  /// 0~3 기초, 4~7 중급, 8~11 비즈니스, 12+ 고급.
  static OnlineCourse courseForPart2Score(int correct) {
    if (correct <= 3) return OnlineCourse.all[1];
    if (correct <= 7) return OnlineCourse.all[2];
    if (correct <= 11) return OnlineCourse.all[3];
    return OnlineCourse.all[4];
  }

  static PlacementResult evaluate({
    required List<int> part1Answers,
    List<int>? part2Answers,
  }) {
    final choice1Count = part1Answers.where((answer) => answer == 1).length;
    if (shouldSkipPart2(part1Answers)) {
      return PlacementResult(
        course: OnlineCourse.all[0],
        skippedLevelTest: true,
        part1Choice1Count: choice1Count,
      );
    }
    final correct = scorePart2(part2Answers ?? const []);
    return PlacementResult(
      course: courseForPart2Score(correct),
      skippedLevelTest: false,
      part1Choice1Count: choice1Count,
      correctCount: correct,
      totalQuestions: part2Questions.length,
    );
  }
}
