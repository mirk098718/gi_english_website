import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gi_english_website/class/Administrator.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/SnackbarUtil.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({Key? key}) : super(key: key);

  @override
  _AdminLoginPageState createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  TextEditingController adminIdController = TextEditingController();
  TextEditingController adminPwController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: FocusNode(),
      onKey: (event) {  if (event.isKeyPressed(LogicalKeyboardKey.enter)) {
          onLogin();
        }
      },
      child: Scaffold(
        body: SizedBox.expand(
          child: Container(
            padding: EdgeInsets.all(50),
            color: Palette.lightPurpleSky,
            alignment: Alignment.center,
            child: Container(
              width: 500,
              height: 500,
              child: Column(
                children: [
                  Text(
                    "Admin Login",
                    style: TextStyle(fontSize: 25),
                  ),
                  SizedBox(height: 20),
                  MyWidget.roundEdgeTextField("ID", adminIdController),
                  SizedBox(height: 20),
                  MyWidget.roundEdgeTextField("PASSWORD", adminPwController,
                      obscureText: true),
                  SizedBox(height: 20),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Palette.mainMediumPurple,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0)),
                          minimumSize: Size(100, 40)),
                      onPressed: onLogin,
                      child: Text("Login",
                          style: TextStyle(
                            fontFamily: "Jalnan",
                          )))
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void onLogin() {
    String id = adminIdController.text.trim();
    String pw = adminPwController.text.trim();
    if (id.isEmpty || pw.isEmpty) {
      SnackbarUtil.showSnackBar("아이디 및 비밀번호를 정확히 입력해주세요", context);
      return;
    }

    Administrator adminstratorToLogin = Administrator(adminId: id, adminPw: pw);
    adminstratorToLogin.login(context);
  }
}

class Human {}

// void main() {
//   Human human = Human();

//   a();
// }


// void a(){
//   Human human;
//   human = Human();
//   print("a");
// }