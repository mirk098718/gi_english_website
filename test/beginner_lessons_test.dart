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
      'https://www.youtube-nocookie.com/embed/UMTr9cXimZM?rel=0&playsinline=1',
    );
    expect(
      UrlUtil.playerUrl(second.videoUrl),
      'https://www.youtube-nocookie.com/embed/ikDXCNb66Yo?rel=0&playsinline=1',
    );
    expect(
      UrlUtil.playerUrl(third.videoUrl),
      'https://www.youtube-nocookie.com/embed/mHrkwI56dVw?rel=0&playsinline=1',
    );
    expect(third.problemLinks.single.title, '3강 연습문제');
    expect(
      third.problemLinks.single.url,
      '/quizzes/gleam-level1-lesson3-quiz.html',
    );
    expect(fourth.title, '4강');
    expect(fourth.videoUrl, 'https://youtu.be/6oYf9w2g-DQ');
    expect(
      UrlUtil.playerUrl(
        'https://www.youtube.com/watch?v=6oYf9w2g-DQ&list=PLTyD0pemTuN0',
      ),
      'https://www.youtube-nocookie.com/embed/6oYf9w2g-DQ?rel=0&playsinline=1',
    );
    expect(
      UrlUtil.playerUrl(fourth.videoUrl),
      'https://www.youtube-nocookie.com/embed/6oYf9w2g-DQ?rel=0&playsinline=1',
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

  test('중급 회화 1강은 재생 목록 없이 영상만 연결한다', () {
    final week =
        EnrollmentService.defaultWeek('intermediate_grammar_speaking', 1);

    expect(week.title, '1강');
    expect(week.videoUrl, 'https://youtu.be/Wnp7FbT_AZ0');
    expect(week.description, '중급 1강 인강을 시청한 뒤 체크리스트를 확인하세요.');
    expect(
      UrlUtil.playerUrl(
        'https://www.youtube.com/watch?v=Wnp7FbT_AZ0&list=PLeelS27LkLHE',
      ),
      'https://www.youtube-nocookie.com/embed/Wnp7FbT_AZ0?rel=0&playsinline=1',
    );
    expect(
      UrlUtil.playerUrl(week.videoUrl),
      'https://www.youtube-nocookie.com/embed/Wnp7FbT_AZ0?rel=0&playsinline=1',
    );

    final stored = OnlineWeek(
      id: 'intermediate_grammar_speaking_week_1',
      courseId: 'intermediate_grammar_speaking',
      weekNumber: 1,
      title: '1회차 인강: 관사의 쓰임',
      description: '',
      videoUrl: EnrollmentService.defaultWeek1VideoUrl,
    );
    final filled = EnrollmentService.withCatalogVideo(stored);
    expect(filled.title, '1강');
    expect(filled.videoUrl, 'https://youtu.be/Wnp7FbT_AZ0');
  });

  test('다른 과정 1회차는 기존 임시 인강을 유지한다', () {
    final week = EnrollmentService.defaultWeek('basic_grammar_speaking', 1);
    expect(week.videoUrl, EnrollmentService.defaultWeek1VideoUrl);
  });
}
