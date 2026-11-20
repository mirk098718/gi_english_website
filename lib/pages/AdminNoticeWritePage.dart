import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gi_english_website/class/Notice.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/NoticeImages.dart';
import 'package:gi_english_website/util/NoticeService.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/SiteLayout.dart';
import 'package:gi_english_website/widget/AcademyHeroBanner.dart';
import 'package:gi_english_website/widget/MobileSchoolLayout.dart';
import 'package:gi_english_website/widget/NoticeAttachedImage.dart';
import 'package:gi_english_website/widget/NoticeBodyField.dart';
import 'package:gi_english_website/widget/WebSchoolLayout.dart';
import 'package:gi_english_website/util/MyWidget.dart';

class AdminNoticeWritePage extends StatefulWidget {
  final Notice? notice;

  const AdminNoticeWritePage({Key? key, this.notice}) : super(key: key);

  @override
  _AdminNoticeWritePageState createState() => _AdminNoticeWritePageState();
}

class _AdminNoticeWritePageState extends State<AdminNoticeWritePage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _contentFocus = FocusNode();

  bool _isImportant = false;
  bool _isLoading = false;
  bool _isUploadingImage = false;
  bool _isEditMode = false;
  bool _keepUploads = false;
  final List<String> _imageUrls = [];
  final List<String> _sessionUploads = [];

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.notice != null;
    _checkAdminStatus();

    if (_isEditMode) {
      _titleController.text = widget.notice!.title;
      _contentController.text = widget.notice!.content;
      _isImportant = widget.notice!.isImportant;
      _imageUrls.addAll(widget.notice!.imageUrls);
    }
  }

  Future<void> _checkAdminStatus() async {
    bool isAdmin = await AuthService.isAdmin();
    if (!isAdmin && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _snack('관리자 권한이 필요합니다. 다시 로그인해주세요.');
        Navigator.pop(context);
      });
    }
  }

  @override
  void dispose() {
    if (!_keepUploads && _sessionUploads.isNotEmpty) {
      NoticeService.deleteNoticeImages(List<String>.from(_sessionUploads));
    }
    _titleController.dispose();
    _contentController.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!useMobileSchoolLayout(context)) {
      return WebSchoolLayout(content: _buildScrollView(includeFooter: true));
    } else {
      return MobileSchoolLayout(
        content: _buildScrollView(includeFooter: false),
      );
    }
  }

  Widget _buildScrollView({required bool includeFooter}) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildMainImage(),
          _buildContentGroup(),
          if (includeFooter) MyWidget.footer(),
        ],
      ),
    );
  }

  Widget _buildMainImage() {
    return Container(
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          AcademyHeroBanner.photo(AcademyHeroBanner.community),
          Container(
            padding: EdgeInsets.only(left: 40, bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  _isEditMode ? "Notice Edit" : "Notice Write",
                  style: TextStyle(
                    color: Palette.white,
                    fontSize: 30,
                    fontFamily: "LucidaCalligraphy",
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  width: 150,
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Palette.navy,
                      foregroundColor: Palette.black,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      "뒤로가기",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: "Jalnan",
                        color: Palette.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentGroup() {
    return Container(
      color: Palette.white,
      padding: EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isEditMode ? "공지사항 수정" : "공지사항 작성",
            style: TextStyle(
              fontFamily: "Jalnan",
              fontSize: 24,
              color: Palette.black,
            ),
          ),
          SizedBox(height: 8),
          Container(height: 2, width: 100, color: Palette.darkTeal),
          SizedBox(height: 40),
          _buildForm(),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "제목",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: "NotoSansKR",
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: _titleController,
          enableInteractiveSelection: true,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _contentFocus.requestFocus(),
          style: TextStyle(fontFamily: "NotoSansKR", fontSize: 16),
          decoration: InputDecoration(
            hintText: '공지사항 제목을 입력하세요',
            hintStyle: TextStyle(
              fontFamily: "NotoSansKR",
              color: Palette.grey400,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Palette.grey300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Palette.primary, width: 1.5),
            ),
          ),
        ),
        SizedBox(height: 24),
        Row(
          children: [
            Checkbox(
              value: _isImportant,
              onChanged: (value) {
                setState(() {
                  _isImportant = value ?? false;
                });
              },
              activeColor: Palette.darkTeal,
            ),
            Text(
              "중요 공지사항",
              style: TextStyle(
                fontSize: 14,
                fontFamily: "NotoSansKR",
                color: Palette.grey700,
              ),
            ),
          ],
        ),
        SizedBox(height: 24),
        Text(
          "내용",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: "NotoSansKR",
          ),
        ),
        SizedBox(height: 8),
        NoticeBodyField(
          controller: _contentController,
          focusNode: _contentFocus,
        ),
        SizedBox(height: 24),
        _buildImageSection(),
        SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 120,
              height: 48,
              child: OutlinedButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        Navigator.pop(context);
                      },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Palette.grey400),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  "취소",
                  style: TextStyle(
                    fontFamily: "NotoSansKR",
                    fontSize: 16,
                    color: Palette.grey700,
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            SizedBox(
              width: 120,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveNotice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Palette.darkTeal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Palette.white,
                          ),
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _isEditMode ? "수정" : "저장",
                        style: TextStyle(
                          fontFamily: "NotoSansKR",
                          fontSize: 16,
                          color: Palette.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    final atLimit = _imageUrls.length >= NoticeImages.maxCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              "이미지",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: "NotoSansKR",
              ),
            ),
            OutlinedButton.icon(
              onPressed: (_isLoading || _isUploadingImage || atLimit)
                  ? null
                  : _pickImages,
              icon: _isUploadingImage
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.image_outlined, size: 18),
              label: Text(
                _isUploadingImage ? "사진 저장 중..." : "이미지 첨부",
                style: TextStyle(fontFamily: "NotoSansKR"),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Palette.darkTeal,
                side: BorderSide(color: Palette.darkTeal),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          "휴대폰 사진도 자동으로 줄여 저장합니다. jpg, png, gif, webp · ${NoticeImages.maxCount}장\n첨부한 이미지는 본문 아래에 표시됩니다.",
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            fontFamily: "NotoSansKR",
            color: Palette.grey600,
          ),
        ),
        if (_imageUrls.isNotEmpty) ...[
          SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (var i = 0; i < _imageUrls.length; i++) _buildThumb(i),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildThumb(int index) {
    final url = _imageUrls[index];
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: NoticeAttachedImage(
                source: url,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _isLoading ? null : () => _removeImage(index),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImages() async {
    if (_imageUrls.length >= NoticeImages.maxCount) {
      _snack('이미지는 최대 ${NoticeImages.maxCount}장까지 첨부할 수 있습니다.');
      return;
    }

    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: NoticeImages.extensions,
        allowMultiple: true,
        withData: true,
      );
    } catch (e) {
      _snack('이미지를 선택하지 못했습니다. ${_errorText(e)}');
      return;
    }
    if (result == null || !mounted) return;

    setState(() => _isUploadingImage = true);
    try {
      for (final file in result.files) {
        if (!mounted) return;
        if (_imageUrls.length >= NoticeImages.maxCount) {
          _snack('이미지는 최대 ${NoticeImages.maxCount}장까지 첨부할 수 있습니다.');
          break;
        }
        await _uploadOne(file.name, file.bytes);
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _uploadOne(String name, Uint8List? bytes) async {
    if (bytes == null) {
      _snack('이미지 파일을 읽지 못했습니다.');
      return;
    }
    final reason = NoticeImages.rejectionReason(
      fileName: name,
      byteLength: bytes.length,
    );
    if (reason != null) {
      _snack(reason);
      return;
    }

    try {
      final url = await NoticeService.uploadNoticeImage(
        bytes: bytes,
        fileName: name,
      );
      if (!mounted) {
        NoticeService.deleteNoticeImages([url]);
        return;
      }
      setState(() {
        _imageUrls.add(url);
        _sessionUploads.add(url);
      });
    } catch (e) {
      _snack('이미지를 올리지 못했습니다. ${_errorText(e)}');
    }
  }

  Future<void> _removeImage(int index) async {
    final url = _imageUrls[index];
    setState(() {
      _imageUrls.removeAt(index);
    });
    if (_sessionUploads.remove(url)) {
      await NoticeService.deleteNoticeImages([url]);
    }
  }

  List<String> _removedOriginals() {
    if (!_isEditMode) return const [];
    final kept = _imageUrls.toSet();
    return widget.notice!.imageUrls
        .where((url) => !kept.contains(url))
        .toList();
  }

  Future<void> _saveNotice() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty) {
      _snack('제목을 입력해주세요.');
      return;
    }
    if (content.isEmpty && _imageUrls.isEmpty) {
      _snack('내용을 입력하거나 이미지를 첨부해주세요.');
      return;
    }
    if (_isUploadingImage) {
      _snack('이미지 첨부가 끝날 때까지 기다려 주세요.');
      return;
    }

    bool isAdmin = await AuthService.isAdmin();
    if (!isAdmin) {
      _snack('관리자 권한이 필요합니다. 다시 로그인해주세요.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String authorName = await AuthService.getAdminName();
      final removed = _removedOriginals();

      Notice notice = Notice(
        title: title,
        content: content,
        author: authorName,
        createdAt: _isEditMode ? widget.notice!.createdAt : DateTime.now(),
        isImportant: _isImportant,
        imageUrls: List<String>.from(_imageUrls),
      );

      bool success;
      if (_isEditMode) {
        success = await NoticeService.updateNotice(widget.notice!.id!, notice);
      } else {
        String? noticeId = await NoticeService.addNotice(notice);
        success = noticeId != null;
      }

      if (!mounted) return;

      if (success) {
        _keepUploads = true;
        _sessionUploads.clear();
        if (removed.isNotEmpty) {
          NoticeService.deleteNoticeImages(removed);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode ? '공지사항이 수정되었습니다.' : '공지사항이 저장되었습니다.',
              style: TextStyle(fontFamily: "NotoSansKR"),
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        _snack(_isEditMode ? '공지사항 수정에 실패했습니다.' : '공지사항 저장에 실패했습니다.');
      }
    } catch (e) {
      _snack('오류가 발생했습니다: ${_errorText(e)}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontFamily: "NotoSansKR")),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _errorText(Object error) {
    final text = error.toString();
    const prefix = 'Exception: ';
    return text.startsWith(prefix) ? text.substring(prefix.length) : text;
  }
}
