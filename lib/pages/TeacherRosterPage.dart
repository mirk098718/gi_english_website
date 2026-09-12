import 'package:flutter/material.dart';
import 'package:gi_english_website/class/OnlineCourse.dart';
import 'package:gi_english_website/class/OnlineNativeTeacher.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/EnrollmentService.dart';
import 'package:gi_english_website/util/LessonFeedbackService.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/PhoneUtil.dart';
import 'package:gi_english_website/util/UrlIUtil.dart';
import 'package:gi_english_website/pages/AdminTeacherScheduleTab.dart';
import 'package:gi_english_website/pages/StudentDetailPage.dart';
import 'package:gi_english_website/widget/AdminContentWidth.dart';
import 'package:gi_english_website/widget/StudentLearningProgressPanel.dart';
import 'package:gi_english_website/widget/TeacherMonthLessonSummary.dart';
import 'package:gi_english_website/widget/NotificationBellButton.dart';

/// 강사 프로필 · 담당 회원 · 화상수업 입장/종료 · 피드백.
/// 강사 관리에서 열면 스케줄과 한달 이력 탭이 함께 보인다.
class TeacherRosterPage extends StatelessWidget {
  final Map<String, dynamic>? teacher;
  final bool embedded;

  const TeacherRosterPage({
    Key? key,
    this.teacher,
    this.embedded = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final body = TeacherRosterView(teacher: teacher);
    if (embedded) return body;
    final uid = teacher?['uid']?.toString() ?? '';
    final name = teacher?['name']?.toString() ?? '강사';
    Widget themed(Widget child) {
      return Theme(data: Palette.adminTheme(Theme.of(context)), child: child);
    }

    if (uid.isEmpty) {
      return themed(Scaffold(
        backgroundColor: Palette.white,
        appBar: AppBar(
          title: Text('강사 프로필 · 담당 회원',
              style: TextStyle(fontFamily: "NotoSansKR")),
          backgroundColor: Palette.navy,
          foregroundColor: Palette.white,
          actions: const [
            NotificationBellButton(light: true),
            SizedBox(width: 8),
          ],
        ),
        body: AdminContentWidth(child: body),
      ));
    }
    return themed(DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Palette.white,
        appBar: AppBar(
          title: Text(name, style: TextStyle(fontFamily: "NotoSansKR")),
          backgroundColor: Palette.navy,
          foregroundColor: Palette.white,
          actions: const [
            NotificationBellButton(light: true),
            SizedBox(width: 8),
          ],
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: Palette.white,
            labelColor: Palette.white,
            unselectedLabelColor: Palette.white.withValues(alpha: 0.7),
            labelStyle: TextStyle(
                fontFamily: "NotoSansKR", fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: '프로필·회원'),
              Tab(text: '스케줄·예약'),
              Tab(text: '한달 이력'),
            ],
          ),
        ),
        body: AdminContentWidth(
          child: TabBarView(
            children: [
              body,
              AdminTeacherScheduleTab(teacherUid: uid),
              TeacherMonthHistoryPanel(teacherUid: uid, teacherName: name),
            ],
          ),
        ),
      ),
    ));
  }
}

class TeacherRosterView extends StatefulWidget {
  final Map<String, dynamic>? teacher;

  const TeacherRosterView({Key? key, this.teacher}) : super(key: key);

  @override
  State<TeacherRosterView> createState() => _TeacherRosterViewState();
}

class _TeacherRosterViewState extends State<TeacherRosterView> {
  Map<String, dynamic>? _teacher;
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _guestMembers = [];
  List<WeekBooking> _bookings = [];
  List<LessonFeedback> _feedbacks = [];
  List<OnlineSession> _sessions = [];
  List<EnrollmentRecord> _enrollments = [];
  Map<String, List<StudentWeekProgress>> _learning = {};
  bool _loading = true;
  String _staffUid = '';
  bool _isOwner = false;
  String _writerName = '';
  bool _busy = false;

  String get _teacherUid => _teacher?['uid']?.toString() ?? '';

