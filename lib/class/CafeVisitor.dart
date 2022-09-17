import 'package:shared_preferences/shared_preferences.dart';

import '../util/JsonUtil.dart';
import 'Visitor.dart';

class CafeVisitor extends Visitor {
  String prefKey() => "CafeVisitor:${childName}";
  String program;
  String programPeriod;

  CafeVisitor({
    required super.childName,
    required super.childAge,
    required super.parentName,
    required super.parentNumber,
    required this.program,
    required this.programPeriod,
  });

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = super.toJson();
    map.addAll({
      'program': program,
      'programPeriod': programPeriod,
    });

    return map;
  }

  CafeVisitor.fromJson(Map<String, dynamic> json)
    : program = json['program'],
      programPeriod = json['programPeriod'], super.fromJson(json);

  bool isValid() {
    return childName != "" && parentName != "" && parentNumber != "";
  }

  Future<void> save() async{
    SharedPreferences storage = await SharedPreferences.getInstance();
    Map<String, dynamic> jsonMap = toJson();
    String jsonStr = JsonUtil.mapToString(jsonMap);
    await storage.setString(prefKey(), jsonStr);
  }

//컬렉션? 여러 데이터를 관리하는 것.
//종류 : List(순서있음),Set(순서없음),Map(key를 통해서 value를 찾는 것 -> 내가 갖고싶은것은? value.)
  static Future<CafeVisitor?> loadWithkey(String key) async {
    //1개의 CafeVisitor인스턴스StringJosn을 갖고오고싶다.
    //sharedpreferences가  특정 key가 있음.

    SharedPreferences storage = await SharedPreferences.getInstance();
    String? jsonStr = storage.getString(key);
    if(jsonStr == null) {
      return null;
    }

    Map<String, dynamic> json = JsonUtil.stringToMap(jsonStr);
    return CafeVisitor.fromJson(json);
  }
}