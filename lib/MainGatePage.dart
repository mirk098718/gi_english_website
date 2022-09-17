import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gi_english_website/admin/page/AdminLoginPage.dart';
import 'package:gi_english_website/cafePages/CafeMainPage.dart';
import 'package:gi_english_website/pages/SchoolMainPage.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/Palette.dart';

class MainGatePage extends StatefulWidget {
  const MainGatePage({Key? key}) : super(key: key);

  @override
  _MainGatePageState createState() => _MainGatePageState();
}

class _MainGatePageState extends State<MainGatePage> {
  final controller = ScrollController();

  //함수 -> 기능.

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
    return Scaffold(
        body: Container(
      decoration: BoxDecoration(
          image: DecorationImage(
        fit: BoxFit.cover,
        image: AssetImage("assets/mainGateImage.png"),
      )),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Stack(
          alignment: Alignment.center,
          children: [
            leftWidget(),
            rightWidget(),
            Positioned(top: 20, right: 20, child: moveAdminButton()),
          ],
        ),
      ),
    ));
  }

  Widget mobileUi() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            fit: BoxFit.cover,
            image: AssetImage("assets/mobileMainGateImage.png"),
          ),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Stack(children: [
            Positioned(top: 20, right: 20, child: moveAdminButton()),
            Container(
              alignment: Alignment.bottomCenter,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  mobileSchoolEnterWidget(),
                  SizedBox(
                    width: 20,
                  ),
                  mobileCafeEnterWidget(),
                ],
              ),
            ),
            Container(
              height: MediaQuery.of(context).size.height,
              padding: EdgeInsets.only(bottom: 10),
              alignment: Alignment.bottomCenter,
              child: Text("ⓒ 글림아일랜드교육", style: TextStyle(color: Palette.white)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget enterButtonForSchool() {
    return ElevatedButton(
        style: ElevatedButton.styleFrom(
            primary: Palette.white,
            onPrimary: Palette.black,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
                side: BorderSide(color: Palette.black)),
            minimumSize: Size(150, 50)),
        onPressed: () {
          MenuUtil.push(context, SchoolMainPage());
        },
        child: Text("Enter",
            style: TextStyle(fontFamily: 'Jalnan', fontSize: 15)));
  }

  Widget enterButtonForCafe() {
    return ElevatedButton(
        style: ElevatedButton.styleFrom(
            primary: Palette.white,
            onPrimary: Palette.black,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
                side: BorderSide(color: Palette.black)),
            minimumSize: Size(150, 50)),
        onPressed: () {
          MenuUtil.push(context, CafeMainPage());
        },
        child: Text(
          "Enter",
          style: TextStyle(fontFamily: 'Jalnan', fontSize: 15),
        ));
  }

  Widget mainImageWidget() {
    return Image.asset("assets/mainGateImage.png");
  }

  Widget leftWidget() {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      padding: EdgeInsets.only(left: 100),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 20,
          ),
          Container(
              padding: EdgeInsets.only(left: 8),
              height: 50,
              child: Image.asset("assets/schoolLogoWithColor.png")),
          SizedBox(
            height: 20,
          ),
          SizedBox(width: 200, child: enterButtonForSchool()),
          SizedBox(
            height: 20,
          ),
        ],
      ),
    );
  }

  Widget rightWidget() {
    return Container(
      padding: EdgeInsets.only(right: 100),
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            height: 70,
            child: Image.asset("assets/cafeLogoWithColor.png"),
          ),
          SizedBox(
            height: 20,
          ),
          SizedBox(width: 200, child: enterButtonForCafe()),
          SizedBox(
            height: 20,
          ),
        ],
      ),
    );
  }

  Widget mobileSchoolEnterWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 10,
        ),
        Container(
            padding: EdgeInsets.only(top: 10, left: 40),
            height: 35,
            width: 140,
            child: Image.asset("assets/schoolLogoWithColor.png")),
        SizedBox(
          height: 15,
        ),
        Row(children: [
          SizedBox(width: 40),
          SizedBox(width: 100, child: enterButtonForSchool())
        ]),
        SizedBox(
          height: 20,
        ),
      ],
    );
  }

  Widget mobileCafeEnterWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.only(top: 10, right: 40),
          height: 45,
          width: 140,
          child: Image.asset("assets/cafeLogoWithColor.png"),
        ),
        SizedBox(
          height: 15,
        ),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          SizedBox(width: 100, child: enterButtonForCafe()),
          SizedBox(
            width: 40,
          )
        ]),
        SizedBox(
          height: 20,
        ),
      ],
    );
  }

  Widget moveAdminButton() {
    return TextButton(
        onPressed: () async {
          MenuUtil.push(context, AdminLoginPage());
        },
        child: Text(
          "Admin",
          style: TextStyle(color: Palette.black),
        ));
  }
}
/*
Stack(
  alignment: Alignment.center,
  children: [
  ],
),
 */
