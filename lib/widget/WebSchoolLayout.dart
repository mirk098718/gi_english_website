import 'package:flutter/material.dart';
import 'package:gi_english_website/pages/School1on1Page.dart';
import 'package:gi_english_website/pages/SchoolAboutPage.dart';
import 'package:gi_english_website/pages/SchoolAllDayPage.dart';
import 'package:gi_english_website/pages/SchoolCampPage.dart';
import 'package:gi_english_website/pages/SchoolCommunityFAQPage.dart';
import 'package:gi_english_website/pages/SchoolCommunityNoticePage.dart';
import 'package:gi_english_website/pages/SchoolConsultationPage.dart';
import 'package:gi_english_website/pages/SchoolCurriculumElePage.dart';
import 'package:gi_english_website/pages/SchoolCurriculumMiddleSchoolPage.dart';
import 'package:gi_english_website/pages/SchoolGalleryPage.dart';
import 'package:gi_english_website/pages/SchoolMainPage.dart';
import 'package:gi_english_website/pages/SchoolMapPage.dart';
import 'package:gi_english_website/pages/SchoolNZPage.dart';
import 'package:gi_english_website/pages/SchoolProgramPage.dart';
import 'package:gi_english_website/pages/SchoolSystemPage.dart';
import 'package:gi_english_website/pages/SchoolTeachersPage.dart';
import 'package:gi_english_website/pages/WorkingAdminLoginPage.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/AuthService.dart';

class WebSchoolLayout extends StatefulWidget {
  final Widget content;
  final double height = 51;

  WebSchoolLayout({Key? key, required this.content}) : super(key: key);

  @override
  _WebSchoolLayoutState createState() => _WebSchoolLayoutState();
}

class _WebSchoolLayoutState extends State<WebSchoolLayout> {
  final idController = TextEditingController();
  final pwController = TextEditingController();
  bool _isAdmin = false;

