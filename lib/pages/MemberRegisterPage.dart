import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gi_english_website/util/SiteLayout.dart';
import 'package:gi_english_website/util/AppLanguage.dart';
import 'package:gi_english_website/pages/MemberLoginPage.dart';
import 'package:gi_english_website/pages/SchoolOnlineClassroomPage.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/PhoneUtil.dart';
import 'package:gi_english_website/util/ProfilePhotoPicker.dart';
import 'package:gi_english_website/widget/MobileSchoolLayout.dart';
import 'package:gi_english_website/widget/ProfileAvatar.dart';
import 'package:gi_english_website/widget/WebSchoolLayout.dart';

import '../util/WidgetUtil.dart';

class MemberRegisterPage extends StatefulWidget {
  const MemberRegisterPage({Key? key}) : super(key: key);

  @override
  _MemberRegisterPageState createState() => _MemberRegisterPageState();
}

class _MemberRegisterPageState extends State<MemberRegisterPage> {
  final nameController = TextEditingController();
  final nicknameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final guardianNameController = TextEditingController();
  final guardianPhoneController = TextEditingController();
  final passwordController = TextEditingController();
  final passwordConfirmController = TextEditingController();
  Uint8List? _photo;
  bool _isLoading = false;
  bool _isMinor = false;

  @override
  void dispose() {
    nameController.dispose();
    nicknameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    guardianNameController.dispose();
    guardianPhoneController.dispose();
    passwordController.dispose();
    passwordConfirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!useMobileSchoolLayout(context)) {
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
          ],
        ),
      ),
    );
  }

  Future<void> _register() async {
    final name = nameController.text.trim();
    final nickname = nicknameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final guardianName = guardianNameController.text.trim();
    final guardianPhone = guardianPhoneController.text.trim();
    final password = passwordController.text;
    final passwordConfirm = passwordConfirmController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showMessage('수강생 이름, 이메일(ID), 비밀번호는 필수입니다.', isError: true);
      return;
    }
    final nicknameError = AuthService.validateNickname(nickname);
    if (nicknameError != null) {
      _showMessage(nicknameError, isError: true);
      return;
    }
    final phoneError = PhoneUtil.validate(phone);
    if (phoneError != null) {
      _showMessage(phoneError, isError: true);
      return;
    }
    if (_isMinor) {
      if (guardianName.isEmpty) {
        _showMessage('미성년자 가입은 보호자 이름을 입력해 주세요.', isError: true);
        return;
      }
      final guardianPhoneError = PhoneUtil.validate(guardianPhone);
      if (guardianPhoneError != null) {
        _showMessage('보호자 $guardianPhoneError', isError: true);
        return;
      }
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
      nickname: nickname,
      phone: phone,
      isMinor: _isMinor,
      guardianName: guardianName,
      guardianPhone: guardianPhone,
      photoBytes: _photo,
      photoFileName: _photo == null ? null : 'photo.jpg',
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

  Widget _field(String hint, TextEditingController controller,
      {bool obscureText = false,
      bool autofocus = false,
      TextInputType? keyboardType}) {
    return MyWidget.roundEdgeTextField(
      tr(context, hint),
      controller,
      obscureText: obscureText,
      autofocus: autofocus,
      dense: true,
      keyboardType: keyboardType,
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
            tr(context, "회원가입"),
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
                    tr(context, "온라인 프로그램 회원 가입"),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "Jalnan",
                      fontSize: 15,
                      color: Palette.navy,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    tr(context, "가입 후 관리자 수강 배정이 완료되면 내 강의실에서 프로그램을 이용하실 수 있습니다. 로그인은 이메일을 ID로 쓰고, 수업에서는 닉네임과 프로필 사진이 보입니다. 휴대폰 번호는 화상수업 예약이 확정되면 알림 문자를 보내는 데 사용합니다."),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "NotoSansKR",
                      fontSize: 13,
                      color: Palette.grey600,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: Column(
                      children: [
                        ProfileAvatar(
                          bytes: _photo,
                          label: nicknameController.text.trim().isNotEmpty
                              ? nicknameController.text
                              : nameController.text,
                          size: 88,
                        ),
                        SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  final cropped =
                                      await ProfilePhotoPicker.pickAndCrop(
                                    context,
                                    onError: (message) =>
                                        _showMessage(message, isError: true),
                                  );
                                  if (!mounted ||
                                      cropped == null ||
                                      cropped.isEmpty) {
                                    return;
                                  }
                                  setState(() => _photo = cropped);
                                },
                          icon: Icon(Icons.photo_camera_outlined, size: 18),
                          label: Text(
                            _photo == null
                                ? tr(context, "프로필 사진 넣기")
                                : tr(context, "사진 다시 선택"),
                            style: TextStyle(fontFamily: "NotoSansKR"),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  _field("수강생 이름", nameController, autofocus: true),
                  CheckboxListTile(
                    value: _isMinor,
                    contentPadding: EdgeInsets.symmetric(horizontal: 4),
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: Palette.darkTeal,
                    title: Text(
                      tr(context, "미성년자입니다"),
                      style: TextStyle(
                        fontFamily: "NotoSansKR",
                        fontSize: 14,
                        color: Palette.grey800,
                      ),
                    ),
                    onChanged: _isLoading
                        ? null
                        : (value) {
                            setState(() {
                              _isMinor = value == true;
                              if (!_isMinor) {
                                guardianNameController.clear();
                                guardianPhoneController.clear();
                              }
                            });
                          },
                  ),
                  if (_isMinor) ...[
                    _field("보호자 이름", guardianNameController),
                    _field(
                      "보호자 연락처",
                      guardianPhoneController,
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                  _field(
                    "수강생 휴대폰 번호 (필수)",
                    phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1, color: Palette.grey300),
                  ),
                  _field("닉네임 (선택, 수업에서 보일 이름)", nicknameController),
                  _field(
                    "이메일 (로그인 ID)",
                    emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  _field("비밀번호 (6자 이상)", passwordController, obscureText: true),
                  _field("비밀번호 확인", passwordConfirmController,
                      obscureText: true),
                  SizedBox(height: 8),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Palette.darkTeal,
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
                              tr(context, "가입하기"),
                              style: TextStyle(
                                fontFamily: "Jalnan",
                                color: Palette.white,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      MenuUtil.push(context, MemberLoginPage());
                    },
                    child: Text(
                      tr(context, "이미 회원이신가요? 로그인"),
                      style: TextStyle(
                        fontFamily: "NotoSansKR",
                        fontSize: 13,
                        color: Palette.darkTeal,
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
