import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/EnrollmentService.dart';
import 'package:gi_english_website/util/LessonFeedbackService.dart';
import 'package:gi_english_website/util/LessonRatingService.dart';

/// 다음 회차는 강사 피드백과 학생 별점이 끝나야 열린다.
/// 한쪽이 이 시간 넘게 멈추면 관리자만 다음 회차를 열 수 있다.
class SessionGateHold {
  final int sessionNumber;
  final bool waitingOnTeacher;
  final bool waitingOnStudent;
  final DateTime stalledSince;

  const SessionGateHold({
    required this.sessionNumber,
    required this.waitingOnTeacher,
    required this.waitingOnStudent,
    required this.stalledSince,
  });

  bool get stalled => waitingOnTeacher || waitingOnStudent;
}

class SessionGate {
  static const Duration stallAfter = Duration(hours: 24);

  static SessionGateHold? hold({
    required int completedSessions,
    required int totalSessions,
    required int adminUnlockedThrough,
    required List<WeekBooking> bookings,
    required List<LessonRating> ratings,
    required List<LessonFeedback> feedbacks,
    DateTime? now,
  }) {
    if (totalSessions > 0 && completedSessions >= totalSessions) return null;
    // 관리자가 이미 연 회차가 다시 멈추면, 그 회차를 기준으로 다음 회차를 연다.
    var frontier = completedSessions + 1;
    if (adminUnlockedThrough > frontier) frontier = adminUnlockedThrough;
    if (totalSessions > 0 && frontier > totalSessions) return null;

    WeekBooking? booking;
    for (final item in bookings) {
      if (!item.isConfirmed || item.weekNumber != frontier) continue;
      if (booking == null || item.date.isAfter(booking.date)) booking = item;
    }
    if (booking == null) return null;

    final start = EnrollmentService.bookingDateTime(booking.date, booking.time);
    if (start == null) return null;
    final classEnd = start.add(
      Duration(minutes: EnrollmentService.lessonMinutes),
    );
    final clock = now ?? DateTime.now();

    LessonFeedback? feedback;
    for (final item in feedbacks) {
      if (!item.hasContent) continue;
      final sameBooking = item.bookingId.isNotEmpty &&
          (item.bookingId == booking.id);
      final sameWeek = item.weekNumber == frontier &&
          (item.bookingId.isEmpty || item.bookingId == booking.id);
      if (!sameBooking && !sameWeek) continue;
      feedback = item;
      break;
    }

    LessonRating? rating;
    for (final item in ratings) {
      if (item.bookingId == booking.id || item.id == booking.id) {
        rating = item;
        break;
      }
    }
    if (rating != null && rating.isRated && feedback != null) return null;

    if (feedback == null) {
      final due = classEnd.add(stallAfter);
      if (clock.isBefore(due)) return null;
      return SessionGateHold(
        sessionNumber: frontier,
        waitingOnTeacher: true,
        waitingOnStudent: false,
        stalledSince: classEnd,
      );
    }

    if (rating != null && rating.isRated) return null;
    final anchor = feedback.updatedAt ?? feedback.createdAt;
    final due = anchor.add(stallAfter);
    if (clock.isBefore(due)) return null;
    return SessionGateHold(
      sessionNumber: frontier,
      waitingOnTeacher: false,
      waitingOnStudent: true,
      stalledSince: anchor,
    );
  }

  static SessionGateHold? holdFor({
    required EnrollmentRecord enrollment,
    required List<WeekBooking> bookings,
    required List<LessonRating> ratings,
    required List<LessonFeedback> feedbacks,
    DateTime? now,
  }) {
    return hold(
      completedSessions: enrollment.completedSessions,
      totalSessions: enrollment.totalSessions,
      adminUnlockedThrough: enrollment.adminUnlockedThrough,
      bookings: bookings
          .where((item) =>
              item.userId == enrollment.userId &&
              item.courseId == enrollment.courseId)
          .toList(),
      ratings: ratings.where((item) => item.userId == enrollment.userId).toList(),
      feedbacks:
          feedbacks.where((item) => item.userId == enrollment.userId).toList(),
      now: now,
    );
  }

  /// 멈춘 회차의 다음 회차만 연다. 횟수는 별점이 끝난 뒤에 빠진다.
  static Future<String?> adminOpenNext(String enrollmentId) async {
    if (!await AuthService.isAdmin()) {
      return '관리자만 다음 회차를 열 수 있습니다.';
    }
    try {
      final snap = await FirebaseFirestore.instance
          .collection('enrollments')
          .doc(enrollmentId)
          .get();
      if (!snap.exists) return '수강 배정을 찾을 수 없습니다.';
      final record = EnrollmentRecord.fromMap(snap.id, snap.data() ?? {});
      final bookings = await EnrollmentService.staffWeekBookings();
      final ratings = await LessonRatingService.listAll();
      final feedbacks = await LessonFeedbackService.listAll();
      final stalled = holdFor(
        enrollment: record,
        bookings: bookings,
        ratings: ratings,
        feedbacks: feedbacks,
      );
      if (stalled == null || !stalled.stalled) {
        return '강사 피드백이나 학생 별점이 하루 이상 멈추지 않았습니다.';
      }
      final next = stalled.sessionNumber + 1;
      if (record.totalSessions > 0 && next > record.totalSessions) {
        return '열 다음 회차가 없습니다.';
      }
      final name = await AuthService.getAdminName();
      return await EnrollmentService.setAdminUnlockedThrough(
        enrollmentId: enrollmentId,
        through: next,
        adminName: name,
        sessionNumber: stalled.sessionNumber,
      );
    } catch (e) {
      print('다음 회차 개방 오류: $e');
      return '다음 회차를 열지 못했습니다.';
    }
  }
}
