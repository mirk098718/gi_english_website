import 'package:flutter/material.dart';
import 'package:gi_english_website/class/FAQ.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/FAQService.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/widget/WebSchoolLayout.dart';
import 'package:gi_english_website/widget/MobileSchoolLayout.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui;

class AdminFAQWritePage extends StatefulWidget {
  final FAQ? faq; // 수정 모드일 때 사용

  const AdminFAQWritePage({Key? key, this.faq}) : super(key: key);

  @override
  _AdminFAQWritePageState createState() => _AdminFAQWritePageState();
}

class _AdminFAQWritePageState extends State<AdminFAQWritePage> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();
  final _categoryController = TextEditingController();

  bool _isImportant = false;
  bool _isLoading = false;
  bool _isEditMode = false;

  // HTML input 관련
  String questionValue = '';
  String answerValue = '';
  String categoryValue = '';
  late html.InputElement questionInput;
  late html.TextAreaElement answerInput;
  late html.InputElement categoryInput;
  String questionViewType = '';
  String answerViewType = '';
  String categoryViewType = '';

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.faq != null;
    
    // 고유한 viewType 생성 (수정 시 새로운 input을 만들기 위해)
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    questionViewType = 'question-input-$timestamp';
    answerViewType = 'answer-input-$timestamp';
    categoryViewType = 'category-input-$timestamp';
    
    _checkAdminStatus();
    _registerHtmlInputs();

    if (_isEditMode) {
      _questionController.text = widget.faq!.question;
      _answerController.text = widget.faq!.answer;
      _categoryController.text = widget.faq!.category;
      questionValue = widget.faq!.question;
      answerValue = widget.faq!.answer;
      categoryValue = widget.faq!.category;
      _isImportant = widget.faq!.isImportant;

      // HTML input에도 값 설정 (약간의 지연 후)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          questionInput.value = questionValue;
          answerInput.value = answerValue;
          categoryInput.value = categoryValue;
        }
      });
    } else {
      _categoryController.text = '일반';
      categoryValue = '일반';
      
      // HTML input에도 값 설정 (약간의 지연 후)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          categoryInput.value = categoryValue;
        }
      });
    }
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

  void _registerHtmlInputs() {
    // 카테고리 입력 필드 등록
    ui.platformViewRegistry.registerViewFactory(
      categoryViewType,
      (int viewId) {
        categoryInput = html.InputElement();
        categoryInput.type = 'text';
        categoryInput.placeholder = '카테고리를 입력하세요 (예: 일반, 수업, 교재)';
        categoryInput.value = categoryValue;
        categoryInput.style.cssText = '''
          width: 100%;
          height: 50px;
          font-size: 16px;
          padding: 12px 16px;
          border: 1px solid #ccc;
          border-radius: 8px;
          outline: none;
          font-family: 'NotoSansKR', sans-serif;
          user-select: text;
          -webkit-user-select: text;
          -moz-user-select: text;
          -ms-user-select: text;
        ''';

        categoryInput.onInput.listen((event) {
          if (mounted) {
            setState(() {
              categoryValue = categoryInput.value ?? '';
            });
          }
        });

        categoryInput.onFocus.listen((event) {
          categoryInput.style.borderColor = '#4F46E5';
        });

        categoryInput.onBlur.listen((event) {
          categoryInput.style.borderColor = '#ccc';
        });

        // 키보드 단축키 지원 (Ctrl+A: 전체 선택)
        categoryInput.onKeyDown.listen((event) {
          if (event.ctrlKey && event.keyCode == 65) { // Ctrl+A
            event.preventDefault();
            categoryInput.select();
          }
        });

        // 더블클릭으로 전체 선택
        categoryInput.onDoubleClick.listen((event) {
          categoryInput.select();
        });

        return categoryInput;
      },
    );

    // 질문 입력 필드 등록
    ui.platformViewRegistry.registerViewFactory(
      questionViewType,
      (int viewId) {
        questionInput = html.InputElement();
        questionInput.type = 'text';
        questionInput.placeholder = '자주 묻는 질문을 입력하세요';
        questionInput.value = questionValue;
        questionInput.style.cssText = '''
          width: 100%;
          height: 50px;
          font-size: 16px;
          padding: 12px 16px;
          border: 1px solid #ccc;
          border-radius: 8px;
          outline: none;
          font-family: 'NotoSansKR', sans-serif;
          user-select: text;
          -webkit-user-select: text;
          -moz-user-select: text;
          -ms-user-select: text;
        ''';

        questionInput.onInput.listen((event) {
          if (mounted) {
            setState(() {
              questionValue = questionInput.value ?? '';
            });
          }
        });

        questionInput.onFocus.listen((event) {
          questionInput.style.borderColor = '#4F46E5';
        });

        questionInput.onBlur.listen((event) {
          questionInput.style.borderColor = '#ccc';
        });

        // 키보드 단축키 지원 (Ctrl+A: 전체 선택)
        questionInput.onKeyDown.listen((event) {
          if (event.ctrlKey && event.keyCode == 65) { // Ctrl+A
            event.preventDefault();
            questionInput.select();
          }
        });

        // 더블클릭으로 전체 선택
        questionInput.onDoubleClick.listen((event) {
          questionInput.select();
        });

        return questionInput;
      },
    );

    // 답변 입력 필드 등록 (TextArea)
    ui.platformViewRegistry.registerViewFactory(
      answerViewType,
      (int viewId) {
        answerInput = html.TextAreaElement();
        answerInput.placeholder = '질문에 대한 답변을 입력하세요';
        answerInput.value = answerValue;
        answerInput.style.cssText = '''
          width: 100%;
          height: 400px;
          font-size: 16px;
          padding: 16px;
          border: 1px solid #ccc;
          border-radius: 8px;
          outline: none;
          font-family: 'NotoSansKR', sans-serif;
          resize: vertical;
          user-select: text;
          -webkit-user-select: text;
          -moz-user-select: text;
          -ms-user-select: text;
        ''';

        answerInput.onInput.listen((event) {
          if (mounted) {
            setState(() {
              answerValue = answerInput.value ?? '';
            });
          }
        });

        answerInput.onFocus.listen((event) {
          answerInput.style.borderColor = '#4F46E5';
        });

        answerInput.onBlur.listen((event) {
          answerInput.style.borderColor = '#ccc';
        });

        // 키보드 단축키 지원 (Ctrl+A: 전체 선택)
        answerInput.onKeyDown.listen((event) {
          if (event.ctrlKey && event.keyCode == 65) { // Ctrl+A
            event.preventDefault();
            answerInput.select();
          }
        });

        // 더블클릭으로 단어 선택, 트리플클릭으로 전체 선택
        answerInput.onDoubleClick.listen((event) {
          answerInput.select();
        });

        return answerInput;
      },
    );
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    _categoryController.dispose();
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
                  _isEditMode ? "FAQ Edit" : "FAQ Write",
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
            _isEditMode ? "FAQ 수정" : "FAQ 작성",
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
          // 카테고리 입력
          Text(
            "카테고리",
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
            child: HtmlElementView(viewType: categoryViewType),
          ),
          SizedBox(height: 24),

          // 질문 입력
          Text(
            "질문",
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
            child: HtmlElementView(viewType: questionViewType),
          ),
          SizedBox(height: 24),

          // 중요 FAQ 체크박스
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
                "중요한 FAQ",
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: "NotoSansKR",
                  color: Palette.grey700,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),

          // 답변 입력
          Text(
            "답변",
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
            child: HtmlElementView(viewType: answerViewType),
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
                  onPressed: _isLoading ? null : _saveFAQ,
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

  Future<void> _saveFAQ() async {
    // HTML input 값으로 유효성 검사
    if (categoryValue.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('카테고리를 입력해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (questionValue.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('질문을 입력해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (answerValue.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('답변을 입력해주세요.'),
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
      FAQ faq = FAQ(
        id: _isEditMode ? widget.faq!.id : '',
        question: questionValue.trim(),
        answer: answerValue.trim(),
        category: categoryValue.trim(),
        createdAt: _isEditMode ? widget.faq!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
        isImportant: _isImportant,
      );

      if (_isEditMode) {
        await FAQService.updateFAQ(faq);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'FAQ가 수정되었습니다.',
              style: TextStyle(fontFamily: "NotoSansKR"),
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await FAQService.addFAQ(faq);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'FAQ가 저장되었습니다.',
              style: TextStyle(fontFamily: "NotoSansKR"),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

      Navigator.pop(context, true); // 성공 시 true 반환
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
