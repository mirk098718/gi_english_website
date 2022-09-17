import 'package:flutter/material.dart';
import 'package:gi_english_website/util/Palette.dart';


class MyWidget {



  static Widget footer() {
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        Container(width: double.infinity, color: Palette.lightestEarth),
        Container(
          padding: EdgeInsets.all(20),
          alignment: Alignment.centerLeft,

          child: Text(
                "Gi Gleam Island 어학원 파주\n"
                "경기도 파주시 교하로 100번길 00, 태산W타워 7층\n"
                "문의 : 031) 90049-380005  /  email : @gmail.com\n"
                "사업자명 : 글림아일랜드 어학원 / 대표자명 : 김남희\n"
                "사업자 등록번호 : \n"
                "신고번호 : \n"
                "Copyright ⓒ 글림아일랜드교육",
            style: TextStyle(color: Palette.black)
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
        Container(width: double.infinity, color: Palette.lightestEarth),
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
              style: TextStyle(color: Palette.white,
              fontFamily: "Cafe24Oneprettynight.ttf")
          ),
        ),
      ],
    );
  }


  static Widget roundEdgeTextFieldVisitorVer(
      {TextEditingController? controller, ValueChanged<String>? onChanged}) {
    return Container(
      padding: EdgeInsets.only(top: 7, bottom: 7),
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

  static Widget roundEdgeTextField(String hintText, TextEditingController controller, {bool obscureText=false}) {
    return Container(
      padding: EdgeInsets.all(5),
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

  static Widget schoolElevatedButton(String text, Color color){
    return ElevatedButton(
      onPressed: () {},
      child: Text(text, textAlign: TextAlign.center,style: TextStyle(
          fontFamily: "Oneprettynight", color: Palette.white, fontSize: 12),),
      style: ElevatedButton.styleFrom(
        primary: color,
        onPrimary: Palette.black,
      ),
    );
  }

  static Widget schoolTextButton(String text, Color color, double size){
    return TextButton(
      onPressed: () {},
      child: Text(text, textAlign: TextAlign.center,style: TextStyle(
          fontFamily: "Oneprettynight", color: color, fontSize: size),),
      style: ElevatedButton.styleFrom(
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
