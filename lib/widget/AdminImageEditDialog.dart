import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gi_english_website/util/GalleryService.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/class/GalleryImage.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui;

class AdminImageEditDialog extends StatefulWidget {
  final GalleryImage image;

  const AdminImageEditDialog({Key? key, required this.image}) : super(key: key);

  @override
  _AdminImageEditDialogState createState() => _AdminImageEditDialogState();
}

class _AdminImageEditDialogState extends State<AdminImageEditDialog> {
  String _description = '';
  bool _isUpdating = false;
  String _updateStatus = '';

  late html.TextAreaElement descriptionTextArea;

  @override
  void initState() {
    super.initState();
    _description = widget.image.description;
    _registerHtmlTextArea();
  }

  void _registerHtmlTextArea() {
    // 설명 입력 텍스트 에리어 등록
    ui.platformViewRegistry.registerViewFactory(
      'edit-description-textarea-${widget.image.id}', // 고유 ID 사용
      (int viewId) {
        descriptionTextArea = html.TextAreaElement();
        descriptionTextArea.value = _description; // 기존 설명으로 초기화
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
            print('📝 설명 수정 입력: ${descriptionTextArea.value}');
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

  Future<void> _updateImage() async {
    // HTML textarea에서 최신 값을 가져와서 동기화
    String finalDescription = _description;
    try {
      String textareaValue = descriptionTextArea.value?.trim() ?? '';
      if (textareaValue.isNotEmpty) {
        finalDescription = textareaValue;
        setState(() {
          _description = finalDescription;
        });
      }
    } catch (e) {
      print('⚠️ textarea 값 읽기 실패, 현재 상태 사용: $e');
    }

    print('🔄 이미지 설명 업데이트 시작...');
    print('📝 새 설명: "$finalDescription"');
    print('📝 기존 설명: "${widget.image.description}"');

    // 설명이 변경되지 않았으면 업데이트하지 않음
    if (finalDescription == widget.image.description) {
      _showSnackBar('설명이 변경되지 않았습니다.', Colors.orange);
      return;
    }

    setState(() {
      _isUpdating = true;
      _updateStatus = '설명 업데이트 중...';
    });

    try {
      await GalleryService.updateImageDescription(
        widget.image.id,
        finalDescription,
      );

      setState(() {
        _updateStatus = '업데이트 완료!';
      });

      print('✅ 이미지 설명 업데이트 성공!');
      _showSnackBar('이미지 설명이 성공적으로 업데이트되었습니다!', Colors.green);

      // 잠시 대기 후 다이얼로그 닫기
      await Future.delayed(Duration(milliseconds: 500));
      Navigator.of(context).pop(true); // 성공 시 true 반환
    } catch (e) {
      print('❌ 이미지 설명 업데이트 실패: $e');
      setState(() {
        _updateStatus = '업데이트 실패';
      });
      _showSnackBar('이미지 설명 업데이트 중 오류가 발생했습니다: $e', Colors.red);
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  Future<void> _deleteImage() async {
    // 삭제 확인 다이얼로그
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '이미지 삭제',
          style: TextStyle(fontFamily: "Jalnan"),
        ),
        content: Text(
          '이 이미지를 정말 삭제하시겠습니까?\n삭제된 이미지는 복구할 수 없습니다.',
          style: TextStyle(fontFamily: "NotoSansKR"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              '취소',
              style: TextStyle(fontFamily: "NotoSansKR"),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(
              '삭제',
              style: TextStyle(fontFamily: "NotoSansKR"),
            ),
          ),
        ],
      ),
    );

    if (confirmDelete != true) return;

    setState(() {
      _isUpdating = true;
      _updateStatus = '이미지 삭제 중...';
    });

    try {
      await GalleryService.deleteImage(widget.image.id);

      setState(() {
        _updateStatus = '삭제 완료!';
      });

      print('✅ 이미지 삭제 성공!');
      _showSnackBar('이미지가 성공적으로 삭제되었습니다!', Colors.green);

      // 잠시 대기 후 다이얼로그 닫기
      await Future.delayed(Duration(milliseconds: 500));
      Navigator.of(context).pop(true); // 성공 시 true 반환
    } catch (e) {
      print('❌ 이미지 삭제 실패: $e');
      setState(() {
        _updateStatus = '삭제 실패';
      });
      _showSnackBar('이미지 삭제 중 오류가 발생했습니다: $e', Colors.red);
    } finally {
      setState(() {
        _isUpdating = false;
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
                    '이미지 수정/삭제',
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

              // 이미지 미리보기
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Palette.grey300, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: Palette.grey50,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    base64Decode(widget.image.imageData),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Palette.grey200,
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image,
                                color: Palette.grey400, size: 32),
                            SizedBox(height: 8),
                            Text(
                              '이미지를 불러올 수 없습니다',
                              style: TextStyle(
                                color: Palette.grey600,
                                fontSize: 12,
                                fontFamily: "NotoSansKR",
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 파일 정보
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Palette.grey50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Palette.grey200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.image,
                            size: 16, color: Palette.grey600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.image.fileName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontFamily: "NotoSansKR",
                              color: Palette.grey700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '업로드일: ${widget.image.uploadedAt.toString().split(' ')[0]}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: "NotoSansKR",
                        color: Palette.grey600,
                      ),
                    ),
                    Text(
                      '크기: ${(widget.image.imageSize / 1024 / 1024).toStringAsFixed(2)} MB',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: "NotoSansKR",
                        color: Palette.grey600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 설명 수정 필드
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
                child: HtmlElementView(
                    viewType: 'edit-description-textarea-${widget.image.id}'),
              ),
              const SizedBox(height: 16),

              // 업데이트 진행률 표시
              if (_isUpdating) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Palette.grey50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Palette.grey300),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Palette.primary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _updateStatus,
                          style: const TextStyle(
                            fontFamily: "NotoSansKR",
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 버튼들
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 삭제 버튼
                  TextButton.icon(
                    onPressed: _isUpdating ? null : _deleteImage,
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text(
                      '삭제',
                      style: TextStyle(
                        fontFamily: "NotoSansKR",
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // 취소/수정 버튼
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          '취소',
                          style: TextStyle(
                            fontFamily: "NotoSansKR",
                            color:
                                _isUpdating ? Palette.grey400 : Palette.grey600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isUpdating ? null : _updateImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Palette.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isUpdating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                '수정',
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
            ],
          ),
        ),
      ),
    );
  }
}
