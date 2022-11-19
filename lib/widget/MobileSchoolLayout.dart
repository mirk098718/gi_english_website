
import 'package:flutter/material.dart';
import 'package:gi_english_website/pages/SchoolAboutPage.dart';
import 'package:gi_english_website/pages/SchoolCommunityNoticePage.dart';
import 'package:gi_english_website/pages/SchoolCurriculumElePage.dart';
import 'package:gi_english_website/pages/SchoolMainPage.dart';
import 'package:gi_english_website/pages/SchoolProgramPage.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/Palette.dart';


class MobileSchoolLayout extends StatefulWidget {
  Widget content;
  final double height = 52;

  MobileSchoolLayout({Key? key, required this.content}) : super(key: key);

  @override
  _MobileSchoolLayoutState createState() => _MobileSchoolLayoutState();
}

class _MobileSchoolLayoutState extends State<MobileSchoolLayout> {
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
        color: Palette.deepGreen,
      ),
      Container(
        padding: EdgeInsets.only(top: 10),
        width: double.maxFinite,
        alignment: Alignment.topCenter,
        child:
            InkWell(
              child: Container(height: 40,child: Image.asset("assets/giEmblem.png")),
              onTap: () {
                MenuUtil.push(context, SchoolMainPage());
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
        color: Palette.deepGreen,
      ),
      SizedBox(width: 30,),
      Container(
        color: Colors.transparent,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // InkWell(
              //   child:
              //   Container(
              //       margin: EdgeInsets.only(left: 10, top: 10, bottom: 5),
              //       width:30, height: 30, child: Image.asset("assets/mobileLoginButton.png")),
              //   onTap: () {
              //     showDialog(
              //         context: context,
              //         builder: (context) {
              //           return AlertDialog(
              //               title: Text("로그인", textAlign: TextAlign.center,),
              //               content: Container(
              //                 width: 280,
              //                 height: 240,
              //                 child: Column(
              //                   children: [
              //                     Divider(),
              //                     SizedBox(height: 10),
              //                     Expanded(
              //                       child: MyWidget.roundEdgeTextField(
              //                           "ID를 입력해주세요", idController),
              //                     ),
              //                     Expanded(
              //                       child: MyWidget.roundEdgeTextField(
              //                           "Password를 입력해주세요", pwController),
              //                     ),
              //                     SizedBox(height: 10),
              //                     Container(
              //                       width: 150,
              //                       height: 50,
              //                       child: ElevatedButton(
              //                         style: ElevatedButton.styleFrom(
              //                           primary: Palette.mainMediumPurple,
              //                           onPrimary: Palette.black,),
              //                         onPressed: () {},
              //                         child: Text("Login", style: TextStyle(fontFamily: "Jalnan"),),
              //                       ),
              //                     )
              //                   ],
              //                 ),
              //               ));
              //         });
              //   },
              // ),
              SizedBox(width: 30),
              InkWell(
                onTap: (){MenuUtil.push(context, SchoolAboutPage());},
                child: Container(
                    height: widget.height,
                    alignment: Alignment.center,
                    child: Text("About GI",style: TextStyle(color: Palette.white,
                        fontFamily: "Jalnan",
                        fontSize: 13),),),),
              SizedBox(width: 30),
              InkWell(
                  onTap: (){MenuUtil.push(context, SchoolProgramPage());},
                  child:
                  Container(
                    height: widget.height,
                    alignment: Alignment.center,
                    child: Text("Program",style: TextStyle(color: Palette.white,
                        fontFamily: "Jalnan",
                        fontWeight: FontWeight.bold,
                        fontSize: 13),),),),
              SizedBox(width: 30),
              InkWell(
                onTap: (){MenuUtil.push(context, SchoolCurriculumElePage());},
                child:
                   Container(
                       height: widget.height,
                       alignment: Alignment.center,
                       child: Text("Curriculum",style: TextStyle(color: Palette.white,
                           fontFamily: "Jalnan",
                           fontWeight: FontWeight.bold,
                           fontSize: 13),)),),
              SizedBox(width: 30),
              InkWell(
                  onTap: (){MenuUtil.push(context, SchoolCommunityNoticePage());},
                  child:
                  Container(
                      height: widget.height,
                      alignment: Alignment.center,
                      child: Text("Community",style: TextStyle(color: Palette.white,
                          fontFamily: "Jalnan",
                          fontWeight: FontWeight.bold,
                          fontSize: 13),)),),
              SizedBox(width: 30),
            ],
          ),
        ),
      ),
    ],
    );
  }

}
