
import 'package:flutter/material.dart';
import 'package:gi_english_website/pages/SchoolConsultationPage.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/widget/EasyKeyboardListener.dart';
import 'package:gi_english_website/widget/MobileSchoolLayout.dart';
import 'package:gi_english_website/widget/WebSchoolLayout.dart';
import '../admin/page/AdminLoginPage.dart';
import '../util/UrlIUtil.dart';
import '../util/WidgetUtil.dart';

class SchoolMainPage extends StatefulWidget {
  const SchoolMainPage({Key? key}) : super(key: key);

  @override
  _SchoolMainPageState createState() => _SchoolMainPageState();
}

class _SchoolMainPageState extends State<SchoolMainPage> {
  final hiddenMenu = "hiddenmenu";
  final idController = TextEditingController();
  final pwController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    MediaQueryData mediaQueryData = MediaQuery.of(context);
    Size size = mediaQueryData.size;
    double width = size.width;

    Widget returnWidget;
    if (width > 768) {
      returnWidget = desktopUi(context);
    } else {
      returnWidget = mobileUi(context);
    }

    return EasyKeyboardListener(
      onValue: (String value) {
        if (value == hiddenMenu) {
          MenuUtil.pop(context);
          MenuUtil.push(context, AdminLoginPage());
        }
      },
      inputLimit: hiddenMenu.length,
      child: returnWidget,
    );
  }

  Widget desktopUi(context) {
    return WebSchoolLayout(content: scrollView());
  }

  Widget mobileUi(context) {
    return MobileSchoolLayout(content: mobileScrollView());
  }

  Widget mainImage() {
    return Container(
        child: Stack(alignment: Alignment.centerLeft, children: [
          Image.asset("assets/mainGateImageBlack.png"),
          Container(
            width: 500,
            padding: EdgeInsets.only(left: 20),
            child: Text(
              "",
              style: TextStyle(fontFamily: "Lovingu", fontSize: 30),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 40,
            child: Container(
              width: 150,
              height: 40,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Palette.black,
                  foregroundColor: Palette.black,
                ),
                onPressed: () {
                  MenuUtil.push(context, SchoolConsultationPage());
                },
                child: Text("상담신청",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "Jalnan",
                      color: Palette.white,
                    )),
              ),
            ),
          )
        ]));
  }

  Widget urlMenu() {
    return Container(
      alignment: Alignment.center,
      color: Palette.white,
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Container(
             height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Palette.lightestEarth, width: 5),
                // borderRadius: BorderRadius.circular(5),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: EdgeInsets.only(top: 5, bottom: 5),
                      alignment: Alignment.center,
                      child: Image.asset("assets/giAppBannerFinal.png"),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      height: 60,
                      alignment: Alignment.center,
                      child: Image.asset("assets/giAppDownload.png"),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.all(5),
                    width: 0.5,
                    height: 40,
                    color: Palette.mainGrey,
                  ),
                  Expanded(
                      flex: 1,
                      child: Container(
                        width: 80,
                        height: 80,
                        padding: EdgeInsets.all(10),
                        alignment: Alignment.center,
                        child: InkWell(
                            onTap: () async {
                              UrlUtil.open('https://www.instagram.com/gleam_island_school/');
                            },
                            child: Image.asset("assets/instaLogo.png")),
                      )),
                  Container(
                    margin: EdgeInsets.all(5),
                    width: 0.5,
                    height: 40,
                    color: Palette.mainGrey,
                  ),
                  Expanded(
                      flex: 1,
                      child: Container(
                        width: 80,
                        height: 80,
                        padding: EdgeInsets.all(10),
                        alignment: Alignment.center,
                        child: InkWell(
                            onTap: () async {
                              UrlUtil.open('https://blog.naver.com/gleam-island-paju');
                            },
                          child: Container(
                              width:40,child: Image.asset("assets/naverBlogLogo.png")),
                        ),
                      )),
                ],
              ),
            ),
          ),
          Expanded(
              flex: 1,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Palette.lightestEarth, width:5),
                      bottom: BorderSide(color: Palette.lightestEarth, width:5),
                      right: BorderSide(color: Palette.lightestEarth, width:5)),
                  // borderRadius: BorderRadius.circular(5),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        margin: EdgeInsets.only(top:15, bottom: 15),
                        child: InkWell(
                          child: Image.asset("assets/middleOnlineLink.png"),
                          onTap: () async {
                            UrlUtil.open('http://gienglish.theclip.net/');
                          },
                        ),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.all(5),
                      width: 0.5,
                      height: 40,
                      color: Palette.mainGrey,
                    ),
                    Expanded(
                      flex: 3,
                      child: Container(
                        margin: EdgeInsets.all(10),
                        child: InkWell(
                          child: Image.asset("assets/eleOnlineLink.png"),
                          onTap: () async {
                            UrlUtil.open('https://www.trophy9.com/account/account.do?stdcmd=sign&url=%2Fdefault%2Edo%3F');
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ))
        ],
      ),
    );
  }

  Widget bulletinBoard() {
    double eachBoardHeight = 500;

    return Container(
      decoration: BoxDecoration(image: DecorationImage(image: AssetImage("assets/bulletinBoardBG.png"), fit: BoxFit.fill)),
      padding: EdgeInsets.only(top: 20, bottom: 200),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Spacer(),
          Expanded(
            flex: 5,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Palette.mainLightGrey, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: SizedBox(
                height: eachBoardHeight,
                child: Column(
                  children: [
                    Container(
                      height: 50,
                      width: double.infinity,
                      child: TextButton(
                        child: Text("Notice Board",
                            style: TextStyle(
                                color: Palette.black, fontFamily: "Jalnan")),
                        onPressed: () {
                          // MenuUtil.push(context, SchoolCommunityNoticePage());
                        },
                      ),
                      decoration: BoxDecoration(
                        color: Palette.mainLightGrey,
                        border:
                            Border.all(color: Palette.mainLightGrey, width: 3),
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(18),
                            topRight: Radius.circular(18)),
                      ),
                    ),
                    Container(
                    color: Colors.white,
                    alignment: Alignment.topLeft,
                    padding: EdgeInsets.all(20),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              style: TextStyle(
                                  color: Palette.black,
                                  fontFamily: "NotoSansKR",
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14),
                              "글림아일랜드 소식"),
                          WidgetUtil.myDivider(),
                          Text(
                              style: TextStyle(
                                  color: Palette.black,
                                  fontFamily: "NotoSansKR",
                                  fontWeight: FontWeight.normal,
                                  fontSize: 14),
                              "* 글림아일랜드 2024년 신학기 개강 일정 :\n"
                                  "- 월수금반 : 3월 6일  /  화목반 : 3월 5일\n"
                                  "* 신규 Prep(파닉스)반 2반 신설 및 중등부 신설"),]
                    ),
                  ),
                    Container(
                      color: Colors.white,
                      alignment: Alignment.topLeft,
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                style: TextStyle(
                                    color: Palette.black,
                                    fontFamily: "NotoSansKR",
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14),
                                "글림아일랜드 어학원 초등부 체험수업"),
                            WidgetUtil.myDivider(),
                            Text(
                                style: TextStyle(
                                    color: Palette.black,
                                    fontFamily: "NotoSansKR",
                                    fontWeight: FontWeight.normal,
                                    fontSize: 14),
                                "- 글림아일랜드의 모든 수업은 체험 수업이 가능합니다. "
                                    "아이가 직접 수업을 참여해보고 결정할 수 있도록 해 주십시오.(일일 수강료 발생)"),]
                      ),
                    ),
                    Container(
                      color: Colors.white,
                      alignment: Alignment.topLeft,
                      padding: EdgeInsets.all(20),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              style: TextStyle(
                                  color: Palette.black,
                                  fontFamily: "NotoSansKR",
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14),
                              "학원 차량 노선"),
                          WidgetUtil.myDivider(),
                          Text(
                            style: TextStyle(
                                color: Palette.black,
                                fontFamily: "NotoSansKR",
                                fontWeight: FontWeight.normal,
                                fontSize: 14),
                            "본원에서는 초등, 중등반 수업 스케줄에 따른 학원 차량을 운행하며 자세한 내용은 상담시 차량 노선과 함께 제공합니다."),]
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
          Spacer(),
          Expanded(
            flex: 5,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Palette.mainLightGrey, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: SizedBox(
                height: eachBoardHeight,
                child: Column(
                  children: [
                    Container(
                      height: 50,
                      width: double.infinity,
                      child: TextButton(
                        child: Text(
                          "FAQ",
                          style: TextStyle(
                              color: Palette.black, fontFamily: "Jalnan"),
                        ),
                        onPressed: () {},
                      ),
                      decoration: BoxDecoration(
                        color: Palette.mainLightGrey,
                        border:
                            Border.all(color: Palette.mainLightGrey, width: 3),
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(18),
                            topRight: Radius.circular(18)),
                      ),
                    ),
                    Container(
                      color: Colors.white,
                      alignment: Alignment.topLeft,
                      padding: EdgeInsets.all(20),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                                style: TextStyle(
                                    color: Palette.black,
                                    fontFamily: "NotoSansKR",
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14),
                                "Q: 글림아일랜드 24년도 개강일은?"),
                            WidgetUtil.myDivider(),
                            Text(
                                style: TextStyle(
                                    color: Palette.black,
                                    fontFamily: "NotoSansKR",
                                    fontWeight: FontWeight.normal,
                                    fontSize: 14),
                                "A: 글림아일랜드 2024년 신학기 개강 일정 :\n"
                                    "- 월수금반 : 3월 6일\n"
                                    "- 화목반 : 3월 5일"),
                          ]),
                    ),
                    Container(
                      height: 1,
                      margin: EdgeInsets.only(right: 10, left: 10),
                    ),
                    Container(
                      color: Colors.white,
                      alignment: Alignment.topLeft,
                      padding: EdgeInsets.all(20),
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                style: TextStyle(
                                    color: Palette.black,
                                    fontFamily: "NotoSansKR",
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14),
                                "Q: 초등, 중등부 각반 정원은 몇명인가요?"),
                            WidgetUtil.myDivider(),
                            Text(
                                style: TextStyle(
                                    color: Palette.black,
                                    fontFamily: "NotoSansKR",
                                    fontWeight: FontWeight.normal,
                                    fontSize: 14),
                                "A: 초등부, 중등부 정원은 한 반에 8명이며 bilingual 선생님께서 담임을 맡아 주실 것이고, "
                                    "최소 주 1회 원어민 선생님 수업이 있습니다."),
                          ]),
                    ),
                    Container(
                      color: Colors.white,
                      height: 1,
                      margin: EdgeInsets.only(right: 10, left: 10),
                    ),
                    Container(
                      color: Colors.white,
                      alignment: Alignment.topLeft,
                      padding: EdgeInsets.all(20),
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                style: TextStyle(
                                    color: Palette.black,
                                    fontFamily: "NotoSansKR",
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14),
                                "Q: 연령별로 반이 나뉘나요?"),
                            WidgetUtil.myDivider(),
                            Text(
                                style: TextStyle(
                                    color: Palette.black,
                                    fontFamily: "NotoSansKR",
                                    fontWeight: FontWeight.normal,
                                    fontSize: 14),
                                "A: 예비초, 초등부는 연령을 고려하되,실력 테스트를 거친 후 레벨 별로 반 배정이 됩니다. 중등부는 연령과 실력에 따라 반 배정이 되며 학교도 되도록이면 통일합니다."),
                          ]),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Spacer(),
        ],
      ),
    );
  }

  Widget scrollView() {
    return SingleChildScrollView(
      child: Container(
        color: Palette.white,
        child: Column(
          children: [
            mainImage(),
            SizedBox(height: 120, child: urlMenu()),
            Container(width:double.infinity,child: InkWell(child: Image.asset("assets/mainBannerOpening.png")
            , onTap: () async {
                UrlUtil.open('https://blog.naver.com/gleam-island-paju/223029184863');
              },)),
            bulletinBoard(),
            SizedBox(height: 213, child: MyWidget.footer()),

          ],
        ),
      ),
    );
  }

  // mobile

  Widget mobileScrollView() {
    return SingleChildScrollView(
      child: Container(
        child: Column(
          children: [
            InkWell(child: Image.asset("assets/mainBannerOpening.png"),
              onTap: () async {
                UrlUtil.open('https://blog.naver.com/gleam-island-paju/223029184863');
              },),
            // mobileMenuList(),
            mobileUrlMenu(),
            mobileBulletinBoard(),
            SizedBox(height: 51, child: MyWidget.mobileSchoolFooter())
          ],
        ),
      ),
    );
  }

  Widget mobileMainImage() {
    return Stack(alignment: Alignment.bottomRight, children: [
      Container(child: Image.asset("assets/mainGateImageLightBlue.png")),
      // Container(
      //   margin: EdgeInsets.all(20),
      //   width: 150,
      //   height: 40,
      //   child: ElevatedButton(
      //     style: ElevatedButton.styleFrom(
      //       primary: Palette.black,
      //       onPrimary: Palette.black,
      //     ),
      //     onPressed: () {MenuUtil.push(context, SchoolConsultationPage());},
      //     child: Text("상담신청",
      //         textAlign: TextAlign.center,
      //         style: TextStyle(
      //           fontFamily: "Jalnan",
      //           color: Palette.white,
      //         )),
      //   ),
      // ),
    ]);
  }

  Widget mobileUrlMenu() {
    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20), color: Palette.greyTenPer),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                  onTap: () async {
                    UrlUtil.open('https://www.instagram.com/gleam_island_school/');
                  },
                  child: Image.asset("assets/instaLogo.png")),
              Spacer(),
              Container(
                margin: EdgeInsets.all(5),
                width: 1,
                height: 40,
                color: Colors.black54,
              ),
              Spacer(),
              Container(
                  width: 40,
                  child: InkWell(
                      onTap: () async {
                        UrlUtil.open('https://blog.naver.com/gleam-island-paju');
                      },
                      child: Image.asset("assets/naverBlogLogo.png"))),
              Spacer(),
              Container(
                margin: EdgeInsets.all(5),
                width: 1,
                height: 40,
                color: Colors.black54,
              ),
              Spacer(),
              Container(
                  width: 70, child: Image.asset("assets/giAppDownload.png")),
              Spacer(),
              Container(
                margin: EdgeInsets.all(5),
                width: 1,
                height: 40,
                color: Colors.black54,
              ),
              Spacer(),
              Container(
                width: 80,
                height: 40,
                child: ElevatedButton(
                  child: Text(
                    "상담신청",
                    style: TextStyle(
                        fontFamily: "Jalnan",
                        fontSize: 10,
                        color: Palette.white),
                  ),
                  onPressed: () {
                    MenuUtil.push(context, SchoolConsultationPage());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Palette.deepGreen,
                    foregroundColor: Palette.black,
                  ),
                ),
              )
            ],
          ),

          SizedBox(
            height: 10,
          ),

          Row(
            children: [
              Expanded(
                flex: 3,
                child: InkWell(
                  child: Container(height: 55, child: Image.asset("assets/middleOnlineLink.png")),
                  onTap: () async {
                    UrlUtil.open('http://gienglish.theclip.net/');
                  },
                ),
              ),
              Container(
                margin: EdgeInsets.all(5),
                width: 0.5,
                height: 40,
                color: Palette.mainGrey,
              ),
              Expanded(
                flex: 3,
                child: InkWell(
                  child: Container(height: 55,child: Image.asset("assets/eleOnlineLink.png")),
                  onTap: () async {
                    UrlUtil.open('https://www.trophy9.com/account/account.do?stdcmd=sign&url=%2Fdefault%2Edo%3F');
                  },
                ),
              ),
              SizedBox(width: 20,)
            ],
          ),
        ],
      ),
    );
  }

  Widget mobileBulletinBoard() {
    return Container(
      color: Colors.white,
      margin: EdgeInsets.only(left: 20, right: 20),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Palette.mainLightGrey, width: 3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  child: TextButton(
                    child: Text(
                      "Notice Board",
                      style:
                      TextStyle(color: Palette.black, fontFamily: "Jalnan"),
                    ),
                    onPressed: () {},
                  ),
                  height: 50,
                  decoration: BoxDecoration(
                    color: Palette.mainLightGrey,
                    border: Border.all(color: Palette.mainLightGrey, width: 3),
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18)),
                  ),
                ),
                Container(
                  color: Colors.white,
                  alignment: Alignment.topLeft,
                  padding: EdgeInsets.all(20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            style: TextStyle(
                                color: Palette.black,
                                fontFamily: "NotoSansKR",
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                            "글림아일랜드 소식"),
                        WidgetUtil.myDivider(),
                        Text(
                            style: TextStyle(
                                color: Palette.black,
                                fontFamily: "NotoSansKR",
                                fontWeight: FontWeight.normal,
                                fontSize: 14),
                            "* 글림아일랜드 2024년 신학기 개강 일정 :\n"
                                "- 월수금반 : 3월 6일\n"
                                "- 화목반 : 3월 5일\n"
                                "* 신규 Prep(파닉스)반 2반 신설 및 중등부 신설"),]
                  ),
                ),
                Container(
                  color: Colors.white,
                  alignment: Alignment.topLeft,
                  padding: EdgeInsets.all(20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            style: TextStyle(
                                color: Palette.black,
                                fontFamily: "NotoSansKR",
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                            "글림아일랜드어학원 초등부 체험수업"),
                        WidgetUtil.myDivider(),
                        Text(
                            style: TextStyle(
                                color: Palette.black,
                                fontFamily: "NotoSansKR",
                                fontWeight: FontWeight.normal,
                                fontSize: 14),
                            "- 글림아일랜드의 모든 수업은 체험 수업이 가능합니다. "
                                "아이가 직접 수업을 참여해보고 결정할 수 있도록 해 주십시오.(일일 수강료 발생)"),]
                  ),
                ),
                Container(

                  alignment: Alignment.topLeft,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20),bottomRight: Radius.circular(20))),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            style: TextStyle(
                                color: Palette.black,
                                fontFamily: "NotoSansKR",
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                            "학원 차량 노선"),
                        WidgetUtil.myDivider(),
                        Text(
                            style: TextStyle(
                                color: Palette.black,
                                fontFamily: "NotoSansKR",
                                fontWeight: FontWeight.normal,
                                fontSize: 14),
                            "- 본원에서는 초등, 중등반 수업 스케줄에 따른 학원 차량을 "
                                "운행하며 자세한 내용은 상담시 차량 노선과 함께 제공합니다."),]
                  ),
                )
              ],
            ),
          ),
          SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Palette.mainLightGrey, width: 3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  child: TextButton(
                    child: Text(
                      "FAQ",
                      style:
                          TextStyle(color: Palette.black, fontFamily: "Jalnan"),
                    ),
                    onPressed: () {},
                  ),
                  height: 50,
                  decoration: BoxDecoration(
                    color: Palette.mainLightGrey,
                    border: Border.all(color: Palette.mainLightGrey, width: 3),
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18)),
                  ),
                ),
                Container(
                  color: Colors.white,
                  alignment: Alignment.topLeft,
                  padding: EdgeInsets.all(20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                            style: TextStyle(
                                color: Palette.black,
                                fontFamily: "NotoSansKR",
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                            "Q: 글림아일랜드 24년도 개강일은?"),
                        WidgetUtil.myDivider(),
                        Text(
                            style: TextStyle(
                                color: Palette.black,
                                fontFamily: "NotoSansKR",
                                fontWeight: FontWeight.normal,
                                fontSize: 14),
                            "A: 글림아일랜드 2024년 신학기 개강 일정 :\n"
                            "- 월수금반 : 3월 6일\n"
                            "- 화목반 : 3월 5일"),
                      ]),
                ),
                Container(
                  height: 1,
                  margin: EdgeInsets.only(right: 10, left: 10),
                ),
                Container(
                  color: Colors.white,
                  alignment: Alignment.topLeft,
                  padding: EdgeInsets.all(20),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            style: TextStyle(
                                color: Palette.black,
                                fontFamily: "NotoSansKR",
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                            "Q: 예비초, 초등, 중등부 각반 정원은 몇명인가요?"),
                        WidgetUtil.myDivider(),
                        Text(
                            style: TextStyle(
                                color: Palette.black,
                                fontFamily: "NotoSansKR",
                                fontWeight: FontWeight.normal,
                                fontSize: 14),
                            "A: 초등부, 중등부 정원은 한 반에 8명이며 bilingual 선생님께서 담임을 맡아 주실 것이고, "
                                "최소 주 1회 원어민 선생님 수업이 있습니다."),
                      ]),
                ),
                Container(
                  color: Colors.white,
                  height: 1,
                  margin: EdgeInsets.only(right: 10, left: 10),
                ),
                Container(
                  alignment: Alignment.topLeft,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(20),bottomRight: Radius.circular(20))),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            style: TextStyle(
                                color: Palette.black,
                                fontFamily: "NotoSansKR",
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                            "Q: 연령별로 반이 나뉘나요?"),
                        WidgetUtil.myDivider(),
                        Text(
                            style: TextStyle(
                                color: Palette.black,
                                fontFamily: "NotoSansKR",
                                fontWeight: FontWeight.normal,
                                fontSize: 14),
                            "A: 예비초, 초등부는 연령을 고려하되,\n"
                                "실력 테스트를 거친 후 레벨 별로 반 배정이 됩니다. 중등부는 연령과 실력에 따라 반 배정이 되며 학교도 되도록이면 통일합니다."),
                      ]),
                ),
              ],
            ),
          ),
          Container(height: 20)
        ],
      ),
    );
  }

// Widget menuListTile(String menu) {
//   return ListTile(
//     leading: Icon(Icons.event_note),
//     title: Text(menu),
//     trailing: Icon(
//       Icons.info_outline,
//       color: Palette.white,
//       size: 20,
//     ),
//     tileColor: Palette.mainMediumPurple,
//   );
// }

// Widget mobileMenuList() {
//   return Column(
//     children: [
//       menuListTile("About Gi어학원"),
//       menuListTile("Program"),
//       menuListTile("Curriculum"),
//       menuListTile("Community"),
//     ],
//   );
// }
}
