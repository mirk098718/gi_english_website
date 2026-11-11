import 'package:flutter_test/flutter_test.dart';
import 'package:gi_english_website/util/EnrollmentService.dart';
import 'package:gi_english_website/util/LessonFeedbackService.dart';
import 'package:gi_english_website/util/LessonRatingService.dart';
import 'package:gi_english_website/util/SessionGate.dart';

WeekBooking _booking({
  String id = 'b1',
  int weekNumber = 1,
  DateTime? date,
  String time = '10:00',
  String status = 'confirmed',
}) {
  return WeekBooking(
    id: id,
    userId: 'u1',
    memberName: '학생',
    email: 'a@b.com',
    courseId: 'beginner_phonics',
    weekId: 'w$weekNumber',
    weekNumber: weekNumber,
    weekTitle: '$weekNumber회차',
    date: date ?? DateTime(2026, 11, 10),
    time: time,
    status: status,
    teacherId: 't1',
    createdAt: DateTime(2026, 11, 1),
  );
}

LessonFeedback _feedback({
  String bookingId = 'b1',
  DateTime? createdAt,
}) {
  return LessonFeedback(
    id: bookingId,
    bookingId: bookingId,
    teacherId: 't1',
    teacherName: 'Emma',
    userId: 'u1',
    memberName: '학생',
    email: 'a@b.com',
    courseId: 'beginner_phonics',
    courseTitle: '왕초보',
    weekId: 'w1',
    weekNumber: 1,
    weekTitle: '1회차',
    date: DateTime(2026, 11, 10),
    time: '10:00',
    content: '잘했어요',
    createdAt: createdAt ?? DateTime(2026, 11, 10, 10, 30),
  );
}

LessonRating _rating({
  String id = 'b1',
  String status = LessonRating.statusPending,
}) {
  return LessonRating(
    id: id,
    bookingId: id,
    teacherId: 't1',
    userId: 'u1',
    date: DateTime(2026, 11, 10),
    status: status,
    createdAt: DateTime(2026, 11, 10, 10, 30),
  );
}

EnrollmentRecord _enrollment({
  int completed = 0,
  int total = 8,
  int adminUnlockedThrough = 0,
  int contentUnlockedThrough = 0,
  DateTime? expiresAt,
}) {
  return EnrollmentRecord(
    id: 'e1',
    userId: 'u1',
    email: 'a@b.com',
    memberName: '학생',
    courseId: 'beginner_phonics',
    isActive: true,
    totalSessions: total,
    completedSessions: completed,
    remainingSessions: total - completed,
    adminUnlockedThrough: adminUnlockedThrough,
    contentUnlockedThrough: contentUnlockedThrough,
    expiresAt: expiresAt,
  );
}

