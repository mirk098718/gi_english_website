import 'package:flutter/material.dart';
import 'package:gi_english_website/class/OnlineCourse.dart';
import 'package:gi_english_website/util/EnrollmentService.dart';
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
  final Map<String, DateTime> _selectedDates = {};
  final Map<String, String> _selectedTimes = {};
  bool _isLoading = true;
  bool _savingChecklist = false;
  bool _submittingBooking = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final lessons = await EnrollmentService.lessons(widget.course.id);
    final sessions = await EnrollmentService.sessions(widget.course.id);
    final weeks = await EnrollmentService.weeks(widget.course.id);
    final enrollment =
        await EnrollmentService.myEnrollmentForCourse(widget.course.id);
    Map<String, List<String>> progress = {};
    List<WeekBooking> bookings = [];
    if (enrollment != null) {
      progress = await EnrollmentService.weekProgress(enrollment.id);
      bookings =
          await EnrollmentService.myWeekBookings(courseId: widget.course.id);
    }
    if (!mounted) return;
    setState(() {
      _lessons = lessons;
      _sessions = sessions;
      _weeks = weeks;
      _enrollment = enrollment;
      _weekProgress = progress;
      _bookings = bookings;
      _isLoading = false;
    });
  }

  int get _currentWeekNumber =>
      EnrollmentService.currentWeekNumber(_enrollment?.createdAt);

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

  bool _problemsChecked(OnlineWeek week, List<String> checked) {
    for (final item in week.checklistItems) {
      if (item.id == 'solve_problems' || item.label.contains('문제풀이')) {
        return checked.contains(item.id);
      }
    }
    return week.checklistItems.isNotEmpty &&
        week.checkedCount(checked) == week.checklistItems.length;
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
            SizedBox(height: 51, child: MyWidget.mobileSchoolFooter()),
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
            "강사님이 수업을 시작하면 해당 회차의 입장 버튼이 활성화됩니다.\n"
            "수업 시간에 아래 회차를 눌러 입장하세요.",
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
    final Color statusColor = live
        ? Palette.success
        : (ended ? Palette.grey500 : Palette.secondaryDark);
    final String statusText = live ? "수업 중" : (ended ? "수업 종료" : "수업 예정");

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
                  session.title,
                  style: TextStyle(
                    fontFamily: "NotoSansKR",
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Palette.black,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  session.scheduledAt != null
                      ? "$statusText · ${_formatDateTime(session.scheduledAt!)}"
                      : statusText,
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
          if (live)
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
              "대기 중",
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
          "주간 학습",
          style: TextStyle(
            fontFamily: "Jalnan",
            fontSize: 15,
            color: Palette.secondaryDark,
          ),
        ),
        SizedBox(height: 8),
        Text(
          _enrollment == null
              ? "수강이 배정되면 주차별로 인강, 문제풀이, 체크리스트를 진행할 수 있습니다."
              : "수강 시작일을 기준으로 이번 주는 ${_currentWeekNumber}주차입니다. "
                  "인강을 보고 문제풀이를 한 뒤, 아래 항목을 직접 체크하세요.",
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
              "아직 등록된 주간 학습이 없습니다. 곧 1주차부터 올라올 예정입니다.",
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

  Widget weekTile(OnlineWeek week) {
    final isCurrent = week.weekNumber == _currentWeekNumber;
    final checked = _checkedIds(week.id);
    final done = week.checkedCount(checked);
    final total = week.checklistItems.length;

    return Container(
      margin: EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent ? widget.course.accentColor : Palette.grey200,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isCurrent || week.weekNumber == 1,
          tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Row(
            children: [
              Text(
                '${week.weekNumber}주차',
                style: TextStyle(
                  fontFamily: "Jalnan",
                  fontSize: 14,
                  color: widget.course.accentColor,
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
                    '이번 주',
                    style: TextStyle(
                      fontFamily: "NotoSansKR",
                      fontSize: 11,
                      color: Palette.white,
                    ),
                  ),
                ),
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
                '이번 주 체크 항목이 아직 없습니다.',
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
            if (_enrollment != null &&
                _problemsChecked(week, checked)) ...[
              SizedBox(height: 16),
              weekBookingSection(week),
            ],
          ],
        ),
      ),
    );
  }

  Widget weekBookingSection(OnlineWeek week) {
    final existing = _bookingFor(week.id);
    final dates = EnrollmentService.remainingBookingDates(
      enrollmentStart: _enrollment?.createdAt,
      weekNumber: week.weekNumber,
    );
    final selectedDate = _selectedDates[week.id];
    final timeSlots = selectedDate == null
        ? const <String>[]
        : EnrollmentService.remainingTimeSlots(selectedDate);
    final selectedTime = _selectedTimes[week.id];

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
              ClipOval(
                child: Image.asset(
                  'assets/nativeTeacherPortrait.png',
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
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
                      '원어민 화상수업',
                      style: TextStyle(
                        fontFamily: "NotoSansKR",
                        fontSize: 12,
                        color: Palette.grey600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          if (existing != null) ...[
            Text(
              existing.isConfirmed
                  ? '${EnrollmentService.formatBookingDate(existing.date)} ${existing.time} · ${existing.statusLabel}'
                  : '${EnrollmentService.formatBookingDate(existing.date)} ${existing.time} 신청됨 · ${existing.statusLabel}',
              style: TextStyle(
                fontFamily: "NotoSansKR",
                fontSize: 14,
                color: existing.isConfirmed
                    ? Palette.secondaryDark
                    : Palette.black,
                height: 1.5,
              ),
            ),
          ] else ...[
            Text(
              '남은 날짜를 고른 뒤 시간을 선택하세요. 강사가 확인하면 예약이 확정됩니다.',
              style: TextStyle(
                fontFamily: "NotoSansKR",
                fontSize: 13,
                color: Palette.grey600,
                height: 1.5,
              ),
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
                  '선택할 수 있는 시간이 없습니다. 다른 날짜를 골라 주세요.',
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
                      label: Text(slot,
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
