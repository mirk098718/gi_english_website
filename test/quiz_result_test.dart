import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gi_english_website/class/QuizResult.dart';
import 'package:gi_english_website/util/EnrollmentService.dart';
import 'package:gi_english_website/widget/QuizResultSummary.dart';

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
    expect(kept[earlier.quizId]!.percent, 56);
    expect(QuizResult.percentFor(18, 25), 72);
    expect(kept[earlier.quizId]!.scoreLabel, '14 / 25문제 · 56%');
    expect(kept[earlier.quizId]!.essays.single.answer, 'I like coffee.');
  });

  test('연결된 연습문제 주소는 모두 퀴즈 키가 된다', () {
    final urls = [
      ...EnrollmentService.beginnerLessons.map((lesson) => lesson.problemUrl),
      ...EnrollmentService.basicLessons.map((lesson) => lesson.problemUrl),
      ...EnrollmentService.intermediateLessons
          .map((lesson) => lesson.problemUrl),
      ...EnrollmentService.advancedLessons.map((lesson) => lesson.problemUrl),
      ...EnrollmentService.businessLessons.map((lesson) => lesson.problemUrl),
    ];

    expect(urls, hasLength(50));
    expect(
      urls.map(QuizResult.quizIdFromUrl).toSet(),
      {
        'gleam-level1-lesson1',
        'gleam-level2-lesson02',
        'gleam-level2-lesson1',
        'gleam-level2-lesson2',
        'gleam-level2-lesson3',
        'gleam-level2-lesson4',
        'gleam-level2-lesson5',
        'gleam-level2-lesson6',
        'gleam-level2-lesson7',
        'gleam-level2-lesson8',
        'gleam-level2-lesson9',
        'gleam-level2-lesson10',
        'gleam-level1-lesson3',
        'gleam-level1-lesson4',
        'gleam-level1-lesson5',
        'gleam-level1-lesson6',
        'gleam-level1-lesson7',
        'gleam-level1-lesson8',
        'gleam-level1-lesson9',
        'gleam-level1-lesson10',
        'gleam-level3-lesson1',
        'gleam-level3-lesson2',
        'gleam-level3-lesson3',
        'gleam-level3-lesson4',
        'gleam-level3-lesson5',
        'gleam-level3-lesson6',
        'gleam-level3-lesson7',
        'gleam-level3-lesson8',
        'gleam-level3-lesson9',
        'gleam-level3-lesson10',
        'gleam-level5-lesson1',
        'gleam-level5-lesson2',
        'gleam-level5-lesson3',
        'gleam-level5-lesson4',
        'gleam-level5-lesson5',
        'gleam-level5-lesson6',
        'gleam-level5-lesson7',
        'gleam-level5-lesson8',
        'gleam-level5-lesson9',
        'gleam-level5-lesson10',
        'gleam-level4-lesson1',
        'gleam-level4-lesson2',
        'gleam-level4-lesson3',
        'gleam-level4-lesson4',
        'gleam-level4-lesson5',
        'gleam-level4-lesson6',
        'gleam-level4-lesson7',
        'gleam-level4-lesson8',
        'gleam-level4-lesson9',
        'gleam-level4-lesson10',
      },
    );
  });

  test('완료로 넘긴 점수와 주관식만 강의실 저장 요청이 된다', () {
    final saved = QuizSaveRequest.tryParse({
      'quizId': 'gleam-level1-lesson5',
      'title': '왕초보 5강 연습문제',
      'courseId': 'beginner_phonics',
      'weekNumber': 5,
      'correctCount': 18,
      'totalCount': 25,
      'completed': true,
      'essays': [
        {
          'index': 1,
          'title': '상황 작문 1',
          'prompt': '문을 닫아 달라고 해 보세요.',
          'answer': 'Could you close the door?',
        },
      ],
    });

    expect(saved, isNotNull);
    expect(saved!.correctCount, 18);
    expect(saved.weekNumber, 5);
    expect(saved.essays.single.answer, 'Could you close the door?');
    expect(
      QuizSaveRequest.tryParse({
        'quizId': 'gleam-level1-lesson5',
        'courseId': 'beginner_phonics',
        'weekNumber': 5,
        'correctCount': 18,
        'totalCount': 24,
        'completed': true,
        'essays': [],
      }),
      isNull,
    );
  });

  testWidgets('주관식 답은 접혀 있다가 열면 보인다', (tester) async {
    final result = QuizResult(
      id: 'student1_gleam-level1-lesson1',
      userId: 'student1',
      quizId: 'gleam-level1-lesson1',
      title: '왕초보 1강 연습문제',
      courseId: 'beginner_phonics',
      weekNumber: 1,
      correctCount: 11,
      totalCount: 25,
      essays: const [
        QuizEssayAnswer(
          index: 1,
          title: '기본 표현 쓰기',
          prompt: '나는 커피를 좋아해요.',
          answer: 'I like coffee',
        ),
      ],
      updatedAt: DateTime(2026, 11, 10, 13, 53),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 420,
              child: QuizResultSummary(result: result),
            ),
          ),
        ),
      ),
    );

    expect(find.text('왕초보 1강 연습문제 · 11 / 25문제 · 44%'), findsOneWidget);
    expect(find.text('주관식 답 보기'), findsOneWidget);
    expect(find.text('I like coffee'), findsNothing);
    expect(find.text('나는 커피를 좋아해요.'), findsNothing);

    await tester.tap(find.text('주관식 답 보기'));
    await tester.pumpAndSettle();

    expect(find.text('I like coffee'), findsOneWidget);
    expect(find.text('나는 커피를 좋아해요.'), findsOneWidget);
    expect(find.text('기본 표현 쓰기'), findsOneWidget);
  });
}
