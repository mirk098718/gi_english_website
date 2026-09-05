import 'package:flutter/material.dart';
import 'package:gi_english_website/class/OnlineCourse.dart';
import 'package:gi_english_website/pages/MemberLoginPage.dart';
import 'package:gi_english_website/pages/OnlineCheckoutPage.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/Palette.dart';
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
          sectionTitle("과정 구성"),
          SizedBox(height: 16),
          bodyText(
            "온라인 프로그램은 학습 목표에 따라 단계별로 구성되어 있으며, 각 과정은 주 단위로 진행됩니다.\n"
            "매주 인강을 보고, 문제풀이 링크로 복습한 뒤, 체크리스트를 스스로 확인합니다.\n"
            "수강생의 레벨 진단 후 적합한 과정을 배정해 드립니다.",
          ),
          SizedBox(height: 28),
          sectionTitle("단계별 커리큘럼 · 수강료"),
          SizedBox(height: 16),
          ...OnlineCourse.all.map((course) {
            return Container(
              width: double.maxFinite,
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Palette.grey200),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
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
            );
          }),
          SizedBox(height: 28),
          sectionTitle("수업 진행 방식"),
          SizedBox(height: 16),
          bodyText(
            "1. 원하는 과정을 결제합니다.\n"
            "2. 배정된 강의를 내 강의실에서 수강합니다.\n"
            "3. 회차별 화상수업과 YouTube 인강으로 학습합니다.",
          ),
          SizedBox(height: 36),
          SizedBox(
            width: 260,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Palette.secondaryDark,
                foregroundColor: Palette.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                if (AuthService.currentUser == null) {
                  MenuUtil.push(context, MemberLoginPage());
                } else {
                  MenuUtil.push(context, OnlineCheckoutPage());
                }
              },
              child: Text(
                "프로그램 결제하기",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: "Jalnan",
                  color: Palette.white,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          SizedBox(height: 40),
        ],
      ),
    );
  }
}
