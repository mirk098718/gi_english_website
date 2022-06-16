import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gi_english_website/cafePages/CafeAboutPage.dart';
import 'package:gi_english_website/cafePages/CafeGalleryPage.dart';
import 'package:gi_english_website/cafePages/CafeMapPage.dart';
import 'package:gi_english_website/cafePages/CafeReservationPage.dart';
import 'package:gi_english_website/cafePages/CafeStaffPage.dart';
import 'package:gi_english_website/pages/SchoolCommunityNoticePage.dart';
import 'package:gi_english_website/pages/SchoolGalleryPage.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/widget/ButtonState.dart';
import 'package:gi_english_website/widget/MobileCafeLayout.dart';
import 'package:gi_english_website/widget/WebCafeLayout.dart';

class CafeSystemPage extends StatefulWidget {
  const CafeSystemPage({Key? key}) : super(key: key);

  @override
  _CafeSystemPageState createState() => _CafeSystemPageState();
}

class _CafeSystemPageState extends State<CafeSystemPage> {

  List<ButtonState> buttonStateList = [
    ButtonState("Gi글림아일랜드", BehaviorColor.colorOnDefault, CafeAboutPage()),
    ButtonState("교원소개", BehaviorColor.colorOnDefault,CafeStaffPage()),
    ButtonState("운영시스템", BehaviorColor.colorOnClick, CafeSystemPage()),
    ButtonState("오시는 길", BehaviorColor.colorOnDefault, CafeMapPage()),
  ];

  @override
  Widget build(BuildContext context) {

    MediaQueryData mediaQueryData = MediaQuery.of(context);
    Size size = mediaQueryData.size;
    double width = size.width;
    if(width>768){
      return WebCafeLayout( content: scrollView());
    }
    else{
      return MobileCafeLayout(content: mobileScrollView());
    }
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

  Widget contentGroup() {
    return Container(
        color: Palette.white,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width:232, child: leftAboutMenu()),
            Expanded(child: content()),
          ],
        )
    );
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
      alignment: Alignment.topLeft,
      padding: EdgeInsets.all(20),
      color: Palette.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Gi English Kids Cafe 운영 시스템",
            style: TextStyle(fontFamily: "Jalnan", fontSize: 20),
          ),
          Divider(),
          SizedBox(
            height: 20,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "요금",
                    textAlign: TextAlign.left,
                    style: TextStyle(fontFamily: "Jalnan", fontSize: 15,),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Text(
                      "● 운영지침 \n\n"
                          "* 100% 예약제로 운영\n"
                          "(단, 인원이 꽉 차지 않았을 경우 워크인도 참여가능)\n"
                          "* 보호자 대동 필수\n"
                          "* 월~금 1:3 / 토, 일 1:4 비율로 원어민프로그램진행\n\n"
                          "● 요금 \n\n"
                          "* 1회권 2시간이용 49.000원\n"
                          "어린이 1인당 보호자 아메리카노 1잔 포함\n"
                          "(음료변경시 추가금 결제 )\n\n"
                          "원어민프로그램 40분+자유놀이 20분 총 2타임 진행\n\n"
                          "● 정기권\n\n"
                          "10회 2개월 5%할인 465.500원\n"
                          "20회 3개월 10%할인 882.000원\n"
                          "50회 6개월 15%할인 2.082.500원 "),
                ],
              ),
              SizedBox(width: 50),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "시간표",
                    style: TextStyle(fontFamily: "Jalnan", fontSize: 15),
                  ),
                  SizedBox(height: 20,),
                  Text("● 운영시간 및 시간표\n"
                      "평일 원어민 1명 운영\n"
                      "주말 원어민 2명 운영\n\n"
                      "* 월~금 14:30 ~ 20:30\n\n"
                      "14:30 ~ 16:30\n"
                      "16:30 ~ 18:30\n"
                      "18:30 ~ 20:30\n\n"
                      "* 토 10:30 ~ 20:30\n\n"
                      "10:30 ~ 12:30\n"
                      "12:30 ~ 14:30\n"
                      "14:30 ~ 16:30\n"
                      "16:30 ~ 18:30\n"
                      "18:30 ~ 20:30\n\n"
                      "* 일 11:00 ~ 19:00\n\n"
                      "11:00 ~ 13:00\n"
                      "13:00 ~ 15:00\n"
                      "15:00 ~ 17:00\n"
                      "17:00 ~ 19:00")
                ],
              )
            ],
          ),

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

  Widget mobileContent() {
    return Container(
      alignment: Alignment.topLeft,
      padding: EdgeInsets.all(20),
      color: Palette.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Gi English Kids Cafe 운영 시스템",
            style: TextStyle(fontFamily: "Jalnan", fontSize: 20),
          ),
          Divider(),
          SizedBox(
            height: 20,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "요금",
                style: TextStyle(fontFamily: "Jalnan", fontSize: 15),
              ),
              SizedBox(
                height: 20,
              ),
              Text(
                  "● 운영지침 \n\n"
                      "* 100% 예약제로 운영\n"
                      "(단, 인원이 꽉 차지 않았을 경우 워크인도 참여가능)\n"
                      "* 보호자 대동 필수\n"
                      "* 월~금 1:3 / 토, 일 1:4 비율로 원어민프로그램진행\n\n"
                      "● 요금 \n\n"
                      "* 1회권 2시간이용 49.000원\n"
                      "어린이 1인당 보호자 아메리카노 1잔 포함\n"
                      "(음료변경시 추가금 결제 )\n\n"
                      "원어민프로그램 40분+자유놀이 20분 총 2타임 진행\n\n"
                      "● 정기권\n\n"
                      "10회 2개월 5%할인 465.500원\n"
                      "20회 3개월 10%할인 882.000원\n"
                      "50회 6개월 15%할인 2.082.500원 "),
            ],
          ),
          SizedBox(height: 30,),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "시간표",
                style: TextStyle(fontFamily: "Jalnan", fontSize: 15),
              ),
              SizedBox(height: 20,),
              Text("● 운영시간 및 시간표\n"
                  "평일 원어민 1명 운영\n"
                  "주말 원어민 2명 운영\n\n"
                  "* 월~금 14:30 ~ 20:30\n\n"
                  "14:30 ~ 16:30\n"
                  "16:30 ~ 18:30\n"
                  "18:30 ~ 20:30\n\n"
                  "* 토 10:30 ~ 20:30\n\n"
                  "10:30 ~ 12:30\n"
                  "12:30 ~ 14:30\n"
                  "14:30 ~ 16:30\n"
                  "16:30 ~ 18:30\n"
                  "18:30 ~ 20:30\n\n"
                  "* 일 11:00 ~ 19:00\n\n"
                  "11:00 ~ 13:00\n"
                  "13:00 ~ 15:00\n"
                  "15:00 ~ 17:00\n"
                  "17:00 ~ 19:00")
            ],
          ),

        ],
      ),
    );
  }
}
