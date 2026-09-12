import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gi_english_website/class/OnlineCourse.dart';
import 'package:gi_english_website/class/OnlineNativeTeacher.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/EnrollmentService.dart';
import 'package:gi_english_website/util/LessonFeedbackService.dart';
import 'package:gi_english_website/util/TeacherScheduleService.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/UrlIUtil.dart';
import 'package:gi_english_website/widget/MobileSchoolLayout.dart';
import 'package:gi_english_website/widget/OnlineProgramSideMenu.dart';
import 'package:gi_english_website/widget/WebSchoolLayout.dart';

import '../util/WidgetUtil.dart';

class OnlineCourseDetailPage extends StatefulWidget {
  final OnlineCourse course;

  const OnlineCourseDetailPage({Key? key, required this.course})
      : super(key: key);

  @override
  _OnlineCourseDetailPageState createState() => _OnlineCourseDetailPageState();
}

class _OnlineCourseDetailPageState extends State<OnlineCourseDetailPage> {
  List<OnlineLesson> _lessons = [];
  List<OnlineSession> _sessions = [];
  List<OnlineWeek> _weeks = [];
  EnrollmentRecord? _enrollment;
  Map<String, List<String>> _weekProgress = {};
  List<WeekBooking> _bookings = [];
  List<LessonFeedback> _feedbacks = [];
  TeacherAvailability _teacherAvailability =
      TeacherAvailability(teacherUid: '');
  final Map<String, DateTime> _selectedDates = {};
  final Map<String, String> _selectedTimes = {};
  final Map<String, OnlineNativeTeacher> _bookingTeacher = {};
  final Map<String, TeacherAvailability> _availabilityByUid = {};
  bool _isLoading = true;
  bool _savingChecklist = false;
  bool _submittingBooking = false;
  Timer? _sessionTicker;

  @override
  void initState() {
    super.initState();
    _loadData();
    _sessionTicker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _sessionTicker?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    await AuthService.selectableNativeTeachers();
    final lessons = await EnrollmentService.lessons(widget.course.id);
    final sessions = await EnrollmentService.sessions(
      widget.course.id,
      userId: AuthService.currentUser?.uid,
    );
    final enrollment =
        await EnrollmentService.myEnrollmentForCourse(widget.course.id);
    final weeks = await EnrollmentService.weeks(
      widget.course.id,
      ensureThrough: enrollment?.unlockedSessionNumber ?? 1,
    );
    Map<String, List<String>> progress = {};
    List<WeekBooking> bookings = [];
    List<LessonFeedback> feedbacks = [];
    TeacherAvailability availability = TeacherAvailability(teacherUid: '');
    if (enrollment != null) {
      progress = await EnrollmentService.weekProgress(enrollment.id);
      bookings =
          await EnrollmentService.myWeekBookings(courseId: widget.course.id);
      feedbacks = await LessonFeedbackService.listForStudent(
          courseId: widget.course.id);
      final teacherUid =
          await TeacherScheduleService.resolveTeacherUid(
        nativeTeacherUid: enrollment.nativeTeacherUid,
        nativeTeacherId: enrollment.nativeTeacherId,
      );
      availability = await TeacherScheduleService.load(teacherUid);
      if (teacherUid.isNotEmpty) {
        _availabilityByUid[teacherUid] = availability;
      }
    }
    if (!mounted) return;
    setState(() {
      _lessons = lessons;
      _sessions = sessions;
      _weeks = weeks;
      _enrollment = enrollment;
      _weekProgress = progress;
      _bookings = bookings;
      _feedbacks = feedbacks;
      _teacherAvailability = availability;
      _isLoading = false;
    });
  }

  int get _currentSessionNumber {
    final enrollment = _enrollment;
    if (enrollment == null) return 1;
    return enrollment.unlockedSessionNumber;
  }

  OnlineNativeTeacher? get _assignedNativeTeacher =>
      _enrollment?.nativeTeacher;

  List<String> _checkedIds(String weekId) =>
      List<String>.from(_weekProgress[weekId] ?? const []);

