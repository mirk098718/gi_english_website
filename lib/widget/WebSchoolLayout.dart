
import 'package:flutter/material.dart';
import 'package:gi_english_website/MainGatePage.dart';
import 'package:gi_english_website/appBarExample/OnHover.dart';
import 'package:gi_english_website/pages/School1on1Page.dart';
import 'package:gi_english_website/pages/SchoolAboutPage.dart';
import 'package:gi_english_website/pages/SchoolAllDayPage.dart';
import 'package:gi_english_website/pages/SchoolCampPage.dart';
import 'package:gi_english_website/pages/SchoolCommunityFAQPage.dart';
import 'package:gi_english_website/pages/SchoolCommunityNoticePage.dart';
import 'package:gi_english_website/pages/SchoolConsultationPage.dart';
import 'package:gi_english_website/pages/SchoolCurriculumElePage.dart';
import 'package:gi_english_website/pages/SchoolCurriculumKindyPage.dart';
import 'package:gi_english_website/pages/SchoolGalleryPage.dart';
import 'package:gi_english_website/pages/SchoolMapPage.dart';
import 'package:gi_english_website/pages/SchoolNZPage.dart';
import 'package:gi_english_website/pages/SchoolProgramPage.dart';
import 'package:gi_english_website/pages/SchoolSystemPage.dart';
import 'package:gi_english_website/pages/SchoolTeachersPage.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/Palette.dart';


class WebSchoolLayout extends StatefulWidget {
  Widget content;
  final double height = 51;

  WebSchoolLayout({Key? key, required this.content}) : super(key: key);

  @override
  _WebSchoolLayoutState createState() => _WebSchoolLayoutState();
}

class _WebSchoolLayoutState extends State<WebSchoolLayout> {
  final idController = TextEditingController();
  final pwController = TextEditingController();

  bool menu1Transparent = true;
  bool menu2Transparent = true;
  bool menu3Transparent = true;
  bool menu4Transparent = true;
  bool menu5Transparent = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
              top: 51, bottom: 0, left: 0, right: 0, child: widget.content),
          Positioned(top: 0, left: 0, right: 0, child: appBar(context)),
        ],
      ),
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

  Widget menu1Column() {
    return Opacity(
      opacity: menu1Transparent ? 0 : 1,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          InkWell(
            onTap: (){MenuUtil.push(context, SchoolAboutPage());},
            child: labelInColorContainer(Palette.violet, "Gi??????????????????"),),
         InkWell(
           onTap: (){MenuUtil.push(context, SchoolTeachersPage());},
            child: labelInColorContainer(Palette.mediumViolet, "????????????"),
         ),
          InkWell(
            onTap: (){MenuUtil.push(context, SchoolSystemPage());},
            child: labelInColorContainer(Palette.violet, "??????System"),),
          InkWell(
            onTap: (){MenuUtil.push(context, SchoolMapPage());},
            child: labelInColorContainer(Palette.mediumViolet, "????????? ???"),)
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
            onTap: (){MenuUtil.push(context, SchoolProgramPage());},
            child: labelInColorContainer(Palette.violet, "??????????????????"),),
          InkWell(
            onTap: (){MenuUtil.push(context, SchoolAllDayPage());},
            child: labelInColorContainer(Palette.mediumViolet, "???????????????"),
          ),
          InkWell(
            onTap: (){MenuUtil.push(context, SchoolCampPage());},
            child: labelInColorContainer(Palette.violet, "????????????"),),
          InkWell(
            onTap: (){MenuUtil.push(context, SchoolNZPage());},
            child: labelInColorContainer(Palette.mediumViolet, "NZ??????????????????"),),
          InkWell(
            onTap: (){MenuUtil.push(context, School1on1Page());},
            child: labelInColorContainer(Palette.mediumViolet, "1ON1????????????"),)
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
            onTap: (){MenuUtil.push(context, SchoolCurriculumKindyPage());},
            child: labelInColorContainer(Palette.violet, "?????? ?????????"),),
          InkWell(
            onTap: (){MenuUtil.push(context, SchoolCurriculumElePage());},
            child: labelInColorContainer(Palette.mediumViolet, "?????? ?????????"),
          ),
        ],
      ),
    );
  }

  Widget menu4Column() {

    return Opacity(
      opacity: menu4Transparent ? 0 : 1,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          InkWell(
            onTap: (){MenuUtil.push(context, SchoolCommunityNoticePage());},
            child: labelInColorContainer(Palette.violet, "Notice Board"),),
          InkWell(
            onTap: (){MenuUtil.push(context, SchoolGalleryPage());},
            child: labelInColorContainer(Palette.mediumViolet, "Gallery"),
          ),
          InkWell(
            onTap: (){MenuUtil.push(context, SchoolConsultationPage());},
            child: labelInColorContainer(Palette.violet, "????????????"),),
          InkWell(
            onTap: (){MenuUtil.push(context, SchoolCommunityFAQPage());},
            child: labelInColorContainer(Palette.mediumViolet, "FAQ"),)
        ],
      ),
    );
  }

  Widget appBar(BuildContext context) {
    return Stack(children: [
      Container(
        height: widget.height,
        padding: EdgeInsets.only(top: 5, bottom: 5, left: 10, right: 10),
        color: Palette.mainPurple,
      ),

      Container(
        color: Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: (){MenuUtil.push(context, SchoolAboutPage());},
              child: OnHover(
                builder: (isHovered) {
                  menu1Transparent = !isHovered;
                  return menuItem("About Gi?????????", menu1Column());
                },
              ),
            ),
            InkWell(
              onTap: (){MenuUtil.push(context, SchoolProgramPage());},
              child: OnHover(
                builder: (isHovered) {
                  menu2Transparent = !isHovered;
                  return menuItem("Program", menu2Column());
                },
              ),
            ),
            InkWell(
              onTap: (){MenuUtil.push(context, SchoolCurriculumKindyPage());},
              child: OnHover(
                builder: (isHovered) {
                  menu3Transparent = !isHovered;
                  return menuItem("Curriculum", menu3Column());
                },
              ),
            ),
            InkWell(
              onTap: (){MenuUtil.push(context, SchoolCommunityNoticePage());},
              child: OnHover(
                builder: (isHovered) {
                  menu4Transparent = !isHovered;
                  return menuItem("Community", menu4Column());
                },
              ),
            ),
            SizedBox(width: 40)
          ],
        ),
      ),
      Container(
        padding: EdgeInsets.only(top: 4, left: 10),
        width: 300,
        alignment: Alignment.topLeft,
        child:
            InkWell(
              child: Container(height: 40,child: Image.asset("assets/schoolLogo.png")),
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
                        title: Text("?????????", textAlign: TextAlign.center,),
                        content: Container(
                          width: 280,
                          height: 240,
                          child: Column(
                            children: [
                              Divider(),
                              SizedBox(height: 10),
                              Expanded(
                                child: MyWidget.roundEdgeTextField(
                                    "ID??? ??????????????????", idController),
                              ),
                              Expanded(
                                child: MyWidget.roundEdgeTextField(
                                    "Password??? ??????????????????", pwController),
                              ),
                              SizedBox(height: 10),
                              Container(
                                width: 150,
                                height: 50,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    primary: Palette.mainMediumPurple,
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

}
