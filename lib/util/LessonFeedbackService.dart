import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gi_english_website/class/OnlineCourse.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/EnrollmentService.dart';
import 'package:gi_english_website/util/NotificationService.dart';
import 'package:gi_english_website/util/Palette.dart';

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
    final week = weekNumber > 0 ? '$weekNumber회차' : '화상수업';
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
    return await listMineForAlerts(courseId: courseId) ?? [];
  }

  /// 조회 실패 시 null. 종 알림은 빈 목록과 오류를 구분해야 한다.
  static Future<List<LessonFeedback>?> listMineForAlerts({
    String? courseId,
    String? userId,
  }) async {
    final uid = userId ?? AuthService.currentUser?.uid ?? '';
    if (uid.isEmpty) return [];
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: uid)
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
      return null;
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

    final writerUid = AuthService.currentUser?.uid ?? '';
    if (writerUid.isEmpty) {
      return '로그인이 만료되었습니다. 강사 계정으로 다시 로그인해 주세요.';
    }

    try {
      final course = OnlineCourse.findById(booking.courseId);
      final ref = _firestore.collection(_collection).doc(booking.id);
      final now = FieldValue.serverTimestamp();
      var isNew = true;
      try {
        final existing = await ref.get();
        isNew = !existing.exists;
      } catch (_) {
        isNew = true;
      }

      final data = <String, dynamic>{
        'bookingId': booking.id,
        'teacherId': teacherId.isNotEmpty ? teacherId : writerUid,
        'writerUid': writerUid,
        'teacherName': teacherName,
        'userId': booking.userId,
        'memberName': booking.memberName,
        'email': booking.email,
        'courseId': booking.courseId,
        'courseTitle': course?.title ?? '',
        'weekId': booking.weekId,
        'weekNumber': booking.weekNumber,
        'weekTitle': EnrollmentService.normalizeSessionLabel(booking.weekTitle),
        'date': Timestamp.fromDate(booking.date),
        'time': booking.time,
        'content': trimmed,
        'updatedAt': now,
        if (isNew) 'createdAt': now,
      };
      await ref.set(data, SetOptions(merge: true));
      final teacher = teacherName.trim().isEmpty ? '강사' : teacherName.trim();
      final week = booking.weekNumber > 0 ? '${booking.weekNumber}회차' : '화상수업';
      final sent = await NotificationService.notifyUser(
        userId: booking.userId,
        title: '강사 피드백',
        body: isNew
            ? '$teacher 선생님이 $week 피드백을 남겼습니다. 내 강의실에서 확인해 주세요.'
            : '$teacher 선생님이 $week 피드백을 수정했습니다. 내 강의실에서 확인해 주세요.',
        type: 'lesson_feedback',
        bookingId: booking.id,
      );
      if (sent) {
        await ref.set({'alertSentAt': now}, SetOptions(merge: true));
      }
      return null;
    } on FirebaseException catch (e) {
      print('피드백 저장 오류: ${e.code} ${e.message}');
      if (e.code == 'permission-denied') {
        return '피드백 저장 권한이 없습니다. 강사 계정으로 다시 로그인해 주세요.';
      }
      return '피드백 저장에 실패했습니다. (${e.code})';
    } catch (e) {
      print('피드백 저장 오류: $e');
      return '피드백 저장에 실패했습니다.';
    }
  }

  /// 피드백 작성/확인 다이얼로그. 저장 성공 시 true.
  static Future<bool> showEditor({
    required BuildContext context,
    required WeekBooking booking,
    LessonFeedback? existing,
    required bool canWrite,
    required String teacherId,
    required String teacherName,
  }) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => LessonFeedbackDialog(
        booking: booking,
        existing: existing,
        canWrite: canWrite,
        onSave: (content) => save(
          booking: booking,
          content: content,
          teacherId: teacherId,
          teacherName: teacherName,
        ),
      ),
    );
    return saved == true;
  }
}

class LessonFeedbackDialog extends StatefulWidget {
  final WeekBooking booking;
  final LessonFeedback? existing;
  final bool canWrite;
  final Future<String?> Function(String content) onSave;

  const LessonFeedbackDialog({
    Key? key,
    required this.booking,
    required this.existing,
    required this.canWrite,
    required this.onSave,
  }) : super(key: key);

  @override
  State<LessonFeedbackDialog> createState() => _LessonFeedbackDialogState();
}

class _LessonFeedbackDialogState extends State<LessonFeedbackDialog> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.existing?.content ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final error = await widget.onSave(_controller.text);
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error, style: TextStyle(fontFamily: "NotoSansKR")),
          backgroundColor: Palette.danger,
        ),
      );
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final course = OnlineCourse.findById(booking.courseId);
    return AlertDialog(
      backgroundColor: Palette.white,
      surfaceTintColor: Palette.white,
      title: Text('회차별 피드백', style: TextStyle(fontFamily: "Jalnan")),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                [
                  if (booking.memberName.isNotEmpty) booking.memberName,
                  if (course != null) course.title,
                  if (booking.weekNumber > 0) '${booking.weekNumber}회차',
                ].join(' · '),
                style: TextStyle(
                    fontFamily: "NotoSansKR", fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 4),
              Text(
                '${EnrollmentService.formatBookingDate(booking.date)} ${EnrollmentService.formatBookingTime(booking.time)}',
                style: TextStyle(
                    fontFamily: "NotoSansKR",
                    fontSize: 13,
                    color: Palette.grey600),
              ),
              SizedBox(height: 16),
              if (widget.canWrite)
                TextField(
                  controller: _controller,
                  maxLines: 8,
                  decoration: InputDecoration(
                    labelText: '수업 피드백',
                    alignLabelWithHint: true,
                    hintText: '오늘 수업에서 잘한 점, 고칠 점, 다음 회차 과제를 적어 주세요.',
                    border: OutlineInputBorder(),
                  ),
                )
              else
                Container(
                  width: double.maxFinite,
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Palette.grey50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Palette.grey200),
                  ),
                  child: Text(
                    (widget.existing?.content ?? '').trim().isEmpty
                        ? '아직 작성된 피드백이 없습니다.'
                        : widget.existing!.content,
                    style: TextStyle(
                        fontFamily: "NotoSansKR", fontSize: 14, height: 1.55),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: Text('닫기'),
        ),
        if (widget.canWrite)
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('저장'),
          ),
      ],
    );
  }
}
