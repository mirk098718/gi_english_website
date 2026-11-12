import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gi_english_website/util/SiteLayout.dart';
import 'package:gi_english_website/class/OnlineCourse.dart';
import 'package:gi_english_website/class/OnlinePlan.dart';
import 'package:gi_english_website/class/OnlineNativeTeacher.dart';
import 'package:gi_english_website/class/QuizResult.dart';
import 'package:gi_english_website/util/AppLanguage.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/EnrollmentService.dart';
import 'package:gi_english_website/util/LessonFeedbackService.dart';
import 'package:gi_english_website/util/LessonRatingService.dart';
import 'package:gi_english_website/util/TeacherScheduleService.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/QuizResultBridge.dart';
import 'package:gi_english_website/util/QuizResultService.dart';
import 'package:gi_english_website/util/JitsiJoin.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/UrlIUtil.dart';
import 'package:gi_english_website/pages/OnlineCheckoutPage.dart';
import 'package:gi_english_website/widget/MobileSchoolLayout.dart';
import 'package:gi_english_website/widget/OnlineProgramSideMenu.dart';
import 'package:gi_english_website/widget/WebSchoolLayout.dart';
import 'package:gi_english_website/widget/QuizResultSummary.dart';
import 'package:gi_english_website/widget/MainTeacherChange.dart';
import 'package:gi_english_website/widget/StudentJoinButton.dart';
import 'package:gi_english_website/widget/TeacherClassTimeLine.dart';
import 'package:gi_english_website/widget/YoutubeLessonPlayer.dart';

import '../util/WidgetUtil.dart';

class OnlineCourseDetailPage extends StatefulWidget {
  final OnlineCourse course;

  const OnlineCourseDetailPage({Key? key, required this.course})
      : super(key: key);

  @override
  _OnlineCourseDetailPageState createState() => _OnlineCourseDetailPageState();
}

