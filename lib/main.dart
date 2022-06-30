import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:gi_english_website/MainGatePage.dart';

Future<void> main() async {
  //TODO: 나중에 주석 풀기
  // WidgetsFlutterBinding.ensureInitialized();//runApp위에 코드를 넣기 위해 넣는 코드
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scrollBehavior: MyCustomScrollBehavior(),
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

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  //alt+insert를 누르면, 여러 메뉴가 나온다.
  //Object a = 1;
  //Object b = MaterialApp();

  @override
  Set<PointerDeviceKind> get dragDevices =>{
    PointerDeviceKind.mouse,
    PointerDeviceKind.touch,
  };
}
