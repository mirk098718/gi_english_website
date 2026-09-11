import 'package:flutter/material.dart';
import 'package:gi_english_website/class/OnlineCourse.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/EnrollmentService.dart';
import 'package:gi_english_website/util/NotificationService.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/PhoneUtil.dart';
import 'package:gi_english_website/util/TeacherScheduleService.dart';

/// 강사 스케줄(불가 시간)과 수업 예약을 한 화면에서 보고 컨펌한다.
class AdminTeacherScheduleTab extends StatefulWidget {
  final bool showAllBookings;

  const AdminTeacherScheduleTab({Key? key, this.showAllBookings = false})
      : super(key: key);

  @override
  _AdminTeacherScheduleTabState createState() =>
      _AdminTeacherScheduleTabState();
}

class _AdminTeacherScheduleTabState extends State<AdminTeacherScheduleTab> {
  TeacherAvailability _availability = TeacherAvailability(teacherUid: '');
  List<WeekBooking> _bookings = [];
  List<AppNotification> _notifications = [];
  DateTime _weekStart = EnrollmentService.weekStart(DateTime.now());
  bool _loading = true;
  bool _saving = false;
  String _teacherUid = '';
  String _staffPhone = '';

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final uid = await AuthService.currentStaffUid();
    final availability = await TeacherScheduleService.load(uid);
    final bookings = await EnrollmentService.staffWeekBookings(
      mineOnly: !widget.showAllBookings,
    );
    final profile = await AuthService.currentStaffProfile();
    final notifications = await NotificationService.listMine();
    if (!mounted) return;
    setState(() {
      _teacherUid = uid;
      _availability = availability;
      _bookings = bookings;
      _staffPhone = profile?['phone']?.toString() ?? '';
      _notifications = notifications.where((item) => !item.read).toList();
      _loading = false;
    });
  }

  bool _belongsOnMyCalendar(WeekBooking booking) {
    if (booking.status == 'rejected') return false;
    if (widget.showAllBookings) return true;
    if (_teacherUid.isEmpty) return false;
    return booking.teacherId == _teacherUid ||
        booking.nativeTeacherUid == _teacherUid;
  }

  WeekBooking? _bookingAt(DateTime date, String time) {
    final day = EnrollmentService.dateOnly(date);
    WeekBooking? confirmed;
    for (final booking in _bookings) {
      if (!_belongsOnMyCalendar(booking)) continue;
      if (EnrollmentService.dateOnly(booking.date) != day) continue;
      if (booking.time.trim() != time.trim()) continue;
      if (booking.isPending) return booking;
      confirmed ??= booking;
    }
    return confirmed;
  }

  void _toast(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontFamily: "NotoSansKR")),
        backgroundColor: error ? Palette.danger : Palette.success,
      ),
    );
  }

  Future<void> _onCellTap(DateTime date, String time) async {
    if (_saving) return;
    if (_bookingAt(date, time) != null ||
        _availability.isOccupied(date, time)) {
      _toast('이미 예약이 있는 시간은 닫을 수 없습니다. 예약을 먼저 처리하세요.', error: true);
      return;
    }
    final remaining =
        EnrollmentService.remainingTimeSlots(date).contains(time);
    if (!remaining && !_availability.isClosed(date, time)) {
      return;
    }

    final routine = _availability.isRoutine(date, time);
    final exception = _availability.isException(date, time);
    final oneOff = _availability.isOneOffClosed(date, time);
    final timeLabel = EnrollmentService.formatBookingTime(time);
    final dateLabel = EnrollmentService.formatBookingDate(date);
    final weekday = _availability.weekdayLabel(date);

    final action = await showDialog<_SlotAction>(
      context: context,
      builder: (dialogContext) {
        Widget option(_SlotAction value, IconData icon, String title,
            String subtitle) {
          return ListTile(
            leading: Icon(icon, color: Palette.darkTeal),
            title: Text(title, style: TextStyle(fontFamily: "NotoSansKR")),
            subtitle: Text(subtitle,
                style: TextStyle(
                    fontFamily: "NotoSansKR",
                    fontSize: 12,
                    color: Palette.grey600)),
            onTap: () => Navigator.pop(dialogContext, value),
          );
        }

        final options = <Widget>[];
        if (routine && !exception) {
          options.addAll([
            option(
              _SlotAction.openThisDay,
              Icons.lock_open,
              '이번만 열기',
              '루틴은 유지하고 $dateLabel만 다시 엽니다.',
            ),
            option(
              _SlotAction.unpinRoutine,
              Icons.push_pin_outlined,
              '루틴 해제',
              '매주 $weekday요일 $timeLabel을 다시 엽니다.',
            ),
          ]);
        } else if (exception) {
          options.addAll([
            option(
              _SlotAction.closeThisWeek,
              Icons.event_busy,
              '이번 주도 닫기',
              '루틴대로 $dateLabel $timeLabel을 다시 닫습니다.',
            ),
            option(
              _SlotAction.unpinRoutine,
              Icons.push_pin_outlined,
              '루틴 해제',
              '매주 $weekday요일 $timeLabel 닫기를 해제합니다.',
            ),
          ]);
        } else if (oneOff) {
          options.addAll([
            option(
              _SlotAction.openOnce,
              Icons.lock_open,
              '다시 열기',
              '$dateLabel $timeLabel만 다시 엽니다.',
            ),
            option(
              _SlotAction.pinRoutine,
              Icons.push_pin,
              '매주 이 시간 닫기로 고정',
              '매주 $weekday요일 $timeLabel을 닫아 둡니다.',
            ),
          ]);
        } else {
          options.addAll([
            option(
              _SlotAction.closeOnce,
              Icons.event_busy,
              '이번만 닫기',
              '$dateLabel $timeLabel만 닫습니다.',
            ),
            option(
              _SlotAction.pinRoutine,
              Icons.push_pin,
              '매주 이 시간 닫기 (루틴 고정)',
              '매주 $weekday요일 $timeLabel을 닫아 둡니다. 언제든 해제할 수 있습니다.',
            ),
          ]);
        }

        return AlertDialog(
          backgroundColor: Palette.white,
          surfaceTintColor: Palette.white,
          title: Text('$dateLabel $timeLabel',
              style: TextStyle(fontFamily: "Jalnan", fontSize: 16)),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '수업은 30분입니다. 원치 않는 시간을 닫거나, 매주 같은 시간을 루틴으로 고정할 수 있습니다.',
                  style: TextStyle(
                      fontFamily: "NotoSansKR",
                      fontSize: 13,
                      color: Palette.grey600),
                ),
                SizedBox(height: 8),
                ...options,
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('취소',
                  style: TextStyle(
                      fontFamily: "NotoSansKR", color: Palette.grey600)),
            ),
          ],
        );
      },
    );
    if (action == null || !mounted) return;
    await _applySlotAction(action, date, time);
  }

  Future<void> _applySlotAction(
      _SlotAction action, DateTime date, String time) async {
    setState(() => _saving = true);
    String? error;
    switch (action) {
      case _SlotAction.closeOnce:
        error = await TeacherScheduleService.setClosed(
          teacherUid: _teacherUid,
          date: date,
          time: time,
          closed: true,
        );
        break;
      case _SlotAction.openOnce:
        error = await TeacherScheduleService.setClosed(
          teacherUid: _teacherUid,
          date: date,
          time: time,
          closed: false,
        );
        break;
      case _SlotAction.pinRoutine:
        error = await TeacherScheduleService.setRoutineClosed(
          teacherUid: _teacherUid,
          date: date,
          time: time,
          closed: true,
        );
        break;
      case _SlotAction.unpinRoutine:
        error = await TeacherScheduleService.setRoutineClosed(
          teacherUid: _teacherUid,
          date: date,
          time: time,
          closed: false,
        );
        if (error == null) {
          error = await TeacherScheduleService.setClosed(
            teacherUid: _teacherUid,
            date: date,
            time: time,
            closed: false,
          );
        }
        if (error == null) {
          error = await TeacherScheduleService.setOpenException(
            teacherUid: _teacherUid,
            date: date,
            time: time,
            openThisDay: false,
          );
        }
        break;
      case _SlotAction.openThisDay:
        error = await TeacherScheduleService.setOpenException(
          teacherUid: _teacherUid,
          date: date,
          time: time,
          openThisDay: true,
        );
        break;
      case _SlotAction.closeThisWeek:
        error = await TeacherScheduleService.setOpenException(
          teacherUid: _teacherUid,
          date: date,
          time: time,
          openThisDay: false,
        );
        break;
    }
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      _toast(error, error: true);
      return;
    }
    await _refresh();
  }

  Future<void> _confirm(WeekBooking booking) async {
    final error = await EnrollmentService.confirmWeekBooking(booking.id);
    if (error != null) {
      _toast(error, error: true);
      return;
    }
    _toast('예약을 확인했습니다. 화상수업 회차가 자동 생성되었고 수강생에게 확정 알림을 보냅니다.');
    await _refresh();
  }

  Future<void> _reject(WeekBooking booking) async {
    final error = await EnrollmentService.rejectWeekBooking(booking.id);
    if (error != null) {
      _toast(error, error: true);
      return;
    }
    _toast('예약을 거절했습니다. 해당 시간은 다시 열리고 수강생에게 알림을 보냅니다.');
    await _refresh();
  }

  Future<void> _editStaffPhone() async {
    final controller =
        TextEditingController(text: PhoneUtil.display(_staffPhone));
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Palette.white,
        surfaceTintColor: Palette.white,
        title: Text('강사 휴대폰 번호', style: TextStyle(fontFamily: "Jalnan")),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: '010-0000-0000',
            helperText: '수강생이 수업을 신청하면 이 번호로 알림 문자를 보냅니다.',
            helperMaxLines: 2,
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('닫기'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('저장'),
          ),
        ],
      ),
    );
    final phone = controller.text;
    controller.dispose();
    if (saved != true) return;
    final error = await AuthService.updateOwnStaffPhone(phone);
    if (error != null) {
      _toast(error, error: true);
      return;
    }
    _toast('연락처를 저장했습니다.');
    await _refresh();
  }

  List<Widget> _staffAlerts() {
    final hasPhone = PhoneUtil.isValid(_staffPhone);
    return [
      Container(
        width: double.maxFinite,
        padding: EdgeInsets.all(14),
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: hasPhone ? Palette.grey50 : const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: hasPhone ? Palette.grey200 : const Color(0xFFFDBA74)),
        ),
        child: Row(
          children: [
            Icon(Icons.smartphone,
                color: hasPhone ? Palette.grey600 : Palette.warning, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                hasPhone
                    ? '예약 알림 수신 번호 ${PhoneUtil.display(_staffPhone)}'
                    : '수강생 예약 알림을 받으려면 휴대폰 번호를 등록해 주세요.',
                style: TextStyle(fontFamily: "NotoSansKR", fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: _editStaffPhone,
              child: Text(hasPhone ? '변경' : '등록',
                  style: TextStyle(
                      fontFamily: "NotoSansKR", color: Palette.secondaryDark)),
            ),
          ],
        ),
      ),
      ..._notifications.take(5).map((item) => Container(
            width: double.maxFinite,
            margin: EdgeInsets.only(bottom: 10),
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Palette.secondary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: Palette.secondary.withValues(alpha: 0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.notifications_active_outlined,
                    color: Palette.secondaryDark, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title,
                          style: TextStyle(
                              fontFamily: "NotoSansKR",
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                      SizedBox(height: 4),
                      Text(item.body,
                          style: TextStyle(
                              fontFamily: "NotoSansKR",
                              fontSize: 13,
                              height: 1.45)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await NotificationService.markRead(item.id);
                    if (!mounted) return;
                    setState(() {
                      _notifications = _notifications
                          .where((n) => n.id != item.id)
                          .toList();
                    });
                  },
                  child: Text('확인',
                      style: TextStyle(
                          fontFamily: "NotoSansKR",
                          color: Palette.secondaryDark)),
                ),
              ],
            ),
          )),
    ];
  }

  List<DateTime> get _days =>
      List.generate(7, (i) => _weekStart.add(Duration(days: i)));

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(20),
      children: [
        Text('스케줄 · 예약', style: TextStyle(fontFamily: "Jalnan", fontSize: 18)),
        SizedBox(height: 8),
        Text(
          widget.showAllBookings
              ? '화상수업은 30분입니다. 6:00 AM–11:30 PM 칸을 눌러 이번만 닫거나 매주 같은 시간을 루틴으로 고정하세요.\n'
                  '학원 전체 예약이 칸과 아래 목록에 함께 보입니다. 담당이 비어 있으면 컨펌 시 내 스케줄로 연결됩니다.'
              : '화상수업은 30분입니다. 원치 않는 칸을 눌러 이번만 닫거나, 매주 같은 요일·시간을 루틴으로 고정할 수 있습니다.\n'
                  '고정한 루틴은 언제든 해제할 수 있고, 수강생은 열린 시간만 예약합니다.',
          style: TextStyle(
              fontFamily: "NotoSansKR", fontSize: 13, color: Palette.grey600),
        ),
        SizedBox(height: 16),
        ..._staffAlerts(),
        Row(
          children: [
            IconButton(
              tooltip: '이전 주',
              onPressed: () {
                setState(() {
                  _weekStart = _weekStart.subtract(Duration(days: 7));
                });
              },
              icon: Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                '${EnrollmentService.formatBookingDate(_weekStart)} ~ '
                '${EnrollmentService.formatBookingDate(_days.last)}',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontFamily: "NotoSansKR", fontSize: 13),
              ),
            ),
            IconButton(
              tooltip: '다음 주',
              onPressed: () {
                setState(() {
                  _weekStart = _weekStart.add(Duration(days: 7));
                });
              },
              icon: Icon(Icons.chevron_right),
            ),
            OutlinedButton.icon(
              onPressed: _loading ? null : _refresh,
              icon: Icon(Icons.refresh, size: 18),
              label:
                  Text('새로고침', style: TextStyle(fontFamily: "NotoSansKR")),
            ),
          ],
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            _legend(Palette.white, Palette.grey300, '열림'),
            _legend(Palette.grey200, Palette.grey400, '이번만 닫힘'),
            _legend(Palette.grey200, Palette.navy, '매주 닫힘'),
            _legend(Palette.white, Palette.darkTeal, '이번만 열림'),
            _legend(Palette.warning.withValues(alpha: 0.16), Palette.warning,
                '예약 대기'),
            _legend(Palette.primary.withValues(alpha: 0.12), Palette.primary,
                '내 수강생 확정'),
            _legend(Palette.accent.withValues(alpha: 0.16), Palette.accent,
                '타 수강생'),
            _legend(Palette.grey100, Palette.grey300, '지난 시간'),
          ],
        ),
        SizedBox(height: 16),
        if (_loading)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          SizedBox(
            height: 560,
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        SizedBox(width: 88, height: 44),
                        ...EnrollmentService.bookingTimeSlots
                            .map(_timeLabel),
                      ],
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: _days.map(_dayHeader).toList()),
                            ...EnrollmentService.bookingTimeSlots
                                .map(_timeCells),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        SizedBox(height: 28),
        Text('수업 예약',
            style: TextStyle(fontFamily: "Jalnan", fontSize: 16)),
        SizedBox(height: 8),
        Text(
          widget.showAllBookings
              ? '회원이 신청한 주차 수업입니다. 날짜·시간을 확인하고 컨펌하세요.'
              : '내 담당 수강생과, 다른 강사 담당이지만 내 시간에 신청한 타 수강생 예약이 함께 보입니다. 타 수강생은 보라색입니다.',
          style: TextStyle(
              fontFamily: "NotoSansKR", fontSize: 13, color: Palette.grey600),
        ),
        SizedBox(height: 12),
        if (!_loading && _bookings.isEmpty)
          Text('아직 들어온 예약이 없습니다.',
              style:
                  TextStyle(fontFamily: "NotoSansKR", color: Palette.grey500))
        else
          ..._bookings.map(_bookingCard),
      ],
    );
  }

  Widget _legend(Color fill, Color border, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: fill,
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        SizedBox(width: 6),
        Text(label,
            style: TextStyle(fontFamily: "NotoSansKR", fontSize: 12)),
      ],
    );
  }

  Widget _dayHeader(DateTime day) {
    return SizedBox(
      width: 88,
      height: 44,
      child: Center(
        child: Text(
          EnrollmentService.formatBookingDate(day).replaceFirst(
              RegExp(r'^\d{4}\.'), ''),
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: "NotoSansKR", fontSize: 11),
        ),
      ),
    );
  }

  Widget _timeLabel(String time) {
    return SizedBox(
      width: 88,
      height: 40,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          EnrollmentService.formatBookingTime(time),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: "Jalnan",
            fontSize: 11,
            color: Palette.grey700,
          ),
        ),
      ),
    );
  }

  Widget _timeCells(String time) {
    return Row(
      children: _days.map((day) => _cell(day, time)).toList(),
    );
  }

  Widget _cell(DateTime date, String time) {
    final booking = _bookingAt(date, time);
    final occupied = booking != null || _availability.isOccupied(date, time);
    final closed = _availability.isClosed(date, time);
    final routine = _availability.isRoutine(date, time);
    final exception = _availability.isException(date, time);
    final past = !EnrollmentService.remainingTimeSlots(date).contains(time) &&
        !closed &&
        !occupied;
    Color fill = Palette.white;
    Color border = Palette.grey300;
    Color textColor = Palette.secondaryDark;
    String label = '열림';
    if (past) {
      fill = Palette.grey100;
      border = Palette.grey300;
      textColor = Palette.grey500;
      label = '';
    } else if (booking != null) {
      final guest = booking.isGuestFor(_teacherUid);
      if (booking.isPending) {
        fill = guest
            ? Palette.accent.withValues(alpha: 0.14)
            : Palette.warning.withValues(alpha: 0.16);
        border = guest ? Palette.accent : Palette.warning;
        textColor = guest ? Palette.accent : Palette.warning;
      } else {
        fill = guest
            ? Palette.accent.withValues(alpha: 0.16)
            : Palette.primary.withValues(alpha: 0.12);
        border = guest ? Palette.accent : Palette.primary;
        textColor = guest ? Palette.accent : Palette.primaryDark;
      }
      label = guest && booking.isPending
          ? '타·대기'
          : booking.calendarLabel;
    } else if (occupied) {
      fill = Palette.primary.withValues(alpha: 0.12);
      border = Palette.primary;
      textColor = Palette.primaryDark;
      label = '예약';
    } else if (exception) {
      fill = Palette.white;
      border = Palette.darkTeal;
      textColor = Palette.darkTeal;
      label = '이번 열림';
    } else if (closed && routine) {
      fill = Palette.grey200;
      border = Palette.navy;
      textColor = Palette.navy;
      label = '매주';
    } else if (closed) {
      fill = Palette.grey200;
      border = Palette.grey400;
      textColor = Palette.grey600;
      label = '닫힘';
    }

    return Padding(
      padding: EdgeInsets.all(2),
      child: Semantics(
        button: true,
        excludeSemantics: true,
        enabled: !past && !occupied,
        label:
            '${EnrollmentService.formatBookingDate(date)} ${EnrollmentService.formatBookingTime(time)} ${label.isEmpty ? '지난 시간' : label}',
        child: InkWell(
          onTap: past || occupied ? null : () => _onCellTap(date, time),
          child: Container(
            width: 86,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: border),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: "NotoSansKR",
                fontSize: 10,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bookingCard(WeekBooking booking) {
    final course = OnlineCourse.findById(booking.courseId);
    return Card(
      margin: EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking.memberName.isEmpty
                        ? booking.email
                        : '${booking.memberName} · ${booking.email}',
                    style: TextStyle(
                        fontFamily: "NotoSansKR", fontWeight: FontWeight.bold),
                  ),
                ),
                if (booking.isGuestFor(_teacherUid)) ...[
                  Container(
                    margin: EdgeInsets.only(right: 8),
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Palette.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '타 수강생',
                      style: TextStyle(
                        fontFamily: "NotoSansKR",
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Palette.accent,
                      ),
                    ),
                  ),
                ],
                Text(
                  booking.statusLabel,
                  style: TextStyle(
                    fontFamily: "NotoSansKR",
                    fontSize: 12,
                    color: booking.isConfirmed
                        ? Palette.success
                        : booking.status == 'rejected'
                            ? Palette.danger
                            : Palette.warning,
                  ),
                ),
              ],
            ),
            SizedBox(height: 6),
            Text(
              '${course?.title ?? booking.courseId} · ${booking.weekNumber}주차'
              '${booking.weekTitle.isEmpty ? '' : ' · ${booking.weekTitle}'}',
              style: TextStyle(
                  fontFamily: "NotoSansKR",
                  fontSize: 13,
                  color: Palette.grey600),
            ),
            SizedBox(height: 4),
            Text(
              '${EnrollmentService.formatBookingDate(booking.date)} ${EnrollmentService.formatBookingTime(booking.time)}',
              style: TextStyle(fontFamily: "Jalnan", fontSize: 15),
            ),
            if (PhoneUtil.isValid(booking.phone)) ...[
              SizedBox(height: 4),
              Text(
                '연락처 ${PhoneUtil.display(booking.phone)}',
                style: TextStyle(
                    fontFamily: "NotoSansKR",
                    fontSize: 12,
                    color: Palette.grey600),
              ),
            ],
            if (booking.nativeTeacherName.isNotEmpty) ...[
              SizedBox(height: 4),
              Text(
                '원어민 · ${booking.nativeTeacherName}',
                style: TextStyle(
                    fontFamily: "NotoSansKR",
                    fontSize: 12,
                    color: Palette.grey600),
              ),
            ],
            if (booking.isPending) ...[
              SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Palette.secondaryDark,
                      foregroundColor: Palette.white,
                    ),
                    onPressed: () => _confirm(booking),
                    child: Text('컨펌', style: TextStyle(fontFamily: "Jalnan")),
                  ),
                  SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => _reject(booking),
                    child: Text('거절',
                        style: TextStyle(fontFamily: "NotoSansKR")),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum _SlotAction {
  closeOnce,
  openOnce,
  pinRoutine,
  unpinRoutine,
  openThisDay,
  closeThisWeek,
}
