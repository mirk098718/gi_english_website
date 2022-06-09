import 'package:flutter/material.dart';

class MenuUtil {
  static void push(BuildContext context, Widget page) {
    var nav = Navigator.of(context);
    nav.push(
      MaterialPageRoute(builder: (context) => page),
    );
  }

  static void pop(BuildContext context) {
    var nav = Navigator.of(context);
    nav.pop();
  }

  //~~
}
