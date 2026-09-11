import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gi_english_website/class/OnlineCourse.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/widget/HeaderSocialLinks.dart';
import 'package:gi_english_website/widget/SiteNav.dart';

enum _HeaderMenu { none, courses, campus }

class WebSchoolLayout extends StatefulWidget {
  final Widget content;

  WebSchoolLayout({Key? key, required this.content}) : super(key: key);

  @override
  _WebSchoolLayoutState createState() => _WebSchoolLayoutState();
}

class _WebSchoolLayoutState extends State<WebSchoolLayout> {
  static const double _barHeight = 72;

  bool _isAdmin = false;
  bool _isMemberLoggedIn = AuthService.currentUser != null;
  StreamSubscription<User?>? _authSub;
  _HeaderMenu _menu = _HeaderMenu.none;
  Timer? _closeTimer;
  Timer? _hoverOpenTimer;

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
    _closeTimer?.cancel();
    _hoverOpenTimer?.cancel();
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

  void _openMenu(_HeaderMenu menu) {
    _closeTimer?.cancel();
    _hoverOpenTimer?.cancel();
    if (_menu == menu) return;
    setState(() => _menu = menu);
  }

  void _scheduleOpen(_HeaderMenu menu, Duration delay) {
    _closeTimer?.cancel();
    _hoverOpenTimer?.cancel();
    _hoverOpenTimer = Timer(delay, () {
      if (!mounted) return;
      _openMenu(menu);
    });
  }

  void _scheduleClose() {
    _hoverOpenTimer?.cancel();
    _closeTimer?.cancel();
    _closeTimer = Timer(const Duration(milliseconds: 160), () {
      if (mounted) setState(() => _menu = _HeaderMenu.none);
    });
  }

