import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gi_english_website/pages/SchoolConsultationPage.dart';
import 'package:gi_english_website/pages/SchoolCurriculumKindyPage.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/WidgetUtil.dart';
import 'package:gi_english_website/widget/ButtonState.dart';
import 'package:gi_english_website/widget/MobileSchoolLayout.dart';
import 'package:gi_english_website/widget/WebSchoolLayout.dart';

class SchoolCurriculumElePage extends StatefulWidget {
  const SchoolCurriculumElePage({Key? key}) : super(key: key);

  @override
  _SchoolCurriculumElePageState createState() => _SchoolCurriculumElePageState();
}

class _SchoolCurriculumElePageState extends State<SchoolCurriculumElePage> {

  List<ButtonState> buttonStateList = [
    ButtonState("정규유치부", BehaviorColor.colorOnDefault, SchoolCurriculumKindyPage()),
    ButtonState("정규초등부", BehaviorColor.colorOnClick, SchoolCurriculumElePage()),
  ];

  @override
  Widget build(BuildContext context) {

    MediaQueryData mediaQueryData = MediaQuery.of(context);
    Size size = mediaQueryData.size;
    double width = size.width;
    if(width>768){
      return WebSchoolLayout(content: scrollView());
    }
    else{
      return MobileSchoolLayout(content:mobileScrollView());
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
          buttonState.color =
          value ? BehaviorColor.colorOnHover : (i == 1 ? BehaviorColor.colorOnClick : BehaviorColor.colorOnDefault);
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        width: MediaQuery.of(context).size.width,
        alignment: Alignment.topLeft,
        padding: EdgeInsets.all(20),
        color: Palette.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "정규 초등부 Curriculum",
              style: TextStyle(fontFamily: "Jalnan", fontSize: 20,),
            ),
            WidgetUtil.myDivider(),
            SizedBox(
              height: 20),
            Text(
              "월수금반",
              style: TextStyle(fontFamily: "Jalnan", fontSize: 15,),
            ),
            SizedBox(
              height: 20),
            Container(width:600, child: Image.asset("assets/eleTimetableMWF.png")),
            SizedBox(
                height: 20),

            Text(
              "화목반",
              style: TextStyle(fontFamily: "Jalnan", fontSize: 15,),
            ),
            SizedBox(
                height: 20),
            Container(width:600, child: Image.asset("assets/eleTimetableTuesThurs.png")),
            SizedBox(
                height: 40),
            Text(
              "NIE 영자신문 수업",
              style: TextStyle(fontFamily: "Jalnan", fontSize: 20),
            ),
            WidgetUtil.myDivider(),
            SizedBox(height: 5),
            Container(width:600,
                margin: EdgeInsets.only(top:10,bottom: 10,left: 30, right: 30),
                child: Image.asset("assets/nieAd2.png")),
            Container(
              width: 600,
              margin: EdgeInsets.only(top:10,bottom: 10,left: 30, right:30),
              child: Text(style: TextStyle(
                  color: Palette.black,
                  fontFamily: "MaruBuri",
                  fontWeight: FontWeight.normal,
                  fontSize: 14),
                  "킨더 타임즈, 키즈 타임즈, 주니어 타임즈 등 아이들의 레벨과 연령에 맞추어 다양한 영자신문을 제공하는 어린이 영자 신문 전문 브랜드로, "
                      "글림아일랜드는 유치부 NIE Speaking 수업과 초등부 NIE Debate 수업을 위하여"
                      "모든 레벨의 어린이 영자신문을 class material 로 적극 활용합니다."),
            ),
            WidgetUtil.myDivider(),
            SizedBox(height: 10),
            Image.asset("assets/nieAd.png"),


          ],
        ),
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
          Image.asset("assets/curriculumImage.png"),
          Container(
            padding: EdgeInsets.only(left: 40, bottom: 20),
            child:
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "Curriculum",
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
      alignment: Alignment.center,
      width: MediaQuery.of(context).size.width,
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
          Image.asset("assets/curriculumImage.png"),
          Container(
            padding: EdgeInsets.only(left: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Curriculum",
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Palette.black,
                      foregroundColor: Palette.black,
                    ),
                    onPressed: () {},
                    child: Text("상담신청",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: "Oneprettynight",
                            color: Palette.white,
                            fontSize: 14)),
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
