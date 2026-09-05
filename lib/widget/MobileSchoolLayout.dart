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
    const topBarHeight = 108.0;

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
            Positioned(top: 56, left: 0, right: 0, child: appBar2(context)),
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
    return Container(
      height: 56,
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Palette.white,
        border: Border(
          top: BorderSide(color: Palette.secondary, width: 3),
          bottom: BorderSide(color: Palette.grey200, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                MenuUtil.push(context, SchoolMainPage());
              },
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  height: 32,
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.matrix(<double>[
                      -1, 0, 0, 0, 255,
                      0, -1, 0, 0, 255,
                      0, 0, -1, 0, 255,
                      0, 0, 0, 1, 0,
                    ]),
                    child: Image.asset("assets/giEmblem.png",
                        fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
          ),
          if (!_isAdmin)
            IconButton(
              onPressed: () {
                _showAdminLoginDialog(context);
              },
              icon: Icon(Icons.admin_panel_settings_outlined,
                  color: Palette.grey500, size: 20),
            ),
          if (_isAdmin) ...[
            TextButton(
              onPressed: _logout,
              child: Text("로그아웃",
                  style: TextStyle(
                      fontFamily: "NotoSansKR",
                      fontSize: 12,
                      color: Palette.grey600)),
            ),
            TextButton(
              onPressed: () {
                MenuUtil.push(context, AdminOnlineHubPage());
              },
              child: Text("관리자",
                  style: TextStyle(
                      fontFamily: "NotoSansKR",
                      fontSize: 12,
                      color: Palette.secondaryDark,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ],
      ),
    );
  }

  Widget appBar2(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Palette.grey200, width: 1),
            ),
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
                          color: Palette.grey800,
                          fontFamily: "NotoSansKR",
                          fontWeight: FontWeight.w500,
                          fontSize: 13),
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
                          color: Palette.grey800,
                          fontFamily: "NotoSansKR",
                          fontWeight: FontWeight.w500,
                          fontSize: 13),
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
                            color: Palette.grey800,
                            fontFamily: "NotoSansKR",
                            fontWeight: FontWeight.w500,
                            fontSize: 13),
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
                            color: Palette.grey800,
                            fontFamily: "NotoSansKR",
                            fontWeight: FontWeight.w500,
                            fontSize: 13),
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
                            color: Palette.grey800,
                            fontFamily: "NotoSansKR",
                            fontWeight: FontWeight.w500,
                            fontSize: 13),
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
