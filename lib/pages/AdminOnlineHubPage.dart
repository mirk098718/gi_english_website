import 'dart:async';
import 'dart:typed_data';

// ignore: deprecated_member_use
import 'dart:html' as html;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gi_english_website/class/OnlineCourse.dart';
import 'package:gi_english_website/class/OnlineNativeTeacher.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/EnrollmentService.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/PhoneUtil.dart';
import 'package:gi_english_website/pages/AdminTeacherScheduleTab.dart';
import 'package:gi_english_website/pages/AdminWeekCurriculumTab.dart';
import 'package:gi_english_website/pages/AdminMembersHubPage.dart';
import 'package:gi_english_website/pages/AdminPaymentTab.dart';
import 'package:gi_english_website/pages/StudentDetailPage.dart';
import 'package:gi_english_website/pages/TeacherRosterPage.dart';
import 'package:gi_english_website/util/UrlIUtil.dart';
import 'package:gi_english_website/widget/TeacherPhotoCropDialog.dart';
import 'package:gi_english_website/widget/StudentLearningProgressPanel.dart';
import 'package:gi_english_website/widget/AdminContentWidth.dart';
import 'package:gi_english_website/widget/NotificationBellButton.dart';

/// 관리자/강사용 온라인 프로그램 관리 허브.
/// - 메인 관리자: 회원관리(내 스케줄·내 수강생·전체 스케줄·모든 수강생), 결제·정산, 강사 관리, 주간 학습
/// - 원어민 강사: 회원관리(내 스케줄·내 수강생)
class AdminOnlineHubPage extends StatefulWidget {
  const AdminOnlineHubPage({Key? key}) : super(key: key);

  @override
  _AdminOnlineHubPageState createState() => _AdminOnlineHubPageState();
}

class _AdminOnlineHubPageState extends State<AdminOnlineHubPage>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  bool _authorized = false;
  bool _checking = true;
  AdminRole _role = AdminRole.none;

  @override
  void initState() {
    super.initState();
    _checkStaff();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _checkStaff() async {
    final isStaff = await AuthService.isStaff();
    final role = await AuthService.getAdminRole();
    if (!mounted) return;

    if (!isStaff) {
      setState(() {
        _authorized = false;
        _checking = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('관리자 또는 강사 권한이 필요합니다.',
              style: TextStyle(fontFamily: "NotoSansKR")),
          backgroundColor: Palette.danger,
        ),
      );
      Navigator.pop(context);
      return;
    }

    _tabController?.dispose();
    _tabController = role == AdminRole.owner
        ? TabController(length: 4, vsync: this)
        : null;

    setState(() {
      _role = role;
      _authorized = true;
      _checking = false;
    });
    if (role == AdminRole.owner) {
      AuthService.publishTeacherProfiles();
    }
  }

  Widget _shell(Widget child) {
    return Theme(data: Palette.adminTheme(Theme.of(context)), child: child);
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return _shell(const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ));
    }
    if (!_authorized) {
      return _shell(const Scaffold(body: SizedBox.shrink()));
    }

    final isOwner = _role == AdminRole.owner;
    final members = AdminMembersHubPage(
      role: isOwner ? AdminRole.owner : AdminRole.teacher,
      mySchedule: const AdminTeacherScheduleTab(),
      myStudents: isOwner
          ? AdminEnrollmentTab(
              role: AdminRole.owner,
              mineAndCoteachOnly: true,
            )
          : const TeacherRosterPage(embedded: true),
    );

    return _shell(Scaffold(
      appBar: AppBar(
        title: Text(
          isOwner ? '온라인 프로그램 관리' : '수업 관리',
          style: TextStyle(fontFamily: "NotoSansKR"),
        ),
        backgroundColor: Palette.navy,
        foregroundColor: Palette.white,
        actions: const [
          NotificationBellButton(light: true),
          SizedBox(width: 8),
        ],
        bottom: isOwner
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: Palette.white,
                labelColor: Palette.white,
                unselectedLabelColor: Palette.white.withValues(alpha: 0.7),
                labelStyle: TextStyle(
                    fontFamily: "NotoSansKR", fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: '회원관리'),
                  Tab(text: '결제내역'),
                  Tab(text: '강사 관리'),
                  Tab(text: '주간 학습'),
                ],
              )
            : null,
      ),
      body: AdminContentWidth(
        child: isOwner
            ? TabBarView(
                controller: _tabController,
                children: [
                  members,
                  AdminPaymentTab(),
                  AdminTeacherTab(),
                  AdminWeekCurriculumTab(),
                ],
              )
            : members,
      ),
    ));
  }
}

// ---------------------------------------------------------------------------
// 수강 배정 탭
// ---------------------------------------------------------------------------

class AdminEnrollmentTab extends StatefulWidget {
  final AdminRole role;
  final bool mineAndCoteachOnly;

  AdminEnrollmentTab({
    this.role = AdminRole.owner,
    this.mineAndCoteachOnly = false,
  });

  @override
  _AdminEnrollmentTabState createState() => _AdminEnrollmentTabState();
}

class _AdminEnrollmentTabState extends State<AdminEnrollmentTab> {
  final emailController = TextEditingController();
  final sessionsController = TextEditingController(text: '8');
  OnlineCourse? _selectedCourse = OnlineCourse.all.first;
  List<EnrollmentRecord> _enrollments = [];
  Map<String, List<StudentWeekProgress>> _learning = {};
  List<Map<String, dynamic>> _members = [];
  bool _loading = true;
  bool _saving = false;
  String _adminName = '';
  String? _staffUid;
  final _bannerKey = GlobalKey<LiveSessionBannerState>();
  bool get _isOwner => widget.role == AdminRole.owner;

  @override
  void initState() {
    super.initState();
    _loadAdminName();
    _refresh();
  }

  Future<void> _loadAdminName() async {
    final name = await AuthService.getAdminName();
    final uid = await AuthService.getStaffUid();
    if (!mounted) return;
    setState(() {
      _adminName = name;
      _staffUid = uid;
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    sessionsController.dispose();
    super.dispose();
  }

  Future<void> _assign() async {
    final email = emailController.text.trim();
    if (email.isEmpty || _selectedCourse == null) {
      _toast('회원 이메일과 과정을 선택해주세요.', error: true);
      return;
    }

    final totalSessions = int.tryParse(sessionsController.text.trim()) ?? 0;

    setState(() {
      _saving = true;
    });

    final allowedIds = _isOwner
        ? null
        : _members.map((m) => m['uid']?.toString() ?? '').toList();

    final error = await EnrollmentService.assignCourseByEmail(
      email: email,
      courseId: _selectedCourse!.id,
      totalSessions: totalSessions,
      allowedMemberIds: allowedIds,
    );

    if (!mounted) return;
    setState(() {
      _saving = false;
    });

    if (error != null) {
      _toast(error, error: true);
      return;
    }

    _toast('수강이 배정되었습니다.');
    emailController.clear();
    await _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
    });

    List<Map<String, dynamic>> members;
    List<EnrollmentRecord> enrollments;

    if (_isOwner && !widget.mineAndCoteachOnly) {
      members = await AuthService.listMembers();
      enrollments = await EnrollmentService.listEnrollments();
    } else {
      final uid = _staffUid ?? await AuthService.getStaffUid() ?? '';
      members = await _membersForTeacher(uid);
      final memberIds = members.map((m) => m['uid']?.toString() ?? '').toList();
      enrollments =
          await EnrollmentService.listEnrollments(memberIds: memberIds);
    }

    final learning = await EnrollmentService.learningByEnrollment(enrollments);
    if (!mounted) return;
    setState(() {
      _enrollments = enrollments;
      _learning = learning;
      _members = members;
      _loading = false;
    });
    _bannerKey.currentState?.reload();
  }

  Future<List<Map<String, dynamic>>> _membersForTeacher(String teacherUid) async {
    if (teacherUid.isEmpty) return [];
    final assigned =
        await AuthService.listMembers(teacherId: teacherUid, limit: 500);
    final byId = <String, Map<String, dynamic>>{};
    for (final member in assigned) {
      final id = member['uid']?.toString() ?? '';
      if (id.isEmpty) continue;
      byId[id] = member;
    }
    final bookings =
        await EnrollmentService.weekBookingsForTeacher(teacherUid);
    for (final booking in bookings) {
      if (booking.userId.isEmpty || byId.containsKey(booking.userId)) continue;
      byId[booking.userId] = {
        'uid': booking.userId,
        'name': booking.memberName,
        'email': booking.email,
        'assignedTeacherName': booking.assignedTeacherName,
        'isCoteachGuest': true,
      };
    }
    final list = byId.values.toList()
      ..sort((a, b) {
        final guestA = a['isCoteachGuest'] == true;
        final guestB = b['isCoteachGuest'] == true;
        if (guestA != guestB) return guestA ? 1 : -1;
        return (a['name']?.toString() ?? '')
            .compareTo(b['name']?.toString() ?? '');
      });
    return list;
  }

