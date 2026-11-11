import 'package:flutter/material.dart';
import 'package:gi_english_website/util/AppLanguage.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/EnrollmentService.dart';
import 'package:gi_english_website/util/LessonRatingService.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/TeacherPayroll.dart';
import 'package:gi_english_website/widget/LessonRatingPromptHost.dart';

/// 스케줄 옆에서 보는 이번 달 지급·마감 후 수업 수와 수당.
class TeacherMonthLessonSummary extends StatelessWidget {
  final TeacherPayroll payroll;
  final bool compact;
  final bool loading;
  final String? title;

  const TeacherMonthLessonSummary({
    Key? key,
    required this.payroll,
    this.compact = false,
    this.loading = false,
    this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final english = AppLanguage.instance.isEnglish;
    final payoutLabel =
        tr(context, payroll.isEstimate ? "예상 입금" : "이번 입금");
    final amountLabel = tr(context, payroll.isEstimate ? "예상 수당" : "수당");
    final cells = [
      _cell(payoutLabel, loading ? '-' : '${payroll.shownPayoutCount}회',
          Palette.secondaryDark),
      _cell(tr(context, "마감 후"), loading ? '-' : '${payroll.lateCount}회',
          Palette.warning),
      _cell(amountLabel, loading ? '-' : TeacherPayroll.won(payroll.shownAmount),
          Palette.navy),
      if (!compact)
        _cell(tr(context, "평균별점"), loading ? '-' : payroll.averageStarsLabel,
            Palette.warning),
    ];

    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: Palette.grey50,
        borderRadius: BorderRadius.circular(compact ? 8 : 12),
        border: Border.all(color: Palette.grey200),
      ),
      child: compact
          ? Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title ?? tr(context, "이번달 수업수"),
                      style: TextStyle(
                        fontFamily: "Jalnan",
                        fontSize: 12,
                        color: Palette.secondaryDark,
                      ),
                    ),
                    Text(
                      _caption(context, english, compact: true),
                      style: TextStyle(
                        fontFamily: "NotoSansKR",
                        fontSize: 10,
                        color: Palette.grey500,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      for (var i = 0; i < cells.length; i++) ...[
                        if (i > 0) SizedBox(width: 8),
                        Expanded(child: cells[i]),
                      ],
                    ],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title ?? tr(context, "이번달 수업수"),
                  style: TextStyle(fontFamily: "Jalnan", fontSize: 15),
                ),
                SizedBox(height: 4),
                Text(
                  _caption(context, english, compact: false),
                  style: TextStyle(
                    fontFamily: "NotoSansKR",
                    fontSize: 12,
                    color: Palette.grey600,
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    for (var i = 0; i < cells.length; i++) ...[
                      if (i > 0) SizedBox(width: 8),
                      Expanded(child: cells[i]),
                    ],
                  ],
                ),
              ],
            ),
    );
  }

  String _caption(BuildContext context, bool english, {required bool compact}) {
    final due = payroll.dueLabel(english: english);
    final phase = payroll.isEstimate
        ? tr(context, "예상")
        : payroll.canMarkPaid || payroll.paid
            ? tr(context, "지급일")
            : tr(context, "마감");
    final carry = payroll.shownCarry > 0
        ? english
            ? ' · ${payroll.shownCarry} carried in'
            : ' · ${tr(context, "지난 마감 후")} ${payroll.shownCarry}회'
        : '';
    final waiting = payroll.awaitingCount > 0
        ? english
            ? ' · ${payroll.awaitingCount} awaiting rating'
            : ' · ${tr(context, "평가 대기")} ${payroll.awaitingCount}건'
        : '';
    if (compact) {
      return '$phase · $due$carry$waiting';
    }
    return '${payroll.monthLabel} · ${tr(context, "월마감은 말일")} · $phase $due'
        ' · ${tr(context, "건당")} ${TeacherPayroll.won(payroll.lessonFeeWon)}'
        '$carry$waiting';
  }

  Widget _cell(String label, String value, Color valueColor) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 6 : 10,
      ),
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Palette.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: "NotoSansKR",
              fontSize: compact ? 10 : 12,
              color: Palette.grey600,
            ),
          ),
          SizedBox(height: compact ? 2 : 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: "Jalnan",
              fontSize: compact ? 13 : 16,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// 메인 관리자가 강사별로 보는 한 달 수업 이력.
class TeacherMonthHistoryPanel extends StatefulWidget {
  final String teacherUid;
  final String teacherName;

  const TeacherMonthHistoryPanel({
    Key? key,
    required this.teacherUid,
    this.teacherName = '',
  }) : super(key: key);

  @override
  State<TeacherMonthHistoryPanel> createState() =>
      _TeacherMonthHistoryPanelState();
}

class _TeacherMonthHistoryPanelState extends State<TeacherMonthHistoryPanel> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  List<WeekBooking> _bookings = [];
  List<LessonRating> _ratings = [];
  List<TeacherSettlement> _settlements = [];
  int _lessonFeeWon = EnrollmentService.lessonPayWon;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final bookings =
        await EnrollmentService.weekBookingsForTeacher(widget.teacherUid);
    final ratings =
        await LessonRatingService.listForTeacher(widget.teacherUid);
    final profile = await AuthService.staffProfile(widget.teacherUid);
    final settlements =
        await AuthService.listLessonSettlementsFor(widget.teacherUid);
    if (!mounted) return;
    setState(() {
      _bookings = bookings;
      _ratings = ratings;
      _settlements = settlements;
      _lessonFeeWon = EnrollmentService.lessonFeeWonOf(profile);
      _loading = false;
    });
  }

  List<WeekBooking> get _monthBookings {
    final items = _bookings.where((booking) {
      return TeacherMonthStats.taughtBy(booking, widget.teacherUid) &&
          booking.date.year == _month.year &&
          booking.date.month == _month.month;
    }).toList();
    items.sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      if (byDate != 0) return byDate;
      return a.time.compareTo(b.time);
    });
    return items;
  }

  TeacherPayroll get _payroll => TeacherPayroll.forTeacher(
        bookings: _bookings,
        ratings: _ratings,
        teacherUid: widget.teacherUid,
        year: _month.year,
        month: _month.month,
        lessonFeeWon: _lessonFeeWon,
        settlements: _settlements,
      );

  void _shiftMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = _monthBookings;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            IconButton(
              tooltip: '이전 달',
              onPressed: () => _shiftMonth(-1),
              icon: Icon(Icons.chevron_left, color: Palette.navy),
            ),
            Expanded(
              child: Text(
                '${_month.year}년 ${_month.month}월 수업 이력',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: "Jalnan", fontSize: 16),
              ),
            ),
            IconButton(
              tooltip: '다음 달',
              onPressed: () => _shiftMonth(1),
              icon: Icon(Icons.chevron_right, color: Palette.navy),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TeacherMonthLessonSummary(
          payroll: _payroll,
          loading: _loading,
          title: '${_month.year}년 ${_month.month}월 수업수',
        ),
        const SizedBox(height: 16),
        Text(
          widget.teacherName.isEmpty
              ? tr(context, "이 달의 예약 · 진행 · 평가가 시간순으로 보입니다. 별점은 인사 평가에 쓰입니다.")
              : '${widget.teacherName} 선생님의 이 달 예약 · 진행 · 학생 평가입니다.',
          style: TextStyle(
              fontFamily: "NotoSansKR", fontSize: 13, color: Palette.grey600),
        ),
        const SizedBox(height: 12),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (items.isEmpty)
          Text(tr(context, "이 달 수업 이력이 없습니다."),
              style:
                  TextStyle(fontFamily: "NotoSansKR", color: Palette.grey500))
        else
          ...items.map(_row),
      ],
    );
  }

  Widget _row(WeekBooking booking) {
    final student = booking.memberName.trim().isEmpty
        ? (booking.email.isEmpty ? '수강생' : booking.email)
        : booking.memberName.trim();
    final when =
        '${EnrollmentService.formatBookingDate(booking.date)} ${EnrollmentService.formatBookingTime(booking.time)}';
    final guest = booking.isSubstitute;
    final rating = LessonRatingService.forBooking(_ratings, booking.id);
    final done = LessonRatingService.isPayable(booking, rating, now: _month);
    return Container(
      width: double.maxFinite,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Palette.grey50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Palette.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$when · ${booking.statusLabel}${done ? ' · 정산' : ''}',
            style: TextStyle(
              fontFamily: "NotoSansKR",
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            [
              student,
              if (booking.weekNumber > 0) '${booking.weekNumber}회차',
              if (guest) tr(context, "코티칭"),
            ].join(' · '),
            style: TextStyle(
              fontFamily: "NotoSansKR",
              fontSize: 12,
              color: Palette.grey600,
            ),
          ),
          const SizedBox(height: 8),
          LessonRatingStatusChip(rating: rating),
          if (rating != null && rating.review.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              rating.review.trim(),
              style: TextStyle(
                fontFamily: "NotoSansKR",
                fontSize: 13,
                height: 1.45,
                color: Palette.grey800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