void main() {
  test('수업 3시간 전까지는 취소·이동이 되고 그 시각이 지나면 막힌다', () {
    final booking = _booking(
      date: DateTime(2026, 11, 10),
      time: '15:00',
    );
    expect(
      EnrollmentService.canStudentChangeBooking(
        booking,
        now: DateTime(2026, 11, 10, 12),
      ),
      isTrue,
    );
    expect(
      EnrollmentService.canStudentChangeBooking(
        booking,
        now: DateTime(2026, 11, 10, 12, 0, 1),
      ),
      isFalse,
    );
    expect(
      EnrollmentService.canStudentChangeBooking(
        _booking(status: 'cancelled'),
        now: DateTime(2026, 11, 10, 9),
      ),
      isFalse,
    );
  });

  test('영상 주소가 없는 저장 회차는 인강 체크 없이 문제풀이만으로 예약이 열린다', () {
    final stored = OnlineWeek(
      id: 'beginner_phonics_week_5',
      courseId: 'beginner_phonics',
      weekNumber: 5,
      title: '5강',
      description: '',
      videoUrl: '',
      checklistItems: const [
        WeekChecklistItem(id: 'watch_video', label: '인강 시청하기'),
        WeekChecklistItem(id: 'solve_problems', label: '문제풀이 하기'),
      ],
    );

    expect(
      EnrollmentService.requiredChecklistItems(stored).map((item) => item.id).toList(),
      ['solve_problems'],
    );
    expect(
      EnrollmentService.isWeekReadyToBook(stored, const ['solve_problems']),
      isTrue,
    );
  });

  test('영상이 있는 회차는 인강과 문제풀이를 모두 체크해야 한다', () {
    final week = EnrollmentService.defaultWeek('beginner_phonics', 1);
    expect(
      EnrollmentService.isWeekReadyToBook(week, const ['watch_video']),
      isFalse,
    );
    expect(
      EnrollmentService.isWeekReadyToBook(
        week,
        const ['watch_video', 'solve_problems'],
      ),
      isTrue,
    );
  });

  test('피드백이나 별점이 하루 넘으면 관리자 예외가 열리고 그 전에는 열리지 않는다', () {
    final classDay = DateTime(2026, 11, 10, 10);
    final bookings = [_booking(date: DateTime(2026, 11, 10), time: '10:00')];

    expect(
      SessionGate.hold(
        completedSessions: 0,
        totalSessions: 8,
        adminUnlockedThrough: 0,
        bookings: bookings,
        ratings: const [],
        feedbacks: const [],
        now: classDay.add(const Duration(hours: 23)),
      ),
      isNull,
    );

    final teacherStall = SessionGate.hold(
      completedSessions: 0,
      totalSessions: 8,
      adminUnlockedThrough: 0,
      bookings: bookings,
      ratings: const [],
      feedbacks: const [],
      now: DateTime(2026, 11, 11, 10, 21),
    );
    expect(teacherStall, isNotNull);
    expect(teacherStall!.waitingOnTeacher, isTrue);
    expect(teacherStall.sessionNumber, 1);

    final studentStall = SessionGate.hold(
      completedSessions: 0,
      totalSessions: 8,
      adminUnlockedThrough: 0,
      bookings: bookings,
      ratings: [_rating()],
      feedbacks: [_feedback(createdAt: DateTime(2026, 11, 10, 11))],
      now: DateTime(2026, 11, 11, 11),
    );
    expect(studentStall, isNotNull);
    expect(studentStall!.waitingOnStudent, isTrue);

    expect(
      SessionGate.hold(
        completedSessions: 0,
        totalSessions: 8,
        adminUnlockedThrough: 2,
        bookings: bookings,
        ratings: const [],
        feedbacks: const [],
        now: DateTime(2026, 11, 12),
      ),
      isNull,
    );

    final openedAgain = SessionGate.hold(
      completedSessions: 0,
      totalSessions: 8,
      adminUnlockedThrough: 2,
      bookings: [
        _booking(
          id: 'b2',
          weekNumber: 2,
          date: DateTime(2026, 11, 12),
          time: '10:00',
        ),
      ],
      ratings: const [],
      feedbacks: const [],
      now: DateTime(2026, 11, 13, 10, 21),
    );
    expect(openedAgain, isNotNull);
    expect(openedAgain!.sessionNumber, 2);
    expect(openedAgain.waitingOnTeacher, isTrue);
  });

  test('관리자가 연 회차까지 학습이 열리고 이수 횟수는 그대로다', () {
    final enrollment = _enrollment(completed: 0, adminUnlockedThrough: 2);
    expect(enrollment.unlockedSessionNumber, 2);
    expect(EnrollmentService.isSessionUnlocked(enrollment, 2), isTrue);
    expect(EnrollmentService.isSessionUnlocked(enrollment, 3), isFalse);
    expect(enrollment.remainingSessions, 8);
  });

  test('체크리스트를 마치면 다음 회차 수업이 열린다', () {
    final first = EnrollmentService.defaultWeek('beginner_phonics', 1);
    final second = EnrollmentService.defaultWeek('beginner_phonics', 2);
    expect(
      EnrollmentService.checklistUnlockedThrough(
        weeks: [first, second],
        progress: {
          first.id: const ['watch_video'],
        },
        totalSessions: 8,
      ),
      1,
    );
    expect(
      EnrollmentService.checklistUnlockedThrough(
        weeks: [first, second],
        progress: {
          first.id: const ['watch_video', 'solve_problems'],
        },
        totalSessions: 8,
      ),
      2,
    );
    final enrollment = _enrollment(completed: 0, contentUnlockedThrough: 2);
    expect(enrollment.unlockedSessionNumber, 2);
    expect(EnrollmentService.isSessionUnlocked(enrollment, 2), isTrue);
    expect(EnrollmentService.isSessionUnlocked(enrollment, 3), isFalse);
  });

  test('연장 결제는 지난 기한을 오늘부터 다시 잇고 진행 회차를 유지한다', () {
    final fields = EnrollmentService.extensionEnrollmentFields(
      previous: {
        'completedSessions': 3,
        'totalSessions': 8,
        'paidAmount': 180000,
        'expiresAt': null,
      },
      addedSessions: 8,
      amount: 180000,
      now: DateTime(2026, 11, 10, 15),
    );
    expect(fields['completedSessions'], 3);
    expect(fields['totalSessions'], 16);
    expect(fields['remainingSessions'], 13);
    expect(fields['paidAmount'], 360000);
    expect(
      EnrollmentService.extendedExpiresAt(
        currentExpires: DateTime(2026, 11, 1),
        addedSessions: 8,
        now: DateTime(2026, 11, 10),
      ),
      DateTime(2026, 11, 10).add(const Duration(days: 16 * 7)),
    );
    expect(
      EnrollmentService.extendedExpiresAt(
        currentExpires: DateTime(2026, 12, 1),
        addedSessions: 1,
        now: DateTime(2026, 11, 10),
      ),
      DateTime(2026, 12, 1).add(const Duration(days: 14)),
    );
  });

  test('기한 지난 수강은 만료로 남는다', () {
    final expired = _enrollment(expiresAt: DateTime(2026, 11, 1));
    final active = _enrollment(expiresAt: DateTime(2026, 11, 20));
    expect(
      EnrollmentService.isEnrollmentExpired(
        expired,
        now: DateTime(2026, 11, 10),
      ),
      isTrue,
    );
    expect(
      EnrollmentService.isEnrollmentExpired(
        active,
        now: DateTime(2026, 11, 10),
      ),
      isFalse,
    );
  });
}
