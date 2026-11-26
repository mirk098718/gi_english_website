import 'dart:convert';
import 'dart:typed_data';

// ignore: deprecated_member_use
import 'package:gi_english_website/util/html_stub.dart'
    if (dart.library.html) 'dart:html' as html;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gi_english_website/util/AppLanguage.dart';
import 'package:gi_english_website/util/EnrollmentService.dart';
import 'package:gi_english_website/util/LessonMaterialService.dart';
import 'package:gi_english_website/util/Palette.dart';

class LessonMaterialTeacherPanel extends StatelessWidget {
  final List<LessonMaterial> materials;
  final bool enabled;
  final bool busy;
  final Future<String?> Function(Uint8List bytes, String fileName) onUpload;
  final Future<String?> Function(LessonMaterial material) onDelete;

  const LessonMaterialTeacherPanel({
    Key? key,
    required this.materials,
    required this.onUpload,
    required this.onDelete,
    this.enabled = true,
    this.busy = false,
  }) : super(key: key);

  Future<void> _pick(BuildContext context) async {
    if (!enabled || busy) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'pdf'],
      withData: true,
    );
    final file = result?.files.single;
    if (file == null || file.bytes == null) return;
    final error = await onUpload(file.bytes!, file.name);
    if (!context.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(context, error), style: TextStyle(fontFamily: 'NotoSansKR')),
          backgroundColor: Palette.danger,
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr(context, '수강생에게 파일을 보냈습니다.'),
          style: TextStyle(fontFamily: 'NotoSansKR'),
        ),
        backgroundColor: Palette.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, '회차 첨부'),
          style: TextStyle(
            fontFamily: 'NotoSansKR',
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: Palette.grey800,
          ),
        ),
        SizedBox(height: 4),
        Text(
          tr(context, '정답지 PDF나 이미지를 보낼 수 있습니다. 수강생 내 강의실과 알림으로 전달됩니다.'),
          style: TextStyle(
            fontFamily: 'NotoSansKR',
            fontSize: 12,
            height: 1.45,
            color: Palette.grey600,
          ),
        ),
        SizedBox(height: 8),
        if (materials.isNotEmpty)
          ...materials.map(
            (item) => _MaterialRow(
              material: item,
              onOpen: () => _openRef(context, item.ref, item.fileName),
              onDelete: enabled && !busy
                  ? () async {
                      final error = await onDelete(item);
                      if (!context.mounted || error == null) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(tr(context, error),
                              style: TextStyle(fontFamily: 'NotoSansKR')),
                          backgroundColor: Palette.danger,
                        ),
                      );
                    }
                  : null,
            ),
          ),
        if (enabled)
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: busy ? null : () => _pick(context),
              icon: Icon(Icons.attach_file, size: 18),
              label: Text(
                tr(context, '파일 보내기'),
                style: TextStyle(fontFamily: 'NotoSansKR', fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }
}

class LessonMaterialStudentPanel extends StatelessWidget {
  final List<LessonMaterial> materials;

  const LessonMaterialStudentPanel({Key? key, required this.materials})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (materials.isEmpty) return SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, '강사 자료'),
          style: TextStyle(
            fontFamily: 'NotoSansKR',
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Palette.navy,
          ),
        ),
        SizedBox(height: 6),
        ...materials.map(
          (item) => _MaterialRow(
            material: item,
            onOpen: () => _openRef(context, item.ref, item.fileName),
          ),
        ),
      ],
    );
  }
}

class _MaterialRow extends StatelessWidget {
  final LessonMaterial material;
  final VoidCallback onOpen;
  final VoidCallback? onDelete;

  const _MaterialRow({
    required this.material,
    required this.onOpen,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final icon = material.isPdf ? Icons.picture_as_pdf : Icons.image_outlined;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Palette.grey50,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Icon(icon, size: 18, color: Palette.darkTeal),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    material.fileName,
                    style: TextStyle(fontFamily: 'NotoSansKR', fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  EnrollmentService.formatBookingDate(material.createdAt),
                  style: TextStyle(
                    fontFamily: 'NotoSansKR',
                    fontSize: 11,
                    color: Palette.grey500,
                  ),
                ),
                if (onDelete != null) ...[
                  SizedBox(width: 4),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints.tightFor(width: 32, height: 32),
                    onPressed: onDelete,
                    icon: Icon(Icons.delete_outline, size: 18),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _openRef(BuildContext context, String ref, String fileName) async {
  final bytes = await LessonMaterialService.bytesForRef(ref);
  if (bytes == null) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr(context, '파일을 열지 못했습니다.'),
          style: TextStyle(fontFamily: 'NotoSansKR'),
        ),
      ),
    );
    return;
  }
  final mime =
      await LessonMaterialService.mimeForRef(ref) ?? 'application/octet-stream';
  final dataUrl = 'data:$mime;base64,${_b64(bytes)}';
  if (kIsWeb) {
    final anchor = html.AnchorElement(href: dataUrl)
      ..download = fileName
      ..target = '_blank';
    anchor.click();
    return;
  }
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        tr(context, '웹에서 파일을 열어 주세요.'),
        style: TextStyle(fontFamily: 'NotoSansKR'),
      ),
    ),
  );
}

String _b64(Uint8List bytes) => base64Encode(bytes);