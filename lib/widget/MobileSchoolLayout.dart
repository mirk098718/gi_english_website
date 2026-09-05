import 'package:flutter/material.dart';
import 'package:gi_english_website/pages/SchoolAboutPage.dart';
import 'package:gi_english_website/pages/SchoolCurriculumElePage.dart';
import 'package:gi_english_website/pages/SchoolGalleryPage.dart';
import 'package:gi_english_website/pages/SchoolMainPage.dart';
import 'package:gi_english_website/pages/SchoolOnlineProgramPage.dart';
import 'package:gi_english_website/pages/SchoolProgramPage.dart';
import 'package:gi_english_website/pages/WorkingAdminLoginPage.dart';
import 'package:gi_english_website/pages/AdminOnlineHubPage.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/AuthService.dart';

class MobileSchoolLayout extends StatefulWidget {
  final Widget content;
  final double height = 52;

  MobileSchoolLayout({Key? key, required this.content}) : super(key: key);

  @override
  _MobileSchoolLayoutState createState() => _MobileSchoolLayoutState();
}

class _MobileSchoolLayoutState extends State<MobileSchoolLayout> {
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
    bool isStaff = await AuthService.isStaff();
    if (mounted) {
      setState(() {
        _isAdmin = isStaff;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 모바일에서 스크롤이 동작하려면 Stack에 명시적 높이가 필요함.
    // 자식이 모두 Positioned일 때 Stack이 0 높이로 줄어들어 스크롤 영역이 사라지는 문제 방지.
    final viewportHeight = MediaQuery.sizeOf(context).height;
    const topBarHeight = 111.0;

    return Scaffold(
      body: SizedBox(
        height: viewportHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: topBarHeight,
              bottom: 0,
              left: 0,
              right: 0,
              child: ClipRect(
                child: widget.content,
              ),
            ),
            Positioned(top: 60, left: 0, right: 0, child: appBar2(context)),
            Positioned(top: 0, left: 0, right: 0, child: appBar1(context)),
          ],
        ),
      ),
    );
  }

  void _showAdminLoginDialog(BuildContext context) {
    print('🔧 MobileSchoolLayout: 관리자 로그인 다이얼로그 호출됨');
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

  Widget appBar1(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Palette.secondaryDark, Color(0xFF022C22)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.3),
                spreadRadius: 0,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(vertical: 4),
          width: double.maxFinite,
          alignment: Alignment.center,
          child: InkWell(
            child: Container(
                height: 49, child: Image.asset("assets/giEmblem.png")),
            onTap: () {
              MenuUtil.push(context, SchoolMainPage());
            },
          ),
        ),
        // 관리자 로그인/로그아웃 버튼 (모바일)
        if (!_isAdmin)
          Positioned(
            top: 15,
            right: 15,
            child: InkWell(
              onTap: () {
                _showAdminLoginDialog(context);
              },
              child: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.admin_panel_settings,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        if (_isAdmin)
          Positioned(
            top: 15,
            right: 15,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () {
                    _logout();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.logout,
                          color: Colors.white,
                          size: 14,
                        ),
                        SizedBox(width: 2),
                        Text(
                          "로그아웃",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontFamily: "NotoSansKR",
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 6),
                InkWell(
                  onTap: () {
                    MenuUtil.push(context, AdminOnlineHubPage());
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.admin_panel_settings,
                          color: Colors.white,
                          size: 14,
                        ),
                        SizedBox(width: 2),
                        Text(
                          "관리자",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontFamily: "NotoSansKR",
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget appBar2(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.3),
                spreadRadius: 0,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 30,
        ),
        Container(
          color: Colors.transparent,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
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
                //                           primary: Palette.accent,
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
                SizedBox(width: 10),
                InkWell(
                  onTap: () {
                    MenuUtil.push(context, SchoolAboutPage());
                  },
                  child: Container(
                    height: widget.height,
                    alignment: Alignment.center,
                    child: Text(
                      "About GI",
                      style: TextStyle(
                          color: Colors.black,
                          fontFamily: "Jalnan",
                          fontSize: 14),
                    ),
                  ),
                ),
                SizedBox(width: 30),
                InkWell(
                  onTap: () {
                    MenuUtil.push(context, SchoolProgramPage());
                  },
                  child: Container(
                    height: widget.height,
                    alignment: Alignment.center,
                    child: Text(
                      "Program",
                      style: TextStyle(
                          color: Colors.black,
                          fontFamily: "Jalnan",
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                  ),
                ),
                SizedBox(width: 30),
                InkWell(
                  onTap: () {
                    MenuUtil.push(context, SchoolCurriculumElePage());
                  },
                  child: Container(
                      height: widget.height,
                      alignment: Alignment.center,
                      child: Text(
                        "Curriculum",
                        style: TextStyle(
                            color: Colors.black,
                            fontFamily: "Jalnan",
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      )),
                ),
                SizedBox(width: 30),
                InkWell(
                  onTap: () {
                    MenuUtil.push(context, SchoolOnlineProgramPage());
                  },
                  child: Container(
                      height: widget.height,
                      alignment: Alignment.center,
                      child: Text(
                        "Online Program",
                        style: TextStyle(
                            color: Colors.black,
                            fontFamily: "Jalnan",
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      )),
                ),
                SizedBox(width: 30),
                InkWell(
                  onTap: () {
                    MenuUtil.push(context, SchoolGalleryPage());
                  },
                  child: Container(
                      height: widget.height,
                      alignment: Alignment.center,
                      child: Text(
                        "Community",
                        style: TextStyle(
                            color: Colors.black,
                            fontFamily: "Jalnan",
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      )),
                ),
                SizedBox(width: 30),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
