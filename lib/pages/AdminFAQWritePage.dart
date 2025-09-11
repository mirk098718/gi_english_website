import 'package:flutter/material.dart';
import 'package:gi_english_website/class/FAQ.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/FAQService.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/widget/WebSchoolLayout.dart';
import 'package:gi_english_website/widget/MobileSchoolLayout.dart';
import 'package:gi_english_website/util/MyWidget.dart';

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

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.faq != null;
    _checkAdminStatus();

    if (_isEditMode) {
      _questionController.text = widget.faq!.question;
      _answerController.text = widget.faq!.answer;
      _categoryController.text = widget.faq!.category;
      _isImportant = widget.faq!.isImportant;
    } else {
      _categoryController.text = '일반';
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
          TextFormField(
            controller: _categoryController,
            decoration: InputDecoration(
              hintText: "카테고리를 입력하세요 (예: 일반, 수업, 교재)",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Palette.grey300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Palette.primary, width: 2),
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '카테고리를 입력해주세요.';
              }
              return null;
            },
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
          TextFormField(
            controller: _questionController,
            decoration: InputDecoration(
              hintText: "자주 묻는 질문을 입력하세요",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Palette.grey300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Palette.primary, width: 2),
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '질문을 입력해주세요.';
              }
              return null;
            },
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
          TextFormField(
            controller: _answerController,
            maxLines: 15,
            decoration: InputDecoration(
              hintText: "질문에 대한 답변을 입력하세요",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Palette.grey300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Palette.primary, width: 2),
              ),
              contentPadding: EdgeInsets.all(16),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '답변을 입력해주세요.';
              }
              return null;
            },
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
    if (!_formKey.currentState!.validate()) {
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
        question: _questionController.text.trim(),
        answer: _answerController.text.trim(),
        category: _categoryController.text.trim(),
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
