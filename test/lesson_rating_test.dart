import 'package:flutter_test/flutter_test.dart';
import 'package:gi_english_website/util/EnrollmentService.dart';
import 'package:gi_english_website/util/LessonRatingService.dart';

WeekBooking _booking({
  String id = 'b1',
  String teacherId = 't1',
  DateTime? date,
  String time = '10:00',
  String status = 'confirmed',
}) {
  return WeekBooking(
    id: id,
    userId: 'u1',
    memberName: '학생',
    email: 'a@b.com',
    courseId: 'c1',
    weekId: 'w1',
    weekNumber: 1,
    weekTitle: '1회차',
    date: date ?? DateTime(2026, 9, 1),
    time: time,
    status: status,
    teacherId: teacherId,
    createdAt: DateTime(2026, 8, 1),
  );
}

LessonRating _rating({
  String id = 'b1',
  String status = LessonRating.statusPending,
  int stars = 0,
  String teacherId = 't1',
  DateTime? date,
  DateTime? createdAt,
  DateTime? lastReminderAt,
}) {
  return LessonRating(
    id: id,
    bookingId: id,
    teacherId: teacherId,
    userId: 'u1',
    date: date ?? DateTime(2026, 9, 10),
    status: status,
    stars: stars,
    createdAt: createdAt ?? DateTime(2026, 9, 10, 12),
    lastReminderAt: lastReminderAt,
  );
}

void main() {
  group('LessonRatingService.isPayable', () {
    test('counts legacy confirmed lessons after class time', () {
      final booking = _booking(date: DateTime(2026, 9, 1), time: '10:00');
      expect(
        LessonRatingService.isPayable(
          booking,
          null,
          now: DateTime(2026, 9, 1, 10, 21),
        ),
        isTrue,
      );
    });

    test('does not count a gated lesson until the student rates', () {
      final booking = _booking(date: DateTime(2026, 9, 1), time: '10:00');
      final now = DateTime(2026, 9, 1, 12);
      expect(
        LessonRatingService.isPayable(
          booking,
          _rating(status: LessonRating.statusAwaitingFeedback),
          now: now,
        ),
        isFalse,
      );
      expect(
        LessonRatingService.isPayable(
          booking,
          _rating(status: LessonRating.statusPending),
          now: now,
        ),
        isFalse,
      );
      expect(
        LessonRatingService.isPayable(
          booking,
          _rating(status: LessonRating.statusRated, stars: 5),
          now: now,
        ),
        isTrue,
      );
    });

    test('ignores unconfirmed bookings', () {
      expect(
        LessonRatingService.isPayable(
          _booking(status: 'pending'),
          _rating(status: LessonRating.statusRated, stars: 4),
        ),
        isFalse,
      );
    });
  });

  group('LessonRatingService.isReminderDue', () {
    final created = DateTime(2026, 9, 21, 10);

    test('waits 3 hours from creation when no reminder was sent', () {
      expect(
        LessonRatingService.isReminderDue(
          now: created.add(Duration(hours: 2, minutes: 59)),
          createdAt: created,
          status: LessonRating.statusPending,
        ),
        isFalse,
      );
      expect(
        LessonRatingService.isReminderDue(
          now: created.add(Duration(hours: 3)),
          createdAt: created,
          status: LessonRating.statusPending,
        ),
        isTrue,
      );
    });

    test('repeats every 3 hours after the last reminder', () {
      final last = created.add(Duration(hours: 3));
      expect(
        LessonRatingService.isReminderDue(
          now: last.add(Duration(hours: 2, minutes: 59)),
          createdAt: created,
          lastReminderAt: last,
          status: LessonRating.statusPending,
        ),
        isFalse,
      );
      expect(
        LessonRatingService.isReminderDue(
          now: last.add(Duration(hours: 3)),
          createdAt: created,
          lastReminderAt: last,
          status: LessonRating.statusPending,
        ),
        isTrue,
      );
    });

    test('does not remind after the student rates', () {
      expect(
        LessonRatingService.isReminderDue(
          now: created.add(Duration(hours: 10)),
          createdAt: created,
          status: LessonRating.statusRated,
        ),
        isFalse,
      );
    });
  });

  group('LessonRatingService.monthStats', () {
    test('pays only rated lessons and averages stars for the month', () {
      final bookings = [
        _booking(id: 'a', date: DateTime(2026, 9, 2)),
        _booking(id: 'b', date: DateTime(2026, 9, 8)),
        _booking(id: 'c', date: DateTime(2026, 9, 15)),
        _booking(id: 'd', date: DateTime(2026, 8, 20)),
      ];
      final ratings = [
        _rating(
          id: 'a',
          status: LessonRating.statusRated,
          stars: 5,
          date: DateTime(2026, 9, 2),
        ),
        _rating(
          id: 'b',
          status: LessonRating.statusPending,
          date: DateTime(2026, 9, 8),
        ),
        _rating(
          id: 'c',
          status: LessonRating.statusRated,
          stars: 3,
          date: DateTime(2026, 9, 15),
        ),
      ];
      final stats = LessonRatingService.monthStats(
        bookings: bookings,
        teacherUid: 't1',
        ratings: ratings,
        now: DateTime(2026, 9, 21),
      );
      expect(stats.completedCount, 2);
      expect(stats.awaitingCount, 1);
      expect(stats.incomeWon, 20000);
      expect(stats.ratedCount, 2);
      expect(stats.averageStars, 4.0);
      expect(stats.averageStarsLabel, '4.0점');
    });
  });

  group('LessonRating validators', () {
    test('requires 1-5 stars', () {
      expect(LessonRatingService.validateStars(0), isNotNull);
      expect(LessonRatingService.validateStars(6), isNotNull);
      expect(LessonRatingService.validateStars(4), isNull);
    });

    test('caps review length', () {
      expect(LessonRatingService.validateReview('좋았어요'), isNull);
      expect(
        LessonRatingService.validateReview('가' * (LessonRating.maxReviewLength + 1)),
        isNotNull,
      );
    });
  });
}
