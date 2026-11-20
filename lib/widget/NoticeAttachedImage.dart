import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gi_english_website/util/AppLanguage.dart';
import 'package:gi_english_website/util/NoticeImages.dart';
import 'package:gi_english_website/util/NoticeService.dart';
import 'package:gi_english_website/util/Palette.dart';

class NoticeAttachedImage extends StatelessWidget {
  final String source;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Color? progressColor;
  final Color? errorColor;

  const NoticeAttachedImage({
    Key? key,
    required this.source,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.progressColor,
    this.errorColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (NoticeImages.isNetworkUrl(source)) {
      return Image.network(
        source,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _progress(progress);
        },
        errorBuilder: (context, error, stackTrace) => _error(context),
      );
    }

    final cached = NoticeService.cachedNoticeImage(source);
    if (cached != null) {
      return _memory(cached);
    }

    return FutureBuilder<Uint8List?>(
      future: NoticeService.loadNoticeImageBytes(source),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _progress(null);
        }
        final bytes = snapshot.data;
        if (bytes == null || bytes.isEmpty) return _error(context);
        return _memory(bytes);
      },
    );
  }

  Widget _memory(Uint8List bytes) {
    return Image.memory(
      bytes,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => _error(context),
    );
  }

  Widget _progress(ImageChunkEvent? progress) {
    final value = progress == null || progress.expectedTotalBytes == null
        ? null
        : progress.cumulativeBytesLoaded / progress.expectedTotalBytes!;
    return SizedBox(
      width: width,
      height: height ?? 180,
      child: Center(
        child: CircularProgressIndicator(
          value: value,
          valueColor: AlwaysStoppedAnimation<Color>(
            progressColor ?? Palette.primary,
          ),
        ),
      ),
    );
  }

  Widget _error(BuildContext context) {
    return SizedBox(
      width: width,
      height: height ?? 48,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          tr(context, "이미지를 불러올 수 없습니다"),
          style: TextStyle(
            fontFamily: "NotoSansKR",
            color: errorColor ?? Palette.grey600,
          ),
        ),
      ),
    );
  }
}
