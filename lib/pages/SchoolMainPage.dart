import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gi_english_website/pages/SchoolCommunityNoticePage.dart';
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
        decoration: BoxDecoration(
          border: Border.all(color: Palette.lightestEarth, width: 10),
          // borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(alignment: Alignment.centerLeft, children: [
          Image.asset("assets/mainGateImageLightBlue.png"),
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
              margin: EdgeInsets.all(5),
              decoration: BoxDecoration(
                border: Border.all(color: Palette.lightestEarth, width: 1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                      flex: 1,
                      child: Container(
                        padding: EdgeInsets.only(left: 15),
                        child: Column(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Container(),
                            ),
                            Text(
                              "GLEAM ISLAND",
                              style: TextStyle(
                                fontFamily: "Jalnan",
                                fontSize: 15,
                                color: Palette.deepGreen,
                              ),
                              textAlign: TextAlign.left,
                            ),
                            Text(
                              "소식을 SNS에서 확인하세요!",
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                  color: Palette.black,
                                  fontFamily: "MaruBuri",
                                  fontWeight: FontWeight.normal,
                                  fontSize: 14),
                            ),
                            Expanded(
                              flex: 1,
                              child: Container(),
                            ),
                          ],
                        ),
                      )),
                  Expanded(
                      flex: 1,
                      child: Container(
                        alignment: Alignment.center,
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset("assets/instaLogo.png"),
                              SizedBox(height: 5),
                              MyWidget.schoolTextButton(
                                  "인스타 바로가기", Palette.black, 12)
                            ]),
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
                        alignment: Alignment.center,
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset("assets/youtubeLogo.png"),
                              SizedBox(height: 5),
                              MyWidget.schoolTextButton(
                                  "유투브 바로가기", Palette.black, 12)
                            ]),
                      )),
                ],
              ),
            ),
          ),
          Expanded(
              flex: 1,
              child: Container(
                margin: EdgeInsets.all(5),
                decoration: BoxDecoration(
                  border: Border.all(color: Palette.lightestEarth, width: 1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: EdgeInsets.only(left: 15, top: 5, bottom: 5),
                        alignment: Alignment.center,
                        child: Image.asset("assets/giAppBannerFinal.png"),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Container(
                        height: 100,
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
                      flex: 3,
                      child: Container(
                        margin: EdgeInsets.all(10),
                        child: InkWell(
                          child: Image.asset("assets/trophyLogo.png"),
                          onTap: () async {
                            UrlUtil.open('https://www.trophy9.com/');
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
    double eachBoardHeight = 450;

    return Container(
      padding: EdgeInsets.only(top: 20, bottom: 20),
      color: Palette.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Spacer(),
          Expanded(
            flex: 5,
            child: Container(
              decoration: BoxDecoration(
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
                      alignment: Alignment.topLeft,
                      margin: EdgeInsets.all(20),
                      child: Container(
                        child: Text(
                            style: TextStyle(
                                color: Palette.black,
                                fontFamily: "Maruburi",
                                fontWeight: FontWeight.normal,
                                fontSize: 14),
                            "글림아일랜드 어학원 초등부 (8세~13세) 입학설명회 : \n"
                            "2023년 2월 9일~10일 \n"
                            "Gi 초등부 1차 입학설명회가 2월 9일부터 이틀간 예정되어 있으니, 학부모님들의 많은 관심과 참여 부탁드립니다! :) \n"
                            "(장소 및 상세스케줄 곧 업데이트 예정, 준공 이후 주소 확정)"),
                      ),
                    ),
                    Container(
                      height: 1,
                      color: Colors.black26,
                      margin: EdgeInsets.only(right: 10, left: 10),
                    ),
                    Container(
                      alignment: Alignment.topLeft,
                      padding: EdgeInsets.all(20),
                      child: Text(
                          style: TextStyle(
                              color: Palette.black,
                              fontFamily: "MaruBuri",
                              fontWeight: FontWeight.normal,
                              fontSize: 14),
                          "글림아일랜드 어학원 유치부 (5세~7세) 입학설명회 : \n"
                          "2023년 2월 9일~10일 \n"
                          "Gi 유치부 1차 입학설명회가 2월 9일부터 이틀간 예정되어 있으니, 학부모님들의 많은 관심과 참여 부탁드립니다! :) \n"
                          "(장소 및 상세스케줄 곧 업데이트 예정, 준공 이후 주소 확정)"),
                    ),
                    Container(
                      height: 1,
                      color: Colors.black26,
                      margin: EdgeInsets.only(right: 10, left: 10),
                    ),
                    Container(
                      alignment: Alignment.topLeft,
                      padding: EdgeInsets.all(20),
                      child: Text(
                          style: TextStyle(
                              color: Palette.black,
                              fontFamily: "MaruBuri",
                              fontWeight: FontWeight.normal,
                              fontSize: 14),
                          "글림아일랜드 어학원 입주 예정지인, 다율동 '태산 W 타워' 준공 1월 초순 예정"),
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
                      alignment: Alignment.topLeft,
                      padding: EdgeInsets.all(20),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                                style: TextStyle(
                                    color: Palette.black,
                                    fontFamily: "MaruBuri",
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14),
                                "Q: 글림아일랜드 어학원 정식 오픈일이 언제일까요?"),
                            WidgetUtil.myDivider(),
                            Text(
                                style: TextStyle(
                                    color: Palette.black,
                                    fontFamily: "MaruBuri",
                                    fontWeight: FontWeight.normal,
                                    fontSize: 14),
                                "A: 글림아일랜드 어학원 예정지인 다율동 태산 W 타워의 준공이 12월 중순 준공 예정이므로, 약 한달의 인테리어 기간 이후인 1월 중순 오픈 예정이며, 이때부터 현장에서 입학설명회가 열릴 예정입니다.^^"),
                          ]),
                    ),
                    Container(
                      height: 1,
                      margin: EdgeInsets.only(right: 10, left: 10),
                    ),
                    Container(
                      alignment: Alignment.topLeft,
                      padding: EdgeInsets.all(20),
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                style: TextStyle(
                                    color: Palette.black,
                                    fontFamily: "MaruBuri",
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14),
                                "Q: 유치부 정원은 몇 명이며 몇 개 반이 있나요?"),
                            WidgetUtil.myDivider(),
                            Text(
                                style: TextStyle(
                                    color: Palette.black,
                                    fontFamily: "MaruBuri",
                                    fontWeight: FontWeight.normal,
                                    fontSize: 14),
                                "A: 유치부 정원은 한 반에 6~8명이며, 총 최대 6반이 운영될 예정입니다. bilingual 선생님께서 담임을 맡아 주실 것이고, 각반을 담당하는 원어민 선생님이 배정됩니다."),
                          ]),
                    ),
                    Container(
                      height: 1,
                      margin: EdgeInsets.only(right: 10, left: 10),
                    ),
                    Container(
                      alignment: Alignment.topLeft,
                      padding: EdgeInsets.all(20),
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                style: TextStyle(
                                    color: Palette.black,
                                    fontFamily: "MaruBuri",
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14),
                                "Q: 초등부는 연령별로 반이 나뉘나요?"),
                            WidgetUtil.myDivider(),
                            Text(
                                style: TextStyle(
                                    color: Palette.black,
                                    fontFamily: "MaruBuri",
                                    fontWeight: FontWeight.normal,
                                    fontSize: 14),
                                "A: 초등부는 연령을 고려하되, 실력 테스트를 거친 후 레벨 별로 반 배정이 됩니다."),
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
            SizedBox(height: 150, child: urlMenu()),
            Container(height: 30, color: Palette.white),
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
            mobileMainImage(),
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
              Image.asset("assets/instaLogo.png"),
              Spacer(),
              Container(
                margin: EdgeInsets.all(5),
                width: 1,
                height: 40,
                color: Colors.black54,
              ),
              Spacer(),
              Image.asset("assets/youtubeLogo.png"),
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
          Container(
            alignment: Alignment.center,
            height: 90,
            margin: EdgeInsets.all(10),
            child: InkWell(
              child: Image.asset("assets/trophyLogo.png"),
              onTap: () async {
                UrlUtil.open('https://www.trophy9.com/');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget mobileBulletinBoard() {
    return Container(
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
                    child: Text("Notice Board",
                        style: TextStyle(
                            color: Palette.black, fontFamily: "Jalnan")),
                    onPressed: () {
                      // MenuUtil.push(context, SchoolCommunityNoticePage());
                    },
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
                  alignment: Alignment.topLeft,
                  padding: EdgeInsets.all(20),
                  child: Text(
                      style: TextStyle(
                          color: Palette.black,
                          fontFamily: "MaruBuri",
                          fontWeight: FontWeight.normal,
                          fontSize: 14),
                      "글림아일랜드 어학원 초등부 (8세~13세) 입학설명회 : 2023년 2월 9일~10일 / \n"
                      "Gi 초등부 1차 입학설명회가 2월 9일부터 이틀간 예정되어 있으니, \n"
                      "학부모님들의 많은 관심과 참여 부탁드립니다! :) \n(장소 및 상세스케줄 곧 업데이트 예정, 준공 이후 주소 확정)"),
                ),
                Container(
                  height: 1,
                  color: Colors.black26,
                  margin: EdgeInsets.only(right: 10, left: 10),
                ),
                Container(
                  alignment: Alignment.topLeft,
                  padding: EdgeInsets.all(20),
                  child: Text(
                      style: TextStyle(
                          color: Palette.black,
                          fontFamily: "MaruBuri",
                          fontWeight: FontWeight.normal,
                          fontSize: 14),
                      "글림아일랜드 어학원 유치부 (5세~7세) 입학설명회 : 2023년 2월 9일~10일 / \n"
                      "Gi 유치부 1차 입학설명회가 2월 9일부터 이틀간 예정되어 있으니, 학부모님들의 많은 관심과 참여 부탁드립니다! :) (장소 및 상세스케줄 곧 업데이트 예정, 준공 이후 주소 확정)"),
                ),
                Container(
                  height: 1,
                  color: Colors.black26,
                  margin: EdgeInsets.only(right: 10, left: 10),
                ),
                Container(
                  alignment: Alignment.topLeft,
                  padding: EdgeInsets.all(20),
                  child: Text(
                      style: TextStyle(
                          color: Palette.black,
                          fontFamily: "MaruBuri",
                          fontWeight: FontWeight.normal,
                          fontSize: 14),
                      "글림아일랜드 어학원 입주 예정지인, 다율동 '태산 W 타워' 준공 1월 초순 예정"),
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
                  alignment: Alignment.topLeft,
                  padding: EdgeInsets.all(20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            style: TextStyle(
                                color: Palette.black,
                                fontFamily: "MaruBuri",
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                            "Q: 글림아일랜드 어학원 정식 오픈일이 언제일까요?"),
                        WidgetUtil.myDivider(),
                        Text(
                            style: TextStyle(
                                color: Palette.black,
                                fontFamily: "MaruBuri",
                                fontWeight: FontWeight.normal,
                                fontSize: 14),
                            "A: 글림아일랜드 어학원 예정지인 다율동 태산 W 타워의 준공이 1월 초순 준공 예정이므로, 약 한달의 인테리어 기간 이후인 1월 중순 오픈 예정이며, 이때부터 현장에서 입학설명회가 열릴 예정입니다.^^"),
                      ]),
                ),
                Container(
                  height: 1,
                  margin: EdgeInsets.only(right: 10, left: 10),
                ),
                Container(
                  alignment: Alignment.topLeft,
                  padding: EdgeInsets.all(20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            style: TextStyle(
                                color: Palette.black,
                                fontFamily: "MaruBuri",
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                            "Q: 유치부 정원은 몇 명이며 몇 개 반이 있나요?"),
                        WidgetUtil.myDivider(),
                        Text(
                            style: TextStyle(
                                color: Palette.black,
                                fontFamily: "MaruBuri",
                                fontWeight: FontWeight.normal,
                                fontSize: 14),
                            "A: 유치부 정원은 한 반에 6~8명이며, 총 최대 6반이 운영될 예정입니다. bilingual 선생님께서 담임을 맡아 주실 것이고, 각반을 담당하는 원어민 선생님이 배정됩니다."),
                      ]),
                ),
                Container(
                  height: 1,
                  margin: EdgeInsets.only(right: 10, left: 10),
                ),
                Container(
                  alignment: Alignment.topLeft,
                  padding: EdgeInsets.all(20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            style: TextStyle(
                                color: Palette.black,
                                fontFamily: "MaruBuri",
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                            "Q: 초등부는 연령별로 반이 나뉘나요?"),
                        WidgetUtil.myDivider(),
                        Text(
                            style: TextStyle(
                                color: Palette.black,
                                fontFamily: "MaruBuri",
                                fontWeight: FontWeight.normal,
                                fontSize: 14),
                            "A: 초등부는 연령을 고려하되, 실력 테스트를 거친 후 레벨 별로 반 배정이 됩니다."),
                      ]),
                ),
              ],
            ),
          ),
          SizedBox(height: 20)
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
