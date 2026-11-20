import 'dart:typed_data';

// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:gi_english_website/util/NoticeImages.dart';

class PreparedNoticeImage {
  final Uint8List bytes;
  final String mimeType;

  const PreparedNoticeImage({required this.bytes, required this.mimeType});
}

Future<PreparedNoticeImage> prepareNoticeImage(
  Uint8List bytes,
  String fileName,
) async {
  final ext = NoticeImages.extensionOf(fileName);
  if (ext == 'gif' && bytes.length <= NoticeImages.maxStoredBytes) {
    return PreparedNoticeImage(bytes: bytes, mimeType: 'image/gif');
  }
  if (bytes.length <= 350 * 1024 && ext != 'gif') {
    return PreparedNoticeImage(
      bytes: bytes,
      mimeType: NoticeImages.contentTypeOf(fileName),
    );
  }

  Uint8List? smallest;
  const attempts = <(int, double)>[
    (1600, 0.72),
    (1280, 0.62),
    (1024, 0.55),
    (800, 0.45),
  ];
  for (final attempt in attempts) {
    final compressed = await _toJpeg(bytes, attempt.$1, attempt.$2);
    if (compressed == null || compressed.isEmpty) continue;
    smallest = compressed;
    if (compressed.length <= NoticeImages.maxStoredBytes) {
      return PreparedNoticeImage(bytes: compressed, mimeType: 'image/jpeg');
    }
  }
  if (smallest != null && smallest.length <= 700 * 1024) {
    return PreparedNoticeImage(bytes: smallest, mimeType: 'image/jpeg');
  }
  if (bytes.length <= NoticeImages.maxStoredBytes) {
    return PreparedNoticeImage(
      bytes: bytes,
      mimeType: NoticeImages.contentTypeOf(fileName),
    );
  }
  throw Exception('사진을 줄여도 용량이 큽니다. 더 작은 사진으로 다시 올려 주세요.');
}

Future<Uint8List?> _toJpeg(Uint8List bytes, int maxSide, double quality) async {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrl(blob);
  try {
    final img = html.ImageElement();
    img.src = url;
    if (img.complete != true || img.naturalWidth == 0) {
      await img.onLoad.first.timeout(const Duration(seconds: 8));
    }
    final width = img.naturalWidth > 0 ? img.naturalWidth : (img.width ?? 0);
    final height = img.naturalHeight > 0
        ? img.naturalHeight
        : (img.height ?? 0);
    if (width <= 0 || height <= 0) return null;

    var ratio = 1.0;
    final longest = width > height ? width : height;
    if (longest > maxSide) ratio = maxSide / longest;
    final targetWidth = (width * ratio).round().clamp(1, maxSide);
    final targetHeight = (height * ratio).round().clamp(1, maxSide);

    final canvas = html.CanvasElement(width: targetWidth, height: targetHeight);
    canvas.context2D.drawImageScaled(img, 0, 0, targetWidth, targetHeight);
    final dataUrl = canvas.toDataUrl('image/jpeg', quality);
    final comma = dataUrl.indexOf(',');
    if (comma < 0) return null;
    final binary = html.window.atob(dataUrl.substring(comma + 1));
    return Uint8List.fromList(binary.codeUnits);
  } catch (_) {
    return null;
  } finally {
    html.Url.revokeObjectUrl(url);
  }
}
