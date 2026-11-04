import 'package:flutter/foundation.dart';
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

  static final RegExp _youtubeId = RegExp(
    r'(?:studio\.youtube\.com/video/|youtube\.com/watch\?[^#]*v=|youtu\.be/|youtube\.com/embed/|youtube\.com/shorts/)([A-Za-z0-9_-]{6,})',
  );

  static String? youtubeVideoId(String url) {
    return _youtubeId.firstMatch(url.trim())?.group(1);
  }

  /// 유튜브 페이지 전체가 아니라 영상 재생기만 여는 주소.
  /// [origin]을 넣어야 유튜브가 재생기를 허용한다. 없으면 Error 153이 난다.
  static String playerUrl(String url, {String? origin}) {
    final id = youtubeVideoId(url);
    if (id == null) return url.trim();
    final query = StringBuffer('rel=0&playsinline=1');
    final site = origin?.trim() ?? '';
    if (site.isNotEmpty) {
      query.write('&origin=${Uri.encodeComponent(site)}');
    }
    return 'https://www.youtube.com/embed/$id?$query';
  }

  /// 재생기를 우리 페이지에 붙여 연다. 유튜브 주소를 바로 열면 Referer가 빠져 Error 153이 난다.
  static String lessonPlayerPath(String url) {
    final id = youtubeVideoId(url);
    if (id == null) return url.trim();
    return '/player.html?v=$id';
  }

  /// 사이트 안 경로(/quizzes/...)는 웹에서는 현재 주소, 앱에서는 호스팅 주소로 연다.
  static Uri resolveLaunchUri(String url) {
    final normalized = normalizeVideoUrl(url);
    final uri = Uri.parse(normalized);
    if (uri.hasScheme) return uri;
    final path = normalized.startsWith('/') ? normalized : '/$normalized';
    if (kIsWeb) return Uri.base.resolve(path);
    return Uri.parse('https://gleam-island.web.app$path');
  }

  static Future<void> openPlayer(String url) {
    final id = youtubeVideoId(url);
    if (id == null) return open(url);
    return _launch(lessonPlayerPath(url));
  }

  static Future<void> open(String url) async {
    final normalized = normalizeVideoUrl(url);
    if (normalized.isEmpty) return;
    return _launch(normalized);
  }

  static Future<void> _launch(String url, {bool alreadyResolved = false}) async {
    if (url.isEmpty) return;
    final uri = alreadyResolved ? Uri.parse(url) : resolveLaunchUri(url);
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