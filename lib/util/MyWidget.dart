import 'package:flutter/material.dart';
import 'package:gi_english_website/util/Palette.dart';

class MyWidget {
  static Widget footer() {
    return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Palette.secondaryDark, Color(0xFF022C22)],
          ),
        ),
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Gi Gleam Island 어학원 파주",
              style: TextStyle(
                  color: Palette.white,
                  fontFamily: "NotoSansKR",
                  fontWeight: FontWeight.w700,
                  fontSize: 18),
            ),
            SizedBox(
              height: 12,
            ),
            Text(
              "경기도 파주시 해올2길 2 태산 W 타워 7층 701~703호 (다율동 1044)\n"
              "문의 : 031 942 0908\n"
              "email : gienglish.paju@gmail.com\n"
              "사업자명 : 글림아일랜드 어학원 / 대표자명 : 김남희",
              style: TextStyle(
                  color: Palette.grey300,
                  fontFamily: "NotoSansKR",
                  fontWeight: FontWeight.normal,
                  fontSize: 14,
                  height: 1.5),
            ),
            SizedBox(height: 16),
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Palette.white.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Copyright ⓒ 글림아일랜드어학원",
              style: TextStyle(
                  color: Palette.grey400,
                  fontFamily: "NotoSansKR",
                  fontSize: 12),
            ),
          ],
        ));
  }

  static Widget cafeFooter() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Palette.secondaryDark, Color(0xFF022C22)],
        ),
      ),
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Gi Gleam Island 어학원 파주",
            style: TextStyle(
                color: Palette.white,
                fontFamily: "NotoSansKR",
                fontWeight: FontWeight.w700,
                fontSize: 18),
          ),
          SizedBox(height: 12),
          Text(
            "경기도 파주시 교하로 100번길 00, 태산W타워 7층\n"
            "문의 : 031) 949-3805  /  email : @gmail.com\n"
            "사업자명 : 글림아일랜드 어학원 / 대표자명 : 김남희\n"
            "사업자 등록번호 : 346 - 86 - 00782 제1461호\n"
            "신고번호 : J1518020200003",
            style: TextStyle(
                color: Palette.white.withOpacity(0.9),
                fontFamily: "NotoSansKR",
                fontSize: 14,
                height: 1.5),
          ),
          SizedBox(height: 16),
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Palette.white.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Copyright ⓒ 글림아일랜드교육",
            style: TextStyle(
                color: Palette.white.withOpacity(0.7),
                fontFamily: "NotoSansKR",
                fontSize: 12),
          ),
        ],
      ),
    );
  }

  static Widget mobileSchoolFooter() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Palette.darkTeal, Palette.darkTealDark],
        ),
      ),
      padding: EdgeInsets.all(16),
      child: Text(
        "ⓒ 글림아일랜드교육",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Palette.white,
          fontFamily: "NotoSansKR",
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  static Widget mobileCafeFooter() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Palette.secondary, Palette.secondaryDark],
        ),
      ),
      padding: EdgeInsets.all(16),
      child: Text(
        "ⓒ 글림아일랜드교육",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Palette.white,
          fontFamily: "NotoSansKR",
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  static Widget roundEdgeTextFieldVisitorVer(
      {TextEditingController? controller, ValueChanged<String>? onChanged}) {
    return Container(
      margin: EdgeInsets.only(top: 10, bottom: 10),
      padding: EdgeInsets.only(top: 10, bottom: 10),
      width: 500,
      color: Colors.transparent,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onChanged: onChanged,
      ),
    );
  }

  static Widget roundEdgeTextField(
      String hintText, TextEditingController controller,
      {bool obscureText = false}) {
    return Container(
      margin: EdgeInsets.only(top: 20, bottom: 20),
      padding: EdgeInsets.all(10),
      color: Colors.transparent,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: hintText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  static Widget schoolElevatedButton(String text, Color color) {
    return ElevatedButton(
      onPressed: () {},
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
            fontFamily: "Oneprettynight", color: Palette.white, fontSize: 14),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Palette.black,
      ),
    );
  }

  static Widget schoolTextButton(String text, Color color, double size) {
    return TextButton(
      onPressed: () {},
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(fontFamily: "Behappy", color: color, fontSize: size),
      ),
      style: ElevatedButton.styleFrom(),
    );
  }
