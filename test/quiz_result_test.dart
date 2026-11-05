import 'package:flutter_test/flutter_test.dart';
import 'package:gi_english_website/class/QuizResult.dart';
import 'package:gi_english_website/util/EnrollmentService.dart';

void main() {
  test('퀴즈 주소에서 저장 키를 만든다', () {
    expect(
      QuizResult.quizIdFromUrl('/quizzes/gleam-level1-lesson1-quiz.html'),
      'gleam-level1-lesson1',
    );
    expect(
      QuizResult.quizIdFromUrl(
        'https://gleam-island.web.app/quizzes/gleam-level3-lesson2-quiz.html?x=1',
      ),
      'gleam-level3-lesson2',
    );
    expect(QuizResult.quizIdFromUrl('https://youtu.be/UMTr9cXimZM'), '');
    expect(
      QuizResult.documentId('student1', 'gleam-level1-lesson1'),
      'student1_gleam-level1-lesson1',
    );
  });

  test('다시 풀면 더 최근 점수와 주관식만 남긴다', () {
    final earlier = QuizResult(
      id: 'student1_gleam-level1-lesson1',
      userId: 'student1',
      quizId: 'gleam-level1-lesson1',
      title: '왕초보 1강',
      courseId: 'beginner_phonics',
      weekNumber: 1,
      correctCount: 20,
      totalCount: 25,
      essays: const [
        QuizEssayAnswer(
          index: 1,
          title: '기본 표현 쓰기',
          prompt: '나는 커피를 좋아해요.',
          answer: 'I like tea.',
        ),
      ],
      updatedAt: DateTime.utc(2026, 11, 1, 1),
    );
    final later = QuizResult(
      id: earlier.id,
      userId: earlier.userId,
      quizId: earlier.quizId,
      title: earlier.title,
      courseId: earlier.courseId,
      weekNumber: 1,
      correctCount: 14,
      totalCount: 25,
      essays: const [
        QuizEssayAnswer(
          index: 1,
          title: '기본 표현 쓰기',
          prompt: '나는 커피를 좋아해요.',
          answer: 'I like coffee.',
        ),
      ],
      updatedAt: DateTime.utc(2026, 11, 5, 2),
    );

    final kept = QuizResult.keepLatest([earlier, later]);

    expect(kept.length, 1);
    expect(kept[earlier.quizId]!.correctCount, 14);
    expect(kept[earlier.quizId]!.scoreLabel, '14 / 25문제 · 14점');
    expect(kept[earlier.quizId]!.essays.single.answer, 'I like coffee.');
  });

  test('연결된 연습문제 주소는 모두 퀴즈 키가 된다', () {
    final urls = [
      ...EnrollmentService.beginnerLessons.map((lesson) => lesson.problemUrl),
      ...EnrollmentService.intermediateLessons
          .map((lesson) => lesson.problemUrl),
    ];

    expect(urls, hasLength(6));
    expect(
      urls.map(QuizResult.quizIdFromUrl).toSet(),
      {
        'gleam-level1-lesson1',
        'gleam-level2-lesson02',
        'gleam-level1-lesson3',
        'gleam-level1-lesson4',
        'gleam-level3-lesson1',
        'gleam-level3-lesson2',
      },
    );
  });
}
