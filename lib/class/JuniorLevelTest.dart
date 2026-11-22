import 'package:gi_english_website/class/JuniorLevel.dart';

class JuniorLevelQuestion {
  final String prompt;
  final List<String> choices;
  final int correctIndex;

  const JuniorLevelQuestion({
    required this.prompt,
    required this.choices,
    required this.correctIndex,
  });
}

/// 초등부·중등부 주니어 레벨테스트. 맞은 개수로 레벨 1~6을 나눈다.
class JuniorLevelTest {
  JuniorLevelTest._();

  static const List<JuniorLevelQuestion> elementary = [
    JuniorLevelQuestion(
      prompt: 'Which letter comes right after A?',
      choices: ['B', 'C', 'D', 'Z'],
      correctIndex: 0,
    ),
    JuniorLevelQuestion(
      prompt: 'Which word is a color?',
      choices: ['run', 'blue', 'book', 'jump'],
      correctIndex: 1,
    ),
    JuniorLevelQuestion(
      prompt: 'I ___ a student.',
      choices: ['am', 'is', 'are', 'be'],
      correctIndex: 0,
    ),
    JuniorLevelQuestion(
      prompt: 'This is ___ apple.',
      choices: ['a', 'an', 'two', 'much'],
      correctIndex: 1,
    ),
    JuniorLevelQuestion(
      prompt: 'She ___ to school every day.',
      choices: ['go', 'goes', 'going', 'went'],
      correctIndex: 1,
    ),
    JuniorLevelQuestion(
      prompt: 'Where ___ you live?',
      choices: ['do', 'does', 'is', 'are'],
      correctIndex: 0,
    ),
    JuniorLevelQuestion(
      prompt: 'I ___ a movie yesterday.',
      choices: ['watch', 'watched', 'watching', 'watches'],
      correctIndex: 1,
    ),
    JuniorLevelQuestion(
      prompt: 'Tom is ___ than Ann.',
      choices: ['tall', 'taller', 'tallest', 'most tall'],
      correctIndex: 1,
    ),
    JuniorLevelQuestion(
      prompt: 'If it rains, we ___ at home.',
      choices: ['stay', 'stayed', 'staying', 'stays'],
      correctIndex: 0,
    ),
    JuniorLevelQuestion(
      prompt: 'The story ___ by our teacher was funny.',
      choices: ['telling', 'told', 'tells', 'tell'],
      correctIndex: 1,
    ),
    JuniorLevelQuestion(
      prompt: 'She has lived here ___ 2019.',
      choices: ['for', 'since', 'during', 'from'],
      correctIndex: 1,
    ),
    JuniorLevelQuestion(
      prompt: 'Mina forgot her umbrella, so she got wet. Why did she get wet?',
      choices: [
        'She bought a new umbrella.',
        'It was sunny all day.',
        'She forgot her umbrella.',
        'She stayed inside.',
      ],
      correctIndex: 2,
    ),
  ];

  static const List<JuniorLevelQuestion> middle = [
    JuniorLevelQuestion(
      prompt: 'Which greeting fits a friend?',
      choices: [
        'To whom it may concern,',
        'Hi, how are you?',
        'Dear Sir or Madam,',
        'Yours faithfully,',
      ],
      correctIndex: 1,
    ),
    JuniorLevelQuestion(
      prompt: 'There ___ many books on the desk.',
      choices: ['is', 'are', 'be', 'was'],
      correctIndex: 1,
    ),
    JuniorLevelQuestion(
      prompt: 'I have never ___ sushi.',
      choices: ['eat', 'ate', 'eaten', 'eating'],
      correctIndex: 2,
    ),
    JuniorLevelQuestion(
      prompt: 'The movie was ___ than I expected.',
      choices: ['more interesting', 'interestinger', 'most interesting', 'interesting'],
      correctIndex: 0,
    ),
    JuniorLevelQuestion(
      prompt: 'Could you tell me ___ the station is?',
      choices: ['where', 'what', 'which', 'who'],
      correctIndex: 0,
    ),
    JuniorLevelQuestion(
      prompt: 'If I ___ you, I would talk to the teacher.',
      choices: ['am', 'was', 'were', 'be'],
      correctIndex: 2,
    ),
    JuniorLevelQuestion(
      prompt: 'The homework ___ yesterday.',
      choices: ['must finish', 'must be finished', 'must finished', 'must finishing'],
      correctIndex: 1,
    ),
    JuniorLevelQuestion(
      prompt: 'Not only Mina but also her friends ___ coming.',
      choices: ['is', 'are', 'was', 'be'],
      correctIndex: 1,
    ),
    JuniorLevelQuestion(
      prompt: 'He suggested ___ earlier.',
      choices: ['to leave', 'leaving', 'leave', 'left'],
      correctIndex: 1,
    ),
    JuniorLevelQuestion(
      prompt: 'The reason ___ she was late was the bus.',
      choices: ['which', 'why', 'what', 'whose'],
      correctIndex: 1,
    ),
    JuniorLevelQuestion(
      prompt: 'Although the test was difficult, Joon finished it and smiled. Joon ___.',
      choices: [
        'gave up before the test',
        'did not take the test',
        'finished it even though it was difficult',
        'thought the test was easy',
      ],
      correctIndex: 2,
    ),
    JuniorLevelQuestion(
      prompt: 'Scarcely ___ the bell rung when the students stood up.',
      choices: ['has', 'had', 'have', 'having'],
      correctIndex: 1,
    ),
  ];

  static List<JuniorLevelQuestion> questionsFor(String band) =>
      band == JuniorLevel.middle ? middle : elementary;

  /// 0~1점 레벨 1, 이후 2점마다 한 단계, 10점 이상은 레벨 6.
  static int levelForScore(int correct) {
    if (correct <= 1) return 1;
    if (correct <= 3) return 2;
    if (correct <= 5) return 3;
    if (correct <= 7) return 4;
    if (correct <= 9) return 5;
    return 6;
  }

  static int score(String band, List<int?> answers) {
    final questions = questionsFor(band);
    var correct = 0;
    for (var i = 0; i < questions.length; i++) {
      if (i < answers.length && answers[i] == questions[i].correctIndex) {
        correct += 1;
      }
    }
    return correct;
  }

  static JuniorLevel result(String band, List<int?> answers) {
    return JuniorLevel(
      band: band == JuniorLevel.middle ? JuniorLevel.middle : JuniorLevel.elementary,
      level: levelForScore(score(band, answers)),
    );
  }
}
