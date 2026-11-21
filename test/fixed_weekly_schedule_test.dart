import 'package:flutter_test/flutter_test.dart';
import 'package:gi_english_website/class/JuniorCurriculum.dart';
import 'package:gi_english_website/class/OnlineCourse.dart';
import 'package:gi_english_website/util/EnrollmentService.dart';
import 'package:gi_english_website/util/FixedWeeklySchedule.dart';
import 'package:gi_english_website/util/TeacherScheduleService.dart';

WeekBooking _booking({
  DateTime? date,
  String time = '16:00',
  bool fixedSchedule = false,
  String status = 'confirmed',
}) {
  return WeekBooking(
    id: 'b1',
    userId: 'u1',
    memberName: '학생',
    email: 'a@b.com',
    courseId: 'junior_twice_month',
    weekId: 'native_speaking_session_1',
    weekNumber: 1,
    weekTitle: '1회 회화',
    date: date ?? DateTime(2026, 11, 24),
    time: time,
    status: status,
    teacherId: 't1',
    createdAt: DateTime(2026, 11, 21),
    fixedSchedule: fixedSchedule,
  );
}

void main() {
  test('주니어 1개월은 4주, 3개월은 12주, 재원생은 주 1회 4주다', () {
    final twice = FixedWeeklySchedule.shapeFor(
      OnlineCourse.junior(JuniorOffer.twiceAWeek, quarter: false),
    )!;
    final thrice = FixedWeeklySchedule.shapeFor(
      OnlineCourse.junior(JuniorOffer.threeTimesAWeek, quarter: false),
    )!;
    final quarter = FixedWeeklySchedule.shapeFor(
      OnlineCourse.junior(JuniorOffer.twiceAWeek, quarter: true),
    )!;
    final talk = FixedWeeklySchedule.shapeFor(OnlineCourse.enrolledFreeTalk)!;
    final adult = FixedWeeklySchedule.shapeFor(OnlineCourse.speaking);

    expect(twice.slotsPerWeek, 2);
    expect(twice.weeks, 4);
    expect(twice.sessions, 8);
    expect(thrice.slotsPerWeek, 3);
    expect(thrice.sessions, 12);
    expect(quarter.weeks, 12);
    expect(quarter.sessions, 24);
    expect(talk.slotsPerWeek, 1);
    expect(talk.weeks, 4);
    expect(talk.sessions, 4);
    expect(adult, isNull);
  });

  test('오늘 시간이 지나면 다음 주부터 4주가 잡힌다', () {
    final now = DateTime(2026, 11, 24, 18); // Tuesday
    final lessons = FixedWeeklySchedule.lessons(
      slots: const [
        WeeklySlot(weekday: DateTime.tuesday, time: '16:00'),
        WeeklySlot(weekday: DateTime.thursday, time: '16:00'),
      ],
      weeks: 4,
      now: now,
    );

    expect(lessons, hasLength(8));
    expect(lessons.first.date, DateTime(2026, 11, 26));
    expect(lessons.first.time, '16:00');
    expect(lessons[1].date, DateTime(2026, 12, 1));
    expect(lessons.last.date, DateTime(2026, 12, 22));
  });

  test('오늘 남은 시간은 이번 주 첫 수업으로 넣는다', () {
    final now = DateTime(2026, 11, 24, 10);
    final lessons = FixedWeeklySchedule.lessons(
      slots: const [
        WeeklySlot(weekday: DateTime.tuesday, time: '16:00'),
      ],
      weeks: 4,
      now: now,
    );

    expect(lessons.first.date, DateTime(2026, 11, 24));
    expect(lessons.last.date, DateTime(2026, 12, 15));
  });

  test('중간에 잡힌 주가 있으면 그 매주 시간은 고를 수 없다', () {
    final now = DateTime(2026, 11, 21, 9);
    final slot = const WeeklySlot(weekday: DateTime.tuesday, time: '16:00');
    final third = FixedWeeklySchedule.nextDate(slot, now)
        .add(const Duration(days: 14));
    final availability = TeacherAvailability(
      teacherUid: 't1',
      occupiedKeys: {
        TeacherScheduleService.slotKey(third, '16:00'),
      },
    );

    expect(
      FixedWeeklySchedule.patternFits(
        availability: availability,
        slots: [slot],
        weeks: 4,
        now: now,
      ),
      isFalse,
    );
    expect(
      FixedWeeklySchedule.openSlots(
        availability: availability,
        weeks: 4,
        now: now,
        times: const ['16:00', '17:00'],
      ).map((item) => item.key),
      isNot(contains(slot.key)),
    );
  });

  test('요일을 고른 뒤에만 공통으로 남은 시간이 열리고, 결제한 회차는 그 시간이다', () {
    final now = DateTime(2026, 11, 21, 9); // Saturday
    final open = FixedWeeklySchedule.openSlots(
      availability: TeacherAvailability(teacherUid: 't1'),
      weeks: 4,
      now: now,
      times: const ['16:00', '17:00'],
    );
    final days = FixedWeeklySchedule.weekdaysWithOpenTime(open);
    expect(days, containsAll([DateTime.tuesday, DateTime.thursday]));

    final both = FixedWeeklySchedule.timesOpenOnEveryWeekday(
      open: open,
      weekdays: const [DateTime.tuesday, DateTime.thursday],
    );
    expect(both, ['16:00', '17:00']);

    final thursdayBlocked = TeacherAvailability(
      teacherUid: 't1',
      occupiedKeys: {
        TeacherScheduleService.slotKey(DateTime(2026, 12, 3), '16:00'),
      },
    );
    final openAfterBlock = FixedWeeklySchedule.openSlots(
      availability: thursdayBlocked,
      weeks: 4,
      now: now,
      times: const ['16:00', '17:00'],
    );
    expect(
      FixedWeeklySchedule.timesOpenOnEveryWeekday(
        open: openAfterBlock,
        weekdays: const [DateTime.tuesday, DateTime.thursday],
      ),
      ['17:00'],
    );

    final slots = FixedWeeklySchedule.slotsOnWeekdays(
      weekdays: const [DateTime.thursday, DateTime.tuesday],
      time: '17:00',
    );
    expect(FixedWeeklySchedule.sameClockTime(slots), isTrue);
    expect(
      FixedWeeklySchedule.sameClockTime(const [
        WeeklySlot(weekday: DateTime.tuesday, time: '16:00'),
        WeeklySlot(weekday: DateTime.thursday, time: '17:00'),
      ]),
      isFalse,
    );
    final lessons = FixedWeeklySchedule.lessons(
      slots: slots,
      weeks: 4,
      now: now,
    );
    expect(lessons, hasLength(8));
    expect(lessons.map((lesson) => lesson.time).toSet(), {'17:00'});
  });

  test('고정 수업은 하루 전까지만 옮기고, 그 전에는 취소만으로 비우지 않는다', () {
    final booking = _booking(
      date: DateTime(2026, 11, 24),
      time: '16:00',
      fixedSchedule: true,
    );
    expect(
      EnrollmentService.canStudentChangeBooking(
        booking,
        now: DateTime(2026, 11, 23, 16),
      ),
      isTrue,
    );
    expect(
      EnrollmentService.canStudentChangeBooking(
        booking,
        now: DateTime(2026, 11, 23, 16, 0, 1),
      ),
      isFalse,
    );
    expect(
      EnrollmentService.fixedCancelWithoutReplacement(booking),
      '대체 시간을 고르지 않으면 취소할 수 없습니다.',
    );
    expect(
      EnrollmentService.fixedCancelWithoutReplacement(
        _booking(fixedSchedule: false),
      ),
      isNull,
    );
  });
}
