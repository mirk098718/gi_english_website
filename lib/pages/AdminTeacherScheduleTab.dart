// ignore: deprecated_member_use
import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gi_english_website/class/OnlineCourse.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/EnrollmentService.dart';
import 'package:gi_english_website/util/LessonFeedbackService.dart';
import 'package:gi_english_website/util/NotificationService.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/PhoneUtil.dart';
import 'package:gi_english_website/util/TeacherScheduleService.dart';
import 'package:gi_english_website/util/UrlIUtil.dart';
import 'package:gi_english_website/widget/StudentLearningProgressPanel.dart';
import 'package:gi_english_website/widget/TeacherMonthLessonSummary.dart';
import 'package:gi_english_website/pages/StudentDetailPage.dart';
import 'package:gi_english_website/widget/AdminContentWidth.dart';
import 'package:gi_english_website/widget/NotificationBellButton.dart';

/// 스케줄만 따로 보는 전체 화면. `/schedule` 또는 허브의 ‘새 화면으로 열기’.
class AdminTeacherSchedulePage extends StatefulWidget {
  final bool? showAllBookings;
  final String teacherUid;

  const AdminTeacherSchedulePage({
    Key? key,
    this.showAllBookings,
    this.teacherUid = '',
  }) : super(key: key);

  static bool matchesUri(Uri uri) {
    if (uri.queryParameters['view'] == 'schedule') return true;
    return uri.path.toLowerCase().contains('/schedule');
  }

  static void openNewScreen(
    BuildContext context, {
    required bool showAllBookings,
    String teacherUid = '',
  }) {
    if (kIsWeb) {
      final params = <String, String>{'view': 'schedule'};
      if (showAllBookings) params['all'] = '1';
      if (teacherUid.isNotEmpty) params['teacher'] = teacherUid;
      final url = Uri.parse(html.window.location.origin)
          .replace(queryParameters: params)
          .toString();
      html.window.open(url, 'giSchedule');
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminTeacherSchedulePage(
          showAllBookings: showAllBookings,
          teacherUid: teacherUid,
        ),
      ),
    );
  }

  @override
  State<AdminTeacherSchedulePage> createState() =>
      _AdminTeacherSchedulePageState();
}

