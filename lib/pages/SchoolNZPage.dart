import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gi_english_website/cafePages/CafeAboutPage.dart';
import 'package:gi_english_website/cafePages/CafeReservationPage.dart';
import 'package:gi_english_website/pages/School1on1Page.dart';
import 'package:gi_english_website/pages/SchoolAllDayPage.dart';
import 'package:gi_english_website/pages/SchoolCampPage.dart';
import 'package:gi_english_website/pages/SchoolConsultationPage.dart';
import 'package:gi_english_website/pages/SchoolProgramPage.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/widget/ButtonState.dart';
import 'package:gi_english_website/widget/MobileSchoolLayout.dart';
import 'package:gi_english_website/widget/WebSchoolLayout.dart';

class SchoolNZPage extends StatefulWidget {
  const SchoolNZPage({Key? key}) : super(key: key);

  @override
  _SchoolNZPageState createState() => _SchoolNZPageState();
}

class _SchoolNZPageState extends State<SchoolNZPage> {

  List<ButtonState> buttonStateList = [
    ButtonState("정규프로그램", BehaviorColor.colorOnDefault, SchoolProgramPage()),
    ButtonState("올데이케어", BehaviorColor.colorOnDefault, SchoolAllDayPage()),
    ButtonState("방학캠프", BehaviorColor.colorOnDefault, SchoolCampPage()),
    ButtonState("NZ연계프로그램", BehaviorColor.colorOnClick, SchoolNZPage()),
    ButtonState("1on1 프로그램", BehaviorColor.colorOnDefault, School1on1Page()),

  ];
  @override
  Widget build(BuildContext context) {

    MediaQueryData mediaQueryData = MediaQuery.of(context);
    Size size = mediaQueryData.size;
    double width = size.width;
    if(width>768){
      return desktopUi(context);
    }
    else{
      return mobileUi(context);
    }
  }

  Widget desktopUi(context){
    return WebSchoolLayout(content: scrollView());
  }

  Widget mobileUi(context){
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
            style: TextStyle(fontFamily: "Jalnan", fontSize: 15),
          ),
          SizedBox(
            height: 20,
          ),
          Text(
              "여름방학 / 겨울방학 기간 2주 코스"),
          SizedBox(
            height: 20,
          ),
          Text(
            "대상",
            style: TextStyle(fontFamily: "Jalnan", fontSize: 15),
          ),
          SizedBox(
            height: 20,
          ),
          Text(
              "뉴질랜드 현지 단기 어학연수 코스를 경험하고 싶은 본원 유치부, 초등부 학생과 학부모"),

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
            child:
            Column(
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
                      style: TextStyle(
                          fontFamily: "Jalnan", color: Palette.white),
                    ),
                    onPressed: () {MenuUtil.push(context, SchoolConsultationPage());},
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
