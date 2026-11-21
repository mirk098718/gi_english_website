import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gi_english_website/util/EnrollmentService.dart';
import 'package:gi_english_website/util/LessonRatingService.dart';
import 'package:gi_english_website/util/TeacherPayroll.dart';
import 'package:gi_english_website/widget/TeacherMonthLessonSummary.dart';

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
    date: date ?? DateTime(2026, 3, 20),
    time: time,
    status: status,
    teacherId: teacherId,
    createdAt: DateTime(2026, 3, 1),
  );
}

LessonRating _rating({
  String id = 'b1',
  String status = LessonRating.statusRated,
  int stars = 5,
  String teacherId = 't1',
  DateTime? date,
  DateTime? ratedAt,
}) {
  return LessonRating(
    id: id,
    bookingId: id,
    teacherId: teacherId,
    userId: 'u1',
    date: date ?? DateTime(2026, 3, 20),
    status: status,
    stars: stars,
    createdAt: date ?? DateTime(2026, 3, 20),
    ratedAt: ratedAt,
  );
}

TeacherPayroll _payroll({
  required List<WeekBooking> bookings,
  required List<LessonRating> ratings,
  required DateTime now,
  int year = 2026,
  int month = 3,
  int lessonFeeWon = 10000,
  String teacherUid = 't1',
  List<SettlementSnapshot> records = const [],
}) {
  return TeacherPayroll.compute(
    bookings: bookings,
    ratings: ratings,
    teacherUid: teacherUid,
    year: year,
    month: month,
    lessonFeeWon: lessonFeeWon,
    records: records,
    now: now,
  );
}

