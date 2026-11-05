import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gi_english_website/widget/TeacherPhotoCropDialog.dart';

/// 웹에서 프로필 사진을 고르고 정사각형으로 자른다.
class ProfilePhotoPicker {
  static Future<Uint8List?> pickAndCrop(
    BuildContext context, {
    void Function(String message)? onError,
  }) async {
    Uint8List? raw;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'gif'],
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return null;
      final bytes = result.files.single.bytes;
      if (bytes == null || bytes.isEmpty) {
        onError?.call('사진을 읽지 못했습니다. JPG 또는 PNG로 다시 시도해주세요.');
        return null;
      }
      raw = Uint8List.fromList(bytes);
    } catch (_) {
      onError?.call('사진 선택 중 오류가 났습니다.');
      return null;
    }
    if (!context.mounted) return null;
    try {
      return await TeacherPhotoCropDialog.show(context, raw);
    } catch (e) {
      print('사진 자르기 닫기 오류: $e');
      return null;
    }
  }
}
