import 'package:flutter_test/flutter_test.dart';
import 'package:gi_english_website/util/EnrollmentService.dart';

void main() {
  test('왕초보 1강부터 3강 인강 주소를 회차에 연결한다', () {
    final first = EnrollmentService.defaultWeek('beginner_phonics', 1);
    final second = EnrollmentService.defaultWeek('beginner_phonics', 2);
    final third = EnrollmentService.defaultWeek('beginner_phonics', 3);

    expect(first.title, '1강');
    expect(first.videoUrl, 'https://youtu.be/UMTr9cXimZM');
    expect(first.problemLinks.single.title, '1강 연습문제');
    expect(
      first.problemLinks.single.url,
      '/quizzes/gleam-level1-lesson1-quiz.html',
    );
    expect(second.problemLinks.single.title, '2강 연습문제');
    expect(
      second.problemLinks.single.url,
      '/quizzes/gleam-level2-lesson02-quiz.html',
    );
    expect(second.videoUrl, 'https://youtu.be/ikDXCNb66Yo');
    expect(third.videoUrl, 'https://youtu.be/mHrkwI56dVw');
    expect(third.problemLinks.single.title, '3강 연습문제');
    expect(
      third.problemLinks.single.url,
      '/quizzes/gleam-level1-lesson3-quiz.html',
    );
  });

  test('저장된 왕초보 회차에 임시 영상만 있으면 실제 인강으로 바꾼다', () {
    final stored = OnlineWeek(
      id: 'beginner_phonics_week_2',
      courseId: 'beginner_phonics',
      weekNumber: 2,
      title: '2회차 학습',
      description: '',
      videoUrl: '',
    );

    final filled = EnrollmentService.withCatalogVideo(stored);

    expect(filled.title, '2강');
    expect(filled.videoUrl, 'https://youtu.be/ikDXCNb66Yo');
  });

  test('이미 연결된 1강에도 연습문제 주소가 없으면 퀴즈를 붙인다', () {
    final stored = OnlineWeek(
      id: 'beginner_phonics_week_1',
      courseId: 'beginner_phonics',
      weekNumber: 1,
      title: '1강',
      description: '왕초보 1강',
      videoUrl: 'https://youtu.be/UMTr9cXimZM',
    );

    final filled = EnrollmentService.withCatalogVideo(stored);

    expect(filled.videoUrl, 'https://youtu.be/UMTr9cXimZM');
    expect(
      filled.problemLinks.single.url,
      '/quizzes/gleam-level1-lesson1-quiz.html',
    );
  });

  test('다른 과정 1회차는 기존 임시 인강을 유지한다', () {
    final week = EnrollmentService.defaultWeek('basic_grammar_speaking', 1);
    expect(week.videoUrl, EnrollmentService.defaultWeek1VideoUrl);
  });
}
