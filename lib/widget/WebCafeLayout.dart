import 'package:flutter/material.dart';
import 'package:gi_english_website/MainGatePage.dart';
import 'package:gi_english_website/appBarExample/OnHover.dart';
import 'package:gi_english_website/cafePages/CafeAboutPage.dart';
import 'package:gi_english_website/cafePages/CafeCommunityNoticePage.dart';
import 'package:gi_english_website/cafePages/CafeGalleryPage.dart';
import 'package:gi_english_website/cafePages/CafeMapPage.dart';
import 'package:gi_english_website/cafePages/CafeProgramArtPage.dart';
import 'package:gi_english_website/cafePages/CafeProgramPage.dart';
import 'package:gi_english_website/cafePages/CafeProgramPhysicalPage.dart';
import 'package:gi_english_website/cafePages/CafeProgramVisualContentsPage.dart';
import 'package:gi_english_website/cafePages/CafeReservationPage.dart';
import 'package:gi_english_website/cafePages/CafeStaffPage.dart';
import 'package:gi_english_website/cafePages/CafeSystemPage.dart';
import 'package:gi_english_website/pages/SchoolAboutPage.dart';
import 'package:gi_english_website/pages/SchoolCommunityNoticePage.dart';
import 'package:gi_english_website/pages/SchoolConsultationPage.dart';
import 'package:gi_english_website/pages/SchoolMainPage.dart';
import 'package:gi_english_website/pages/SchoolProgramPage.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/widget/AppbarDropdown.dart';

class WebCafeLayout extends StatefulWidget {

  Widget content;
  final double height = 51;

  WebCafeLayout({Key? key, required this.content}) : super(key: key);

  @override
  _WebCafeLayoutState createState() => _WebCafeLayoutState();
}

class _WebCafeLayoutState extends State<WebCafeLayout> {

  final idController = TextEditingController();
  final pwController = TextEditingController();

