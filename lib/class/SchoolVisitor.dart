import 'package:cloud_firestore/cloud_firestore.dart';

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


  SchoolVisitor.fromJson(Map<String, dynamic> json)
  : level = json['level'], time = json['time'], super.fromJson(json);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = super.toJson();
    map.addAll({
      'level': level,
      'time': time,
    });

    return map;
  }

  factory SchoolVisitor.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return SchoolVisitor(
      childName: data?['childName'],
      childAge: data?['childAge'],
      parentName: data?['parentName'],
      parentNumber: data?['parentNumber'],
      time: data?['time'],
      level: data?['level'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return toJson();
  }


  bool isValid() {
    return childName != "" && parentName != "" && parentNumber != "";
  }
  //
  // Future<void> save() async{
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   Map<String, dynamic> jsonMap = toJson();
  //   String jsonStr = JsonUtil.mapToString(jsonMap);
  //   await prefs.setString(prefKey(), jsonStr);
  //   print(jsonStr);
  // }
  //
  // static Future<SchoolVisitor?> loadWithkey(String key) async {
  //   SharedPreferences storage = await SharedPreferences.getInstance();
  //   String? jsonStr = storage.getString(key);
  //   if(jsonStr == null) {
  //     return null;
  //   }
  //
  //   Map<String, dynamic> json = JsonUtil.stringToMap(jsonStr);
  //   return SchoolVisitor.fromJson(json);
  // }
}

