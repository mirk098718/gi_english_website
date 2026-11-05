import 'package:flutter/material.dart';
import 'package:gi_english_website/pages/AdminFAQWritePage.dart';
import 'package:gi_english_website/pages/AdminNoticeWritePage.dart';
import 'package:gi_english_website/pages/AdminOnlineHubPage.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/widget/AccountRecoveryDialog.dart';

class WorkingAdminLoginPage extends StatefulWidget {
  final String category; // 게시판 타입 ('notice' 또는 'faq')

  const WorkingAdminLoginPage({Key? key, this.category = 'notice'})
      : super(key: key);

  @override
  _WorkingAdminLoginPageState createState() => _WorkingAdminLoginPageState();
}

class _WorkingAdminLoginPageState extends State<WorkingAdminLoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final emailFocus = FocusNode();
  final passwordFocus = FocusNode();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Palette.adminTheme(Theme.of(context)),
      child: Scaffold(
      appBar: AppBar(
        title:
            Text("운영자 로그인", style: TextStyle(fontFamily: "NotoSansKR")),
        backgroundColor: Palette.navy,
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
                  color: Palette.darkTeal,
                ),
                SizedBox(height: 32),
                Text(
                  "운영자 로그인",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: "Jalnan",
                    fontSize: 24,
                    color: Palette.navy,
                  ),
                ),
                SizedBox(height: 40),
                Text(
                  "이메일",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: "NotoSansKR",
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: emailController,
                  focusNode: emailFocus,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.username],
                  onSubmitted: (_) => passwordFocus.requestFocus(),
                  decoration: InputDecoration(
                    hintText: '관리자 또는 강사 이메일',
                    hintStyle: TextStyle(fontFamily: "NotoSansKR"),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  style: TextStyle(fontFamily: "NotoSansKR", fontSize: 16),
                ),
                SizedBox(height: 20),
                Text(
                  "비밀번호",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: "NotoSansKR",
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: passwordController,
                  focusNode: passwordFocus,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onSubmitted: (_) {
                    if (!_isLoading) _login();
                  },
                  decoration: InputDecoration(
                    hintText: '비밀번호를 입력하세요',
                    hintStyle: TextStyle(fontFamily: "NotoSansKR"),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  style: TextStyle(fontFamily: "NotoSansKR", fontSize: 16),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => AccountRecoveryDialog.show(
                              context,
                              prefillEmail: emailController.text,
                            ),
                    child: Text(
                      '아이디 · 비밀번호 찾기',
                      style: TextStyle(
                        fontFamily: 'NotoSansKR',
                        fontSize: 13,
                        color: Palette.darkTeal,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Palette.darkTeal,
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
    ),
    );
  }

  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty) {
      _showSnackBar('이메일을 입력해주세요.', Colors.red);
      return;
    }

    if (password.isEmpty) {
      _showSnackBar('비밀번호를 입력해주세요.', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1) 메인 관리자 (기존 하드코딩 계정) — Firebase Auth 세션이 있어야
      // 학원 갤러리/공지/FAQ 쓰기가 통과한다. prefs-only 로그인은 하지 않는다.
      if (email.toLowerCase() == AuthService.ownerEmail &&
          password == "gleam701") {
        final cred = await AuthService.signInWithEmailAndPassword(
          email,
          password,
        );
        if (cred == null || cred.user == null) {
          _showSnackBar(
            '메인 관리자 Firebase 로그인에 실패했습니다. '
            'Authentication에 등록된 비밀번호로 다시 시도해 주세요.',
            Colors.red,
          );
          return;
        }
        await AuthService.ensureAdminDoc(email, "관리자", role: 'owner');
        await AuthService.saveAdminSession(
          email,
          name: "관리자",
          role: AdminRole.owner,
          uid: cred.user?.uid,
        );

        _showSnackBar('관리자 로그인에 성공했습니다.', Colors.green);
        Navigator.pop(context);
        if (widget.category == 'general') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AdminOnlineHubPage()),
          );
        } else {
          _showWriteDialog();
        }
        return;
      }

      if (widget.category != 'general') {
        _showSnackBar('게시판 관리는 메인 관리자만 가능합니다.', Colors.red);
        return;
      }

      final error =
          await AuthService.signInAsStaff(email: email, password: password);
      if (error != null) {
        _showSnackBar(error, Colors.red);
        return;
      }

      final role = await AuthService.getAdminRole();
      _showSnackBar(
        role == AdminRole.teacher ? '강사 로그인에 성공했습니다.' : '관리자 로그인에 성공했습니다.',
        Colors.green,
      );
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AdminOnlineHubPage()),
      );
    } catch (e) {
      _showSnackBar('로그인 중 오류가 발생했습니다: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
