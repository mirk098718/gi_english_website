import 'package:flutter/material.dart';
import 'package:gi_english_website/class/Notice.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/NoticeService.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/widget/WebSchoolLayout.dart';
import 'package:gi_english_website/widget/MobileSchoolLayout.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui;

class AdminNoticeWritePage extends StatefulWidget {
  final Notice? notice; // 수정 모드일 때 사용

  const AdminNoticeWritePage({Key? key, this.notice}) : super(key: key);

  @override
  _AdminNoticeWritePageState createState() => _AdminNoticeWritePageState();
}

class _AdminNoticeWritePageState extends State<AdminNoticeWritePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  bool _isImportant = false;
  bool _isLoading = false;
  bool _isEditMode = false;

  // HTML input 관련
  String titleValue = '';
  String contentValue = '';
  late html.InputElement titleInput;
  late html.TextAreaElement contentInput;
  String titleViewType = '';
  String contentViewType = '';

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.notice != null;
    
    // 고유한 viewType 생성 (수정 시 새로운 input을 만들기 위해)
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    titleViewType = 'title-input-$timestamp';
    contentViewType = 'content-input-$timestamp';
    
    _checkAdminStatus();
    _registerHtmlInputs();

    if (_isEditMode) {
      _titleController.text = widget.notice!.title;
      _contentController.text = widget.notice!.content;
      titleValue = widget.notice!.title;
      contentValue = widget.notice!.content;
      _isImportant = widget.notice!.isImportant;

      // HTML input에도 값 설정 (약간의 지연 후)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          titleInput.value = titleValue;
          contentInput.value = contentValue;
        }
      });
    }
  }

  void _registerHtmlInputs() {
    // 제목 입력 필드 등록
    ui.platformViewRegistry.registerViewFactory(
      titleViewType,
      (int viewId) {
        titleInput = html.InputElement();
        titleInput.type = 'text';
        titleInput.placeholder = '공지사항 제목을 입력하세요';
        titleInput.value = titleValue;
        titleInput.style.cssText = '''
          width: 100%;
          height: 50px;
          font-size: 16px;
          padding: 12px 16px;
          border: 1px solid #ccc;
          border-radius: 8px;
          outline: none;
          font-family: 'NotoSansKR', sans-serif;
        ''';

        titleInput.onInput.listen((event) {
          if (mounted) {
            setState(() {
              titleValue = titleInput.value ?? '';
            });
          }
        });

        titleInput.onFocus.listen((event) {
          titleInput.style.borderColor = '#4F46E5';
        });

        titleInput.onBlur.listen((event) {
          titleInput.style.borderColor = '#ccc';
        });

        return titleInput;
      },
    );

    // 내용 입력 필드 등록 (TextArea)
    ui.platformViewRegistry.registerViewFactory(
      contentViewType,
      (int viewId) {
        contentInput = html.TextAreaElement();
        contentInput.placeholder = '공지사항 내용을 입력하세요';
        contentInput.value = contentValue;
        contentInput.style.cssText = '''
          width: 100%;
          height: 400px;
          font-size: 16px;
          padding: 16px;
          border: 1px solid #ccc;
          border-radius: 8px;
          outline: none;
          font-family: 'NotoSansKR', sans-serif;
          resize: vertical;
        ''';

        contentInput.onInput.listen((event) {
          if (mounted) {
            setState(() {
              contentValue = contentInput.value ?? '';
            });
          }
        });

        contentInput.onFocus.listen((event) {
          contentInput.style.borderColor = '#4F46E5';
        });

        contentInput.onBlur.listen((event) {
          contentInput.style.borderColor = '#ccc';
        });

        return contentInput;
      },
    );
  }

  Future<void> _checkAdminStatus() async {
    bool isAdmin = await AuthService.isAdmin();
    if (!isAdmin) {
      // 관리자가 아니면 이전 페이지로 돌아가기
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('관리자 권한이 필요합니다. 다시 로그인해주세요.'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    MediaQueryData mediaQueryData = MediaQuery.of(context);
    Size size = mediaQueryData.size;
    double width = size.width;

    if (width > 768) {
      return WebSchoolLayout(content: _buildScrollView());
    } else {
      return MobileSchoolLayout(content: _buildScrollView());
    }
  }

  Widget _buildScrollView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildMainImage(),
          _buildContentGroup(),
          MyWidget.footer(),
        ],
      ),
    );
  }

  Widget _buildMainImage() {
    return Container(
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          Image.asset("assets/communityMainImage.png"),
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
                      fontFamily: "LucidaCalligraphy"),
                ),
                SizedBox(height: 20),
                Container(
                  width: 150,
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Palette.black,
                      foregroundColor: Palette.black,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text("뒤로가기",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: "Jalnan",
                          color: Palette.white,
                        )),
                  ),
                ),
              ],
            ),
          )
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
          Container(
            height: 2,
            width: 100,
            color: Palette.primary,
          ),
          SizedBox(height: 40),
          _buildForm(),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목 입력
          Text(
            "제목",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: "NotoSansKR",
            ),
          ),
          SizedBox(height: 8),
          Container(
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: HtmlElementView(viewType: titleViewType),
          ),
          SizedBox(height: 24),

          // 중요 공지 체크박스
          Row(
            children: [
              Checkbox(
                value: _isImportant,
                onChanged: (value) {
                  setState(() {
                    _isImportant = value ?? false;
                  });
                },
                activeColor: Palette.primary,
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

          // 내용 입력
          Text(
            "내용",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: "NotoSansKR",
            ),
          ),
          SizedBox(height: 8),
          Container(
            height: 400,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: HtmlElementView(viewType: contentViewType),
          ),
          SizedBox(height: 40),

          // 버튼들
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 취소 버튼
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

              // 저장 버튼
              SizedBox(
                width: 120,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveNotice,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Palette.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Palette.white),
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
      ),
    );
  }

  Future<void> _saveNotice() async {
    // HTML input 값으로 유효성 검사
    if (titleValue.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('제목을 입력해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (contentValue.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('내용을 입력해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 저장하기 전에 관리자 권한 다시 확인
    bool isAdmin = await AuthService.isAdmin();
    if (!isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('관리자 권한이 필요합니다. 다시 로그인해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String authorName = await AuthService.getAdminName();

      Notice notice = Notice(
        title: titleValue.trim(),
        content: contentValue.trim(),
        author: authorName,
        createdAt: _isEditMode ? widget.notice!.createdAt : DateTime.now(),
        isImportant: _isImportant,
      );

      bool success;
      if (_isEditMode) {
        success = await NoticeService.updateNotice(widget.notice!.id!, notice);
      } else {
        String? noticeId = await NoticeService.addNotice(notice);
        success = noticeId != null;
      }

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode ? '공지사항이 수정되었습니다.' : '공지사항이 저장되었습니다.',
              style: TextStyle(fontFamily: "NotoSansKR"),
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // 성공 시 true 반환
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode ? '공지사항 수정에 실패했습니다.' : '공지사항 저장에 실패했습니다.',
              style: TextStyle(fontFamily: "NotoSansKR"),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '오류가 발생했습니다: $e',
            style: TextStyle(fontFamily: "NotoSansKR"),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
