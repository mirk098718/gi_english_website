import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:gi_english_website/util/GalleryService.dart';
import 'package:gi_english_website/util/Palette.dart';
// ignore: deprecated_member_use
import 'package:gi_english_website/util/html_stub.dart'
    if (dart.library.html) 'dart:html' as html;
import 'package:gi_english_website/util/ui_web_stub.dart'
    if (dart.library.html) 'dart:ui_web' as ui;

class AdminImageUploadDialog extends StatefulWidget {
  const AdminImageUploadDialog({Key? key}) : super(key: key);

  @override
  _AdminImageUploadDialogState createState() => _AdminImageUploadDialogState();
}

class _AdminImageUploadDialogState extends State<AdminImageUploadDialog> {
  Uint8List? _selectedImageData;
  String? _selectedFileName;
  String _description = '';
  final _descriptionController = TextEditingController();
  bool _isUploading = false;
  String _uploadStatus = '';
  double _uploadProgress = 0.0;

  late html.TextAreaElement descriptionTextArea;

  @override
  void initState() {
    super.initState();
    _registerHtmlTextArea();
  }

  void _registerHtmlTextArea() {
    // 설명 입력 텍스트 에리어 등록
    ui.platformViewRegistry.registerViewFactory(
      'description-textarea',
      (int viewId) {
        descriptionTextArea = html.TextAreaElement();
        descriptionTextArea.placeholder = '이미지에 대한 설명을 입력해주세요 (선택사항)';
        descriptionTextArea.style.cssText = '''
          width: 100%;
          height: 80px;
          font-size: 14px;
          padding: 12px;
          border: 1px solid #ccc;
          border-radius: 8px;
          outline: none;
          font-family: 'NotoSansKR', sans-serif;
          resize: vertical;
          box-sizing: border-box;
        ''';

        descriptionTextArea.onInput.listen((event) {
          if (mounted) {
            setState(() {
              _description = descriptionTextArea.value ?? '';
            });
            print('📝 설명 입력: ${descriptionTextArea.value}');
          }
        });

        descriptionTextArea.onFocus.listen((event) {
          descriptionTextArea.style.borderColor = '#4F46E5';
        });

        descriptionTextArea.onBlur.listen((event) {
          descriptionTextArea.style.borderColor = '#ccc';
        });

        return descriptionTextArea;
      },
    );
  }

  @override
  void dispose() {
    // 상태 초기화
    _selectedImageData = null;
    _selectedFileName = null;
    _description = '';
    _isUploading = false;
    _descriptionController.dispose();
    super.dispose();
  }

