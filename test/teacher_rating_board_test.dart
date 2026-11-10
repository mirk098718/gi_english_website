import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gi_english_website/util/EnrollmentService.dart';
import 'package:gi_english_website/util/LessonRatingService.dart';
import 'package:gi_english_website/widget/TeacherRatingBoard.dart';

LessonRating _rating({
  required String id,
  required String name,
  required int stars,
  required DateTime at,
  String review = '',
  String status = LessonRating.statusRated,
}) {
  return LessonRating(
    id: id,
    bookingId: id,
    teacherId: 't1',
    userId: 'u1',
    memberName: name,
    courseTitle: '글림 기초영어',
    weekNumber: 2,
    date: DateTime(at.year, at.month, at.day),
    time: '10:00',
    status: status,
    stars: stars,
    review: review,
    createdAt: at,
    ratedAt: status == LessonRating.statusRated ? at : null,
  );
}

void main() {
  testWidgets('강사 카드에 이번달 평균과 최근 별점이 보인다', (tester) async {
    final ratings = [
      _rating(
        id: 'old',
        name: '이전학생',
        stars: 3,
        at: DateTime(2026, 10, 2, 9),
        review: '예전 수업',
      ),
      _rating(
        id: 'new',
        name: '최근학생',
        stars: 5,
        at: DateTime(2026, 11, 8, 11),
        review: '발음 교정이 좋았습니다',
      ),
    ];

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TeacherRatingBoard(
          previewLimit: 1,
          stats: TeacherMonthStats(
            year: 2026,
            month: 11,
            completedCount: 1,
            cancelledCount: 0,
            ratedCount: 1,
            starSum: 5,
          ),
          ratings: ratings,
        ),
      ),
    ));

    expect(find.textContaining('이번달 평균 5.0점'), findsOneWidget);
    expect(find.textContaining('전체 2건'), findsOneWidget);
    expect(find.textContaining('최근학생'), findsOneWidget);
    expect(find.text('발음 교정이 좋았습니다'), findsOneWidget);
    expect(find.textContaining('이전학생'), findsNothing);
    expect(find.byIcon(Icons.star_rounded), findsWidgets);
  });

  testWidgets('별점이 없으면 빈 안내를 보여 준다', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TeacherRatingBoard(
          stats: TeacherMonthStats(
            year: 2026,
            month: 11,
            completedCount: 0,
            cancelledCount: 0,
          ),
          ratings: const [],
        ),
      ),
    ));

    expect(find.textContaining('이번달 평균 -'), findsOneWidget);
    expect(find.text('학생 별점이 아직 없습니다.'), findsOneWidget);
  });

  test('전체 목록은 최근 평가가 위로 온다', () {
    final ordered = TeacherRatingBoard.newestFirst([
      _rating(id: 'a', name: '가', stars: 4, at: DateTime(2026, 9, 1)),
      _rating(id: 'b', name: '나', stars: 5, at: DateTime(2026, 11, 1)),
    ]);
    expect(ordered.first.memberName, '나');
  });
}
