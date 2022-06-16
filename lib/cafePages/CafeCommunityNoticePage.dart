import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gi_english_website/cafePages/CafeAboutPage.dart';
import 'package:gi_english_website/cafePages/CafeGalleryPage.dart';
import 'package:gi_english_website/cafePages/CafeReservationPage.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/widget/ButtonState.dart';
import 'package:gi_english_website/widget/MobileCafeLayout.dart';
import 'package:gi_english_website/widget/WebCafeLayout.dart';

class CafeCommunityNoticePage extends StatefulWidget {
  const CafeCommunityNoticePage({Key? key}) : super(key: key);

  @override
  _SchoolAboutPageState createState() => _SchoolAboutPageState();
}

class _SchoolAboutPageState extends State<CafeCommunityNoticePage> {

  List<ButtonState> buttonStateList = [
    ButtonState("Notice Board", BehaviorColor.colorOnClick, CafeCommunityNoticePage()),
    ButtonState("Gallery", BehaviorColor.colorOnDefault, CafeGalleryPage()),

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
    return WebCafeLayout( content: scrollView());
  }

  Widget mobileUi(context){
    return MobileCafeLayout(content: mobileScrollView());
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
          Divider(),
          SizedBox(height: 20,),
          Container(width: 600,height: 600, child: Text("게시판 필요"),)
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
            // mobileMainImage(),
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
