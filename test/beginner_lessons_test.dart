import 'package:flutter_test/flutter_test.dart';
import 'package:gi_english_website/util/EnrollmentService.dart';
import 'package:gi_english_website/util/UrlIUtil.dart';

void main() {
  test('왕초보 1강부터 4강 인강 주소를 회차에 연결한다', () {
    final first = EnrollmentService.defaultWeek('beginner_phonics', 1);
    final second = EnrollmentService.defaultWeek('beginner_phonics', 2);
    final third = EnrollmentService.defaultWeek('beginner_phonics', 3);
    final fourth = EnrollmentService.defaultWeek('beginner_phonics', 4);

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
    expect(
      UrlUtil.playerUrl(first.videoUrl),
      'https://www.youtube.com/embed/UMTr9cXimZM?rel=0&playsinline=1',
    );
    expect(
      UrlUtil.playerUrl(second.videoUrl),
      'https://www.youtube.com/embed/ikDXCNb66Yo?rel=0&playsinline=1',
    );
    expect(
      UrlUtil.playerUrl(third.videoUrl),
      'https://www.youtube.com/embed/mHrkwI56dVw?rel=0&playsinline=1',
    );
    expect(third.problemLinks.single.title, '3강 연습문제');
    expect(
      third.problemLinks.single.url,
      '/quizzes/gleam-level1-lesson3-quiz.html',
    );
    expect(fourth.title, '4강');
    expect(fourth.videoUrl, 'https://youtu.be/6oYf9w2g-DQ');
    expect(fourth.problemLinks.single.title, '4강 연습문제');
    expect(
      fourth.problemLinks.single.url,
      '/quizzes/gleam-level1-lesson4-quiz.html',
    );
  });

  test('왕초보 5강부터 10강 연습문제를 회차에 연결한다', () {
    for (var lesson = 5; lesson <= 10; lesson++) {
      final week = EnrollmentService.defaultWeek('beginner_phonics', lesson);
      expect(week.title, '$lesson강');
      expect(week.videoUrl, isEmpty);
      expect(week.problemLinks.single.title, '$lesson강 연습문제');
      expect(
        week.problemLinks.single.url,
        '/quizzes/gleam-level1-lesson$lesson-quiz.html',
      );
    }
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

  test('왕초보 4강에 잘못 넣은 중급 영상은 4강 인강으로 되돌린다', () {
    final stored = OnlineWeek(
      id: 'beginner_phonics_week_4',
      courseId: 'beginner_phonics',
      weekNumber: 4,
      title: '4강',
      description: '왕초보 4강',
      videoUrl: 'https://youtu.be/Wnp7FbT_AZ0',
    );

    final filled = EnrollmentService.withCatalogVideo(stored);

    expect(filled.videoUrl, 'https://youtu.be/6oYf9w2g-DQ');
    expect(
      filled.problemLinks.single.url,
      '/quizzes/gleam-level1-lesson4-quiz.html',
    );
  });

  test('중급 1강 영상을 재생 목록 없이 연결한다', () {
    final week =
        EnrollmentService.defaultWeek('intermediate_grammar_speaking', 1);

    expect(week.title, '1강');
    expect(week.videoUrl, 'https://youtu.be/Wnp7FbT_AZ0');
    expect(week.problemLinks.single.title, '1강 연습문제');
    expect(
      week.problemLinks.single.url,
      '/quizzes/gleam-level3-lesson1-quiz.html',
    );
    expect(week.description, '중급 1강 인강을 시청한 뒤 체크리스트를 확인하세요.');
    expect(
      UrlUtil.playerUrl(
        'https://www.youtube.com/watch?v=Wnp7FbT_AZ0&list=PLeelS27LkLHE',
      ),
      'https://www.youtube.com/embed/Wnp7FbT_AZ0?rel=0&playsinline=1',
    );
    expect(
      UrlUtil.playerUrl(week.videoUrl, origin: 'https://gleam-island.web.app'),
      'https://www.youtube.com/embed/Wnp7FbT_AZ0?rel=0&playsinline=1&origin=https%3A%2F%2Fgleam-island.web.app',
    );
    expect(
      UrlUtil.lessonPlayerPath(week.videoUrl),
      '/player.html?v=Wnp7FbT_AZ0',
    );
  });

  test('중급 2강 영상과 연습문제를 연결한다', () {
    final week =
        EnrollmentService.defaultWeek('intermediate_grammar_speaking', 2);

    expect(week.title, '2강');
    expect(week.videoUrl, 'https://youtu.be/ycjiMoPOpy8');
    expect(week.problemLinks.single.title, '2강 연습문제');
    expect(
      week.problemLinks.single.url,
      '/quizzes/gleam-level3-lesson2-quiz.html',
    );
    expect(
      UrlUtil.playerUrl(
        'https://www.youtube.com/watch?v=ycjiMoPOpy8&list=PLeelS27LkLHE&index=2',
      ),
      'https://www.youtube.com/embed/ycjiMoPOpy8?rel=0&playsinline=1',
    );
    expect(
      UrlUtil.lessonPlayerPath(week.videoUrl),
      '/player.html?v=ycjiMoPOpy8',
    );
  });

  test('중급 3강부터 10강 연습문제를 회차에 연결한다', () {
    for (var lesson = 3; lesson <= 10; lesson++) {
      final week = EnrollmentService.defaultWeek(
        'intermediate_grammar_speaking',
        lesson,
      );
      expect(week.title, '$lesson강');
      expect(week.videoUrl, isEmpty);
      expect(week.problemLinks.single.title, '$lesson강 연습문제');
      expect(
        week.problemLinks.single.url,
        '/quizzes/gleam-level3-lesson$lesson-quiz.html',
      );
    }
  });

  test('기초 1강부터 10강은 인강 없이 연습문제만 연결한다', () {
    for (var lesson = 1; lesson <= 10; lesson++) {
      final week = EnrollmentService.defaultWeek('basic_grammar_speaking', lesson);
      expect(week.title, '$lesson강');
      expect(week.videoUrl, isEmpty);
      expect(week.problemLinks.single.title, '$lesson강 연습문제');
      expect(
        week.problemLinks.single.url,
        '/quizzes/gleam-level2-lesson$lesson-quiz.html',
      );
    }
  });
}
