import 'package:flutter_test/flutter_test.dart';
import 'package:gi_english_website/class/ClassPlacementQuiz.dart';

void main() {
  test('Part 1 majority ① skips Part 2 and assigns 왕초보', () {
    expect(ClassPlacementQuiz.shouldSkipPart2([1, 1, 1, 2, 3]), isTrue);
    expect(ClassPlacementQuiz.shouldSkipPart2([1, 1, 2, 2, 3]), isFalse);

    final skipped = ClassPlacementQuiz.evaluate(part1Answers: [1, 1, 1, 4, 5]);
    expect(skipped.skippedLevelTest, isTrue);
    expect(skipped.course.id, 'beginner_phonics');
    expect(skipped.course.order, 1);
  });

  test('Part 2 score bands keep random guessing in 기초', () {
    final answers = List<int>.filled(15, 0);
    expect(ClassPlacementQuiz.scorePart2(answers), 0);

    expect(ClassPlacementQuiz.courseForPart2Score(0).id, 'basic_grammar_speaking');
    expect(ClassPlacementQuiz.courseForPart2Score(5).id, 'basic_grammar_speaking');
    expect(ClassPlacementQuiz.courseForPart2Score(6).id, 'intermediate_grammar_speaking');
    expect(ClassPlacementQuiz.courseForPart2Score(9).id, 'intermediate_grammar_speaking');
    expect(ClassPlacementQuiz.courseForPart2Score(10).id, 'business_english');
    expect(ClassPlacementQuiz.courseForPart2Score(12).id, 'business_english');
    expect(ClassPlacementQuiz.courseForPart2Score(13).id, 'advanced_premium_speaking');
    expect(ClassPlacementQuiz.courseForPart2Score(15).id, 'advanced_premium_speaking');
  });

  test('Part 2 correct answers are spread across 1-4', () {
    final counts = <int, int>{1: 0, 2: 0, 3: 0, 4: 0};
    for (final q in ClassPlacementQuiz.part2Questions) {
      counts[q.correctChoice] = (counts[q.correctChoice] ?? 0) + 1;
    }
    expect(counts[1], 4);
    expect(counts[2], 4);
    expect(counts[3], 4);
    expect(counts[4], 3);
  });

  test('Part 2 correct answers score 15', () {
    final answers = ClassPlacementQuiz.part2Questions
        .map((q) => q.correctChoice)
        .toList();
    expect(ClassPlacementQuiz.scorePart2(answers), 15);
  });
}
