import 'package:flutter/material.dart';
import 'package:gi_english_website/pages/MemberLoginPage.dart';
import 'package:gi_english_website/pages/OnlineCheckoutPage.dart';
import 'package:gi_english_website/pages/OnlineCourseDetailPage.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/EnrollmentService.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/Palette.dart';
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMyCourses();
  }

  Future<void> _loadMyCourses() async {
    final enrollments = await EnrollmentService.myEnrollments();
    if (!mounted) return;
    setState(() {
      _myEnrollments = enrollments;
      _isLoading = false;
    });
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
                backgroundColor: Palette.secondaryDark,
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
        Text(
          email.isEmpty ? "수강 중인 프로그램" : "$email 님의 수강 중인 프로그램",
          style: TextStyle(
            fontFamily: "Jalnan",
            fontSize: 15,
            color: Palette.secondaryDark,
          ),
        ),
        SizedBox(height: 20),
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
          children: [
            Container(
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
            ),
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
                  SizedBox(height: 4),
                  Text(
                    '이번 주 ${EnrollmentService.currentWeekNumber(enrollment.createdAt)}주차 · 주간 학습 보기',
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
            allDone
                ? "화상수업 ${enrollment.totalSessions}회 모두 완료"
                : "남은 화상수업 ${enrollment.remainingSessions}회 / 전체 ${enrollment.totalSessions}회",
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
}
