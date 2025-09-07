import 'package:flutter/material.dart';
import 'package:gi_english_website/pages/SchoolAllDayPage.dart';
import 'package:gi_english_website/pages/SchoolCampPage.dart';
import 'package:gi_english_website/pages/SchoolConsultationPage.dart';
import 'package:gi_english_website/pages/SchoolNZPage.dart';
import 'package:gi_english_website/pages/SchoolProgramPage.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/ModernWidgets.dart';
import 'package:gi_english_website/widget/ButtonState.dart';
import 'package:gi_english_website/widget/MobileSchoolLayout.dart';
import 'package:gi_english_website/widget/WebSchoolLayout.dart';

class School1on1Page extends StatefulWidget {
  const School1on1Page({Key? key}) : super(key: key);

  @override
  _School1on1PageState createState() => _School1on1PageState();
}

class _School1on1PageState extends State<School1on1Page> {
  List<ButtonState> buttonStateList = [
    ButtonState("정규프로그램", BehaviorColor.colorOnDefault, SchoolProgramPage()),
    ButtonState("올데이케어", BehaviorColor.colorOnDefault, SchoolAllDayPage()),
    ButtonState("방학캠프", BehaviorColor.colorOnDefault, SchoolCampPage()),
    ButtonState("뉴질랜드프로그램", BehaviorColor.colorOnDefault, SchoolNZPage()),
    ButtonState("1on1 프로그램", BehaviorColor.colorOnClick, School1on1Page()),
  ];
  @override
  Widget build(BuildContext context) {
    MediaQueryData mediaQueryData = MediaQuery.of(context);
    Size size = mediaQueryData.size;
    double width = size.width;
    if (width > 768) {
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
        color: Palette.background,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 280, child: leftAboutMenu()),
            Expanded(child: content()),
          ],
        ));
  }

  Widget leftAboutMenu() {
    return Container(
      padding: EdgeInsets.all(20),
      child: ModernWidgets.modernCard(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "프로그램",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Palette.grey900,
                fontFamily: "NotoSansKR",
              ),
            ),
            SizedBox(height: 16),
            ...buttonStateList.asMap().entries.map((entry) {
              int index = entry.key;
              ButtonState buttonState = entry.value;
              bool isSelected = index == 4; // 1on1 프로그램이 선택됨

              return ModernWidgets.modernMenuItem(
                title: buttonState.label,
                onTap: () => MenuUtil.push(context, buttonState.nextPage),
                isSelected: isSelected,
                selectedColor: Palette.primary,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget content() {
    return Container(
      padding: EdgeInsets.all(20),
      color: Palette.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ModernWidgets.modernSectionHeader(
            title: "1 on 1 프로그램",
            subtitle: "개인 맞춤형 특별 보충 수업",
            padding: EdgeInsets.zero,
          ),
          SizedBox(height: 24),
          ModernWidgets.modernInfoCard(
            title: "프로그램 소개",
            content:
                "1 on 1 프로그램은 특별 개인 보충 수업으로, 본원 학생 중 정규 수업을 따라가는데에 어려움을 겪는 학생들을 대상으로 한 프로그램입니다. 글림아일랜드는 학습이 어려운 학생을 결코 방치하지 않고 적극적으로 서포트하며 자신감을 잃지 않도록 합니다.",
            icon: Icons.person,
            accentColor: Palette.primary,
          ),
          SizedBox(height: 16),
          ModernWidgets.modernInfoCard(
            title: "수업 대상",
            content:
                "학습에 어려움을 겪는 본원 유초등부 학생들을 대상으로 합니다. 개별 상담을 통해 학생의 수준과 필요에 맞는 맞춤형 수업을 제공합니다.",
            icon: Icons.school,
            accentColor: Palette.secondary,
          ),
          SizedBox(height: 16),
          ModernWidgets.modernInfoCard(
            title: "수업 특징",
            content:
                "• 개별 맞춤형 학습 계획 수립\n• 학생의 학습 속도에 맞춘 진도 조절\n• 1:1 집중 관리로 학습 효과 극대화\n• 정기적인 학습 상황 점검 및 피드백",
            icon: Icons.star,
            accentColor: Palette.accent,
          ),
        ],
      ),
    );
  }

  Widget scrollView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          mainImage(),
          contentGroup(),
          ModernWidgets.modernFooter(),
        ],
      ),
    );
  }

  Widget mainImage() {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/ballPoolImage.png"),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.6),
            ],
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 40,
              bottom: 40,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Palette.primary.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Program",
                      style: TextStyle(
                        color: Palette.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: "NotoSansKR",
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "1 on 1 프로그램",
                    style: TextStyle(
                      color: Palette.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      fontFamily: "NotoSansKR",
                      shadows: [
                        Shadow(
                          offset: Offset(0, 2),
                          blurRadius: 4,
                          color: Colors.black.withOpacity(0.5),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "개인 맞춤형 특별 보충 수업",
                    style: TextStyle(
                      color: Palette.white.withOpacity(0.9),
                      fontSize: 16,
                      fontFamily: "NotoSansKR",
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 2,
                          color: Colors.black.withOpacity(0.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 40,
              bottom: 40,
              child: ModernWidgets.modernButton(
                text: "상담신청",
                onPressed: () =>
                    MenuUtil.push(context, SchoolConsultationPage()),
                backgroundColor: Palette.primary,
                icon: Icons.chat,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  //mobile

  Widget mobileScrollView() {
    return SingleChildScrollView(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // mobileMainImage(),
            mobileLeftMenu(),
            content(),
            ModernWidgets.modernMobileFooter()
          ],
        ),
      ),
    );
  }

  Widget mobileLeftMenu() {
    return Container(
      color: Palette.background,
      padding: EdgeInsets.all(20),
      child: ModernWidgets.modernCard(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: buttonStateList.asMap().entries.map((entry) {
              int index = entry.key;
              ButtonState buttonState = entry.value;
              bool isSelected = index == 4; // 1on1 프로그램이 선택됨
              bool isLast = index == buttonStateList.length - 1;

              return Container(
                margin: EdgeInsets.only(right: isLast ? 0 : 8),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Palette.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? Palette.primary : Palette.grey300,
                      width: 1,
                    ),
                  ),
                  child: InkWell(
                    onTap: () => MenuUtil.push(context, buttonState.nextPage),
                    child: Text(
                      buttonState.label,
                      style: TextStyle(
                        color: isSelected ? Palette.white : Palette.grey700,
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontFamily: "NotoSansKR",
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget mobileMainImage() {
    return Container(
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Image.asset("assets/ballPoolImage.png"),
          Container(
            padding: EdgeInsets.only(left: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Program",
                  style: TextStyle(
                      color: Palette.white,
                      fontSize: 20,
                      fontFamily: "LucidaCalligraphy"),
                ),
                SizedBox(
                  height: 10,
                ),
                Container(
                  width: 150,
                  height: 40,
                  child: ElevatedButton(
                    child: Text(
                      "상담신청",
                      style:
                          TextStyle(fontFamily: "Jalnan", color: Palette.white),
                    ),
                    onPressed: () {
                      MenuUtil.push(context, SchoolConsultationPage());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(139, 92, 246, 1),
                      foregroundColor: Palette.black,
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
