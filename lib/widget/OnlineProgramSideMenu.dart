import 'package:flutter/material.dart';
import 'package:gi_english_website/pages/SchoolOnlineClassroomPage.dart';
import 'package:gi_english_website/pages/SchoolOnlineCurriculumPage.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/widget/ButtonState.dart';

/// Online Program 하위 페이지들이 공유하는 좌측(모바일에서는 상단) 메뉴.
/// selectedIndex가 -1이면 선택된 항목 없이 표시된다.
class OnlineProgramSideMenu extends StatefulWidget {
  final int selectedIndex;
  final bool isMobile;

  const OnlineProgramSideMenu({
    Key? key,
    required this.selectedIndex,
    this.isMobile = false,
  }) : super(key: key);

  @override
  _OnlineProgramSideMenuState createState() => _OnlineProgramSideMenuState();
}

class _OnlineProgramSideMenuState extends State<OnlineProgramSideMenu> {
  late List<ButtonState> buttonStateList;

  @override
  void initState() {
    super.initState();
    buttonStateList = [
      ButtonState("내 강의실", _colorFor(0), SchoolOnlineClassroomPage()),
      ButtonState("커리큘럼", _colorFor(1), SchoolOnlineCurriculumPage()),
    ];
  }

  Color _colorFor(int index) => index == widget.selectedIndex
      ? BehaviorColor.colorOnClick
      : BehaviorColor.colorOnDefault;

  @override
  Widget build(BuildContext context) {
    return widget.isMobile ? mobileMenu() : webMenu();
  }

  Widget webMenu() {
    List<Widget> children = [];
    for (int i = 0; i < buttonStateList.length; i++) {
      ButtonState buttonState = buttonStateList[i];

      bool isFirst = (i == 0);
      bool isLast = (i == buttonStateList.length - 1);

      Widget child;
      if (isFirst) {
        child = MyWidget.leftMenuTop(buttonState.color, buttonState.label);
      } else if (isLast) {
        child = MyWidget.leftMenuBottom(buttonState.color, buttonState.label);
      } else {
        child = MyWidget.leftMenuMiddle(buttonState.color, buttonState.label);
      }

      children.add(InkWell(
        child: child,
        onHover: (value) {
          buttonState.color =
              value ? BehaviorColor.colorOnHover : _colorFor(i);
          setState(() {});
        },
        onTap: () {
          MenuUtil.push(context, buttonState.nextPage);
        },
      ));

      if (!isLast) {
        children.add(Divider(height: 1));
      }
    }

    return Container(
      padding: EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            width: 1,
            color: Palette.black,
          ),
        ),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget mobileMenu() {
    List<Widget> children = [];
    for (int i = 0; i < buttonStateList.length; i++) {
      ButtonState buttonState = buttonStateList[i];

      bool isFirst = (i == 0);
      bool isLast = (i == buttonStateList.length - 1);

      Widget child;
      if (isFirst) {
        child =
            MyWidget.mobileLeftMenuStart(buttonState.color, buttonState.label);
      } else if (isLast) {
        child = MyWidget.mobileLeftMenuEnd(buttonState.color, buttonState.label);
      } else {
        child =
            MyWidget.mobileLeftMenuMiddle(buttonState.color, buttonState.label);
      }

      children.add(InkWell(
        child: child,
        onHover: (value) {
          buttonState.color =
              value ? BehaviorColor.colorOnHover : _colorFor(i);
          setState(() {});
        },
        onTap: () {
          MenuUtil.push(context, buttonState.nextPage);
        },
      ));

      if (!isLast) {
        children.add(Container(
          width: 1,
          height: 40,
          color: const Color.fromRGBO(96, 165, 250, 1),
        ));
      }
    }

    return Container(
      color: Palette.white,
      padding: EdgeInsets.all(20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: children,
        ),
      ),
    );
  }
}
