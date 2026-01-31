import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:gi_english_website/firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:gi_english_website/util/NoticeService.dart';
import 'package:gi_english_website/util/FAQService.dart';

import 'pages/SchoolMainPage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Firestore 설정 초기화
  NoticeService.initializeFirestore();

  // 달력 등 한글 로케일(요일/월 이름) 사용을 위한 초기화
  await initializeDateFormatting('ko_KR', null);

  // 더미 데이터는 앱 시작 시마다 추가하지 않음 (추가할 때마다 Firestore에 중복 저장되어 게시글이 2개씩 보이는 문제 발생)
  // try { await _addDummyData(); } catch (e) { print('더미 데이터 추가 중 오류: $e'); }

  runApp(MyApp());
}

// 임시: 더미 데이터 추가 함수
Future<void> _addDummyData() async {
  try {
    // Notice 더미 데이터 추가
    await NoticeService.addDummyNotices();
    // FAQ 더미 데이터 추가
    await FAQService.addDummyFAQs();
    print('✅ 모든 더미 데이터가 추가되었습니다.');
  } catch (e) {
    print('❌ 더미 데이터 추가 실패: $e');
  }
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
        home: SchoolMainPage());
  }
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  //alt+insert를 누르면, 여러 메뉴가 나온다.
  //Object a = 1;
  //Object b = MaterialApp();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.mouse,
        PointerDeviceKind.touch,
      };
}