  void _toast(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontFamily: "NotoSansKR")),
        backgroundColor: error ? Palette.danger : Palette.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: EdgeInsets.all(20),
        children: [
          LiveSessionBanner(key: _bannerKey, hostName: _adminName),
          Text('내 수강생 관리', style: TextStyle(fontFamily: "Jalnan", fontSize: 18)),
          SizedBox(height: 8),
          Text(
            '나에게 배정된 수강생과, 코티칭으로 들어온 수강생만 보여 줍니다. '
            '회차 차감과 결제 기록을 여기서 관리하세요.',
            style: TextStyle(
                fontFamily: "NotoSansKR", fontSize: 13, color: Palette.grey600),
          ),
          SizedBox(height: 12),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: false,
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.only(bottom: 8),
              leading: Icon(Icons.playlist_add, color: Palette.navy),
              title: Text('수동 과정 배정',
                  style: TextStyle(fontFamily: "Jalnan", fontSize: 16)),
              subtitle: Text(
                '오프라인 이전, 체험, 결제 복구가 필요할 때만 펼치세요.',
                style: TextStyle(
                    fontFamily: "NotoSansKR",
                    fontSize: 12,
                    color: Palette.grey600),
              ),
              children: [
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: '회원 이메일',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Palette.white,
                  ),
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<OnlineCourse>(
                  initialValue: _selectedCourse,
                  decoration: InputDecoration(
                    labelText: '과정 선택',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Palette.white,
                  ),
                  items: OnlineCourse.all
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text('${c.order}. ${c.title} (${c.subtitle})',
                                style: TextStyle(
                                    fontFamily: "NotoSansKR", fontSize: 13)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCourse = value;
                    });
                  },
                ),
                SizedBox(height: 12),
                TextField(
                  controller: sessionsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '전체 화상수업 횟수',
                    suffixText: '회',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Palette.white,
                  ),
                ),
                SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Palette.darkTeal,
                      foregroundColor: Palette.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    onPressed: _saving ? null : _assign,
                    child: _saving
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Palette.white),
                          )
                        : Text('배정하기', style: TextStyle(fontFamily: "Jalnan")),
                  ),
                ),
                if (_members.isNotEmpty) ...[
                  SizedBox(height: 16),
                  Text('담당·코티칭 회원에서 이메일 채우기',
                      style: TextStyle(fontFamily: "Jalnan", fontSize: 14)),
                  ..._members.take(12).map((m) {
                    final email = m['email']?.toString() ?? '';
                    final name = m['name']?.toString() ?? '';
                    if (email.isEmpty) return SizedBox.shrink();
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text('$name ($email)',
                          style:
                              TextStyle(fontFamily: "NotoSansKR", fontSize: 13)),
                      trailing: TextButton(
                        onPressed: () {
                          emailController.text = email;
                        },
                        child: Text('선택',
                            style: TextStyle(
                                fontFamily: "NotoSansKR",
                                color: Palette.secondaryDark)),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
          if (_isOwner) ...[
            Divider(height: 32),
            Text('결제·수강 내역 요약',
                style: TextStyle(fontFamily: "Jalnan", fontSize: 16)),
            SizedBox(height: 8),
            Text(
              '내 수강생 배정 ${_enrollments.length}건 · 결제완료 ${_enrollments.where((e) => e.isPaid).length}건 · 미결제 ${_enrollments.where((e) => !e.isPaid).length}건',
              style: TextStyle(
                  fontFamily: "NotoSansKR",
                  fontSize: 13,
                  color: Palette.secondaryDark,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '각 수업 카드의 ‘결제 정보’에서 결제 여부와 금액을 기록할 수 있습니다.',
              style: TextStyle(
                  fontFamily: "NotoSansKR",
                  fontSize: 12,
                  color: Palette.grey600),
            ),
          ],
          Divider(height: 32),
          Text('담당·코티칭 수강생',
              style: TextStyle(fontFamily: "Jalnan", fontSize: 16)),
          SizedBox(height: 8),
          Text(
            '배정된 수업에서 회차를 보정하고, 이름을 눌러 회원 상세·결제를 볼 수 있습니다.',
            style: TextStyle(
                fontFamily: "NotoSansKR", fontSize: 13, color: Palette.grey600),
          ),
          SizedBox(height: 12),
          if (_loading)
            Center(child: CircularProgressIndicator())
          else if (_members.isEmpty)
            Text('아직 담당하거나 코티칭으로 들어온 수강생이 없습니다.',
                style:
                    TextStyle(fontFamily: "NotoSansKR", color: Palette.grey500))
          else
            ..._members.map(_memberCard),
        ],
      ),
    );
  }

  Widget _memberCard(Map<String, dynamic> member) {
    final uid = member['uid']?.toString() ?? '';
    final name = member['name']?.toString().trim() ?? '';
    final email = member['email']?.toString().trim() ?? '';
    final guest = member['isCoteachGuest'] == true;
    final assignedTeacherName =
        member['assignedTeacherName']?.toString().trim() ?? '';
    final records =
        _enrollments.where((record) => record.userId == uid).toList();

    return Card(
      margin: EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: records.isNotEmpty,
        leading: guest
            ? Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Palette.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '코티칭',
                  style: TextStyle(
                    fontFamily: "NotoSansKR",
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Palette.accent,
                  ),
                ),
              )
            : CircleAvatar(
                backgroundColor: Palette.darkTeal,
                foregroundColor: Palette.white,
                child: Text(name.isEmpty ? '?' : name.substring(0, 1),
                    style: TextStyle(fontFamily: "NotoSansKR")),
              ),
        title: Text(name.isEmpty ? '이름 미등록 회원' : name,
            style: TextStyle(
                fontFamily: "NotoSansKR",
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        subtitle: Text(
          [
            if (email.isNotEmpty) email,
            if (guest && assignedTeacherName.isNotEmpty)
              '담당 $assignedTeacherName',
            '배정 ${records.length}개',
          ].join(' · '),
          style: TextStyle(fontFamily: "NotoSansKR", fontSize: 12),
        ),
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: email.isEmpty ? null : () => _showAssignDialog(email),
                  icon: Icon(Icons.add, size: 18),
                  label:
                      Text('수업 배정', style: TextStyle(fontFamily: "NotoSansKR")),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Palette.darkTeal,
                    foregroundColor: Palette.white,
                  ),
                ),
                OutlinedButton.icon(
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
                    await _refresh();
                  },
                  icon: Icon(Icons.person_outline, size: 18),
                  label: Text('회원 상세',
                      style: TextStyle(fontFamily: "NotoSansKR")),
                ),
              ],
            ),
          ),
          if (records.isEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 18),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('배정된 수업이 없습니다.',
                    style: TextStyle(
                        fontFamily: "NotoSansKR", color: Palette.grey500)),
              ),
            )
          else
            ...records.map(_enrollmentTile),
        ],
      ),
    );
  }

  Widget _enrollmentTile(EnrollmentRecord record) {
    final course = record.course;
    final title =
        course == null ? record.courseId : '${course.order}. ${course.title}';
    final sessionsConfigured = record.totalSessions > 0;

    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: record.isActive ? Palette.white : Palette.grey100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Palette.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: TextStyle(
                        fontFamily: "NotoSansKR", fontWeight: FontWeight.bold)),
              ),
              if (!record.isActive)
                Text('배정 취소됨',
                    style: TextStyle(
                        fontFamily: "NotoSansKR",
                        fontSize: 12,
                        color: Palette.danger)),
            ],
          ),
          SizedBox(height: 8),
          Text(
            sessionsConfigured
                ? '진행 ${record.completedSessions}회 / 전체 ${record.totalSessions}회 · 남은 ${record.remainingSessions}회'
                : '수업 횟수 미설정',
            style: TextStyle(
                fontFamily: "NotoSansKR",
                fontSize: 13,
                color:
                    sessionsConfigured ? Palette.secondaryDark : Palette.danger,
                fontWeight: FontWeight.bold),
          ),
          if (record.lastSessionAt != null) ...[
            SizedBox(height: 4),
            Text(
              '최근 수업 처리: ${_formatDateTime(record.lastSessionAt)}',
              style: TextStyle(
                  fontFamily: "NotoSansKR",
                  fontSize: 12,
                  color: Palette.grey500),
            ),
          ],
          if (_isOwner) ...[
            SizedBox(height: 4),
            Text(
              record.isPaid
                  ? '결제 완료${record.paidAmount > 0 ? ' · ${record.paidAmount}원' : ''}'
                  : '미결제',
              style: TextStyle(
                  fontFamily: "NotoSansKR",
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: record.isPaid ? Palette.success : Palette.danger),
            ),
          ],
          SizedBox(height: 12),
          StudentLearningProgressPanel(
            enrollments: [record],
            progressByEnrollment: _learning,
            dense: true,
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: record.isActive &&
                        sessionsConfigured &&
                        record.remainingSessions > 0
                    ? () => _completeSession(record)
                    : null,
                icon: Icon(Icons.check, size: 17),
                label: Text('회차 차감',
                    style: TextStyle(fontFamily: "NotoSansKR", fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Palette.darkTeal,
                  foregroundColor: Palette.white,
                ),
              ),
              if (record.completedSessions > 0)
                OutlinedButton(
                  onPressed: () => _adjustSession(record, -1),
                  child: Text('차감 되돌리기',
                      style: TextStyle(fontFamily: "NotoSansKR", fontSize: 12)),
                ),
              OutlinedButton.icon(
                onPressed: () => _showClassDialog(record),
                icon: Icon(Icons.videocam, size: 16),
                label: Text('화상수업',
                    style: TextStyle(fontFamily: "NotoSansKR", fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Palette.secondaryDark,
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _showHistoryDialog(record),
                icon: Icon(Icons.history, size: 16),
                label: Text('처리 이력',
                    style: TextStyle(fontFamily: "NotoSansKR", fontSize: 12)),
              ),
              OutlinedButton(
                onPressed: () => _showEditDialog(record),
                child: Text('배정 변경',
                    style: TextStyle(fontFamily: "NotoSansKR", fontSize: 12)),
              ),
              if (_isOwner)
                OutlinedButton.icon(
                  onPressed: () => _showPaymentDialog(record),
                  icon: Icon(Icons.payments_outlined, size: 16),
                  label: Text('결제 정보',
                      style: TextStyle(fontFamily: "NotoSansKR", fontSize: 12)),
                ),
              TextButton(
                onPressed: () => _cancelEnrollment(record),
                child: Text(record.isActive ? '배정 취소' : '배정 복구',
                    style: TextStyle(
                        fontFamily: "NotoSansKR",
                        fontSize: 12,
                        color: record.isActive
                            ? Palette.danger
                            : Palette.secondaryDark)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showAssignDialog(String email) async {
    OnlineCourse selectedCourse = OnlineCourse.all.first;
    final sessionsController = TextEditingController(text: '8');

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('수업 배정', style: TextStyle(fontFamily: "Jalnan")),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<OnlineCourse>(
                  initialValue: selectedCourse,
                  decoration: InputDecoration(
                      labelText: '과정', border: OutlineInputBorder()),
                  items: OnlineCourse.all
                      .map((course) => DropdownMenuItem(
                            value: course,
                            child: Text(course.title,
                                style: TextStyle(fontFamily: "NotoSansKR")),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedCourse = value);
                    }
                  },
                ),
                SizedBox(height: 14),
                TextField(
                  controller: sessionsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '전체 화상수업 횟수',
                    suffixText: '회',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text('닫기')),
            ElevatedButton(
              onPressed: () async {
                final total = int.tryParse(sessionsController.text.trim()) ?? 0;
                final error = await EnrollmentService.assignCourseByEmail(
                  email: email,
                  courseId: selectedCourse.id,
                  totalSessions: total,
                  allowedMemberIds: _isOwner
                      ? null
                      : _members
                          .map((m) => m['uid']?.toString() ?? '')
                          .toList(),
                );
                if (!mounted) return;
                if (error != null) {
                  _toast(error, error: true);
                  return;
                }
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: Text('배정하기'),
            ),
          ],
        ),
      ),
    );
    sessionsController.dispose();

    if (saved == true) {
      _toast('수업이 배정되었습니다.');
      await _refresh();
    }
  }

  Future<void> _showEditDialog(EnrollmentRecord record) async {
    OnlineCourse selectedCourse = record.course ?? OnlineCourse.all.first;
    final sessionsController = TextEditingController(
        text: record.totalSessions > 0 ? '${record.totalSessions}' : '8');

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('배정 변경', style: TextStyle(fontFamily: "Jalnan")),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<OnlineCourse>(
                  initialValue: selectedCourse,
                  decoration: InputDecoration(
                      labelText: '과정', border: OutlineInputBorder()),
                  items: OnlineCourse.all
                      .map((course) => DropdownMenuItem(
                            value: course,
                            child: Text(course.title,
                                style: TextStyle(fontFamily: "NotoSansKR")),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedCourse = value);
                    }
                  },
                ),
                SizedBox(height: 14),
                TextField(
                  controller: sessionsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '전체 화상수업 횟수',
                    suffixText: '회',
                    helperText: selectedCourse.id == record.courseId
                        ? '같은 과정이면 현재 진행 횟수를 유지합니다.'
                        : '과정을 변경하면 진행 횟수가 0회로 초기화됩니다.',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text('닫기')),
            ElevatedButton(
              onPressed: () async {
                final total = int.tryParse(sessionsController.text.trim()) ?? 0;
                final error = await EnrollmentService.updateEnrollment(
                  enrollmentId: record.id,
                  userId: record.userId,
                  currentCourseId: record.courseId,
                  courseId: selectedCourse.id,
                  totalSessions: total,
                );
                if (!mounted) return;
                if (error != null) {
                  _toast(error, error: true);
                  return;
                }
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: Text('변경 저장'),
            ),
          ],
        ),
      ),
    );
    sessionsController.dispose();

    if (saved == true) {
      _toast('배정 정보가 변경되었습니다.');
      await _refresh();
    }
  }

  Future<void> _completeSession(EnrollmentRecord record) async {
    final course = record.course;
    final title = course == null ? record.courseId : course.title;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('회차 차감', style: TextStyle(fontFamily: "Jalnan")),
        content: Text(
          '$title 과정의 이번 화상수업 1회를 차감할까요?\n'
          '차감 후 남은 횟수: ${record.remainingSessions - 1}회\n\n'
          '강사가 화상수업을 종료하면 회차가 자동으로 차감됩니다. '
          '이 버튼은 보정할 때만 사용하세요.',
          style: TextStyle(fontFamily: "NotoSansKR", height: 1.5),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text('취소', style: TextStyle(fontFamily: "NotoSansKR"))),
          ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text('차감하기', style: TextStyle(fontFamily: "NotoSansKR"))),
        ],
      ),
    );
    if (confirmed != true) return;
    await _adjustSession(record, 1);
  }

  Future<void> _adjustSession(EnrollmentRecord record, int delta) async {
    final result = await EnrollmentService.adjustCompletedSessions(
        record.id, delta,
        adminName: _adminName);
    if (!result.success) {
      _toast(result.error!, error: true);
      return;
    }
    if (delta > 0 && result.allCompleted) {
      _toast(
          '마지막 회차까지 모두 완료되었습니다. (${result.completedSessions}/${result.totalSessions}회)');
    } else {
      _toast(delta > 0 ? '화상수업 1회가 완료 처리되었습니다.' : '진행 횟수를 1회 되돌렸습니다.');
    }
    await _refresh();
  }

  /// 회원 카드에서 바로 화상수업 회차를 시작·종료·입장할 수 있는 다이얼로그.
  Future<void> _showClassDialog(EnrollmentRecord record) async {
    final course = record.course;
    final courseTitle = course == null ? record.courseId : course.title;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _ClassControlDialog(
        courseId: record.courseId,
        courseTitle: courseTitle,
        hostName: _adminName,
        nextOrderHint: record.completedSessions + 1,
      ),
    );
    if (!mounted) return;
    await _refresh();
  }

  Future<void> _showHistoryDialog(EnrollmentRecord record) async {
    final logs = await EnrollmentService.sessionLogs(record.id);
    if (!mounted) return;

    final course = record.course;
    final title = course == null ? record.courseId : course.title;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('$title · 수업 처리 이력',
            style: TextStyle(fontFamily: "Jalnan", fontSize: 16)),
        content: SizedBox(
          width: 420,
          child: logs.isEmpty
              ? Text('아직 처리 이력이 없습니다.',
                  style: TextStyle(fontFamily: "NotoSansKR"))
              : ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 360),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: logs.length,
                    separatorBuilder: (_, __) => Divider(height: 1),
                    itemBuilder: (_, index) {
                      final log = logs[index];
                      final isComplete = log.delta > 0;
                      final when = _formatDateTime(log.createdAt);
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 4),
                        leading: Icon(
                          isComplete ? Icons.check_circle : Icons.undo,
                          color: isComplete ? Palette.primary : Palette.grey500,
                          size: 20,
                        ),
                        title: Text(
                          isComplete
                              ? '수업 완료 (${log.completedAfter}/${log.totalSessions}회)'
                              : '되돌리기 (${log.completedAfter}/${log.totalSessions}회)',
                          style:
                              TextStyle(fontFamily: "NotoSansKR", fontSize: 13),
                        ),
                        subtitle: Text(
                          '$when'
                          '${log.adminName.isNotEmpty ? ' · ${log.adminName}' : ''}',
                          style: TextStyle(
                              fontFamily: "NotoSansKR",
                              fontSize: 12,
                              color: Palette.grey500),
                        ),
                      );
                    },
                  ),
                ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('닫기', style: TextStyle(fontFamily: "NotoSansKR"))),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '시간 미상';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}.${two(dt.month)}.${two(dt.day)} '
        '${two(dt.hour)}:${two(dt.minute)}';
  }

  Future<void> _showPaymentDialog(EnrollmentRecord record) async {
    bool isPaid = record.isPaid;
    final amountController = TextEditingController(
        text: record.paidAmount > 0 ? '${record.paidAmount}' : '');
    final noteController = TextEditingController(text: record.paymentNote);

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('결제 정보', style: TextStyle(fontFamily: "Jalnan")),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title:
                      Text('결제 완료', style: TextStyle(fontFamily: "NotoSansKR")),
                  value: isPaid,
                  onChanged: (v) => setDialogState(() => isPaid = v),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '결제 금액',
                    suffixText: '원',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: '메모 (예: 계좌이체 / 카드)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text('닫기')),
            ElevatedButton(
              onPressed: () async {
                final amount = int.tryParse(amountController.text.trim()) ?? 0;
                final error = await EnrollmentService.updatePaymentInfo(
                  enrollmentId: record.id,
                  isPaid: isPaid,
                  paidAmount: amount,
                  paymentNote: noteController.text.trim(),
                );
                if (!mounted) return;
                if (error != null) {
                  _toast(error, error: true);
                  return;
                }
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: Text('저장'),
            ),
          ],
        ),
      ),
    );
    amountController.dispose();
    noteController.dispose();

    if (saved == true) {
      _toast('결제 정보가 저장되었습니다.');
      await _refresh();
    }
  }

  Future<void> _cancelEnrollment(EnrollmentRecord record) async {
    if (record.isActive) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('배정 취소'),
          content: Text('이 수업을 회원의 내 강의실에서 숨길까요? 진행 횟수 기록은 보존됩니다.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text('아니요')),
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text('배정 취소', style: TextStyle(color: Palette.danger))),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    final error = await EnrollmentService.setEnrollmentActive(
        record.id, !record.isActive);
    if (error != null) {
      _toast(error, error: true);
      return;
    }
    _toast(record.isActive ? '배정이 취소되었습니다.' : '배정이 복구되었습니다.');
    await _refresh();
  }
}


