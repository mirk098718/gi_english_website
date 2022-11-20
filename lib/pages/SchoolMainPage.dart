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
        if(value==hiddenMenu) {
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
                onPressed: () {MenuUtil.push(context, SchoolConsultationPage());},
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
                              style: TextStyle(color: Palette.black, fontFamily: "MaruBuri", fontWeight: FontWeight.normal, fontSize: 12),
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
                      flex: 2,
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
                      flex: 2,
                      child: Container(
                        alignment: Alignment.center,
                        child: Container(
                            padding: EdgeInsets.all(15),
                            child: Image.asset("assets/giKidsWeekendLogo.png")),
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
    return Container(
      padding: EdgeInsets.only(top: 20, bottom: 20),
      color: Palette.white,
      child: Row(
        children: [
          Expanded(flex: 1, child: SizedBox()),
          Expanded(
            flex: 4,
            child: Container(
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
                        MenuUtil.push(context, SchoolCommunityNoticePage());
                      },
                    ),
                    height: 50,
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
                    padding: EdgeInsets.all(20),
                    child: Text(style: TextStyle(color: Palette.black, fontFamily: "MaruBuri", fontWeight: FontWeight.normal, fontSize: 12),
                        "Gi 글림아일랜드 어학원 유치부(5세~7세) 입학설명회 2023년 2월 1일~3일 Gi 유치부 소수정예반 입학 설명회가 예정되어 있으니 학부모님들의 많은 관심과 참여 부탁드립니다! :) 입학설명회 상세 스케줄 및 예약문의: "),
                  ),
                  Divider(),
                  Container(
                    padding: EdgeInsets.all(20),
                    child: Text(style: TextStyle(color: Palette.black, fontFamily: "MaruBuri", fontWeight: FontWeight.normal, fontSize: 12),
                        "Gi 글림아일랜드 어학원 유치부(5세~7세) 입학설명회 2023년 2월 1일~3일 Gi 유치부 소수정예반 입학 설명회가 예정되어 있으니 학부모님들의 많은 관심과 참여 부탁드립니다! :) 입학설명회 상세 스케줄 및 예약문의: "),
                  )
                ],
              ),
            ),
          ),
          Expanded(flex: 1, child: SizedBox()),
          Expanded(
            flex: 4,
            child: Container(
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
                        "QnA",
                        style: TextStyle(
                            color: Palette.black, fontFamily: "Jalnan"),
                      ),
                      onPressed: () {},
                    ),
                    height: 50,
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
                    padding: EdgeInsets.all(20),
                    child: Text(style: TextStyle(color: Palette.black, fontFamily: "MaruBuri", fontWeight: FontWeight.normal, fontSize: 12),
                        "Gi 글림아일랜드 어학원 유치부(5세~7세) 입학설명회 2023년 2월 1일~3일 Gi 유치부 소수정예반 입학 설명회가 예정되어 있으니 학부모님들의 많은 관심과 참여 부탁드립니다! :) 입학설명회 상세 스케줄 및 예약문의: "),
                  ),
                  Divider(),
                  Container(
                    padding: EdgeInsets.all(20),
                    child: Text(style: TextStyle(color: Palette.black, fontFamily: "MaruBuri", fontWeight: FontWeight.normal, fontSize: 12),
                        "Gi 글림아일랜드 어학원 유치부(5세~7세) 입학설명회 2023년 2월 1일~3일 Gi 유치부 소수정예반 입학 설명회가 예정되어 있으니 학부모님들의 많은 관심과 참여 부탁드립니다! :) 입학설명회 상세 스케줄 및 예약문의: "),
                  )
                ],
              ),
            ),
          ),
          Expanded(flex: 1, child: SizedBox()),
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
            SizedBox(height: 473, child: bulletinBoard()),
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
                  width: double.maxFinite,
                  height: 50,
                  child: TextButton(
                    child: Text("Notice Board",
                        style: TextStyle(
                            color: Palette.black, fontFamily: "Jalnan")),
                    onPressed: () {},
                  ),
                  decoration: BoxDecoration(
                    color: Palette.mainLightGrey,
                    border: Border.all(color: Palette.mainLightGrey, width: 3),
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18)),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(20),
                  child: Text(style: TextStyle(color: Palette.black, fontFamily: "MaruBuri", fontWeight: FontWeight.normal, fontSize: 12),
                      "Gi 글림아일랜드 어학원 유치부(5세~7세) 입학설명회 2023년 2월 1일~3일 Gi 유치부 소수정예반 입학 설명회가 예정되어 있으니\n"
                      "학부모님들의 많은 관심과 참여 부탁드립니다! :) 입학설명회 상세 스케줄 및 예약문의: "),
                ),
                Divider(),
                Container(
                  padding: EdgeInsets.all(20),
                  child: Text(style: TextStyle(color: Palette.black, fontFamily: "MaruBuri", fontWeight: FontWeight.normal, fontSize: 12),
                      "Gi 글림아일랜드 어학원 유치부(5세~7세) 입학설명회 2023년 2월 1일~3일 Gi 유치부 소수정예반 입학 설명회가 예정되어 있으니\n"
                      " 학부모님들의 많은 관심과 참여 부탁드립니다! :) 입학설명회 상세 스케줄 및 예약문의: "),
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
                  width: double.maxFinite,
                  height: 50,
                  child: TextButton(
                    child: Text(
                      "QnA",
                      style:
                          TextStyle(color: Palette.black, fontFamily: "Jalnan"),
                    ),
                    onPressed: () {},
                  ),
                  decoration: BoxDecoration(
                    color: Palette.mainLightGrey,
                    border: Border.all(color: Palette.mainLightGrey, width: 3),
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18)),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(20),
                  child: Text(style: TextStyle(color: Palette.black, fontFamily: "MaruBuri", fontWeight: FontWeight.normal, fontSize: 12),
                      "Gi 글림아일랜드 어학원 유치부(5세~7세) 입학설명회 2023년 2월 1일~3일 Gi 유치부 소수정예반 입학 설명회가 예정되어 있으니 학부모님들의 많은 관심과 참여 부탁드립니다! :) 입학설명회 상세 스케줄 및 예약문의: "),
                ),
                Divider(),
                Container(
                  padding: EdgeInsets.all(20),
                  child: Text(style: TextStyle(color: Palette.black, fontFamily: "MaruBuri", fontWeight: FontWeight.normal, fontSize: 12),
                      "Gi 글림아일랜드 어학원 유치부(5세~7세) 입학설명회 2023년 2월 1일~3일 Gi 유치부 소수정예반 입학 설명회가 예정되어 있으니 학부모님들의 많은 관심과 참여 부탁드립니다! :) 입학설명회 상세 스케줄 및 예약문의: "),
                )
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
