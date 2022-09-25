import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gi_english_website/pages/School1on1Page.dart';
import 'package:gi_english_website/pages/SchoolAllDayPage.dart';
import 'package:gi_english_website/pages/SchoolCampPage.dart';
import 'package:gi_english_website/pages/SchoolConsultationPage.dart';
import 'package:gi_english_website/pages/SchoolNZPage.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/widget/ButtonState.dart';
import 'package:gi_english_website/widget/MobileSchoolLayout.dart';
import 'package:gi_english_website/widget/WebSchoolLayout.dart';

class SchoolProgramPage extends StatefulWidget {
  const SchoolProgramPage({Key? key}) : super(key: key);

  @override
  _SchoolProgramPageState createState() => _SchoolProgramPageState();
}

class _SchoolProgramPageState extends State<SchoolProgramPage> {
  List<ButtonState> buttonStateList = [
    ButtonState("정규프로그램", BehaviorColor.colorOnClick, SchoolProgramPage()),
    ButtonState("올데이케어", BehaviorColor.colorOnDefault, SchoolAllDayPage()),
    ButtonState("방학캠프", BehaviorColor.colorOnDefault, SchoolCampPage()),
    ButtonState("NZ연계프로그램", BehaviorColor.colorOnDefault, SchoolNZPage()),
    ButtonState("1on1 프로그램", BehaviorColor.colorOnDefault, School1on1Page()),
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
            "정규 프로그램",
            style: TextStyle(fontFamily: "Jalnan", fontSize: 20),
          ),
          Divider(),
          Container(
            margin: EdgeInsets.only(top: 20, bottom: 20),
            // padding: EdgeInsets.all(10),
            width: 440, color: Palette.greyTenPer,
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "유치부",
                        style: TextStyle(fontFamily: "Jalnan", fontSize: 15),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 5),
                        height: 2,
                        width: 180,
                        color: Colors.black,
                      ),
                      Container(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 10),
                          Text(
                            "운영시간",
                            style:
                                TextStyle(fontFamily: "Jalnan", fontSize: 15),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Text("오전 9.15 ~ 오후 3시\n"
                              "(자세한 시간표는 커리큘럼 참조)"),
                          SizedBox(
                            height: 10,
                          ),
                          Text(
                            "대상",
                            style:
                                TextStyle(fontFamily: "Jalnan", fontSize: 15),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Text("5세 7세 미취학 유아"),
                        ],
                      )
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.only(right: 20, top: 20, bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "초등부",
                        style: TextStyle(fontFamily: "Jalnan", fontSize: 15),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 5),
                        height: 2,
                        width: 180,
                        color: Colors.black,
                      ),
                      Container(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 10,
                          ),
                          Text(
                            "운영시간",
                            style:
                                TextStyle(fontFamily: "Jalnan", fontSize: 15),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Text("오후 3.10 ~ 오후 7시\n"
                              "(자세한 시간표는 커리큘럼 참조)"),
                          SizedBox(
                            height: 10,
                          ),
                          Text(
                            "대상",
                            style:
                                TextStyle(fontFamily: "Jalnan", fontSize: 15),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Text("초등 1학년 ~ 6학년"),
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
          Text(
            "프로그램 개요",
            style: TextStyle(fontFamily: "Jalnan", fontSize: 15),
          ),
          SizedBox(
            height: 20,
          ),
          Text(
              "Creative Arts는 아이들이 재미있게 즐길 수 있는 다양한 아트 활동을 통해서 아이디어를 자유롭게 표현할 수 있는 시간입니다.\n"
              "영어능력뿐 아니라 창의력과 상상력을 함께 성장시킬 수 있는 놀이 프로그램입니다."),
          SizedBox(
            height: 20,
          ),
        ],
      ),
    );
  }

  Widget mobileContent() {
    return Container(
      padding: EdgeInsets.all(20),
      color: Palette.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "정규 프로그램",
            style: TextStyle(fontFamily: "Jalnan", fontSize: 20),
          ),
          Divider(),
          Container(
            margin: EdgeInsets.only(top: 20, bottom: 20),
            // padding: EdgeInsets.all(10),
            padding: EdgeInsets.all(20),
            width: 440,
            color: Palette.greyTenPer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "유치부",
                  style: TextStyle(fontFamily: "Jalnan", fontSize: 15, color: Palette.mainPurple),
                ),
                Container(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(height: 10),
                  Text(
                    "운영시간", style: TextStyle(fontFamily: "Jalnan", fontSize: 15),
                  ),
                  SizedBox(height: 10),
                  Text("오전 9.15 ~ 오후 3시\n"
                      "(자세한 시간표는 커리큘럼 참조)"),
                  SizedBox(
                    height: 10
                  ),
                  Text(
                    "대상", style: TextStyle(fontFamily: "Jalnan", fontSize: 15)),
                  SizedBox(height: 10),
                  Text("5세 7세 미취학 유아"),
                ]),
                SizedBox(height: 10),
                Divider(color: Palette.black, thickness: 2),
                SizedBox(height: 10),
                Text("초등부", style: TextStyle(fontFamily: "Jalnan", fontSize: 15, color: Palette.mainPurple),
                ),
                Container(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 10,
                    ),
                    Text(
                      "운영시간",
                      style: TextStyle(fontFamily: "Jalnan", fontSize: 15),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Text("오후 3.10 ~ 오후 7시\n"
                        "(자세한 시간표는 커리큘럼 참조)"),
                    SizedBox(
                      height: 10,
                    ),
                    Text(
                      "대상",
                      style: TextStyle(fontFamily: "Jalnan", fontSize: 15),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Text("초등 1학년 ~ 6학년"),
                  ],
                )
              ],
            ),
          ),
          Text(
            "프로그램 개요",
            style: TextStyle(fontFamily: "Jalnan", fontSize: 15),
          ),
          SizedBox(
            height: 20,
          ),
          Text(
              "Creative Arts는 아이들이 재미있게 즐길 수 있는 다양한 아트 활동을 통해서 아이디어를 자유롭게 표현할 수 있는 시간입니다.\n"
              "영어능력뿐 아니라 창의력과 상상력을 함께 성장시킬 수 있는 놀이 프로그램입니다."),
          SizedBox(
            height: 20,
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
            // mobileMainImage(),
            mobileLeftMenu(),
            mobileContent(),
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  "Program",
                  style: TextStyle(
                      color: Palette.white,
                      fontSize: 20,
                      fontFamily: "LucidaCalligraphy"),
                ),
                Spacer(),
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
                SizedBox(width: 20)
              ],
            ),
          )
        ],
      ),
    );
  }
}
