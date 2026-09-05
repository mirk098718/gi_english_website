import 'package:flutter/material.dart';
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
import 'package:gi_english_website/pages/SchoolOnlineProgramPage.dart';
import 'package:gi_english_website/pages/SchoolProgramPage.dart';
import 'package:gi_english_website/pages/SchoolSystemPage.dart';
import 'package:gi_english_website/pages/SchoolTeachersPage.dart';
import 'package:gi_english_website/pages/WorkingAdminLoginPage.dart';
import 'package:gi_english_website/pages/AdminOnlineHubPage.dart';
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
    bool isStaff = await AuthService.isStaff();
    if (mounted) {
      setState(() {
        _isAdmin = isStaff;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
              top: 72, bottom: 0, left: 0, right: 0, child: widget.content),
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

  Widget _navLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: Palette.grey800,
        fontFamily: "NotoSansKR",
        fontWeight: FontWeight.w500,
        fontSize: 15,
        letterSpacing: -0.2,
      ),
    );
  }

  Widget appBar(BuildContext context) {
    return Container(
      height: 72,
      padding: EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: Palette.white,
        border: Border(
          top: BorderSide(color: Palette.secondary, width: 3),
          bottom: BorderSide(color: Palette.grey200, width: 1),
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              MenuUtil.push(context, SchoolMainPage());
            },
            child: SizedBox(
              height: 36,
              child: ColorFiltered(
                colorFilter: const ColorFilter.matrix(<double>[
                  -1, 0, 0, 0, 255,
                  0, -1, 0, 0, 255,
                  0, 0, -1, 0, 255,
                  0, 0, 0, 1, 0,
                ]),
                child: Image.asset("assets/giEmblem.png", fit: BoxFit.contain),
              ),
            ),
          ),
          Spacer(),
          InkWell(
            onTap: () {
              MenuUtil.push(context, SchoolAboutPage());
            },
            child: _navLabel("About"),
          ),
          SizedBox(width: 28),
          InkWell(
            onTap: () {
              MenuUtil.push(context, SchoolProgramPage());
            },
            child: _navLabel("Program"),
          ),
          SizedBox(width: 28),
          InkWell(
            onTap: () {
              MenuUtil.push(context, SchoolCurriculumElePage());
            },
            child: _navLabel("Curriculum"),
          ),
          SizedBox(width: 28),
          InkWell(
            onTap: () {
              MenuUtil.push(context, SchoolOnlineProgramPage());
            },
            child: _navLabel("Online"),
          ),
          SizedBox(width: 28),
          InkWell(
            onTap: () {
              MenuUtil.push(context, SchoolGalleryPage());
            },
            child: _navLabel("Community"),
          ),
          SizedBox(width: 20),
          if (!_isAdmin)
            IconButton(
              tooltip: '관리자 로그인',
              onPressed: () {
                _showAdminLoginDialog(context);
              },
              icon: Icon(Icons.admin_panel_settings_outlined,
                  color: Palette.grey500, size: 20),
            ),
          if (_isAdmin) ...[
            TextButton(
              onPressed: _logout,
              child: Text(
                "로그아웃",
                style: TextStyle(
                  color: Palette.grey600,
                  fontSize: 13,
                  fontFamily: "NotoSansKR",
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                MenuUtil.push(context, AdminOnlineHubPage());
              },
              child: Text(
                "관리자",
                style: TextStyle(
                  color: Palette.secondaryDark,
                  fontSize: 13,
                  fontFamily: "NotoSansKR",
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
