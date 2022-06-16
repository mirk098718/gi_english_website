import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gi_english_website/cafePages/CafeCommunityNoticePage.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/widget/MobileCafeLayout.dart';
import 'package:gi_english_website/widget/WebCafeLayout.dart';

import 'CafeReservationPage.dart';

class CafeMainPage extends StatefulWidget {
  const CafeMainPage({Key? key}) : super(key: key);

  @override
  _CafeMainPageState createState() => _CafeMainPageState();
}

class _CafeMainPageState extends State<CafeMainPage> {
  @override
  Widget build(BuildContext context) {
    MediaQueryData mediaQueryData = MediaQuery.of(context);
    Size size = mediaQueryData.size;
    double width = size.width;
    if (width > 768) {
      return desktopUi();
    } else {
      return mobileUi();
    }
  }

  Widget desktopUi() {
    return WebCafeLayout(content: scrollView());
  }

  Widget mobileUi() {
    return MobileCafeLayout(content: mobileScrollView());
  }

  Widget scrollView() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Column(
        children: [
          mainImage(),
          SizedBox(height: 126, child: urlMenu()),
          Container(height: 30, color: Palette.white),
          SizedBox(height: 473, child: bulletinBoard()),
          SizedBox(height: 213, child: MyWidget.cafeFooter()),
        ],
      ),
    );
  }

  Widget mainImage() {
    return Container(
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Image.asset("assets/cafeMainImage.png"),
          Container(
            padding: EdgeInsets.only(left: 20, bottom: 50),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 500, child: Image.asset("assets/cafeMainCatch.png")),
                Container(
                  width: 150,
                  height: 50,
                  child: ElevatedButton(
                    child: Text(
                      "예약문의",
                      style:
                          TextStyle(fontFamily: "Jalnan", color: Palette.white),
                    ),
                    onPressed: () {
                      MenuUtil.push(context, CafeReservationPage());
                    },
                    style: ElevatedButton.styleFrom(
                      primary: Palette.mainLime,
                      onPrimary: Palette.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget urlMenu() {
    return Container(
      color: Palette.greyTenPer,
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Expanded(
                    flex: 2,
                    child: Container(
                      padding: EdgeInsets.only(left: 10, top: 5, bottom: 5),
                      alignment: Alignment.center,
                      color: Palette.greyTenPer,
                      child: Image.asset("assets/snsArrow.png"),
                      // Column(
                      //         mainAxisAlignment: MainAxisAlignment.center,
                      //         children: [
                      //           // Text("GLEAM ISLAND",style: TextStyle(fontFamily: "Jalnan", fontSize: 15, color: Palette.mainMediumPurple,),textAlign: TextAlign.center,),
                      //           // Text("소식을 SNS에서 \n 확인하세요!",textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                      //         ],
                      //       ),
                    )),
                Expanded(
                    flex: 1,
                    child: Container(
                      alignment: Alignment.center,
                      color: Palette.greyTenPer,
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset("assets/instaLogo.png"),
                            SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () {},
                              child: Text(
                                "인스타 바로가기",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontFamily: "Jalnan",
                                    color: Palette.white,
                                    fontSize: 12),
                              ),
                              style: ElevatedButton.styleFrom(
                                primary: Palette.mainMediumPurple,
                                onPrimary: Palette.black,
                              ),
                            )
                          ]),
                    )),
                Container(
                  margin: EdgeInsets.all(5),
                  width: 1,
                  height: 40,
                  color: Colors.black54,
                ),
                Expanded(
                    flex: 1,
                    child: Container(
                      alignment: Alignment.center,
                      color: Palette.greyTenPer,
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset("assets/youtubeLogo.png"),
                            SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () {},
                              child: Text(
                                "유튜브 바로가기",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontFamily: "Jalnan",
                                    color: Palette.white,
                                    fontSize: 12),
                              ),
                              style: ElevatedButton.styleFrom(
                                primary: Palette.mainMediumPurple,
                                onPrimary: Palette.black,
                              ),
                            )
                          ]),
                    )),
              ],
            ),
          ),
          Expanded(
              flex: 1,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: EdgeInsets.only(left: 10, top: 5, bottom: 5),
                      alignment: Alignment.center,
                      color: Palette.greyTenPer,
                      child: Image.asset("assets/giAppBanner.png"),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      height: 100,
                      alignment: Alignment.center,
                      color: Palette.greyTenPer,
                      child: Image.asset("assets/giAppDownload.png"),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.all(5),
                    width: 1,
                    height: 40,
                    color: Colors.black54,
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      alignment: Alignment.center,
                      color: Palette.greyTenPer,
                    ),
                  ),
                ],
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
                      onPressed: () {MenuUtil.push(context, CafeCommunityNoticePage());},
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
                    padding: EdgeInsets.all(20),
                    child: Text(
                        "Gi 글림아일랜드 어학원 유치부(5세~7세) 입학설명회 2023년 2월 1일~3일 Gi 유치부 소수정예반 입학 설명회가 예정되어 있으니 학부모님들의 많은 관심과 참여 부탁드립니다! :) 입학설명회 상세 스케줄 및 예약문의: "),
                  ),
                  Divider(),
                  Container(
                    padding: EdgeInsets.all(20),
                    child: Text(
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
                    padding: EdgeInsets.all(20),
                    child: Text(
                        "Gi 글림아일랜드 어학원 유치부(5세~7세) 입학설명회 2023년 2월 1일~3일 Gi 유치부 소수정예반 입학 설명회가 예정되어 있으니 학부모님들의 많은 관심과 참여 부탁드립니다! :) 입학설명회 상세 스케줄 및 예약문의: "),
                  ),
                  Divider(),
                  Container(
                    padding: EdgeInsets.all(20),
                    child: Text(
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

  //Mobile

  Widget mobileScrollView() {
    return SingleChildScrollView(
      child: Container(
        child: Column(
          children: [
            mobileMainImage(),
            // mobileMenuList(),
            mobileUrlMenu(),
            mobileBulletinBoard(),
            SizedBox(height: 51, child: MyWidget.mobileCafeFooter())
          ],
        ),
      ),
    );
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
                    "예약문의",
                    style: TextStyle(
                        fontFamily: "Jalnan",
                        fontSize: 10,
                        color: Palette.white),
                  ),
                  onPressed: () {
                    MenuUtil.push(context, CafeReservationPage());
                  },
                  style: ElevatedButton.styleFrom(
                    primary: Palette.mainLime,
                    onPrimary: Palette.black,
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
                  child: Text(
                      "Gi 글림아일랜드 어학원 유치부(5세~7세) 입학설명회 2023년 2월 1일~3일 Gi 유치부 소수정예반 입학 설명회가 예정되어 있으니\n"
                      "학부모님들의 많은 관심과 참여 부탁드립니다! :) 입학설명회 상세 스케줄 및 예약문의: "),
                ),
                Divider(),
                Container(
                  padding: EdgeInsets.all(20),
                  child: Text(
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
                  child: Text(
                      "Gi 글림아일랜드 어학원 유치부(5세~7세) 입학설명회 2023년 2월 1일~3일 Gi 유치부 소수정예반 입학 설명회가 예정되어 있으니 학부모님들의 많은 관심과 참여 부탁드립니다! :) 입학설명회 상세 스케줄 및 예약문의: "),
                ),
                Divider(),
                Container(
                  padding: EdgeInsets.all(20),
                  child: Text(
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

  Widget mobileMainImage() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [Container(
        child: Image.asset("assets/cafeMainImage.png")),
        Container(
          margin: EdgeInsets.all(20),
          width: 150,
          height: 40,
          child: ElevatedButton(
            child: Text(
              "예약문의",
              style:
              TextStyle(fontFamily: "Jalnan", color: Palette.white),
            ),
            onPressed: () {
              MenuUtil.push(context, CafeReservationPage());
            },
            style: ElevatedButton.styleFrom(
              primary: Palette.mainLime,
              onPrimary: Palette.black,
            ),


          ),
        ),],
    );
  }
}
