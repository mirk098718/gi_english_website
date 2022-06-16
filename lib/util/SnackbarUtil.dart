import 'package:flutter/material.dart';

class SnackbarUtil {
  static void showSnackBar(String message, BuildContext context) {
    var scaffoldMessenger = ScaffoldMessenger.of(context);

    scaffoldMessenger.clearSnackBars();

    scaffoldMessenger.showSnackBar(SnackBar(content:Text(message)));

    // scaffoldMessenger.showSnackBar(
    //   SnackBar(
    //     content: SizedBox(
    //       height: 100,
    //       child: Column(
    //         mainAxisAlignment: MainAxisAlignment.end,
    //         children: [
    //           Text("알림"),
    //           Text(message),
    //         ],
    //       ),
    //     ),
    //   ),
    // );
  }
}
