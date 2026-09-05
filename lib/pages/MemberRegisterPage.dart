import 'package:flutter/material.dart';
import 'package:gi_english_website/pages/MemberLoginPage.dart';
import 'package:gi_english_website/pages/SchoolOnlineClassroomPage.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/widget/MobileSchoolLayout.dart';
import 'package:gi_english_website/widget/WebSchoolLayout.dart';

import '../util/WidgetUtil.dart';

class MemberRegisterPage extends StatefulWidget {
  const MemberRegisterPage({Key? key}) : super(key: key);

  @override
  _MemberRegisterPageState createState() => _MemberRegisterPageState();
}

class _MemberRegisterPageState extends State<MemberRegisterPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final passwordConfirmController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    passwordConfirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 768) {
      return WebSchoolLayout(content: scrollView());
    }
    return MobileSchoolLayout(content: mobileScrollView());
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

  Future<void> _register() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text;
    final passwordConfirm = passwordConfirmController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showMessage('이름, 이메일, 비밀번호는 필수입니다.', isError: true);
      return;
    }
    if (password.length < 6) {
      _showMessage('비밀번호는 6자 이상으로 입력해주세요.', isError: true);
      return;
    }
    if (password != passwordConfirm) {
      _showMessage('비밀번호 확인이 일치하지 않습니다.', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final error = await AuthService.registerMember(
      email: email,
      password: password,
      name: name,
      phone: phone,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (error != null) {
      _showMessage(error, isError: true);
      return;
    }

    _showMessage('회원가입이 완료되었습니다.');
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
            "회원가입",
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
                    "온라인 프로그램 회원 가입",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "Jalnan",
                      fontSize: 15,
                      color: Palette.secondaryDark,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "가입 후 관리자 수강 배정이 완료되면 내 강의실에서 프로그램을 이용하실 수 있습니다.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "NotoSansKR",
                      fontSize: 13,
                      color: Palette.grey600,
                      height: 1.5,
                    ),
                  ),
                  MyWidget.roundEdgeTextField("이름", nameController,
                      autofocus: true),
                  MyWidget.roundEdgeTextField("이메일", emailController),
                  MyWidget.roundEdgeTextField("연락처 (선택)", phoneController),
                  MyWidget.roundEdgeTextField("비밀번호 (6자 이상)", passwordController,
                      obscureText: true),
                  MyWidget.roundEdgeTextField(
                      "비밀번호 확인", passwordConfirmController,
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
                      onPressed: _isLoading ? null : _register,
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
                              "가입하기",
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
                      MenuUtil.push(context, MemberLoginPage());
                    },
                    child: Text(
                      "이미 회원이신가요? 로그인",
                      style: TextStyle(
                        fontFamily: "NotoSansKR",
                        fontSize: 13,
                        color: Palette.secondaryDark,
                      ),
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
