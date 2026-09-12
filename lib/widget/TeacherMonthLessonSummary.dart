import 'package:flutter/material.dart';
import 'package:gi_english_website/util/EnrollmentService.dart';
import 'package:gi_english_website/util/Palette.dart';

/// 스케줄 옆에서 보는 이번 달 진행·취소 수업 수와 수입.
class TeacherMonthLessonSummary extends StatelessWidget {
  final TeacherMonthStats stats;
  final bool compact;
  final bool loading;
  final String? title;

  const TeacherMonthLessonSummary({
    Key? key,
    required this.stats,
    this.compact = false,
    this.loading = false,
    this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cells = [
      _cell('진행', loading ? '-' : '${stats.completedCount}회', Palette.secondaryDark),
      _cell('취소', loading ? '-' : '${stats.cancelledCount}회', Palette.danger),
      _cell('수입', loading ? '-' : stats.incomeLabel, Palette.navy),
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
                      title ?? '이번달 수업수',
                      style: TextStyle(
                        fontFamily: "Jalnan",
                        fontSize: 12,
                        color: Palette.secondaryDark,
                      ),
                    ),
                    Text(
                      '${EnrollmentService.lessonMinutes}분 · ${_payLabel()}',
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
                  title ?? '이번달 수업수',
                  style: TextStyle(fontFamily: "Jalnan", fontSize: 15),
                ),
                SizedBox(height: 4),
                Text(
                  '${stats.monthLabel} · 수업 ${EnrollmentService.lessonMinutes}분 · 건당 ${_payLabel()}',
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

  String _payLabel() {
    final digits = EnrollmentService.lessonPayWon.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return '${buffer}원';
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
    if (!mounted) return;
    setState(() {
      _bookings = bookings;
      _loading = false;
    });
  }

  bool _isCompleted(WeekBooking booking) {
    final at = EnrollmentService.bookingDateTime(booking.date, booking.time);
    if (at == null) return booking.isConfirmed;
    return booking.isConfirmed &&
        DateTime.now().isAfter(
            at.add(Duration(minutes: EnrollmentService.lessonMinutes)));
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

  TeacherMonthStats get _stats => TeacherMonthStats.fromBookings(
        bookings: _bookings,
        teacherUid: widget.teacherUid,
        isCompleted: _isCompleted,
        now: _month,
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
          stats: _stats,
          loading: _loading,
          title: '${_month.year}년 ${_month.month}월 수업수',
        ),
        const SizedBox(height: 16),
        Text(
          widget.teacherName.isEmpty
              ? '이 달의 예약 · 진행 · 취소가 시간순으로 보입니다.'
              : '${widget.teacherName} 선생님의 이 달 예약 · 진행 · 취소입니다.',
          style: TextStyle(
              fontFamily: "NotoSansKR", fontSize: 13, color: Palette.grey600),
        ),
        const SizedBox(height: 12),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (items.isEmpty)
          Text('이 달 수업 이력이 없습니다.',
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
    final done = _isCompleted(booking);
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
            '$when · ${booking.statusLabel}${done ? ' · 진행' : ''}',
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
              if (guest) '코티칭',
            ].join(' · '),
            style: TextStyle(
              fontFamily: "NotoSansKR",
              fontSize: 12,
              color: Palette.grey600,
            ),
          ),
        ],
      ),
    );
  }
}