  void _resetState() {
    setState(() {
      _selectedImageData = null;
      _selectedFileName = null;
      _description = '';
      _descriptionController.clear();
      _isUploading = false;
      _uploadStatus = '';
      _uploadProgress = 0.0;
    });
    // HTML textarea 내용도 초기화
    try {
      descriptionTextArea.value = '';
    } catch (e) {
      print('텍스트 에리어 초기화 오류: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      print('🔄 파일 선택 시작...');

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp'],
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        print('✅ 파일 선택 완료: ${result.files.single.name}');
        setState(() {
          _selectedImageData = result.files.single.bytes!;
          _selectedFileName = result.files.single.name;
          _description = '';
          _descriptionController.clear();
        });
        print(
            '📊 파일 크기: ${(_selectedImageData!.length / 1024 / 1024).toStringAsFixed(2)} MB');
      } else {
        print('❌ 파일 선택 취소 또는 데이터 없음');
      }
    } catch (e) {
      print('❌ 파일 선택 오류: $e');
      _showSnackBar('이미지 선택 중 오류가 발생했습니다: $e', Colors.red);
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImageData == null || _selectedFileName == null) {
      _showSnackBar('먼저 이미지를 선택해주세요.', Colors.orange);
      return;
    }

    print('🚀 이미지 업로드 시작...');
    print('📁 파일명: $_selectedFileName');
    print(
        '📏 파일 크기: ${(_selectedImageData!.length / 1024 / 1024).toStringAsFixed(2)} MB');

    setState(() {
      _isUploading = true;
      _uploadStatus = 'Firebase 연결 확인 중...';
      _uploadProgress = 0.1;
    });

    try {
      print('📤 GalleryService.addImage 호출 중...');

      // HTML textarea에서 직접 설명 읽어오기
      String description = '';
      try {
        // 강제로 상태 동기화
        setState(() {
          _description = descriptionTextArea.value?.trim() ?? '';
        });
        description = _description;
        print('📝 HTML textarea에서 읽은 설명: "$description"');
        print('📝 Flutter 상태 _description: "$_description"');
      } catch (e) {
        print('❌ HTML textarea 읽기 오류: $e');
        description = _description.trim();
      }

      // 설명이 비어있으면 빈 문자열로 유지 (기본값 설정하지 않음)
      if (description.isEmpty) {
        print('📝 설명이 비어있음 - 빈 문자열로 업로드');
      }

      setState(() {
        _uploadStatus = '이미지 압축 중...';
        _uploadProgress = 0.2;
      });

      await GalleryService.addImage(
        imageData: _selectedImageData!,
        fileName: _selectedFileName!,
        description: description, // 빈 문자열이어도 그대로 전달
      );

      setState(() {
        _uploadStatus = '업로드 완료!';
        _uploadProgress = 1.0;
      });

      print('✅ 이미지 업로드 성공!');
      _showSnackBar('이미지가 성공적으로 업로드되었습니다!', Colors.green);

      // 잠시 대기 후 다이얼로그 닫기
      await Future.delayed(Duration(milliseconds: 500));
      Navigator.of(context).pop(true); // 성공 시 true 반환
    } catch (e) {
      print('❌ 이미지 업로드 실패: $e');
      setState(() {
        _uploadStatus = '업로드 실패';
        _uploadProgress = 0.0;
      });
      _showSnackBar('이미지 업로드 중 오류가 발생했습니다: $e', Colors.red);
    } finally {
      print('🔄 업로드 상태 리셋');
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(message, style: const TextStyle(fontFamily: "NotoSansKR")),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '갤러리 이미지 업로드',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: "Jalnan",
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 이미지 선택 영역
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Palette.grey300, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: Palette.grey50,
                ),
                child: _selectedImageData != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          _selectedImageData!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      )
                    : InkWell(
                        onTap: _pickImage,
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_upload_outlined,
                              size: 48,
                              color: Palette.grey400,
                            ),
                            SizedBox(height: 8),
                            Text(
                              '클릭하여 이미지 선택',
                              style: TextStyle(
                                color: Palette.grey600,
                                fontSize: 16,
                                fontFamily: "NotoSansKR",
                              ),
                            ),
                            Text(
                              'JPG, PNG 파일만 지원',
                              style: TextStyle(
                                color: Palette.grey400,
                                fontSize: 12,
                                fontFamily: "NotoSansKR",
                              ),
                            ),
                          ],
                        ),
                      ),
              ),

              if (_selectedFileName != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.image, size: 16, color: Palette.grey600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedFileName!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: "NotoSansKR",
                          color: Palette.grey700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _resetState();
                        _pickImage();
                      },
                      child: const Text(
                        '다시 선택',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: "NotoSansKR",
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 20),

              // 이미지가 선택된 경우에만 설명 입력 필드 표시
              if (_selectedImageData != null) ...[
                const Text(
                  '이미지 설명 (선택사항)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: "NotoSansKR",
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: kIsWeb
                      ? HtmlElementView(viewType: 'description-textarea')
                      : TextField(
                          controller: _descriptionController,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          onChanged: (value) => _description = value,
                          decoration: const InputDecoration(
                            hintText: '이미지에 대한 설명을 입력해주세요 (선택사항)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                ),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 24),

              // 업로드 진행률 표시
              if (_isUploading) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Palette.grey50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Palette.grey300),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Palette.primary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _uploadStatus,
                              style: const TextStyle(
                                fontFamily: "NotoSansKR",
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _uploadProgress,
                        backgroundColor: Palette.grey300,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Palette.primary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(_uploadProgress * 100).toInt()}%',
                        style: const TextStyle(
                          fontFamily: "NotoSansKR",
                          fontSize: 12,
                          color: Palette.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 버튼들
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      '취소',
                      style: TextStyle(
                        fontFamily: "NotoSansKR",
                        color: _isUploading ? Palette.grey400 : Palette.grey600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_selectedImageData != null)
                    ElevatedButton(
                      onPressed: _isUploading ? null : _uploadImage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Palette.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isUploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              '업로드',
                              style: TextStyle(
                                fontFamily: "NotoSansKR",
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
