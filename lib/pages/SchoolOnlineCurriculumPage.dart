import 'package:flutter/material.dart';
import 'package:gi_english_website/class/ClassPlacementQuiz.dart';
import 'package:gi_english_website/class/OnlineCourse.dart';
import 'package:gi_english_website/pages/MemberLoginPage.dart';
import 'package:gi_english_website/pages/OnlineTeacherSelectPage.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/widget/ClassPlacementDialog.dart';
import 'package:gi_english_website/widget/MobileSchoolLayout.dart';
import 'package:gi_english_website/widget/OnlineProgramSideMenu.dart';
import 'package:gi_english_website/widget/WebSchoolLayout.dart';

import '../util/WidgetUtil.dart';

class SchoolOnlineCurriculumPage extends StatefulWidget {
  const SchoolOnlineCurriculumPage({Key? key}) : super(key: key);

  @override
  _SchoolOnlineCurriculumPageState createState() =>
      _SchoolOnlineCurriculumPageState();
}

class _SchoolOnlineCurriculumPageState
    extends State<SchoolOnlineCurriculumPage> {
  OnlineCourse? _selectedCourse = OnlineCourse.all.first;
  final GlobalKey _courseListKey = GlobalKey();

  void _openPlacementTest() {
    ClassPlacementDialog.show(
      context,
      onViewCourse: (course) {
        Navigator.of(context).pop();
        setState(() => _selectedCourse = course);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final target = _courseListKey.currentContext;
          if (target != null) {
            Scrollable.ensureVisible(
              target,
              duration: const Duration(milliseconds: 400),
              alignment: 0.12,
            );
          }
        });
      },
    );
  }

  void _goTeacherSelect() {
    if (AuthService.currentUser == null) {
      MenuUtil.push(context, MemberLoginPage());
      return;
    }
    final course = _selectedCourse;
    if (course == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('과정을 선택해주세요.',
              style: TextStyle(fontFamily: 'NotoSansKR')),
          backgroundColor: Palette.danger,
        ),
      );
      return;
    }
    MenuUtil.push(context, OnlineTeacherSelectPage(course: course));
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
            OnlineProgramSideMenu(selectedIndex: 0, isMobile: true),
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
            child: OnlineProgramSideMenu(selectedIndex: 0),
          ),
          Expanded(child: content()),
        ],
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: "Jalnan",
        fontSize: 15,
        color: Palette.secondaryDark,
      ),
    );
  }

  Widget bodyText(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Palette.black,
        fontFamily: "NotoSansKR",
        fontWeight: FontWeight.normal,
        fontSize: 14,
        height: 1.6,
      ),
    );
  }

  Widget content() {
    return Container(
      alignment: Alignment.topLeft,
      width: double.maxFinite,
      padding: EdgeInsets.all(20),
      color: Palette.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "온라인 프로그램 커리큘럼",
            style: TextStyle(fontFamily: "Jalnan", fontSize: 20),
          ),
          WidgetUtil.myDivider(),
          SizedBox(height: 20),
          _placementSection(),
          SizedBox(height: 28),
          sectionTitle("과정 구성"),
          SizedBox(height: 16),
          bodyText(
            "온라인 프로그램은 학습 목표에 따라 단계별로 구성되어 있으며, 각 과정은 주 단위로 진행됩니다.\n"
            "매주 인강을 보고, 문제풀이 링크로 복습한 뒤, 체크리스트를 스스로 확인합니다.\n"
            "수강생의 레벨 진단 후 적합한 과정을 배정해 드립니다.",
          ),
          SizedBox(height: 28),
          KeyedSubtree(
            key: _courseListKey,
            child: sectionTitle("단계별 커리큘럼 · 수강료"),
          ),
          SizedBox(height: 16),
          ...OnlineCourse.all.map(_courseRadioOption),
          SizedBox(height: 20),
          SizedBox(
            width: double.maxFinite,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Palette.secondaryDark,
                foregroundColor: Palette.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _goTeacherSelect,
              icon: Icon(Icons.arrow_forward, color: Palette.white),
              label: Text(
                '다음 · 원어민 강사 선택',
                style: TextStyle(fontFamily: 'Jalnan', fontSize: 15),
              ),
            ),
          ),
          SizedBox(height: 28),
          sectionTitle("수업 진행 방식"),
          SizedBox(height: 16),
          bodyText(
            "1. 이 페이지에서 원하는 과정을 선택합니다.\n"
            "2. 메인 원어민 강사를 고릅니다.\n"
            "3. 결제 후 내 강의실에서 인강·화상수업을 진행합니다.",
          ),
          SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _courseRadioOption(OnlineCourse course) {
    final selected = _selectedCourse?.id == course.id;
    return InkWell(
      onTap: () => setState(() => _selectedCourse = course),
      child: Container(
        width: double.maxFinite,
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? Palette.secondary : Palette.grey200,
            width: selected ? 2 : 1,
          ),
          color: selected
              ? Palette.secondary.withValues(alpha: 0.04)
              : Palette.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? Palette.secondary : Palette.grey400,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${course.order}. ${course.title}',
                      style: TextStyle(
                          fontFamily: "NotoSansKR",
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  SizedBox(height: 4),
                  Text(
                      '${course.subtitle} · 화상 ${course.defaultSessions}회',
                      style: TextStyle(
                          fontFamily: "NotoSansKR",
                          fontSize: 12,
                          color: Palette.grey600)),
                ],
              ),
            ),
            Text(course.priceLabel,
                style: TextStyle(
                    fontFamily: "Jalnan",
                    fontSize: 14,
                    color: Palette.secondaryDark)),
          ],
        ),
      ),
    );
  }

  Widget _placementSection() {
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Palette.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '「나에게 맞는 클래스 선택하기」',
            style: TextStyle(
              fontFamily: 'NotoSansKR',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Palette.grey900,
            ),
          ),
          SizedBox(height: 10),
          Text(
            ClassPlacementQuiz.skipNotice,
            style: TextStyle(
              fontFamily: 'NotoSansKR',
              fontSize: 13,
              height: 1.55,
              color: Palette.grey600,
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Palette.secondary,
                foregroundColor: Palette.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: 28),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _openPlacementTest,
              child: Text(
                'Test',
                style: TextStyle(
                  fontFamily: 'NotoSansKR',
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
