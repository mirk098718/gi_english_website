import 'package:flutter/material.dart';
import 'package:gi_english_website/pages/SchoolConsultationPage.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/widget/ButtonState.dart';
import 'package:gi_english_website/widget/MobileSchoolLayout.dart';
import 'package:gi_english_website/widget/WebSchoolLayout.dart';

import '../util/WidgetUtil.dart';

class SchoolGalleryPage extends StatefulWidget {
  const SchoolGalleryPage({Key? key}) : super(key: key);

  @override
  _SchoolGalleryPageState createState() => _SchoolGalleryPageState();
}

class _SchoolGalleryPageState extends State<SchoolGalleryPage> {
  List<ButtonState> buttonStateList = [
    //ButtonState("Notice Board", BehaviorColor.colorOnDefault, SchoolCommunityNoticePage()),
    ButtonState("Gallery", BehaviorColor.colorOnClick, SchoolGalleryPage()),
    ButtonState("입학상담", BehaviorColor.colorOnDefault, SchoolConsultationPage()),
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
              : (i == 0
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

  Widget content() {
    return Container(
      padding: EdgeInsets.all(20),
      color: Palette.white,
      child: Row(children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Gallery",
                style: TextStyle(fontFamily: "Jalnan", fontSize: 20),
              ),
              WidgetUtil.myDivider(),
              SizedBox(
                height: 30,
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Container(
                      color: Palette.grey100,
                      width: 200,
                      height: 200,
                      child: Image.asset("assets/lobby1.jpeg",
                          fit: BoxFit.fitHeight),
                    ),
                    SizedBox(
                      width: 20,
                    ),
                    Container(
                      color: Palette.grey100,
                      width: 200,
                      height: 200,
                      child: Image.asset("assets/doors.jpeg",
                          fit: BoxFit.fitWidth),
                    ),
                    SizedBox(
                      width: 20,
                    ),
                    Container(
                      color: Palette.grey100,
                      width: 200,
                      height: 200,
                      child: Image.asset("assets/lobby.jpeg",
                          fit: BoxFit.fitHeight),
                    ),
                    SizedBox(
                      width: 20,
                    ),
                    Container(
                      color: Palette.grey100,
                      width: 200,
                      height: 200,
                      child: Image.asset("assets/classroom.jpeg",
                          fit: BoxFit.fitWidth),
                    )
                  ],
                ),
              ),
              SizedBox(
                height: 20,
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Container(
                      color: Palette.grey100,
                      width: 200,
                      height: 200,
                      child: Image.asset("assets/mainEnterance.jpeg",
                          fit: BoxFit.fitWidth),
                    ),
                    SizedBox(
                      width: 20,
                    ),
                    Container(
                        color: const Color.fromRGBO(243, 244, 246, 1),
                        width: 200,
                        height: 200,
                        child: Image.asset("assets/gleamIslandLogo.jpeg")),
                    SizedBox(
                      width: 20,
                    ),
                    Container(
                      color: const Color.fromRGBO(243, 244, 246, 1),
                      width: 200,
                      height: 200,
                      child: Image.asset("assets/car1.jpeg",
                          fit: BoxFit.fitHeight),
                    ),
                    SizedBox(
                      width: 20,
                    ),
                    Container(
                      color: const Color.fromRGBO(243, 244, 246, 1),
                      width: 200,
                      height: 200,
                      child: Image.asset("assets/car2.jpeg",
                          fit: BoxFit.fitHeight),
                    )
                  ],
                ),
              ),
              SizedBox(
                height: 20,
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Container(
                      color: const Color.fromRGBO(243, 244, 246, 1),
                      width: 200,
                      height: 200,
                      child: Image.asset("assets/scienceday.jpeg",
                          fit: BoxFit.fitWidth),
                    ),
                    SizedBox(
                      width: 20,
                    ),
                    Container(
                        color: const Color(0xFFF3F4F6),
                        width: 200,
                        height: 200,
                        child: Image.asset("assets/projectart.jpeg")),
                    SizedBox(
                      width: 20,
                    ),
                    Container(
                      color: const Color.fromRGBO(243, 244, 246, 1),
                      width: 200,
                      height: 200,
                      child: Image.asset("assets/lobby2.jpeg",
                          fit: BoxFit.fitHeight),
                    ),
                    SizedBox(
                      width: 20,
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ]),
    );
  }

  Widget mobileContent() {
    return Container(
      padding: EdgeInsets.all(20),
      color: Palette.white,
      child: Column(children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Gallery",
              style: TextStyle(fontFamily: "Jalnan", fontSize: 20),
            ),
            WidgetUtil.myDivider(),
            SizedBox(
              height: 30,
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Container(
                    color: const Color.fromRGBO(243, 244, 246, 1),
                    width: 200,
                    height: 200,
                    child: Image.asset("assets/lobby1.jpeg",
                        fit: BoxFit.fitHeight),
                  ),
                  SizedBox(
                    width: 20,
                  ),
                  Container(
                    color: const Color.fromRGBO(243, 244, 246, 1),
                    width: 200,
                    height: 200,
                    child:
                        Image.asset("assets/doors.jpeg", fit: BoxFit.fitWidth),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 20,
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Container(
                    color: const Color.fromRGBO(243, 244, 246, 1),
                    width: 200,
                    height: 200,
                    child: Image.asset("assets/mainEnterance.jpeg",
                        fit: BoxFit.fitWidth),
                  ),
                  SizedBox(
                    width: 20,
                  ),
                  Container(
                      color: const Color.fromRGBO(243, 244, 246, 1),
                      width: 200,
                      height: 200,
                      child: Image.asset("assets/gleamIslandLogo.jpeg")),
                ],
              ),
            )
          ],
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 20,
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Container(
                    color: Palette.grey100,
                    width: 200,
                    height: 200,
                    child:
                        Image.asset("assets/lobby.jpeg", fit: BoxFit.fitHeight),
                  ),
                  SizedBox(
                    width: 20,
                  ),
                  Container(
                    color: Palette.grey100,
                    width: 200,
                    height: 200,
                    child: Image.asset("assets/classroom.jpeg",
                        fit: BoxFit.fitWidth),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 20,
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Container(
                    color: const Color.fromRGBO(243, 244, 246, 1),
                    width: 200,
                    height: 200,
                    child:
                        Image.asset("assets/car1.jpeg", fit: BoxFit.fitWidth),
                  ),
                  SizedBox(
                    width: 20,
                  ),
                  Container(
                      color: const Color.fromRGBO(243, 244, 246, 1),
                      width: 200,
                      height: 200,
                      child: Image.asset("assets/car2.jpeg",
                          fit: BoxFit.fitHeight)),
                ],
              ),
            ),
            SizedBox(
              height: 20,
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Container(
                    color: Palette.grey100,
                    width: 200,
                    height: 200,
                    child: Image.asset("assets/scienceday.jpeg",
                        fit: BoxFit.fitWidth),
                  ),
                  SizedBox(
                    width: 20,
                  ),
                  Container(
                      color: Palette.grey100,
                      width: 200,
                      height: 200,
                      child: Image.asset("assets/projectart.jpeg",
                          fit: BoxFit.fitHeight)),
                ],
              ),
            )
          ],
        ),
      ]),
    );
  }

  Widget scrollView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          mainImage(),
          contentGroup(),
          SizedBox(height: 213, child: MyWidget.footer()),
        ],
      ),
    );
  }

  Widget mainImage() {
    return Container(
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          Image.asset("assets/communityMainImage.png"),
          Container(
            padding: EdgeInsets.only(left: 40, bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "Community",
                  style: TextStyle(
                      color: Palette.white,
                      fontSize: 30,
                      fontFamily: "LucidaCalligraphy"),
                ),
                SizedBox(
                  height: 20,
                ),
                Container(
                  width: 150,
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Palette.black,
                      backgroundColor: Palette.black,
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
              ],
            ),
          )
        ],
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
            mobileContent(),
            SizedBox(height: 51, child: MyWidget.mobileSchoolFooter())
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
              : (i == 0
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
          color: Palette.primaryLight,
        ));
      }
    }

    return Container(
      alignment: Alignment.center,
      width: MediaQuery.of(context).size.width,
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
    );
  }

  Widget mobileMainImage() {
    return Container(
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Image.asset("assets/communityMainImage.png"),
          Container(
            padding: EdgeInsets.only(left: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Community",
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
                      foregroundColor: Palette.black,
                      backgroundColor: Palette.accent,
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
