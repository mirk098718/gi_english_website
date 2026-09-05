import 'package:flutter/material.dart';
import 'package:gi_english_website/pages/MemberLoginPage.dart';
import 'package:gi_english_website/pages/OnlineCheckoutPage.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/widget/MobileSchoolLayout.dart';
import 'package:gi_english_website/widget/OnlineProgramSideMenu.dart';
import 'package:gi_english_website/widget/WebSchoolLayout.dart';

import '../util/WidgetUtil.dart';

class SchoolOnlineProgramPage extends StatefulWidget {
  const SchoolOnlineProgramPage({Key? key}) : super(key: key);

  @override
  _SchoolOnlineProgramPageState createState() =>
      _SchoolOnlineProgramPageState();
}

class _SchoolOnlineProgramPageState extends State<SchoolOnlineProgramPage> {
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

  Widget scrollView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          mainImage(),
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
            OnlineProgramSideMenu(selectedIndex: -1, isMobile: true),
            content(),
            SizedBox(height: 51, child: MyWidget.mobileSchoolFooter()),
          ],
        ),
      ),
    );
  }

  Widget contentGroup() {
    return Container(
      color: Palette.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 232,
            child: OnlineProgramSideMenu(selectedIndex: -1),
          ),
          Expanded(child: content()),
        ],
      ),
    );
  }

  Widget mainImage() {
    return Container(
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          Image.asset("assets/ballPoolImage.png"),
          Container(
            padding: EdgeInsets.only(left: 40, bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "Online Program",
                  style: TextStyle(
                      color: Palette.white,
                      fontSize: 30,
                      fontFamily: "LucidaCalligraphy"),
                ),
                SizedBox(height: 20),
                applyButton(width: 220),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget applyButton({double width = double.infinity}) {
    return Container(
      width: width,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Palette.secondaryDark,
          foregroundColor: Palette.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: () {
          if (AuthService.currentUser == null) {
            MenuUtil.push(context, MemberLoginPage());
          } else {
            MenuUtil.push(context, OnlineCheckoutPage());
          }
        },
        child: Text(
          "프로그램 결제하기",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: "Jalnan",
            color: Palette.white,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget classGuideImage() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        width: 800,
        child: Image.asset("assets/onlineProgramClasses.png"),
      ),
    );
  }

  Widget content() {
    return Container(
      alignment: Alignment.topLeft,
      width: double.maxFinite,
      padding: EdgeInsets.all(20),
      color: Palette.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "온라인 프로그램 (인강)",
            style: TextStyle(fontFamily: "Jalnan", fontSize: 20),
          ),
          WidgetUtil.myDivider(),
          SizedBox(height: 20),
          Text(
            "언제 어디서나, 글림아일랜드의 수업을 이어가세요",
            style: TextStyle(
              fontFamily: "Jalnan",
              fontSize: 15,
              color: Palette.secondaryDark,
            ),
          ),
          SizedBox(height: 20),
          Text(
            style: TextStyle(
              color: Palette.black,
              fontFamily: "NotoSansKR",
              fontWeight: FontWeight.normal,
              fontSize: 14,
              height: 1.6,
            ),
            "글림아일랜드 온라인 프로그램은 바쁜 일정 속에서도 체계적인 영어 학습을 이어갈 수 있도록 마련된 인강 과정입니다.\n"
            "검증된 커리큘럼과 현장 수업의 노하우를 온라인으로 옮겼으며, 신청하신 분들께 안내된 강의실에서 배정된 강의를 수강하실 수 있습니다.",
          ),
          SizedBox(height: 28),
          classGuideImage(),
          SizedBox(height: 28),
          Text(
            "이런 분들께 추천합니다",
            style: TextStyle(
              fontFamily: "Jalnan",
              fontSize: 15,
              color: Palette.secondaryDark,
            ),
          ),
          SizedBox(height: 16),
          Text(
            style: TextStyle(
              color: Palette.black,
              fontFamily: "NotoSansKR",
              fontWeight: FontWeight.normal,
              fontSize: 14,
              height: 1.6,
            ),
            "• 시간·장소 제약 없이 꾸준히 영어를 공부하고 싶은 성인 학습자\n"
            "• 오프라인 수업과 병행해 복습·예습을 강화하고 싶은 분\n"
            "• 체계적인 인강으로 목표(회화·시험·유학 준비 등)에 집중하고 싶은 분",
          ),
          SizedBox(height: 28),
          Text(
            "이용 안내",
            style: TextStyle(
              fontFamily: "Jalnan",
              fontSize: 15,
              color: Palette.secondaryDark,
            ),
          ),
          SizedBox(height: 16),
          Text(
            style: TextStyle(
              color: Palette.black,
              fontFamily: "NotoSansKR",
              fontWeight: FontWeight.normal,
              fontSize: 14,
              height: 1.6,
            ),
            "1. 아래 버튼으로 온라인 프로그램을 신청해 주세요.\n"
            "2. 상담·안내 후 수강이 확정되면 배정된 강의를 안내드립니다.\n"
            "3. 회원으로 로그인하시면 나의 강의실에서 할당된 인강을 시청할 수 있습니다.",
          ),
          SizedBox(height: 36),
          applyButton(width: 260),
          SizedBox(height: 40),
        ],
      ),
    );
  }
}
