import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/EnrollmentService.dart';
import 'package:gi_english_website/util/LessonRatingService.dart';

/// 강사 수당의 한 달.
///
/// 월마감은 말일이다. 그 달 1일부터 말일까지 끝난 수업이 마감분이다.
/// 지급일은 다음 달 10일이다. 말일 이후의 별점은 수업 달 카드에 남고,
/// 별점이 끝난 달의 다음 10일에 지급한다.
class TeacherPayroll {
  static const Duration seoulOffset = Duration(hours: 9);

  final int year;
  final int month;
  final DateTime deposit;
  final bool monthClosed;
  final bool paydayReached;
  final int lessonFeeWon;

  /// 이번 달 수업 중 이번 입금에 들어가는 횟수.
  final int closedCount;

  /// 앞달에서 이번 입금으로 넘어온 횟수.
  final int carryInCount;

  /// 이번 달 수업 중 다음 입금으로 넘기는 횟수.
  final int lateCount;
  final int awaitingCount;
  final int cancelledCount;

  /// 예전 지급 기록 뒤에 끝난 이번 달 수업. 다음 입금에 넣지 않는다.
  final int omittedCount;

  /// 예전 지급 기록의 달로 넘어왔지만 그 기록에 없는 수업.
  final int strandedCarryCount;

  final int ratedCount;
  final int starSum;
  final bool paid;
  final bool legacyPaid;
  final int recordedCount;
  final int recordedAmount;
  final int recordedClosed;
  final int recordedCarry;
  final DateTime? paidAt;
  final List<String> payoutBookingIds;

  const TeacherPayroll({
    required this.year,
    required this.month,
    required this.deposit,
    required this.monthClosed,
    required this.paydayReached,
    required this.lessonFeeWon,
    required this.closedCount,
    required this.carryInCount,
    required this.lateCount,
    required this.awaitingCount,
    required this.cancelledCount,
    required this.omittedCount,
    required this.strandedCarryCount,
    required this.ratedCount,
    required this.starSum,
    required this.paid,
    required this.legacyPaid,
    required this.recordedCount,
    required this.recordedAmount,
    required this.recordedClosed,
    required this.recordedCarry,
    required this.paidAt,
    required this.payoutBookingIds,
  });

  bool get isEstimate => !paid && !monthClosed;

  bool get canMarkPaid => !paid && paydayReached;

  int get shownClosed => paid ? recordedClosed : closedCount;

  int get shownCarry => paid ? recordedCarry : carryInCount;

  int get shownPayoutCount =>
      paid ? recordedCount : closedCount + carryInCount;

  int get shownAmount =>
      paid ? recordedAmount : shownPayoutCount * lessonFeeWon;

  int get lateAmount => lateCount * lessonFeeWon;

  String get monthLabel => '$year년 $month월';

  DateTime get depositDate => seoulDate(deposit);

  double? get averageStars => ratedCount <= 0 ? null : starSum / ratedCount;

  String get averageStarsLabel {
    final avg = averageStars;
    if (avg == null) return '-';
    return '${avg.toStringAsFixed(1)}점';
  }

  String dueLabel({required bool english}) {
    final date = depositDate;
    if (english) {
      const names = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${names[date.month - 1]} ${date.day}';
    }
    return '${date.month}월 ${date.day}일';
  }

  /// 예전 기록에 없어서 다음 입금에도 넣지 않는 수업 안내.
  String? get legacyNote {
    if (!legacyPaid) return null;
    final parts = <String>[];
    if (omittedCount > 0) {
      parts.add('지급 뒤에 끝난 수업 ${omittedCount}회');
    }
    if (strandedCarryCount > 0) {
      parts.add('앞달에서 넘어온 ${strandedCarryCount}회');
    }
    if (parts.isEmpty) return null;
    return '${parts.join(', ')}는 이 기록에 없고 다음 입금에도 넣지 않습니다.';
  }

  static String won(int amount) {
    final digits = amount.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return '${buffer}원';
  }

  static String formatSeoulDay(DateTime instant) {
    final date = seoulDate(instant);
    String two(int n) => n.toString().padLeft(2, '0');
    return '${date.year}.${two(date.month)}.${two(date.day)}';
  }

  /// 서울 달력의 0시를 UTC 시각으로 돌려준다.
  static DateTime seoulMidnightUtc(int year, int month, int day) {
    return DateTime.utc(year, month, day).subtract(seoulOffset);
  }

