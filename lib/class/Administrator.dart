import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/src/widgets/framework.dart';
import '../admin/page/AdminVisitorViewPage.dart';
import '../util/MenuUtil.dart';
import '../util/SnackbarUtil.dart';

class Administrator {
  String prefKey() => "id_" + adminId;
  String adminId;
  String adminPw;

  Administrator({required this.adminId, required this.adminPw});

  Map<String, dynamic> toJson() {
    return {
      'adminId': adminId,
      'adminPw': adminPw,
    };
  }

  Administrator.fromJson(Map<String, dynamic> json)
      : adminId = json['adminId'],
        adminPw = json['adminPw'];

  void login(BuildContext context) async {
    //문제? 로그인을 모든 유저가 할 수 있다. (회원가입한 유저는 다 로그인할지도?)
    //해결?=
    // 회원가입 안하면 안되나? X
    // 특정 유저만 관리자 로그인하게 하면되나?
    //어떻게 구분할 수 있을까요?
    //이게 관리자 아이디 인지만 비교한다.

    //관리자 아이디가 아니면, 관리자 아이디가 아닙니다.

    if (adminId != "mirk098718@gmail.com") {
      SnackbarUtil.showSnackBar("관리자 아이디가 아니므로 로그인 불가합니다.", context);
      return;
    }

    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: adminId, password: adminPw);
      SnackbarUtil.showSnackBar("관리자 모드로 로그인 되었습니다", context);
      MenuUtil.push(context, AdminVisitorViewPage());
    } on FirebaseAuthException catch (e) {
      //1. (초보) FirebaseAuth 개발자가 만든 문서를 본다.
      //2. (고수) FirebaseAuthException에 들어간다.
      if (e.code == 'user-not-found') {
        SnackbarUtil.showSnackBar("해당 이메일이 없습니다.", context);
      } else if (e.code == 'wrong-password') {
        SnackbarUtil.showSnackBar("비밀번호가 틀렸습니다.", context);
      } else {
        SnackbarUtil.showSnackBar("로그인에 실패하였습니다.[code:${e.code}]", context);
      }
    }
  }
}
//
// void main()async{
//
//   Administrator admin = Administrator(adminId: "htmiakim", adminPw: "090910@");
//
//   Map<String,dynamic>jsonMap = admin.toJson();
//
//   String jsonStr = jsonEncode(jsonMap);
//
//   SharedPreferences prefs = await SharedPreferences.getInstance();
//
//   prefs.setString("id_${admin.adminId}", jsonStr);
//
//
//
//
//
//
// }
//
