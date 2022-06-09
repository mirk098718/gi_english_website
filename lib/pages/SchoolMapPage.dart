import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gi_english_website/cafePages/CafeAboutPage.dart';
import 'package:gi_english_website/cafePages/CafeReservationPage.dart';
import 'package:gi_english_website/pages/SchoolAboutPage.dart';
import 'package:gi_english_website/pages/SchoolSystemPage.dart';
import 'package:gi_english_website/pages/SchoolTeachersPage.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/widget/ButtonState.dart';
import 'package:gi_english_website/widget/MobileSchoolLayout.dart';
import 'package:gi_english_website/widget/WebSchoolLayout.dart';

import 'SchoolConsultationPage.dart';


class SchoolMapPage extends StatefulWidget {
  const SchoolMapPage({Key? key}) : super(key: key);

  @override
  _SchoolMapPageState createState() => _SchoolMapPageState();
}

class _SchoolMapPageState extends State<SchoolMapPage> {
  // List<String> labelList = ["Gi글림아일랜드", "교원소개", "운영시스템", "오시는 길"];
  // List<Color> selectedColorList = [
  //   BehaviorColor.colorOnClick,
  //   BehaviorColor.colorOnDefault,
  //   BehaviorColor.colorOnDefault,
  //   BehaviorColor.colorOnDefault
  // ];
  // List<Widget> nextPageList = [
  //   CafeAboutPage(),
  // ];

  List<ButtonState> buttonStateList = [
    ButtonState("Gi글림아일랜드", BehaviorColor.colorOnDefault, SchoolAboutPage()),
    ButtonState("교원소개", BehaviorColor.colorOnDefault,SchoolTeachersPage()),
    ButtonState("운영시스템", BehaviorColor.colorOnDefault, SchoolSystemPage()),
    ButtonState("오시는 길", BehaviorColor.colorOnClick, SchoolMapPage()),
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
              : (i == 3
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
            "오시는 길",
            style: TextStyle(fontFamily: "Jalnan", fontSize: 20),
          ),
          Divider(),
          SizedBox(
            height: 20,
          ),
          Text(
              "GLEAM ISLAND 란 반짝이는 섬 이라는 뜻으로 오세아니아의 아름다운 섬 뉴질랜드의 교육 철학과 정신을 컨셉트로 한 이름입니다. \n"
                  "자유로운 탐구와 적극적인 토론, Creative learning 을 기반으로 하여, 뉴질랜드와 호주 등 오세아니아 국가들은 아이들이 \n"
                  "무한히 창의적인 발상을 할 수 있도록 가르치며, 지루하고 틀에 박힌 주입식 교육 시스템에서 벗어나, 반짝이는 아이디어를 마음껏 \n"
                  "발산할 수 있는 교육 현장을 제공하는 것이 저희 GLEAM ISLAND 의 모토입니다.\n"
                  "GLEAM ISLAND 는 놀이와 학습 현장이 적절히 배분되어 있어, 아이들이 지루할 틈이 없는 활기 넘치는 공간일 것입니다.\n"
                  "GLEAM ISLAND 는 크게 두가지의 영어공부 플랫폼을 제공합니다."),
          SizedBox(
            height: 20,
          ),
          Text("GLEAM ISLAND 어학원",
              style: TextStyle(
                  fontFamily: "Jalnan",
                  fontSize: 15,
                  color: Palette.mainMediumPurple)),
          SizedBox(
            height: 20,
          ),
          Text("Gi 글림아일랜드 어학원은,\n"
              "* 영어의 Fundamental을 확립할 Gi Grammar 프로그램,\n"
              "* 적극적 의사표현력을 습득할  Gi Discussion 프로그램,\n"
              "* 풍부한 스피킹 표현력을 배울 Gi Expression 프로그램, \n"
              "* Reading 능력을 키워줄  원서읽기 다독 Slow Reading 프로그램,\n"
              "* 유치부를 위한 S.T.E.A.M 프로그램 (Science, Technology, Engineering, Arts, Mathematics)\n"
              "등의 양질의 교육 서비스와 액티비티 프로그램을 제공하는 프리미엄 소수정예 영어학원입니다."),
          SizedBox(
            height: 20,
          ),
          Text("GLEAM ISLAND 어학원",
              style: TextStyle(
                  fontFamily: "Jalnan", fontSize: 15, color: Palette.mainLime)),
          SizedBox(
            height: 20,
          ),
          Text(
              "Gi English 키즈카페 Gi 글림아일랜드 영어키즈카페는 Gi 글림아일랜드 어학원 과 협업하여 프로그램의 전문성을 더하고, \n"
                  "아이들이 놀이를 통해 재밌게 영어를 접할 수 있는 복합놀이문화공간입니다.  \n"
                  "Storytelling, Creative Arts, Visual Contents 등 다양한 프리미엄 놀이 프로그램을 제공하며,  \n"
                  "원어민과의 interaction을 통해 아이들이 자연스럽게 영어로 소통할 수 있도록 하였습니다.  \n"
                  "또한 소수 정예 예약제를 도입하여 프로그램의 집중도를 높였으며,  \n"
                  "동행한 보호자에게도 쾌적한 공간과 휴식 시간을 제공합니다."),
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
                  height: 50,
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
                      primary: Palette.mainMediumPurple,
                      onPrimary: Palette.black,
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



  //mobile

  Widget mobileScrollView() {
    return SingleChildScrollView(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            mobileMainImage(),
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
              : (i == 3
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
                      primary: Palette.mainMediumPurple,
                      onPrimary: Palette.black,
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