  static DateTime seoulDate(DateTime instant) {
    final wall = instant.toUtc().add(seoulOffset);
    return DateTime(wall.year, wall.month, wall.day);
  }

  static bool isMonthClosed(int year, int month, DateTime now) {
    return !now.toUtc().isBefore(seoulMidnightUtc(year, month + 1, 1));
  }

  static bool isPayday(int year, int month, DateTime now) {
    return !now.toUtc().isBefore(seoulMidnightUtc(year, month + 1, 10));
  }

  /// 별점이 끝난 서울 달의 다음 달 10일.
  static DateTime paymentInstantFor(DateTime completedAt) {
    final wall = completedAt.toUtc().add(seoulOffset);
    return seoulMidnightUtc(wall.year, wall.month + 1, 10);
  }

  static String completionMonthKey(DateTime completedAt) {
    final wall = completedAt.toUtc().add(seoulOffset);
    return _monthKey(wall.year, wall.month);
  }

  static TeacherPayroll forTeacher({
    required List<WeekBooking> bookings,
    required List<LessonRating> ratings,
    required String teacherUid,
    required int year,
    required int month,
    required int lessonFeeWon,
    required List<TeacherSettlement> settlements,
    DateTime? now,
  }) {
    return compute(
      bookings: bookings,
      ratings: ratings,
      teacherUid: teacherUid,
      year: year,
      month: month,
      lessonFeeWon: lessonFeeWon,
      records: settlements.map(SettlementSnapshot.fromSettlement).toList(),
      now: now,
    );
  }