  bool menu1Transparent = true;
  bool menu2Transparent = true;
  bool menu3Transparent = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
              top: 51, bottom: 0, left: 0, right: 0, child: widget.content),
          Positioned(top: 0, left: 0, right: 0, child: cafeAppBar(context)),
        ],
      ),
    );
  }

  Widget cafeAppBar(BuildContext context) {
    return Stack(children: [
      Container(
        height: widget.height,
        padding: EdgeInsets.only(top: 5, bottom: 5, left: 10, right: 10),
        color: Palette.mainLime,
      ),
      Container(
        color: Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: (){MenuUtil.push(context, CafeAboutPage());},
              child: OnHover(
                builder: (isHovered) {
                  menu1Transparent = !isHovered;
                  return menuItem("Gi영어키즈카페", menu1Column());
                },
              ),
            ),
            InkWell(
              onTap: (){MenuUtil.push(context, CafeProgramPage());},
              child: OnHover(
                builder: (isHovered) {
                  menu2Transparent = !isHovered;
                  return menuItem("Program", menu2Column());
                },
              ),
            ),

            InkWell(
              onTap: (){MenuUtil.push(context, CafeCommunityNoticePage());},
              child: OnHover(
                builder: (isHovered) {
                  menu3Transparent = !isHovered;
                  return menuItem("Community", menu3Column());
                },
              ),
            ),

            InkWell(
              onTap: (){MenuUtil.push(context, CafeReservationPage());},
              child: OnHover(
                builder: (isHovered) {
                  menu3Transparent = !isHovered;
                  return InkWell(child: menuItem("예약문의", menuColumn()),
                  onTap: (){MenuUtil.push(context, CafeReservationPage());},);
                },
              ),
            ),
            SizedBox(width: 40)
          ],
        ),
      ),
      Container(
        padding: EdgeInsets.only(top: 3, left: 10),
        width: 300,
        alignment: Alignment.topLeft,
        child:
        InkWell(
          child: Container(height:40, child: Image.asset("assets/cafeLogo.png")),
          onTap: () {
            MenuUtil.pop(context);
          },
        ),
      ),
      Positioned(
        right:5, top: 5,
        child: Container(
          alignment: Alignment.topRight,
          padding: EdgeInsets.all(5),
          child:InkWell(
            child: Container(width:30, height: 30, child: Image.asset("assets/loginButton.png")),
            onTap: () {
              showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                        title: Text("로그인", textAlign: TextAlign.center,),
                        content: Container(
                          width: 280,
                          height: 240,
                          child: Column(
                            children: [
                              Divider(),
                              SizedBox(height: 10),
                              Expanded(
                                child: MyWidget.roundEdgeTextField(
                                    "ID를 입력해주세요", idController),
                              ),
                              Expanded(
                                child: MyWidget.roundEdgeTextField(
                                    "Password를 입력해주세요", pwController),
                              ),
                              SizedBox(height: 10),
                              Container(
                                width: 150,
                                height: 50,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    primary: Palette.mainLime,
                                    onPrimary: Palette.black,),
                                  onPressed: () {},
                                  child: Text("Login", style: TextStyle(fontFamily: "Jalnan"),),
                                ),
                              )
                            ],
                          ),
                        ));
                  });
            },
          ),
        ),
      ),
    ],
    );
  }

  Widget menuItem(String menuStr, Widget menuColumn) {
    return Column(
      children: [
        Container(
            height: widget.height,
            alignment: Alignment.center,
            child: Text(menuStr,style: TextStyle(color: Palette.white, fontWeight: FontWeight.bold),)),
        menuColumn
      ],
    );
  }

  labelInColorContainer(Color selectedColor, String label) {
    return Container(
      alignment: Alignment.center,
      color: selectedColor,
      width: 140,
      height: 35,
      child: Text(label, style: TextStyle(color: Palette.white)),
    );
  }

  Widget menuColumn() {
    return Opacity(
      opacity: menu1Transparent ? 0 : 1,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          InkWell(
            onTap: (){},
            child: labelInColorContainer(Colors.transparent, ""),),
        ],
      ),
    );
  }

  Widget menu1Column() {
    return Opacity(
      opacity: menu1Transparent ? 0 : 1,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          InkWell(
            onTap: (){MenuUtil.push(context, CafeAboutPage());},
            child: labelInColorContainer(Palette.greenishLime, "Gi글림아일랜드"),),
          InkWell(
            onTap: (){MenuUtil.push(context, CafeStaffPage());},
            child: labelInColorContainer(Palette.darkerGreenishLime, "교원소개"),
          ),
          InkWell(
            onTap: (){MenuUtil.push(context, CafeSystemPage());},
            child: labelInColorContainer(Palette.greenishLime, "운영System"),),
          InkWell(
            onTap: (){MenuUtil.push(context, CafeMapPage());},
            child: labelInColorContainer(Palette.darkerGreenishLime, "오시는 길"),)
        ],
      ),
    );
  }

  Widget menu2Column() {
    return Opacity(
      opacity: menu2Transparent ? 0 : 1,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          InkWell(
            onTap: (){MenuUtil.push(context, CafeProgramPage());},
            child: labelInColorContainer(Palette.greenishLime, "Storytelling"),),
          InkWell(
            onTap: (){MenuUtil.push(context, CafeProgramArtPage());},
            child: labelInColorContainer(Palette.darkerGreenishLime, "Creative Art"),
          ),
          InkWell(
            onTap: (){MenuUtil.push(context, CafeProgramVisualContentsPage());},
            child: labelInColorContainer(Palette.greenishLime, "Visual Contents"),),
          InkWell(
            onTap: ()=>MenuUtil.push(context, CafeProgramPhysicalPage()),
            child: labelInColorContainer(Palette.darkerGreenishLime, "Physical Activities"),),

        ],
      ),
    );
  }

  Widget menu3Column() {

    return Opacity(
      opacity: menu3Transparent ? 0 : 1,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          InkWell(
            onTap: (){MenuUtil.push(context, CafeCommunityNoticePage());},
            child: labelInColorContainer(Palette.greenishLime, "Notice Board"),),
          InkWell(
            onTap: (){MenuUtil.push(context, CafeGalleryPage());},
            child: labelInColorContainer(Palette.darkerGreenishLime, "Gallery"),
          ),
        ],
      ),
    );
  }

}
