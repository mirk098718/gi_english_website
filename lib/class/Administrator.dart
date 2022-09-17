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

  void login(BuildContext context) {
    if (adminId == "htmiakim" && adminPw == "090910@") {
      SnackbarUtil.showSnackBar("관리자 모드로 로그인 되었습니다", context);
      MenuUtil.push(context, AdminVisitorViewPage());
      return;
    }

    SnackbarUtil.showSnackBar("로그인에 실패하였습니다", context);

    //TODO: 추후에 SharedPrefrese로 해볼 수 있는 코드....
    //로컬에만 저장되는거라 실제로 작동은 안함.. 내컴퓨터에서만 해볼수있음.
    // String? savedJson = prefs.getString(adminstratorToLogin.prefKey());
    // bool idExist = savedJson != null;
    // if(idExist) {
    //   Administrator registeredAdminstrator = Administrator.fromJson(jsonDecode(savedJson));
    //   if(adminstratorToLogin.adminPw == registeredAdminstrator.adminPw) {
    //     //로그인을 시켜야함.
    //     SnackbarUtil.showSnackBar(
    //         "관리자 모드로 로그인 되었습니다", context);
    //     MenuUtil.push(context, SchoolConsultationPage());
    //     return;
    //   }
    // }
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
