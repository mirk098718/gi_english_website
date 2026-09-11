import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gi_english_website/class/OnlineCourse.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/EnrollmentService.dart';

int _intValue(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

class LessonFeedback {
  final String id;
  final String bookingId;
  final String teacherId;
  final String teacherName;
  final String userId;
  final String memberName;
  final String email;
  final String courseId;
  final String courseTitle;
  final String weekId;
  final int weekNumber;
  final String weekTitle;
  final DateTime date;
  final String time;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;

  LessonFeedback({
    required this.id,
    required this.bookingId,
    required this.teacherId,
    required this.teacherName,
    required this.userId,
    required this.memberName,
    required this.email,
    required this.courseId,
    required this.courseTitle,
    required this.weekId,
    required this.weekNumber,
    required this.weekTitle,
    required this.date,
    required this.time,
    required this.content,
    required this.createdAt,
    this.updatedAt,
  });

  bool get hasContent => content.trim().isNotEmpty;

  String get lessonLabel {
    final week = weekNumber > 0 ? '$weekNumber주차' : '화상수업';
    return '$week · ${EnrollmentService.formatBookingDate(date)} ${EnrollmentService.formatBookingTime(time)}';
  }

  factory LessonFeedback.fromMap(String id, Map<String, dynamic> data) {
    DateTime toDate(dynamic raw) {
      if (raw is Timestamp) return EnrollmentService.dateOnly(raw.toDate());
      return EnrollmentService.dateOnly(DateTime.now());
    }

    DateTime? toDateTime(dynamic raw) =>
        raw is Timestamp ? raw.toDate() : null;

    return LessonFeedback(
      id: id,
      bookingId: data['bookingId']?.toString() ?? id,
      teacherId: data['teacherId']?.toString() ?? '',
      teacherName: data['teacherName']?.toString() ?? '',
      userId: data['userId']?.toString() ?? '',
      memberName: data['memberName']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      courseId: data['courseId']?.toString() ?? '',
      courseTitle: data['courseTitle']?.toString() ?? '',
      weekId: data['weekId']?.toString() ?? '',
      weekNumber: _intValue(data['weekNumber']),
      weekTitle: data['weekTitle']?.toString() ?? '',
      date: toDate(data['date']),
      time: data['time']?.toString() ?? '',
      content: data['content']?.toString() ?? '',
      createdAt: toDateTime(data['createdAt']) ?? DateTime.now(),
      updatedAt: toDateTime(data['updatedAt']),
    );
  }
}

class LessonFeedbackService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'lesson_feedbacks';

  static Future<List<LessonFeedback>> listForTeacher(String teacherId) async {
    if (teacherId.isEmpty) return [];
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('teacherId', isEqualTo: teacherId)
          .get();
      final list = snapshot.docs
          .map((doc) => LessonFeedback.fromMap(doc.id, doc.data()))
          .toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    } catch (e) {
      print('강사 피드백 조회 오류: $e');
      return [];
    }
  }

  static Future<List<LessonFeedback>> listForStudent({
    String? courseId,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) return [];
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: user.uid)
          .get();
      final list = snapshot.docs
          .map((doc) => LessonFeedback.fromMap(doc.id, doc.data()))
          .where((item) =>
              courseId == null ||
              courseId.isEmpty ||
              item.courseId == courseId)
          .toList();
      list.sort((a, b) => a.weekNumber.compareTo(b.weekNumber));
      return list;
    } catch (e) {
      print('수강생 피드백 조회 오류: $e');
      return [];
    }
  }

  static LessonFeedback? forBooking(
      List<LessonFeedback> items, String bookingId) {
    if (bookingId.isEmpty) return null;
    for (final item in items) {
      if (item.bookingId == bookingId || item.id == bookingId) return item;
    }
    return null;
  }

  static LessonFeedback? forWeek(
      List<LessonFeedback> items, String weekId, int weekNumber) {
    LessonFeedback? pick(bool Function(LessonFeedback item) match) {
      LessonFeedback? best;
      for (final item in items) {
        if (!match(item) || !item.hasContent) continue;
        if (best == null ||
            item.date.isAfter(best.date) ||
            (item.date == best.date &&
                (item.updatedAt ?? item.createdAt)
                    .isAfter(best.updatedAt ?? best.createdAt))) {
          best = item;
        }
      }
      return best;
    }

    if (weekId.isNotEmpty) {
      final byId = pick((item) => item.weekId == weekId);
      if (byId != null) return byId;
    }
    if (weekNumber > 0) {
      return pick((item) => item.weekNumber == weekNumber);
    }
    return null;
  }

  static Future<String?> save({
    required WeekBooking booking,
    required String content,
    required String teacherId,
    required String teacherName,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return '피드백 내용을 입력해주세요.';
    if (booking.id.isEmpty) return '수업 정보가 없습니다.';
    try {
      final course = OnlineCourse.findById(booking.courseId);
      final ref = _firestore.collection(_collection).doc(booking.id);
      final existing = await ref.get();
      final now = FieldValue.serverTimestamp();
      final data = <String, dynamic>{
        'bookingId': booking.id,
        'teacherId': teacherId,
        'teacherName': teacherName,
        'userId': booking.userId,
        'memberName': booking.memberName,
        'email': booking.email,
        'courseId': booking.courseId,
        'courseTitle': course?.title ?? '',
        'weekId': booking.weekId,
        'weekNumber': booking.weekNumber,
        'weekTitle': booking.weekTitle,
        'date': Timestamp.fromDate(booking.date),
        'time': booking.time,
        'content': trimmed,
        'updatedAt': now,
      };
      if (!existing.exists) {
        data['createdAt'] = now;
      }
      await ref.set(data, SetOptions(merge: true));
      return null;
    } catch (e) {
      print('피드백 저장 오류: $e');
      return '피드백 저장에 실패했습니다.';
    }
  }
}