  bool get _canWrite =>
      _isOwner || (_staffUid.isNotEmpty && _staffUid == _teacherUid);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final isOwner = await AuthService.isAdmin();
    final staffUid = await AuthService.currentStaffUid();
    final writerName = await AuthService.getAdminName();
    Map<String, dynamic>? teacher = widget.teacher;
    if (teacher == null || (teacher['uid']?.toString() ?? '').isEmpty) {
      teacher = await AuthService.currentStaffProfile();
    }
    final teacherUid = teacher?['uid']?.toString() ?? '';
    final members = teacherUid.isEmpty
        ? <Map<String, dynamic>>[]
        : await AuthService.listMembers(teacherId: teacherUid);
    final bookings = await EnrollmentService.weekBookingsForTeacher(teacherUid);
    if (teacherUid.isNotEmpty) {
      await EnrollmentService.backfillSessionsForTeacher(teacherUid);
    }
    final sessions = teacherUid.isEmpty
        ? <OnlineSession>[]
        : await EnrollmentService.sessionsForTeacher(teacherUid);
    final byId = <String, Map<String, dynamic>>{};
    for (final member in members) {
      final id = member['uid']?.toString() ?? '';
      if (id.isNotEmpty) byId[id] = member;
    }
    final myIds = byId.keys.toSet();
    final guestById = <String, Map<String, dynamic>>{};
    for (final booking in bookings) {
      if (booking.userId.isEmpty || myIds.contains(booking.userId)) continue;
      guestById.putIfAbsent(booking.userId, () {
        return {
          'uid': booking.userId,
          'name': booking.memberName,
          'email': booking.email,
          'assignedTeacherName': booking.assignedTeacherName,
        };
      });
    }
    final feedbacks = await LessonFeedbackService.listForTeacher(teacherUid);
    final userIds = {...byId.keys, ...guestById.keys}.toList();
    final enrollments =
        await EnrollmentService.listEnrollments(memberIds: userIds);
    final learning = await EnrollmentService.learningByEnrollment(enrollments);
    if (!mounted) return;
    setState(() {
      _teacher = teacher;
      _members = byId.values.toList()
        ..sort((a, b) => (a['name']?.toString() ?? '')
            .compareTo(b['name']?.toString() ?? ''));
      _guestMembers = guestById.values.toList()
        ..sort((a, b) => (a['name']?.toString() ?? '')
            .compareTo(b['name']?.toString() ?? ''));
      _bookings = bookings;
      _feedbacks = feedbacks;
      _sessions = sessions;
      _enrollments = enrollments;
      _learning = learning;
      _staffUid = staffUid;
      _isOwner = isOwner;
      _writerName = writerName;
      _loading = false;
    });
  }

  void _toast(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontFamily: "NotoSansKR")),
        backgroundColor: error ? Palette.danger : Palette.success,
      ),
    );
  }

  List<WeekBooking> _bookingsFor(String memberId) {
    return _bookings.where((b) => b.userId == memberId).toList();
  }

  OnlineSession? _sessionFor(WeekBooking booking) {
    final expected = booking.sessionId.trim().isNotEmpty
        ? booking.sessionId.trim()
        : EnrollmentService.sessionDocIdForBooking(booking.id);
    for (final session in _sessions) {
      if (session.id == expected || session.bookingId == booking.id) {
        return session;
      }
    }
    return null;
  }

  String _sessionIdFor(WeekBooking booking) {
    final session = _sessionFor(booking);
    if (session != null) return session.id;
    if (booking.sessionId.trim().isNotEmpty) return booking.sessionId.trim();
    return EnrollmentService.sessionDocIdForBooking(booking.id);
  }

  Future<void> _openFeedback(WeekBooking booking,
      {bool afterClass = false}) async {
    final existing =
        LessonFeedbackService.forBooking(_feedbacks, booking.id);
    final saved = await LessonFeedbackService.showEditor(
      context: context,
      booking: booking,
      existing: existing,
      canWrite: _canWrite,
      teacherId: _teacherUid,
      teacherName: (_teacher?['name']?.toString() ?? '').trim().isNotEmpty
          ? _teacher!['name'].toString()
          : _writerName,
    );
    if (saved) {
      _toast(afterClass ? '피드백을 저장했습니다. 수업이 마무리되었습니다.' : '피드백을 저장했습니다.');
      await _load();
    } else if (afterClass && mounted) {
      await _load();
    }
  }

  Future<void> _enterAsHost(WeekBooking booking) async {
    if (_busy) return;
    if (!booking.isConfirmed) {
      _toast('확정된 예약만 화상수업으로 입장할 수 있습니다.', error: true);
      return;
    }
    setState(() => _busy = true);
    final url = EnrollmentService.meetingUrlForBooking(
      courseId: booking.courseId,
      bookingId: booking.id,
    );
    final session = _sessionFor(booking);
    final openUrl =
        (session != null && session.meetingUrl.trim().isNotEmpty)
            ? session.meetingUrl
            : url;
    await UrlUtil.open(openUrl);
    final error = await EnrollmentService.setSessionLive(
      sessionId: _sessionIdFor(booking),
      isLive: true,
      hostName: _writerName,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      _toast(error, error: true);
      return;
    }
    _toast('호스트로 입장했습니다. 수강생도 입장할 수 있습니다.');
    await _load();
  }

  Future<void> _endClass(WeekBooking booking) async {
    if (_busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('수업 종료', style: TextStyle(fontFamily: "Jalnan")),
        content: Text(
          '이 회차 화상수업을 종료할까요?\n종료 후 바로 피드백을 작성할 수 있습니다.',
          style: TextStyle(fontFamily: "NotoSansKR", height: 1.5),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text('취소')),
          ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text('수업 종료')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    final error = await EnrollmentService.setSessionLive(
      sessionId: _sessionIdFor(booking),
      isLive: false,
      hostName: _writerName,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      _toast(error, error: true);
      return;
    }
    _toast('수업을 종료했습니다. 피드백을 작성해 주세요.');
    await _openFeedback(booking, afterClass: true);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(child: CircularProgressIndicator());
    }
    if (_teacherUid.isEmpty) {
      return Center(
        child: Text('강사 정보를 찾을 수 없습니다.',
            style: TextStyle(fontFamily: "NotoSansKR")),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.all(20),
        children: [
          _profileCard(),
          SizedBox(height: 24),
          Text('내 수강생', style: TextStyle(fontFamily: "Jalnan", fontSize: 16)),
          SizedBox(height: 8),
          Text(
            '담당 회원의 화상수업 입장·종료와 회차별 피드백을 여기서 진행합니다. '
            '수업 종료 직후 피드백 창이 열립니다.',
            style: TextStyle(
                fontFamily: "NotoSansKR", fontSize: 13, color: Palette.grey600),
          ),
          SizedBox(height: 16),
          if (_members.isEmpty)
            Text('아직 배정된 회원이 없습니다.',
                style: TextStyle(
                    fontFamily: "NotoSansKR", color: Palette.grey500))
          else
            ..._members.map(_memberCard),
          SizedBox(height: 28),
          Text('타 수강생', style: TextStyle(fontFamily: "Jalnan", fontSize: 16)),
          SizedBox(height: 8),
          Text(
            '다른 강사 담당이지만 내 스케줄로 예약한 수강생입니다. 컨펌하면 수업 횟수에 포함됩니다.',
            style: TextStyle(
                fontFamily: "NotoSansKR", fontSize: 13, color: Palette.grey600),
          ),
          SizedBox(height: 16),
          if (_guestMembers.isEmpty)
            Text('아직 타 수강생 수업이 없습니다.',
                style: TextStyle(
                    fontFamily: "NotoSansKR", color: Palette.grey500))
          else
            ..._guestMembers.map((member) => _memberCard(member, guest: true)),
          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _profileCard() {
    final teacher = _teacher ?? {};
    final name = teacher['name']?.toString() ?? '';
    final email = teacher['email']?.toString() ?? '';
    final nationality = teacher['nationality']?.toString() ?? '';
    final intro = teacher['intro']?.toString() ?? '';
    final photoUrl = teacher['photoUrl']?.toString() ?? '';
    final phone = teacher['phone']?.toString() ?? '';
    final isOwnerTeacher = teacher['role']?.toString() != 'teacher';
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Palette.grey50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Palette.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _photo(photoUrl, 88),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOwnerTeacher ? '$name (메인 관리자 · 강사)' : name,
                      style: TextStyle(fontFamily: "Jalnan", fontSize: 18),
                    ),
                    if (email.isNotEmpty) ...[
                      SizedBox(height: 6),
                      Text(email,
                          style: TextStyle(
                              fontFamily: "NotoSansKR",
                              fontSize: 13,
                              color: Palette.grey600)),
                    ],
                    if (PhoneUtil.isValid(phone)) ...[
                      SizedBox(height: 6),
                      Text(PhoneUtil.display(phone),
                          style: TextStyle(
                              fontFamily: "NotoSansKR",
                              fontSize: 13,
                              color: Palette.grey600)),
                    ],
                    if (_canWrite && AuthService.bankLabel(teacher).isNotEmpty) ...[
                      SizedBox(height: 6),
                      Text(
                        AuthService.bankLabel(teacher),
                        style: TextStyle(
                            fontFamily: "NotoSansKR",
                            fontSize: 13,
                            color: Palette.grey600),
                      ),
                    ],
                    if (nationality.isNotEmpty) ...[
                      SizedBox(height: 8),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Palette.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Palette.grey200),
                        ),
                        child: Text(nationality,
                            style: TextStyle(
                                fontFamily: "NotoSansKR",
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            intro.trim().isEmpty ? '소개가 아직 없습니다.' : intro,
            style: TextStyle(
              fontFamily: "NotoSansKR",
              fontSize: 14,
              height: 1.5,
              color: Palette.grey700,
            ),
          ),
          SizedBox(height: 10),
          Text(
            '내 수강생 ${_members.length}명 · 타 수강생 ${_guestMembers.length}명 · 화상수업 ${_bookings.length}건',
            style: TextStyle(
                fontFamily: "NotoSansKR",
                fontSize: 12,
                color: Palette.grey500),
          ),
          if (isOwnerTeacher && _canWrite) ...[
            SizedBox(height: 16),
            Text('수업 받기',
                style: TextStyle(fontFamily: "Jalnan", fontSize: 14)),
            SizedBox(height: 6),
            Text(
              '결제 때 고르는 강사와, 다른 강사 수강생의 코티칭을 따로 켤 수 있습니다.',
              style: TextStyle(
                  fontFamily: "NotoSansKR",
                  fontSize: 12,
                  color: Palette.grey600),
            ),
            SizedBox(height: 10),
            _offerTile(TeacherBookingOffer.both),
            _offerTile(TeacherBookingOffer.coteach),
            _offerTile(TeacherBookingOffer.off),
          ],
        ],
      ),
    );
  }

  String get _bookingOffer =>
      TeacherBookingOffer.resolve(_teacher, isOwner: true);

  Widget _offerTile(String offer) {
    final selected = _bookingOffer == offer;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? Palette.secondaryDark.withValues(alpha: 0.08)
            : Palette.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: _busy ? null : () => _setBookingOffer(offer),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.maxFinite,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? Palette.secondaryDark : Palette.grey200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  size: 20,
                  color: selected ? Palette.secondaryDark : Palette.grey400,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        TeacherBookingOffer.label(offer),
                        style: TextStyle(
                          fontFamily: "NotoSansKR",
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        TeacherBookingOffer.description(offer),
                        style: TextStyle(
                          fontFamily: "NotoSansKR",
                          fontSize: 12,
                          color: Palette.grey600,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _setBookingOffer(String offer) async {
    if (_bookingOffer == offer || _teacherUid.isEmpty) return;
    setState(() => _busy = true);
    final error = await AuthService.updateBookingOffer(
      teacherUid: _teacherUid,
      offer: offer,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (error == null) {
        final next = Map<String, dynamic>.from(_teacher ?? {});
        next['bookingOffer'] = offer;
        _teacher = next;
      }
    });
    if (error != null) {
      _toast(error, error: true);
      return;
    }
    _toast('수업 받기 설정을 저장했습니다.');
  }

  Widget _photo(String url, double size) {
    final provider = OnlineNativeTeacher.imageProviderOf(url);
    if (provider == null) {
      return Container(
        width: size,
        height: size,
        color: Palette.grey200,
        child: Icon(Icons.person, color: Palette.grey400),
      );
    }
    return Image(
      image: provider,
      width: size,
      height: size,
      fit: BoxFit.cover,
    );
  }

  Widget _memberCard(Map<String, dynamic> member, {bool guest = false}) {
    final memberId = member['uid']?.toString() ?? '';
    final name = member['name']?.toString() ?? '';
    final email = member['email']?.toString() ?? '';
    final assignedTeacherName = member['assignedTeacherName']?.toString() ?? '';
    final lessons = _bookingsFor(memberId);
    final records =
        _enrollments.where((item) => item.userId == memberId).toList();
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: guest
              ? Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Palette.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '타',
                    style: TextStyle(
                      fontFamily: "NotoSansKR",
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Palette.accent,
                    ),
                  ),
                )
              : null,
          title: Text(
            name.isEmpty ? email : name,
            style:
                TextStyle(fontFamily: "NotoSansKR", fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            [
              if (email.isNotEmpty) email,
              if (guest && assignedTeacherName.isNotEmpty)
                '담당 $assignedTeacherName',
              '화상수업 ${lessons.length}건',
            ].join(' · '),
            style: TextStyle(
                fontFamily: "NotoSansKR", fontSize: 12, color: Palette.grey600),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StudentDetailPage(
                        member: member,
                        teacherName: guest
                            ? assignedTeacherName
                            : AuthService.memberTeacherName(member),
                      ),
                    ),
                  );
                  if (!mounted) return;
                  await _load();
                },
                icon: Icon(Icons.person_outline, size: 18),
                label: Text('회원 상세 · 결제',
                    style: TextStyle(fontFamily: "NotoSansKR")),
              ),
            ),
            SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: StudentLearningProgressPanel(
                enrollments: records,
                progressByEnrollment: _learning,
              ),
            ),
            SizedBox(height: 16),
            if (lessons.isEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '아직 화상수업 이력이 없습니다.',
                  style: TextStyle(
                      fontFamily: "NotoSansKR",
                      fontSize: 13,
                      color: Palette.grey500),
                ),
              )
            else
              ...lessons.map((booking) => _lessonRow(booking)),
          ],
        ),
      ),
    );
  }

  Widget _lessonRow(WeekBooking booking) {
    final feedback = LessonFeedbackService.forBooking(_feedbacks, booking.id);
    final written = feedback != null && feedback.hasContent;
    final course = OnlineCourse.findById(booking.courseId);
    final session = _sessionFor(booking);
    final live = session?.isLiveNow == true;
    final ended = session?.isFinished == true || session?.isStale == true;
    final canHost = _canWrite && booking.isConfirmed && !ended;
    final canEnd = _canWrite &&
        booking.isConfirmed &&
        (live || (session?.isLive == true) || !ended);

    return Container(
      width: double.maxFinite,
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Palette.grey50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: live ? Palette.success : Palette.grey200,
            width: live ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            [
              if (booking.weekNumber > 0) '${booking.weekNumber}회차',
              if (course != null) course.title,
            ].join(' · '),
            style: TextStyle(
                fontFamily: "NotoSansKR",
                fontSize: 13,
                fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 4),
          Text(
            '${EnrollmentService.formatBookingDate(booking.date)} ${EnrollmentService.formatBookingTime(booking.time)} · ${booking.statusLabel}'
            '${live ? ' · 수업 중' : ended ? ' · 수업 종료' : ''}',
            style: TextStyle(
                fontFamily: "NotoSansKR", fontSize: 12, color: Palette.grey600),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: written
                      ? Palette.secondary.withValues(alpha: 0.12)
                      : Palette.grey200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  written ? '피드백 작성됨' : '피드백 미작성',
                  style: TextStyle(
                    fontFamily: "NotoSansKR",
                    fontSize: 11,
                    color: written ? Palette.secondaryDark : Palette.grey600,
                  ),
                ),
              ),
              if (canHost)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Palette.darkTeal,
                    foregroundColor: Palette.white,
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: _busy ? null : () => _enterAsHost(booking),
                  icon: Icon(Icons.videocam, size: 16),
                  label: Text('호스트로 입장',
                      style: TextStyle(fontFamily: "NotoSansKR", fontSize: 12)),
                ),
              if (canEnd && !ended)
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _endClass(booking),
                  icon: Icon(Icons.stop_circle, size: 16),
                  label: Text('수업 종료',
                      style: TextStyle(fontFamily: "NotoSansKR", fontSize: 12)),
                ),
              TextButton(
                onPressed: () => _openFeedback(booking),
                child: Text(
                  written
                      ? (_canWrite ? '피드백 확인 · 수정' : '피드백 확인')
                      : (_canWrite ? '피드백 작성' : '확인'),
                  style: TextStyle(
                      fontFamily: "NotoSansKR", color: Palette.secondaryDark),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
