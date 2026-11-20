import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gi_english_website/class/OnlineCourse.dart';
import 'package:gi_english_website/class/OnlinePlan.dart';
import 'package:gi_english_website/util/EnrollmentService.dart';

void main() {
  test('안내 가격은 묶음이 인강과 화상 8회를 따로 사는 것보다 싸다', () {
    for (final course in OnlineCourse.all) {
      final separate = course.lecturePrice +
          OnlinePlan.speakingSessionPrice * course.defaultSessions;
      expect(separate, greaterThan(course.price));
      expect(course.lecturePrice, greaterThan(0));
      expect(
        course.amountFor(OnlinePlan.lecture),
        course.lecturePrice,
      );
      expect(course.sessionsFor(OnlinePlan.lecture), 0);
      expect(
        course.amountFor(OnlinePlan.bundle),
        course.price,
      );
    }
  });

  test('화상만은 고른 횟수만큼 1회 금액으로 계산한다', () {
    final course = OnlineCourse.speaking;
    expect(course.isSpeakingProduct, isTrue);
    expect(OnlineCourse.findById(course.id), same(course));
    expect(OnlineCourse.all.contains(course), isFalse);
    for (final count in OnlinePlan.speakingSessionChoices) {
      expect(
        course.amountFor(OnlinePlan.speaking, sessions: count),
        OnlinePlan.speakingSessionPrice * count,
      );
      expect(
        course.sessionsFor(OnlinePlan.speaking, sessions: count),
        count,
      );
    }
  });

  test('예전 수강은 묶음으로 보고 화상 전용 과정은 화상만으로 본다', () {
    expect(OnlinePlan.normalize(null), OnlinePlan.bundle);
    expect(OnlinePlan.normalize(''), OnlinePlan.bundle);
    expect(
      OnlinePlan.resolve(courseId: OnlinePlan.speakingCourseId),
      OnlinePlan.speaking,
    );
    expect(OnlinePlan.includesLessons(OnlinePlan.lecture), isTrue);
    expect(OnlinePlan.includesSpeaking(OnlinePlan.lecture), isFalse);
    expect(OnlinePlan.includesLessons(OnlinePlan.speaking), isFalse);
    expect(OnlinePlan.includesSpeaking(OnlinePlan.speaking), isTrue);
  });

  test('인강만은 24주가 열리고 연장해도 화상 횟수는 늘지 않는다', () {
    final start = DateTime(2026, 11, 11);
    expect(
      EnrollmentService.expiresAtForPlan(start, OnlinePlan.lecture, 0),
      DateTime(2026, 11, 11).add(const Duration(days: 24 * 7)),
    );
    final fields = EnrollmentService.extensionEnrollmentFields(
      previous: {
        'courseId': 'basic_grammar_speaking',
        'completedSessions': 0,
        'totalSessions': 0,
        'paidAmount': 129000,
        'expiresAt': Timestamp.fromDate(DateTime(2026, 11, 1)),
      },
      addedSessions: 0,
      amount: 129000,
      plan: OnlinePlan.lecture,
      now: DateTime(2026, 11, 11),
    );
    expect(fields['plan'], OnlinePlan.lecture);
    expect(fields['totalSessions'], 0);
    expect(
      (fields['expiresAt'] as Timestamp).toDate(),
      DateTime(2026, 11, 11).add(const Duration(days: 24 * 7)),
    );
  });

  test('인강만 수강은 회차를 잠그지 않는다', () {
    final enrollment = EnrollmentRecord(
      id: 'e1',
      userId: 'u1',
      email: 'a@b.com',
      memberName: '학생',
      courseId: 'basic_grammar_speaking',
      isActive: true,
      totalSessions: 0,
      completedSessions: 0,
      remainingSessions: 0,
      plan: OnlinePlan.lecture,
    );
    expect(enrollment.includesLessons, isTrue);
    expect(enrollment.includesSpeaking, isFalse);
    expect(EnrollmentService.isSessionUnlocked(enrollment, 1), isTrue);
    expect(EnrollmentService.isSessionUnlocked(enrollment, 25), isTrue);
  });
}
