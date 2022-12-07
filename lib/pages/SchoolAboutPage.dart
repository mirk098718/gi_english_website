import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gi_english_website/pages/SchoolMapPage.dart';
import 'package:gi_english_website/pages/SchoolSystemPage.dart';
import 'package:gi_english_website/pages/SchoolTeachersPage.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/widget/ButtonState.dart';
import 'package:gi_english_website/widget/MobileSchoolLayout.dart';
import 'package:gi_english_website/widget/WebSchoolLayout.dart';

import 'SchoolConsultationPage.dart';


class SchoolAboutPage extends StatefulWidget {
  const SchoolAboutPage({Key? key}) : super(key: key);

  @override
  _SchoolAboutPageState createState() => _SchoolAboutPageState();
}

class _SchoolAboutPageState extends State<SchoolAboutPage> {

  List<ButtonState> buttonStateList = [
    ButtonState("Gi글림아일랜드", BehaviorColor.colorOnClick, SchoolAboutPage()),
    ButtonState("교원소개", BehaviorColor.colorOnDefault,SchoolTeachersPage()),
    ButtonState("운영시스템", BehaviorColor.colorOnDefault, SchoolSystemPage()),
    ButtonState("오시는 길", BehaviorColor.colorOnDefault, SchoolMapPage()),
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
    return MobileSchoolLayout(content:mobileScrollView());
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
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.only(left: 20, top: 20, right: 20, bottom: 20),
      color: Palette.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "GLEAM ISLAND 의 철학과 목표",
            style: TextStyle(fontFamily: "Jalnan", fontSize: 20),
          ),
          Divider(),
          SizedBox(
            height: 20,
          ),
          Text(style: TextStyle(color: Palette.black, fontFamily: "MaruBuri", fontWeight: FontWeight.normal,
              fontSize: 14),
              "GLEAM ISLAND 란 반짝이는 섬 이라는 뜻으로 오세아니아의 아름다운 섬, \n"
                  "뉴질랜드의 교육 철학과 정신을 컨셉트로 한 이름입니다. \n"
              "자유로운 탐구와 적극적인 토론, Creative learning 을 기반으로 하여,\n"
                  "뉴질랜드와 호주 등 오세아니아 국가들은 아이들이 \n"
                  "무한히 창의적인 발상을 할 수 있도록 가르치며, \n"
                  "지루하고 틀에 박힌 주입식 교육 시스템에서 벗어나, \n"
                  "반짝이는 아이디어를 마음껏 발산할 수 있는 \n"
                  "교육 현장을 제공하는 것이 저희 GLEAM ISLAND 의 모토입니다.\n"
              "GLEAM ISLAND 는 놀이와 학습 현장이 적절히 배분되어 있어, \n"
                  "아이들이 지루할 틈이 없는 활기 넘치는 공간일 것입니다."
              ),
          SizedBox(
            height: 20,
          ),
          Text("GLEAM ISLAND 어학원",
              style: TextStyle(
                  fontFamily: "Jalnan",
                  fontSize: 15,
                  color: Palette.deepGreen)),
          SizedBox(
            height: 20,
          ),
          Text(style: TextStyle(color: Palette.black, fontFamily: "MaruBuri", fontWeight: FontWeight.normal,
              fontSize: 14),
              "Gi 글림아일랜드 어학원은,\n"
              "* 영어의 Fundamental을 확립할 Grammar 프로그램,\n"
              "* 적극적 의사표현력을 습득할  NIE Speaking (Debate) 프로그램,\n"
              "* 풍부한 스피킹 표현력을 배울 Gi Expression 프로그램, \n"
              "* Reading 능력을 키워줄  원서읽기 Slow Reading 프로그램,\n"
              "* 유치부를 위한 S.T.E.A.M 프로그램 (Science, Technology, Engineering, Arts, Mathematics)\n"
              "등의 양질의 교육 서비스와 액티비티 프로그램을 제공하는 프리미엄 소수정예 영어학원입니다."),
          SizedBox(
            height: 20,
          ),
          Text("GLEAM ISLAND 어학원만의 New Zealand 현지 체험 프로그램",
              style: TextStyle(
                  fontFamily: "Jalnan",
                  fontSize: 15,
                  color: Palette.deepGreen)),
          SizedBox(
            height: 20,
          ),
          Text(style: TextStyle(color: Palette.black, fontFamily: "MaruBuri", fontWeight: FontWeight.normal,
              fontSize: 14),
              "뻔하고 지루한 방학 특강 프로그램,\n"
              "여기 저기서 많이 들어 보고 시켜도 봤지만, 큰 효과를 얻지 못하셨죠?\n"
              "글림아일랜드는 파격적인 뉴질랜드 현지 공립학교 체험 프로그램을 도입하여, \n"
              "현지 코디네이터와 협업하여, 매 년 아이들이 최상의 방학 프로그램을 즐길 수 있도록 지원합니다!\n"
              "뉴질랜드 에듀케이션 '공식' 에이전트인 믿을만한 현지 코디네이터 '비전유학'과 함께하는 알차고 재미있는 현지 영어 체험!\n"
              "공부도 활동도 놓치지 않는 글림아일랜드만의 방학 프로그램! 그 어떤 교육보다 유익하면서도 아이들에게는 잊지 못할 추억을 선사해드립니다!\n"
              "(자세한 내용은 'NZ 연계 프로그램' 페이지를 참고하세요!^^)"
              ),
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
          Image.asset("assets/aboutMainImage.png"),
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
        color: Colors.white,
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
        child = MyWidget.mobileLeftMenuStart(buttonState.color, buttonState.label);
      } else if (isLast) {
        //last
        child = MyWidget.mobileLeftMenuEnd(buttonState.color, buttonState.label);
      } else {
        child = MyWidget.mobileLeftMenuMiddle(buttonState.color, buttonState.label);
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
        children.add(Container(width: 1, height: 40, color: Palette.mainLightPurple,));
      }

    }

    return Container(
      color: Palette.white,
      padding: EdgeInsets.all(20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: children,
        ),
      ),
    );
  }

  Widget mobileMainImage() {
    return Container(
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Image.asset("assets/aboutMainImage.png"),
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
                      backgroundColor: Palette.mainMediumPurple,
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
