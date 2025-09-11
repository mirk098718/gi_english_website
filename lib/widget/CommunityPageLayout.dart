import 'package:flutter/material.dart';
import 'package:gi_english_website/pages/SchoolConsultationPage.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/widget/ButtonState.dart';
import 'package:gi_english_website/widget/MobileSchoolLayout.dart';
import 'package:gi_english_website/widget/WebSchoolLayout.dart';

class CommunityPageLayout extends StatefulWidget {
  final String currentPage; // "Notice Board" 또는 "FAQ"
  final Widget content;
  final List<ButtonState> menuItems;

  const CommunityPageLayout({
    Key? key,
    required this.currentPage,
    required this.content,
    required this.menuItems,
  }) : super(key: key);

  @override
  _CommunityPageLayoutState createState() => _CommunityPageLayoutState();
}

class _CommunityPageLayoutState extends State<CommunityPageLayout> {
  @override
  Widget build(BuildContext context) {
    MediaQueryData mediaQueryData = MediaQuery.of(context);
    Size size = mediaQueryData.size;
    double width = size.width;

    if (width > 768) {
      return WebSchoolLayout(content: _buildScrollView());
    } else {
      return MobileSchoolLayout(content: _buildMobileScrollView());
    }
  }

  Widget _buildScrollView() {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height,
        ),
        child: IntrinsicHeight(
          child: Column(
            children: [
              _buildMainImage(),
              Expanded(child: _buildContentGroup()),
              MyWidget.footer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentGroup() {
    return Container(
      color: Palette.white,
      constraints: BoxConstraints(
        minHeight: 600, // 최소 높이 설정
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 232, child: _buildLeftMenu()),
          Expanded(child: widget.content),
        ],
      ),
    );
  }

  Widget _buildLeftMenu() {
    List<Widget> children = [];
    for (int i = 0; i < widget.menuItems.length; i++) {
      ButtonState buttonState = widget.menuItems[i];
      bool isFirst = (i == 0);
      bool isLast = (i == widget.menuItems.length - 1);
      bool isCurrent = buttonState.label == widget.currentPage;

      Widget child;
      if (isFirst) {
        child = MyWidget.leftMenuTop(buttonState.color, buttonState.label);
      } else if (isLast) {
        child = MyWidget.leftMenuBottom(buttonState.color, buttonState.label);
      } else {
        child = MyWidget.leftMenuMiddle(buttonState.color, buttonState.label);
      }

      children.add(InkWell(
        child: child,
        onHover: (value) {
          buttonState.color = value
              ? BehaviorColor.colorOnHover
              : (isCurrent
                  ? BehaviorColor.colorOnClick
                  : BehaviorColor.colorOnDefault);
          setState(() {});
        },
        onTap: () {
          if (!isCurrent) {
            MenuUtil.push(context, buttonState.nextPage);
          }
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
          border: Border.all(width: 1, color: Palette.black),
        ),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildMainImage() {
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
                    fontFamily: "LucidaCalligraphy",
                  ),
                ),
                SizedBox(height: 20),
                Container(
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
                    child: Text(
                      "상담신청",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: "Jalnan",
                        color: Palette.white,
                      ),
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

  Widget _buildMobileScrollView() {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height,
        ),
        child: IntrinsicHeight(
          child: Column(
            children: [
              _buildMobileLeftMenu(),
              Expanded(
                child: Container(
                  color: Colors.white,
                  constraints: BoxConstraints(minHeight: 500),
                  child: widget.content,
                ),
              ),
              SizedBox(height: 51, child: MyWidget.mobileSchoolFooter())
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLeftMenu() {
    List<Widget> children = [];
    for (int i = 0; i < widget.menuItems.length; i++) {
      ButtonState buttonState = widget.menuItems[i];
      bool isFirst = (i == 0);
      bool isLast = (i == widget.menuItems.length - 1);
      bool isCurrent = buttonState.label == widget.currentPage;

      Widget child;
      if (isFirst) {
        child =
            MyWidget.mobileLeftMenuStart(buttonState.color, buttonState.label);
      } else if (isLast) {
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
              : (isCurrent
                  ? BehaviorColor.colorOnClick
                  : BehaviorColor.colorOnDefault);
          setState(() {});
        },
        onTap: () {
          if (!isCurrent) {
            MenuUtil.push(context, buttonState.nextPage);
          }
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
      color: Palette.white,
      padding: EdgeInsets.all(20),
      child: Container(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: children),
        ),
      ),
    );
  }
}
