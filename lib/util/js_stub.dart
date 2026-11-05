class JsObject {
  JsObject.jsify(Object object);
}

class JsContext {
  dynamic callMethod(String method, List<dynamic> args) => null;
}

final JsContext context = JsContext();