  bool menu1Transparent = true;
  bool menu2Transparent = true;
  bool menu3Transparent = true;
  bool menu4Transparent = true;
  bool menu5Transparent = true;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    bool isAdmin = await AuthService.isAdmin();
    if (mounted) {
      setState(() {
        _isAdmin = isAdmin;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
              top: 80, bottom: 0, left: 0, right: 0, child: widget.content),
          Positioned(top: 0, left: 0, right: 0, child: appBar(context)),
        ],
      ),
    );
  }

  void _showAdminLoginDialog(BuildContext context) {
    print('🔧 WebSchoolLayout: 관리자 로그인 다이얼로그 호출됨');
    // WorkingAdminLoginPage로 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkingAdminLoginPage(category: 'general'),
      ),
    ).then((_) {
      // 로그인 후 돌아왔을 때 관리자 상태 다시 확인
      _checkAdminStatus();
    });
  }

  Future<void> _logout() async {
    try {
      await AuthService.signOut();
      setState(() {
        _isAdmin = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('로그아웃되었습니다.', style: TextStyle(fontFamily: "NotoSansKR")),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('로그아웃 중 오류가 발생했습니다.',
              style: TextStyle(fontFamily: "NotoSansKR")),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget menuItem(String menuStr, Widget menuColumn) {
    return Column(
      children: [
        Container(
            height: widget.height,
            alignment: Alignment.center,
            child: Text(
              menuStr,
              style:
                  TextStyle(color: Palette.white, fontWeight: FontWeight.bold),
            )),
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
            onTap: () {
              MenuUtil.push(context, SchoolAboutPage());
            },
            child: labelInColorContainer(Palette.accent, "Gi글림아일랜드"),
          ),
          InkWell(
            onTap: () {
              MenuUtil.push(context, SchoolTeachersPage());
            },
            child: labelInColorContainer(Palette.accent, "교원소개"),
          ),
          InkWell(
            onTap: () {
              MenuUtil.push(context, SchoolSystemPage());
            },
            child: labelInColorContainer(Palette.accent, "운영System"),
          ),
          InkWell(
            onTap: () {
              MenuUtil.push(context, SchoolMapPage());
            },
            child: labelInColorContainer(Palette.accent, "오시는 길"),
          )
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
            onTap: () {
              MenuUtil.push(context, SchoolProgramPage());
            },
            child: labelInColorContainer(Palette.accent, "정규프로그램"),
          ),
          InkWell(
            onTap: () {
              MenuUtil.push(context, SchoolAllDayPage());
            },
            child: labelInColorContainer(Palette.accent, "올데이케어"),
          ),
          InkWell(
            onTap: () {
              MenuUtil.push(context, SchoolCampPage());
            },
            child: labelInColorContainer(Palette.accent, "방학캠프"),
          ),
          InkWell(
            onTap: () {
              MenuUtil.push(context, SchoolNZPage());
            },
            child: labelInColorContainer(Palette.accent, "뉴질랜드프로그램"),
          ),
          InkWell(
            onTap: () {
              MenuUtil.push(context, School1on1Page());
            },
            child: labelInColorContainer(Palette.accent, "1ON1프로그램"),
          )
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
            onTap: () {
              MenuUtil.push(context, SchoolCurriculumMiddleSchoolPage());
            },
            child: labelInColorContainer(Palette.accent, "정규 중등부"),
          ),
          InkWell(
            onTap: () {
              MenuUtil.push(context, SchoolCurriculumElePage());
            },
            child: labelInColorContainer(Palette.accent, "정규 초등부"),
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
            onTap: () {
              MenuUtil.push(context, SchoolCommunityNoticePage());
            },
            child: labelInColorContainer(Palette.accent, "Notice Board"),
          ),
          InkWell(
            onTap: () {
              MenuUtil.push(context, SchoolGalleryPage());
            },
            child: labelInColorContainer(Palette.accent, "Gallery"),
          ),
          InkWell(
            onTap: () {
              MenuUtil.push(context, SchoolConsultationPage());
            },
            child: labelInColorContainer(Palette.accent, "입학상담"),
          ),
          InkWell(
            onTap: () {
              MenuUtil.push(context, SchoolCommunityFAQPage());
            },
            child: labelInColorContainer(Palette.accent, "FAQ"),
          )
        ],
      ),
    );
  }

  Widget appBar(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 80,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Palette.secondaryDark, Color(0xFF022C22)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha:0.3),
                spreadRadius: 0,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),

        Container(
          color: Colors.transparent,
          padding: EdgeInsets.only(top: 25),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              InkWell(
                onTap: () {
                  MenuUtil.push(context, SchoolAboutPage());
                },
                child: Text(
                  "About",
                  style: TextStyle(
                      color: Colors.white,
                      fontFamily: "NotoSansKR",
                      fontWeight: FontWeight.bold,
                      fontSize: 20),
                ),
              ),
              Container(
                margin: EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
                width: 0.5,
                height: 10,
                color: Colors.white.withValues(alpha:0.3),
              ),
              InkWell(
                  onTap: () {
                    MenuUtil.push(context, SchoolProgramPage());
                  },
                  child: Text(
                    "Program",
                    style: TextStyle(
                        color: Colors.white,
                        fontFamily: "NotoSansKR",
                        fontWeight: FontWeight.bold,
                        fontSize: 20),
                  )),
              Container(
                margin: EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
                width: 0.5,
                height: 10,
                color: Colors.white.withValues(alpha:0.3),
              ),
              InkWell(
                  onTap: () {
                    MenuUtil.push(context, SchoolCurriculumElePage());
                  },
                  child: Text(
                    "Curriculum",
                    style: TextStyle(
                        color: Colors.white,
                        fontFamily: "NotoSansKR",
                        fontWeight: FontWeight.bold,
                        fontSize: 20),
                  )),
              Container(
                margin: EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
                width: 0.5,
                height: 10,
                color: Colors.white.withValues(alpha:0.3),
              ),
              InkWell(
                  onTap: () {
                    MenuUtil.push(context, SchoolGalleryPage());
                  },
                  child: Text(
                    "Community",
                    style: TextStyle(
                        color: Colors.white,
                        fontFamily: "NotoSansKR",
                        fontWeight: FontWeight.bold,
                        fontSize: 20),
                  )),
              SizedBox(width: 20),
              // 관리자 로그인/로그아웃 버튼
              if (!_isAdmin)
                InkWell(
                  onTap: () {
                    _showAdminLoginDialog(context);
                  },
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha:0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.admin_panel_settings,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              if (_isAdmin) ...[
                InkWell(
                  onTap: () {
                    _logout();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha:0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.logout,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          "로그아웃",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontFamily: "NotoSansKR",
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha:0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.admin_panel_settings,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        "관리자",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: "NotoSansKR",
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(width: 20),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.only(top: 15.5, bottom: 15.5, left: 15),
          width: 300,
          alignment: Alignment.centerLeft,
          child: InkWell(
            child: Container(
                height: 49, child: Image.asset("assets/giEmblem.png")),
            onTap: () {
              MenuUtil.push(context, SchoolMainPage());
            },
          ),
        ),
        // Positioned(
        //   right:5, top: 5,
        //   child: Container(
        //     alignment: Alignment.topRight,
        //     padding: EdgeInsets.only(top: 5, bottom: 5, right: 10),
        //     child:InkWell(
        //       child: Container(width:30, height: 30, child: Image.asset("assets/loginButton.png")),
        //       onTap: () {
        //         showDialog(
        //             context: context,
        //             builder: (context) {
        //               return AlertDialog(
        //                   title: Text("로그인", textAlign: TextAlign.center,),
        //                   content: Container(
        //                     width: 280,
        //                     height: 240,
        //                     child: Column(
        //                       children: [
        //                         Divider(),
        //                         SizedBox(height: 10),
        //                         Expanded(
        //                           child: MyWidget.roundEdgeTextField(
        //                               "ID를 입력해주세요", idController),
        //                         ),
        //                         Expanded(
        //                           child: MyWidget.roundEdgeTextField(
        //                               "Password를 입력해주세요", pwController),
        //                         ),
        //                         SizedBox(height: 10),
        //                         Container(
        //                           width: 150,
        //                           height: 50,
        //                           child: ElevatedButton(
        //                             style: ElevatedButton.styleFrom(
        //                               primary: Palette.accent,
        //                               onPrimary: Palette.black,),
        //                             onPressed: () {},
        //                             child: Text("Login", style: TextStyle(fontFamily: "Jalnan"),),
        //                           ),
        //                         )
        //                       ],
        //                     ),
        //                   ));
        //             });
        //       },
        //     ),
        //   ),
        // ),
      ],
    );
  }
}