// ---------------------------------------------------------------------------
// 진행 중인 수업 배너 (종료 깜빡함 방지)
// ---------------------------------------------------------------------------

class LiveSessionBanner extends StatefulWidget {
  final String hostName;

  const LiveSessionBanner({Key? key, required this.hostName}) : super(key: key);

  @override
  LiveSessionBannerState createState() => LiveSessionBannerState();
}

class LiveSessionBannerState extends State<LiveSessionBanner> {
  List<OnlineSession> _live = [];
  bool _working = false;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    final live = await EnrollmentService.liveSessions();
    if (!mounted) return;
    setState(() => _live = live);
  }

  Future<void> _end(OnlineSession session) async {
    setState(() => _working = true);
    final error = await EnrollmentService.setSessionLive(
      sessionId: session.id,
      isLive: false,
      hostName: widget.hostName,
    );
    if (!mounted) return;
    setState(() => _working = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? '수업을 종료했습니다.',
            style: TextStyle(fontFamily: "NotoSansKR")),
        backgroundColor: error != null ? Palette.danger : Palette.success,
      ),
    );
    await reload();
  }

  @override
  Widget build(BuildContext context) {
    if (_live.isEmpty) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Palette.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Palette.success),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.videocam, size: 18, color: Palette.success),
              SizedBox(width: 8),
              Text('진행 중인 수업 ${_live.length}건',
                  style: TextStyle(
                      fontFamily: "Jalnan",
                      fontSize: 14,
                      color: Palette.success)),
            ],
          ),
          SizedBox(height: 6),
          Text(
            '화상 창을 닫아도 자동으로 종료되지 않습니다. 수업이 끝났으면 아래에서 종료해주세요.',
            style: TextStyle(
                fontFamily: "NotoSansKR", fontSize: 12, color: Palette.grey600),
          ),
          SizedBox(height: 10),
          ..._live.map((session) {
            final course = OnlineCourse.findById(session.courseId);
            final label =
                '${course?.title ?? session.courseId} · ${session.title}';
            return Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      session.isStale ? '$label (시간 초과로 종료 처리됨)' : label,
                      style: TextStyle(
                          fontFamily: "NotoSansKR",
                          fontSize: 12,
                          color: session.isStale
                              ? Palette.grey500
                              : Palette.black),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Palette.danger,
                      foregroundColor: Palette.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    onPressed: _working ? null : () => _end(session),
                    child: Text('수업 종료',
                        style:
                            TextStyle(fontFamily: "NotoSansKR", fontSize: 12)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 회원 카드용 화상수업 제어 다이얼로그
// ---------------------------------------------------------------------------

class _ClassControlDialog extends StatefulWidget {
  final String courseId;
  final String courseTitle;
  final String hostName;
  final int nextOrderHint;

  const _ClassControlDialog({
    required this.courseId,
    required this.courseTitle,
    required this.hostName,
    required this.nextOrderHint,
  });

  @override
  _ClassControlDialogState createState() => _ClassControlDialogState();
}

class _ClassControlDialogState extends State<_ClassControlDialog> {
  List<OnlineSession> _sessions = [];
  bool _loading = true;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final sessions = await EnrollmentService.sessions(widget.courseId);
    if (!mounted) return;
    setState(() {
      _sessions = sessions;
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

  /// 다음 회차를 만들고 곧바로 수업을 시작한다.
  Future<void> _createAndStart() async {
    setState(() => _working = true);

    final nextOrder =
        _sessions.isEmpty ? widget.nextOrderHint : (_sessions.last.order + 1);

    final sessionId = await EnrollmentService.createSessionReturningId(
      courseId: widget.courseId,
      title: '$nextOrder회차 화상수업',
      order: nextOrder,
    );

    if (sessionId == null) {
      if (!mounted) return;
      setState(() => _working = false);
      _toast('회차 생성에 실패했습니다.', error: true);
      return;
    }

    final error = await EnrollmentService.setSessionLive(
      sessionId: sessionId,
      isLive: true,
      hostName: widget.hostName,
    );
    if (!mounted) return;
    setState(() => _working = false);

    if (error != null) {
      _toast(error, error: true);
      return;
    }

    await _load();
    if (!mounted) return;
    _toast('$nextOrder회차 화상수업을 시작했습니다. 회원이 입장할 수 있습니다.');

    // 강사가 호스트로 먼저 들어가야 회원이 대기 없이 참여할 수 있다.
    final started = _sessions.firstWhere(
      (s) => s.id == sessionId,
      orElse: () => _sessions.last,
    );
    await UrlUtil.open(started.meetingUrl);
  }

  Future<void> _toggleLive(OnlineSession session) async {
    setState(() => _working = true);
    final error = await EnrollmentService.setSessionLive(
      sessionId: session.id,
      isLive: !session.isLive,
      hostName: widget.hostName,
    );
    if (!mounted) return;
    setState(() => _working = false);

    if (error != null) {
      _toast(error, error: true);
      return;
    }
    _toast(session.isLive ? '수업을 종료했습니다.' : '수업을 시작했습니다. 회원이 입장할 수 있습니다.');
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.courseTitle} · 화상수업',
          style: TextStyle(fontFamily: "Jalnan", fontSize: 16)),
      content: SizedBox(
        width: 460,
        child: _loading
            ? Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '호스트로 입장하면 수강생도 같은 회의실로 들어올 수 있습니다.',
                    style: TextStyle(
                        fontFamily: "NotoSansKR",
                        fontSize: 12,
                        height: 1.6,
                        color: Palette.grey600),
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.maxFinite,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Palette.darkTeal,
                        foregroundColor: Palette.white,
                        padding: EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _working ? null : _createAndStart,
                      icon: Icon(Icons.play_circle, size: 18),
                      label: Text('다음 회차 만들어 수업 시작',
                          style: TextStyle(fontFamily: "Jalnan", fontSize: 13)),
                    ),
                  ),
                  SizedBox(height: 18),
                  Text('등록된 회차',
                      style: TextStyle(fontFamily: "Jalnan", fontSize: 14)),
                  SizedBox(height: 8),
                  if (_sessions.isEmpty)
                    Text('아직 등록된 회차가 없습니다. 위 버튼으로 1회차를 시작할 수 있습니다.',
                        style: TextStyle(
                            fontFamily: "NotoSansKR",
                            fontSize: 12,
                            color: Palette.grey500))
                  else
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: 260),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _sessions.length,
                        separatorBuilder: (_, __) => Divider(height: 1),
                        itemBuilder: (_, index) {
                          final session = _sessions[index];
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 2),
                            title: Text(session.title,
                                style: TextStyle(
                                    fontFamily: "NotoSansKR", fontSize: 13)),
                            subtitle: Text(
                              session.isLiveNow
                                  ? '수업 중'
                                  : (session.isStale
                                      ? '시간 초과 · 종료 처리됨'
                                      : (session.isFinished
                                          ? '수업 종료'
                                          : '수업 예정')),
                              style: TextStyle(
                                fontFamily: "NotoSansKR",
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: session.isLiveNow
                                    ? Palette.success
                                    : Palette.grey500,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: '호스트로 입장',
                                  onPressed: () async {
                                    UrlUtil.open(session.meetingUrl);
                                    if (!session.isLive && !session.isFinished) {
                                      await _toggleLive(session);
                                    }
                                  },
                                  icon: Icon(Icons.videocam,
                                      size: 18, color: Palette.secondaryDark),
                                ),
                                TextButton(
                                  onPressed: _working
                                      ? null
                                      : () => _toggleLive(session),
                                  child: Text(
                                    session.isLive ? '종료' : '시작',
                                    style: TextStyle(
                                        fontFamily: "NotoSansKR",
                                        fontSize: 12,
                                        color: session.isLive
                                            ? Palette.danger
                                            : Palette.secondaryDark),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('닫기', style: TextStyle(fontFamily: "NotoSansKR")),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 화상수업 회차 탭 (메인 관리자 + 강사)
// ---------------------------------------------------------------------------

class AdminSessionTab extends StatefulWidget {
  @override
  _AdminSessionTabState createState() => _AdminSessionTabState();
}

class _AdminSessionTabState extends State<AdminSessionTab> {
  OnlineCourse _selectedCourse = OnlineCourse.all.first;
  final titleController = TextEditingController(text: '1회차 화상수업');
  final orderController = TextEditingController(text: '1');
  final meetingUrlController = TextEditingController();
  DateTime? _scheduledAt;
  List<OnlineSession> _sessions = [];
  bool _loading = true;
  bool _saving = false;
  bool _isOwner = true;
  String _hostName = '';
  String _teacherUid = '';
  Timer? _ticker;
  final _bannerKey = GlobalKey<LiveSessionBannerState>();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    titleController.dispose();
    orderController.dispose();
    meetingUrlController.dispose();
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await _loadHostName();
    await _refresh();
  }

  Future<void> _loadHostName() async {
    final name = await AuthService.getAdminName();
    final role = await AuthService.getAdminRole();
    final uid = await AuthService.currentStaffUid();
    if (!mounted) return;
    setState(() {
      _hostName = name;
      _isOwner = role == AdminRole.owner;
      _teacherUid = uid;
    });
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    List<OnlineSession> sessions;
    if (_isOwner) {
      await EnrollmentService.backfillSessionsForCourse(_selectedCourse.id);
      sessions = await EnrollmentService.sessions(_selectedCourse.id);
    } else {
      final uid = _teacherUid.isNotEmpty
          ? _teacherUid
          : await AuthService.currentStaffUid();
      await EnrollmentService.backfillSessionsForTeacher(uid);
      sessions = await EnrollmentService.sessionsForTeacher(uid);
    }
    if (!mounted) return;
    setState(() {
      _sessions = sessions;
      _loading = false;
      final nextOrder = sessions.isEmpty ? 1 : sessions.last.order + 1;
      orderController.text = '$nextOrder';
      titleController.text = '$nextOrder회차 화상수업';
    });
    _bannerKey.currentState?.reload();
  }

  void _toast(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontFamily: "NotoSansKR")),
        backgroundColor: error ? Palette.danger : Palette.success,
      ),
    );
  }

  Future<void> _pickSchedule() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt ?? DateTime.now(),
      firstDate: DateTime.now().subtract(Duration(days: 1)),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt ?? DateTime.now()),
    );
    if (!mounted) return;

    setState(() {
      _scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? 0,
        time?.minute ?? 0,
      );
    });
  }

  Future<void> _addSession() async {
    setState(() => _saving = true);
    final error = await EnrollmentService.addSession(
      courseId: _selectedCourse.id,
      title: titleController.text,
      order: int.tryParse(orderController.text.trim()) ?? 0,
      meetingUrl: meetingUrlController.text,
      scheduledAt: _scheduledAt,
    );
    if (!mounted) return;
    setState(() => _saving = false);

    if (error != null) {
      _toast(error, error: true);
      return;
    }
    _toast('화상수업 회차가 등록되었습니다.');
    meetingUrlController.clear();
    setState(() => _scheduledAt = null);
    await _refresh();
  }

  Future<void> _enterAsHost(OnlineSession session) async {
    UrlUtil.open(session.meetingUrl);
    if (!session.isLive && !session.isFinished) {
      final error = await EnrollmentService.setSessionLive(
        sessionId: session.id,
        isLive: true,
        hostName: _hostName,
      );
      if (error != null) {
        _toast(error, error: true);
        return;
      }
      await _refresh();
    }
  }

  Future<void> _toggleLive(OnlineSession session) async {
    if (!session.isLive) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('수업 시작', style: TextStyle(fontFamily: "Jalnan")),
          content: Text(
            '${session.title}을 시작할까요?\n\n'
            '호스트로 입장하면 수강생 입장도 함께 열립니다. 이 버튼은 수업을 따로 표시할 때 사용합니다.',
            style: TextStyle(fontFamily: "NotoSansKR", height: 1.5),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text('취소')),
            ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text('수업 시작')),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    final error = await EnrollmentService.setSessionLive(
      sessionId: session.id,
      isLive: !session.isLive,
      hostName: _hostName,
    );
    if (error != null) {
      _toast(error, error: true);
      return;
    }
    _toast(session.isLive ? '수업을 종료했습니다.' : '수업을 시작했습니다. 회원이 입장할 수 있습니다.');
    await _refresh();
  }

  Future<void> _deleteSession(OnlineSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('회차 삭제'),
        content: Text('${session.title}을 삭제할까요?',
            style: TextStyle(fontFamily: "NotoSansKR")),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text('아니요')),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text('삭제', style: TextStyle(color: Palette.danger))),
        ],
      ),
    );
    if (confirmed != true) return;

    final error = await EnrollmentService.deleteSession(session.id);
    if (error != null) {
      _toast(error, error: true);
      return;
    }
    _toast('회차가 삭제되었습니다.');
    await _refresh();
  }

  String _formatDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}.${two(dt.month)}.${two(dt.day)} '
        '${two(dt.hour)}:${two(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: EdgeInsets.all(20),
        children: [
          LiveSessionBanner(key: _bannerKey, hostName: _hostName),
          Text(_isOwner ? '화상수업 회차 관리' : '화상수업',
              style: TextStyle(fontFamily: "Jalnan", fontSize: 18)),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Palette.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Palette.grey200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('수업 진행 순서',
                    style: TextStyle(
                        fontFamily: "NotoSansKR",
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                SizedBox(height: 6),
                Text(
                  _isOwner
                      ? '1) 예약을 컨펌하면 회차가 자동으로 만들어집니다. 필요하면 아래에서 직접 등록할 수도 있습니다.\n'
                          '2) 수업 시간에 ‘호스트로 입장’을 누르면 강사가 회의실에 들어가고, 수강생 입장 버튼도 함께 열립니다.\n'
                          '3) 수업을 직접 끄려면 ‘수업 종료’를 누릅니다.'
                      : '1) 스케줄에서 예약을 컨펌하면 이 목록에 회차가 자동으로 생성됩니다.\n'
                          '2) 수업 5분 전에 강사와 수강생 휴대폰으로 알림 문자가 갑니다.\n'
                          '3) ‘호스트로 입장’을 누르면 수강생도 바로 들어올 수 있습니다.\n'
                          '4) 수업이 끝나면 ‘수업 종료’를 누릅니다.',
                  style: TextStyle(
                      fontFamily: "NotoSansKR",
                      fontSize: 12,
                      height: 1.7,
                      color: Palette.grey600),
                ),
                SizedBox(height: 8),
                Text(
                  '※ meet.jit.si는 첫 입장자에게 호스트 로그인을 요구할 수 있습니다. '
                  '이 경우 강사가 회의실에서 ‘내가 호스트’를 눌러 Google 계정으로 한 번 로그인하면 됩니다. '
                  'Google Meet·Zoom 링크를 쓰려면 아래 회의 주소 칸에 직접 붙여넣으세요.',
                  style: TextStyle(
                      fontFamily: "NotoSansKR",
                      fontSize: 12,
                      height: 1.6,
                      color: Palette.danger),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          if (_isOwner) ...[
            DropdownButtonFormField<OnlineCourse>(
              initialValue: _selectedCourse,
              decoration: InputDecoration(
                labelText: '과정 선택',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Palette.white,
              ),
              items: OnlineCourse.all
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text('${c.order}. ${c.title}',
                            style: TextStyle(
                                fontFamily: "NotoSansKR", fontSize: 13)),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedCourse = value);
                _refresh();
              },
            ),
            SizedBox(height: 20),
            Text('새 회차 등록',
                style: TextStyle(fontFamily: "Jalnan", fontSize: 16)),
            SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 110,
                  child: TextField(
                    controller: orderController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '회차',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Palette.white,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: '회차 제목',
                      hintText: '예: 1회차 화상수업',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Palette.white,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            TextField(
              controller: meetingUrlController,
              decoration: InputDecoration(
                labelText: '회의 주소 (비워두면 Jitsi 방이 자동 생성됩니다)',
                hintText:
                    'https://meet.google.com/... 또는 https://zoom.us/j/...',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Palette.white,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _pickSchedule,
                  icon: Icon(Icons.event, size: 16),
                  label: Text(
                      _scheduledAt == null
                          ? '수업 일시 선택 (선택사항)'
                          : _formatDateTime(_scheduledAt!),
                      style:
                          TextStyle(fontFamily: "NotoSansKR", fontSize: 12)),
                ),
                if (_scheduledAt != null)
                  TextButton(
                    onPressed: () => setState(() => _scheduledAt = null),
                    child: Text('지우기',
                        style: TextStyle(
                            fontFamily: "NotoSansKR", fontSize: 12)),
                  ),
              ],
            ),
            SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Palette.darkTeal,
                  foregroundColor: Palette.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
                onPressed: _saving ? null : _addSession,
                child: _saving
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Palette.white),
                      )
                    : Text('회차 등록', style: TextStyle(fontFamily: "Jalnan")),
              ),
            ),
            Divider(height: 32),
            Text('${_selectedCourse.title} · 등록된 회차',
                style: TextStyle(fontFamily: "Jalnan", fontSize: 16)),
          ] else
            Text('컨펌된 화상수업',
                style: TextStyle(fontFamily: "Jalnan", fontSize: 16)),
          SizedBox(height: 12),
          if (_loading)
            Center(child: CircularProgressIndicator())
          else if (_sessions.isEmpty)
            Text(
                _isOwner
                    ? '등록된 회차가 없습니다.'
                    : '컨펌한 수업이 여기에 자동으로 나타납니다.',
                style:
                    TextStyle(fontFamily: "NotoSansKR", color: Palette.grey500))
          else
            ..._sessions.map(_sessionCard),
        ],
      ),
    );
  }

  Widget _sessionCard(OnlineSession session) {
    final countdown = EnrollmentService.formatSessionCountdown(session);
    final live = session.isLiveNow;
    final ended = session.isFinished || session.isStale;
    final badgeColor = live
        ? Palette.success
        : ended
            ? Palette.grey500
            : Palette.darkTeal;
    final course = OnlineCourse.findById(session.courseId);
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(session.title,
                      style: TextStyle(
                          fontFamily: "NotoSansKR",
                          fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    countdown,
                    style: TextStyle(
                      fontFamily: "NotoSansKR",
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ),
            if (course != null) ...[
              SizedBox(height: 4),
              Text(course.title,
                  style: TextStyle(
                      fontFamily: "NotoSansKR",
                      fontSize: 12,
                      color: Palette.grey600)),
            ],
            if (session.scheduledAt != null) ...[
              SizedBox(height: 6),
              Text(
                '수업 일시: ${_formatDateTime(session.scheduledAt!)}',
                style: TextStyle(
                    fontFamily: "NotoSansKR",
                    fontSize: 12,
                    color: Palette.grey600),
              ),
            ],
            SizedBox(height: 6),
            Text(session.meetingUrl,
                style: TextStyle(
                    fontFamily: "NotoSansKR",
                    fontSize: 11,
                    color: Palette.grey500)),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Palette.darkTeal,
                    foregroundColor: Palette.white,
                  ),
                  onPressed: () => _enterAsHost(session),
                  icon: Icon(Icons.videocam, size: 16),
                  label: Text('호스트로 입장',
                      style: TextStyle(fontFamily: "NotoSansKR", fontSize: 12)),
                ),
                OutlinedButton.icon(
                  onPressed: () => _toggleLive(session),
                  icon: Icon(
                      session.isLive ? Icons.stop_circle : Icons.play_circle,
                      size: 16),
                  label: Text(session.isLive ? '수업 종료' : '수업 시작',
                      style: TextStyle(fontFamily: "NotoSansKR", fontSize: 12)),
                ),
                TextButton(
                  onPressed: () => _deleteSession(session),
                  child: Text('삭제',
                      style: TextStyle(
                          fontFamily: "NotoSansKR",
                          fontSize: 12,
                          color: Palette.danger)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 강사 관리 탭 (메인 관리자 전용)
// ---------------------------------------------------------------------------

Widget _adminTeacherCirclePhoto({
  String url = '',
  Uint8List? bytes,
  double size = 72,
}) {
  final provider = OnlineNativeTeacher.imageProviderOf(url, bytes);
  return ClipOval(
    child: Container(
      width: size,
      height: size,
      color: Palette.grey100,
      alignment: Alignment.center,
      child: provider == null
          ? Icon(Icons.person, size: size * 0.45, color: Palette.grey400)
          : Image(
              image: provider,
              width: size,
              height: size,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) =>
                  Icon(Icons.person, size: size * 0.45, color: Palette.grey400),
            ),
    ),
  );
}

class _TeacherEditDialog extends StatefulWidget {
  final Map<String, dynamic> teacher;
  final Future<Uint8List?> Function() pickPhoto;

  const _TeacherEditDialog({
    required this.teacher,
    required this.pickPhoto,
  });

  @override
  State<_TeacherEditDialog> createState() => _TeacherEditDialogState();
}

class _TeacherEditDialogState extends State<_TeacherEditDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _nationalityCtrl;
  late final TextEditingController _introCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _bankNameCtrl;
  late final TextEditingController _bankAccountCtrl;
  late final TextEditingController _accountHolderCtrl;
  late final TextEditingController _passwordCtrl;
  Uint8List? _newPhoto;
  bool _saving = false;
  bool _obscurePassword = true;

  String get _uid => widget.teacher['uid']?.toString() ?? '';
  String get _existingUrl => widget.teacher['photoUrl']?.toString() ?? '';
  bool get _isTeacher => widget.teacher['role']?.toString() == 'teacher';
  bool get _missingPassword => widget.teacher['hasLoginPassword'] != true;

  @override
  void initState() {
    super.initState();
    _nameCtrl =
        TextEditingController(text: widget.teacher['name']?.toString() ?? '');
    _nationalityCtrl = TextEditingController(
        text: widget.teacher['nationality']?.toString() ?? '');
    _introCtrl =
        TextEditingController(text: widget.teacher['intro']?.toString() ?? '');
    _phoneCtrl =
        TextEditingController(text: widget.teacher['phone']?.toString() ?? '');
    _bankNameCtrl = TextEditingController(
        text: widget.teacher['bankName']?.toString() ?? '');
    _bankAccountCtrl = TextEditingController(
        text: widget.teacher['bankAccount']?.toString() ?? '');
    _accountHolderCtrl = TextEditingController(
        text: widget.teacher['accountHolder']?.toString() ?? '');
    _passwordCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nationalityCtrl.dispose();
    _introCtrl.dispose();
    _phoneCtrl.dispose();
    _bankNameCtrl.dispose();
    _bankAccountCtrl.dispose();
    _accountHolderCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontFamily: "NotoSansKR")),
        backgroundColor: Palette.danger,
      ),
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_isTeacher &&
        _missingPassword &&
        _passwordCtrl.text.trim().length < 6) {
      _showError('이 강사는 아직 로그인 비밀번호가 없습니다. 6자 이상으로 만들어 주세요.');
      return;
    }
    final phoneError = PhoneUtil.validate(_phoneCtrl.text);
    if (phoneError != null) {
      _showError(phoneError);
      return;
    }
    setState(() => _saving = true);
    String? error;
    try {
      error = await AuthService.updateTeacherProfile(
        teacherUid: _uid,
        name: _nameCtrl.text,
        phone: _phoneCtrl.text,
        nationality: _nationalityCtrl.text,
        intro: _introCtrl.text,
        bankName: _bankNameCtrl.text,
        bankAccount: _bankAccountCtrl.text,
        accountHolder: _accountHolderCtrl.text,
        photoBytes: _newPhoto,
        photoFileName: _newPhoto == null ? null : 'teacher.jpg',
        password: _passwordCtrl.text.trim(),
      );
    } catch (e) {
      error = '강사 정보 수정 중 오류가 발생했습니다.';
    }
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      _showError(error);
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Palette.white,
      surfaceTintColor: Palette.white,
      title: Text('강사 정보 수정', style: TextStyle(fontFamily: "Jalnan")),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.teacher['email']?.toString() ?? '',
                style: TextStyle(
                    fontFamily: "NotoSansKR",
                    fontSize: 13,
                    color: Palette.grey600),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  _adminTeacherCirclePhoto(
                      url: _existingUrl, bytes: _newPhoto, size: 72),
                  SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: _saving
                        ? null
                        : () async {
                            final cropped = await widget.pickPhoto();
                            if (!mounted || cropped == null || cropped.isEmpty) {
                              return;
                            }
                            setState(() => _newPhoto = cropped);
                          },
                    icon: Icon(Icons.photo_camera_outlined, size: 18),
                    label: Text('사진 변경',
                        style: TextStyle(fontFamily: "NotoSansKR")),
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: '강사 이름',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: '휴대폰 번호',
                  helperText: '수업 예약이 들어오면 이 번호로 알림 문자를 보냅니다.',
                  helperMaxLines: 2,
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _bankNameCtrl,
                decoration: InputDecoration(
                  labelText: '월급 은행',
                  hintText: '예: 국민은행',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _bankAccountCtrl,
                decoration: InputDecoration(
                  labelText: '계좌번호',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _accountHolderCtrl,
                decoration: InputDecoration(
                  labelText: '예금주',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _nationalityCtrl,
                decoration: InputDecoration(
                  labelText: '국적 (예: USA, UK, Korea)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _introCtrl,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: '강사 프로필 / 소개',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              if (_isTeacher) ...[
                SizedBox(height: 12),
                TextField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: _missingPassword
                        ? '로그인 비밀번호 (필수, 6자 이상)'
                        : '로그인 비밀번호 변경 (비워두면 유지)',
                    helperText: _missingPassword
                        ? '이 강사는 아직 로그인 비밀번호가 없습니다. 여기서 만들어 주세요.'
                        : '운영자 로그인 화면에서 이 이메일로 들어올 때 사용합니다.',
                    helperMaxLines: 2,
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: Text('닫기'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('저장'),
        ),
      ],
    );
  }
}