  Future<void> _toggleChecklist(OnlineWeek week, String itemId, bool checked) async {
    final enrollment = _enrollment;
    if (enrollment == null || _savingChecklist) return;

    final next = _checkedIds(week.id);
    if (checked) {
      if (!next.contains(itemId)) next.add(itemId);
    } else {
      next.remove(itemId);
    }

    setState(() {
      _weekProgress[week.id] = next;
      _savingChecklist = true;
    });

    final error = await EnrollmentService.setWeekChecklist(
      enrollmentId: enrollment.id,
      weekId: week.id,
      checkedItemIds: next,
      week: week,
    );
    if (!mounted) return;
    setState(() {
      _savingChecklist = false;
    });
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error, style: TextStyle(fontFamily: "NotoSansKR")),
          backgroundColor: Palette.danger,
        ),
      );
      await _loadData();
    }
  }

  bool _readyToBook(OnlineWeek week, List<String> checked) {
    return EnrollmentService.isWeekReadyToBook(week, checked);
  }

  WeekBooking? _bookingFor(String weekId) {
    for (final booking in _bookings) {
      if (booking.weekId == weekId &&
          (booking.isPending || booking.isConfirmed)) {
        return booking;
      }
    }
    return null;
  }

  Future<void> _submitBooking(OnlineWeek week) async {
    final enrollment = _enrollment;
    if (enrollment == null || _submittingBooking) return;
    final date = _selectedDates[week.id];
    final time = _selectedTimes[week.id];
    if (date == null || time == null || time.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('날짜와 시간을 선택해주세요.',
              style: TextStyle(fontFamily: "NotoSansKR")),
          backgroundColor: Palette.danger,
        ),
      );
      return;
    }
    setState(() {
      _submittingBooking = true;
    });
    final error = await EnrollmentService.requestWeekBooking(
      enrollment: enrollment,
      week: week,
      date: date,
      time: time,
      teacher: _teacherForWeek(week.id),
    );
    if (!mounted) return;
    setState(() {
      _submittingBooking = false;
    });
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error, style: TextStyle(fontFamily: "NotoSansKR")),
          backgroundColor: Palette.danger,
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('예약이 신청되었습니다. 강사 확인을 기다려 주세요.',
            style: TextStyle(fontFamily: "NotoSansKR")),
        backgroundColor: Palette.success,
      ),
    );
    await _loadData();
  }

  void _showProblemPlaceholder() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'HTML 문제 페이지가 연결되면 이 버튼으로 열립니다.',
          style: TextStyle(fontFamily: "NotoSansKR"),
        ),
        backgroundColor: Palette.secondaryDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    MediaQueryData mediaQueryData = MediaQuery.of(context);
    Size size = mediaQueryData.size;
    double width = size.width;
    if (width > 768) {
      return WebSchoolLayout(content: scrollView());
    } else {
      return MobileSchoolLayout(content: mobileScrollView());
    }
  }

  Widget scrollView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          contentGroup(),
          MyWidget.footer(),
        ],
      ),
    );
  }

  Widget mobileScrollView() {
    return SingleChildScrollView(
      child: Container(
        color: Palette.white,
        child: Column(
          children: [
            OnlineProgramSideMenu(selectedIndex: 1, isMobile: true),
            content(),
          ],
        ),
      ),
    );
  }

  Widget contentGroup() {
    return Container(
      color: Palette.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 232,
            child: OnlineProgramSideMenu(selectedIndex: 1),
          ),
          Expanded(child: content()),
        ],
      ),
    );
  }

  Widget content() {
    final course = widget.course;

    return Container(
      alignment: Alignment.topLeft,
      width: double.maxFinite,
      padding: EdgeInsets.all(20),
      color: Palette.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            course.title,
            style: TextStyle(fontFamily: "Jalnan", fontSize: 20),
          ),
          WidgetUtil.myDivider(),
          SizedBox(height: 20),
          Text(
            course.subtitle,
            style: TextStyle(
              fontFamily: "Jalnan",
              fontSize: 15,
              color: course.accentColor,
            ),
          ),
          SizedBox(height: 16),
          Text(
            course.highlights.map((line) => "• $line").join("\n"),
            style: TextStyle(
              fontFamily: "NotoSansKR",
              fontSize: 14,
              color: Palette.black,
              height: 1.6,
            ),
          ),
          SizedBox(height: 32),
          meetingSection(),
          SizedBox(height: 32),
          weekSection(),
          if (_weeks.isEmpty) ...[
            SizedBox(height: 32),
            lessonSection(),
          ],
          SizedBox(height: 40),
        ],
      ),
    );
  }

  OnlineNativeTeacher? _teacherForWeek(String weekId) {
    return _bookingTeacher[weekId] ?? _assignedNativeTeacher;
  }

  TeacherAvailability _availabilityForWeek(String weekId) {
    final uid = _teacherForWeek(weekId)?.accountUid ?? '';
    if (uid.isNotEmpty && _availabilityByUid.containsKey(uid)) {
      return _availabilityByUid[uid]!;
    }
    return _teacherAvailability;
  }

  bool _isOtherTeacher(String weekId) {
    final selected = _teacherForWeek(weekId);
    final assigned = _assignedNativeTeacher;
    if (selected == null || assigned == null) return false;
    if (selected.accountUid.isNotEmpty && assigned.accountUid.isNotEmpty) {
      return selected.accountUid != assigned.accountUid;
    }
    return selected.id != assigned.id;
  }

  OnlineNativeTeacher? _teacherForBooking(WeekBooking booking) {
    return OnlineNativeTeacher.findAssigned(
          profileId: booking.nativeTeacherId,
          accountUid: booking.nativeTeacherUid.isNotEmpty
              ? booking.nativeTeacherUid
              : booking.teacherId,
        ) ??
        _assignedNativeTeacher;
  }

  OnlineSession? _sessionForBooking(WeekBooking booking) {
    final expected = EnrollmentService.sessionDocIdForBooking(booking.id);
    for (final session in _sessions) {
      if (session.bookingId == booking.id || session.id == expected) {
        return session;
      }
    }
    return null;
  }

  String _joinUrlForBooking(WeekBooking booking) {
    final session = _sessionForBooking(booking);
    if (session != null && session.meetingUrl.trim().isNotEmpty) {
      return session.meetingUrl;
    }
    return EnrollmentService.meetingUrlForBooking(
      courseId: booking.courseId.isNotEmpty
          ? booking.courseId
          : widget.course.id,
      bookingId: booking.id,
    );
  }

  bool _canJoinBooking(WeekBooking booking) {
    if (!booking.isConfirmed) return false;
    final session = _sessionForBooking(booking);
    if (session != null) return session.canStudentJoin;
    return true;
  }

  Widget _joinButton(String url) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Palette.secondaryDark,
        foregroundColor: Palette.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () => UrlUtil.open(url),
      icon: Icon(Icons.login, size: 16, color: Palette.white),
      label: Text(
        '화상수업 입장',
        style: TextStyle(fontFamily: "Jalnan", color: Palette.white, fontSize: 13),
      ),
    );
  }

  void _showTeacherProfile({
    OnlineNativeTeacher? teacher,
    String fallbackName = '',
  }) {
    final name = teacher?.name.trim().isNotEmpty == true
        ? teacher!.name
        : (fallbackName.isNotEmpty
            ? fallbackName
            : (_enrollment?.nativeTeacherLabel ?? '원어민 강사'));
    final nationality = teacher?.nationality.trim() ?? '';
    final intro = teacher?.intro.trim() ?? '';
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        contentPadding: EdgeInsets.fromLTRB(20, 20, 20, 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: double.infinity,
                height: 180,
                child: teacher?.photoFill() ??
                    Image.asset(
                      'assets/nativeTeacherPortrait.png',
                      fit: BoxFit.cover,
                    ),
              ),
            ),
            SizedBox(height: 14),
            Text(
              name,
              style: TextStyle(
                fontFamily: "Jalnan",
                fontSize: 18,
                color: Palette.secondaryDark,
              ),
            ),
            if (nationality.isNotEmpty) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Palette.grey50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Palette.grey200),
                ),
                child: Text(
                  nationality,
                  style: TextStyle(
                    fontFamily: "NotoSansKR",
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Palette.grey700,
                  ),
                ),
              ),
            ],
            SizedBox(height: 10),
            Text(
              intro.isNotEmpty
                  ? intro
                  : '선택한 원어민 강사와 화상수업을 진행합니다.',
              style: TextStyle(
                fontFamily: "NotoSansKR",
                fontSize: 14,
                height: 1.55,
                color: Palette.grey700,
              ),
            ),
          ],
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

  Future<void> _pickOtherTeacher(OnlineWeek week) async {
    final teachers = await AuthService.selectableNativeTeachers();
    final assignedUid = _assignedNativeTeacher?.accountUid ?? '';
    final assignedId = _assignedNativeTeacher?.id ?? '';
    final others = teachers.where((teacher) {
      if (teacher.accountUid.isEmpty) return false;
      if (assignedUid.isNotEmpty && teacher.accountUid == assignedUid) {
        return false;
      }
      if (assignedId.isNotEmpty && teacher.id == assignedId) return false;
      return true;
    }).toList();
    if (!mounted) return;
    if (others.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('지금은 예약할 수 있는 다른 원어민 강사가 없습니다.',
              style: TextStyle(fontFamily: "NotoSansKR")),
          backgroundColor: Palette.grey700,
        ),
      );
      return;
    }
    final selected = await showDialog<OnlineNativeTeacher>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('다른 원어민 강사 선택',
            style: TextStyle(fontFamily: "Jalnan", fontSize: 16)),
        content: SizedBox(
          width: 420,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: others.length,
            separatorBuilder: (_, __) => Divider(height: 1),
            itemBuilder: (context, index) {
              final teacher = others[index];
              return ListTile(
                contentPadding: EdgeInsets.symmetric(vertical: 6),
                leading: ClipOval(
                  child: teacher.photo(width: 44, height: 44),
                ),
                title: Text(teacher.name,
                    style: TextStyle(
                        fontFamily: "NotoSansKR",
                        fontWeight: FontWeight.w700)),
                subtitle: Text(
                  teacher.nationality.isEmpty
                      ? '담당 선생님 시간이 안 맞을 때 이 선생님 스케줄로 예약합니다.'
                      : teacher.nationality,
                  style: TextStyle(
                      fontFamily: "NotoSansKR",
                      fontSize: 12,
                      color: Palette.grey600),
                ),
                onTap: () => Navigator.pop(dialogContext, teacher),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('취소', style: TextStyle(fontFamily: "NotoSansKR")),
          ),
        ],
      ),
    );
    if (selected == null || !mounted) return;
    final availability = await TeacherScheduleService.load(selected.accountUid);
    if (!mounted) return;
    setState(() {
      _bookingTeacher[week.id] = selected;
      _availabilityByUid[selected.accountUid] = availability;
      _selectedDates.remove(week.id);
      _selectedTimes.remove(week.id);
    });
  }

  Widget meetingSection() {
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Palette.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Palette.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "화상수업 회차",
                style: TextStyle(
                  fontFamily: "Jalnan",
                  fontSize: 15,
                  color: Palette.secondaryDark,
                ),
              ),
              SizedBox(width: 10),
              IconButton(
                tooltip: '새로고침',
                onPressed: _loadData,
                icon: Icon(Icons.refresh, size: 18, color: Palette.grey600),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            "강사가 예약을 컨펌하면 회차가 생기고, 수업 시작 5분 전에 휴대폰으로 알림이 갑니다.\n"
            "강사가 호스트로 입장하면 수강생도 바로 들어올 수 있습니다. 수업 시간이 되면 입장하기를 누르세요.",
            style: TextStyle(
              fontFamily: "NotoSansKR",
              fontSize: 14,
              color: Palette.black,
              height: 1.6,
            ),
          ),
          SizedBox(height: 20),
          if (_isLoading)
            Container(
              padding: EdgeInsets.symmetric(vertical: 20),
              alignment: Alignment.center,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (_sessions.isEmpty)
            Container(
              width: double.maxFinite,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              decoration: BoxDecoration(
                color: Palette.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Palette.grey200),
              ),
              child: Column(
                children: [
                  Icon(Icons.videocam_off_outlined,
                      size: 34, color: Palette.grey400),
                  SizedBox(height: 10),
                  Text(
                    "아직 등록된 화상수업 회차가 없습니다.",
                    style: TextStyle(
                      fontFamily: "NotoSansKR",
                      fontSize: 14,
                      color: Palette.grey600,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "수업 일정이 확정되면 회차가 표시됩니다.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "NotoSansKR",
                      fontSize: 13,
                      color: Palette.grey500,
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: _sessions.map(sessionTile).toList(),
            ),
        ],
      ),
    );
  }

  Widget sessionTile(OnlineSession session) {
    final bool live = session.isLiveNow;
    final bool ended = session.isFinished || session.isStale;
    final String countdown =
        EnrollmentService.formatSessionCountdown(session);
    final Color statusColor = live
        ? Palette.success
        : (ended ? Palette.grey500 : Palette.secondaryDark);
    final scheduledLabel = session.scheduledAt == null
        ? countdown
        : '$countdown · ${_formatDateTime(session.scheduledAt!)}';

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: live ? Palette.success : Palette.grey200,
            width: live ? 1.5 : 1),
      ),
      child: Row(
        children: [
          Icon(
            live ? Icons.videocam : Icons.schedule,
            size: 26,
            color: statusColor,
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  EnrollmentService.normalizeSessionLabel(session.title),
                  style: TextStyle(
                    fontFamily: "NotoSansKR",
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Palette.black,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  scheduledLabel,
                  style: TextStyle(
                    fontFamily: "NotoSansKR",
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          if (session.canStudentJoin)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Palette.secondaryDark,
                foregroundColor: Palette.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => UrlUtil.open(session.meetingUrl),
              icon: Icon(Icons.login, size: 16, color: Palette.white),
              label: Text(
                "입장하기",
                style: TextStyle(
                  fontFamily: "Jalnan",
                  color: Palette.white,
                  fontSize: 13,
                ),
              ),
            )
          else
            Text(
              countdown,
              style: TextStyle(
                fontFamily: "NotoSansKR",
                fontSize: 12,
                color: Palette.grey500,
              ),
            ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}.${two(dt.month)}.${two(dt.day)} '
        '${two(dt.hour)}:${two(dt.minute)}';
  }

  Widget weekSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "회차 학습",
          style: TextStyle(
            fontFamily: "Jalnan",
            fontSize: 15,
            color: Palette.secondaryDark,
          ),
        ),
        SizedBox(height: 8),
        Text(
          _enrollment == null
              ? "수강이 배정되면 회차별로 인강, 문제풀이, 체크리스트를 진행할 수 있습니다."
              : _enrollmentDeadlineCopy(),
          style: TextStyle(
            fontFamily: "NotoSansKR",
            fontSize: 14,
            color: Palette.black,
            height: 1.6,
          ),
        ),
        SizedBox(height: 16),
        if (_isLoading)
          Container(
            padding: EdgeInsets.symmetric(vertical: 30),
            alignment: Alignment.center,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else if (_weeks.isEmpty)
          Container(
            width: double.maxFinite,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            decoration: BoxDecoration(
              color: Palette.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Palette.grey200),
            ),
            child: Text(
              "아직 등록된 회차 학습이 없습니다. 곧 1회차부터 올라올 예정입니다.",
              style: TextStyle(
                fontFamily: "NotoSansKR",
                fontSize: 14,
                color: Palette.grey600,
              ),
            ),
          )
        else
          Column(
            children: _weeks.map(weekTile).toList(),
          ),
      ],
    );
  }

  String _enrollmentDeadlineCopy() {
    final enrollment = _enrollment!;
    final current = enrollment.unlockedSessionNumber;
    final done = enrollment.completedSessions;
    if (enrollment.remainingSessions <= 0) {
      return "화상수업 ${enrollment.totalSessions}회를 모두 마쳤습니다. 이전 회차는 복습할 수 있습니다.";
    }
    final deadline = enrollment.expiresAt == null
        ? "권장은 주 1회입니다."
        : "권장은 주 1회이며, 수강 기한은 ${enrollment.remainingDeadlineWeeks}주 남았습니다.";
    return "지금 열린 수업은 $current회차입니다. 이 회차 화상수업을 마치면 다음 회차가 열립니다. "
        "$deadline 인강과 문제풀이를 모두 체크하면 예약이 열립니다."
        "${done > 0 ? ' 이수 $done/${enrollment.totalSessions}회.' : ''}";
  }

  Widget weekTile(OnlineWeek week) {
    final enrollment = _enrollment;
    final unlocked = enrollment == null ||
        EnrollmentService.isSessionUnlocked(enrollment, week.weekNumber);
    final isCurrent =
        enrollment != null && week.weekNumber == _currentSessionNumber;
    final completed = enrollment != null &&
        week.weekNumber <= enrollment.completedSessions;
    final checked = _checkedIds(week.id);
    final done = week.checkedCount(checked);
    final total = week.checklistItems.length;

    return Container(
      margin: EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: unlocked ? Palette.white : Palette.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent ? widget.course.accentColor : Palette.grey200,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isCurrent,
          tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Row(
            children: [
              Text(
                '${week.weekNumber}회차',
                style: TextStyle(
                  fontFamily: "Jalnan",
                  fontSize: 14,
                  color: unlocked
                      ? widget.course.accentColor
                      : Palette.grey500,
                ),
              ),
              if (isCurrent) ...[
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: widget.course.accentColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '진행 중',
                    style: TextStyle(
                      fontFamily: "NotoSansKR",
                      fontSize: 11,
                      color: Palette.white,
                    ),
                  ),
                ),
              ] else if (completed) ...[
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Palette.success,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '이수',
                    style: TextStyle(
                      fontFamily: "NotoSansKR",
                      fontSize: 11,
                      color: Palette.white,
                    ),
                  ),
                ),
              ] else if (!unlocked) ...[
                SizedBox(width: 8),
                Icon(Icons.lock_outline, size: 16, color: Palette.grey500),
              ],
            ],
          ),
          subtitle: Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              [
                week.title,
                if (total > 0) '체크 $done/$total',
              ].where((e) => e.isNotEmpty).join(' · '),
              style: TextStyle(
                fontFamily: "NotoSansKR",
                fontSize: 13,
                color: Palette.grey600,
              ),
            ),
          ),
          children: [
            if (!unlocked) ...[
              Text(
                '이전 회차 화상수업을 마치면 이 회차가 열립니다. '
                '인강과 예약은 열린 회차에서만 진행할 수 있습니다.',
                style: TextStyle(
                  fontFamily: "NotoSansKR",
                  fontSize: 13,
                  height: 1.5,
                  color: Palette.grey600,
                ),
              ),
            ] else ...[
            if (week.description.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  week.description,
                  style: TextStyle(
                    fontFamily: "NotoSansKR",
                    fontSize: 14,
                    height: 1.5,
                    color: Palette.black,
                  ),
                ),
              ),
              SizedBox(height: 12),
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: Text('1. 인강 보기',
                  style: TextStyle(fontFamily: "Jalnan", fontSize: 13)),
            ),
            SizedBox(height: 8),
            if (week.videoUrl.isEmpty)
              Text(
                '아직 인강이 등록되지 않았습니다.',
                style: TextStyle(
                    fontFamily: "NotoSansKR",
                    fontSize: 13,
                    color: Palette.grey500),
              )
            else
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => UrlUtil.open(week.videoUrl),
                  icon: Icon(Icons.play_circle_outline),
                  label: Text(
                    week.title.isNotEmpty ? week.title : '인강 시청하기',
                    style: TextStyle(fontFamily: "NotoSansKR"),
                  ),
                ),
              ),
            SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('2. 문제풀이',
                  style: TextStyle(fontFamily: "Jalnan", fontSize: 13)),
            ),
            SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.start,
                children: [
                  if (week.problemLinks.isNotEmpty)
                    ...week.problemLinks.map((link) => OutlinedButton.icon(
                          onPressed: () {
                            if (link.url.trim().isEmpty) {
                              _showProblemPlaceholder();
                              return;
                            }
                            UrlUtil.open(link.url);
                          },
                          icon: Icon(Icons.quiz_outlined, size: 18),
                          label: Text(
                            link.title.isEmpty ? '리뷰 및 문제풀이' : link.title,
                            style: TextStyle(fontFamily: "NotoSansKR"),
                          ),
                        ))
                  else
                    OutlinedButton.icon(
                      onPressed: _showProblemPlaceholder,
                      icon: Icon(Icons.quiz_outlined, size: 18),
                      label: Text('리뷰 및 문제풀이',
                          style: TextStyle(fontFamily: "NotoSansKR")),
                    ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('3. 학습 체크리스트',
                  style: TextStyle(fontFamily: "Jalnan", fontSize: 13)),
            ),
            SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '인강 시청과 문제풀이를 모두 체크해야 아래 예약이 열립니다.',
                style: TextStyle(
                  fontFamily: "NotoSansKR",
                  fontSize: 12,
                  color: Palette.grey500,
                ),
              ),
            ),
            SizedBox(height: 8),
            if (_enrollment == null)
              Text(
                '체크하려면 이 과정에 수강이 배정되어 있어야 합니다.',
                style: TextStyle(
                    fontFamily: "NotoSansKR",
                    fontSize: 13,
                    color: Palette.grey500),
              )
            else if (week.checklistItems.isEmpty)
              Text(
                '이번 회차 체크 항목이 아직 없습니다.',
                style: TextStyle(
                    fontFamily: "NotoSansKR",
                    fontSize: 13,
                    color: Palette.grey500),
              )
            else
              Column(
                children: week.checklistItems.map((item) {
                  final isChecked = checked.contains(item.id);
                  return CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    value: isChecked,
                    onChanged: (value) {
                      if (value == null) return;
                      _toggleChecklist(week, item.id, value);
                    },
                    title: Text(
                      item.label,
                      style: TextStyle(
                        fontFamily: "NotoSansKR",
                        fontSize: 14,
                        decoration:
                            isChecked ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                }).toList(),
              ),
            SizedBox(height: 16),
            weekFeedbackSection(week),
            if (_enrollment != null) ...[
              SizedBox(height: 16),
              if (_readyToBook(week, checked))
                weekBookingSection(week)
              else
                Text(
                  '인강 시청과 문제풀이를 모두 체크하면 화상수업 예약이 열립니다.',
                  style: TextStyle(
                    fontFamily: "NotoSansKR",
                    fontSize: 13,
                    color: Palette.grey600,
                    height: 1.5,
                  ),
                ),
            ],
            ],
          ],
        ),
      ),
    );
  }

  Widget weekFeedbackSection(OnlineWeek week) {
    final feedback =
        LessonFeedbackService.forWeek(_feedbacks, week.id, week.weekNumber);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text('4. 강사 피드백',
              style: TextStyle(fontFamily: "Jalnan", fontSize: 13)),
        ),
        SizedBox(height: 8),
        Container(
          width: double.maxFinite,
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Palette.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Palette.grey200),
          ),
          child: feedback == null
              ? Text(
                  '아직 강사 피드백이 없습니다.',
                  style: TextStyle(
                    fontFamily: "NotoSansKR",
                    fontSize: 13,
                    color: Palette.grey500,
                    height: 1.5,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      [
                        if (feedback.teacherName.isNotEmpty)
                          '${feedback.teacherName} 선생님',
                        feedback.lessonLabel,
                      ].join(' · '),
                      style: TextStyle(
                        fontFamily: "NotoSansKR",
                        fontSize: 12,
                        color: Palette.grey600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      feedback.content,
                      style: TextStyle(
                        fontFamily: "NotoSansKR",
                        fontSize: 14,
                        height: 1.55,
                        color: Palette.black,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget weekBookingSection(OnlineWeek week) {
    final existing = _bookingFor(week.id);
    final bookingTeacher = existing != null
        ? _teacherForBooking(existing)
        : _teacherForWeek(week.id);
    final availability = _availabilityForWeek(week.id);
    final otherTeacher = existing != null
        ? existing.isSubstitute
        : _isOtherTeacher(week.id);
    final teacherName = bookingTeacher?.name.trim().isNotEmpty == true
        ? bookingTeacher!.name
        : (existing?.nativeTeacherName.isNotEmpty == true
            ? existing!.nativeTeacherName
            : (_enrollment?.nativeTeacherLabel.isNotEmpty == true
                ? _enrollment!.nativeTeacherLabel
                : '원어민'));
    final dates = EnrollmentService.remainingBookingDates(
      enrollmentStart: _enrollment?.createdAt,
      weekNumber: week.weekNumber,
      expiresAt: _enrollment?.expiresAt,
    );
    final selectedDate = _selectedDates[week.id];
    final timeSlots = selectedDate == null
        ? const <String>[]
        : availability.openTimes(
            selectedDate,
            EnrollmentService.remainingTimeSlots(selectedDate),
          );
    final selectedTime = _selectedTimes[week.id];
    final session = existing == null ? null : _sessionForBooking(existing);

    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Palette.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Palette.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Tooltip(
                message: '프로필 보기',
                child: InkWell(
                  onTap: () => _showTeacherProfile(
                    teacher: bookingTeacher,
                    fallbackName: teacherName,
                  ),
                  customBorder: CircleBorder(),
                  child: ClipOval(
                    child: bookingTeacher?.photo(width: 56, height: 56) ??
                        Image.asset(
                          'assets/nativeTeacherPortrait.png',
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                        ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '화상수업 예약하기',
                      style: TextStyle(fontFamily: "Jalnan", fontSize: 13),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '$teacherName 선생님과 화상수업',
                      style: TextStyle(
                        fontFamily: "NotoSansKR",
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Palette.secondaryDark,
                      ),
                    ),
                    if (otherTeacher) ...[
                      SizedBox(height: 2),
                      Text(
                        '담당 선생님 대신 다른 원어민 수업입니다.',
                        style: TextStyle(
                          fontFamily: "NotoSansKR",
                          fontSize: 11,
                          color: Palette.accent,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          if (existing != null) ...[
            Text(
              existing.isConfirmed
                  ? '${EnrollmentService.formatBookingDate(existing.date)} ${EnrollmentService.formatBookingTime(existing.time)} · ${existing.statusLabel}'
                  : '${EnrollmentService.formatBookingDate(existing.date)} ${EnrollmentService.formatBookingTime(existing.time)} 신청됨 · ${existing.statusLabel}',
              style: TextStyle(
                fontFamily: "NotoSansKR",
                fontSize: 14,
                color: existing.isConfirmed
                    ? Palette.secondaryDark
                    : Palette.black,
                height: 1.5,
              ),
            ),
            if (session != null) ...[
              SizedBox(height: 4),
              Text(
                EnrollmentService.formatSessionCountdown(session),
                style: TextStyle(
                  fontFamily: "NotoSansKR",
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: session.isLiveNow
                      ? Palette.success
                      : Palette.darkTeal,
                ),
              ),
            ],
            if (_canJoinBooking(existing)) ...[
              SizedBox(height: 12),
              _joinButton(_joinUrlForBooking(existing)),
            ],
          ] else ...[
            Text(
              otherTeacher
                  ? '수업은 30분입니다. 선택한 원어민 선생님이 열어 둔 시간만 예약할 수 있습니다. 담당 선생님이 아니어도 강사가 확인하면 확정됩니다.'
                  : '수업은 30분입니다. 담당 원어민 선생님이 열어 둔 시간만 6:00 AM부터 11:00 PM까지 30분 단위로 선택할 수 있습니다. 강사가 확인하면 예약이 확정됩니다.',
              style: TextStyle(
                fontFamily: "NotoSansKR",
                fontSize: 13,
                color: Palette.grey600,
                height: 1.5,
              ),
            ),
            SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: _submittingBooking
                      ? null
                      : () => _pickOtherTeacher(week),
                  child: Text(
                    '다른 원어민 강사 수업 예약',
                    style: TextStyle(fontFamily: "NotoSansKR", fontSize: 12),
                  ),
                ),
                if (_isOtherTeacher(week.id))
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _bookingTeacher.remove(week.id);
                        _selectedDates.remove(week.id);
                        _selectedTimes.remove(week.id);
                      });
                    },
                    child: Text(
                      '담당 선생님으로 다시 예약',
                      style: TextStyle(
                          fontFamily: "NotoSansKR", fontSize: 12),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 10),
            Text('날짜 선택',
                style: TextStyle(fontFamily: "NotoSansKR", fontSize: 13)),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: dates.map((date) {
                final selected = selectedDate != null &&
                    EnrollmentService.dateOnly(selectedDate) ==
                        EnrollmentService.dateOnly(date);
                return ChoiceChip(
                  label: Text(EnrollmentService.formatBookingDate(date),
                      style: TextStyle(fontFamily: "NotoSansKR", fontSize: 12)),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      _selectedDates[week.id] = date;
                      _selectedTimes.remove(week.id);
                    });
                  },
                );
              }).toList(),
            ),
            if (selectedDate != null) ...[
              SizedBox(height: 12),
              Text('시간 선택',
                  style: TextStyle(fontFamily: "NotoSansKR", fontSize: 13)),
              SizedBox(height: 8),
              if (timeSlots.isEmpty)
                Text(
                  '선택할 수 있는 열린 시간이 없습니다. 다른 날짜를 골라 주세요.',
                  style: TextStyle(
                      fontFamily: "NotoSansKR",
                      fontSize: 13,
                      color: Palette.grey500),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: timeSlots.map((slot) {
                    return ChoiceChip(
                      label: Text(EnrollmentService.formatBookingTime(slot),
                          style: TextStyle(fontFamily: "NotoSansKR")),
                      selected: selectedTime == slot,
                      onSelected: (_) {
                        setState(() {
                          _selectedTimes[week.id] = slot;
                        });
                      },
                    );
                  }).toList(),
                ),
              SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Palette.secondaryDark,
                    foregroundColor: Palette.white,
                  ),
                  onPressed: _submittingBooking
                      ? null
                      : () => _submitBooking(week),
                  child: Text('예약 신청',
                      style: TextStyle(fontFamily: "Jalnan")),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget lessonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "강의 영상 자료",
          style: TextStyle(
            fontFamily: "Jalnan",
            fontSize: 15,
            color: Palette.secondaryDark,
          ),
        ),
        SizedBox(height: 16),
        if (_isLoading)
          Container(
            padding: EdgeInsets.symmetric(vertical: 30),
            alignment: Alignment.center,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else if (_lessons.isEmpty)
          emptyLessonView()
        else
          Column(
            children: _lessons.map(lessonTile).toList(),
          ),
      ],
    );
  }

  Widget emptyLessonView() {
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: Palette.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Palette.grey200),
      ),
      child: Column(
        children: [
          Icon(Icons.video_library_outlined, size: 40, color: Palette.grey400),
          SizedBox(height: 12),
          Text(
            "등록된 강의 영상이 아직 없습니다.",
            style: TextStyle(
              fontFamily: "NotoSansKR",
              fontSize: 14,
              color: Palette.grey600,
            ),
          ),
          SizedBox(height: 6),
          Text(
            "기본 영상 자료는 순차적으로 업로드될 예정입니다.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: "NotoSansKR",
              fontSize: 13,
              color: Palette.grey500,
            ),
          ),
        ],
      ),
    );
  }

  Widget lessonTile(OnlineLesson lesson) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Palette.grey200),
      ),
      child: Row(
        children: [
          Icon(Icons.play_circle_fill,
              size: 28, color: widget.course.accentColor),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.title,
                  style: TextStyle(
                    fontFamily: "NotoSansKR",
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Palette.black,
                  ),
                ),
                if (lesson.description.isNotEmpty) ...[
                  SizedBox(height: 4),
                  Text(
                    lesson.description,
                    style: TextStyle(
                      fontFamily: "NotoSansKR",
                      fontSize: 13,
                      color: Palette.grey600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (lesson.videoUrl.isNotEmpty)
            TextButton(
              onPressed: () => UrlUtil.open(lesson.videoUrl),
              child: Text(
                "시청하기",
                style: TextStyle(
                  fontFamily: "NotoSansKR",
                  fontSize: 13,
                  color: Palette.secondaryDark,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
