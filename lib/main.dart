import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:gi_english_website/firebase_options.dart';
import 'package:gi_english_website/pages/PaymentResultPage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:gi_english_website/util/NoticeService.dart';
import 'package:gi_english_website/util/SiteAlertCenter.dart';

import 'pages/AdminTeacherScheduleTab.dart';
import 'pages/SchoolAboutPage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Firestore 설정 초기화
  NoticeService.initializeFirestore();

  // 달력 등 한글 로케일(요일/월 이름) 사용을 위한 초기화
  await initializeDateFormatting('ko_KR', null);
  SiteAlertCenter.instance.start();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => SiteAlertCenter.instance.unlockAudio(),
      child: MaterialApp(
        scrollBehavior: MyCustomScrollBehavior(),
        title: 'Gleam Island Homepage',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: _resolveHome()),
    );
  }

  /// 토스 결제 리다이렉트 URL(/payment/success|fail)을 앱 시작 시 처리한다.
  Widget _resolveHome() {
    final uri = Uri.base;
    final path = uri.path;
    if (path.contains('/payment/success')) {
      return PaymentResultPage.fromUri(uri, success: true);
    }
    if (path.contains('/payment/fail')) {
      return PaymentResultPage.fromUri(uri, success: false);
    }
    if (AdminTeacherSchedulePage.matchesUri(uri)) {
      return const AdminTeacherSchedulePage();
    }
    return const SchoolAboutPage();
  }
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.mouse,
        PointerDeviceKind.touch,
      };
}
