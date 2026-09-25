import 'package:flutter/material.dart';
import 'package:gi_english_website/pages/SchoolAboutPage.dart';
import 'package:gi_english_website/pages/SchoolConsultationPage.dart';
import 'package:gi_english_website/pages/SchoolMapPage.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/widget/ButtonState.dart';
import 'package:gi_english_website/widget/MobileSchoolLayout.dart';
import 'package:gi_english_website/widget/AcademyHeroBanner.dart';
import 'package:gi_english_website/widget/WebSchoolLayout.dart';

import '../util/WidgetUtil.dart';

class SchoolTeachersPage extends StatefulWidget {
  const SchoolTeachersPage({Key? key}) : super(key: key);

  @override
  _SchoolTeachersPageState createState() => _SchoolTeachersPageState();
}

class _SchoolTeachersPageState extends State<SchoolTeachersPage> {
  List<ButtonState> buttonStateList = [
    ButtonState("Gi글림아일랜드", BehaviorColor.colorOnDefault, SchoolAboutPage()),
    ButtonState(
        "교원/운영시스템 소개", BehaviorColor.colorOnClick, SchoolTeachersPage()),
    ButtonState("상담/오시는 길", BehaviorColor.colorOnDefault, SchoolMapPage()),
  ];

  @override
  Widget build(BuildContext context) {
    MediaQueryData mediaQueryData = MediaQuery.of(context);
    Size size = mediaQueryData.size;
    double width = size.width;
    if (width > 768) {
      return desktopUi(context);
    } else {
      return mobileUi(context);
    }
  }

  Widget desktopUi(context) {
    return WebSchoolLayout(content: scrollView());
  }

  Widget mobileUi(context) {
    return MobileSchoolLayout(content: mobileScrollView());
  }

