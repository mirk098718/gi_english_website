import 'package:flutter/material.dart';
import 'package:gi_english_website/pages/SchoolAboutPage.dart';
import 'package:gi_english_website/pages/SchoolTeachersPage.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/widget/ButtonState.dart';
import 'package:gi_english_website/widget/MobileSchoolLayout.dart';
import 'package:gi_english_website/widget/AcademyHeroBanner.dart';
import 'package:gi_english_website/widget/WebSchoolLayout.dart';

import '../util/WidgetUtil.dart';
import '../widget/AcademyLocationMap.dart';
import 'SchoolConsultationPage.dart';

class SchoolMapPage extends StatefulWidget {
  const SchoolMapPage({Key? key}) : super(key: key);

  @override
  _SchoolMapPageState createState() => _SchoolMapPageState();
}

class _SchoolMapPageState extends State<SchoolMapPage> {
  List<ButtonState> buttonStateList = [
    ButtonState("Gi글림아일랜드", BehaviorColor.colorOnDefault, SchoolAboutPage()),
    ButtonState(
        "교원/운영시스템 소개", BehaviorColor.colorOnDefault, SchoolTeachersPage()),
    ButtonState("상담/오시는 길", BehaviorColor.colorOnClick, SchoolMapPage()),
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
              : (i == 2
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
            "상담/오시는 길",
            style: TextStyle(fontFamily: "Jalnan", fontSize: 20),
          ),
          WidgetUtil.myDivider(),
          SizedBox(height: 24),
          Text(
            "상담 예약하기",
            style: TextStyle(fontFamily: "Jalnan", fontSize: 18),
          ),
          SizedBox(height: 12),
          Text(
            "입학 상담 및 입학 테스트를 원하시는 학부모님께서는 대표번호로 연락 주세요.\n"
            "\n"
            "• 상담 요일 : 월요일~금요일 / 토요일 오전\n"
            "• 상담 시간 : 오후 1시~8시40분 / 토요일 9시~12시\n"
            "• 상담 절차 : 031 942 0908\n"
            "  대표번호로 전화 주셔서 상담실과 상담 또는 각반 담임/원장 상담 예약 바랍니다.\n"
            "\n"
            "• 전화 상담 : 031 942 0908\n"
            "• 이메일 : gienglish.paju@gmail.com",
            style: TextStyle(
              fontFamily: "NotoSansKR",
              fontSize: 14,
              height: 1.6,
              color: Palette.black,
            ),
          ),
          SizedBox(height: 28),
          Text(
            "오시는 길",
            style: TextStyle(fontFamily: "Jalnan", fontSize: 18),
          ),
          SizedBox(height: 12),
          Text(
            "주소: ${AcademyLocationMap.address}",
            style: TextStyle(fontFamily: "NotoSansKR", fontSize: 15, height: 1.5),
          ),
          SizedBox(height: 20),
          AcademyLocationMap(),
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
          AcademyHeroBanner.photo(AcademyHeroBanner.map),
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
                      foregroundColor: Palette.black,
                      backgroundColor: Palette.black,
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
              : (i == 2
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
          color: Palette.primaryLight,
        ));
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
          AcademyHeroBanner.photo(AcademyHeroBanner.map),
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
                      foregroundColor: Palette.black,
                      backgroundColor: Palette.accent,
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
