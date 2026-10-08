import 'dart:async';
import 'dart:typed_data';

/// 모바일 컴파일용 빈 구현. 웹에서는 dart:html이 대신 쓰인다.
class Event {
  bool ctrlKey = false;
  int keyCode = 0;
  void preventDefault() {}
}

class HtmlStream<T> {
  const HtmlStream();

  StreamSubscription<T> listen(
    void Function(T event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<T>.empty().listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  Future<T> get first => Future<T>.error(UnsupportedError('web only'));
}

class CssStyleDeclaration {
  String cssText = '';
  String border = '';
  String width = '';
  String height = '';
  String borderColor = '';
}

class Blob {
  Blob(List<dynamic> parts);
}

class Url {
  static String createObjectUrl(Blob blob) => '';
  static void revokeObjectUrl(String url) {}
}

class ImageElement {
  String src = '';
  int? width = 0;
  int? height = 0;
  int naturalWidth = 0;
  int naturalHeight = 0;
  bool complete = false;
  final HtmlStream<Event> onLoad = const HtmlStream();
  final HtmlStream<Event> onError = const HtmlStream();
}

class CanvasRenderingContext2D {
  bool imageSmoothingEnabled = false;
  String fillStyle = '';
  void fillRect(num x, num y, num w, num h) {}
  void translate(num x, num y) {}
  void scale(num x, num y) {}
  void drawImage(ImageElement image, num x, num y) {}
  void drawImageScaled(ImageElement image, num x, num y, num w, num h) {}
}

class CanvasElement {
  CanvasElement({int? width, int? height});
  int? width = 0;
  int? height = 0;
  CanvasRenderingContext2D get context2D => CanvasRenderingContext2D();
  String toDataUrl(String type, [num? quality]) => '';
}

class _Element {
  final CssStyleDeclaration style = CssStyleDeclaration();
  String? value = '';
  String placeholder = '';
  String type = '';
  final HtmlStream<Event> onInput = const HtmlStream();
  final HtmlStream<Event> onFocus = const HtmlStream();
  final HtmlStream<Event> onBlur = const HtmlStream();
  final HtmlStream<Event> onKeyDown = const HtmlStream();
  final HtmlStream<Event> onDoubleClick = const HtmlStream();
  final HtmlStream<Event> onChange = const HtmlStream();
  void setAttribute(String name, String value) {}
  void click() {}
  void select() {}
}

class InputElement extends _Element {}

class TextAreaElement extends _Element {}

class File {
  String name = '';
}

class FileList {
  bool get isEmpty => true;
  File get first => File();
}

class FileUploadInputElement extends _Element {
  String accept = '';
  FileList? files;
}

class FileReader {
  Object? result;
  final HtmlStream<Event> onLoadEnd = const HtmlStream();
  void readAsArrayBuffer(File file) {}
}

class AudioElement {
  AudioElement([String? src]);
  double volume = 0;
  num currentTime = 0;
  Future<dynamic> play() => Future<dynamic>.value();
  void pause() {}
}

class Location {
  String origin = '';
}

class Window {
  final Location location = Location();
  void open(String url, String name) {}
  String atob(String data) => '';
}

final Window window = Window();
