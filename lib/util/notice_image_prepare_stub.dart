import 'dart:typed_data';

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
  if (bytes.length > NoticeImages.maxStoredBytes) {
    throw Exception('사진을 줄이지 못했습니다. 더 작은 사진으로 다시 올려 주세요.');
  }
  return PreparedNoticeImage(
    bytes: bytes,
    mimeType: NoticeImages.contentTypeOf(fileName),
  );
}
