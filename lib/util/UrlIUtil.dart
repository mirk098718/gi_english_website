import 'package:url_launcher/url_launcher.dart';

// class Human {
//   //이름 -> 정적속성
//   //밥먹다. -> 동적속성.
// }

//함수 -> 기능 (입력, 처리, 출력)
//기능 정의.

//기능 실행.


class UrlUtil {
  /// YouTube 스튜디오 수정 주소를 학생이 볼 수 있는 시청 주소로 바꾼다.
  static String normalizeVideoUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return trimmed;

    final studio = RegExp(r'studio\.youtube\.com/video/([A-Za-z0-9_-]{6,})');
    final watch = RegExp(
        r'(?:youtube\.com/watch\?[^#]*v=|youtu\.be/|youtube\.com/embed/)([A-Za-z0-9_-]{6,})');
    final match = studio.firstMatch(trimmed) ?? watch.firstMatch(trimmed);
    if (match != null) {
      return 'https://youtu.be/${match.group(1)}';
    }
    return trimmed;
  }

  static Future<void> open(String url) async {
    final normalized = normalizeVideoUrl(url);
    if (normalized.isEmpty) return;
    final uri = Uri.parse(normalized);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
        webOnlyWindowName: '_blank',
      );
      if (launched) return;
    } catch (_) {}
    // 일부 웹/브라우저에서 canLaunchUrl이 false여도 실제로는 열 수 있다.
    try {
      await launchUrl(uri, webOnlyWindowName: '_blank');
    } catch (_) {}
  }

  //주소가 실행 가능한지 확인하는 기능.
  static Future<bool> canLaunch(String url) async {
    final uri = Uri.parse(url);
    return await canLaunchUrl(uri);
  }
}