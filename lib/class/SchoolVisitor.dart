import 'package:shared_preferences/shared_preferences.dart';

import '../util/JsonUtil.dart';
import 'Visitor.dart';

class SchoolVisitor extends Visitor {
  String prefKey() => "SchoolVisitor:${childName}";
  String time;
  String level;

  SchoolVisitor({
    required super.childName,
    required super.childAge,
    required super.parentName,
    required super.parentNumber,
    required this.time,
    required this.level,
  });

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = super.toJson();
    map.addAll({
      'level': level,
      'time': time,
    });

    return map;
  }

  SchoolVisitor.fromJson(Map<String, dynamic> json)
    : level = json['level'], time = json['time'], super.fromJson(json);


  bool isValid() {
    return childName != "" && parentName != "" && parentNumber != "";
  }

  Future<void> save() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> jsonMap = toJson();
    String jsonStr = JsonUtil.mapToString(jsonMap);
    await prefs.setString(prefKey(), jsonStr);
    print(jsonStr);
  }
}

