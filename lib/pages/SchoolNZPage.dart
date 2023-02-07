import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
import '../util/WidgetUtil.dart';
import 'SchoolCodingPage.dart';

class SchoolNZPage extends StatefulWidget {
  const SchoolNZPage({Key? key}) : super(key: key);

  @override
  _SchoolNZPageState createState() => _SchoolNZPageState();
}

class _SchoolNZPageState extends State<SchoolNZPage> {
  List<ButtonState> buttonStateList = [
    ButtonState("정규프로그램", BehaviorColor.colorOnDefault, SchoolProgramPage()),
    ButtonState("선택프로그램", BehaviorColor.colorOnDefault, SchoolCodingPage()),
    ButtonState("뉴질랜드프로그램", BehaviorColor.colorOnClick, SchoolNZPage()),
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
      padding: EdgeInsets.all(20),
      color: Palette.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "New Zealand 현지 공립학교 체험 프로그램",
            style: TextStyle(fontFamily: "Jalnan", fontSize: 20),
          ),
          WidgetUtil.myDivider(),
          SizedBox(
            height: 20,
          ),
          Image.asset("assets/aucklandView.png"),
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
          Text(style: TextStyle(color: Palette.black, fontFamily: "NotoSansKR", fontWeight: FontWeight.normal,
              fontSize: 14),
              "뻔하고 지루한 방학 특강 프로그램,\n"
                  "여기 저기서 많이 들어 보고 시켜도 봤지만, 큰 효과를 얻지 못하셨죠?\n"
                  "글림아일랜드는 파격적인 뉴질랜드 현지 공립학교 체험 프로그램을 도입하여, \n"
                  "현지 코디네이터와 협업하여, 매 년 아이들이 최상의 방학 프로그램을 즐길 수 있도록 지원합니다!\n"
                  "뉴질랜드 에듀케이션 '공식' 에이전트인 믿을만한 현지 코디네이터 '비전유학'과 함께하는 알차고 재미있는 현지 영어 체험!\n"
                  "공부도 활동도 놓치지 않는 글림아일랜드만의 방학 프로그램! 그 어떤 교육보다 유익하면서도 아이들에게는 잊지 못할 추억을 선사해드립니다!"

          ),
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
                  fontFamily: "NotoSansKR",
                  fontWeight: FontWeight.normal,
                  fontSize: 14),
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
                  fontFamily: "NotoSansKR",
                  fontWeight: FontWeight.normal,
                  fontSize: 14),
              "뉴질랜드 현지 단기 (2주~4주) 어학연수 코스를 경험하고 싶은 본원 초등부 학생과 학부모. 조기 유학은 부담스럽고, 단기 여행으로는 큰 영어 습득의 효과를 얻을 수 없기에, 적절한 기간의 단기 연수를 주기적으로 체험하고 싶은 학생과 학부모."),
          SizedBox(
            height: 40,
          ),
          Text(
            "뉴질랜드 교육환경",
            style: TextStyle(fontFamily: "Jalnan", fontSize: 15),
          ),
          WidgetUtil.myDivider(),
          SizedBox(
            height: 40,
          ),
          SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(width: 800, child: Image.asset("assets/whyNZInfo.png"))),
          SizedBox(
            height: 40,
          ),
          InkWell(
              onTap: () {
                launchUrl(
                  Uri.parse('https://m.youtube.com/watch?v=Ytc6ClRRhw0'),
                );
              },
              child: Container(width:800, child: Image.asset("assets/whyChooseNzClip.png"))),

          SizedBox(
            height: 40,
          ),
          Text(
            "Tauranga City 소개",
            style: TextStyle(fontFamily: "Jalnan", fontSize: 15),
          ),
          WidgetUtil.myDivider(),
          SizedBox(
            height: 40,
          ),
          SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(width:800, child: Image.asset("assets/whyTaurangaInfo.png"))),

          SizedBox(
            height: 40,
          ),
          InkWell(
            child: Container(width:800, child: Image.asset("assets/whyTaurangaClipWeb.png")),
            onTap: () async {
              UrlUtil.open('https://www.youtube.com/watch?v=uT2IIPu5uuY');
            },
          ),
          SizedBox(
            height: 40,
          ),
          SizedBox(
            height: 40,
          ),
          Text(
            "학교 선택",
            style: TextStyle(fontFamily: "Jalnan", fontSize: 15),
          ),
          WidgetUtil.myDivider(),
          SizedBox(
            height: 40,
          ),
          Image.asset("assets/schoolSelection.png"),
          SizedBox(
            height: 40,
          ),
          Text(
            "학교 리스트",
            style: TextStyle(fontFamily: "Jalnan", fontSize: 15),
          ),
          WidgetUtil.myDivider(),
          SizedBox(
            height: 40,
          ),
          Image.asset("assets/schoolList.png"),
          Image.asset("assets/nzMiddleSchoolList.png"),

          SizedBox(
            height: 40,
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