class _TeacherRegisterDialog extends StatefulWidget {
  final Future<Uint8List?> Function() pickPhoto;

  const _TeacherRegisterDialog({required this.pickPhoto});

  @override
  State<_TeacherRegisterDialog> createState() => _TeacherRegisterDialogState();
}

class _TeacherRegisterDialogState extends State<_TeacherRegisterDialog> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _bankAccountCtrl = TextEditingController();
  final _accountHolderCtrl = TextEditingController();
  final _nationalityCtrl = TextEditingController();
  final _introCtrl = TextEditingController();
  Uint8List? _photo;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    _bankNameCtrl.dispose();
    _bankAccountCtrl.dispose();
    _accountHolderCtrl.dispose();
    _nationalityCtrl.dispose();
    _introCtrl.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontFamily: "NotoSansKR")),
        backgroundColor: Palette.danger,
      ),
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showError('이름, 이메일, 비밀번호를 모두 입력해주세요.');
      return;
    }
    final phoneError = PhoneUtil.validate(phone);
    if (phoneError != null) {
      _showError(phoneError);
      return;
    }
    setState(() => _saving = true);
    String? error;
    try {
      error = await AuthService.registerTeacher(
        email: email,
        password: password,
        name: name,
        phone: phone,
        nationality: _nationalityCtrl.text.trim(),
        intro: _introCtrl.text.trim(),
        photoBytes: _photo,
        photoFileName: _photo == null ? null : 'teacher.jpg',
        bankName: _bankNameCtrl.text.trim(),
        bankAccount: _bankAccountCtrl.text.trim(),
        accountHolder: _accountHolderCtrl.text.trim(),
      );
    } catch (e) {
      error = '강사 등록 중 오류가 발생했습니다.';
    }
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      _showError(error);
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Palette.white,
      surfaceTintColor: Palette.white,
      title: Text('강사등록', style: TextStyle(fontFamily: "Jalnan")),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '등록한 강사는 관리자 로그인 화면에서 이메일/비밀번호로 로그인할 수 있습니다. '
                '사진과 소개는 수강생의 강사 선택 화면에 그대로 보입니다.',
                style: TextStyle(
                    fontFamily: "NotoSansKR",
                    fontSize: 13,
                    color: Palette.grey600),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  _adminTeacherCirclePhoto(bytes: _photo, size: 72),
                  SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: _saving
                        ? null
                        : () async {
                            final cropped = await widget.pickPhoto();
                            if (!mounted || cropped == null || cropped.isEmpty) {
                              return;
                            }
                            setState(() => _photo = cropped);
                          },
                    icon: Icon(Icons.photo_camera_outlined, size: 18),
                    label: Text(
                        _photo == null ? '강사 사진 등록' : '사진 다시 선택',
                        style: TextStyle(fontFamily: "NotoSansKR")),
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: '강사 이름',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _emailCtrl,
                decoration: InputDecoration(
                  labelText: '강사 이메일',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '초기 비밀번호 (6자 이상)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: '휴대폰 번호',
                  helperText: '수업 예약이 들어오면 이 번호로 알림 문자를 보냅니다.',
                  helperMaxLines: 2,
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _bankNameCtrl,
                decoration: InputDecoration(
                  labelText: '월급 은행',
                  hintText: '예: 국민은행',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _bankAccountCtrl,
                decoration: InputDecoration(
                  labelText: '계좌번호',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _accountHolderCtrl,
                decoration: InputDecoration(
                  labelText: '예금주',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _nationalityCtrl,
                decoration: InputDecoration(
                  labelText: '국적 (예: USA, UK, Korea)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _introCtrl,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: '강사 프로필 / 소개',
                  hintText: '경력, 수업 스타일, 학생에게 전하고 싶은 말을 적어 주세요.',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: Text('닫기'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('등록'),
        ),
      ],
    );
  }
}

class AdminTeacherTab extends StatefulWidget {
  @override
  _AdminTeacherTabState createState() => _AdminTeacherTabState();
}

class _AdminTeacherTabState extends State<AdminTeacherTab> {
  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _members = [];
  List<WeekBooking> _bookings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    await AuthService.publishTeacherProfiles();
    final teachers = await AuthService.listTeachers();
    final members = await AuthService.listMembers();
    final bookings = await EnrollmentService.staffWeekBookings(mineOnly: false);
    if (!mounted) return;
    setState(() {
      _teachers = teachers;
      _members = members;
      _bookings = bookings;
      _loading = false;
    });
  }

  bool _bookingDone(WeekBooking booking) {
    final at = EnrollmentService.bookingDateTime(booking.date, booking.time);
    if (at == null) return booking.isConfirmed;
    return booking.isConfirmed &&
        DateTime.now().isAfter(
            at.add(Duration(minutes: EnrollmentService.lessonMinutes)));
  }

  TeacherMonthStats _statsFor(String uid) {
    return TeacherMonthStats.fromBookings(
      bookings: _bookings,
      teacherUid: uid,
      isCompleted: _bookingDone,
    );
  }

  int _pendingFor(String uid) {
    final now = DateTime.now();
    var count = 0;
    for (final booking in _bookings) {
      if (!TeacherMonthStats.taughtBy(booking, uid)) continue;
      if (booking.date.year != now.year || booking.date.month != now.month) {
        continue;
      }
      if (booking.status == 'pending') count += 1;
    }
    return count;
  }

  Future<void> _openTeacherDetail(Map<String, dynamic> teacher) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TeacherRosterPage(teacher: teacher)),
    );
    if (mounted) await _refresh();
  }

  void _toast(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontFamily: "NotoSansKR")),
        backgroundColor: error ? Palette.danger : Palette.success,
      ),
    );
  }

  Future<void> _openRegister() async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _TeacherRegisterDialog(pickPhoto: _pickPhoto),
    );
    if (!mounted || saved != true) return;
    _toast('강사가 등록되었습니다. 해당 계정으로 로그인할 수 있습니다.');
    await _refresh();
  }

  Future<Uint8List?> _pickPhoto() async {
    Uint8List? raw;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'gif'],
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return null;
      final bytes = result.files.single.bytes;
      if (bytes == null || bytes.isEmpty) {
        _toast('사진을 읽지 못했습니다. JPG 또는 PNG로 다시 시도해주세요.', error: true);
        return null;
      }
      raw = Uint8List.fromList(bytes);
    } catch (e) {
      _toast('사진 선택 중 오류가 났습니다.', error: true);
      return null;
    }
    if (!mounted) return null;
    try {
      return await TeacherPhotoCropDialog.show(context, raw);
    } catch (e) {
      print('사진 자르기 닫기 오류: $e');
      return null;
    }
  }

  Widget _circlePhoto({
    String url = '',
    Uint8List? bytes,
    double size = 72,
  }) {
    return _adminTeacherCirclePhoto(url: url, bytes: bytes, size: size);
  }

  Future<void> _editTeacher(Map<String, dynamic> teacher) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _TeacherEditDialog(
        teacher: teacher,
        pickPhoto: _pickPhoto,
      ),
    );
    if (!mounted || saved != true) return;
    await _refresh();
    if (mounted) _toast('강사 정보를 수정했습니다.');
  }

  Future<void> _editOwnerBookingOffer(Map<String, dynamic> teacher) async {
    final uid = teacher['uid']?.toString() ?? '';
    if (uid.isEmpty) return;
    final current = TeacherBookingOffer.resolve(teacher, isOwner: true);
    final next = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('수업 받기',
              style: TextStyle(fontFamily: "Jalnan", fontSize: 16)),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TeacherBookingOffer.both,
                TeacherBookingOffer.coteach,
                TeacherBookingOffer.off,
              ].map((offer) {
                final selected = current == offer;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: selected
                        ? Palette.secondaryDark
                        : Palette.grey400,
                  ),
                  title: Text(TeacherBookingOffer.label(offer),
                      style: TextStyle(
                          fontFamily: "NotoSansKR",
                          fontWeight: FontWeight.w700)),
                  subtitle: Text(TeacherBookingOffer.description(offer),
                      style: TextStyle(
                          fontFamily: "NotoSansKR", fontSize: 12)),
                  onTap: () => Navigator.pop(dialogContext, offer),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('닫기', style: TextStyle(fontFamily: "NotoSansKR")),
            ),
          ],
        );
      },
    );
    if (next == null || next == current) return;
    final error =
        await AuthService.updateBookingOffer(teacherUid: uid, offer: next);
    if (!mounted) return;
    if (error != null) {
      _toast(error, error: true);
      return;
    }
    _toast('수업 받기 설정을 저장했습니다.');
    await _refresh();
  }

  Future<void> _assignMember(Map<String, dynamic> member) async {
    String selectedTeacherId = member['teacherId']?.toString() ?? '';

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('강사 배정', style: TextStyle(fontFamily: "Jalnan")),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${member['name'] ?? ''} (${member['email'] ?? ''})',
                  style: TextStyle(fontFamily: "NotoSansKR", fontSize: 13),
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue:
                      selectedTeacherId.isEmpty ? '' : selectedTeacherId,
                  decoration: InputDecoration(
                    labelText: '담당 강사',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: '',
                      child: Text('배정 없음',
                          style: TextStyle(fontFamily: "NotoSansKR")),
                    ),
                    ..._teachers
                        .where((t) => t['isActive'] != false)
                        .map((t) => DropdownMenuItem(
                              value: t['uid']?.toString() ?? '',
                              child: Text(
                                  '${t['name'] ?? ''} (${t['email'] ?? ''})',
                                  style: TextStyle(
                                      fontFamily: "NotoSansKR", fontSize: 13)),
                            )),
                  ],
                  onChanged: (v) =>
                      setDialogState(() => selectedTeacherId = v ?? ''),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text('닫기')),
            ElevatedButton(
              onPressed: () async {
                final error = await AuthService.assignMemberToTeacher(
                  memberId: member['uid']?.toString() ?? '',
                  teacherId: selectedTeacherId,
                );
                if (!mounted) return;
                if (error != null) {
                  _toast(error, error: true);
                  return;
                }
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: Text('저장'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      _toast('회원-강사 배정이 저장되었습니다.');
      await _refresh();
    }
  }

  Future<void> _editMemberPhone(Map<String, dynamic> member) async {
    final controller = TextEditingController(
        text: member['phone']?.toString() ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Palette.white,
        surfaceTintColor: Palette.white,
        title: Text('회원 연락처', style: TextStyle(fontFamily: "Jalnan")),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: '휴대폰 번호',
            helperText: '예약 확정 문자를 이 번호로 보냅니다.',
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
    final error = await AuthService.updateMemberPhone(
      memberId: member['uid']?.toString() ?? '',
      phone: phone,
    );
    if (error != null) {
      _toast(error, error: true);
      return;
    }
    _toast('연락처를 저장했습니다.');
    await _refresh();
  }

  String _teacherName(String teacherId) {
    if (teacherId.isEmpty) return '미배정';
    for (final t in _teachers) {
      if (t['uid']?.toString() == teacherId) {
        return t['name']?.toString() ?? teacherId;
      }
    }
    return '알 수 없음';
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: Text('등록된 강사',
                    style: TextStyle(fontFamily: "Jalnan", fontSize: 16)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Palette.darkTeal,
                  foregroundColor: Palette.white,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onPressed: _openRegister,
                icon: Icon(Icons.person_add_alt_1, size: 18),
                label: Text('강사등록', style: TextStyle(fontFamily: "Jalnan")),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '강사를 누르면 프로필·회원, 그 강사의 스케줄·예약, 한달 수업 이력을 볼 수 있습니다. 카드에는 이번 달 진행·취소·수입이 함께 보입니다.',
            style: TextStyle(
                fontFamily: "NotoSansKR", fontSize: 13, color: Palette.grey600),
          ),
          SizedBox(height: 12),
          if (_loading)
            Center(child: CircularProgressIndicator())
          else if (_teachers.isEmpty)
            Text('등록된 강사가 없습니다.',
                style:
                    TextStyle(fontFamily: "NotoSansKR", color: Palette.grey500))
          else
            ..._teachers.map((t) {
              final isOwnerTeacher = t['role']?.toString() != 'teacher';
              final active = t['isActive'] != false;
              final uid = t['uid']?.toString() ?? '';
              final assignedCount = _members
                  .where((m) => m['teacherId']?.toString() == uid)
                  .length;
              final intro = t['intro']?.toString() ?? '';
              final nationality = t['nationality']?.toString() ?? '';
              final photoUrl = t['photoUrl']?.toString() ?? '';
              final bookingOffer = TeacherBookingOffer.resolve(
                t,
                isOwner: isOwnerTeacher,
              );
              final stats = _statsFor(uid);
              final pending = _pendingFor(uid);
              final bank = AuthService.bankLabel(t);
              final titleName = isOwnerTeacher
                  ? '${t['name'] ?? '관리자'} (메인 관리자 · 강사)'
                  : '${t['name'] ?? ''} (${t['email'] ?? ''})';
              return Card(
                margin: EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        onTap: () => _openTeacherDetail(t),
                        leading: _circlePhoto(url: photoUrl, size: 52),
                        title: Text(titleName,
                            style: TextStyle(fontFamily: "NotoSansKR")),
                        subtitle: Text(
                          [
                            if (nationality.isNotEmpty) nationality,
                            if (!isOwnerTeacher && t['hasLoginPassword'] != true)
                              '비밀번호 없음',
                            isOwnerTeacher
                                ? '${TeacherBookingOffer.label(bookingOffer)} · 담당 $assignedCount명'
                                : (active
                                    ? '활성 · 담당 $assignedCount명'
                                    : '비활성 · 담당 $assignedCount명'),
                            '이번달 진행 ${stats.completedCount}회 · 취소 ${stats.cancelledCount}회 · 대기 ${pending}건',
                            stats.incomeLabel,
                            if (bank.isNotEmpty) bank,
                            PhoneUtil.isValid(t['phone']?.toString() ?? '')
                                ? PhoneUtil.display(t['phone']?.toString() ?? '')
                                : '연락처 없음',
                          ].join(' · '),
                          style: TextStyle(
                              fontFamily: "NotoSansKR",
                              fontSize: 12,
                              color: active ? Palette.grey600 : Palette.danger),
                        ),
                        trailing: Wrap(
                          spacing: 4,
                          children: [
                            TextButton(
                              onPressed: () => _openTeacherDetail(t),
                              child: Text('상세',
                                  style: TextStyle(
                                      fontFamily: "NotoSansKR",
                                      color: Palette.secondaryDark)),
                            ),
                            TextButton(
                              onPressed: () => _editTeacher(t),
                              child: Text('수정',
                                  style: TextStyle(
                                      fontFamily: "NotoSansKR",
                                      color: Palette.secondaryDark)),
                            ),
                            if (isOwnerTeacher)
                              TextButton(
                                onPressed: () => _editOwnerBookingOffer(t),
                                child: Text('수업 받기',
                                    style: TextStyle(
                                        fontFamily: "NotoSansKR",
                                        color: Palette.secondaryDark)),
                              ),
                            if (!isOwnerTeacher)
                              TextButton(
                                onPressed: () async {
                                  final error = await AuthService
                                      .setTeacherActive(uid, !active);
                                  if (error != null) {
                                    _toast(error, error: true);
                                    return;
                                  }
                                  _toast(active
                                      ? '강사를 비활성화했습니다.'
                                      : '강사를 활성화했습니다.');
                                  await _refresh();
                                },
                                child: Text(active ? '비활성화' : '활성화',
                                    style: TextStyle(
                                        fontFamily: "NotoSansKR",
                                        color: active
                                            ? Palette.danger
                                            : Palette.secondaryDark)),
                              ),
                          ],
                        ),
                      ),
                      if (intro.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(left: 4, right: 4, bottom: 4),
                          child: Text(
                            intro,
                            style: TextStyle(
                              fontFamily: "NotoSansKR",
                              fontSize: 13,
                              height: 1.45,
                              color: Palette.grey700,
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: EdgeInsets.only(left: 4, right: 4, bottom: 4),
                          child: Text(
                            '소개가 없습니다. 수정에서 프로필을 채워 주세요.',
                            style: TextStyle(
                              fontFamily: "NotoSansKR",
                              fontSize: 12,
                              color: Palette.grey400,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          Divider(height: 32),
          Text('회원 → 강사 배정',
              style: TextStyle(fontFamily: "Jalnan", fontSize: 16)),
          SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () async {
                final error =
                    await AuthService.assignOwnerNativeTeacherToAllStudents();
                if (error != null) {
                  _toast(error, error: true);
                  return;
                }
                _toast('모든 수강생에게 메인 관리자를 배정했습니다.');
                await _refresh();
              },
              icon: Icon(Icons.person_pin_circle_outlined, size: 18),
              label: Text('모든 수강생에게 메인 관리자 배정',
                  style: TextStyle(fontFamily: "NotoSansKR")),
            ),
          ),
          SizedBox(height: 8),
          Text(
            '회원을 강사에게 배정하면, 해당 강사는 스케줄·예약과 회원관리(피드백)에서 그 회원만 볼 수 있습니다. 과정 배정은 메인 관리자만 할 수 있습니다.',
            style: TextStyle(
                fontFamily: "NotoSansKR", fontSize: 13, color: Palette.grey600),
          ),
          SizedBox(height: 12),
          if (_members.isEmpty)
            Text('가입된 회원이 없습니다.',
                style:
                    TextStyle(fontFamily: "NotoSansKR", color: Palette.grey500))
          else
            ..._members.map((m) {
              final teacherId = m['teacherId']?.toString() ?? '';
              final phone = m['phone']?.toString() ?? '';
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text('${m['name'] ?? ''} (${m['email'] ?? ''})',
                    style: TextStyle(fontFamily: "NotoSansKR", fontSize: 13)),
                subtitle: Text(
                  [
                    '담당: ${_teacherName(teacherId)}',
                    PhoneUtil.isValid(phone)
                        ? PhoneUtil.display(phone)
                        : '연락처 없음',
                  ].join(' · '),
                  style: TextStyle(
                      fontFamily: "NotoSansKR",
                      fontSize: 12,
                      color: Palette.grey600),
                ),
                trailing: Wrap(
                  children: [
                    TextButton(
                      onPressed: () => _editMemberPhone(m),
                      child: Text('연락처',
                          style: TextStyle(
                              fontFamily: "NotoSansKR",
                              color: Palette.secondaryDark)),
                    ),
                    TextButton(
                      onPressed: () => _assignMember(m),
                      child: Text('배정',
                          style: TextStyle(
                              fontFamily: "NotoSansKR",
                              color: Palette.secondaryDark)),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 강의 업로드 탭
// ---------------------------------------------------------------------------

class AdminLessonTab extends StatefulWidget {
  @override
  _AdminLessonTabState createState() => _AdminLessonTabState();
}

class _AdminLessonTabState extends State<AdminLessonTab> {
  OnlineCourse _selectedCourse = OnlineCourse.all.first;
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final videoUrlController = TextEditingController();
  final orderController = TextEditingController(text: '1');
  final meetingUrlController = TextEditingController();

  List<OnlineLesson> _lessons = [];
  bool _loading = true;
  bool _saving = false;
  bool _uploading = false;
  String? _pickedFileName;
  Uint8List? _pickedBytes;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    videoUrlController.dispose();
    orderController.dispose();
    meetingUrlController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
    });
    final lessons = await EnrollmentService.lessons(_selectedCourse.id);
    final meetingUrl = await EnrollmentService.meetingUrl(_selectedCourse.id);
    if (!mounted) return;
    setState(() {
      _lessons = lessons;
      meetingUrlController.text = meetingUrl;
      _loading = false;
    });
  }

  void _pickVideoFile() {
    final input = html.FileUploadInputElement()..accept = 'video/*';
    input.click();
    input.onChange.listen((event) {
      final files = input.files;
      if (files == null || files.isEmpty) return;
      final file = files.first;
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      reader.onLoadEnd.listen((event) {
        final result = reader.result;
        if (result is ByteBuffer) {
          setState(() {
            _pickedFileName = file.name;
            _pickedBytes = Uint8List.view(result);
          });
        }
      });
    });
  }

  Future<void> _saveMeetingUrl() async {
    setState(() {
      _saving = true;
    });
    final error = await EnrollmentService.saveMeetingUrl(
        _selectedCourse.id, meetingUrlController.text);
    if (!mounted) return;
    setState(() {
      _saving = false;
    });
    _toast(error ?? '화상수업 링크가 저장되었습니다.', error: error != null);
  }

  Future<void> _addLesson() async {
    final title = titleController.text.trim();
    if (title.isEmpty) {
      _toast('강의 제목을 입력해주세요.', error: true);
      return;
    }

    setState(() {
      _saving = true;
    });

    String videoUrl = videoUrlController.text.trim();

    if (_pickedBytes != null && _pickedFileName != null) {
      setState(() {
        _uploading = true;
      });
      final uploaded = await EnrollmentService.uploadLessonVideo(
        courseId: _selectedCourse.id,
        fileName: _pickedFileName!,
        bytes: _pickedBytes!,
      );
      setState(() {
        _uploading = false;
      });
      if (uploaded == null) {
        setState(() {
          _saving = false;
        });
        _toast('영상 파일 업로드에 실패했습니다. URL로 등록하거나 다시 시도해주세요.', error: true);
        return;
      }
      videoUrl = uploaded;
    }

    if (videoUrl.isEmpty) {
      setState(() {
        _saving = false;
      });
      _toast('영상 URL을 입력하거나 파일을 선택해주세요.', error: true);
      return;
    }

    final order = int.tryParse(orderController.text.trim()) ?? 0;
    final error = await EnrollmentService.addLesson(
      courseId: _selectedCourse.id,
      title: title,
      description: descriptionController.text.trim(),
      videoUrl: videoUrl,
      order: order,
    );

    if (!mounted) return;
    setState(() {
      _saving = false;
    });

    if (error != null) {
      _toast(error, error: true);
      return;
    }

    _toast('강의가 등록되었습니다.');
    titleController.clear();
    descriptionController.clear();
    videoUrlController.clear();
    _pickedBytes = null;
    _pickedFileName = null;
    orderController.text = '${order + 1}';
    await _refresh();
  }

  void _toast(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontFamily: "NotoSansKR")),
        backgroundColor: error ? Palette.danger : Palette.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(20),
      children: [
        Text('과정 선택', style: TextStyle(fontFamily: "Jalnan", fontSize: 16)),
        SizedBox(height: 8),
        DropdownButtonFormField<OnlineCourse>(
          initialValue: _selectedCourse,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Palette.white,
          ),
          items: OnlineCourse.all
              .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text('${c.order}. ${c.title}',
                        style: TextStyle(fontFamily: "NotoSansKR")),
                  ))
              .toList(),
          onChanged: (value) async {
            if (value == null) return;
            setState(() {
              _selectedCourse = value;
            });
            await _refresh();
          },
        ),
        SizedBox(height: 24),
        Text('화상수업 링크', style: TextStyle(fontFamily: "Jalnan", fontSize: 16)),
        SizedBox(height: 8),
        TextField(
          controller: meetingUrlController,
          decoration: InputDecoration(
            labelText: 'Jitsi / BigBlueButton 등 화상수업 URL',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Palette.white,
          ),
        ),
        SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Palette.darkTeal,
              foregroundColor: Palette.white,
            ),
            onPressed: _saving ? null : _saveMeetingUrl,
            child: Text('화상링크 저장', style: TextStyle(fontFamily: "Jalnan")),
          ),
        ),
        Divider(height: 36),
        Text('강의 영상 등록', style: TextStyle(fontFamily: "Jalnan", fontSize: 16)),
        SizedBox(height: 8),
        Text(
          'YouTube/Vimeo URL을 넣거나, 영상 파일을 직접 업로드할 수 있습니다.',
          style: TextStyle(
              fontFamily: "NotoSansKR", fontSize: 13, color: Palette.grey600),
        ),
        SizedBox(height: 12),
        TextField(
          controller: titleController,
          decoration: InputDecoration(
            labelText: '강의 제목',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Palette.white,
          ),
        ),
        SizedBox(height: 10),
        TextField(
          controller: descriptionController,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: '설명 (선택)',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Palette.white,
          ),
        ),
        SizedBox(height: 10),
        TextField(
          controller: videoUrlController,
          decoration: InputDecoration(
            labelText: '영상 URL (선택: 파일 업로드 시 비워도 됨)',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Palette.white,
          ),
        ),
        SizedBox(height: 10),
        TextField(
          controller: orderController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: '정렬 순서',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Palette.white,
          ),
        ),
        SizedBox(height: 10),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _pickVideoFile,
              icon: Icon(Icons.upload_file),
              label:
                  Text('영상 파일 선택', style: TextStyle(fontFamily: "NotoSansKR")),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                _pickedFileName == null
                    ? '선택된 파일 없음'
                    : '선택됨: $_pickedFileName'
                        '${_pickedBytes != null ? " (${(_pickedBytes!.length / 1024 / 1024).toStringAsFixed(1)} MB)" : ""}',
                style: TextStyle(
                    fontFamily: "NotoSansKR",
                    fontSize: 12,
                    color: Palette.grey600),
              ),
            ),
          ],
        ),
        SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Palette.darkTeal,
              foregroundColor: Palette.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            onPressed: (_saving || _uploading) ? null : _addLesson,
            child: (_saving || _uploading)
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Palette.white),
                  )
                : Text(_uploading ? '업로드 중...' : '강의 등록',
                    style: TextStyle(fontFamily: "Jalnan")),
          ),
        ),
        Divider(height: 36),
        Text('등록된 강의', style: TextStyle(fontFamily: "Jalnan", fontSize: 16)),
        SizedBox(height: 12),
        if (_loading)
          Center(child: CircularProgressIndicator())
        else if (_lessons.isEmpty)
          Text('등록된 강의가 없습니다.',
              style:
                  TextStyle(fontFamily: "NotoSansKR", color: Palette.grey500))
        else
          ..._lessons.map((lesson) => Card(
                margin: EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text('${lesson.order}. ${lesson.title}',
                      style: TextStyle(
                          fontFamily: "NotoSansKR",
                          fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    lesson.videoUrl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: "NotoSansKR", fontSize: 12),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline, color: Palette.danger),
                    onPressed: () async {
                      final err =
                          await EnrollmentService.deleteLesson(lesson.id);
                      if (err != null) {
                        _toast(err, error: true);
                      } else {
                        _toast('삭제되었습니다.');
                        await _refresh();
                      }
                    },
                  ),
                ),
              )),
      ],
    );
  }
}
