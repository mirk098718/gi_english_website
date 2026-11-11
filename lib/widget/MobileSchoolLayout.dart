import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gi_english_website/util/AppLanguage.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/widget/AcademyNavMenu.dart';
import 'package:gi_english_website/widget/GleamMark.dart';
import 'package:gi_english_website/widget/HeaderSocialLinks.dart';
import 'package:gi_english_website/widget/HomeDailyWordBlock.dart';
import 'package:gi_english_website/widget/LetsTalkNavChip.dart';
import 'package:gi_english_website/widget/LessonRatingPromptHost.dart';
import 'package:gi_english_website/widget/NotificationBellButton.dart';
import 'package:gi_english_website/widget/SiteNav.dart';

enum _MobileMenu { none, courses, academy }

class MobileSchoolLayout extends StatefulWidget {
  final Widget content;
  final double height = 52;
  final DailyWordTone dailyWordTone;

  MobileSchoolLayout({
    Key? key,
    required this.content,
    this.dailyWordTone = DailyWordTone.home,
  }) : super(key: key);

  @override
  _MobileSchoolLayoutState createState() => _MobileSchoolLayoutState();
}

class _MobileSchoolLayoutState extends State<MobileSchoolLayout> {
  AdminRole _adminRole = AdminRole.none;
  bool _isMemberLoggedIn = AuthService.currentUser != null;
  _MobileMenu _menu = _MobileMenu.none;
  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    _authSub = AuthService.authStateChanges.listen((user) {
      if (mounted) {
        setState(() {
          _isMemberLoggedIn = user != null;
          if (user == null && _menu == _MobileMenu.courses) {
            _menu = _MobileMenu.none;
          }
        });
        _checkAdminStatus();
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  bool get _isStaff =>
      _adminRole == AdminRole.owner || _adminRole == AdminRole.teacher;

  void _closeMenu() {
    if (_menu == _MobileMenu.none) return;
    setState(() => _menu = _MobileMenu.none);
  }

  void _toggleMenu(_MobileMenu menu) {
    setState(() => _menu = _menu == menu ? _MobileMenu.none : menu);
  }

  void _go(VoidCallback action) {
    _closeMenu();
    action();
  }

  Future<void> _checkAdminStatus() async {
    final role = await AuthService.getAdminRole();
    if (mounted) {
      setState(() {
        _adminRole = role;
      });
    }
  }

  Future<void> _logout() async {
    try {
      await AuthService.signOut();
      if (!mounted) return;
      setState(() {
        _adminRole = AdminRole.none;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(tr(context, "로그아웃되었습니다."), style: TextStyle(fontFamily: "NotoSansKR")),
          backgroundColor: Palette.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(context, "로그아웃 중 오류가 발생했습니다."),
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

    return LessonRatingPromptHost(
      enabled: _isMemberLoggedIn && !_isStaff,
      child: Scaffold(
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
                  HomeDailyWordBlock(
                    bar: true,
                    tone: widget.dailyWordTone,
                  ),
                  MyWidget.mobileSchoolFooter(),
                ],
              ),
            ),
            if (_menu != _MobileMenu.none) ...[
              Positioned(
                top: topBarHeight,
                left: 0,
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: _closeMenu,
                  behavior: HitTestBehavior.opaque,
                  child: ColoredBox(
                    color: Palette.black.withValues(alpha: 0.28),
                  ),
                ),
              ),
              Positioned(
                top: topBarHeight,
                left: 0,
                right: 0,
                child: _menu == _MobileMenu.courses
                    ? _coursesMenu()
                    : _academyMenu(viewportHeight - topBarHeight),
              ),
            ],
            Positioned(top: 56, left: 0, right: 0, child: _navRow()),
            Positioned(top: 0, left: 0, right: 0, child: _topBar()),
          ],
        ),
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
          InkWell(
            onTap: () => _go(() => SiteNav.goHome(context)),
            child: SizedBox(
              height: 32,
              child: GleamMark(height: 32),
            ),
          ),
          SizedBox(width: 8),
          const LanguageToggle(compact: true),
          SizedBox(width: 4),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  NotificationBellButton(),
                  HeaderSocialLinks(compact: true),
                  if (_isStaff) ...[
            TextButton(
              onPressed: _logout,
              child: Text(
                tr(context, "로그아웃"),
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
                _adminRole == AdminRole.teacher ? tr(context, "수업 관리") : tr(context, "관리자"),
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
                  tr(context, "로그아웃"),
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
                  tr(context, "수강생 로그인"),
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
                tr(context, "운영자 로그인"),
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
            ),
          ),
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
            _navLink(
              '과정',
              () => _toggleMenu(_MobileMenu.courses),
              enabled: _isMemberLoggedIn,
              selected: _menu == _MobileMenu.courses,
              expandable: true,
            ),
            _navLink(
              '내 강의실',
              () => _go(() => SiteNav.goClassroom(context)),
              enabled: _isMemberLoggedIn,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: LetsTalkNavChip(
                compact: true,
                onTap: () => _go(() => SiteNav.goLetsTalk(context)),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Container(width: 1, height: 16, color: Palette.grey300),
            ),
            _navLink(
              '글림아일랜드 어학원',
              () => _toggleMenu(_MobileMenu.academy),
              color: Palette.darkTeal,
              selected: _menu == _MobileMenu.academy,
              expandable: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _coursesMenu() {
    return Material(
      color: Palette.white,
      elevation: 6,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Palette.grey200)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _menuRow(
              '온라인 과정 보기',
              () => _go(() => SiteNav.goCourses(context)),
            ),
            _menuRow(
              '레벨테스트',
              () => _go(() => SiteNav.openPlacement(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuRow(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Text(
          tr(context, label),
          style: TextStyle(
            fontFamily: 'NotoSansKR',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Palette.black,
          ),
        ),
      ),
    );
  }

  Widget _academyMenu(double maxHeight) {
    return Material(
      color: Palette.white,
      elevation: 6,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Palette.grey200)),
          ),
          child: AcademyNavMenu(
            onSelect: (item) {
              _closeMenu();
              SiteNav.openPage(context, item);
            },
          ),
        ),
      ),
    );
  }

  Widget _navLink(
    String label,
    VoidCallback onTap, {
    Color? color,
    bool enabled = true,
    bool selected = false,
    bool expandable = false,
  }) {
    final tone = enabled ? (color ?? Palette.black) : Palette.grey400;
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Container(
        color: selected ? Palette.darkTeal.withValues(alpha: 0.08) : null,
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: SizedBox(
          height: widget.height,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tr(context, label),
                style: TextStyle(
                  color: tone,
                  fontFamily: "NotoSansKR",
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              if (expandable) ...[
                SizedBox(width: 2),
                Icon(
                  selected
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 16,
                  color: enabled ? tone : Palette.grey400,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
