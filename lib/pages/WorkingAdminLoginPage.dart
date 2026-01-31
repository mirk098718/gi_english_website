import 'package:flutter/material.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/pages/AdminNoticeWritePage.dart';
import 'package:gi_english_website/pages/AdminFAQWritePage.dart';
import 'package:gi_english_website/util/AuthService.dart';
// ignore: deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui;

class WorkingAdminLoginPage extends StatefulWidget {
  final String category; // 게시판 타입 ('notice' 또는 'faq')

  const WorkingAdminLoginPage({Key? key, this.category = 'notice'})
      : super(key: key);

  @override
  _WorkingAdminLoginPageState createState() => _WorkingAdminLoginPageState();
}

class _WorkingAdminLoginPageState extends State<WorkingAdminLoginPage> {
  String emailValue = '';
  String passwordValue = '';
  bool _isLoading = false;
  bool _obscurePassword = true;

  late html.InputElement emailInput;
  late html.InputElement passwordInput;

  @override
  void initState() {
    super.initState();
    _registerHtmlInputs();
  }

  void _registerHtmlInputs() {
    // 이메일 입력 필드 등록
    ui.platformViewRegistry.registerViewFactory(
      'email-input',
      (int viewId) {
        emailInput = html.InputElement();
        emailInput.type = 'email';
        emailInput.placeholder = 'gienglish.paju@gmail.com';
        emailInput.style.cssText = '''
          width: 100%;
          height: 50px;
          font-size: 16px;
          padding: 12px 16px;
          border: 1px solid #ccc;
          border-radius: 8px;
          outline: none;
          font-family: 'NotoSansKR', sans-serif;
        ''';

        emailInput.onInput.listen((event) {
          if (mounted) {
            setState(() {
              emailValue = emailInput.value ?? '';
            });
            print('📧 이메일 입력: ${emailInput.value}');
          }
        });

        emailInput.onFocus.listen((event) {
          emailInput.style.borderColor = '#4F46E5';
        });

        emailInput.onBlur.listen((event) {
          emailInput.style.borderColor = '#ccc';
        });

        return emailInput;
      },
    );

    // 비밀번호 입력 필드 등록
    ui.platformViewRegistry.registerViewFactory(
      'password-input',
      (int viewId) {
        passwordInput = html.InputElement();
        passwordInput.type = _obscurePassword ? 'password' : 'text';
        passwordInput.placeholder = '비밀번호를 입력하세요';
        passwordInput.style.cssText = '''
          width: 100%;
          height: 50px;
          font-size: 16px;
          padding: 12px 16px;
          border: 1px solid #ccc;
          border-radius: 8px;
          outline: none;
          font-family: 'NotoSansKR', sans-serif;
        ''';

        passwordInput.onInput.listen((event) {
          if (mounted) {
            setState(() {
              passwordValue = passwordInput.value ?? '';
            });
            print('🔒 비밀번호 입력: ${passwordInput.value}');
          }
        });

        passwordInput.onFocus.listen((event) {
          passwordInput.style.borderColor = '#4F46E5';
        });

        passwordInput.onBlur.listen((event) {
          passwordInput.style.borderColor = '#ccc';
        });

        return passwordInput;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text("관리자 로그인 (동작 버전)", style: TextStyle(fontFamily: "NotoSansKR")),
        backgroundColor: Palette.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 40),
                Icon(
                  Icons.admin_panel_settings,
                  size: 80,
                  color: Palette.primary,
                ),
                SizedBox(height: 32),
                Text(
                  "관리자 로그인",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: "Jalnan",
                    fontSize: 24,
                    color: Palette.black,
                  ),
                ),
                SizedBox(height: 40),

                // 이메일 입력
                Text(
                  "이메일",
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
                  child: HtmlElementView(viewType: 'email-input'),
                ),
                SizedBox(height: 20),

                // 비밀번호 입력
                Row(
                  children: [
                    Text(
                      "비밀번호",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: "NotoSansKR",
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                          passwordInput.type =
                              _obscurePassword ? 'password' : 'text';
                        });
                      },
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: HtmlElementView(viewType: 'password-input'),
                ),
                SizedBox(height: 32),

                // 로그인 버튼
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Palette.primary,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          "로그인",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: "NotoSansKR",
                          ),
                        ),
                ),
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    // 유효성 검사
    if (emailValue.trim().isEmpty) {
      _showSnackBar('이메일을 입력해주세요.', Colors.red);
      return;
    }

    if (passwordValue.trim().isEmpty) {
      _showSnackBar('비밀번호를 입력해주세요.', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 하드코딩된 관리자 계정 확인
      if (emailValue.trim() == "gienglish.paju@gmail.com" &&
          passwordValue.trim() == "gleam701") {
        // AuthService를 통해 로그인 상태 저장 (관리자 이름도 함께 저장)
        await AuthService.saveAdminSession(emailValue.trim(), name: "관리자");

        _showSnackBar('관리자 로그인에 성공했습니다.', Colors.green);

        // 글쓰기 다이얼로그 표시 (카테고리에 따라 처리)
        Navigator.pop(context); // 로그인 페이지 닫기
        if (widget.category != 'general') {
          _showWriteDialog();
        }
      } else {
        _showSnackBar('로그인에 실패했습니다. 이메일과 비밀번호를 확인해주세요.', Colors.red);
      }
    } catch (e) {
      _showSnackBar('로그인 중 오류가 발생했습니다: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontFamily: "NotoSansKR")),
        backgroundColor: color,
      ),
    );
  }

  void _showWriteDialog() {
    if (widget.category == 'notice') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AdminNoticeWritePage(),
          fullscreenDialog: true,
        ),
      );
    } else if (widget.category == 'faq') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AdminFAQWritePage(),
          fullscreenDialog: true,
        ),
      );
    }
  }
}
