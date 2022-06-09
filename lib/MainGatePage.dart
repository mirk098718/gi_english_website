import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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

  //대문 칼럼 이용 그림쪼개기
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
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
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
        ),
      ),
    );
  }

  Widget enterButtonForSchool() {
    return ElevatedButton(
        style: ElevatedButton.styleFrom(
            primary: Palette.mainMediumPurple,
            onPrimary: Palette.black,
            minimumSize: Size(200, 50)),
        onPressed: () {
          MenuUtil.push(context, SchoolMainPage());
        },
        child: Text("Enter",
            style: TextStyle(fontFamily: 'Jalnan', fontSize: 15)));
  }

  Widget enterButtonForCafe() {
    return ElevatedButton(
        style: ElevatedButton.styleFrom(
            primary: Palette.greenishLime,
            onPrimary: Palette.black,
            minimumSize: Size(200, 50)),
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
              height: 50, child: Image.asset("assets/schoolLogoWithColor.png")),
          SizedBox(
            height: 20,
          ),
          enterButtonForSchool(),
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
          enterButtonForCafe(),
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
          height: 20,
        ),
        Container(
            height: 50, child: Image.asset("assets/schoolLogoWithColor.png")),
        SizedBox(
          height: 20,
        ),
        enterButtonForSchool(),
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
          height: 70,
          child: Image.asset("assets/cafeLogoWithColor.png"),
        ),
        SizedBox(
          height: 20,
        ),
        enterButtonForCafe(),
        SizedBox(
          height: 20,
        ),
      ],
    );
  }
}
/*
Stack(
  alignment: Alignment.center,
  children: [
  ],
),
 */
