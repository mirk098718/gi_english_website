import 'package:flutter/material.dart';
import 'package:gi_english_website/MainGatePage.dart';
import 'package:gi_english_website/cafePages/CafeAboutPage.dart';
import 'package:gi_english_website/cafePages/CafeCommunityNoticePage.dart';
import 'package:gi_english_website/cafePages/CafeProgramPage.dart';
import 'package:gi_english_website/cafePages/CafeReservationPage.dart';
import 'package:gi_english_website/pages/SchoolAboutPage.dart';
import 'package:gi_english_website/pages/SchoolCommunityNoticePage.dart';
import 'package:gi_english_website/pages/SchoolCurriculumElePage.dart';
import 'package:gi_english_website/pages/SchoolMainPage.dart';
import 'package:gi_english_website/pages/SchoolProgramPage.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/Palette.dart';


class MyWidget {
  static Widget footer() {
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        Container(width: double.infinity, color: Colors.purple),
        Container(
          padding: EdgeInsets.all(20),
          alignment: Alignment.centerLeft,

          child: Text(
                "Gi Gleam Island 어학원 파주\n"
                "경기도 파주시 교하로 100번길 00, 태산W타워 7층\n"
                "문의 : 031) 949-3805  /  email : @gmail.com\n"
                "사업자명 : 글림아일랜드 어학원 / 대표자명 : 김남희\n"
                "사업자 등록번호 : 346 - 86 - 00782 제1461호\n"
                "신고번호 : J1518020200003\n"
                "Copyright ⓒ 글림아일랜드교육",
            style: TextStyle(color: Palette.white)
          ),
        ),
      ],
    );
  }

  static Widget cafeFooter() {
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        Container(width: double.infinity, color: Palette.mainLime),
        Container(
          padding: EdgeInsets.all(20),
          alignment: Alignment.centerLeft,

          child: Text(
                "Gi Gleam Island 어학원 파주\n"
                "경기도 파주시 교하로 100번길 00, 태산W타워 7층\n"
                "문의 : 031) 949-3805  /  email : @gmail.com\n"
                "사업자명 : 글림아일랜드 어학원 / 대표자명 : 김남희\n"
                "사업자 등록번호 : 346 - 86 - 00782 제1461호\n"
                "신고번호 : J1518020200003\n"
                "Copyright ⓒ 글림아일랜드교육",
            style: TextStyle(color: Palette.white),
          ),
        ),
      ],
    );
  }

  static Widget mobileSchoolFooter(){
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        Container(width: double.infinity, color: Colors.purple),
        Container(
          padding: EdgeInsets.all(5),
          alignment: Alignment.center,

          child: Text("ⓒ 글림아일랜드교육",
              style: TextStyle(color: Palette.white)
          ),
        ),
      ],
    );
  }

  static Widget mobileCafeFooter(){
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        Container(width: double.infinity, color: Palette.mainLime),
        Container(
          padding: EdgeInsets.all(5),
          alignment: Alignment.center,

          child: Text("ⓒ 글림아일랜드교육",
              style: TextStyle(color: Palette.white)
          ),
        ),
      ],
    );
  }


  static Widget roundEdgeTextField(String hintText, TextEditingController controller) {
    return Container(
      padding: EdgeInsets.all(5),
      color: Colors.transparent,
      child: TextField(
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: hintText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

//좌측메뉴 세분화

  static Widget leftMenuTop(Color selectedMenuColor, String content) {
    return Container(
      alignment: Alignment.center,
      width: 192, height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10))
        ,color: selectedMenuColor,
      ),
      child: Text(
        content, textAlign: TextAlign.center, style: TextStyle(color: Palette.black, fontWeight: FontWeight.bold),
      ),
    );
  }

  static Widget leftMenuMiddle(Color menuColor, String menuContent) {
    return Container(
      color: menuColor,
      alignment: Alignment.center,
      width: 192, height: 40,
      child: Text(
        menuContent,
        style: TextStyle(color: Palette.black, fontWeight: FontWeight.bold),
      ),
    );
  }

  static Widget leftMenuBottom(Color menuColor, String content) {
    return Container(
      alignment: Alignment.center,
      width: 192, height: 40,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10))
          ,color: menuColor),
      child: Text(content,
        style: TextStyle(color: Palette.black, fontWeight: FontWeight.bold),
      ),
    );
  }


  //mobile 상세메뉴

  static Widget mobileLeftMenuStart(Color selectedMenuColor, String content) {
    return Container(
      alignment: Alignment.center,
      width: 150, height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10))
        ,color: selectedMenuColor,
      ),
      child: Text(
        content, textAlign: TextAlign.center, style: TextStyle(color: Palette.black, fontWeight: FontWeight.bold),
      ),
    );
  }

  static Widget mobileLeftMenuMiddle(Color menuColor, String menuContent) {
    return Container(
      color: menuColor,
      alignment: Alignment.center,
      width: 150, height: 40,
      child: Text(
        menuContent,
        style: TextStyle(color: Palette.black, fontWeight: FontWeight.bold),
      ),
    );
  }

  static Widget mobileLeftMenuEnd(Color menuColor, String content) {
    return Container(
      alignment: Alignment.center,
      width: 150, height: 40,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.only(topRight: Radius.circular(10), bottomRight: Radius.circular(10))
          ,color: menuColor),
      child: Text(content,
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