class _AdminTeacherSchedulePageState extends State<AdminTeacherSchedulePage> {
  bool _checking = true;
  bool _authorized = false;
  bool _showAll = false;
  String _teacherUid = '';

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final isStaff = await AuthService.isStaff();
    if (!mounted) return;
    final fromQuery = Uri.base.queryParameters['all'] == '1';
    final teacherFromQuery = Uri.base.queryParameters['teacher'] ?? '';
    setState(() {
      _authorized = isStaff;
      _showAll = widget.showAllBookings ?? fromQuery;
      _teacherUid = widget.teacherUid.isNotEmpty
          ? widget.teacherUid
          : teacherFromQuery;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_authorized) {
      return Scaffold(
        appBar: AppBar(
          title: Text('내 스케줄', style: TextStyle(fontFamily: "NotoSansKR")),
          backgroundColor: Palette.navy,
          foregroundColor: Palette.white,
        ),
        body: Center(
          child: Text(
            '강사 또는 관리자로 로그인한 뒤 다시 열어 주세요.',
            style: TextStyle(fontFamily: "NotoSansKR"),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Palette.white,
      body: SafeArea(
        child: AdminContentWidth(
          child: AdminTeacherScheduleTab(
            showAllBookings: _showAll,
            standalone: true,
            teacherUid: _teacherUid,
          ),
        ),
      ),
    );
  }
}

enum _OverviewKind { pending, confirmed, completed, cancelled }

/// 강사 스케줄(불가 시간)과 수업 예약을 한 화면에서 보고 컨펌한다.
class AdminTeacherScheduleTab extends StatefulWidget {
  final bool showAllBookings;
  final bool standalone;
  final String teacherUid;
  final bool schoolOverview;

  const AdminTeacherScheduleTab({
    Key? key,
    this.showAllBookings = false,
    this.teacherUid = '',
    this.standalone = false,
    this.schoolOverview = false,
  }) : super(key: key);

  @override
  _AdminTeacherScheduleTabState createState() =>
      _AdminTeacherScheduleTabState();
}

class _AdminTeacherScheduleTabState extends State<AdminTeacherScheduleTab> {
  TeacherAvailability _availability = TeacherAvailability(teacherUid: '');
  List<WeekBooking> _bookings = [];
  List<EnrollmentRecord> _enrollments = [];
  Map<String, List<StudentWeekProgress>> _learning = {};
  List<AppNotification> _notifications = [];
  DateTime _weekStart = EnrollmentService.weekStart(DateTime.now());
  bool _loading = true;
  bool _saving = false;
  String _teacherUid = '';
  String _staffPhone = '';
  DateTime? _selectAnchorDate;
  String? _selectAnchorTime;
  bool _selecting = false;
  final Set<String> _selectedKeys = {};

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final uid = widget.teacherUid.isNotEmpty
        ? widget.teacherUid
        : await AuthService.currentStaffUid();
    final availability = widget.schoolOverview
        ? TeacherAvailability(teacherUid: uid)
        : await TeacherScheduleService.load(uid);
    final bookings = widget.schoolOverview
        ? await EnrollmentService.staffWeekBookings(mineOnly: false)
        : widget.teacherUid.isNotEmpty
            ? await EnrollmentService.weekBookingsForTeacher(uid)
            : await EnrollmentService.staffWeekBookings(
                mineOnly: !widget.showAllBookings,
              );
    if (widget.standalone || widget.schoolOverview) {
      if (!mounted) return;
      setState(() {
        _teacherUid = uid;
        _availability = availability;
        _bookings = bookings;
        _enrollments = [];
        _learning = {};
        _staffPhone = '';
        _notifications = [];
        _loading = false;
      });
      return;
    }
    final profile = widget.teacherUid.isNotEmpty
        ? await AuthService.staffProfile(widget.teacherUid)
        : await AuthService.currentStaffProfile();
    final notifications = widget.teacherUid.isNotEmpty
        ? <AppNotification>[]
        : await NotificationService.listMine();
    final userIds = bookings
        .map((item) => item.userId)
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    final enrollments =
        await EnrollmentService.listEnrollments(memberIds: userIds);
    final learning = await EnrollmentService.learningByEnrollment(enrollments);
    if (!mounted) return;
    setState(() {
      _teacherUid = uid;
      _availability = availability;
      _bookings = bookings;
      _enrollments = enrollments;
      _learning = learning;
      _staffPhone = profile?['phone']?.toString() ?? '';
      _notifications = notifications.where((item) => !item.read).toList();
      _loading = false;
    });
  }

  bool _belongsOnMyCalendar(WeekBooking booking) {
    if (widget.schoolOverview || widget.showAllBookings) return true;
    if (_teacherUid.isEmpty) return false;
    return booking.teacherId == _teacherUid ||
        booking.nativeTeacherUid == _teacherUid;
  }

  bool _isSlotPast(DateTime date, String time) {
    final at = EnrollmentService.bookingDateTime(date, time);
    if (at == null) return false;
    return DateTime.now()
        .isAfter(at.add(Duration(minutes: EnrollmentService.lessonMinutes)));
  }

  bool _isBookingSettled(WeekBooking booking) {
    if (booking.status == 'rejected') return true;
    return booking.isConfirmed && _isSlotPast(booking.date, booking.time);
  }

  WeekBooking? _bookingAt(DateTime date, String time) {
    final day = EnrollmentService.dateOnly(date);
    WeekBooking? confirmed;
    WeekBooking? rejected;
    for (final booking in _bookings) {
      if (!_belongsOnMyCalendar(booking)) continue;
      if (EnrollmentService.dateOnly(booking.date) != day) continue;
      if (booking.time.trim() != time.trim()) continue;
      if (booking.isPending) return booking;
      if (booking.isConfirmed) confirmed ??= booking;
      if (booking.status == 'rejected') rejected ??= booking;
    }
    return confirmed ?? rejected;
  }

  void _toast(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontFamily: "NotoSansKR")),
        backgroundColor: error ? Palette.danger : Palette.success,
      ),
    );
  }

  Future<void> _openVideoForBooking(WeekBooking booking) async {
    // 이름이 보이는 칸(=대기 아님)이면 화상으로 연결한다.
    if (booking.isPending) {
      _toast('대기 중인 예약입니다. 아래에서 먼저 확정해 주세요.', error: true);
      return;
    }
    if (booking.status == 'rejected') {
      _toast('취소된 예약입니다.', error: true);
      return;
    }
    if (_isBookingSettled(booking)) {
      await _openPastBookingActions(booking);
      return;
    }
    if (booking.courseId.trim().isEmpty || booking.id.trim().isEmpty) {
      _toast('화상수업 정보를 찾을 수 없습니다.', error: true);
      return;
    }

    final url = EnrollmentService.meetingUrlForBooking(
      courseId: booking.courseId,
      bookingId: booking.id,
    );
    _toast('${booking.memberName.isEmpty ? '수강생' : booking.memberName} 화상수업을 엽니다.');
    // 팝업 차단을 피하려고 클릭 직후 바로 URL을 연다.
    await UrlUtil.open(url);

    final sessionId = booking.sessionId.trim().isNotEmpty
        ? booking.sessionId.trim()
        : EnrollmentService.sessionDocIdForBooking(booking.id);
    final profile = await AuthService.currentStaffProfile();
    final hostName = (profile?['name'] ?? '').toString().trim();
    await EnrollmentService.setSessionLive(
      sessionId: sessionId,
      isLive: true,
      hostName: hostName,
    );
  }

  Future<void> _openPastBookingActions(WeekBooking booking) async {
    final cancelled = booking.status == 'rejected';
    final action = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(cancelled ? '취소된 수업' : '완료된 수업',
            style: TextStyle(fontFamily: "Jalnan")),
        content: Text(
          [
            if (booking.memberName.isNotEmpty) booking.memberName,
            if (booking.weekNumber > 0) '${booking.weekNumber}회차',
            '${EnrollmentService.formatBookingDate(booking.date)} ${EnrollmentService.formatBookingTime(booking.time)}',
          ].join(' · '),
          style: TextStyle(fontFamily: "NotoSansKR", height: 1.5),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('닫기')),
          if (!cancelled)
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, 'feedback'),
              child: Text('피드백'),
            ),
        ],
      ),
    );
    if (action != 'feedback' || !mounted) return;
    final profile = await AuthService.currentStaffProfile();
    final teacherName = (profile?['name'] ?? '').toString().trim();
    final existing = await LessonFeedbackService.listForTeacher(_teacherUid);
    final saved = await LessonFeedbackService.showEditor(
      context: context,
      booking: booking,
      existing: LessonFeedbackService.forBooking(existing, booking.id),
      canWrite: true,
      teacherId: _teacherUid,
      teacherName: teacherName.isNotEmpty ? teacherName : '강사',
    );
    if (saved) _toast('피드백을 저장했습니다.');
  }

  Future<void> _onCellTap(DateTime date, String time) async {
    if (_saving) return;
    final existing = _bookingAt(date, time);
    if (existing != null) {
      await _openVideoForBooking(existing);
      return;
    }
    if (_availability.isOccupied(date, time)) {
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
    final existingNote = _availability.noteFor(date, time);
    final timeLabel = EnrollmentService.formatBookingTime(time);
    final dateLabel = EnrollmentService.formatBookingDate(date);
    final weekday = _availability.weekdayLabel(date);
    final noteController = TextEditingController(text: existingNote);

    final action = await showDialog<_SlotAction>(
      context: context,
      builder: (dialogContext) {
        Widget option(_SlotAction value, IconData icon, String title,
            String subtitle,
            {Color? iconColor}) {
          return ListTile(
            leading: Icon(icon, color: iconColor ?? Palette.darkTeal),
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
        options.add(option(
          _SlotAction.savePersonal,
          Icons.circle,
          existingNote.isEmpty ? '개인 일정으로 닫기' : '개인 일정 저장',
          '아래 사유를 빨간 점으로 표시하고 이 시간을 닫습니다.',
          iconColor: Palette.danger,
        ));

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
                  '수업은 20분입니다. 닫거나, 매주 같은 시간을 고정하거나, 사유를 적어 개인 일정을 표시할 수 있습니다.',
                  style: TextStyle(
                      fontFamily: "NotoSansKR",
                      fontSize: 13,
                      color: Palette.grey600),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: '개인 일정 사유',
                    hintText: '예: 병원, 출장',
                    helperText: '사유를 적으면 빨간 점으로 표시됩니다.',
                    helperMaxLines: 2,
                    border: OutlineInputBorder(),
                  ),
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
    final note = noteController.text.trim();
    noteController.dispose();
    if (action == null || !mounted) return;
    await _applySlotAction(action, date, time, note: note);
  }

  Future<void> _applySlotAction(
      _SlotAction action, DateTime date, String time,
      {String note = ''}) async {
    setState(() => _saving = true);
    String? error;
    switch (action) {
      case _SlotAction.savePersonal:
        if (note.isEmpty) {
          setState(() => _saving = false);
          _toast('개인 일정 사유를 입력해 주세요.', error: true);
          return;
        }
        error = await TeacherScheduleService.setClosed(
          teacherUid: _teacherUid,
          date: date,
          time: time,
          closed: true,
          note: note,
        );
        break;
      case _SlotAction.closeOnce:
        error = await TeacherScheduleService.setClosed(
          teacherUid: _teacherUid,
          date: date,
          time: time,
          closed: true,
          note: note,
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

  static const double _timeColWidth = 62;
  static const double _dayHeaderHeight = 32;
  static const double _cellHeight = 26;
  static const double _rowPitch = 28;

  List<DateTime> get _days =>
      List.generate(7, (i) => _weekStart.add(Duration(days: i)));

  String _historyLabel(WeekBooking booking) {
    final cancelled = booking.status == 'rejected';
    final status = cancelled ? '취소' : '완료';
    final raw = booking.memberName.trim().isNotEmpty
        ? booking.memberName.trim()
        : booking.email.trim();
    final name = raw.isEmpty
        ? status
        : (raw.length > 5 ? raw.substring(0, 5) : raw);
    if (raw.isEmpty) return status;
    if (booking.weekNumber <= 0) return '$name\n$status';
    return '$name\n${booking.weekNumber}회·$status';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.standalone) {
      return ListView(
        physics: _selecting
            ? const NeverScrollableScrollPhysics()
            : const ClampingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(8, 2, 8, 8),
        children: [
          _weekBar(compact: true),
          _monthSummary(compact: true),
          SizedBox(height: 6),
          _grid(),
        ],
      );
    }

    return ListView(
      physics: _selecting
          ? const NeverScrollableScrollPhysics()
          : const ClampingScrollPhysics(),
      padding: EdgeInsets.all(20),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      widget.schoolOverview
                          ? '전체 스케줄'
                          : (widget.teacherUid.isEmpty ? '내 스케줄' : '스케줄 · 예약'),
                      style: TextStyle(fontFamily: "Jalnan", fontSize: 18)),
                  SizedBox(height: 8),
                  Text(
                    widget.schoolOverview
                        ? '학원 전체 예약을 같은 시간표로 봅니다. 숫자는 그 시간 건수이고, 색은 상태입니다. 숫자를 누르면 해당 수강생이 나옵니다.'
                        : widget.showAllBookings
                            ? '화상수업은 20분입니다. 6:00 AM–11:00 PM 칸을 눌러 이번만 닫거나 매주 같은 시간을 루틴으로 고정하세요.\n'
                                '학원 전체 예약이 칸과 아래 목록에 함께 보입니다. 담당이 비어 있으면 컨펌 시 내 스케줄로 연결됩니다.'
                            : '화상수업은 20분입니다. 칸을 누르거나 드래그해서 여러 시간을 한꺼번에 닫을 수 있습니다.\n'
                                '고정한 루틴은 언제든 해제할 수 있고, 수강생은 열린 시간만 예약합니다.',
                    style: TextStyle(
                        fontFamily: "NotoSansKR",
                        fontSize: 13,
                        color: Palette.grey600),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12),
            if (!widget.schoolOverview)
              OutlinedButton.icon(
                onPressed: () => AdminTeacherSchedulePage.openNewScreen(
                  context,
                  showAllBookings: widget.showAllBookings,
                  teacherUid: widget.teacherUid,
                ),
                icon: Icon(Icons.open_in_new, size: 18),
                label: Text('새 화면으로 열기',
                    style: TextStyle(fontFamily: "NotoSansKR")),
              ),
          ],
        ),
        SizedBox(height: 16),
        if (!widget.schoolOverview && widget.teacherUid.isEmpty)
          ..._staffAlerts(),
        if (widget.schoolOverview) _overviewWeekSummary() else _monthSummary(),
        SizedBox(height: 12),
        _weekBar(),
        SizedBox(height: 8),
        _legendRow(),
        SizedBox(height: 16),
        _grid(),
        if (!widget.schoolOverview) ...[
        SizedBox(height: 28),
        Text('수업 예약',
            style: TextStyle(fontFamily: "Jalnan", fontSize: 16)),
        SizedBox(height: 8),
        Text(
          widget.showAllBookings
              ? '회원이 신청한 회차 수업입니다. 날짜·시간을 확인하고 컨펌하세요.'
              : '내 담당 수강생과, 다른 강사 담당이지만 내 시간에 신청한 타 수강생 예약이 함께 보입니다. 타 수강생은 보라색입니다.',
          style: TextStyle(
              fontFamily: "NotoSansKR", fontSize: 13, color: Palette.grey600),
        ),
        SizedBox(height: 12),
        _bookingList(),
        ],
      ],
    );
  }

  TeacherMonthStats get _monthStats => TeacherMonthStats.fromBookings(
        bookings: _bookings,
        teacherUid: _teacherUid,
        isCompleted: (booking) =>
            booking.isConfirmed && _isSlotPast(booking.date, booking.time),
      );

  Widget _monthSummary({bool compact = false}) {
    return TeacherMonthLessonSummary(
      stats: _monthStats,
      compact: compact,
      loading: _loading,
    );
  }

  Widget _weekBar({bool compact = false}) {
    return Row(
      children: [
        IconButton(
          tooltip: '이전 주',
          visualDensity: compact ? VisualDensity.compact : null,
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontFamily: "NotoSansKR", fontSize: compact ? 12 : 13),
          ),
        ),
        IconButton(
          tooltip: '다음 주',
          visualDensity: compact ? VisualDensity.compact : null,
          onPressed: () {
            setState(() {
              _weekStart = _weekStart.add(Duration(days: 7));
            });
          },
          icon: Icon(Icons.chevron_right),
        ),
        if (compact) ...[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Palette.danger,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 4),
          Text('개인',
              style: TextStyle(
                  fontFamily: "NotoSansKR",
                  fontSize: 11,
                  color: Palette.grey600)),
          const NotificationBellButton(),
          IconButton(
            tooltip: '새로고침',
            visualDensity: VisualDensity.compact,
            onPressed: _loading ? null : _refresh,
            icon: Icon(Icons.refresh, size: 18),
          ),
        ] else
          OutlinedButton.icon(
            onPressed: _loading ? null : _refresh,
            icon: Icon(Icons.refresh, size: 18),
            label: Text('새로고침', style: TextStyle(fontFamily: "NotoSansKR")),
          ),
      ],
    );
  }

  Widget _legendRow() {
    if (widget.schoolOverview) {
      return Wrap(
        spacing: 12,
        runSpacing: 6,
        children: [
          _legend(Palette.warning.withValues(alpha: 0.16), Palette.warning,
              '예약'),
          _legend(Palette.primary.withValues(alpha: 0.12), Palette.primary,
              '확정'),
          _legend(Palette.success.withValues(alpha: 0.14), Palette.success,
              '완료'),
          _legend(Palette.grey200, Palette.grey400, '취소'),
        ],
      );
    }
    return Wrap(
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
        _legend(Palette.grey200, Palette.grey400, '완료 · 취소'),
        _legend(Palette.grey100, Palette.grey300, '지난 시간'),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Palette.danger,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 6),
            Text('개인 일정',
                style: TextStyle(fontFamily: "NotoSansKR", fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _grid() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final rowH = widget.schoolOverview ? 36.0 : _rowPitch;
    final cellH = widget.schoolOverview ? 34.0 : _cellHeight;
    return Listener(
      onPointerUp: (_) => _finishSelect(),
      onPointerCancel: (_) => _finishSelect(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              SizedBox(width: _timeColWidth, height: _dayHeaderHeight),
              ...EnrollmentService.bookingTimeSlots
                  .map((t) => _timeLabel(t, height: rowH)),
            ],
          ),
          Expanded(
            child: Column(
              children: [
                Row(
                  children: _days
                      .map((d) => Expanded(child: _dayHeader(d)))
                      .toList(),
                ),
                ...EnrollmentService.bookingTimeSlots.map(
                  (t) => _timeCells(t, height: cellH),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _canToggleSlot(DateTime date, String time) {
    if (widget.schoolOverview) return false;
    if (_isSlotPast(date, time)) return false;
    if (_bookingAt(date, time) != null) return false;
    if (_availability.isOccupied(date, time)) return false;
    return true;
  }

  void _beginSelect(DateTime date, String time) {
    if (_saving || !_canToggleSlot(date, time)) return;
    _selecting = true;
    _selectAnchorDate = EnrollmentService.dateOnly(date);
    _selectAnchorTime = time;
    _applySelectRect(date, time);
  }

  void _hoverSelect(DateTime date, String time) {
    if (!_selecting) return;
    _applySelectRect(date, time);
  }

  void _applySelectRect(DateTime date, String time) {
    final anchorDate = _selectAnchorDate;
    final anchorTime = _selectAnchorTime;
    if (anchorDate == null || anchorTime == null) return;
    final slots = EnrollmentService.bookingTimeSlots;
    final aTime = slots.indexOf(anchorTime);
    final bTime = slots.indexOf(time);
    if (aTime < 0 || bTime < 0) return;
    final startTime = aTime < bTime ? aTime : bTime;
    final endTime = aTime < bTime ? bTime : aTime;
    var startDay = EnrollmentService.dateOnly(anchorDate);
    var endDay = EnrollmentService.dateOnly(date);
    if (endDay.isBefore(startDay)) {
      final swap = startDay;
      startDay = endDay;
      endDay = swap;
    }
    final keys = <String>{};
    for (var day = startDay;
        !day.isAfter(endDay);
        day = day.add(const Duration(days: 1))) {
      for (var i = startTime; i <= endTime; i++) {
        final slotTime = slots[i];
        if (!_canToggleSlot(day, slotTime)) continue;
        keys.add(TeacherScheduleService.slotKey(day, slotTime));
      }
    }
    setState(() {
      _selectedKeys
        ..clear()
        ..addAll(keys);
    });
  }

  Future<void> _finishSelect() async {
    if (!_selecting) return;
    final keys = Set<String>.from(_selectedKeys);
    _selecting = false;
    _selectAnchorDate = null;
    _selectAnchorTime = null;
    if (keys.isEmpty) return;
    if (keys.length == 1) {
      final parsed = _parseSlotKey(keys.first);
      setState(() => _selectedKeys.clear());
      if (parsed != null) await _onCellTap(parsed.date, parsed.time);
      return;
    }
    await _onMultiSelect(keys);
    if (mounted) setState(() => _selectedKeys.clear());
  }

  _PickedSlot? _parseSlotKey(String key) {
    final at = key.lastIndexOf('_');
    if (at <= 0) return null;
    final date = DateTime.tryParse(key.substring(0, at));
    final time = key.substring(at + 1);
    if (date == null || time.isEmpty) return null;
    return _PickedSlot(EnrollmentService.dateOnly(date), time);
  }

  Future<void> _onMultiSelect(Set<String> keys) async {
    final slots = <_PickedSlot>[];
    for (final key in keys) {
      final parsed = _parseSlotKey(key);
      if (parsed != null) slots.add(parsed);
    }
    if (slots.isEmpty) return;
    slots.sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      if (byDate != 0) return byDate;
      return a.time.compareTo(b.time);
    });

    final noteController = TextEditingController();
    final action = await showDialog<_SlotAction>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Palette.white,
        surfaceTintColor: Palette.white,
        title: Text('선택한 ${slots.length}칸',
            style: TextStyle(fontFamily: "Jalnan", fontSize: 16)),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '드래그한 시간을 한꺼번에 닫거나 다시 열 수 있습니다. 사유를 적으면 빨간 점으로 개인 일정이 표시됩니다.',
                style: TextStyle(
                    fontFamily: "NotoSansKR",
                    fontSize: 13,
                    color: Palette.grey600),
              ),
              SizedBox(height: 12),
              TextField(
                controller: noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: '개인 일정 사유 (선택)',
                  hintText: '예: 병원, 출장',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 8),
              ListTile(
                leading: Icon(Icons.event_busy, color: Palette.darkTeal),
                title: Text('이번만 닫기',
                    style: TextStyle(fontFamily: "NotoSansKR")),
                subtitle: Text('선택한 칸만 이번 주에 닫습니다.',
                    style: TextStyle(
                        fontFamily: "NotoSansKR",
                        fontSize: 12,
                        color: Palette.grey600)),
                onTap: () =>
                    Navigator.pop(dialogContext, _SlotAction.closeOnce),
              ),
              ListTile(
                leading: Icon(Icons.circle, color: Palette.danger, size: 16),
                title: Text('개인 일정으로 닫기',
                    style: TextStyle(fontFamily: "NotoSansKR")),
                subtitle: Text('사유를 빨간 점으로 표시하고 선택한 칸을 닫습니다.',
                    style: TextStyle(
                        fontFamily: "NotoSansKR",
                        fontSize: 12,
                        color: Palette.grey600)),
                onTap: () =>
                    Navigator.pop(dialogContext, _SlotAction.savePersonal),
              ),
              ListTile(
                leading: Icon(Icons.push_pin, color: Palette.darkTeal),
                title: Text('매주 이 시간 닫기',
                    style: TextStyle(fontFamily: "NotoSansKR")),
                subtitle: Text('각 칸의 요일·시간을 매주 반복해서 닫습니다.',
                    style: TextStyle(
                        fontFamily: "NotoSansKR",
                        fontSize: 12,
                        color: Palette.grey600)),
                onTap: () =>
                    Navigator.pop(dialogContext, _SlotAction.pinRoutine),
              ),
              ListTile(
                leading: Icon(Icons.lock_open, color: Palette.darkTeal),
                title: Text('다시 열기',
                    style: TextStyle(fontFamily: "NotoSansKR")),
                subtitle: Text('선택한 칸의 닫기·루틴을 해제합니다.',
                    style: TextStyle(
                        fontFamily: "NotoSansKR",
                        fontSize: 12,
                        color: Palette.grey600)),
                onTap: () =>
                    Navigator.pop(dialogContext, _SlotAction.openOnce),
              ),
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
      ),
    );
    final note = noteController.text.trim();
    noteController.dispose();
    if (action == null || !mounted) return;
    if (action == _SlotAction.savePersonal && note.isEmpty) {
      _toast('개인 일정 사유를 입력해 주세요.', error: true);
      return;
    }

    setState(() => _saving = true);
    String? error;
    final dates = slots.map((s) => s.date).toList();
    final times = slots.map((s) => s.time).toList();
    if (action == _SlotAction.pinRoutine) {
      error = await TeacherScheduleService.setRoutineClosedMany(
        teacherUid: _teacherUid,
        dates: dates,
        times: times,
        closed: true,
      );
    } else if (action == _SlotAction.closeOnce ||
        action == _SlotAction.savePersonal) {
      error = await TeacherScheduleService.setClosedMany(
        teacherUid: _teacherUid,
        dates: dates,
        times: times,
        closed: true,
        note: note,
      );
    } else {
      error = await TeacherScheduleService.setRoutineClosedMany(
        teacherUid: _teacherUid,
        dates: dates,
        times: times,
        closed: false,
      );
      if (error == null) {
        error = await TeacherScheduleService.setClosedMany(
          teacherUid: _teacherUid,
          dates: dates,
          times: times,
          closed: false,
        );
      }
    }
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      _toast(error, error: true);
      return;
    }
    _toast('${slots.length}칸을 반영했습니다.');
    await _refresh();
  }

  Widget _bookingList() {
    if (_loading) return SizedBox.shrink();
    if (_bookings.isEmpty) {
      return Text('아직 들어온 예약이 없습니다.',
          style: TextStyle(fontFamily: "NotoSansKR", color: Palette.grey500));
    }
    return Column(
      children: _bookings.map(_bookingCard).toList(),
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
      height: _dayHeaderHeight,
      child: Center(
        child: Text(
          EnrollmentService.formatBookingDate(day).replaceFirst(
              RegExp(r'^\d{4}\.'), ''),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontFamily: "NotoSansKR", fontSize: 10),
        ),
      ),
    );
  }

  Widget _timeLabel(String time, {double? height}) {
    return SizedBox(
      width: _timeColWidth,
      height: height ?? _rowPitch,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          EnrollmentService.formatBookingTime(time),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: "Jalnan",
            fontSize: 10,
            color: Palette.grey700,
          ),
        ),
      ),
    );
  }

  Widget _timeCells(String time, {double? height}) {
    return Row(
      children: _days
          .map((day) => Expanded(
                child: _cell(day, time, height: height),
              ))
          .toList(),
    );
  }

  Widget _cell(DateTime date, String time, {double? height}) {
    if (widget.schoolOverview) {
      return _overviewCell(date, time, height: height);
    }
    final booking = _bookingAt(date, time);
    final personalNote = _availability.noteFor(date, time);
    final hasPersonal = personalNote.isNotEmpty && booking == null;
    final occupied = booking != null || _availability.isOccupied(date, time);
    final closed = _availability.isClosed(date, time);
    final routine = _availability.isRoutine(date, time);
    final exception = _availability.isException(date, time);
    final slotPast = _isSlotPast(date, time);
    final pastEmpty = slotPast && !closed && !occupied;
    Color fill = Palette.white;
    Color border = Palette.grey300;
    Color textColor = Palette.secondaryDark;
    String label = '열림';
    if (booking != null && booking.status == 'rejected') {
      fill = Palette.grey200;
      border = Palette.grey400;
      textColor = Palette.grey500;
      label = _historyLabel(booking);
    } else if (booking != null && booking.isPending) {
      final guest = booking.isGuestFor(_teacherUid);
      fill = guest
          ? Palette.accent.withValues(alpha: 0.14)
          : Palette.warning.withValues(alpha: 0.16);
      border = guest ? Palette.accent : Palette.warning;
      textColor = guest ? Palette.accent : Palette.warning;
      label = guest ? '타·대기' : booking.calendarLabel;
    } else if (booking != null && slotPast) {
      fill = Palette.grey200;
      border = Palette.grey400;
      textColor = Palette.grey500;
      label = _historyLabel(booking);
    } else if (pastEmpty) {
      fill = Palette.grey100;
      border = Palette.grey300;
      textColor = Palette.grey500;
      label = '';
    } else if (booking != null) {
      final guest = booking.isGuestFor(_teacherUid);
      fill = guest
          ? Palette.accent.withValues(alpha: 0.16)
          : Palette.primary.withValues(alpha: 0.12);
      border = guest ? Palette.accent : Palette.primary;
      textColor = guest ? Palette.accent : Palette.primaryDark;
      label = booking.calendarLabel;
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
      label = '매주 닫힘';
    } else if (closed) {
      fill = Palette.grey200;
      border = Palette.grey400;
      textColor = Palette.grey600;
      label = '닫힘';
    }

    final settled = booking != null && _isBookingSettled(booking);
    final canOpenBooking =
        booking != null && booking.isConfirmed && !settled;
    final canToggleSlot = _canToggleSlot(date, time);
    final selected =
        _selectedKeys.contains(TeacherScheduleService.slotKey(date, time));
    final tappable = canOpenBooking ||
        canToggleSlot ||
        booking != null ||
        (booking != null && settled);
    if (selected) {
      fill = Palette.secondary.withValues(alpha: 0.18);
      border = Palette.secondaryDark;
      textColor = Palette.secondaryDark;
    }

    return Padding(
      padding: EdgeInsets.all(1),
      child: Material(
        color: Colors.transparent,
        child: Semantics(
          button: true,
          excludeSemantics: true,
          enabled: tappable,
          label:
              '${EnrollmentService.formatBookingDate(date)} ${EnrollmentService.formatBookingTime(time)} ${label.isEmpty ? '지난 시간' : label.replaceAll('\n', ' ')}${hasPersonal ? ' · $personalNote' : ''}${canOpenBooking ? ' · 화상수업 입장' : ''}',
          child: MouseRegion(
            onEnter: (_) => _hoverSelect(date, time),
            child: Listener(
              onPointerDown: canToggleSlot
                  ? (event) {
                      if (event.buttons == 1) _beginSelect(date, time);
                    }
                  : null,
              child: InkWell(
                onTap: (!tappable || canToggleSlot)
                    ? null
                    : () => _onCellTap(date, time),
                borderRadius: BorderRadius.circular(4),
                child: _slotFace(
                  height: height ?? _cellHeight,
                  fill: fill,
                  border: border,
                  selected: selected,
                  label: label,
                  textColor: textColor,
                  emphasize: canOpenBooking || settled,
                  underline: canOpenBooking,
                  personalNote: hasPersonal ? personalNote : '',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<WeekBooking> _bookingsAtSlot(DateTime date, String time) {
    final day = EnrollmentService.dateOnly(date);
    return _bookings.where((booking) {
      return EnrollmentService.dateOnly(booking.date) == day &&
          booking.time.trim() == time.trim();
    }).toList();
  }

  _OverviewKind? _overviewKindOf(WeekBooking booking) {
    if (booking.status == 'rejected') return _OverviewKind.cancelled;
    if (booking.isPending) return _OverviewKind.pending;
    if (booking.isConfirmed && _isSlotPast(booking.date, booking.time)) {
      return _OverviewKind.completed;
    }
    if (booking.isConfirmed) return _OverviewKind.confirmed;
    return null;
  }

  Color _overviewColor(_OverviewKind kind) {
    switch (kind) {
      case _OverviewKind.pending:
        return Palette.warning;
      case _OverviewKind.confirmed:
        return Palette.primary;
      case _OverviewKind.completed:
        return Palette.success;
      case _OverviewKind.cancelled:
        return Palette.grey500;
    }
  }

  String _overviewLabel(_OverviewKind kind) {
    switch (kind) {
      case _OverviewKind.pending:
        return '예약';
      case _OverviewKind.confirmed:
        return '확정';
      case _OverviewKind.completed:
        return '완료';
      case _OverviewKind.cancelled:
        return '취소';
    }
  }

  Map<_OverviewKind, int> _overviewCounts(Iterable<WeekBooking> items) {
    final counts = <_OverviewKind, int>{};
    for (final booking in items) {
      final kind = _overviewKindOf(booking);
      if (kind == null) continue;
      counts[kind] = (counts[kind] ?? 0) + 1;
    }
    return counts;
  }

  Widget _overviewWeekSummary() {
    final start = EnrollmentService.dateOnly(_weekStart);
    final end = start.add(const Duration(days: 7));
    final week = _bookings.where((booking) {
      final day = EnrollmentService.dateOnly(booking.date);
      return !day.isBefore(start) && day.isBefore(end);
    });
    final counts = _overviewCounts(week);
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: _OverviewKind.values.map((kind) {
        final count = counts[kind] ?? 0;
        return Text(
          '${_overviewLabel(kind)} $count건',
          style: TextStyle(
            fontFamily: "NotoSansKR",
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: count == 0 ? Palette.grey500 : _overviewColor(kind),
          ),
        );
      }).toList(),
    );
  }

  Widget _overviewCell(DateTime date, String time, {double? height}) {
    final items = _bookingsAtSlot(date, time);
    final counts = _overviewCounts(items);
    final past = _isSlotPast(date, time);
    final h = height ?? 34;
    return Padding(
      padding: const EdgeInsets.all(1),
      child: Container(
        width: double.infinity,
        height: h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: items.isEmpty && past ? Palette.grey100 : Palette.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: items.isEmpty ? Palette.grey300 : Palette.grey400,
          ),
        ),
        child: items.isEmpty
            ? const SizedBox.shrink()
            : Wrap(
                alignment: WrapAlignment.center,
                spacing: 2,
                runSpacing: 0,
                children: _OverviewKind.values
                    .where((kind) => (counts[kind] ?? 0) > 0)
                    .map((kind) {
                  final color = _overviewColor(kind);
                  final count = counts[kind] ?? 0;
                  return InkWell(
                    onTap: () =>
                        _showOverviewStudents(date, time, kind, items),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 3, vertical: 1),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontFamily: "Jalnan",
                          fontSize: 13,
                          color: color,
                          decoration: TextDecoration.underline,
                          decorationColor: color,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
      ),
    );
  }

  Future<void> _showOverviewStudents(
    DateTime date,
    String time,
    _OverviewKind kind,
    List<WeekBooking> slotItems,
  ) async {
    final items = slotItems
        .where((booking) => _overviewKindOf(booking) == kind)
        .toList()
      ..sort((a, b) => a.memberName.compareTo(b.memberName));
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          '${EnrollmentService.formatBookingDate(date)} ${EnrollmentService.formatBookingTime(time)} · ${_overviewLabel(kind)} ${items.length}건',
          style: TextStyle(fontFamily: "Jalnan", fontSize: 16),
        ),
        content: SizedBox(
          width: 420,
          child: items.isEmpty
              ? Text('해당하는 수강생이 없습니다.',
                  style: TextStyle(fontFamily: "NotoSansKR"))
              : ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 420),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, index) {
                      final booking = items[index];
                      final course = OnlineCourse.findById(booking.courseId);
                      final teacher = booking.nativeTeacherName.trim().isNotEmpty
                          ? booking.nativeTeacherName
                          : booking.assignedTeacherName;
                      final name = booking.memberName.trim().isEmpty
                          ? (booking.email.isEmpty ? '이름 미등록' : booking.email)
                          : booking.memberName;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(name,
                            style: TextStyle(
                                fontFamily: "NotoSansKR",
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                        subtitle: Text(
                          [
                            if (booking.email.isNotEmpty) booking.email,
                            if (course != null) course.title,
                            if (teacher.trim().isNotEmpty) '담당 $teacher',
                            if (booking.weekNumber > 0)
                              '${booking.weekNumber}회차',
                          ].join(' · '),
                          style: TextStyle(
                              fontFamily: "NotoSansKR",
                              fontSize: 12,
                              color: Palette.grey600),
                        ),
                        onTap: () {
                          Navigator.pop(dialogContext);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StudentDetailPage(
                                member: {
                                  'uid': booking.userId,
                                  'name': booking.memberName,
                                  'email': booking.email,
                                  'phone': booking.phone,
                                  'nativeTeacherName': teacher,
                                },
                                teacherName: teacher,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('닫기', style: TextStyle(fontFamily: "NotoSansKR")),
          ),
        ],
      ),
    );
  }

  Widget _slotFace({
    required double height,
    required Color fill,
    required Color border,
    required bool selected,
    required String label,
    required Color textColor,
    required bool emphasize,
    required bool underline,
    required String personalNote,
  }) {
    final face = Container(
      width: double.infinity,
      height: height,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: "NotoSansKR",
                fontSize: 8,
                height: 1.15,
                fontWeight: emphasize ? FontWeight.w700 : FontWeight.w400,
                color: textColor,
                decoration: underline ? TextDecoration.underline : null,
              ),
            ),
          ),
          if (personalNote.isNotEmpty)
            Positioned(
              top: 3,
              left: 3,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Palette.danger,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
    if (personalNote.isEmpty) return face;
    return Tooltip(
      message: personalNote,
      waitDuration: const Duration(milliseconds: 250),
      child: face,
    );
  }

  Widget _bookingCard(WeekBooking booking) {
    final course = OnlineCourse.findById(booking.courseId);
    final settled = _isBookingSettled(booking);
    final cancelled = booking.status == 'rejected';
    return Card(
      margin: EdgeInsets.only(bottom: 10),
      color: settled ? Palette.grey50 : null,
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
                        fontFamily: "NotoSansKR",
                        fontWeight: FontWeight.bold,
                        color: settled ? Palette.grey600 : null),
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
                  cancelled
                      ? '취소'
                      : settled
                          ? '완료'
                          : booking.statusLabel,
                  style: TextStyle(
                    fontFamily: "NotoSansKR",
                    fontSize: 12,
                    color: cancelled || settled
                        ? Palette.grey500
                        : booking.isConfirmed
                            ? Palette.success
                            : Palette.warning,
                  ),
                ),
              ],
            ),
            SizedBox(height: 6),
            Text(
              '${course?.title ?? booking.courseId} · ${booking.weekNumber}회차'
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
            SizedBox(height: 10),
            StudentLearningProgressPanel(
              enrollments: _enrollments
                  .where((item) =>
                      item.userId == booking.userId &&
                      item.courseId == booking.courseId)
                  .toList(),
              progressByEnrollment: _learning,
              onlyWeekNumber: booking.weekNumber,
              dense: true,
            ),
            if (booking.isPending) ...[
              SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Palette.darkTeal,
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
            ] else ...[
              SizedBox(height: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Palette.darkTeal,
                  foregroundColor: Palette.white,
                ),
                onPressed: () => _openVideoForBooking(booking),
                icon: Icon(Icons.videocam, size: 18),
                label: Text('화상수업 입장',
                    style: TextStyle(fontFamily: "NotoSansKR")),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PickedSlot {
  final DateTime date;
  final String time;

  _PickedSlot(this.date, this.time);
}

enum _SlotAction {
  closeOnce,
  savePersonal,
  openOnce,
  pinRoutine,
  unpinRoutine,
  openThisDay,
  closeThisWeek,
}
