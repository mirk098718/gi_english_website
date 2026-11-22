import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gi_english_website/class/OnlineNativeTeacher.dart';
import 'package:gi_english_website/util/AppLanguage.dart';
import 'package:gi_english_website/util/EnrollmentService.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/UrlIUtil.dart';
import 'package:gi_english_website/widget/AcademyLmsLinks.dart';
import 'package:gi_english_website/widget/assignment_camera.dart';
import 'package:image_picker/image_picker.dart';

/// 글리머 주니어·재원생 화상의 회차별 과제. 화상 시간과는 따로 체크한다.
class AssignmentWorkSection extends StatefulWidget {
  final List<String> checkedIds;
  final List<String> photoUrls;
  final bool enabled;
  final void Function(String itemId, bool checked) onToggle;
  final Future<String?> Function(Uint8List bytes, String fileName) onUpload;
  final Future<String?> Function(String url) onRemove;

  const AssignmentWorkSection({
    Key? key,
    required this.checkedIds,
    required this.photoUrls,
    required this.enabled,
    required this.onToggle,
    required this.onUpload,
    required this.onRemove,
  }) : super(key: key);

  @override
  State<AssignmentWorkSection> createState() => _AssignmentWorkSectionState();
}

class _AssignmentWorkSectionState extends State<AssignmentWorkSection> {
  bool _busy = false;

  Future<void> _capture() async {
    if (!widget.enabled || _busy) return;
    if (widget.photoUrls.length >= EnrollmentService.maxAssignmentPhotos) {
      _toast('사진은 회차마다 ${EnrollmentService.maxAssignmentPhotos}장까지 올릴 수 있습니다.');
      return;
    }
    if (!kIsWeb) {
      await _pickFile(ImageSource.camera);
      return;
    }
    final shot = await captureFromDeviceCamera(context);
    if (!mounted) return;
    final error = shot.error;
    if (error != null) {
      _toast(error);
      return;
    }
    final bytes = shot.bytes;
    if (bytes == null) return;
    await _send(bytes, 'camera.jpg');
  }

