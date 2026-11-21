import 'package:flutter/material.dart';
import 'package:gi_english_website/class/JuniorCurriculum.dart';
import 'package:gi_english_website/class/OnlineCourse.dart';
import 'package:gi_english_website/util/SiteLayout.dart';
import 'package:gi_english_website/util/AppLanguage.dart';
import 'package:gi_english_website/pages/SchoolOnlineJuniorCurriculumPage.dart';
import 'package:gi_english_website/pages/SchoolNZPage.dart';
import 'package:gi_english_website/pages/SchoolProgramPage.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/widget/ButtonState.dart';
import 'package:gi_english_website/widget/MobileSchoolLayout.dart';
import 'package:gi_english_website/widget/WebSchoolLayout.dart';

class SchoolCodingPage extends StatefulWidget {
  const SchoolCodingPage({Key? key}) : super(key: key);

  @override
  _SchoolCodingPageState createState() => _SchoolCodingPageState();
}

class _SchoolCodingPageState extends State<SchoolCodingPage> {
  List<ButtonState> buttonStateList = [
    ButtonState("정규프로그램", BehaviorColor.colorOnDefault, SchoolProgramPage()),
    ButtonState("선택프로그램", BehaviorColor.colorOnClick, SchoolCodingPage()),
    ButtonState("뉴질랜드프로그램", BehaviorColor.colorOnDefault, SchoolNZPage()),
  ];
  @override
  Widget build(BuildContext context) {
    if (!useMobileSchoolLayout(context)) {
      return desktopUi(context);
    } else {
      return mobileUi(context);
    }
  }

  Widget desktopUi(context) {
    return WebSchoolLayout(content: scrollView());
  }

  Widget mobileUi(context) {
    return MobileSchoolLayout(content: mobileScrollView());
  }

  Widget contentGroup() {
    return Container(
        color: Palette.white,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 232, child: leftAboutMenu()),
            Expanded(child: content()),
          ],
        ));
  }

  Widget leftAboutMenu() {
    List<Widget> children = [];
    for (int i = 0; i < buttonStateList.length; i++) {
      ButtonState buttonState = buttonStateList[i];

      bool isFirst = (i == 0);
      bool isLast = (i == buttonStateList.length - 1);

      Widget child;
      if (isFirst) {
        child = MyWidget.leftMenuTop(buttonState.color, buttonState.label);
      } else if (isLast) {
        //last
        child = MyWidget.leftMenuBottom(buttonState.color, buttonState.label);
      } else {
        child = MyWidget.leftMenuMiddle(buttonState.color, buttonState.label);
      }

      children.add(InkWell(
        child: child,
        onHover: (value) {
          buttonState.color = value
              ? BehaviorColor.colorOnHover
              : (i == 1
                  ? BehaviorColor.colorOnClick
                  : BehaviorColor.colorOnDefault);
          print(
              "label ${buttonState.label}, selectedColorList: ${buttonState.color}");
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

    return MyWidget.menuWithDailyWord(
    Container(
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
    ));
  }

  Widget content() {
    return OptionalProgramBody(compact: useMobileSchoolLayout(context));
  }

  Widget scrollView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          contentGroup(),
          MyWidget.footer(),
        ],
      ),
    );
  }

  Widget mobileScrollView() {
    return SingleChildScrollView(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            mobileLeftMenu(),
            content(),
          ],
        ),
      ),
    );
  }

  Widget mobileLeftMenu() {
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
        //last
        child =
            MyWidget.mobileLeftMenuEnd(buttonState.color, buttonState.label);
      } else {
        child =
            MyWidget.mobileLeftMenuMiddle(buttonState.color, buttonState.label);
      }

      children.add(InkWell(
        child: child,
        onHover: (value) {
          buttonState.color = value
              ? BehaviorColor.colorOnHover
              : (i == 1
                  ? BehaviorColor.colorOnClick
                  : BehaviorColor.colorOnDefault);
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
          color: Palette.grey300,
        ));
      }
    }

    return MyWidget.menuWithDailyWord(
    Container(
      color: Palette.white,
      padding: EdgeInsets.all(20),
      child: Container(
        // decoration: BoxDecoration(
        //   borderRadius: BorderRadius.circular(10),
        //   border: Border.all(
        //     width: 1,
        //     color: Palette.black,
        //   ),
        // ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: children,
          ),
        ),
      ),
    ));
  }

}

/// 글림아일랜드 선택 프로그램. 온라인 주니어 수업과 재원생 프리토킹.
class OptionalProgramBody extends StatelessWidget {
  final bool compact;

  const OptionalProgramBody({Key? key, this.compact = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Palette.white,
      width: double.maxFinite,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 20 : 28,
              20,
              compact ? 20 : 28,
              0,
            ),
            child: Text(
              tr(context, '선택 프로그램'),
              style: TextStyle(fontFamily: 'Jalnan', fontSize: 20),
            ),
          ),
          JuniorCurriculumContent(
            compact: compact,
            title: '1. 주니어 커리큘럼',
          ),
          EnrolledFreeTalkSection(compact: compact),
        ],
      ),
    );
  }
}

class EnrolledFreeTalkSection extends StatelessWidget {
  final bool compact;

  const EnrolledFreeTalkSection({Key? key, this.compact = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 20 : 28,
        0,
        compact ? 20 : 28,
        28,
      ),
      child: Container(
        width: double.maxFinite,
        padding: EdgeInsets.fromLTRB(16, 16, 16, 18),
        decoration: BoxDecoration(
          color: Palette.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Palette.grey200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: compact ? 180 : 240,
                width: double.infinity,
                child: Image.asset(
                  'assets/plan-card-speaking.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              tr(context, '2. 원어민 화상 프리토킹 (재원생 대상)'),
              style: TextStyle(
                fontFamily: 'NotoSansKR',
                fontWeight: FontWeight.w800,
                fontSize: compact ? 20 : 24,
                height: 1.35,
                color: Palette.grey900,
              ),
            ),
            SizedBox(height: 10),
            Text(
              tr(
                context,
                '재원생만 들을 수 있는 수업입니다. 원서와 문제 없이, 원어민 선생님과 이야기만 합니다.',
              ),
              style: TextStyle(
                fontFamily: 'NotoSansKR',
                fontSize: 15,
                height: 1.55,
                color: Palette.grey700,
              ),
            ),
            SizedBox(height: 12),
            Text(
              tf(context, '주 1회 · 20분 · 4회 {p0}', {
                'p0': EnrolledFreeTalk.priceLabel(),
              }),
              style: TextStyle(
                fontFamily: 'Jalnan',
                fontSize: compact ? 16 : 20,
                color: Color(0xFFEA7A1A),
              ),
            ),
            SizedBox(height: 16),
            Text(
              tr(context, '원어민 강사를 고른 뒤 결제합니다.'),
              style: TextStyle(
                fontFamily: 'NotoSansKR',
                fontSize: 13,
                height: 1.5,
                color: Palette.grey600,
              ),
            ),
            SizedBox(height: 12),
            PackagePayButton(
              label: tf(context, '{p0} 결제하기', {
                'p0': EnrolledFreeTalk.priceLabel(),
              }),
              color: const Color(0xFFEA7A1A),
              onPressed: () =>
                  startPackagePayment(context, OnlineCourse.enrolledFreeTalk),
            ),
          ],
        ),
      ),
    );
  }
}
