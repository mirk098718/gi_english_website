import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gi_english_website/cafePages/CafeAboutPage.dart';
import 'package:gi_english_website/cafePages/CafeMapPage.dart';
import 'package:gi_english_website/cafePages/CafeReservationPage.dart';
import 'package:gi_english_website/cafePages/CafeSystemPage.dart';
import 'package:gi_english_website/pages/SchoolAboutPage.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/widget/ButtonState.dart';
import 'package:gi_english_website/widget/MobileCafeLayout.dart';
import 'package:gi_english_website/widget/WebCafeLayout.dart';
import 'package:gi_english_website/widget/WebSchoolLayout.dart';

class CafeStaffPage extends StatefulWidget {
  const CafeStaffPage({Key? key}) : super(key: key);



  @override
  _CafeStaffPageState createState() => _CafeStaffPageState();
}

class _CafeStaffPageState extends State<CafeStaffPage> {
  List<ButtonState> buttonStateList = [
    ButtonState("Gi글림아일랜드", BehaviorColor.colorOnDefault, CafeAboutPage()),
    ButtonState("교원소개", BehaviorColor.colorOnClick,CafeStaffPage()),
    ButtonState("운영시스템", BehaviorColor.colorOnDefault, CafeSystemPage()),
    ButtonState("오시는 길", BehaviorColor.colorOnDefault, CafeMapPage()),
  ];

  @override
  Widget build(BuildContext context) {
    MediaQueryData mediaQueryData = MediaQuery.of(context);
    Size size = mediaQueryData.size;
    double width = size.width;
    if (width > 768) {
      return WebCafeLayout(content: scrollView());
    } else {
      return MobileCafeLayout(content: mobileScrollView());
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
      // width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.only(left: 20, top: 20, right: 20, bottom: 20),
      color: Palette.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "GLEAM ISLAND 교원 소개",
            style: TextStyle(fontFamily: "Jalnan", fontSize: 20),
          ),
          Divider(),
          SizedBox(
            height: 30,
          ),
          Text("원장 Mia 선생님",style: TextStyle(fontFamily: "Jalnan", fontSize: 15, color: Palette.mainPurple),),
          SizedBox(
            height: 20,
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(alignment: Alignment.topLeft, width: 200, height: 400, child: Image.asset("mobileSchoolMainImage.png")),
                SizedBox(width: 20,),
                Text("Mia Kim \n\n"
                    "현 Gi 글림아일랜드 어학원 파주 원장\n"
                    "현 글림아일랜드 교육 대표\n"
                    "전 서대문구 소재 청담 에이프릴 어학원 교수부장\n"
                    "전 서대문구 소재 위즈빌 어학원 영어 유초등부 강사\n"
                    "전 하이 잉글리쉬 대기업 출강 강사 (현대케피코, 두산중공업 등)\n"
                    "전 강남 유명 OPIC (영어 구술 시험) 전문 어학원 강사\n"
                    "전 비욘드 어학원 초, 중등 강사\n"
                    "JTBC 다큐멘터리 “스포츠관광을 디렉팅하라” 영문번역"
                    "\n\n"
                    "학력 및 자격\n"
                    "\n"
                    "뉴질랜드 오클랜드 공과 대학교 (Auckland University of Technology) 석사졸\n"
                    "뉴질랜드 오클랜드 소재 Glenfield College 고등학교 졸\n"
                    "TESOL 영어 강사 자격 보유\n"
                    "(Certificate in Teaching English as a Second Language)")
              ],
            ),
          ),

          // SizedBox(
          //   height: 10,
          // ),

          Text("부원장 Mia 선생님",style: TextStyle(fontFamily: "Jalnan", fontSize: 15, color: Palette.mainPurple),),
          SizedBox(
            height: 20,
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(alignment: Alignment.topLeft, width: 200, height: 400, child: Image.asset("mobileSchoolMainImage.png")),
                SizedBox(width: 20,),
                Text("Mia Kim \n\n"
                    "현 Gi 글림아일랜드 어학원 파주 원장\n"
                    "현 글림아일랜드 교육 대표\n"
                    "전 서대문구 소재 청담 에이프릴 어학원 교수부장\n"
                    "전 서대문구 소재 위즈빌 어학원 영어 유초등부 강사\n"
                    "전 하이 잉글리쉬 대기업 출강 강사 (현대케피코, 두산중공업 등)\n"
                    "전 강남 유명 OPIC (영어 구술 시험) 전문 어학원 강사\n"
                    "전 비욘드 어학원 초, 중등 강사\n"
                    "JTBC 다큐멘터리 “스포츠관광을 디렉팅하라” 영문번역"
                    "\n\n"
                    "학력 및 자격\n"
                    "\n"
                    "뉴질랜드 오클랜드 공과 대학교 (Auckland University of Technology) 석사졸\n"
                    "뉴질랜드 오클랜드 소재 Glenfield College 고등학교 졸\n"
                    "TESOL 영어 강사 자격 보유\n"
                    "(Certificate in Teaching English as a Second Language)")
              ],
            ),
          ),
          SizedBox(
            height: 20,),
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
          SizedBox(height: 213, child: MyWidget.cafeFooter()),
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
            child:
            Column(
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
                      "예약문의",
                      style: TextStyle(
                          fontFamily: "Jalnan", color: Palette.white),
                    ),
                    onPressed: () {MenuUtil.push(context, CafeReservationPage());},
                    style: ElevatedButton.styleFrom(
                      primary: Palette.mainLime,
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
            SizedBox(height: 51, child: MyWidget.mobileCafeFooter())

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
                      "예약문의",
                      style:
                      TextStyle(fontFamily: "Jalnan", color: Palette.white),
                    ),
                    onPressed: () {
                      MenuUtil.push(context, CafeReservationPage());
                    },
                    style: ElevatedButton.styleFrom(
                      primary: Palette.mainLime,
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
