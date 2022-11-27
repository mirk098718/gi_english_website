import 'package:url_launcher/url_launcher.dart';

// class Human {
//   //이름 -> 정적속성
//   //밥먹다. -> 동적속성.
// }

//함수 -> 기능 (입력, 처리, 출력)
//기능 정의.

//기능 실행.


class UrlUtil {
  // 필드(정적속성) -> 변수를 빌림.
  // 메소드(동적속성) -> 함수(기능)를 빌림.

  //주소를 실행하는 기능
  static Future<void> open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunch(url)) {
      await launchUrl(uri);
    }
  }

  //주소가 실행 가능한지 확인하는 기능.
  static Future<bool> canLaunch(String url) async {
    final uri = Uri.parse(url);
    return await canLaunchUrl(uri);
  }
}