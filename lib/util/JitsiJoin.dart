import 'dart:convert';

import 'package:gi_english_website/util/UrlIUtil.dart';

/// meet.jit.si 입장 URL.
///
/// 공개 Jitsi는 방을 처음 여는 사람에게 Google 로그인을 요구한다.
/// 호스트는 '내가 호스트' 화면을 건너뛰고 로그인 페이지로 바로 보내고,
/// 한 번 로그인한 Google 계정은 Jitsi 쪽에서 유지된다.
class JitsiJoin {
  static const String meetHost = 'meet.jit.si';
  static const String signInUrl =
      'https://meet.jit.si/v1/_cdn/auth-static/meet-jit-si/v1/signin.html';

  static bool isJitsiMeeting(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || uri.host.isEmpty) return false;
    final host = uri.host.toLowerCase();
    return host == meetHost || host == 'www.$meetHost';
  }

  static String? roomNameOf(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return null;
    final parts =
        uri.pathSegments.where((part) => part.trim().isNotEmpty).toList();
    if (parts.isEmpty || parts.first == 'v1') return null;
    return parts.first;
  }

  static String prepare(
    String meetingUrl, {
    required bool asHost,
    String displayName = '',
  }) {
    if (!isJitsiMeeting(meetingUrl)) return meetingUrl;
    return asHost
        ? hostUrl(meetingUrl)
        : guestUrl(meetingUrl, displayName: displayName);
  }

  static String guestUrl(String meetingUrl, {String displayName = ''}) {
    final room = roomNameOf(meetingUrl);
    if (room == null) return meetingUrl;
    final params = <String>[
      'config.prejoinConfig.enabled=false',
      'config.disableDeepLinking=true',
    ];
    final name = displayName.trim();
    if (name.isNotEmpty) {
      params.add('userInfo.displayName="${Uri.encodeComponent(name)}"');
    }
    return 'https://$meetHost/$room#${params.join('&')}';
  }

  static String hostUrl(String meetingUrl) {
    final room = roomNameOf(meetingUrl);
    if (room == null) return meetingUrl;
    final roomSafe = Uri.encodeComponent(room.toLowerCase()).toLowerCase();
    final state = <String, dynamic>{
      'room': room,
      'roomSafe': roomSafe,
      'config.prejoinConfig.enabled': false,
    };
    final encodedState = Uri.encodeComponent(jsonEncode(state));
    return '$signInUrl?state=$encodedState#room=${Uri.encodeComponent(room)}&subdir=';
  }

  static Future<void> open(
    String meetingUrl, {
    required bool asHost,
    String displayName = '',
  }) {
    return UrlUtil.open(
      prepare(meetingUrl, asHost: asHost, displayName: displayName),
    );
  }
}
