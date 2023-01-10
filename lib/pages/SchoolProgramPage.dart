import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gi_english_website/pages/SchoolConsultationPage.dart';
import 'package:gi_english_website/pages/SchoolNZPage.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/widget/ButtonState.dart';
import 'package:gi_english_website/widget/MobileSchoolLayout.dart';
import 'package:gi_english_website/widget/WebSchoolLayout.dart';

import '../util/WidgetUtil.dart';
import 'SchoolCodingPage.dart';

class SchoolProgramPage extends StatefulWidget {
  const SchoolProgramPage({Key? key}) : super(key: key);

  @override
  _SchoolProgramPageState createState() => _SchoolProgramPageState();
}

class _SchoolProgramPageState extends State<SchoolProgramPage> {
  List<ButtonState> buttonStateList = [
    ButtonState("정규프로그램", BehaviorColor.colorOnClick, SchoolProgramPage()),
    ButtonState("영어코딩프로그램", BehaviorColor.colorOnDefault, SchoolCodingPage()),
    ButtonState("NZ연계프로그램", BehaviorColor.colorOnDefault, SchoolNZPage()),
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
          WidgetUtil.myDivider(),
          Container(
            margin: EdgeInsets.only(top: 20, bottom: 20),
            // padding: EdgeInsets.all(10),
            width: 500, color: Palette.greyTenPer,
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "중등부",
                        style: TextStyle(fontFamily: "Jalnan", fontSize: 15, color: Palette.deepGreen),
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
                          Text(style: TextStyle(
                              color: Palette.black,
                              fontFamily: "MaruBuri",
                              fontWeight: FontWeight.normal,
                              fontSize: 14),
                              "오전 9시 30분 ~ 오후 2시 30분\n"
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
                          Text(style: TextStyle(
                              color: Palette.black,
                              fontFamily: "MaruBuri",
                              fontWeight: FontWeight.normal,
                              fontSize: 14),
                              "14세~16세 (만 13세~만 15세) \n"
                                  "중학생"),
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
                        style: TextStyle(fontFamily: "Jalnan", fontSize: 15, color: Palette.deepGreen),
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
                          Text(style: TextStyle(
                              color: Palette.black,
                              fontFamily: "MaruBuri",
                              fontWeight: FontWeight.normal,
                              fontSize: 14),
                              "오후 2.20 ~ 오후 7시\n"
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
                          Text(style: TextStyle(
                              color: Palette.black,
                              fontFamily: "MaruBuri",
                              fontWeight: FontWeight.normal,
                              fontSize: 14),
                              "초등학교 1학년 ~ 6학년 \n"
                                  ""),
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
          Text(
            "중등부 프로그램 개요",
            style: TextStyle(fontFamily: "Jalnan", fontSize: 15, color: Palette.deepGreen),
          ),
          SizedBox(
            height: 20,
          ),
          Text(style: TextStyle(
              color: Palette.black,
              fontFamily: "MaruBuri",
              fontWeight: FontWeight.normal,
              fontSize: 14),
              "글림아일랜드의 영어 중등부 프로그램은, \n"
              "뉴질랜드 College 교육 현장의 자유로움과, 자기표현, 크리에이티비티를 중시하는 분위기를 그대로 도입하여\n"
                  "다양하면서도 독특한 수업을 제공합니다. 아이들을 질리게 하는 공부만을 위한 공부가 되지 않도록\n"
                  "아이들이 사회, 과학, 예술 등 다양한 영역에 대한 상식과 세상을 배울 수 있도록 다양한 컨텐츠를 다루는 영자신문을 활용한\n"
                  "NIE Speaking 프로그램은 아이들의 영어 실력을 눈에 띄게 향상시킬 것 입니다.\n"
                  "그 외, 선택 과목으로 컴퓨터 프로그래밍적인 사고를 배울 수 있는 코딩 수업을 제공합니다."),
          SizedBox(
            height: 20,
          ),
          Text(
            "초등부 프로그램 개요",
            style: TextStyle(fontFamily: "Jalnan", fontSize: 15, color: Palette.deepGreen),
          ),
          SizedBox(
            height: 20,
          ),
          Text(style: TextStyle(
              color: Palette.black,
              fontFamily: "MaruBuri",
              fontWeight: FontWeight.normal,
              fontSize: 14),
              "글림아일랜드의 영어 초등부 프로그램은, \n"
                  "뉴질랜드 초등 교육 현장의 자유로움과, 자기표현, 크리에이티비티를 중시하는 분위기를 그대로 도입하여\n"
                  "다양하면서도 독특한 수업을 제공합니다. 언어 교육에 기본이 되는 리딩, 문법 수업을 통하여 기본기를 탄탄히 하되,\n"
                  "영자 신문을 활용한 스피치, Debate 수업을 통하여 아이들이 다양한 상식을 접함과 동시에 이에 대한 본인의 생각을\n"
                  "표현할 수 있도록 가르치며, 토론이 익숙치 않은 아이들이 효과적으로 설득력 있게 말하는 방법을 배울 것 입니다.\n"
                  "또한 분기별로 이루어질 Speech Contest 를 통하여, 아이들이 더욱 적극적으로 목표 의식을 가지고 수업에 임할 수 있도록 합니다.\n"
                  "글림아일랜드의 초등부 수업은 아이들이 현지 초등학교 수업에 참여할 수 있을 정도의 실용적 영어실력을 갖추게 하는 것이 목표이며,\n"
                  "실제로 뉴질랜드 공립학교 방항 프로그램에 참여하여 현지 영어를 직접 체험할 수 있도록 합니다."),
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
          WidgetUtil.myDivider(),
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
                  "중등",
                  style: TextStyle(fontFamily: "Jalnan", fontSize: 15, color: Palette.deepGreen),
                ),
                Container(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(height: 10),
                  Text(
                    "운영시간", style: TextStyle(fontFamily: "Jalnan", fontSize: 15),
                  ),
                  SizedBox(height: 10),
                  Text(style: TextStyle(
                      color: Palette.black,
                      fontFamily: "MaruBuri",
                      fontWeight: FontWeight.normal,
                      fontSize: 14),
                      "오전 9시 30분 ~ 오후 2시 30분\n"
                      "(자세한 시간표는 커리큘럼 참조)"),
                  SizedBox(
                    height: 10
                  ),
                  Text(
                    "대상", style: TextStyle(fontFamily: "Jalnan", fontSize: 15)),
                  SizedBox(height: 10),
                  Text(style: TextStyle(
                      color: Palette.black,
                      fontFamily: "MaruBuri",
                      fontWeight: FontWeight.normal,
                      fontSize: 14),
                      "14세~16세 (만13세~만15세) \n"
                          "중등학생"),
                ]),
                SizedBox(height: 10),
                Divider(color: Palette.black, thickness: 2),
                SizedBox(height: 10),
                Text("초등부", style: TextStyle(color: Palette.deepGreen, fontFamily: "Jalnan", fontSize: 15),
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
                    Text(style: TextStyle(
                        color: Palette.black,
                        fontFamily: "MaruBuri",
                        fontWeight: FontWeight.normal,
                        fontSize: 14),
                        "오후 2시 20분 ~ 오후 7시\n"
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
                    Text(style: TextStyle(
                        color: Palette.black,
                        fontFamily: "MaruBuri",
                        fontWeight: FontWeight.normal,
                        fontSize: 14),
                        "초등학교 1학년 ~ 6학년"),
                  ],
                )
              ],
            ),
          ),
          Text(
            "중등부 프로그램 개요",
            style: TextStyle(fontFamily: "Jalnan", fontSize: 15, color: Palette.deepGreen),
          ),
          SizedBox(
            height: 20,
          ),
          Text(style: TextStyle(
              color: Palette.black,
              fontFamily: "MaruBuri",
              fontWeight: FontWeight.normal,
              fontSize: 14),
              "글림아일랜드의 영어 중등부 프로그램은, \n"
                  "뉴질랜드 College 교육 현장의 자유로움과, 자기표현, 크리에이티비티를 중시하는 분위기를 그대로 도입한 커리큘럼을 제공하며,\n"
                  "아이들이 사회, 과학, 예술 등 다양한 영역에 대한 상식과 세상을 배울 수 있도록 다양한 컨텐츠를 제공하는 영자신문을 활용한\n"
                  "NIE Speaking 프로그램은 아이들의 영어 실력을 눈에 띄게 향상시킬 것 입니다.\n"
                  "그 외에도, 컴퓨터 프로그래밍적인 사고를 배울 수 있는 코딩 수업, 두뇌 발달과 재미을 동시에 잡는 체스 시간 역시\n"
                  "타 영어유치원에서는 볼 수 없는 글림아일랜드만의 특별 프로그램이랍니다! :)"),
          SizedBox(
            height: 20,
          ),
          Text(
            "초등부 프로그램 개요",
            style: TextStyle(fontFamily: "Jalnan", fontSize: 15, color: Palette.deepGreen),
          ),
          SizedBox(
            height: 20,
          ),
          Text(style: TextStyle(
              color: Palette.black,
              fontFamily: "MaruBuri",
              fontWeight: FontWeight.normal,
              fontSize: 14),
              "글림아일랜드의 영어 초등부 프로그램은, \n"
                  "뉴질랜드 초등 교육 현장의 자유로움과, 자기표현, 크리에이티비티를 중시하는 분위기를 그대로 도입하여\n"
                  "다양하면서도 독특한 수업을 제공합니다. 언어 교육에 기본이 되는 리딩, 문법 수업을 통하여 기본기를 탄탄히 하되,\n"
                  "영자 신문을 활용한 스피치, Debate 수업을 통하여 아이들이 다양한 상식을 접함과 동시에 이에 대한 본인의 생각을\n"
                  "표현할 수 있도록 가르치며, 토론이 익숙치 않은 아이들이 효과적으로 설득력 있게 말하는 방법을 배울 것 입니다.\n"
                  "또한 분기별로 이루어질 Speech Contest 를 통하여, 아이들이 더욱 적극적으로 목표 의식을 가지고 수업에 임할 수 있도록 합니다.\n"
                  "글림아일랜드의 초등부 수업은 아이들이 현지 초등학교 수업에 참여할 수 있을 정도의 실용적 영어실력을 갖추게 하는 것이 목표이며,\n"
                  "실제로 뉴질랜드 공립학교 방항 프로그램에 참여하여 현지 영어를 직접 체험할 수 있도록 합니다."),
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
                      backgroundColor: Palette.mainMediumPurple,
                      foregroundColor: Palette.black,
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