class _OnlineCourseDetailPageState extends State<OnlineCourseDetailPage>
    with WidgetsBindingObserver {
  List<OnlineLesson> _lessons = [];
  List<OnlineSession> _sessions = [];
  List<OnlineWeek> _weeks = [];
  EnrollmentRecord? _enrollment;
  Map<String, List<String>> _weekProgress = {};
  Map<String, QuizResult> _quizResults = {};
  List<WeekBooking> _bookings = [];
  List<LessonFeedback> _feedbacks = [];
  List<LessonRating> _ratings = [];
  TeacherAvailability _teacherAvailability =
      TeacherAvailability(teacherUid: '');
  final Map<String, DateTime> _selectedDates = {};
  final Map<String, String> _selectedTimes = {};
  final Map<String, OnlineNativeTeacher> _bookingTeacher = {};
  final Map<String, TeacherAvailability> _availabilityByUid = {};
  bool _isLoading = true;
  bool _savingChecklist = false;
  bool _submittingBooking = false;
  String? _movingWeekId;
  bool _watchingSessions = false;
  Timer? _sessionTicker;
  StreamSubscription<void>? _quizSavedSub;
  StreamSubscription<dynamic>? _authSub;
  StreamSubscription<List<LessonRating>>? _ratingSub;
  StreamSubscription<List<OnlineSession>>? _sessionSub;
  int _ratingBind = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _quizSavedSub = QuizResultEvents.saved.listen((_) {
      _reloadQuizzes();
    });
    _loadData();
    _authSub = AuthService.authStateChanges.listen((_) {
      _bindRatings();
    });
    _sessionTicker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _quizSavedSub?.cancel();
    _authSub?.cancel();
    _ratingSub?.cancel();
    _sessionSub?.cancel();
    _sessionTicker?.cancel();
    super.dispose();
  }

  Future<void> _bindRatings() async {
    final token = ++_ratingBind;
    await _ratingSub?.cancel();
    if (!mounted || token != _ratingBind) return;
    _ratingSub = null;
    final uid = AuthService.currentUser?.uid ?? '';
    if (uid.isEmpty) return;
    _ratingSub = LessonRatingService.watchMine(userId: uid).listen((ratings) {
      if (!mounted) return;
      setState(() {
        _ratings = ratings
            .where((rating) =>
                rating.courseId.isEmpty || rating.courseId == widget.course.id)
            .toList();
      });
    }, onError: (_) {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_isLoading) {
      _reloadQuizzes();
    }
  }

  Future<void> _reloadQuizzes() async {
    final uid = AuthService.currentUser?.uid ?? '';
    if (uid.isEmpty) return;
    final quizIds = <String>{};
    for (final week in _weeks) {
      for (final link in week.problemLinks) {
        final quizId = QuizResult.quizIdFromUrl(link.url);
        if (quizId.isNotEmpty) quizIds.add(quizId);
      }
    }
    final lookup = await QuizResultService.fetchForUser(
      userId: uid,
      quizIds: quizIds,
    );
    if (!mounted) return;
    setState(() => _quizResults = lookup.results);
  }

  Future<void> _loadData() async {
    try {
    await AuthService.selectableNativeTeachers();
    final lessons = await EnrollmentService.lessons(widget.course.id);
    final sessions = await EnrollmentService.sessions(
      widget.course.id,
      userId: AuthService.currentUser?.uid,
    );
    final enrollment =
        await EnrollmentService.myEnrollmentForCourse(widget.course.id);
    final speaking = widget.course.isSpeakingProduct ||
        enrollment?.plan == OnlinePlan.speaking;
    final weeks = speaking
        ? _speakingWeeks(enrollment?.totalSessions ?? 8)
        : await EnrollmentService.weeks(
            widget.course.id,
            ensureThrough: enrollment?.unlockedSessionNumber ?? 1,
          );
    Map<String, List<String>> progress = {};
    List<WeekBooking> bookings = [];
    List<LessonFeedback> feedbacks = [];
    List<LessonRating> ratings = [];
    TeacherAvailability availability = TeacherAvailability(teacherUid: '');
    final uid = AuthService.currentUser?.uid ?? '';
    Map<String, QuizResult> quizResults = {};
    if (uid.isNotEmpty) {
      final quizIds = <String>{};
      for (final week in weeks) {
        for (final link in week.problemLinks) {
          final quizId = QuizResult.quizIdFromUrl(link.url);
          if (quizId.isNotEmpty) quizIds.add(quizId);
        }
      }
      final lookup = await QuizResultService.fetchForUser(
        userId: uid,
        quizIds: quizIds,
      );
      quizResults = lookup.results;
    }
    if (enrollment != null) {
      progress = await EnrollmentService.weekProgress(enrollment.id);
      bookings =
          await EnrollmentService.myWeekBookings(courseId: widget.course.id);
      feedbacks = await LessonFeedbackService.listForStudent(
          courseId: widget.course.id);
      ratings = await LessonRatingService.listMine();
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
      if (!_watchingSessions) _sessions = sessions;
      _weeks = weeks;
      _enrollment = enrollment;
      _weekProgress = progress;
      _quizResults = quizResults;
      _bookings = bookings;
      _feedbacks = feedbacks;
      _ratings = ratings;
      _teacherAvailability = availability;
      _isLoading = false;
    });
    _watchSessions();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (_weeks.isEmpty) {
          _weeks = [EnrollmentService.defaultWeek1(widget.course.id)];
        }
      });
    }
  }

  /// 강사가 시작을 누르면 새로고침 없이 입장 버튼이 초록으로 바뀐다.
  void _watchSessions() {
    if (_watchingSessions) return;
    _watchingSessions = true;
    final uid = AuthService.currentUser?.uid;
    _sessionSub = EnrollmentService.watchSessions(
      widget.course.id,
      userId: uid,
    ).listen((sessions) {
      if (!mounted) return;
      setState(() => _sessions = sessions);
    }, onError: (Object error) {
      print('화상수업 회차 구독 오류: $error');
    });
  }

  int get _currentSessionNumber {
    final enrollment = _enrollment;
    if (enrollment == null) return 1;
    return enrollment.unlockedSessionNumber;
  }

  bool get _lectureOnly => _enrollment?.plan == OnlinePlan.lecture;

  bool get _speakingOnly =>
      widget.course.isSpeakingProduct ||
      _enrollment?.plan == OnlinePlan.speaking;

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
          content: Text(tr(context, "날짜와 시간을 선택해주세요."),
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
        content: Text(tr(context, "예약이 신청되었습니다. 강사 확인을 기다려 주세요."),
            style: TextStyle(fontFamily: "NotoSansKR")),
        backgroundColor: Palette.success,
      ),
    );
    await _loadData();
  }

  Future<void> _cancelBooking(WeekBooking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr(context, "예약 취소"),
            style: TextStyle(fontFamily: "Jalnan")),
        content: Text(
          tr(context, "이 예약을 취소할까요?\n강사 시간이 바로 비워지고, 같은 회차를 다시 신청할 수 있습니다."),
          style: TextStyle(fontFamily: "NotoSansKR", height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(tr(context, "닫기")),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(tr(context, "예약 취소")),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _submittingBooking = true);
    final error = await EnrollmentService.cancelWeekBooking(booking);
    if (!mounted) return;
    setState(() {
      _submittingBooking = false;
      if (error == null) _movingWeekId = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ?? tr(context, "예약을 취소했습니다. 강사 시간이 비워졌습니다."),
          style: TextStyle(fontFamily: "NotoSansKR"),
        ),
        backgroundColor: error == null ? Palette.success : Palette.danger,
      ),
    );
    if (error == null) await _loadData();
  }

  Future<void> _moveBooking(OnlineWeek week, WeekBooking booking) async {
    final enrollment = _enrollment;
    if (enrollment == null || _submittingBooking) return;
    final date = _selectedDates[week.id];
    final time = _selectedTimes[week.id];
    if (date == null || time == null || time.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(context, "날짜와 시간을 선택해주세요."),
              style: TextStyle(fontFamily: "NotoSansKR")),
          backgroundColor: Palette.danger,
        ),
      );
      return;
    }
    setState(() => _submittingBooking = true);
    final error = await EnrollmentService.moveWeekBooking(
      enrollment: enrollment,
      week: week,
      current: booking,
      date: date,
      time: time,
    );
    if (!mounted) return;
    setState(() {
      _submittingBooking = false;
      if (error == null) _movingWeekId = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ?? tr(context, "예약 시간을 옮겼습니다. 강사 확인을 기다려 주세요."),
          style: TextStyle(fontFamily: "NotoSansKR"),
        ),
        backgroundColor: error == null ? Palette.success : Palette.danger,
      ),
    );
    if (error == null) await _loadData();
  }

  void _openExtension() {
    MenuUtil.push(
      context,
      OnlineCheckoutPage(
        initialCourseId: widget.course.id,
        extendEnrollment: true,
        initialPlan: _enrollment?.plan,
        initialSessions: _enrollment?.plan == OnlinePlan.speaking
            ? _enrollment?.totalSessions
            : null,
      ),
    );
  }

  void _showProblemPlaceholder() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr(context, "HTML 문제 페이지가 연결되면 이 버튼으로 열립니다."),
          style: TextStyle(fontFamily: "NotoSansKR"),
        ),
        backgroundColor: Palette.secondaryDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!useMobileSchoolLayout(context)) {
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
            course.localizedName(context, _enrollment?.plan ?? OnlinePlan.bundle),
            style: TextStyle(fontFamily: "Jalnan", fontSize: 20),
          ),
          WidgetUtil.myDivider(),
          SizedBox(height: 20),
          Text(
            tr(context, course.subtitleFor(_enrollment?.plan ?? OnlinePlan.bundle)),
            style: TextStyle(
              fontFamily: "Jalnan",
              fontSize: 15,
              color: course.accentColor,
            ),
          ),
          SizedBox(height: 16),
          Text(
            course.highlights.map((line) => "• ${tr(context, line)}").join("\n"),
            style: TextStyle(
              fontFamily: "NotoSansKR",
              fontSize: 14,
              color: Palette.black,
              height: 1.6,
            ),
          ),
          SizedBox(height: 32),
          weekSection(),
          if (!_isLoading && _weeks.isEmpty) ...[
            SizedBox(height: 32),
            meetingSection(),
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
    if (session == null) return false;
    return session.canStudentJoin;
  }

  bool _showLockedJoin(WeekBooking booking) {
    if (!booking.isConfirmed) return false;
    if (_canJoinBooking(booking)) return false;
    final session = _sessionForBooking(booking);
    if (session == null) return true;
    return session.isWaitingForStart;
  }

  String get _meetingDisplayName {
    return (AuthService.currentUser?.displayName ?? '').trim();
  }

  void _openStudentMeeting(String url) {
    JitsiJoin.open(
      url,
      asHost: false,
      displayName: _meetingDisplayName,
    );
  }

  Widget _joinButton(String url, {required bool enabled}) {
    final button = StudentJoinButton(
      enabled: enabled,
      label: tr(context, "입장하기"),
      onPressed: () => _openStudentMeeting(url),
    );
    if (enabled) return button;
    return Tooltip(
      message: tr(context, "강사가 수업을 시작하면 입장할 수 있습니다."),
      child: button,
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
                  : tr(context, "선택한 원어민 강사와 화상수업을 진행합니다."),
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
            child: Text(tr(context, "닫기"), style: TextStyle(fontFamily: "NotoSansKR")),
          ),
        ],
      ),
    );
  }

  Future<void> _changeMainTeacher() async {
    final changed = await MainTeacherChange.pick(
      context,
      currentUid: _assignedNativeTeacher?.accountUid ??
          _enrollment?.nativeTeacherUid ??
          '',
    );
    if (!changed || !mounted) return;
    setState(_bookingTeacher.clear);
    await _loadData();
  }

  Future<void> _pinMainTeacher(OnlineNativeTeacher teacher) async {
    final changed = await MainTeacherChange.pin(context, teacher);
    if (!changed || !mounted) return;
    setState(() {
      _bookingTeacher.removeWhere((_, picked) =>
          picked.accountUid == teacher.accountUid || picked.id == teacher.id);
    });
    await _loadData();
  }

  Future<void> _pickOtherTeacher(OnlineWeek week) async {
    final teachers = await AuthService.selectableNativeTeachers(
      kind: TeacherPickKind.coteach,
    );
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
          content: Text(tr(context, "지금은 예약할 수 있는 다른 원어민 강사가 없습니다."),
              style: TextStyle(fontFamily: "NotoSansKR")),
          backgroundColor: Palette.grey700,
        ),
      );
      return;
    }
    final selected = await showDialog<OnlineNativeTeacher>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr(context, "다른 원어민 강사 선택"),
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
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      teacher.nationality.isEmpty
                          ? tr(context, "담당 선생님 시간이 안 맞을 때 이 선생님 스케줄로 예약합니다.")
                          : teacher.nationality,
                      style: TextStyle(
                          fontFamily: "NotoSansKR",
                          fontSize: 12,
                          color: Palette.grey600),
                    ),
                    TeacherClassTimeLine(
                      bands: teacher.classBands,
                      closedRoutines: teacher.closedRoutineKeys,
                    ),
                  ],
                ),
                onTap: () => Navigator.pop(dialogContext, teacher),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(tr(context, "취소"), style: TextStyle(fontFamily: "NotoSansKR")),
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
                tr(context, "화상수업 회차"),
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
            tr(context, "강사가 예약을 컨펌하면 수업 일정이 확정되고, 시작 5분 전에 휴대폰으로 알림이 갑니다.\n입장 버튼은 회색으로 기다리다가, 강사가 수업을 시작하면 초록으로 바뀌어 누를 수 있습니다."),
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
                    tr(context, "아직 등록된 화상수업 회차가 없습니다."),
                    style: TextStyle(
                      fontFamily: "NotoSansKR",
                      fontSize: 14,
                      color: Palette.grey600,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    tr(context, "수업 일정이 확정되면 회차가 표시됩니다."),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                if (session.isWaitingForStart) ...[
                  SizedBox(height: 4),
                  Text(
                    tr(context, "수업 일정이 확정되었습니다."),
                    style: TextStyle(
                      fontFamily: "NotoSansKR",
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Palette.grey600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (session.canStudentJoin)
            _joinButton(session.meetingUrl, enabled: true)
          else if (session.isWaitingForStart)
            _joinButton(session.meetingUrl, enabled: false)
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
          if (ended) ...[
            SizedBox(height: 10),
            _sessionRatingRow(session),
          ],
        ],
      ),
    );
  }

  LessonRating? _ratingForSession(OnlineSession session) {
    if (session.bookingId.isNotEmpty) {
      final byBooking =
          LessonRatingService.forBooking(_ratings, session.bookingId);
      if (byBooking != null) return byBooking;
    }
    if (session.id.startsWith('booking_')) {
      final bookingId = session.id.substring('booking_'.length);
      final byId = LessonRatingService.forBooking(_ratings, bookingId);
      if (byId != null) return byId;
    }
    if (session.weekNumber <= 0) return null;
    LessonRating? best;
    for (final rating in _ratings) {
      if (rating.weekNumber != session.weekNumber) continue;
      if (best == null || rating.date.isAfter(best.date)) best = rating;
    }
    return best;
  }

  Future<void> _rateLesson(LessonRating rating) async {
    final saved = await LessonRatingService.showPrompt(
      context: context,
      rating: rating,
    );
    if (saved) await _loadData();
  }

  Widget _sessionRatingRow(OnlineSession session) {
    final rating = _ratingForSession(session);
    if (rating != null && rating.isRated) {
      return Row(
        children: [
          LessonStarView(stars: rating.stars, size: 18),
          SizedBox(width: 6),
          Text(
            rating.starsLabel,
            style: TextStyle(
              fontFamily: "NotoSansKR",
              fontSize: 12,
              color: Palette.grey700,
            ),
          ),
        ],
      );
    }
    if (rating != null && rating.canStudentRate) {
      return Align(
        alignment: Alignment.centerLeft,
        child: ElevatedButton.icon(
          onPressed: () => _rateLesson(rating),
          icon: Icon(Icons.star_rounded, size: 18),
          label: Text(tr(context, "별점 평가하기"),
              style: TextStyle(fontFamily: "NotoSansKR")),
        ),
      );
    }
    return Text(
      tr(context, "강사가 수업을 종료하면 이 자리에서 별점을 남길 수 있습니다."),
      style: TextStyle(
        fontFamily: "NotoSansKR",
        fontSize: 12,
        color: Palette.grey600,
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
        Row(
          children: [
            Text(
              tr(context, _speakingOnly ? "회화 예약" : "회차 학습"),
              style: TextStyle(
                fontFamily: "Jalnan",
                fontSize: 15,
                color: Palette.secondaryDark,
              ),
            ),
            SizedBox(width: 4),
            IconButton(
              tooltip: '새로고침',
              onPressed: _loadData,
              icon: Icon(Icons.refresh, size: 18, color: Palette.grey600),
            ),
            if (_enrollment != null && !_lectureOnly)
              TextButton(
                onPressed: _changeMainTeacher,
                child: Text(
                  tr(context, "메인 강사 변경"),
                  style: TextStyle(fontFamily: "NotoSansKR", fontSize: 13),
                ),
              ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          _enrollment == null
              ? tr(context, "수강이 배정되면 회차별로 인강, 문제풀이, 체크리스트를 진행할 수 있습니다.")
              : _enrollmentDeadlineCopy(),
          style: TextStyle(
            fontFamily: "NotoSansKR",
            fontSize: 14,
            color: Palette.black,
            height: 1.6,
          ),
        ),
        if (_enrollment != null &&
            EnrollmentService.isEnrollmentExpired(_enrollment!)) ...[
          SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Palette.secondaryDark,
                foregroundColor: Palette.white,
              ),
              onPressed: _openExtension,
              child: Text(tr(context, "연장 결제"),
                  style: TextStyle(fontFamily: "Jalnan")),
            ),
          ),
        ],
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
              tr(context, "아직 등록된 회차 학습이 없습니다. 곧 1회차부터 올라올 예정입니다."),
              style: TextStyle(
                fontFamily: "NotoSansKR",
                fontSize: 14,
                color: Palette.grey600,
              ),
            ),
          )
        else
          Column(
            children: [
              ..._weeks.map(weekTile),
              ..._unmatchedSessions().map(sessionTile),
            ],
          ),
      ],
    );
  }

  List<OnlineWeek> _speakingWeeks(int total) {
    final count = total < 1 ? 1 : total;
    return [
      for (var n = 1; n <= count; n++)
        OnlineWeek(
          id: 'native_speaking_session_$n',
          courseId: widget.course.id,
          weekNumber: n,
          title: '$n회 회화',
          description: '원어민과 1:1로 말하는 회화 수업입니다.',
          videoUrl: '',
        ),
    ];
  }

  String _enrollmentDeadlineCopy() {
    final enrollment = _enrollment!;
    final current = enrollment.unlockedSessionNumber;
    final done = enrollment.completedSessions;
    if (_lectureOnly) {
      if (EnrollmentService.isEnrollmentExpired(enrollment)) {
        return '수강 기한이 지났습니다. 연장 결제 후 인강을 이어서 들을 수 있습니다.';
      }
      return '인강 ${OnlinePlan.lessonsPerLevel}편과 퀴즈를 들을 수 있습니다. '
          '화상수업은 포함되지 않습니다. '
          '수강 기한은 ${enrollment.remainingDeadlineWeeks}주 남았습니다.';
    }
    if (_speakingOnly) {
      if (enrollment.remainingSessions <= 0) {
        return '회화 ${enrollment.totalSessions}회를 모두 마쳤습니다.';
      }
      if (EnrollmentService.isEnrollmentExpired(enrollment)) {
        return '수강 기한이 지났습니다. 연장 결제 후 회화를 이어서 예약할 수 있습니다.';
      }
      final deadline = enrollment.expiresAt == null
          ? ''
          : ' 수강 기한은 ${enrollment.remainingDeadlineWeeks}주 남았습니다.';
      return '지금 예약할 수 있는 회화는 $current회입니다. '
          '회화를 마치면 다음 회차가 열립니다.$deadline'
          '${done > 0 ? ' 이수 $done/${enrollment.totalSessions}회.' : ''}';
    }
    if (enrollment.remainingSessions <= 0) {
      return "화상수업 ${enrollment.totalSessions}회를 모두 마쳤습니다. 이전 회차는 복습할 수 있습니다.";
    }
    final deadline = enrollment.expiresAt == null
        ? "권장은 주 1회입니다."
        : "권장은 주 1회이며, 수강 기한은 ${enrollment.remainingDeadlineWeeks}주 남았습니다.";
    if (EnrollmentService.isEnrollmentExpired(enrollment)) {
      return '수강 기한이 지났습니다. 목록에 만료로 남아 있으며, 연장 결제 후 이어서 예약할 수 있습니다.';
    }
    return "지금 열린 수업은 $current회차입니다. 강사 피드백과 별점 평가가 끝나야 다음 회차가 열립니다. "
        "$deadline 영상이 있는 회차는 인강과 문제풀이를, 영상이 없는 회차는 문제풀이만 체크하면 예약이 열립니다."
        "${done > 0 ? ' 이수 $done/${enrollment.totalSessions}회.' : ''}";
  }

  LessonRating? _ratingForWeek(OnlineWeek week) {
    LessonRating? best;
    for (final rating in _ratings) {
      if (week.id.isNotEmpty && rating.weekId == week.id) {
        if (best == null || rating.date.isAfter(best.date)) best = rating;
        continue;
      }
      if (week.weekNumber > 0 && rating.weekNumber == week.weekNumber) {
        if (best == null || rating.date.isAfter(best.date)) best = rating;
      }
    }
    if (best != null) return best;
    final booking = _bookingFor(week.id);
    if (booking != null) {
      return LessonRatingService.forBooking(_ratings, booking.id);
    }
    return null;
  }

  String _lockMessage(OnlineWeek week) {
    final previous = week.weekNumber - 1;
    if (previous > 0) {
      LessonRating? pending;
      for (final rating in _ratings) {
        if (rating.weekNumber == previous && rating.canStudentRate) {
          pending = rating;
          break;
        }
      }
      if (pending != null) {
        return '${previous}회차 별점 평가를 마치면 이 회차가 열립니다. '
            '하루가 지나도 평가가 없으면 관리자가 다음 회차를 열 수 있습니다.';
      }
    }
    return '이전 회차의 강사 피드백과 별점 평가가 끝나야 이 회차가 열립니다. '
        '한쪽이 하루 넘게 멈추면 관리자만 다음 회차를 열 수 있습니다.';
  }

  Widget weekTile(OnlineWeek week) {
    final enrollment = _enrollment;
    final unlocked = enrollment == null ||
        EnrollmentService.isSessionUnlocked(enrollment, week.weekNumber);
    final isCurrent = !_lectureOnly &&
        enrollment != null &&
        week.weekNumber == _currentSessionNumber;
    final completed = !_lectureOnly &&
        enrollment != null &&
        week.weekNumber <= enrollment.completedSessions;
    final checked = _checkedIds(week.id);
    final visibleItems = EnrollmentService.requiredChecklistItems(week);
    final done = visibleItems.where((item) => checked.contains(item.id)).length;
    final total = visibleItems.length;

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
          expandedAlignment: Alignment.centerLeft,
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
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
                    tr(context, "진행 중"),
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
                    tr(context, "이수"),
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
                _lockMessage(week),
                style: TextStyle(
                  fontFamily: "NotoSansKR",
                  fontSize: 13,
                  height: 1.5,
                  color: Palette.grey600,
                ),
              ),
              ..._sessionsForWeek(week).map(sessionTile),
            ] else if (_speakingOnly) ...[
              if (_enrollment == null)
                Text(
                  tr(context, '결제 후 이 회차 회화를 예약할 수 있습니다.'),
                  style: TextStyle(
                    fontFamily: 'NotoSansKR',
                    fontSize: 13,
                    height: 1.5,
                    color: Palette.grey600,
                  ),
                )
              else ...[
                weekBookingSection(week),
                SizedBox(height: 16),
                weekFeedbackSection(week),
              ],
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
              child: Text(tr(context, "1. 인강 보기"),
                  style: TextStyle(fontFamily: "Jalnan", fontSize: 13)),
            ),
            SizedBox(height: 8),
            if (week.videoUrl.isEmpty)
              Text(
                tr(context, "아직 인강이 등록되지 않았습니다."),
                style: TextStyle(
                    fontFamily: "NotoSansKR",
                    fontSize: 13,
                    color: Palette.grey500),
              )
            else
              YoutubeLessonPlayer(
                videoUrl: week.videoUrl,
                title: week.title.isNotEmpty ? week.title : '인강 시청하기',
              ),
            SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(tr(context, "2. 문제풀이"),
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
                            link.title.isEmpty ? tr(context, "리뷰 및 문제풀이") : link.title,
                            style: TextStyle(fontFamily: "NotoSansKR"),
                          ),
                        ))
                  else
                    OutlinedButton.icon(
                      onPressed: _showProblemPlaceholder,
                      icon: Icon(Icons.quiz_outlined, size: 18),
                      label: Text(tr(context, "리뷰 및 문제풀이"),
                          style: TextStyle(fontFamily: "NotoSansKR")),
                    ),
                ],
              ),
            ),
            _quizResultSection(week),
            SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(tr(context, "3. 학습 체크리스트"),
                  style: TextStyle(fontFamily: "Jalnan", fontSize: 13)),
            ),
            SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                tr(
                  context,
                  _lectureOnly
                      ? '인강과 문제풀이를 체크하며 진도를 남깁니다. 이 상품에는 화상수업이 없습니다.'
                      : EnrollmentService.bookingChecklistHint(week),
                ),
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
                tr(context, "체크하려면 이 과정에 수강이 배정되어 있어야 합니다."),
                style: TextStyle(
                    fontFamily: "NotoSansKR",
                    fontSize: 13,
                    color: Palette.grey500),
              )
            else if (week.checklistItems.isEmpty)
              Text(
                tr(context, "이번 회차 체크 항목이 아직 없습니다."),
                style: TextStyle(
                    fontFamily: "NotoSansKR",
                    fontSize: 13,
                    color: Palette.grey500),
              )
            else
              Column(
                children: EnrollmentService.requiredChecklistItems(week).map((item) {
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
            if (!_lectureOnly) ...[
              SizedBox(height: 16),
              weekLiveClassSection(week, checked),
              SizedBox(height: 16),
              weekFeedbackSection(week),
            ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _quizResultSection(OnlineWeek week) {
    final quizIds = week.problemLinks
        .map((link) => QuizResult.quizIdFromUrl(link.url))
        .where((id) => id.isNotEmpty)
        .toList();
    if (quizIds.isEmpty) return SizedBox.shrink();
    final results = <QuizResult>[];
    for (final quizId in quizIds) {
      final result = _quizResults[quizId];
      if (result != null) results.add(result);
    }
    if (results.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: 8),
        child: Text(
          tr(context, "완료를 누르면 맞은 개수와 주관식 답이 여기에 바로 남습니다. 다시 풀고 완료하면 최근 결과로 바뀝니다."),
          style: TextStyle(
            fontFamily: "NotoSansKR",
            fontSize: 12,
            height: 1.45,
            color: Palette.grey500,
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: results
          .map((result) => QuizResultSummary(result: result))
          .toList(),
    );
  }

  List<OnlineSession> _sessionsForWeek(OnlineWeek week) {
    final booking = _bookingFor(week.id);
    final expectedId = booking == null
        ? ''
        : EnrollmentService.sessionDocIdForBooking(booking.id);
    return _sessions.where((session) {
      if (session.cancelled) return false;
      if (session.bookingId.isNotEmpty) {
        for (final booking in _bookings) {
          if (booking.id == session.bookingId && booking.isCancelled) {
            return false;
          }
        }
      }
      if (booking != null &&
          (session.bookingId == booking.id || session.id == expectedId)) {
        return true;
      }
      if (session.bookingId.isNotEmpty && week.weekNumber > 0) {
        for (final item in _bookings) {
          if (item.id == session.bookingId &&
              item.weekNumber == week.weekNumber) {
            return true;
          }
        }
      }
      if (week.weekNumber <= 0) return false;
      if (session.weekNumber == week.weekNumber) return true;
      return session.weekNumber == 0 &&
          session.bookingId.isEmpty &&
          session.order == week.weekNumber;
    }).toList();
  }

  List<OnlineSession> _unmatchedSessions() {
    final matched = <String>{};
    for (final week in _weeks) {
      for (final session in _sessionsForWeek(week)) {
        matched.add(session.id);
      }
    }
    return _sessions.where((session) => !matched.contains(session.id)).toList();
  }

  /// 인강 · 문제 · 체크 다음, 강사 피드백 앞에 두는 이 회차의 화상수업.
  Widget weekLiveClassSection(OnlineWeek week, List<String> checked) {
    final sessions = _sessionsForWeek(week);
    final booking = _bookingFor(week.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            tr(context, "4. 화상수업"),
            style: TextStyle(fontFamily: "Jalnan", fontSize: 13),
          ),
        ),
        SizedBox(height: 8),
        if (sessions.isNotEmpty)
          Column(children: sessions.map(sessionTile).toList())
        else if (_enrollment != null &&
            (booking != null || _readyToBook(week, checked)))
          weekBookingSection(week)
        else
          Text(
            _enrollment == null
                ? tr(context, '수강이 배정되면 이 회차 화상수업을 예약할 수 있습니다.')
                : tr(context, EnrollmentService.bookingChecklistHint(week)),
            style: TextStyle(
              fontFamily: "NotoSansKR",
              fontSize: 13,
              color: Palette.grey600,
              height: 1.5,
            ),
          ),
      ],
    );
  }

  Widget weekFeedbackSection(OnlineWeek week) {
    final feedback =
        LessonFeedbackService.forWeek(_feedbacks, week.id, week.weekNumber);
    final rating = _ratingForWeek(week);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(tr(context, "5. 강사 피드백"),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (feedback == null)
                Text(
                  tr(context, "아직 강사 피드백이 없습니다."),
                  style: TextStyle(
                    fontFamily: "NotoSansKR",
                    fontSize: 13,
                    color: Palette.grey500,
                    height: 1.5,
                  ),
                )
              else ...[
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
              SizedBox(height: 12),
              Text(tr(context, "수업 평가"),
                  style: TextStyle(
                      fontFamily: "NotoSansKR",
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
              SizedBox(height: 6),
              if (rating != null && rating.isRated) ...[
                LessonStarView(stars: rating.stars),
                if (rating.review.trim().isNotEmpty) ...[
                  SizedBox(height: 6),
                  Text(
                    rating.review.trim(),
                    style: TextStyle(
                      fontFamily: "NotoSansKR",
                      fontSize: 13,
                      height: 1.45,
                      color: Palette.grey700,
                    ),
                  ),
                ],
              ] else if (rating != null && rating.canStudentRate)
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton(
                    onPressed: () => _rateLesson(rating),
                    child: Text(tr(context, "별점 평가하기"),
                        style: TextStyle(fontFamily: "NotoSansKR")),
                  ),
                )
              else
                Text(
                  tr(context,
                      "화상수업을 마치면 이 자리에서 강사 별점을 남길 수 있습니다. 평가를 마치면 다음 회차가 열립니다."),
                  style: TextStyle(
                    fontFamily: "NotoSansKR",
                    fontSize: 13,
                    height: 1.5,
                    color: Palette.grey600,
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
    ).where((date) {
      return availability
          .openTimes(
            date,
            EnrollmentService.remainingTimeSlots(date),
          )
          .isNotEmpty;
    }).toList();
    final pickedDate = _selectedDates[week.id];
    final selectedDate = pickedDate != null &&
            dates.any((date) =>
                EnrollmentService.dateOnly(date) ==
                EnrollmentService.dateOnly(pickedDate))
        ? pickedDate
        : null;
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
                      tr(context, "화상수업 예약하기"),
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
                    TeacherClassTimeLine(
                      bands: availability.classBands,
                      closedRoutines: availability.routineKeys,
                    ),
                    if (otherTeacher) ...[
                      SizedBox(height: 2),
                      Text(
                        tr(context, "담당 선생님 대신 다른 원어민 수업입니다."),
                        style: TextStyle(
                          fontFamily: "NotoSansKR",
                          fontSize: 11,
                          color: Palette.accent,
                        ),
                      ),
                      if (bookingTeacher != null &&
                          bookingTeacher.accountUid.trim().isNotEmpty)
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => _pinMainTeacher(bookingTeacher),
                          child: Text(
                            tr(context, "이 강사를 메인 강사로 고정"),
                            style: TextStyle(
                              fontFamily: "NotoSansKR",
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
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
              _joinButton(_joinUrlForBooking(existing), enabled: true),
            ] else if (_showLockedJoin(existing)) ...[
              SizedBox(height: 8),
              Text(
                tr(context, "수업 일정이 확정되었습니다."),
                style: TextStyle(
                  fontFamily: "NotoSansKR",
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Palette.grey600,
                ),
              ),
              SizedBox(height: 12),
              _joinButton(_joinUrlForBooking(existing), enabled: false),
            ],
            SizedBox(height: 12),
            if (EnrollmentService.canStudentChangeBooking(existing)) ...[
              Text(
                tr(context, "수업 3시간 전까지 취소하거나 시간을 옮길 수 있습니다. 취소하면 강사 시간이 바로 비워집니다."),
                style: TextStyle(
                  fontFamily: "NotoSansKR",
                  fontSize: 12,
                  height: 1.45,
                  color: Palette.grey600,
                ),
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: _submittingBooking
                        ? null
                        : () => _cancelBooking(existing),
                    child: Text(tr(context, "예약 취소"),
                        style: TextStyle(fontFamily: "NotoSansKR", fontSize: 12)),
                  ),
                  OutlinedButton(
                    onPressed: _submittingBooking
                        ? null
                        : () {
                            setState(() {
                              _movingWeekId =
                                  _movingWeekId == week.id ? null : week.id;
                            });
                          },
                    child: Text(
                      _movingWeekId == week.id
                          ? tr(context, "옮기기 취소")
                          : tr(context, "시간 옮기기"),
                      style: TextStyle(fontFamily: "NotoSansKR", fontSize: 12),
                    ),
                  ),
                ],
              ),
            ] else
              Text(
                tr(context, "취소 가능 시각이 지나 예약이 그대로 남습니다. 수업 3시간 전까지만 강사 시간을 비울 수 있습니다."),
                style: TextStyle(
                  fontFamily: "NotoSansKR",
                  fontSize: 12,
                  height: 1.45,
                  color: Palette.grey600,
                ),
              ),
          ],
          if (existing == null &&
              _enrollment != null &&
              EnrollmentService.isEnrollmentExpired(_enrollment!)) ...[
            Text(
              tr(context, "수강 기한이 지났습니다. 연장 결제하면 이어서 들을 수 있습니다."),
              style: TextStyle(
                fontFamily: "NotoSansKR",
                fontSize: 13,
                height: 1.5,
                color: Palette.grey600,
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Palette.secondaryDark,
                foregroundColor: Palette.white,
              ),
              onPressed: _openExtension,
              child: Text(tr(context, "연장 결제"),
                  style: TextStyle(fontFamily: "Jalnan")),
            ),
          ] else if (existing == null || _movingWeekId == week.id) ...[
            if (existing == null) ...[
            Text(
              otherTeacher
                  ? tr(context, "수업은 20분입니다. 선택한 원어민 선생님이 열어 둔 시간만 예약할 수 있습니다. 담당 선생님이 아니어도 강사가 확인하면 확정됩니다.")
                  : tr(context, "수업은 20분입니다. 담당 원어민 선생님이 열어 둔 시간만 6:00 AM부터 11:00 PM까지 30분 단위로 선택할 수 있습니다. 강사가 확인하면 예약이 확정됩니다."),
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
                    tr(context, "다른 원어민 강사 수업 예약"),
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
                      tr(context, "담당 선생님으로 다시 예약"),
                      style: TextStyle(
                          fontFamily: "NotoSansKR", fontSize: 12),
                    ),
                  ),
              ],
            ),
            ],
            SizedBox(height: 10),
            Text(tr(context, "날짜 선택"),
                style: TextStyle(fontFamily: "NotoSansKR", fontSize: 13)),
            SizedBox(height: 8),
            if (dates.isEmpty)
              Text(
                tr(context, "선택할 수 있는 열린 날짜가 없습니다."),
                style: TextStyle(
                  fontFamily: "NotoSansKR",
                  fontSize: 13,
                  color: Palette.grey500,
                ),
              ),
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
              Text(tr(context, "시간 선택"),
                  style: TextStyle(fontFamily: "NotoSansKR", fontSize: 13)),
              SizedBox(height: 8),
              if (timeSlots.isEmpty)
                Text(
                  tr(context, "선택할 수 있는 열린 시간이 없습니다. 다른 날짜를 골라 주세요."),
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
                      : () => existing != null && _movingWeekId == week.id
                          ? _moveBooking(week, existing)
                          : _submitBooking(week),
                  child: Text(
                    existing != null && _movingWeekId == week.id
                        ? tr(context, "이 시간으로 옮기기")
                        : tr(context, "예약 신청"),
                    style: TextStyle(fontFamily: "Jalnan"),
                  ),
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
          tr(context, "강의 영상 자료"),
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
            tr(context, "등록된 강의 영상이 아직 없습니다."),
            style: TextStyle(
              fontFamily: "NotoSansKR",
              fontSize: 14,
              color: Palette.grey600,
            ),
          ),
          SizedBox(height: 6),
          Text(
            tr(context, "기본 영상 자료는 순차적으로 업로드될 예정입니다."),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
            ],
          ),
          if (lesson.videoUrl.isNotEmpty) ...[
            SizedBox(height: 12),
            YoutubeLessonPlayer(
              videoUrl: lesson.videoUrl,
              title: lesson.title.isNotEmpty ? lesson.title : '시청하기',
            ),
          ],
        ],
      ),
    );
  }
}