  Future<void> _pickGallery() async {
    if (!widget.enabled || _busy) return;
    if (widget.photoUrls.length >= EnrollmentService.maxAssignmentPhotos) {
      _toast('사진은 회차마다 ${EnrollmentService.maxAssignmentPhotos}장까지 올릴 수 있습니다.');
      return;
    }
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'gif'],
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        _toast('사진을 읽지 못했습니다. JPG 또는 PNG로 다시 시도해 주세요.');
        return;
      }
      await _send(Uint8List.fromList(bytes), file.name);
    } catch (_) {
      if (!mounted) return;
      _toast('사진을 열지 못했습니다.');
    }
  }

  Future<void> _pickFile(ImageSource source) async {
    if (!widget.enabled || _busy) return;
    if (widget.photoUrls.length >= EnrollmentService.maxAssignmentPhotos) {
      _toast('사진은 회차마다 ${EnrollmentService.maxAssignmentPhotos}장까지 올릴 수 있습니다.');
      return;
    }
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1600,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      await _send(bytes, file.name);
    } catch (_) {
      if (!mounted) return;
      _toast('카메라를 열지 못했습니다. 브라우저에서 카메라 권한을 허용해 주세요.');
    }
  }

  Future<void> _send(Uint8List bytes, String fileName) async {
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      final error = await widget.onUpload(bytes, fileName);
      if (!mounted) return;
      if (error != null) _toast(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(String url) async {
    if (!widget.enabled || _busy) return;
    setState(() => _busy = true);
    final error = await widget.onRemove(url);
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) _toast(error);
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr(context, message),
            style: TextStyle(fontFamily: 'NotoSansKR')),
        backgroundColor: Palette.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, '온라인 과제'),
          style: TextStyle(fontFamily: 'Jalnan', fontSize: 13),
        ),
        SizedBox(height: 6),
        Text(
          tr(context, '과제 체크는 화상 시간과 따로입니다. 원어민 선생님이 확인만 합니다.'),
          style: TextStyle(
            fontFamily: 'NotoSansKR',
            fontSize: 12,
            height: 1.45,
            color: Palette.grey600,
          ),
        ),
        SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => UrlUtil.open(AcademyLmsLinks.trophy9Url),
          icon: Icon(Icons.open_in_new, size: 18),
          label: Text(
            tr(context, '온라인 과제 바로가기'),
            style: TextStyle(fontFamily: 'NotoSansKR'),
          ),
        ),
        SizedBox(height: 8),
        for (final item in EnrollmentService.assignmentChecklists)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: widget.checkedIds.contains(item.id),
            onChanged: widget.enabled
                ? (value) => widget.onToggle(item.id, value == true)
                : null,
            title: Text(
              tr(context, item.label),
              style: TextStyle(fontFamily: 'NotoSansKR', fontSize: 14),
            ),
          ),
        SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: widget.enabled && !_busy ? _capture : null,
              icon: Icon(Icons.photo_camera_outlined, size: 18),
              label: Text(tr(context, '카메라로 찍기'),
                  style: TextStyle(fontFamily: 'NotoSansKR', fontSize: 12)),
            ),
            OutlinedButton.icon(
              onPressed: widget.enabled && !_busy ? _pickGallery : null,
              icon: Icon(Icons.image_outlined, size: 18),
              label: Text(tr(context, '사진 올리기'),
                  style: TextStyle(fontFamily: 'NotoSansKR', fontSize: 12)),
            ),
            if (_busy)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
        ),
        if (widget.photoUrls.isNotEmpty) ...[
          SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final url in widget.photoUrls)
                Stack(
                  children: [
                    AssignmentPhotoThumb(url: url),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Material(
                        color: Palette.black.withValues(alpha: 0.55),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: widget.enabled ? () => _remove(url) : null,
                          child: Padding(
                            padding: EdgeInsets.all(2),
                            child: Icon(Icons.close, size: 14, color: Palette.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// 강사가 회차를 열었을 때 보는 과제 체크와 사진.
class AssignmentStatusView extends StatelessWidget {
  final bool onlineProblemChecked;
  final bool workbookChecked;
  final List<String> photoUrls;

  const AssignmentStatusView({
    Key? key,
    required this.onlineProblemChecked,
    required this.workbookChecked,
    required this.photoUrls,
  }) : super(key: key);

  Widget _status(
    BuildContext context,
    bool done,
    String doneLabel,
    String pendingLabel,
  ) {
    return Text(
      tr(context, done ? doneLabel : pendingLabel),
      style: TextStyle(
        fontFamily: 'NotoSansKR',
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: done ? Palette.success : Palette.grey700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _status(
          context,
          onlineProblemChecked,
          '온라인 문제풀이 완료',
          '온라인 문제풀이 미완료',
        ),
        SizedBox(height: 4),
        _status(
          context,
          workbookChecked,
          '교재 풀이 완료',
          '교재 풀이 미완료',
        ),
        if (photoUrls.isEmpty)
          Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              tr(context, '올린 사진이 없습니다.'),
              style: TextStyle(
                fontFamily: 'NotoSansKR',
                fontSize: 12,
                color: Palette.grey500,
              ),
            ),
          )
        else ...[
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final url in photoUrls)
                AssignmentPhotoThumb(url: url),
            ],
          ),
        ],
      ],
    );
  }
}

class AssignmentPhotoThumb extends StatelessWidget {
  final String url;

  const AssignmentPhotoThumb({Key? key, required this.url}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (url.startsWith('http://') ||
        url.startsWith('https://') ||
        url.startsWith('data:image')) {
      return _frame(OnlineNativeTeacher.imageProviderOf(url));
    }
    return FutureBuilder<Uint8List?>(
      future: EnrollmentService.assignmentPhotoBytes(url),
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null || bytes.isEmpty) {
          if (snapshot.connectionState != ConnectionState.done) {
            return _frame(null, waiting: true);
          }
          return _frame(null);
        }
        return _frame(MemoryImage(bytes));
      },
    );
  }

  Widget _frame(ImageProvider? provider, {bool waiting = false}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 96,
        height: 96,
        child: provider == null
            ? ColoredBox(
                color: Palette.grey100,
                child: Center(
                  child: waiting
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.broken_image_outlined, color: Palette.grey500),
                ),
              )
            : Image(
                image: provider,
                width: 96,
                height: 96,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => ColoredBox(
                  color: Palette.grey100,
                  child: Icon(Icons.broken_image_outlined, color: Palette.grey500),
                ),
              ),
      ),
    );
  }
}
