import 'package:flutter/material.dart';

import 'MenuUtil.dart';
import 'Palette.dart';

//클래스 필드
//클래스 메소드 : 클래스가 갖고 있는 메소드
//인스턴스 필드
//인스턴스 메소드 : 인스턴스가 갖고 있는 메소드

class DialogUtil {
  static void showAlert(BuildContext context, String content) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
            content: Container(
              width: 250,
              height: 260,
              alignment: Alignment.center,
              padding: EdgeInsets.all(30),
              child: Column(
                children: [
                  SizedBox(
                    height: 50,
                  ),
                  Text(
                    content,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(
                    height: 60,
                  ),
                  Container(
                    width: 150,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: Palette.mainLime,
                        onPrimary: Palette.black,
                      ),
                      onPressed: ()=>backPage(context),
                      child: Text(
                        "확인",
                        style: TextStyle(fontFamily: "Jalnan"),
                      ),
                    ),
                  )
                ],
              ),
            ));
      },
    );
  }

  static void backPage(BuildContext context) {
    MenuUtil.pop(context);
  }
}