  static TeacherPayroll compute({
    required List<WeekBooking> bookings,
    required List<LessonRating> ratings,
    required String teacherUid,
    required int year,
    required int month,
    required int lessonFeeWon,
    List<SettlementSnapshot> records = const [],
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final deposit = seoulMidnightUtc(year, month + 1, 10);
    final monthEnd = seoulMidnightUtc(year, month + 1, 1);
    final viewedKey = _monthKey(year, month);
    final monthClosed = !clock.toUtc().isBefore(monthEnd);
    final paydayReached = !clock.toUtc().isBefore(deposit);
    final fee = lessonFeeWon < 0 ? EnrollmentService.lessonPayWon : lessonFeeWon;

    final legacyMonths = <String>{};
    final paidIds = <String>{};
    SettlementSnapshot? viewed;
    for (final record in records) {
      if (record.yearMonth == viewedKey) viewed = record;
      if (!record.paid) continue;
      if (!record.hasBookingIds) {
        legacyMonths.add(record.yearMonth);
      } else {
        paidIds.addAll(record.bookingIds);
      }
    }

    final byBooking = <String, LessonRating>{};
    for (final rating in ratings) {
      if (rating.bookingId.isNotEmpty) {
        byBooking[rating.bookingId] = rating;
      }
      byBooking.putIfAbsent(rating.id, () => rating);
    }

    var closed = 0;
    var carry = 0;
    var late = 0;
    var awaiting = 0;
    var cancelled = 0;
    var omitted = 0;
    final payoutIds = <String>[];
    final viewedIndex = year * 12 + month;

    for (final booking in bookings) {
      if (!TeacherMonthStats.taughtBy(booking, teacherUid)) continue;
      final classKey = _monthKey(booking.date.year, booking.date.month);
      final inViewed = classKey == viewedKey;
      if (inViewed &&
          (booking.status == 'rejected' || booking.status == 'cancelled')) {
        cancelled += 1;
      }

      final rating = byBooking[booking.id];
      if (inViewed &&
          booking.isConfirmed &&
          rating != null &&
          !rating.isRated) {
        awaiting += 1;
      }

      final completed = _completedAt(booking, rating, clock);
      if (completed == null) continue;
      if (paidIds.contains(booking.id)) continue;

      final classLegacy = legacyMonths.contains(classKey);
      if (inViewed && classLegacy) {
        final paidAt = viewed?.paidAt;
        if (paidAt != null && completed.toUtc().isAfter(paidAt.toUtc())) {
          omitted += 1;
        }
        continue;
      }
      if (classLegacy) continue;

      final doneKey = completionMonthKey(completed);
      final classIndex = booking.date.year * 12 + booking.date.month;
      if (doneKey == viewedKey) {
        if (inViewed) {
          closed += 1;
          payoutIds.add(booking.id);
        } else if (classIndex < viewedIndex) {
          carry += 1;
          payoutIds.add(booking.id);
        }
      } else if (inViewed && _monthIndex(doneKey) > viewedIndex) {
        late += 1;
      }
    }

    var ratedCount = 0;
    var starSum = 0;
    for (final rating in ratings) {
      if (rating.teacherId != teacherUid || !rating.isRated) continue;
      if (rating.date.year != year || rating.date.month != month) continue;
      ratedCount += 1;
      starSum += rating.stars;
    }

    final paid = viewed?.paid == true;
    final legacyPaid = paid && viewed?.hasBookingIds != true;
    final recordedClosed = legacyPaid
        ? (viewed?.sessionCount ?? 0)
        : (viewed?.closedCount ?? 0);
    final recordedCarry = legacyPaid ? 0 : (viewed?.carryInCount ?? 0);

    return TeacherPayroll(
      year: year,
      month: month,
      deposit: deposit,
      monthClosed: monthClosed,
      paydayReached: paydayReached,
      lessonFeeWon: fee,
      closedCount: paid ? recordedClosed : closed,
      carryInCount: paid ? recordedCarry : carry,
      lateCount: legacyPaid ? 0 : late,
      awaitingCount: awaiting,
      cancelledCount: cancelled,
      omittedCount: legacyPaid ? omitted : 0,
      strandedCarryCount: legacyPaid ? carry : 0,
      ratedCount: ratedCount,
      starSum: starSum,
      paid: paid,
      legacyPaid: legacyPaid,
      recordedCount: viewed?.sessionCount ?? 0,
      recordedAmount: viewed?.amount ?? 0,
      recordedClosed: recordedClosed,
      recordedCarry: recordedCarry,
      paidAt: viewed?.paidAt,
      payoutBookingIds: paid ? const [] : List.unmodifiable(payoutIds),
    );
  }

  static DateTime? _completedAt(
    WeekBooking booking,
    LessonRating? rating,
    DateTime now,
  ) {
    if (!booking.isConfirmed) return null;
    if (rating != null) {
      if (!rating.isRated) return null;
      if (rating.ratedAt != null) return rating.ratedAt;
      return seoulMidnightUtc(
        booking.date.year,
        booking.date.month,
        booking.date.day,
      ).add(const Duration(hours: 12));
    }
    if (!LessonRatingService.isLessonTimePassed(booking, now: now)) {
      return null;
    }
    final start = EnrollmentService.bookingDateTime(booking.date, booking.time);
    if (start == null) {
      return seoulMidnightUtc(
        booking.date.year,
        booking.date.month,
        booking.date.day,
      ).add(const Duration(hours: 12));
    }
    return start.add(Duration(minutes: EnrollmentService.lessonMinutes));
  }

  static int _monthIndex(String key) {
    final parts = key.split('-');
    final year = int.tryParse(parts.first) ?? 0;
    final month = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return year * 12 + month;
  }

  static String _monthKey(int year, int month) {
    final mm = month.toString().padLeft(2, '0');
    return '$year-$mm';
  }
}

/// 지급 기록 중 수당 계산에 쓰는 값.
class SettlementSnapshot {
  final String yearMonth;
  final bool paid;
  final bool hasBookingIds;
  final List<String> bookingIds;
  final DateTime? paidAt;
  final int sessionCount;
  final int amount;
  final int closedCount;
  final int carryInCount;

  const SettlementSnapshot({
    required this.yearMonth,
    required this.paid,
    required this.hasBookingIds,
    required this.bookingIds,
    required this.paidAt,
    required this.sessionCount,
    required this.amount,
    required this.closedCount,
    required this.carryInCount,
  });

  static SettlementSnapshot fromSettlement(TeacherSettlement settlement) {
    return SettlementSnapshot(
      yearMonth: settlement.yearMonth,
      paid: settlement.paid,
      hasBookingIds: settlement.hasBookingIds,
      bookingIds: settlement.bookingIds,
      paidAt: settlement.paidAt,
      sessionCount: settlement.sessionCount,
      amount: settlement.amount,
      closedCount: settlement.closedCount,
      carryInCount: settlement.carryInCount,
    );
  }
}