//좌측메뉴 세분화

  static Widget leftMenuTop(Color selectedMenuColor, String content) {
    return Container(
      alignment: Alignment.center,
      width: 192,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10), topRight: Radius.circular(10)),
        color: selectedMenuColor,
      ),
      child: Text(
        content,
        textAlign: TextAlign.center,
        style: TextStyle(color: Palette.black, fontWeight: FontWeight.bold),
      ),
    );
  }

  static Widget leftMenuMiddle(Color menuColor, String menuContent) {
    return Container(
      color: menuColor,
      alignment: Alignment.center,
      width: 192,
      height: 40,
      child: Text(
        menuContent,
        style: TextStyle(color: Palette.black, fontWeight: FontWeight.bold),
      ),
    );
  }

  static Widget leftMenuBottom(Color menuColor, String content) {
    return Container(
      alignment: Alignment.center,
      width: 192,
      height: 40,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(10)),
          color: menuColor),
      child: Text(
        content,
        style: TextStyle(color: Palette.black, fontWeight: FontWeight.bold),
      ),
    );
  }

  //게시판 세분화

  static Widget boardEntryTop(
      Color selectedMenuColor, String entryNumber, String content) {
    return Container(
      padding: EdgeInsets.all(5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10), topRight: Radius.circular(10)),
        color: selectedMenuColor,
      ),
      child: Row(children: [
        SizedBox(width: 20),
        Text(entryNumber,
            style: TextStyle(
                color: Palette.black,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
        SizedBox(width: 30),
        Expanded(
          child: Text(
            content,
            textAlign: TextAlign.left,
            style: TextStyle(
                color: Palette.black,
                fontWeight: FontWeight.normal,
                fontSize: 14),
          ),
        ),
      ]),
    );
  }

  static Widget boardEntryMiddle(
      Color menuColor, String entryNumber, String content) {
    return Container(
      padding: EdgeInsets.all(5),
      color: menuColor,
      alignment: Alignment.center,
      child: Row(children: [
        SizedBox(
          width: 20,
        ),
        Text(entryNumber,
            style: TextStyle(
                color: Palette.black,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
        SizedBox(width: 30),
        Text(
          content,
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Palette.black,
              fontWeight: FontWeight.normal,
              fontSize: 14),
        ),
      ]),
    );
  }

  static Widget boardEntryBottom(
      Color menuColor, String entryNumber, String content) {
    return Container(
      padding: EdgeInsets.all(5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(10)),
          color: menuColor),
      child: Row(children: [
        SizedBox(width: 20),
        Text(entryNumber,
            style: TextStyle(
                color: Palette.black,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
        SizedBox(width: 30),
        Text(
          content,
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Palette.black,
              fontWeight: FontWeight.normal,
              fontSize: 14),
        ),
      ]),
    );
  }

  //mobile 상세메뉴

  static Widget mobileLeftMenuStart(Color selectedMenuColor, String content) {
    return Container(
      alignment: Alignment.center,
      width: 150,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
        color: selectedMenuColor,
      ),
      child: Text(
        content,
        textAlign: TextAlign.center,
        style: TextStyle(color: Palette.black, fontWeight: FontWeight.bold),
      ),
    );
  }

  static Widget mobileLeftMenuMiddle(Color menuColor, String menuContent) {
    return Container(
      color: menuColor,
      alignment: Alignment.center,
      width: 150,
      height: 40,
      child: Text(
        menuContent,
        style: TextStyle(color: Palette.black, fontWeight: FontWeight.bold),
      ),
    );
  }

  static Widget mobileLeftMenuEnd(Color menuColor, String content) {
    return Container(
      alignment: Alignment.center,
      width: 150,
      height: 40,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
              topRight: Radius.circular(10), bottomRight: Radius.circular(10)),
          color: menuColor),
      child: Text(
        content,
        style: TextStyle(color: Palette.black, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// Widget roundEdgeButton(String text, [Color color = Palette.white]) {
//   return ElevatedButton(
//     style: ButtonStyle(),
//     child: Text(text, style: TextStyle(),),
//     onPressed: (){},
//   );
// }