  Widget contentGroup() {
    return Container(
        color: Palette.white,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 232, child: leftAboutMenu()),
            Expanded(child: content()),
          ],
        ));
  }

  Widget leftAboutMenu() {
    List<Widget> children = [];
    for (int i = 0; i < buttonStateList.length; i++) {
      ButtonState buttonState = buttonStateList[i];

      bool isFirst = (i == 0);
      bool isLast = (i == buttonStateList.length - 1);

      Widget child;
      if (isFirst) {
        child = MyWidget.leftMenuTop(buttonState.color, buttonState.label);
      } else if (isLast) {
        //last
        child = MyWidget.leftMenuBottom(buttonState.color, buttonState.label);
      } else {
        child = MyWidget.leftMenuMiddle(buttonState.color, buttonState.label);
      }

      children.add(InkWell(
        child: child,
        onHover: (value) {
          buttonState.color = value
              ? BehaviorColor.colorOnHover
              : (i == 1
                  ? BehaviorColor.colorOnClick
                  : BehaviorColor.colorOnDefault);
          print(
              "label ${buttonState.label}, selectedColorList: ${buttonState.color}");
          setState(() {});
        },
        onTap: () {
          MenuUtil.push(context, buttonState.nextPage);
        },
      ));

      if (!isLast) {
        children.add(Divider(height: 1));
      }
    }

    return Container(
      padding: EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            width: 1,
            color: Palette.black,
          ),
        ),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget content() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(left: 20, top: 20, right: 20, bottom: 20),
      color: Palette.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "GLEAM ISLAND 교원/운영시스템 소개",
            style: TextStyle(fontFamily: "Jalnan", fontSize: 20),
          ),
          WidgetUtil.myDivider(),
          SizedBox(
            height: 30,
          ),
          Text(
            "원장 Mia 선생님",
            style: TextStyle(
                fontFamily: "Jalnan", fontSize: 15, color: Palette.primary),
          ),
          SizedBox(
            height: 20,
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final photo = SizedBox(
                width: 150,
                height: 300,
                child: Image.asset(
                  "assets/directorPhoto.jpeg",
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              );
              final bio = Text(
                "Mia Kim \n\n"
                "현 Gi 글림아일랜드 어학원 파주 원장\n"
                "전 서대문구 소재 청담 에이프릴 어학원 교수부장\n"
                "서대문구 소재 위즈빌 어학원 영어 유초등부 강사\n"
                "하이잉글리쉬 대기업 출강강사 (현대케피코, 두산중공업 등)\n"
                "강남 유명 OPIC (영어 구술 시험) 전문 어학원 강사\n"
                "비욘드 어학원 초, 중등 강사\n"
                "JTBC 다큐멘터리 “스포츠관광을 디렉팅하라” 영문번역",
                style: TextStyle(
                    color: Palette.black,
                    fontFamily: "NotoSansKR",
                    fontSize: 14),
              );
              final creds = Text(
                "학력 및 자격\n"
                "\n"
                "뉴질랜드 오클랜드 공과 대학교\n"
                "(Auckland University of Technology) 석사졸\n"
                "뉴질랜드 오클랜드 소재 Glenfield College 고등학교 졸\n"
                "TESOL 영어 강사 자격 보유\n"
                "(Certificate in Teaching English as a Second Language)\n"
                "(Queens Academic Group)",
                style: TextStyle(
                    color: Palette.black,
                    fontFamily: "NotoSansKR",
                    fontSize: 14),
              );
              if (constraints.maxWidth >= 720) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    photo,
                    SizedBox(width: 20),
                    Expanded(child: bio),
                    SizedBox(width: 20),
                    Expanded(child: creds),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  photo,
                  SizedBox(height: 16),
                  bio,
                  SizedBox(height: 16),
                  creds,
                ],
              );
            },
          ),
          WidgetUtil.pageImage("assets/teachers.png", maxWidth: 900),
          SizedBox(height: 40),
          Text(
            "운영시스템",
            style: TextStyle(fontFamily: "Jalnan", fontSize: 20),
          ),
          WidgetUtil.myDivider(),
          SizedBox(height: 20),
          Text(
            style: TextStyle(
                color: Palette.black,
                fontFamily: "NotoSansKR",
                fontWeight: FontWeight.normal,
                fontSize: 14),
            "글림아일랜드 어학원은 원장의 총괄 관리 하에 중등부와 초등부 한 해 전체 커리큘럼이 사전에 완벽하게 짜여진 상태로 진행되는 시스템으로, 담임 선생님들이 아이들을 밀착 관리하되, 수업 내용은 원장 및 교수부가 부단한 노력으로 연구 개발한 커리큘럼의 틀을 크게 벗어나지 않도록 철저히 관리합니다.\n"
            "글림아일랜드의 시간표는 버리는 시간이 없도록 알찬 내용으로 구성되어 있으며, 아이들이 재미와 학습을 모두 잡을 수 있도록 합니다.",
          ),
          SizedBox(height: 20),
          Text(
            "정기상담",
            style: TextStyle(
                fontFamily: "Jalnan",
                fontSize: 15,
                color: Palette.secondaryDark),
          ),
          SizedBox(height: 20),
          Text(
            style: TextStyle(
                color: Palette.black,
                fontFamily: "NotoSansKR",
                fontWeight: FontWeight.normal,
                fontSize: 14),
            "본원에서는 아이들의 학업 성취와 원 생활에 대한 정보을 학부모님과 보다 가깝게 소통하기 위하여 "
            "월 정기 담임 상담 1회, 레벨업 상담 1회를 진행합니다. 또한 상담실은 언제든 열려 있으며, "
            "원장 상담 역시 언제든 예약해주십시오.",
          ),
          SizedBox(height: 20),
          Text(
            "정기테스트",
            style: TextStyle(
                fontFamily: "Jalnan",
                fontSize: 15,
                color: Palette.secondaryDark),
          ),
          SizedBox(height: 20),
          Text(
            style: TextStyle(
                color: Palette.black,
                fontFamily: "NotoSansKR",
                fontWeight: FontWeight.normal,
                fontSize: 14),
            "• 본원에서는 아이들의 원활한 Vocabulary 습득을 위하여 정기적인 단어시험을 진행합니다.\n"
            "• 중등, 초등부 모두 매주 해당 주에 배운 단어들에 대한 쪽지 시험을 보며,\n"
            "• 매월 정기 Monthly Test, 6개월에 1회 Level Up Test 를 진행합니다\n",
          ),
          SizedBox(height: 20),
          Container(
            width: double.infinity,
            child: Image.asset("assets/tuitionFeeChart.jpeg"),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget scrollView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          mainImage(),
          contentGroup(),
          MyWidget.footer(),
        ],
      ),
    );
  }

  Widget mainImage() {
    return Container(
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          AcademyHeroBanner.photo(AcademyHeroBanner.teachers),
          Container(
            padding: EdgeInsets.only(left: 40, bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "About Us",
                  style: TextStyle(
                      color: Palette.white,
                      fontSize: 30,
                      fontFamily: "LucidaCalligraphy"),
                ),
                SizedBox(
                  height: 20,
                ),
                Container(
                  width: 150,
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Palette.black,
                      foregroundColor: Palette.black,
                    ),
                    onPressed: () {
                      MenuUtil.push(context, SchoolConsultationPage());
                    },
                    child: Text("상담신청",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: "Jalnan",
                          color: Palette.white,
                        )),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  //mobile

  Widget mobileScrollView() {
    return SingleChildScrollView(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // mobileMainImage(),
            mobileLeftMenu(),
            content(),
          ],
        ),
      ),
    );
  }

  Widget mobileLeftMenu() {
    List<Widget> children = [];
    for (int i = 0; i < buttonStateList.length; i++) {
      ButtonState buttonState = buttonStateList[i];

      bool isFirst = (i == 0);
      bool isLast = (i == buttonStateList.length - 1);

      Widget child;
      if (isFirst) {
        child =
            MyWidget.mobileLeftMenuStart(buttonState.color, buttonState.label);
      } else if (isLast) {
        //last
        child =
            MyWidget.mobileLeftMenuEnd(buttonState.color, buttonState.label);
      } else {
        child =
            MyWidget.mobileLeftMenuMiddle(buttonState.color, buttonState.label);
      }

      children.add(InkWell(
        child: child,
        onHover: (value) {
          buttonState.color = value
              ? BehaviorColor.colorOnHover
              : (i == 1
                  ? BehaviorColor.colorOnClick
                  : BehaviorColor.colorOnDefault);
          setState(() {});
        },
        onTap: () {
          MenuUtil.push(context, buttonState.nextPage);
        },
      ));

      if (!isLast) {
        children.add(Container(
          width: 1,
          height: 40,
          color: Palette.grey300,
        ));
      }
    }

    return Container(
      color: Palette.white,
      padding: EdgeInsets.all(20),
      child: Container(
        // decoration: BoxDecoration(
        //   borderRadius: BorderRadius.circular(10),
        //   border: Border.all(
        //     width: 1,
        //     color: Palette.black,
        //   ),
        // ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: children,
          ),
        ),
      ),
    );
  }

  Widget mobileMainImage() {
    return Container(
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          AcademyHeroBanner.photo(AcademyHeroBanner.teachers),
          Container(
            padding: EdgeInsets.only(left: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "About Us",
                  style: TextStyle(
                      color: Palette.white,
                      fontSize: 20,
                      fontFamily: "LucidaCalligraphy"),
                ),
                SizedBox(
                  height: 10,
                ),
                Container(
                  width: 150,
                  height: 40,
                  child: ElevatedButton(
                    child: Text(
                      "상담신청",
                      style:
                          TextStyle(fontFamily: "Jalnan", color: Palette.white),
                    ),
                    onPressed: () {
                      MenuUtil.push(context, SchoolConsultationPage());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Palette.accent,
                      foregroundColor: Palette.black,
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
