import 'package:flutter/material.dart';
import 'package:gi_english_website/pages/MemberRegisterPage.dart';
import 'package:gi_english_website/pages/SchoolOnlineClassroomPage.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/widget/MobileSchoolLayout.dart';
import 'package:gi_english_website/widget/WebSchoolLayout.dart';

import '../util/WidgetUtil.dart';

class MemberLoginPage extends StatefulWidget {
  const MemberLoginPage({Key? key}) : super(key: key);

  @override
  _MemberLoginPageState createState() => _MemberLoginPageState();
}

class _MemberLoginPageState extends State<MemberLoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    MediaQueryData mediaQueryData = MediaQuery.of(context);
    Size size = mediaQueryData.size;
    double width = size.width;
    if (width > 768) {
      return WebSchoolLayout(content: scrollView());
    } else {
      return MobileSchoolLayout(content: mobileScrollView());
    }
  }

  Widget scrollView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          content(),
          MyWidget.footer(),
        ],
      ),
    );
  }

  Widget mobileScrollView() {
    return SingleChildScrollView(
      child: Container(
        color: Palette.white,
        child: Column(
          children: [
            content(),
            SizedBox(height: 51, child: MyWidget.mobileSchoolFooter()),
          ],
        ),
      ),
    );
  }

  Future<void> _login() async {
    String email = emailController.text.trim();
    String password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('이메일과 비밀번호를 입력해주세요.', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result =
        await AuthService.signInWithEmailAndPassword(email, password);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result == null) {
      _showMessage('로그인에 실패했습니다. 이메일과 비밀번호를 확인해주세요.', isError: true);
      return;
    }

    _showMessage('로그인되었습니다.');
    MenuUtil.push(context, SchoolOnlineClassroomPage());
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontFamily: "NotoSansKR")),
        backgroundColor: isError ? Palette.danger : Palette.success,
      ),
    );
  }

  Widget content() {
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.all(20),
      color: Palette.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "회원 로그인",
            style: TextStyle(fontFamily: "Jalnan", fontSize: 20),
          ),
          WidgetUtil.myDivider(),
          SizedBox(height: 20),
          Center(
            child: Container(
              width: 420,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Palette.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Palette.grey200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "온라인 프로그램 회원 로그인",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "Jalnan",
                      fontSize: 15,
                      color: Palette.secondaryDark,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "로그인하시면 나의 강의실에서 배정된 인강을 수강하실 수 있습니다.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "NotoSansKR",
                      fontSize: 13,
                      color: Palette.grey600,
                      height: 1.5,
                    ),
                  ),
                  MyWidget.roundEdgeTextField("이메일을 입력해주세요", emailController,
                      autofocus: true),
                  MyWidget.roundEdgeTextField(
                      "비밀번호를 입력해주세요", passwordController,
                      obscureText: true),
                  SizedBox(height: 4),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Palette.secondaryDark,
                        foregroundColor: Palette.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Palette.white,
                              ),
                            )
                          : Text(
                              "로그인",
                              style: TextStyle(
                                fontFamily: "Jalnan",
                                color: Palette.white,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      MenuUtil.push(context, MemberRegisterPage());
                    },
                    child: Text(
                      "아직 회원이 아니신가요? 회원가입",
                      style: TextStyle(
                        fontFamily: "NotoSansKR",
                        fontSize: 13,
                        color: Palette.secondaryDark,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "가입 후 관리자 수강 배정이 완료되면 내 강의실에서 프로그램을 이용할 수 있습니다.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "NotoSansKR",
                      fontSize: 12,
                      color: Palette.grey500,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 40),
        ],
      ),
    );
  }
}
