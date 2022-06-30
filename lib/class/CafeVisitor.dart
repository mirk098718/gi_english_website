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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> jsonMap = toJson();
    String jsonStr = JsonUtil.mapToString(jsonMap);
    await prefs.setString(prefKey(), jsonStr);
  }

}
