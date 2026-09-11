import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/widget/HeaderSocialLinks.dart';
import 'package:gi_english_website/widget/SiteNav.dart';

class MobileSchoolLayout extends StatefulWidget {
  final Widget content;
  final double height = 52;

  MobileSchoolLayout({Key? key, required this.content}) : super(key: key);

  @override
  _MobileSchoolLayoutState createState() => _MobileSchoolLayoutState();
}

class _MobileSchoolLayoutState extends State<MobileSchoolLayout> {
  bool _isAdmin = false;
  bool _isMemberLoggedIn = AuthService.currentUser != null;
  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    _authSub = AuthService.authStateChanges.listen((user) {
      if (mounted) {
        setState(() {
          _isMemberLoggedIn = user != null;
        });
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _checkAdminStatus() async {
    final isStaff = await AuthService.isStaff();
    if (mounted) {
      setState(() {
        _isAdmin = isStaff;
      });
    }
  }

  Future<void> _logout() async {
    try {
      await AuthService.signOut();
      if (!mounted) return;
      setState(() {
        _isAdmin = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('로그아웃되었습니다.', style: TextStyle(fontFamily: "NotoSansKR")),
          backgroundColor: Palette.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('로그아웃 중 오류가 발생했습니다.',
              style: TextStyle(fontFamily: "NotoSansKR")),
          backgroundColor: Palette.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
              child: Column(
                children: [
                  Expanded(
                    child: ClipRect(
                      child: widget.content,
                    ),
                  ),
                  MyWidget.mobileSchoolFooter(),
                ],
              ),
            ),
            Positioned(top: 56, left: 0, right: 0, child: _navRow()),
            Positioned(top: 0, left: 0, right: 0, child: _topBar()),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Container(
      height: 56,
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Palette.white,
        border: Border(
          top: BorderSide(color: Palette.darkTeal, width: 3),
          bottom: BorderSide(color: Palette.grey200, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => SiteNav.goHome(context),
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
          HeaderSocialLinks(compact: true),
          SizedBox(width: 4),
          if (_isAdmin) ...[
            TextButton(
              onPressed: _logout,
              child: Text(
                '로그아웃',
                style: TextStyle(
                  fontFamily: "NotoSansKR",
                  fontSize: 12,
                  color: Palette.grey600,
                ),
              ),
            ),
            TextButton(
              onPressed: () => SiteNav.goAdminHub(context),
              child: Text(
                '관리자',
                style: TextStyle(
                  fontFamily: "NotoSansKR",
                  fontSize: 12,
                  color: Palette.darkTeal,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ] else ...[
            if (_isMemberLoggedIn)
              TextButton(
                onPressed: _logout,
                child: Text(
                  '로그아웃',
                  style: TextStyle(
                    fontFamily: "NotoSansKR",
                    fontSize: 12,
                    color: Palette.grey600,
                  ),
                ),
              )
            else
              TextButton(
                onPressed: () => SiteNav.goLogin(context),
                child: Text(
                  '수강생 로그인',
                  style: TextStyle(
                    fontFamily: "NotoSansKR",
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Palette.black,
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 2),
              child: Container(width: 1, height: 12, color: Palette.grey300),
            ),
            TextButton(
              onPressed: () async {
                await SiteNav.goAdminLogin(context);
                await _checkAdminStatus();
              },
              child: Text(
                '운영자 로그인',
                style: TextStyle(
                  fontFamily: "NotoSansKR",
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Palette.darkTeal,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _navRow() {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Palette.white,
        border: Border(
          bottom: BorderSide(color: Palette.grey200, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            _navLink('과정', () => SiteNav.goCourses(context)),
            _navLink('레벨 진단', () => SiteNav.openPlacement(context)),
            _navLink('내 강의실', () => SiteNav.goClassroom(context)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Container(width: 1, height: 16, color: Palette.grey300),
            ),
            _navLink(
              '글림아일랜드 어학원',
              () => SiteNav.goAcademy(context),
              color: Palette.darkTeal,
            ),
          ],
        ),
      ),
    );
  }

  Widget _navLink(String label, VoidCallback onTap, {Color? color}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: SizedBox(
          height: widget.height,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: color ?? Palette.black,
                fontFamily: "NotoSansKR",
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
