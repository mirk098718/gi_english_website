import 'package:flutter/material.dart';
import 'package:gi_english_website/testPages/SfCanlendarExamplePage.dart';
import 'package:gi_english_website/testPages/StackRatioTestPage.dart';
import 'package:gi_english_website/testPages/StretchTestPage.dart';
import 'package:gi_english_website/cafePages/CafeAboutPage.dart';
import 'package:gi_english_website/cafePages/cafeMainPage.dart';
import 'package:gi_english_website/pages/SchoolAboutPage.dart';
import 'package:gi_english_website/MainGatePage.dart';
import 'package:gi_english_website/pages/SchoolMainPage.dart';
import 'package:gi_english_website/pages/SchoolProgramPage.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gleam Island Homepage',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MainGatePage(),
    );
  }
}