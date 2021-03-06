import 'package:flutter/material.dart';
import 'package:gi_english_website/class/Administrator.dart';
import 'package:gi_english_website/pages/SchoolConsultationPage.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/SnackbarUtil.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    return Scaffold(
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
                MyWidget.roundEdgeTextField("PASSWORD", adminPwController),
                SizedBox(height: 20),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        primary: Palette.mainMediumPurple,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0)),
                        minimumSize: Size(100, 40)),
                    onPressed: () async {
                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      String id = adminIdController.text.trim();
                      String pw = adminPwController.text.trim();
                      if (id.isEmpty || pw.isEmpty) {
                        SnackbarUtil.showSnackBar(
                            "????????? ??? ??????????????? ????????? ??????????????????", context);
                        return;
                      }

                      Administrator adminstratorToLogin =
                          Administrator(adminId: id, adminPw: pw);
                      if (adminstratorToLogin.adminId == "htmiakim" &&
                          adminstratorToLogin.adminPw == "090910@") {
                        SnackbarUtil.showSnackBar("????????? ????????? ????????? ???????????????", context);
                        MenuUtil.push(context, SchoolConsultationPage());
                        return;
                      }

                      SnackbarUtil.showSnackBar("???????????? ?????????????????????", context);

                      //TODO: ????????? SharedPrefrese??? ?????? ??? ?????? ??????....
                      //???????????? ?????????????????? ????????? ????????? ??????.. ????????????????????? ???????????????.
                      // String? savedJson = prefs.getString(adminstratorToLogin.prefKey());
                      // bool idExist = savedJson != null;
                      // if(idExist) {
                      //   Administrator registeredAdminstrator = Administrator.fromJson(jsonDecode(savedJson));
                      //   if(adminstratorToLogin.adminPw == registeredAdminstrator.adminPw) {
                      //     //???????????? ????????????.
                      //     SnackbarUtil.showSnackBar(
                      //         "????????? ????????? ????????? ???????????????", context);
                      //     MenuUtil.push(context, SchoolConsultationPage());
                      //     return;
                      //   }
                      // }

                    },
                    child: Text("Login",
                        style: TextStyle(
                          fontFamily: "Jalnan",
                        )))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
