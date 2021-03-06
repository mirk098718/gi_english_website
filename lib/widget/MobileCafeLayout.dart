
import 'package:flutter/material.dart';
import 'package:gi_english_website/MainGatePage.dart';
import 'package:gi_english_website/appBarExample/OnHover.dart';
import 'package:gi_english_website/cafePages/CafeAboutPage.dart';
import 'package:gi_english_website/cafePages/CafeCommunityNoticePage.dart';
import 'package:gi_english_website/cafePages/CafeProgramPage.dart';
import 'package:gi_english_website/cafePages/CafeReservationPage.dart';
import 'package:gi_english_website/pages/SchoolAboutPage.dart';
import 'package:gi_english_website/pages/SchoolCommunityNoticePage.dart';
import 'package:gi_english_website/pages/SchoolConsultationPage.dart';
import 'package:gi_english_website/pages/SchoolCurriculumElePage.dart';
import 'package:gi_english_website/pages/SchoolGalleryPage.dart';
import 'package:gi_english_website/pages/SchoolProgramPage.dart';
import 'package:gi_english_website/pages/schoolTeachersPage.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/Palette.dart';


class MobileCafeLayout extends StatefulWidget {
  Widget content;
  final double height = 52;

  MobileCafeLayout({Key? key, required this.content}) : super(key: key);

  @override
  _MobileCafeLayoutState createState() => _MobileCafeLayoutState();
}

class _MobileCafeLayoutState extends State<MobileCafeLayout> {
  final idController = TextEditingController();
  final pwController = TextEditingController();

  @override

  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(top: 102, bottom: 0, left: 0, right: 0, child: widget.content),
          Positioned(top: 51, left: 0, right: 0, child: appBar2(context)),
          Positioned(top: 0, left: 0, right: 0, child: appBar1(context))

        ],
      ),
    );
  }

  Widget appBar1(BuildContext context) {
    return Stack(children: [
      Container(
        height: widget.height,
        color: Palette.mainLime,
      ),
      Container(
        padding: EdgeInsets.only(top: 10),
        width: double.maxFinite,
        alignment: Alignment.topCenter,
        child:
        InkWell(
          child: Container(height: 40,child: Image.asset("assets/giEmblem.png")),
          onTap: () {
            MenuUtil.push(context, MainGatePage());
          },
        ),
      ),

    ],
    );
  }

  Widget appBar2(BuildContext context) {
    return Stack(children: [
      Container(
        height: widget.height,
        padding: EdgeInsets.only(left: 5, right: 5),
        color: Palette.mainLime,
      ),
      Container(
        color: Colors.transparent,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                child: Container(
                    margin: EdgeInsets.only(left: 10, top: 10, bottom: 5),
                    width:30, height: 30, child: Image.asset("assets/loginButton.png")),
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
              SizedBox(width: 30),
              InkWell(
                onTap: (){MenuUtil.push(context, CafeAboutPage());},
                child: Container(
                  height: widget.height,
                  alignment: Alignment.center,
                  child: Text("Gi????????????",style: TextStyle(color: Palette.white, fontWeight: FontWeight.bold),),),),
              SizedBox(width: 30),
              InkWell(
                onTap: (){MenuUtil.push(context, CafeProgramPage());},
                child:
                Container(
                  height: widget.height,
                  alignment: Alignment.center,
                  child: Text("Program",style: TextStyle(color: Palette.white, fontWeight: FontWeight.bold),),),),
              SizedBox(width: 30),
              InkWell(
                onTap: (){MenuUtil.push(context, CafeCommunityNoticePage());},
                child:
                Container(
                    height: widget.height,
                    alignment: Alignment.center,
                    child: Text("Community",style: TextStyle(color: Palette.white, fontWeight: FontWeight.bold),)),),
              SizedBox(width: 30),
              InkWell(
                onTap: (){MenuUtil.push(context, CafeReservationPage());},
                child:
                Container(
                    height: widget.height,
                    alignment: Alignment.center,
                    child: Text("????????????",style: TextStyle(color: Palette.white, fontWeight: FontWeight.bold),)),),
              SizedBox(width: 30),
            ],
          ),
        ),
      ),
    ],
    );
  }

}
