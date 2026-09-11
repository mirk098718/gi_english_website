import 'package:flutter/material.dart';
import 'package:gi_english_website/class/OnlineCourse.dart';
import 'package:gi_english_website/pages/AdminOnlineHubPage.dart';
import 'package:gi_english_website/pages/MemberLoginPage.dart';
import 'package:gi_english_website/pages/OnlineCourseDetailPage.dart';
import 'package:gi_english_website/pages/SchoolAboutPage.dart';
import 'package:gi_english_website/pages/SchoolCodingPage.dart';
import 'package:gi_english_website/pages/SchoolCommunityFAQPage.dart';
import 'package:gi_english_website/pages/SchoolCommunityNoticePage.dart';
import 'package:gi_english_website/pages/SchoolCurriculumElePage.dart';
import 'package:gi_english_website/pages/SchoolCurriculumHighSchoolPage.dart';
import 'package:gi_english_website/pages/SchoolCurriculumMiddleSchoolPage.dart';
import 'package:gi_english_website/pages/SchoolGalleryPage.dart';
import 'package:gi_english_website/pages/SchoolMapPage.dart';
import 'package:gi_english_website/pages/SchoolNZPage.dart';
import 'package:gi_english_website/pages/SchoolOnlineClassroomPage.dart';
import 'package:gi_english_website/pages/SchoolOnlineCurriculumPage.dart';
import 'package:gi_english_website/pages/SchoolProgramPage.dart';
import 'package:gi_english_website/pages/SchoolSystemPage.dart';
import 'package:gi_english_website/pages/SchoolTeachersPage.dart';
import 'package:gi_english_website/pages/WorkingAdminLoginPage.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/widget/ClassPlacementDialog.dart';

class SiteNavItem {
  final String label;
  final WidgetBuilder page;

  const SiteNavItem(this.label, this.page);
}

class SiteNavGroup {
  final String title;
  final List<SiteNavItem> items;

  const SiteNavGroup(this.title, this.items);
}

/// 온라인 우선 헤더에서 쓰는 목적지. 학원 페이지는 「글림아일랜드 어학원」 아래로 모은다.
class SiteNav {
  static final List<SiteNavGroup> academyGroups = [
    SiteNavGroup('소개', [
      SiteNavItem('학원 홈', (_) => SchoolAboutPage()),
      SiteNavItem('교원소개', (_) => SchoolTeachersPage()),
      SiteNavItem('운영 System', (_) => SchoolSystemPage()),
      SiteNavItem('상담/오시는 길', (_) => SchoolMapPage()),
    ]),
    SiteNavGroup('프로그램', [
      SiteNavItem('정규프로그램', (_) => SchoolProgramPage()),
      SiteNavItem('선택프로그램', (_) => SchoolCodingPage()),
      SiteNavItem('뉴질랜드프로그램', (_) => SchoolNZPage()),
    ]),
    SiteNavGroup('커리큘럼', [
      SiteNavItem('정규 초등부', (_) => SchoolCurriculumElePage()),
      SiteNavItem('정규 중등부', (_) => SchoolCurriculumMiddleSchoolPage()),
      SiteNavItem('정규 고등부', (_) => SchoolCurriculumHighSchoolPage()),
    ]),
    SiteNavGroup('커뮤니티', [
      SiteNavItem('공지사항', (_) => SchoolCommunityNoticePage()),
      SiteNavItem('갤러리', (_) => SchoolGalleryPage()),
      SiteNavItem('FAQ', (_) => SchoolCommunityFAQPage()),
    ]),
  ];

  static bool get isMemberLoggedIn => AuthService.currentUser != null;

  static void goHome(BuildContext context) {
    MenuUtil.push(context, const SchoolAboutPage());
  }

  static void goCourses(BuildContext context) {
    if (!isMemberLoggedIn) return;
    MenuUtil.push(context, const SchoolOnlineCurriculumPage());
  }

  static void goCourse(BuildContext context, OnlineCourse course) {
    if (!isMemberLoggedIn) return;
    MenuUtil.push(context, OnlineCourseDetailPage(course: course));
  }

  static void goClassroom(BuildContext context) {
    if (!isMemberLoggedIn) return;
    MenuUtil.push(context, const SchoolOnlineClassroomPage());
  }

  static void goAcademy(BuildContext context) {
    MenuUtil.push(context, const SchoolAboutPage());
  }

  static void goAcademyProgram(BuildContext context) {
    MenuUtil.push(context, const SchoolProgramPage());
  }

  static void goConsultation(BuildContext context) {
    MenuUtil.push(context, const SchoolMapPage());
  }

  static void goLogin(BuildContext context) {
    MenuUtil.push(context, const MemberLoginPage());
  }

  static void goAdminHub(BuildContext context) {
    MenuUtil.push(context, const AdminOnlineHubPage());
  }

  static Future<void> goAdminLogin(BuildContext context) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkingAdminLoginPage(category: 'general'),
      ),
    );
  }

  static void openPlacement(BuildContext context) {
    if (!isMemberLoggedIn) return;
    ClassPlacementDialog.show(
      context,
      onViewCourse: (course) {
        Navigator.of(context).pop();
        MenuUtil.push(context, OnlineCourseDetailPage(course: course));
      },
    );
  }

  static void openPage(BuildContext context, SiteNavItem item) {
    MenuUtil.push(context, item.page(context));
  }
}