  void _closeMenu() {
    _hoverOpenTimer?.cancel();
    _closeTimer?.cancel();
    if (_menu == _HeaderMenu.none) return;
    setState(() => _menu = _HeaderMenu.none);
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
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: _barHeight,
            bottom: 0,
            left: 0,
            right: 0,
            child: widget.content,
          ),
          if (_menu != _HeaderMenu.none)
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeMenu,
                behavior: HitTestBehavior.opaque,
                child: const SizedBox.expand(),
              ),
            ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _header(),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return MouseRegion(
      onExit: (_) => _scheduleClose(),
      onEnter: (_) => _closeTimer?.cancel(),
      child: Material(
        color: Palette.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _bar(),
            if (_menu != _HeaderMenu.none) _dropdown(),
          ],
        ),
      ),
    );
  }

  Widget _bar() {
    return Container(
      height: _barHeight,
      padding: EdgeInsets.symmetric(horizontal: 28),
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
            onTap: () {
              _closeMenu();
              SiteNav.goHome(context);
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
          SizedBox(width: 28),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _navItem(
                    label: '과정',
                    menu: _HeaderMenu.courses,
                  ),
                  SizedBox(width: 8),
                  _navItem(
                    label: '레벨 진단',
                    onTap: () {
                      _closeMenu();
                      SiteNav.openPlacement(context);
                    },
                  ),
                  SizedBox(width: 8),
                  _navItem(
                    label: '내 강의실',
                    onTap: () {
                      _closeMenu();
                      SiteNav.goClassroom(context);
                    },
                  ),
                  _navDivider(),
                  _navItem(
                    label: '글림아일랜드 어학원',
                    menu: _HeaderMenu.campus,
                    color: Palette.darkTeal,
                    hoverDelay: const Duration(milliseconds: 220),
                    onTap: () {
                      _closeMenu();
                      SiteNav.goAcademy(context);
                    },
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 12),
          MouseRegion(
            onEnter: (_) => _scheduleClose(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                HeaderSocialLinks(),
                SizedBox(width: 12),
                ..._accountActions(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        width: 1,
        height: 22,
        color: Palette.grey300,
      ),
    );
  }

  Widget _navItem({
    required String label,
    VoidCallback? onTap,
    _HeaderMenu? menu,
    Duration? hoverDelay,
    Color? color,
  }) {
    final selected = menu != null && _menu == menu;
    final idle = color ?? Palette.black;
    final active = color ?? Palette.navy;
    return MouseRegion(
      onEnter: (_) {
        if (menu != null) {
          if (hoverDelay != null) {
            _scheduleOpen(menu, hoverDelay);
          } else {
            _openMenu(menu);
          }
        } else {
          _scheduleClose();
        }
      },
      child: InkWell(
        onTap: () {
          if (onTap != null) {
            onTap();
            return;
          }
          if (menu != null) {
            if (_menu == menu) {
              _closeMenu();
            } else {
              _openMenu(menu);
            }
          }
        },
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected ? active : idle,
                  fontFamily: "NotoSansKR",
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 15,
                  letterSpacing: -0.2,
                ),
              ),
              if (menu != null) ...[
                SizedBox(width: 2),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: selected ? active : Palette.grey500,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _accountActions() {
    final muted = TextStyle(
      color: Palette.grey600,
      fontSize: 13,
      fontFamily: "NotoSansKR",
    );
    final student = TextStyle(
      color: Palette.black,
      fontSize: 13,
      fontFamily: "NotoSansKR",
      fontWeight: FontWeight.w600,
    );
    final operatorStyle = TextStyle(
      color: Palette.darkTeal,
      fontSize: 13,
      fontFamily: "NotoSansKR",
      fontWeight: FontWeight.w600,
    );

    if (_isAdmin) {
      return [
        TextButton(
          onPressed: _logout,
          child: Text('로그아웃', style: muted),
        ),
        TextButton(
          onPressed: () {
            _closeMenu();
            SiteNav.goAdminHub(context);
          },
          child: Text('관리자', style: operatorStyle),
        ),
      ];
    }

    return [
      if (_isMemberLoggedIn)
        TextButton(
          onPressed: _logout,
          child: Text('로그아웃', style: muted),
        )
      else
        TextButton(
          onPressed: () {
            _closeMenu();
            SiteNav.goLogin(context);
          },
          child: Text('수강생 로그인', style: student),
        ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 2),
        child: Container(width: 1, height: 12, color: Palette.grey300),
      ),
      TextButton(
        onPressed: () async {
          _closeMenu();
          await SiteNav.goAdminLogin(context);
          await _checkAdminStatus();
        },
        child: Text('운영자 로그인', style: operatorStyle),
      ),
    ];
  }

  Widget _dropdown() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(28, 20, 28, 24),
      decoration: BoxDecoration(
        color: Palette.white,
        border: Border(
          bottom: BorderSide(color: Palette.grey200),
        ),
      ),
      child: _menu == _HeaderMenu.courses
          ? _coursesPanel()
          : _campusPanel(),
    );
  }

  Widget _coursesPanel() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _panelChip(
          label: '전체 과정 보기',
          subtitle: '수강 신청 · 강사 선택',
          onTap: () {
            _closeMenu();
            SiteNav.goCourses(context);
          },
        ),
        ...OnlineCourse.all.map(
          (course) => _panelChip(
            label: course.title,
            subtitle: course.subtitle,
            onTap: () {
              _closeMenu();
              SiteNav.goCourse(context, course);
            },
          ),
        ),
      ],
    );
  }

  Widget _campusPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 840;
            if (!wide) {
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final group in SiteNav.academyGroups)
                    _panelChip(
                      label: group.title,
                      onTap: () {
                        _closeMenu();
                        SiteNav.openPage(context, group.items.first);
                      },
                    ),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final group in SiteNav.academyGroups)
                  Expanded(child: _campusGroup(group)),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _campusGroup(SiteNavGroup group) {
    return Padding(
      padding: EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            group.title,
            style: TextStyle(
              fontFamily: "NotoSansKR",
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Palette.grey500,
              letterSpacing: 0.4,
            ),
          ),
          SizedBox(height: 10),
          for (final item in group.items)
            InkWell(
              onTap: () {
                _closeMenu();
                SiteNav.openPage(context, item);
              },
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontFamily: "NotoSansKR",
                    fontSize: 14,
                    color: Palette.black,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _panelChip({
    required String label,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 220,
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Palette.grey200),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: "NotoSansKR",
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Palette.grey900,
              ),
            ),
            if (subtitle != null) ...[
              SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: "NotoSansKR",
                  fontSize: 12,
                  color: Palette.grey500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
