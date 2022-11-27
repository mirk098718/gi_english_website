import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gi_english_website/pages/SchoolAllDayPage.dart';
import 'package:gi_english_website/pages/SchoolConsultationPage.dart';
import 'package:gi_english_website/pages/SchoolProgramPage.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/widget/ButtonState.dart';
import 'package:gi_english_website/widget/MobileSchoolLayout.dart';
import 'package:gi_english_website/widget/WebSchoolLayout.dart';
import 'package:url_launcher/url_launcher.dart';

import '../util/UrlIUtil.dart';

class SchoolNZPage extends StatefulWidget {
  const SchoolNZPage({Key? key}) : super(key: key);

  @override
  _SchoolNZPageState createState() => _SchoolNZPageState();
}

class _SchoolNZPageState extends State<SchoolNZPage> {
  List<ButtonState> buttonStateList = [
    ButtonState("정규프로그램", BehaviorColor.colorOnDefault, SchoolProgramPage()),
    ButtonState("올데이케어", BehaviorColor.colorOnDefault, SchoolAllDayPage()),
    ButtonState("NZ연계프로그램", BehaviorColor.colorOnClick, SchoolNZPage()),
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
      padding: EdgeInsets.all(20),
      color: Palette.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "New Zealand 연계 방학 프로그램",
            style: TextStyle(fontFamily: "Jalnan", fontSize: 20),
          ),
          Divider(),
          SizedBox(
            height: 20,
          ),
          Image.asset("assets/aucklandView.png"),
          SizedBox(
            height: 20,
          ),
          Text(
            "운영기간",
            style: TextStyle(
                fontFamily: "Jalnan", fontSize: 15, color: Palette.deepGreen),
          ),
          SizedBox(
            height: 20,
          ),
          Text(
              style: TextStyle(
                  color: Palette.black,
                  fontFamily: "MaruBuri",
                  fontWeight: FontWeight.normal,
                  fontSize: 13),
              "여름방학 / 겨울방학 기간 동안 뉴질랜드 공립학교에서 직접 수업을 들으며 원어민 친구들을 사귈 수 있는 단기 2주 또는 4주 코스."),
          SizedBox(
            height: 20,
          ),
          Text(
            "대상",
            style: TextStyle(
                fontFamily: "Jalnan", fontSize: 15, color: Palette.deepGreen),
          ),
          SizedBox(
            height: 20,
          ),
          Text(
              style: TextStyle(
                  color: Palette.black,
                  fontFamily: "MaruBuri",
                  fontWeight: FontWeight.normal,
                  fontSize: 13),
              "뉴질랜드 현지 단기 (2주~4주) 어학연수 코스를 경험하고 싶은 본원 초등부 학생과 학부모. 조기 유학은 부담스럽고, 단기 여행으로는 큰 영어 습득의 효과를 얻을 수 없기에, 적절한 기간의 단기 연수를 주기적으로 체험하고 싶은 학생과 학부모."),
          SizedBox(
            height: 40,
          ),
          Text(
            "왜 뉴질랜드인가?",
            style: TextStyle(fontFamily: "Jalnan", fontSize: 15),
          ),
          Divider(),
          SizedBox(
            height: 20,
          ),
          InkWell(
              onTap: () {
                launchUrl(
                  Uri.parse('https://m.youtube.com/watch?v=Ytc6ClRRhw0'),
                );
              },
              child: Image.asset("assets/whyChooseNzClip.png")),
          SizedBox(
            height: 20,
          ),
          Image.asset("assets/whyNz.png"),
          SizedBox(
            height: 40,
          ),
          Text(
            "왜 타우랑가인가?",
            style: TextStyle(fontFamily: "Jalnan", fontSize: 15),
          ),
          Divider(),
          SizedBox(
            height: 20,
          ),
          InkWell(
            child: Image.asset("assets/whyTaurangaClipWeb.png"),
            onTap: () async {
              UrlUtil.open('https://www.youtube.com/watch?v=uT2IIPu5uuY');
            },
          ),
          SizedBox(
            height: 20,
          ),
          Image.asset("assets/whyTauranga.png"),
          SizedBox(
            height: 20,
          ),
          SizedBox(
            height: 40,
          ),
          Text(
            "학교 선택 기준",
            style: TextStyle(fontFamily: "Jalnan", fontSize: 15),
          ),
          Divider(),
          Image.asset("assets/schoolSelection.png"),
          SizedBox(
            height: 40,
          ),
          Text(
            "학교 리스트",
            style: TextStyle(fontFamily: "Jalnan", fontSize: 15),
          ),
          Divider(),
          Image.asset("assets/schoolList.png"),
          SizedBox(
            height: 20,
          ),
          Text(
            "자료 제공: 비전유학",
            textAlign: TextAlign.end,
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
          Image.asset("assets/ballPoolImage.png"),
          Container(
            padding: EdgeInsets.only(left: 40, bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "Program",
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
        children.add(Container(
          width: 1,
          height: 40,
          color: Palette.mainLightPurple,
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
          Image.asset("assets/ballPoolImage.png"),
          Container(
            padding: EdgeInsets.only(left: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Program",
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
