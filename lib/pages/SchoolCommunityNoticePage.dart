import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gi_english_website/pages/SchoolConsultationPage.dart';
import 'package:gi_english_website/pages/SchoolGalleryPage.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/widget/ButtonState.dart';
import 'package:gi_english_website/widget/MobileSchoolLayout.dart';
import 'package:gi_english_website/widget/WebSchoolLayout.dart';

import '../util/WidgetUtil.dart';

class SchoolCommunityNoticePage extends StatefulWidget {
  const SchoolCommunityNoticePage({Key? key}) : super(key: key);

  @override
  _SchoolCommunityNoticePageState createState() => _SchoolCommunityNoticePageState();
}

class _SchoolCommunityNoticePageState extends State<SchoolCommunityNoticePage> {

  List<ButtonState> buttonStateList = [
    // ButtonState("Notice Board", BehaviorColor.colorOnClick, SchoolCommunityNoticePage()),
    ButtonState("Gallery", BehaviorColor.colorOnDefault, SchoolGalleryPage()),
    ButtonState("입학상담", BehaviorColor.colorOnDefault, SchoolConsultationPage()),
  ];

  List<NoticeBoardEntry> noticeBoardEntryList = [
    NoticeBoardEntry("3","2023 글림아일랜드 유,초등부 원생 대모집! 1~2월 중 수시, 상담문의 전화는 곧 공개됩니다.",  BehaviorColor.colorOnDefault),
    NoticeBoardEntry("2","글림아일랜드 어학원 ", BehaviorColor.colorOnDefault),
    NoticeBoardEntry("1","2023 글림아일랜드 유,초등부 원생 대모집!", BehaviorColor.colorOnDefault),
    NoticeBoardEntry("", "", BehaviorColor.colorOnDefault),
    NoticeBoardEntry("", "", BehaviorColor.colorOnDefault),
    NoticeBoardEntry("", "", BehaviorColor.colorOnDefault),
    NoticeBoardEntry("", "", BehaviorColor.colorOnDefault),
    NoticeBoardEntry("", "", BehaviorColor.colorOnDefault),
    NoticeBoardEntry("", "", BehaviorColor.colorOnDefault),
    NoticeBoardEntry("", "", BehaviorColor.colorOnDefault),
    NoticeBoardEntry("", "", BehaviorColor.colorOnDefault),
    NoticeBoardEntry("", "", BehaviorColor.colorOnDefault),
    NoticeBoardEntry("", "", BehaviorColor.colorOnDefault),
    NoticeBoardEntry("", "", BehaviorColor.colorOnDefault),
    NoticeBoardEntry("", "", BehaviorColor.colorOnDefault),
    NoticeBoardEntry("", "", BehaviorColor.colorOnDefault),
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
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.all(20),
      color: Palette.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Notice Board",
            style: TextStyle(fontFamily: "Jalnan", fontSize: 20),
          ),
          WidgetUtil.myDivider(),
          SizedBox(height: 20,),
          bulletinBoard()
        ],
      ),
    );
  }

  Widget bulletinBoard(){

    List<Widget> children = [];
    for (int i = 0; i < noticeBoardEntryList.length; i++) {
      NoticeBoardEntry noticeBoardEntry = noticeBoardEntryList[i];

      bool isFirst = (i == 0);
      bool isLast = (i == noticeBoardEntryList.length - 1);

      Widget child;
      if (isFirst) {
        child = MyWidget.boardEntryTop(noticeBoardEntry.color,noticeBoardEntry.entryNumber,noticeBoardEntry.title);
      } else if (isLast) {
        //last
        child = MyWidget.boardEntryBottom(noticeBoardEntry.color,noticeBoardEntry.entryNumber,noticeBoardEntry.title);
      } else {
        child = MyWidget.boardEntryMiddle(noticeBoardEntry.color,noticeBoardEntry.entryNumber,noticeBoardEntry.title);
      }

      children.add(InkWell(
        child: child,
        onHover: (value) {
          noticeBoardEntry.color = value
              ? BehaviorColor.colorOnHover
              : (i == 0
              ? BehaviorColor.colorOnDefault
              : BehaviorColor.colorOnDefault);
          setState(() {});
        },
        onTap: (){}
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
          Image.asset("assets/communityMainImage.png"),
          Container(
            padding: EdgeInsets.only(left: 40, bottom: 20),
            child:
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "Community",
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
          Image.asset("assets/communityMainImage.png"),
          Container(
            padding: EdgeInsets.only(left: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Community",
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
