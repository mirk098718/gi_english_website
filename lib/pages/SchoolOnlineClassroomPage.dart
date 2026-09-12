import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gi_english_website/class/OnlineCourse.dart';
import 'package:gi_english_website/pages/MemberLoginPage.dart';
import 'package:gi_english_website/pages/OnlineCheckoutPage.dart';
import 'package:gi_english_website/pages/OnlineCourseDetailPage.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/EnrollmentService.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/NotificationService.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/PhoneUtil.dart';
import 'package:gi_english_website/widget/MobileSchoolLayout.dart';
import 'package:gi_english_website/widget/OnlineProgramSideMenu.dart';
import 'package:gi_english_website/widget/WebSchoolLayout.dart';

import '../util/WidgetUtil.dart';

class SchoolOnlineClassroomPage extends StatefulWidget {
  const SchoolOnlineClassroomPage({Key? key}) : super(key: key);

  @override
  _SchoolOnlineClassroomPageState createState() =>
      _SchoolOnlineClassroomPageState();
}

class _SchoolOnlineClassroomPageState extends State<SchoolOnlineClassroomPage> {
  List<EnrollmentRecord> _myEnrollments = [];
  List<AppNotification> _notifications = [];
  String _memberPhone = '';
  bool _isLoading = true;
  bool _savingPhone = false;
  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    _loadMyCourses();
    _authSub = AuthService.authStateChanges.listen((user) {
      if (!mounted) return;
      if (user == null) {
        setState(() {
          _myEnrollments = [];
          _notifications = [];
          _memberPhone = '';
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _logout() async {
    await AuthService.signOut();
    if (!mounted) return;
    setState(() {
      _myEnrollments = [];
      _notifications = [];
      _memberPhone = '';
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('로그아웃되었습니다.', style: TextStyle(fontFamily: 'NotoSansKR')),
        backgroundColor: Palette.success,
      ),
    );
  }

  Future<void> _loadMyCourses() async {
    await AuthService.selectableNativeTeachers();
    final enrollments = await EnrollmentService.myEnrollments();
    final member = await AuthService.currentMemberDoc();
    final notifications = await NotificationService.listMine();
    if (!mounted) return;
    setState(() {
      _myEnrollments = enrollments;
      _notifications = notifications;
      _memberPhone = member?['phone']?.toString() ?? '';
      _isLoading = false;
    });
  }

  Future<void> _editPhone({String initial = ''}) async {
    final controller = TextEditingController(text: PhoneUtil.display(initial));
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Palette.white,
        surfaceTintColor: Palette.white,
        title: Text('휴대폰 번호', style: TextStyle(fontFamily: "Jalnan")),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: '010-0000-0000',
            helperText: '화상수업이 확정되면 이 번호로 알림 문자를 보냅니다.',
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
    if (saved != true || !mounted) return;
    final uid = AuthService.currentUser?.uid ?? '';
    setState(() => _savingPhone = true);
    final error = await AuthService.updateMemberPhone(memberId: uid, phone: phone);
    if (!mounted) return;
    setState(() => _savingPhone = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error, style: TextStyle(fontFamily: "NotoSansKR")),
          backgroundColor: Palette.danger,
        ),
      );
      return;
    }
    setState(() => _memberPhone = PhoneUtil.normalize(phone));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('연락처를 저장했습니다.', style: TextStyle(fontFamily: "NotoSansKR")),
        backgroundColor: Palette.success,
      ),
    );
  }

  List<Widget> _notificationCards() {
    final unread = _notifications.where((item) => !item.read).toList();
    if (unread.isEmpty) return const [];
    return [
      ...unread.take(5).map((item) => Container(
            width: double.maxFinite,
            margin: EdgeInsets.only(bottom: 10),
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Palette.secondary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Palette.secondary.withValues(alpha: 0.25)),
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
                              height: 1.45,
                              color: Palette.grey700)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await NotificationService.markRead(item.id);
                    if (!mounted) return;
                    setState(() {
                      _notifications = _notifications
                          .map((n) => n.id == item.id
                              ? AppNotification(
                                  id: n.id,
                                  userId: n.userId,
                                  title: n.title,
                                  body: n.body,
                                  type: n.type,
                                  bookingId: n.bookingId,
                                  read: true,
                                  createdAt: n.createdAt,
                                )
                              : n)
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
      SizedBox(height: 8),
    ];
  }

  Widget _phoneBanner() {
    final hasPhone = PhoneUtil.isValid(_memberPhone);
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.all(14),
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
                  ? '알림 문자 수신 번호 ${PhoneUtil.display(_memberPhone)}'
                  : '화상수업이 확정되면 문자로 알려 드립니다. 휴대폰 번호를 등록해 주세요.',
              style: TextStyle(
                  fontFamily: "NotoSansKR",
                  fontSize: 13,
                  color: Palette.grey700),
            ),
          ),
          TextButton(
            onPressed: _savingPhone
                ? null
                : () => _editPhone(initial: _memberPhone),
            child: Text(hasPhone ? '변경' : '등록',
                style: TextStyle(
                    fontFamily: "NotoSansKR", color: Palette.secondaryDark)),
          ),
        ],
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
    bool isLoggedIn = AuthService.currentUser != null;

