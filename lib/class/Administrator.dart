

class Administrator {
  String prefKey() => "id_"+ adminId;
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