void main() {
  final marchClose = DateTime.utc(2026, 3, 31, 14, 59);
  final aprilOpen = DateTime.utc(2026, 3, 31, 15);
  final beforePayday = DateTime.utc(2026, 4, 5, 3);
  final payday = DateTime.utc(2026, 4, 9, 15);

  group('월마감과 지급일', () {
    test('말일까지 끝난 수업은 다음 달 10일 지급분이다', () {
      final payroll = _payroll(
        bookings: [_booking()],
        ratings: [
          _rating(ratedAt: DateTime.utc(2026, 3, 21, 3)),
        ],
        now: payday,
      );
      expect(payroll.monthClosed, isTrue);
      expect(payroll.paydayReached, isTrue);
      expect(payroll.isEstimate, isFalse);
      expect(payroll.canMarkPaid, isTrue);
      expect(payroll.closedCount, 1);
      expect(payroll.lateCount, 0);
      expect(payroll.shownAmount, 10000);
      expect(payroll.payoutBookingIds, ['b1']);
      expect(payroll.dueLabel(english: false), '4월 10일');
    });

    test('말일 이후 별점은 그 달 지급에 넣지 않고 다음 지급으로 넘긴다', () {
      final bookings = [_booking(date: DateTime(2026, 3, 31))];
      final ratings = [
        _rating(
          date: DateTime(2026, 3, 31),
          ratedAt: DateTime.utc(2026, 4, 2, 3),
        ),
      ];
      final march = _payroll(
        bookings: bookings,
        ratings: ratings,
        now: payday,
      );
      expect(march.closedCount, 0);
      expect(march.lateCount, 1);
      expect(march.payoutBookingIds, isEmpty);

      final april = _payroll(
        bookings: bookings,
        ratings: ratings,
        now: DateTime.utc(2026, 5, 9, 15),
        month: 4,
      );
      expect(april.carryInCount, 1);
      expect(april.closedCount, 0);
      expect(april.payoutBookingIds, ['b1']);
      expect(april.dueLabel(english: false), '5월 10일');
    });

    test('말일 23시 59분은 그 달이고 다음 달 0시는 다음 달이다', () {
      final bookings = [_booking(id: 'edge', date: DateTime(2026, 3, 31))];
      final before = _payroll(
        bookings: bookings,
        ratings: [
          _rating(id: 'edge', date: DateTime(2026, 3, 31), ratedAt: marchClose),
        ],
        now: payday,
      );
      final after = _payroll(
        bookings: bookings,
        ratings: [
          _rating(id: 'edge', date: DateTime(2026, 3, 31), ratedAt: aprilOpen),
        ],
        now: payday,
      );
      expect(before.closedCount, 1);
      expect(before.lateCount, 0);
      expect(after.closedCount, 0);
      expect(after.lateCount, 1);
    });

    test('말일이 지나기 전에는 예상이고 10일 전에는 기록할 수 없다', () {
      final open = _payroll(
        bookings: [_booking()],
        ratings: [_rating(ratedAt: DateTime.utc(2026, 3, 10, 3))],
        now: DateTime.utc(2026, 3, 15, 3),
      );
      expect(open.isEstimate, isTrue);
      expect(open.canMarkPaid, isFalse);
      expect(open.closedCount, 1);

      final closed = _payroll(
        bookings: [_booking()],
        ratings: [_rating(ratedAt: DateTime.utc(2026, 3, 10, 3))],
        now: beforePayday,
      );
      expect(closed.monthClosed, isTrue);
      expect(closed.isEstimate, isFalse);
      expect(closed.canMarkPaid, isFalse);
      expect(TeacherPayroll.isPayday(2026, 3, beforePayday), isFalse);
      expect(TeacherPayroll.isPayday(2026, 3, payday), isTrue);
    });

    test('별점 시각이 없는 예전 평가는 수업일이 있는 달에 넣는다', () {
      final payroll = _payroll(
        bookings: [_booking(date: DateTime(2026, 3, 15))],
        ratings: [
          _rating(date: DateTime(2026, 3, 15)),
        ],
        now: payday,
      );
      expect(payroll.closedCount, 1);
      expect(payroll.lateCount, 0);
    });

    test('평가 기록이 없는 예전 수업은 수업 시간이 지나면 그 달에 넣는다', () {
      final payroll = _payroll(
        bookings: [_booking(date: DateTime(2026, 3, 1), time: '10:00')],
        ratings: const [],
        now: DateTime(2026, 3, 1, 10, 21),
      );
      expect(payroll.closedCount, 1);
    });

    test('별점이 없는 수업과 취소 수업과 다른 강사 수업은 빠진다', () {
      final payroll = _payroll(
        bookings: [
          _booking(id: 'wait', date: DateTime(2026, 3, 8)),
          _booking(id: 'cancel', date: DateTime(2026, 3, 9), status: 'cancelled'),
          _booking(id: 'other', teacherId: 't2', date: DateTime(2026, 3, 10)),
        ],
        ratings: [
          _rating(
            id: 'wait',
            status: LessonRating.statusPending,
            stars: 0,
            date: DateTime(2026, 3, 8),
          ),
          _rating(
            id: 'other',
            teacherId: 't2',
            date: DateTime(2026, 3, 10),
            ratedAt: DateTime.utc(2026, 3, 10, 3),
          ),
        ],
        now: payday,
      );
      expect(payroll.closedCount, 0);
      expect(payroll.awaitingCount, 1);
      expect(payroll.cancelledCount, 1);
      expect(payroll.shownAmount, 0);
    });

    test('회차 수당을 횟수에 곱한다', () {
      final payroll = _payroll(
        bookings: [
          _booking(id: 'a'),
          _booking(id: 'b', date: DateTime(2026, 3, 22)),
        ],
        ratings: [
          _rating(id: 'a', stars: 5, ratedAt: DateTime.utc(2026, 3, 21, 3)),
          _rating(
            id: 'b',
            date: DateTime(2026, 3, 22),
            stars: 3,
            ratedAt: DateTime.utc(2026, 3, 22, 3),
          ),
        ],
        now: payday,
        lessonFeeWon: 15000,
      );
      expect(payroll.shownAmount, 30000);
      expect(payroll.averageStars, 4);
    });

    test('예약 번호가 없는 예전 지급 기록은 다음 입금으로 넘기지 않는다', () {
      final bookings = [_booking(id: 'old', date: DateTime(2026, 2, 10))];
      final ratings = [
        _rating(
          id: 'old',
          date: DateTime(2026, 2, 10),
          ratedAt: DateTime.utc(2026, 3, 5, 3),
        ),
      ];
      final records = [
        SettlementSnapshot(
          yearMonth: '2026-02',
          paid: true,
          hasBookingIds: false,
          bookingIds: const [],
          paidAt: DateTime.utc(2026, 3, 1, 1),
          sessionCount: 4,
          amount: 40000,
          closedCount: 0,
          carryInCount: 0,
        ),
      ];
      final february = _payroll(
        bookings: bookings,
        ratings: ratings,
        now: payday,
        month: 2,
        records: records,
      );
      final march = _payroll(
        bookings: bookings,
        ratings: ratings,
        now: payday,
        records: records,
      );
      expect(february.legacyPaid, isTrue);
      expect(february.shownAmount, 40000);
      expect(february.omittedCount, 1);
      expect(february.lateCount, 0);
      expect(february.legacyNote, contains('다음 입금에도 넣지 않습니다'));
      expect(march.carryInCount, 0);
      expect(march.payoutBookingIds, isEmpty);
    });

    test('이미 기록한 수업은 다시 세지 않고 기록 금액을 유지한다', () {
      final payroll = _payroll(
        bookings: [
          _booking(id: 'a'),
          _booking(id: 'late', date: DateTime(2026, 3, 31)),
        ],
        ratings: [
          _rating(id: 'a', ratedAt: DateTime.utc(2026, 3, 21, 3)),
          _rating(
            id: 'late',
            date: DateTime(2026, 3, 31),
            ratedAt: DateTime.utc(2026, 4, 12, 3),
          ),
        ],
        now: DateTime.utc(2026, 4, 20, 3),
        lessonFeeWon: 20000,
        records: [
          SettlementSnapshot(
            yearMonth: '2026-03',
            paid: true,
            hasBookingIds: true,
            bookingIds: const ['a'],
            paidAt: payday,
            sessionCount: 1,
            amount: 10000,
            closedCount: 1,
            carryInCount: 0,
          ),
        ],
      );
      expect(payroll.paid, isTrue);
      expect(payroll.shownAmount, 10000);
      expect(payroll.payoutBookingIds, isEmpty);
      expect(payroll.lateCount, 1);

      final may = _payroll(
        bookings: [
          _booking(id: 'a'),
          _booking(id: 'late', date: DateTime(2026, 3, 31)),
        ],
        ratings: [
          _rating(id: 'a', ratedAt: DateTime.utc(2026, 3, 21, 3)),
          _rating(
            id: 'late',
            date: DateTime(2026, 3, 31),
            ratedAt: DateTime.utc(2026, 4, 12, 3),
          ),
        ],
        now: DateTime.utc(2026, 5, 9, 15),
        month: 4,
        records: [
          SettlementSnapshot(
            yearMonth: '2026-03',
            paid: true,
            hasBookingIds: true,
            bookingIds: const ['a'],
            paidAt: payday,
            sessionCount: 1,
            amount: 10000,
            closedCount: 1,
            carryInCount: 0,
          ),
        ],
      );
      expect(may.carryInCount, 1);
      expect(may.payoutBookingIds, ['late']);
    });
  });

  testWidgets('수당 요약에 말일 마감과 10일 지급이 보인다', (tester) async {
    final payroll = _payroll(
      bookings: [_booking()],
      ratings: [_rating(ratedAt: DateTime.utc(2026, 3, 21, 3))],
      now: beforePayday,
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TeacherMonthLessonSummary(payroll: payroll),
      ),
    ));

    expect(find.text('이번 입금'), findsOneWidget);
    expect(find.text('마감 후'), findsOneWidget);
    expect(find.text('1회'), findsWidgets);
    expect(find.textContaining('월마감은 말일'), findsOneWidget);
    expect(find.textContaining('4월 10일'), findsOneWidget);
    expect(find.textContaining('마감'), findsWidgets);
  });
}