    return Container(
      alignment: Alignment.topLeft,
      width: double.maxFinite,
      padding: EdgeInsets.all(20),
      color: Palette.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "내 강의실",
            style: TextStyle(fontFamily: "Jalnan", fontSize: 20),
          ),
          WidgetUtil.myDivider(),
          SizedBox(height: 20),
          isLoggedIn ? loggedInView() : loginRequiredView(),
          SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget loginRequiredView() {
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
          Text(
            "로그인이 필요합니다",
            style: TextStyle(
              fontFamily: "Jalnan",
              fontSize: 15,
              color: Palette.secondaryDark,
            ),
          ),
          SizedBox(height: 12),
          Text(
            "내 강의실은 온라인 프로그램을 신청하신 회원만 이용할 수 있습니다.\n"
            "로그인하시면 배정된 강의 목록과 수강 현황을 확인하실 수 있습니다.",
            style: TextStyle(
              fontFamily: "NotoSansKR",
              fontSize: 14,
              color: Palette.black,
              height: 1.6,
            ),
          ),
          SizedBox(height: 20),
          SizedBox(
            width: 200,
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Palette.darkTeal,
                foregroundColor: Palette.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                MenuUtil.push(context, MemberLoginPage());
              },
              child: Text(
                "회원 로그인",
                style: TextStyle(
                  fontFamily: "Jalnan",
                  color: Palette.white,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget loggedInView() {
    String email = AuthService.currentUser?.email ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                email.isEmpty ? "수강 중인 프로그램" : "$email 님의 수강 중인 프로그램",
                style: TextStyle(
                  fontFamily: "Jalnan",
                  fontSize: 15,
                  color: Palette.secondaryDark,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _logout,
              icon: Icon(Icons.logout, size: 16, color: Palette.grey600),
              label: Text(
                '로그아웃',
                style: TextStyle(
                  fontFamily: 'NotoSansKR',
                  fontSize: 13,
                  color: Palette.grey600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        ..._notificationCards(),
        _phoneBanner(),
        SizedBox(height: 12),
        if (_isLoading)
          Container(
            padding: EdgeInsets.symmetric(vertical: 40),
            alignment: Alignment.center,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else if (_myEnrollments.isEmpty)
          emptyCourseView()
        else
          Column(
            children: [
              ..._myEnrollments.map(courseCard),
              SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () {
                    MenuUtil.push(context, OnlineCheckoutPage());
                  },
                  icon: Icon(Icons.add_shopping_cart, size: 16),
                  label: Text('다른 프로그램 결제하기',
                      style: TextStyle(fontFamily: "NotoSansKR")),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget emptyCourseView() {
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
          Icon(Icons.play_circle_outline, size: 40, color: Palette.grey400),
          SizedBox(height: 12),
          Text(
            "결제하신 프로그램이 없습니다.",
            style: TextStyle(
              fontFamily: "NotoSansKR",
              fontSize: 14,
              color: Palette.grey600,
            ),
          ),
          SizedBox(height: 6),
          Text(
            "과정을 선택하고 결제하시면 이곳에 프로그램이 표시됩니다.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: "NotoSansKR",
              fontSize: 13,
              color: Palette.grey500,
            ),
          ),
          SizedBox(height: 18),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Palette.secondaryDark,
              foregroundColor: Palette.white,
            ),
            onPressed: () {
              MenuUtil.push(context, OnlineCheckoutPage());
            },
            child: Text("프로그램 결제하기", style: TextStyle(fontFamily: "Jalnan")),
          ),
        ],
      ),
    );
  }

  Widget courseCard(EnrollmentRecord enrollment) {
    final course = enrollment.course;
    if (course == null) return SizedBox.shrink();

    final sessionsConfigured = enrollment.totalSessions > 0;
    final allDone = sessionsConfigured && enrollment.remainingSessions <= 0;

    return InkWell(
      onTap: () {
        MenuUtil.push(context, OnlineCourseDetailPage(course: course));
      },
      child: Container(
        width: double.maxFinite,
        margin: EdgeInsets.only(bottom: 14),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Palette.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Palette.grey200),
          boxShadow: [
            BoxShadow(
              color: Palette.grey200.withValues(alpha: 0.6),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _courseLeading(enrollment, course),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: TextStyle(
                      fontFamily: "NotoSansKR",
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Palette.black,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    course.subtitle,
                    style: TextStyle(
                      fontFamily: "NotoSansKR",
                      fontSize: 13,
                      color: course.accentColor,
                    ),
                  ),
                  if (enrollment.nativeTeacher != null ||
                      enrollment.nativeTeacherLabel.isNotEmpty) ...[
                    SizedBox(height: 10),
                    Text(
                      enrollment.nativeTeacher?.name ??
                          enrollment.nativeTeacherLabel,
                      style: TextStyle(
                        fontFamily: "NotoSansKR",
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Palette.secondaryDark,
                      ),
                    ),
                    if ((enrollment.nativeTeacher?.nationality ?? '')
                        .trim()
                        .isNotEmpty) ...[
                      SizedBox(height: 2),
                      Text(
                        enrollment.nativeTeacher!.nationality,
                        style: TextStyle(
                          fontFamily: "NotoSansKR",
                          fontSize: 12,
                          color: Palette.grey600,
                        ),
                      ),
                    ],
                    if ((enrollment.nativeTeacher?.intro ?? '')
                        .trim()
                        .isNotEmpty) ...[
                      SizedBox(height: 4),
                      Text(
                        enrollment.nativeTeacher!.intro,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: "NotoSansKR",
                          fontSize: 12,
                          height: 1.45,
                          color: Palette.grey700,
                        ),
                      ),
                    ],
                  ],
                  SizedBox(height: 4),
                  Text(
                    _classroomProgressCopy(enrollment, allDone),
                    style: TextStyle(
                      fontFamily: "NotoSansKR",
                      fontSize: 12,
                      color: Palette.grey600,
                    ),
                  ),
                  if (sessionsConfigured) ...[
                    SizedBox(height: 8),
                    sessionBadge(enrollment, allDone),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Palette.grey400),
          ],
        ),
      ),
    );
  }

  Widget _courseLeading(EnrollmentRecord enrollment, OnlineCourse course) {
    final teacher = enrollment.nativeTeacher;
    if (teacher != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: teacher.photo(width: 88, height: 110),
      );
    }
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: course.accentColor.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Text(
        "${course.order}",
        style: TextStyle(
          fontFamily: "Jalnan",
          fontSize: 16,
          color: course.accentColor,
        ),
      ),
    );
  }

