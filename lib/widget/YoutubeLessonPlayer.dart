import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gi_english_website/util/AppLanguage.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/UrlIUtil.dart';
// ignore: deprecated_member_use
import 'package:gi_english_website/util/html_stub.dart'
    if (dart.library.html) 'dart:html' as html;
import 'package:gi_english_website/util/ui_web_stub.dart'
    if (dart.library.html) 'dart:ui_web' as ui;

/// 유튜브 시청 페이지로 나가지 않고, 강의 화면 안에 영상만 붙인다.
class YoutubeLessonPlayer extends StatefulWidget {
  final String videoUrl;
  final String title;

  const YoutubeLessonPlayer({
    Key? key,
    required this.videoUrl,
    this.title = '인강',
  }) : super(key: key);

  @override
  State<YoutubeLessonPlayer> createState() => _YoutubeLessonPlayerState();
}

class _YoutubeLessonPlayerState extends State<YoutubeLessonPlayer> {
  static final Set<String> _registered = {};
  late final String? _videoId = UrlUtil.youtubeVideoId(widget.videoUrl);
  late final String _viewType = 'gleam-youtube-${_videoId ?? 'none'}';

  @override
  void initState() {
    super.initState();
    final id = _videoId;
    if (!kIsWeb || id == null || !_registered.add(_viewType)) return;
    ui.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final iframe = html.IFrameElement()
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';
      iframe.setAttribute(
        'allow',
        'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share',
      );
      iframe.setAttribute('allowfullscreen', 'true');
      iframe.setAttribute('referrerpolicy', 'strict-origin-when-cross-origin');
      iframe.setAttribute('title', widget.title);
      iframe.src = UrlUtil.playerUrl(
        widget.videoUrl,
        origin: Uri.base.origin,
      );
      return iframe;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_videoId == null || !kIsWeb) {
      return Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: () => UrlUtil.openPlayer(widget.videoUrl),
          icon: Icon(Icons.play_circle_outline),
          label: Text(
            widget.title,
            style: TextStyle(fontFamily: "NotoSansKR"),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ColoredBox(
            color: Palette.black,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: HtmlElementView(viewType: _viewType),
            ),
          ),
        ),
        SizedBox(height: 6),
        Text(
          tr(context, "유튜브 페이지로 나가지 않고 이 자리에서 재생됩니다."),
          style: TextStyle(
            fontFamily: "NotoSansKR",
            fontSize: 12,
            color: Palette.grey500,
          ),
        ),
      ],
    );
  }
}
