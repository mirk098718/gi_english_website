import 'dart:convert';

class JsonUtil {

  static Map<String,dynamic> stringToMap(String jsonStr){
    return jsonDecode(jsonStr);
  }

  static String mapToString(Map<String,dynamic> jsonMap){
    return jsonEncode(jsonMap);
  }
}