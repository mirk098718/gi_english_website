import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gi_english_website/class/OnlineCourse.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/EnrollmentService.dart';
import 'package:gi_english_website/util/Palette.dart';

int _intValue(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

/// 수강생 → 강사 수업 평가. 강사 피드백 이후에만 별점을 받는다.
class LessonRating {
  static const String statusAwaitingFeedback = 'awaiting_feedback';
  static const String statusPending = 'pending';
  static const String statusRated = 'rated';
  static const Duration reminderInterval = Duration(hours: 3);
  static const int minStars = 1;
  static const int maxStars = 5;
  static const int maxReviewLength = 500;

  final String id;
  final String bookingId;
  final String teacherId;
  final String teacherName;
  final String userId;
  final String memberName;
  final String courseId;
  final String courseTitle;
  final String weekId;
  final int weekNumber;
  final String weekTitle;
  final DateTime date;
  final String time;
  final String sessionId;
  final String status;
  final int stars;
  final String review;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? ratedAt;
  final DateTime? dismissedAt;
  final DateTime? lastReminderAt;
  final int reminderCount;

  LessonRating({
    required this.id,
    required this.bookingId,
    required this.teacherId,
    this.teacherName = '',
    required this.userId,
    this.memberName = '',
    this.courseId = '',
    this.courseTitle = '',
    this.weekId = '',
    this.weekNumber = 0,
    this.weekTitle = '',
    required this.date,
    this.time = '',
    this.sessionId = '',
    required this.status,
    this.stars = 0,
    this.review = '',
    required this.createdAt,
    this.updatedAt,
    this.ratedAt,
    this.dismissedAt,
    this.lastReminderAt,
    this.reminderCount = 0,
  });

  bool get isRated =>
      status == statusRated &&
      stars >= minStars &&
      stars <= maxStars;

  bool get isPendingStudent => status == statusPending && !isRated;

  bool get awaitingTeacherFeedback => status == statusAwaitingFeedback;

  String get lessonLabel {
    final week = weekNumber > 0 ? '$weekNumber회차' : '화상수업';
    return '$week · ${EnrollmentService.formatBookingDate(date)} ${EnrollmentService.formatBookingTime(time)}';
  }

  String get starsLabel => isRated ? '$stars점' : '미평가';

  factory LessonRating.fromMap(String id, Map<String, dynamic> data) {
    DateTime toDate(dynamic raw) {
      if (raw is Timestamp) return EnrollmentService.dateOnly(raw.toDate());
      if (raw is DateTime) return EnrollmentService.dateOnly(raw);
      return EnrollmentService.dateOnly(DateTime.now());
    }

    DateTime? toDateTime(dynamic raw) {
      if (raw is Timestamp) return raw.toDate();
      if (raw is DateTime) return raw;
      return null;
    }

    return LessonRating(
      id: id,
      bookingId: data['bookingId']?.toString() ?? id,
      teacherId: data['teacherId']?.toString() ?? '',
      teacherName: data['teacherName']?.toString() ?? '',
      userId: data['userId']?.toString() ?? '',
      memberName: data['memberName']?.toString() ?? '',
      courseId: data['courseId']?.toString() ?? '',
      courseTitle: data['courseTitle']?.toString() ?? '',
      weekId: data['weekId']?.toString() ?? '',
      weekNumber: _intValue(data['weekNumber']),
      weekTitle: data['weekTitle']?.toString() ?? '',
      date: toDate(data['date']),
      time: data['time']?.toString() ?? '',
      sessionId: data['sessionId']?.toString() ?? '',
      status: data['status']?.toString() ?? statusAwaitingFeedback,
      stars: _intValue(data['stars']),
      review: data['review']?.toString() ?? '',
      createdAt: toDateTime(data['createdAt']) ?? DateTime.now(),
      updatedAt: toDateTime(data['updatedAt']),
      ratedAt: toDateTime(data['ratedAt']),
      dismissedAt: toDateTime(data['dismissedAt']),
      lastReminderAt: toDateTime(data['lastReminderAt']),
      reminderCount: _intValue(data['reminderCount']),
    );
  }
}

class LessonRatingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String collection = 'lesson_ratings';

  static LessonRating? forBooking(List<LessonRating> items, String bookingId) {
    if (bookingId.isEmpty) return null;
    for (final item in items) {
      if (item.bookingId == bookingId || item.id == bookingId) return item;
    }
    return null;
  }

  /// 예약 시각 + 수업 시간이 지났는지. 레거시 정산(평가 문서 없음)에만 쓴다.
  static bool isLessonTimePassed(WeekBooking booking, {DateTime? now}) {
    final at = EnrollmentService.bookingDateTime(booking.date, booking.time);
    final clock = now ?? DateTime.now();
    if (at == null) return booking.isConfirmed;
    return clock.isAfter(at.add(Duration(minutes: EnrollmentService.lessonMinutes)));
  }

  /// 강사 월급에 넣는 수업: 피드백+별점이 끝났거나, 예전 수업(평가 문서 없음)은 시간 경과.
  static bool isPayable(WeekBooking booking, LessonRating? rating,
      {DateTime? now}) {
    if (!booking.isConfirmed) return false;
    if (rating != null) return rating.isRated;
    return isLessonTimePassed(booking, now: now);
  }

  static bool Function(WeekBooking booking) payableChecker(
    List<LessonRating> ratings, {
    DateTime? now,
  }) {
    final byId = <String, LessonRating>{};
    for (final rating in ratings) {
      if (rating.bookingId.isNotEmpty) byId[rating.bookingId] = rating;
      byId[rating.id] = rating;
    }
    return (booking) =>
        isPayable(booking, byId[booking.id], now: now);
  }

  static TeacherMonthStats monthStats({
    required List<WeekBooking> bookings,
    required String teacherUid,
    required List<LessonRating> ratings,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    var ratedCount = 0;
    var starSum = 0;
    for (final rating in ratings) {
      if (rating.teacherId != teacherUid) continue;
      if (rating.date.year != current.year ||
          rating.date.month != current.month) {
        continue;
      }
      if (!rating.isRated) continue;
      ratedCount += 1;
      starSum += rating.stars;
    }
    return TeacherMonthStats.fromBookings(
      bookings: bookings,
      teacherUid: teacherUid,
      isCompleted: payableChecker(ratings, now: now),
      isAwaitingPay: (booking) {
        final rating = forBooking(ratings, booking.id);
        if (rating == null) return false;
        return !rating.isRated;
      },
      ratedCount: ratedCount,
      starSum: starSum,
      now: current,
    );
  }

  /// 미평가 재알림: 마지막 알림(없으면 생성 시각)으로부터 3시간.
  static bool isReminderDue({
    required DateTime now,
    required DateTime createdAt,
    DateTime? lastReminderAt,
    required String status,
  }) {
    if (status != LessonRating.statusPending) return false;
    final anchor = lastReminderAt ?? createdAt;
    return !now.isBefore(anchor.add(LessonRating.reminderInterval));
  }

  static String? validateStars(int stars) {
    if (stars < LessonRating.minStars || stars > LessonRating.maxStars) {
      return '별점 1~5점을 선택해 주세요.';
    }
    return null;
  }

  static String? validateReview(String review) {
    if (review.trim().length > LessonRating.maxReviewLength) {
      return '후기는 ${LessonRating.maxReviewLength}자 이내로 적어 주세요.';
    }
    return null;
  }

  static Future<List<LessonRating>> listForTeacher(String teacherId) async {
    if (teacherId.isEmpty) return [];
    try {
      final snapshot = await _firestore
          .collection(collection)
          .where('teacherId', isEqualTo: teacherId)
          .get();
      final list = snapshot.docs
          .map((doc) => LessonRating.fromMap(doc.id, doc.data()))
          .toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    } catch (e) {
      print('강사 수업 평가 조회 오류: $e');
      return [];
    }
  }

  static Future<List<LessonRating>> listAll() async {
    try {
      final snapshot = await _firestore.collection(collection).get();
      final list = snapshot.docs
          .map((doc) => LessonRating.fromMap(doc.id, doc.data()))
          .toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    } catch (e) {
      print('수업 평가 전체 조회 오류: $e');
      return [];
    }
  }

  static Future<List<LessonRating>> listMine({String? userId}) async {
    final uid = userId ?? AuthService.currentUser?.uid ?? '';
    if (uid.isEmpty) return [];
    try {
      final snapshot = await _firestore
          .collection(collection)
          .where('userId', isEqualTo: uid)
          .get();
      final list = snapshot.docs
          .map((doc) => LessonRating.fromMap(doc.id, doc.data()))
          .toList();
      list.sort((a, b) => a.weekNumber.compareTo(b.weekNumber));
      return list;
    } catch (e) {
      print('내 수업 평가 조회 오류: $e');
      return [];
    }
  }

  static Stream<List<LessonRating>> watchMinePending({String? userId}) {
    final uid = userId ?? AuthService.currentUser?.uid ?? '';
    if (uid.isEmpty) return Stream.value(const []);
    return _firestore
        .collection(collection)
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => LessonRating.fromMap(doc.id, doc.data()))
          .where((item) => item.isPendingStudent)
          .toList();
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return list;
    });
  }

  /// 강사 피드백 저장 직후 학생 별점 요청을 연다.
  static Future<void> openAfterFeedback({
    required WeekBooking booking,
    required String teacherId,
    required String teacherName,
  }) async {
    if (booking.id.isEmpty || booking.userId.isEmpty) return;
    final course = OnlineCourse.findById(booking.courseId);
    final ref = _firestore.collection(collection).doc(booking.id);
    try {
      final existing = await ref.get();
      final data = existing.data() ?? {};
      if (data['status']?.toString() == LessonRating.statusRated) return;
      await ref.set({
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
        'weekTitle': EnrollmentService.normalizeSessionLabel(booking.weekTitle),
        'date': Timestamp.fromDate(booking.date),
        'time': booking.time,
        'sessionId': booking.sessionId.isNotEmpty
            ? booking.sessionId
            : EnrollmentService.sessionDocIdForBooking(booking.id),
        'status': LessonRating.statusPending,
        'stars': _intValue(data['stars']),
        'review': data['review']?.toString() ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
        'feedbackSubmittedAt': FieldValue.serverTimestamp(),
        if (!existing.exists) 'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('수업 평가 요청 생성 오류: $e');
    }
  }

  static Future<String?> submit({
    required LessonRating rating,
    required int stars,
    required String review,
  }) async {
    final starError = validateStars(stars);
    if (starError != null) return starError;
    final reviewError = validateReview(review);
    if (reviewError != null) return reviewError;
    final uid = AuthService.currentUser?.uid ?? '';
    if (uid.isEmpty || uid != rating.userId) {
      return '로그인이 만료되었습니다. 다시 로그인해 주세요.';
    }
    if (rating.id.isEmpty) return '수업 정보가 없습니다.';
    try {
      await _firestore.collection(collection).doc(rating.id).set({
        'stars': stars,
        'review': review.trim(),
        'status': LessonRating.statusRated,
        'ratedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return null;
    } on FirebaseException catch (e) {
      print('수업 평가 저장 오류: ${e.code} ${e.message}');
      if (e.code == 'permission-denied') {
        return '수업 평가 저장 권한이 없습니다. 다시 로그인해 주세요.';
      }
      return '수업 평가 저장에 실패했습니다. (${e.code})';
    } catch (e) {
      print('수업 평가 저장 오류: $e');
      return '수업 평가 저장에 실패했습니다.';
    }
  }

  static Future<void> markDismissed(LessonRating rating) async {
    if (rating.id.isEmpty || !rating.isPendingStudent) return;
    if (rating.dismissedAt != null) return;
    try {
      await _firestore.collection(collection).doc(rating.id).set({
        'dismissedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('수업 평가 닫기 기록 오류: $e');
    }
  }

  static Future<bool> showPrompt({
    required BuildContext context,
    required LessonRating rating,
  }) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => LessonRatingDialog(rating: rating),
    );
    return saved == true;
  }
}

class LessonStarView extends StatelessWidget {
  final int stars;
  final double size;
  final bool showEmpty;

  const LessonStarView({
    Key? key,
    required this.stars,
    this.size = 16,
    this.showEmpty = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= LessonRating.maxStars; i++)
          Icon(
            i <= stars ? Icons.star_rounded : Icons.star_border_rounded,
            size: size,
            color: i <= stars
                ? Palette.warning
                : (showEmpty ? Palette.grey300 : Palette.transparent),
          ),
      ],
    );
  }
}

class LessonRatingDialog extends StatefulWidget {
  final LessonRating rating;

  const LessonRatingDialog({Key? key, required this.rating}) : super(key: key);

  @override
  State<LessonRatingDialog> createState() => _LessonRatingDialogState();
}

class _LessonRatingDialogState extends State<LessonRatingDialog> {
  int _stars = 0;
  final _review = TextEditingController();
  bool _saving = false;
  bool _settled = false;

  @override
  void dispose() {
    if (!_settled) {
      LessonRatingService.markDismissed(widget.rating);
    }
    _review.dispose();
    super.dispose();
  }

  Future<void> _later() async {
    _settled = true;
    await LessonRatingService.markDismissed(widget.rating);
    if (!mounted) return;
    Navigator.pop(context, false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final error = await LessonRatingService.submit(
      rating: widget.rating,
      stars: _stars,
      review: _review.text,
    );
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
    _settled = true;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final rating = widget.rating;
    final teacher = rating.teacherName.trim().isEmpty
        ? '강사'
        : rating.teacherName.trim();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _settled) return;
        _later();
      },
      child: AlertDialog(
        backgroundColor: Palette.white,
        surfaceTintColor: Palette.white,
        title: Text('수업 평가', style: TextStyle(fontFamily: "Jalnan")),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$teacher 선생님의 ${rating.lessonLabel} 수업을 평가해 주세요. '
                  '별점은 필수이며, 평가를 마치면 다음 회차가 열립니다.',
                  style: TextStyle(
                    fontFamily: "NotoSansKR",
                    fontSize: 13,
                    height: 1.5,
                    color: Palette.grey700,
                  ),
                ),
                SizedBox(height: 18),
                Text('별점',
                    style: TextStyle(
                        fontFamily: "NotoSansKR", fontWeight: FontWeight.w700)),
                SizedBox(height: 8),
                Row(
                  children: [
                    for (var i = 1; i <= LessonRating.maxStars; i++)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: _saving ? null : () => setState(() => _stars = i),
                        icon: Icon(
                          i <= _stars
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: i <= _stars ? Palette.warning : Palette.grey400,
                          size: 32,
                        ),
                      ),
                  ],
                ),
                if (_stars > 0)
                  Text(
                    '$_stars점',
                    style: TextStyle(
                        fontFamily: "NotoSansKR",
                        fontSize: 12,
                        color: Palette.grey600),
                  ),
                SizedBox(height: 16),
                TextField(
                  controller: _review,
                  maxLines: 4,
                  maxLength: LessonRating.maxReviewLength,
                  enabled: !_saving,
                  decoration: InputDecoration(
                    labelText: '후기 (선택)',
                    alignLabelWithHint: true,
                    hintText: '좋았던 점이나 바라는 점을 적어도 됩니다.',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _later,
            child: Text('나중에'),
          ),
          ElevatedButton(
            onPressed: _saving || _stars < LessonRating.minStars ? null : _save,
            child: _saving
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('평가 제출'),
          ),
        ],
      ),
    );
  }
}