  Widget sessionBadge(EnrollmentRecord enrollment, bool allDone) {
    final Color color = allDone ? Palette.grey500 : Palette.secondaryDark;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            allDone ? Icons.emoji_events_outlined : Icons.videocam_outlined,
            size: 15,
            color: color,
          ),
          SizedBox(width: 6),
          Text(
            _sessionBadgeCopy(enrollment, allDone),
            style: TextStyle(
              fontFamily: "NotoSansKR",
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _classroomProgressCopy(EnrollmentRecord enrollment, bool allDone) {
    if (allDone) {
      return '화상수업 ${enrollment.totalSessions}회를 모두 마쳤습니다 · 회차 학습 보기';
    }
    final session = enrollment.unlockedSessionNumber;
    if (enrollment.expiresAt != null) {
      return '$session회차 진행 중 · 기한 ${enrollment.remainingDeadlineWeeks}주 남음 · 회차 학습 보기';
    }
    return '$session회차 진행 중 · 회차 학습 보기';
  }

  String _sessionBadgeCopy(EnrollmentRecord enrollment, bool allDone) {
    if (allDone) {
      return '화상수업 ${enrollment.totalSessions}회 모두 완료';
    }
    return '남은 화상수업 ${enrollment.remainingSessions}회 / 전체 ${enrollment.totalSessions}회';
  }
}
