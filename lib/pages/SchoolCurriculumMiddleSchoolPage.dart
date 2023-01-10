
import 'package:flutter/material.dart';
import 'package:gi_english_website/pages/SchoolConsultationPage.dart';
import 'package:gi_english_website/pages/SchoolCurriculumElePage.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/widget/ButtonState.dart';
import 'package:gi_english_website/widget/MobileSchoolLayout.dart';
import 'package:gi_english_website/widget/WebSchoolLayout.dart';

import '../util/WidgetUtil.dart';

class SchoolCurriculumMiddleSchoolPage extends StatefulWidget {
  const SchoolCurriculumMiddleSchoolPage({Key? key}) : super(key: key);

  @override
  _SchoolCurriculumMiddleSchoolPageState createState() =>
      _SchoolCurriculumMiddleSchoolPageState();
}

class _SchoolCurriculumMiddleSchoolPageState extends State<SchoolCurriculumMiddleSchoolPage> {
  List<ButtonState> buttonStateList = [
    ButtonState(
        "정규중등부", BehaviorColor.colorOnClick, SchoolCurriculumMiddleSchoolPage()),
    ButtonState(
        "정규초등부", BehaviorColor.colorOnDefault, SchoolCurriculumElePage()),
  ];

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
              : (i == 0
                  ? BehaviorColor.colorOnClick
                  : BehaviorColor.colorOnDefault);
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        width: MediaQuery.of(context).size.width,
        alignment: Alignment.topLeft,
        padding: EdgeInsets.all(20),
        color: Palette.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "정규 중등부 Curriculum",
              style: TextStyle(fontFamily: "Jalnan", fontSize: 20),
            ),
            WidgetUtil.myDivider(),
            SizedBox(height: 20),
            Text(style: TextStyle(
                color: Palette.black,
                fontFamily: "MaruBuri",
                fontWeight: FontWeight.normal,
                fontSize: 14),
                "글림아일랜드 중등부는 "
                "균형을 맞춘 자체 커리큘럼을 100% 영어로 소화하고 있으며, 아이들이 창의성을 최대한 발휘할 수 있는 재미있는 수업 방식을 채택하여 진행합니다.\n"
                "또한 Kids Times, Junior Times와 같은 영자신문 프로그램과 코딩 수업을 영어로 제공하는 Wonder Code 등 뛰어난 외부 교육프로그램 역시 적용하고 교육 효과를 극대화하고 있습니다."),
            SizedBox(height: 20),
            Container(
                width: 600, child: Image.asset("assets/eleTimetableMWF.png")),
            // SizedBox(height: 40),
            // Text(
            //   "Scholastic Reading",
            //   style: TextStyle(fontFamily: "Jalnan", fontSize: 20),
            // ),
            // Divider(),
            // Container(
            //     padding: EdgeInsets.only(top: 20, bottom: 20),
            //     width: 500,
            //     child: Image.asset("assets/scholasticLogo.jpg")),
            // Text(style: TextStyle(
            //     color: Palette.black,
            //     fontFamily: "MaruBuri",
            //     fontWeight: FontWeight.normal,
            //     fontSize: 14),
            //     "Scholastic 은 전 세계적으로 가장 크고 유명한 출판사 중 하나로, 양질의 영문원서들과 다양한 관련 교육 프로그램들을 제공합니다.\n"
            //     "Scholastic 은 'Lexile 지수'를 사용, 사용자의 읽기 능력을 판별하고, 읽기 능력에 따라 적합한 레벨의 서적들을 제시합니다.\n"
            //     "글림아일랜드는 Scholastic 에서 출판한 교육적이며 재미있는 영문 원서들로 구성된 자체 Library 를 제공하며,\n"
            //     "풍부한 reading material 들을 활용하여 Slow reading 기법을 적용한 재미있는 읽기 수업을 진행합니다.\n"),
            // // Text(
            // //   "렉사일 수준이란 무엇입니까?\n",
            // //   style: TextStyle(fontFamily: "Jalnan", fontSize: 15),
            // // ),
            // // Text(style: TextStyle(
            // //     color: Palette.black,
            // //     fontFamily: "MaruBuri",
            // //     fontWeight: FontWeight.normal,
            // //     fontSize: 14),
            // //     "학교에서 학생 독자의 능력을 측정하는 데 사용하는 인기 있는 방법은 Lexile 수준 또는 Lexile 측정입니다. Lexile 지수는 교사, 학부모, 학생에게 유용한 도구입니다.\n"
            // //     "두 가지 고유한 기능을 제공합니다. 텍스트가 얼마나 어려운지 또는 학생의 읽기 능력 수준을 측정하는 것입니다.\n"
            // //     "Lexile Framework는 원래 국립 아동 건강 및 인간 발달 연구소(National Institute of Child Health and Human Development)의\n"
            // //     "자금 지원을 받은 교육 평가 및 연구 팀인 MetaMetrics©에서 개발했습니다.\n\n"
            // //     "* 렉사일 점수는 무엇을 의미합니까?:\n\n"
            // //     "학생은 Lexile 또는 읽기 능력을 측정하기 위해 특별히 고안된 학교에서 시행하는 SRI(Scholastic Reading Inventory) 시험을 치르거나 독자의 결과를 렉사일 지수.\n"
            // //     "학생이 550L을 받으면 550레벨 Lexile 독자입니다. 550L은 가독성 수준의 척도입니다. 절대 점수라고 하지 않는다는 점에 유의하세요! 이것은 학생의 성취를 격려합니다.\n\n"
            // //     "* 책의 Lexile을 찾는 방법:\n\n"
            // //     "책의 Lexile 지수는 MetaMetrics©에서 분석합니다.\n"
            // //     "텍스트가 평가된 후 학생의 가독성 수준과 같은 측정값이 제공됩니다(예: 600L).\n"
            // //     "이 측정에서 MetaMetrics©는 텍스트의 난이도를 평가하고 있습니다. 500L의 책이나 잡지의 Lexile 레벨은 500입니다.\n"
            // //     "MetaMetrics©는 텍스트가 독자가 이해하기 얼마나 어려울지 예측하고 평가합니다. 테스트하는 두 가지 주요 기준은 단어 빈도와 문장 강도입니다.\n"
            // //     "텍스트의 Lexile Framework는 10L이 가장 낮은 값으로 10씩 증가합니다. 10L 미만의 측정값은 BR 또는 초급 독자로 분류됩니다.\n\n"
            // //     "* 실제 Lexile 수준:\n\n"
            // //     "독자와 텍스트 모두에게 이상적인 것은 평가된 Lexile 측정치를 모두 일치시키는 것입니다.\n"
            // //     "예를 들어 책이나 잡지에 770L이 있고 독자는 Lexile 수준 770으로 평가됩니다. 교실당 읽기 수준은 광범위하고 다양합니다.\n"
            // //     "학생을 이상적인 텍스트에 맞추는 데에는 여러 가지 요소가 있습니다.\n"
            // //     "Lexile Framework는 개입이 필요한 영역을 대상으로 하고 학년 수준 및 커리큘럼 전반에 걸쳐 성취를 장려하므로 올바른 Lexile 수준에서 올바른 책을 선택하는 데 좋은 출발점입니다.\n\n"
            // //     "* 자녀의 렉사일 수준에 맞는 책을 찾는 방법:\n\n"
            // //     "Lexile 수준은 책의 난이도와 가독성에 따라 과학적, 수학적으로 지정됩니다.\n"
            // //     "자녀의 Lexile 수준을 알면 이 수준에 맞는 책을 검색하여 가정 도서관을 확장하고 가정에서 매일 읽기 연습을 장려할 수 있습니다.\n"
            // //     "Lexile 데이터베이스를 사용하여 Lexile 수준, 제목 또는 주제별로 검색하여 자녀가 좋아하고 읽기 성취도에 낙담하지 않고 읽을 수 있는 책을 찾으십시오.\n"
            // //     "아래 차트를 사용하여 Lexile 수준을 다른 수준별 읽기 시스템과 비교하십시오:"),
            SizedBox(height: 40),
            Text(
              "Wonder Code",
              style: TextStyle(fontFamily: "Jalnan", fontSize: 20),
            ),
            WidgetUtil.myDivider(),
            SizedBox(height: 20),
            Container(
                width: 500, child: Image.asset("assets/wonderCodeLogo.jpg")),
            SizedBox(height: 20),
            Text(style: TextStyle(
                color: Palette.black,
                fontFamily: "MaruBuri",
                fontWeight: FontWeight.normal,
                fontSize: 14),
                "원더코드는 코딩 및 IT 전문 교육 기관으로, 글림아일랜드는 원더코드와 손잡고\n"
                "아이들의 프로그래밍적 사고와 문제해결능력을 키우기 위한 특별한 코딩 교육을 제공합니다."),
            SizedBox(
                height: 40),
            Text(
              "NIE 영자신문 수업",
              style: TextStyle(fontFamily: "Jalnan", fontSize: 20),
            ),
            WidgetUtil.myDivider(),
            SizedBox(height: 5),
            Container(width:600,
                margin: EdgeInsets.only(top:10,bottom: 10,left: 30, right: 30),
                child: Image.asset("assets/nieAd2.png")),
            Container(
              width: 600,
              margin: EdgeInsets.only(top:10,bottom: 10,left: 30, right:30),
              child: Text(style: TextStyle(
                  color: Palette.black,
                  fontFamily: "MaruBuri",
                  fontWeight: FontWeight.normal,
                  fontSize: 14),
                  "킨더 타임즈, 키즈 타임즈, 주니어 타임즈 등 아이들의 레벨과 연령에 맞추어 다양한 영자신문을 제공하는 어린이 영자 신문 전문 브랜드로, "
                      "글림아일랜드는 중등부 NIE Speaking 수업과 초등부 NIE Debate 수업을 위하여"
                      "모든 레벨의 어린이 영자신문을 class material 로 적극 활용합니다."),
            ),
            WidgetUtil.myDivider(),
            SizedBox(height: 10),
            Image.asset("assets/nieAd.png"),

            WidgetUtil.myDivider(),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget scrollView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          mainImage(),
          contentGroup(),
          SizedBox(height: 213, child: MyWidget.footer()),
        ],
      ),
    );
  }

  Widget mainImage() {
    return Container(
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          Image.asset("assets/curriculumImage.png"),
          Container(
            padding: EdgeInsets.only(left: 40, bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "Curriculum",
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
                    onPressed: () {MenuUtil.push(context, SchoolConsultationPage());},
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
        child: Column(
          children: [
            // mobileMainImage(),
            mobileLeftMenu(),
            content(),
            SizedBox(height: 51, child: MyWidget.mobileSchoolFooter())
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
              : (i == 0
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
          color: Palette.mainLightPurple,
        ));
      }
    }

    return Container(
      alignment: Alignment.center,
      width: MediaQuery.of(context).size.width,
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

}
